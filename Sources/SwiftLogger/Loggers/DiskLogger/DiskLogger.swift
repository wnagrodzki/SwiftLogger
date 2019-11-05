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

protocol SizeLimitedFileFactory {
    
    /// Returns newly initialized SizeLimitedFile instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the file.
    ///   - fileSizeLimit: Maximum size the file can reach in bytes.
    /// - Throws: An error that may occur while the file is being opened for writing.
    func makeInstance(fileURL: URL, fileSizeLimit: UInt64) throws -> SizeLimitedFile
}

protocol LogrotateFactory {
    
    /// Returns newly initialized Logrotate instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the log file.
    ///   - rotations: Number of times log files are rotated before being removed.
    func makeInstance(fileURL: URL, rotations: Int) -> Logrotate
}

/// Logger that writes messages into the file at specified URL with log rotation support.
@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class DiskLogger: Logger {
    
    private let fileURL: URL
    private let fileSizeLimit: UInt64
    private let rotations: Int
    private let fileManager: OSFileManager
    private let sizeLimitedFileFactory: SizeLimitedFileFactory
    private let logrotateFactory: LogrotateFactory
    private let formatter: DateFormatter
    private let queue = DispatchQueue(label: "com.wnagrodzki.DiskLogger", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    private var buffer = Data()
    private var sizeLimitedFile: SizeLimitedFile!
    
    /// Initializes new DiskLogger instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the log file.
    ///   - fileSizeLimit: Maximum size log file can reach in bytes. Attempt to exceeding that limit triggers log files rotation.
    ///   - rotations: Number of times log files are rotated before being removed.
    public convenience init(fileURL: URL, fileSizeLimit: UInt64, rotations: Int) {
        self.init(fileURL: fileURL, fileSizeLimit: fileSizeLimit, rotations: rotations, fileManager: FileManager.default, sizeLimitedFileFactory: SizeLimitedFileFactoryImpl(),  logrotateFactory: LogrotateFactoryImpl())
    }
    
    init(fileURL: URL, fileSizeLimit: UInt64, rotations: Int, fileManager: OSFileManager, sizeLimitedFileFactory: SizeLimitedFileFactory, logrotateFactory: LogrotateFactory) {
        self.fileURL = fileURL
        self.fileSizeLimit = fileSizeLimit
        self.rotations = rotations
        self.fileManager = fileManager
        self.sizeLimitedFileFactory = sizeLimitedFileFactory
        self.logrotateFactory = logrotateFactory
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
                try self.openSizeLimitedFile()
                do {
                    try self.writeBuffer()
                }
                catch is SizeLimitedFileQuotaReached {
                    try self.closeSizeLimitedFile()
                    try self.rotateLogFiles()
                    try self.openSizeLimitedFile()
                    try self.writeBuffer()
                }
            }
            catch {
                let message = self.formatter.string(from: Date()) + " <" + LogLevel.warning.logDescription + "> " + String(describing: error) + "\n"
                let data = Data(message.utf8)
                self.buffer.append(data)
            }
        }
    }
    
    private func openSizeLimitedFile() throws {
        guard sizeLimitedFile == nil else { return }
        if fileManager.itemExists(at: fileURL) == false {
            _ = fileManager.createFile(at: fileURL)
        }
        sizeLimitedFile = try sizeLimitedFileFactory.makeInstance(fileURL: fileURL, fileSizeLimit: fileSizeLimit)
    }
    
    private func writeBuffer() throws {
        try sizeLimitedFile.write(buffer)
        buffer.removeAll()
    }
    
    private func closeSizeLimitedFile() throws {
        try self.sizeLimitedFile.synchronizeAndCloseFile()
        self.sizeLimitedFile = nil
    }
    
    private func rotateLogFiles() throws {
        let logrotate = logrotateFactory.makeInstance(fileURL: fileURL, rotations: rotations)
        try logrotate.rotate()
    }
}

private class LogrotateFactoryImpl: LogrotateFactory {
    func makeInstance(fileURL: URL, rotations: Int) -> Logrotate {
        return LogrotateImpl(fileURL: fileURL, rotations: rotations, fileManager: FileManager.default)
    }
}

private class SizeLimitedFileFactoryImpl: SizeLimitedFileFactory {
    func makeInstance(fileURL: URL, fileSizeLimit: UInt64) throws -> SizeLimitedFile {
        return try SizeLimitedFileImpl(fileURL: fileURL, fileSizeLimit: fileSizeLimit, fileFactory: FileHandleFactoryImpl())
    }
}

private class FileHandleFactoryImpl: FileHandleFactory {
    func makeInstance(forWritingTo: URL) throws -> OSFileHandle {
        return try FileHandle(forWritingTo: forWritingTo)
    }
}
