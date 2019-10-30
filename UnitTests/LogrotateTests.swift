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

class LogrotateTests: XCTestCase {
    
    let logURL = URL(fileURLWithPath: "/var/log/application.log")
    let log1URL = URL(fileURLWithPath: "/var/log/application.log.1")
    let log2URL = URL(fileURLWithPath: "/var/log/application.log.2")
    let log3URL = URL(fileURLWithPath: "/var/log/application.log.3")
    
    func test_1rotation_0files() {
        let fimeManager = FileManagerMock(files: [])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 1, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>()
        XCTAssertEqual(actual, expected)
    }
    
    func test_1rotation_1file() {
        let fimeManager = FileManagerMock(files: [logURL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 1, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_1rotation_2files() {
        let fimeManager = FileManagerMock(files: [logURL, log1URL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 1, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_1rotation_3files() {
        let fimeManager = FileManagerMock(files: [logURL, log1URL, log2URL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 1, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL, log2URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_2rotations_0files() {
        let fimeManager = FileManagerMock(files: [])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 2, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>()
        XCTAssertEqual(actual, expected)
    }
    
    func test_2rotations_1file() {
        let fimeManager = FileManagerMock(files: [logURL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 2, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_2rotations_2files() {
        let fimeManager = FileManagerMock(files: [logURL, log1URL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 2, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL, log2URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_2rotations_3files() {
        let fimeManager = FileManagerMock(files: [logURL, log1URL, log2URL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 2, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL, log2URL])
        XCTAssertEqual(actual, expected)
    }
    
    func test_2rotations_4files() {
        let fimeManager = FileManagerMock(files: [logURL, log1URL, log2URL, log3URL])
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 2, fileManager: fimeManager)
        try? logrotate.rotate()
        
        let actual = fimeManager.files
        let expected = Set<URL>([log1URL, log2URL, log3URL])
        XCTAssertEqual(actual, expected)
    }
    
    func testErrorPropagation() {
        let fimeManager = BrokenFileSystem()
        let logrotate = LogrotateImpl(fileURL: logURL, rotations: 1, fileManager: fimeManager)
        
        XCTAssertThrowsError(try logrotate.rotate(), "An error when removing or moving an item") { (error) in
            XCTAssertTrue(error is BrokenFileSystem.IOError)
        }
    }
}

private class FileManagerMock: OSFileManager {
    
    private(set) var files = Set<URL>()
    
    init(files: Set<URL>) {
        self.files = files
    }
    
    func itemExists(at URL: URL) -> Bool {
        return files.contains(URL)
    }
    
    func removeItem(at URL: URL) throws {
        files.remove(URL)
    }
    
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        files.remove(srcURL)
        files.insert(dstURL)
    }
    
    func createFile(at URL: URL) -> Bool {
        files.insert(URL)
        return true
    }
}

private class BrokenFileSystem: OSFileManager {
    
    struct IOError: Error { }
    
    func itemExists(at URL: URL) -> Bool {
        return true
    }
    
    func removeItem(at URL: URL) throws {
        throw IOError()
    }
    
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        throw IOError()
    }
    
    func createFile(at URL: URL) -> Bool {
        return false
    }
}
