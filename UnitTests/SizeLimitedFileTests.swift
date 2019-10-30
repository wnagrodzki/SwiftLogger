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

class SizeLimitedFileTests: XCTestCase {
    
    let logURL = URL(fileURLWithPath: "/var/log/application.log")
    
    func testFileOpeningFailure() {
        let factory = UnopenableFileFactory()
        XCTAssertThrowsError(try SizeLimitedFileImpl(fileURL: logURL, fileSizeLimit: 0, fileFactory: factory), "file open failure") { (error) in
            XCTAssertTrue(error is UnopenableFileFactory.OpenFileError)
        }
    }
    
    func testKeepingFileSizeLimit() throws {
        let factory = FileMockFactory()
        let writer = try SizeLimitedFileImpl(fileURL: logURL, fileSizeLimit: 1, fileFactory: factory)
        let data = Data([0])
        try writer.write(data)
        
        XCTAssertEqual(factory.mock.writtenData, data)
    }
    
    func testExceedingFileSizeLimit() throws {
        let factory = FileMockFactory()
        let writer = try SizeLimitedFileImpl(fileURL: logURL, fileSizeLimit: 1, fileFactory: factory)
        let data = Data([0, 0])
        
        XCTAssertThrowsError(try writer.write(data), "file size limit exceeded") { (error) in
            XCTAssertTrue(error is SizeLimitedFileQuotaReached)
        }
        
        XCTAssertEqual(factory.mock.writtenData.count, 0)
    }
    
    func testSynchronizingAndClosingFile() throws {
        let factory = FileMockFactory()
        let writer = try SizeLimitedFileImpl(fileURL: logURL, fileSizeLimit: 1, fileFactory: factory)
        writer.synchronizeAndCloseFile()
        XCTAssertTrue(factory.mock.synchronizeFileCallCount == 1 && factory.mock.closeFileCallCount == 1)
    }
}

private class UnopenableFileFactory: FileFactory {
    
    struct OpenFileError: Error {}
    
    func makeInstance(forWritingTo: URL) throws -> OSFileHandle {
        throw OpenFileError()
    }
}

private class FileMockFactory: FileFactory {
    
    let mock = FileMock()
    
    func makeInstance(forWritingTo: URL) throws -> OSFileHandle {
        return mock
    }
}

private class FileMock: OSFileHandle {
    
    private(set) var writtenData = Data()
    private(set) var synchronizeFileCallCount = 0
    private(set) var closeFileCallCount = 0
    
    func seekToEndOfFile() -> UInt64 {
        return 0
    }
    
    func swift_write(_ data: Data) throws {
        self.writtenData.append(data)
    }
    
    func synchronizeFile() {
        synchronizeFileCallCount += 1
    }
    
    func closeFile() {
        closeFileCallCount += 1
    }
}
