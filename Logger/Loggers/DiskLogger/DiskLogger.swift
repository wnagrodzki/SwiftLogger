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

/// Logger that writes messages into the file at specified URL with log rotation support.
public final class DiskLogger: Logger {
    
    private let fileURL: URL
    private let fileSizeLimit: UInt64
    private let rotations: Int
    private let formatter: DateFormatter
    private let queue = DispatchQueue(label: "com.wnagrodzki.DiskLogger", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    private var buffer = Data()
    private var fileWriter: FileWriter!
    
    /// Initializes new DiskLogger instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the log file.
    ///   - fileSizeLimit: Maximum size log file can reach in bytes. Attempt to exceeding that limit triggers log files rotation.
    ///   - rotations: Number of times log files are rotated before being removed.
    public init(fileURL: URL, fileSizeLimit: UInt64, rotations: Int) {
        self.fileURL = fileURL
        self.fileSizeLimit = fileSizeLimit
        self.rotations = rotations
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    
    public func log(time: Date, level: LogLevel, location: String, message: @autoclosure () -> String) {
        let message = formatter.string(from: time) + " <" + level.logDescription + "> " + location + " " + message() + "\n"
        log(message)
    }
    
    private func log(_ message: String) {
        let data = Data(message.utf8)
        queue.async {
            self.buffer.append(data)
            
            do {
                try self.openFileWriter()
                do {
                    try self.writeBuffer()
                }
                catch is FileWriter.FileSizeLimitReached {
                    self.closeFileWriter()
                    try self.rotateLogFiles()
                }
            }
            catch {
                let message = String(describing: error)
                self.log(message, level: .warning)
            }
        }
    }
    
    private func openFileWriter() throws {
        guard fileWriter == nil else { return }
        if FileManager.default.fileExists(atPath: fileURL.path) == false {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        fileWriter = try FileWriter(fileURL: fileURL, fileSizeLimit: fileSizeLimit)
    }
    
    private func writeBuffer() throws {
        try fileWriter.write(buffer)
        buffer.removeAll()
    }
    
    private func closeFileWriter() {
        self.fileWriter.synchronizeAndCloseFile()
        self.fileWriter = nil
    }
    
    private func rotateLogFiles() throws {
        let logrotate = Logrotate(fileURL: fileURL, rotations: rotations)
        try logrotate.rotate()
    }
}
