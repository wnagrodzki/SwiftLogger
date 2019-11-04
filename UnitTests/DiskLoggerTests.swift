//
// MIT License
//
// Copyright (c) 2018 Wojciech Nagrodzki
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import XCTest
@testable import Logger

class DiskLoggerTests: XCTestCase {
    
    let logURL = URL(fileURLWithPath: "/var/log/application.log")
    
    func testLoggingMessageToFile() {
        if #available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let expectation = XCTestExpectation(description: "write(_:) was called on SizeLimitedFile")
            expectation.expectedFulfillmentCount = 1
            
            let fimeManager = FileManagerStub()
            let sizeLimitedFileFactory = SizeLimitedFileMockFactory(writeCall: expectation)
            let logrotateFactory = LogrotateMockFactory()
            let logger = DiskLogger(fileURL: logURL,
                                    fileSizeLimit: 1024,
                                    rotations: 1,
                                    fileManager: fimeManager,
                                    sizeLimitedFileFactory: sizeLimitedFileFactory,
                                    logrotateFactory: logrotateFactory)
            
            logger.log("message", level: .critical)
            
            let result = XCTWaiter().wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(result, .completed)
            
            XCTAssertEqual(sizeLimitedFileFactory.files.count, 1)
            
            // "2018-08-30 17:23:11.514 <crit> DiskLoggerTests:46 testWritingMessageToFile() a message\n"
            let loggedMessage = String(decoding: sizeLimitedFileFactory.files[0].data, as: UTF8.self)
            let expectedSuffix = " <crit> DiskLoggerTests:47 testLoggingMessageToFile() message\n"
            
            XCTAssertTrue(loggedMessage.hasSuffix(expectedSuffix))
        }
    }
    
    func testExceedingFileSizeLimit() {
        if #available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let expectation = XCTestExpectation(description: "write(_:) was called on SizeLimitedFile")
            expectation.expectedFulfillmentCount = 2
            
            let fimeManager = FileManagerStub()
            let sizeLimitedFileFactory = SizeLimitedFileMockFactory(writeCall: expectation)
            let logrotateFactory = LogrotateMockFactory()
            let logger = DiskLogger(fileURL: logURL,
                                    fileSizeLimit: 91,
                                    rotations: 1,
                                    fileManager: fimeManager,
                                    sizeLimitedFileFactory: sizeLimitedFileFactory,
                                    logrotateFactory: logrotateFactory)
            
            logger.log("1st message", level: .critical)
            logger.log("2st message", level: .critical)
            
            let result = XCTWaiter().wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(result, .completed)
            
            XCTAssertEqual(sizeLimitedFileFactory.files.count, 2)
            
            // "2018-08-31 18:29:34.748 <crit> DiskLoggerTests:75 testExceedingFileSizeLimit() 2st message\n"
            let loggedMessage = String(decoding: sizeLimitedFileFactory.files[1].data, as: UTF8.self)
            let expectedSuffix = " <crit> DiskLoggerTests:78 testExceedingFileSizeLimit() 2st message\n"
            
            XCTAssertTrue(loggedMessage.hasSuffix(expectedSuffix))
        }
    }
    
    func testErrorDuringLogProcess() {
        if #available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let expectation = XCTestExpectation(description: "write(_:) was called on SizeLimitedFile")
            expectation.expectedFulfillmentCount = 2
            
            let fimeManager = FileManagerStub()
            let sizeLimitedFileFactory = UnwritableFileStubFactory(writeCall: expectation)
            let logrotateFactory = LogrotateMockFactory()
            let logger = DiskLogger(fileURL: logURL,
                                    fileSizeLimit: 91,
                                    rotations: 1,
                                    fileManager: fimeManager,
                                    sizeLimitedFileFactory: sizeLimitedFileFactory,
                                    logrotateFactory: logrotateFactory)
            
            logger.log("1st message", level: .critical)
            logger.log("2st message", level: .critical)
            
            let result = XCTWaiter().wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(result, .completed)
            
            XCTAssertEqual(sizeLimitedFileFactory.files.count, 1)
            
            // "2018-08-31 18:29:34.748 <crit> DiskLoggerTests:75 testExceedingFileSizeLimit() 2st message\n"
            let loggedMessage = String(decoding: sizeLimitedFileFactory.files[0].data, as: UTF8.self)
            let expectedOccurence = " <warning> WriteFailed()"
            
            XCTAssertTrue(loggedMessage.contains(expectedOccurence))
        }
    }
}

private class FileManagerStub: OSFileManager {
    func itemExists(at URL: URL) -> Bool {
        return false
    }
    
    func removeItem(at URL: URL) throws {
        
    }
    
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        
    }
    
    func createFile(at URL: URL) -> Bool {
        return true
    }
}

private class SizeLimitedFileMockFactory: SizeLimitedFileFactory {
    
    private(set) var files = [SizeLimitedFileMock]()
    private let writeCall: XCTestExpectation
    
    init(writeCall: XCTestExpectation) {
        self.writeCall = writeCall
    }
    
    func makeInstance(fileURL: URL, fileSizeLimit: UInt64) throws -> SizeLimitedFile {
        let mock = SizeLimitedFileMock(writeCall: writeCall, fileSizeLimit: fileSizeLimit)
        files.append(mock)
        return mock
    }
}

private class SizeLimitedFileMock: SizeLimitedFile {
    
    private(set) var data = Data()
    private(set) var synchronizeAndCloseFileCallCount = 0
    private let writeCall: XCTestExpectation
    private let fileSizeLimit: UInt64
    
    init(writeCall: XCTestExpectation, fileSizeLimit: UInt64) {
        self.writeCall = writeCall
        self.fileSizeLimit = fileSizeLimit
    }
    
    func write(_ data: Data) throws {
        guard data.count + self.data.count <= fileSizeLimit else {
            throw SizeLimitedFileQuotaReached()
        }
        self.data.append(data)
        writeCall.fulfill()
    }
    
    func synchronizeAndCloseFile() {
        synchronizeAndCloseFileCallCount += 1
    }
}

private class UnwritableFileStubFactory: SizeLimitedFileFactory {
    
    private(set) var files = [UnwritableFileStub]()
    private let writeCall: XCTestExpectation
    
    init(writeCall: XCTestExpectation) {
        self.writeCall = writeCall
    }
    
    func makeInstance(fileURL: URL, fileSizeLimit: UInt64) throws -> SizeLimitedFile {
        let file = UnwritableFileStub(writeCall: writeCall, fileSizeLimit: fileSizeLimit)
        files.append(file)
        return file
    }
}

private class UnwritableFileStub: SizeLimitedFile {
    
    struct WriteFailed: Error {}
    
    private(set) var data = Data()
    private let writeCall: XCTestExpectation
    private var didThrowError = false
    
    init(writeCall: XCTestExpectation, fileSizeLimit: UInt64) {
        self.writeCall = writeCall
    }
    
    func write(_ data: Data) throws {
        if didThrowError {
            self.data.append(data)
            writeCall.fulfill()
        }
        else {
            didThrowError = true
            writeCall.fulfill()
            throw WriteFailed()
        }
    }
    
    func synchronizeAndCloseFile() {
        
    }
}

private class LogrotateMockFactory: LogrotateFactory {
    
    private(set) var logrotates = [LogrotateMock]()
    
    func makeInstance(fileURL: URL, rotations: Int) -> Logrotate {
        let mock = LogrotateMock()
        logrotates.append(mock)
        return mock
    }
}

private class LogrotateMock: Logrotate {
    
    private(set) var rotateCallCount = 0
    
    func rotate() throws {
        rotateCallCount += 1
    }
}
