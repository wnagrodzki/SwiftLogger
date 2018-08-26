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

class LoggetTests: XCTestCase {

    func testLocation() {
        let mock = LoggerMock()
        mock.log("", level: .critical)
        XCTAssertEqual(mock.location, "LoggetTests:32 testLocation()")
    }
    
    func testLogLevelLogDescription() {
        XCTAssertEqual(LogLevel.emergency.logDescription, "emerg")
        XCTAssertEqual(LogLevel.alert.logDescription, "alert")
        XCTAssertEqual(LogLevel.critical.logDescription, "crit")
        XCTAssertEqual(LogLevel.error.logDescription, "err")
        XCTAssertEqual(LogLevel.warning.logDescription, "warning")
        XCTAssertEqual(LogLevel.notice.logDescription, "notice")
        XCTAssertEqual(LogLevel.informational.logDescription, "info")
        XCTAssertEqual(LogLevel.debug.logDescription, "debug")
    }
}

private class LoggerMock: Logger {
    
    var location: String?
    
    func log(time: Date, level: LogLevel, location: String, message: @autoclosure () -> String) {
        self.location = location
    }
}
