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

public protocol Logger {
    func log(time: String, level: LogLevel, location: String, object: String)
    
    func description(for date: Date) -> String
    func description(for file: String, line: Int, function: String) -> String
    func description(for object: Any) -> String
}

public enum LogLevel: String {
    case `default` = "Default"
    case info = "Info"
    case debug = "Debug"
    case error = "Error"
    case fault = "Fault"
}

extension Logger {
    public func log(_ object: Any, level: LogLevel = .default, file: String = #file, line: Int = #line, function: String = #function) {
        let now = Date()
        let time = description(for: now)
        let location = description(for: file, line: line, function: function)
        let objectDescription = description(for: object)
        log(time: time, level: level, location: location, object: objectDescription)
    }
    
    public func description(for date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    public func description(for file: String, line: Int, function: String) -> String {
        return filename(fromFilePath: file) + ":\(line) \(function)"
    }
    
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
