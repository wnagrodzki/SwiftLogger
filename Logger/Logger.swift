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

import Foundation

/// A type able to build custom log message and send it to a logging system.
public protocol Logger {
    
    /// Builds log a message from passed parameters and sends it to the logging system.
    ///
    /// Do not call this method directly.
    ///
    /// - Parameters:
    ///   - time: The date log method was called.
    ///   - level: The log level.
    ///   - location: Part of the log message provided by `description(for file: String, line: Int, function: String)` method.
    ///   - object: Part of the log message provided by `description(for object: Any)` method.
    func log(time: Date, level: LogLevel, location: String, object: String)
    
    /// Transforms passed parameters into location textual representation which will be a part of the log message.
    ///
    /// Customization point. Default implementation returns location in format `"<file name>:<line> <function>"`,
    ///
    /// - Parameters:
    ///   - file: The path to the file log method was called from.
    ///   - line: The line number log method was called at.
    ///   - function: The name of the declaration log method was called within.
    func description(for file: String, line: Int, function: String) -> String
    
    /// Transforms `object` into textual representation which will be a part of the log message.
    ///
    /// Customization point. Default implementation returns `logDescription` for objects implementing `LogStringConvertible`,
    /// or `String(describing:object)` otherwise.
    ///
    /// - Parameter object: The object to be logged.
    func description(for object: Any) -> String
}

/// Log level controls the conditions under which a message should be logged.
public enum LogLevel: Int {
    
    /// Use this level to capture information about things that might result a failure.
    case `default`
    
    /// Use this level to capture information that may be helpful, but isn’t essential, for troubleshooting errors.
    case info
    
    /// Use this level to capture information that may be useful during development or while troubleshooting a specific problem.
    case debug
    
    /// Use this log level to capture process-level information to report errors in the process.
    case error
    
    /// Use this level to capture system-level or multi-process information to report system errors.
    case fault
}

extension LogLevel: LogStringConvertible {
    
    public var logDescription: String {
        switch self {
        case .default: return "Default"
        case .info: return "Info"
        case .debug: return "Debug"
        case .error: return "Error"
        case .fault: return "Fault"
        }
    }
}

extension Logger {
    
    /// Sends object to the logging system, optionally specifying a custom log level.
    ///
    /// - Parameters:
    ///   - object: The object to be logged.
    ///   - level: The log level. If unspecified, the `default` log level is used.
    ///   - file: **Do not provide a custom value.** The path to the file log method is called from.
    ///   - line: **Do not provide a custom value.** The line number log method is called at.
    ///   - function: **Do not provide a custom value.** The name of the declaration log method is called within.
    public func log(_ object: Any, level: LogLevel = .default, file: String = #file, line: Int = #line, function: String = #function) {
        let now = Date()
        let location = description(for: file, line: line, function: function)
        let objectDescription = description(for: object)
        log(time: now, level: level, location: location, object: objectDescription)
    }
        
    /// Returns location in format `"<file name>:<line> <function>"`.
    public func description(for file: String, line: Int, function: String) -> String {
        return filename(fromFilePath: file) + ":\(line) \(function)"
    }
    
    /// Returns `logDescription` for objects implementing `LogStringConvertible`, or `String(describing:object)` otherwise.
    public func description(for object: Any) -> String {
        if let logStringConvertible = object as? LogStringConvertible {
            return logStringConvertible.logDescription
        }
        return String(describing: object)
    }
    
    private func filename(fromFilePath path: String) -> String {
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
}
