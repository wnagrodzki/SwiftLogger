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

class AgregateLoggerTests: XCTestCase {

    func testCallForwarding() {
        let loggerA = LoggerMock()
        let loggerB = LoggerMock()
        let agregateLogger = AgregateLogger(loggers: [loggerA, loggerB])
        agregateLogger.log("0", level: .emergency)
        agregateLogger.log("1", level: .alert)
        agregateLogger.log("2", level: .critical)
        agregateLogger.log("3", level: .error)
        agregateLogger.log("4", level: .warning)
        agregateLogger.log("5", level: .notice)
        agregateLogger.log("6", level: .informational)
        agregateLogger.log("7", level: .debug)
        XCTAssertEqual(loggerA, loggerB)
    }
}

private class LoggerMock: Logger {
    
    struct Log: Equatable {
        let time: Date
        let level: LogLevel
        let location: String
        let message: String
    }
    
    private var logs = [Log]()
    
    func log(time: Date, level: LogLevel, location: String, message: @autoclosure () -> String) {
        let log = Log(time: time, level: level, location: location, message: message())
        logs.append(log)
    }
}

extension LoggerMock: Equatable {
    
    static func == (lhs: LoggerMock, rhs: LoggerMock) -> Bool {
        return lhs.logs == rhs.logs
    }
}
