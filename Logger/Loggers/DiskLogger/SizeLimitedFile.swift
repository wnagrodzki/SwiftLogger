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

protocol FileFactory {
    func makeInstance(forWritingTo: URL) throws -> OSFileHandle
}

/// Write failed as allowed size limit would be exceeded.
public struct SizeLimitedFileQuotaReached: Error {}

/// Allows writing to a file while respecting allowed size limit.
protocol SizeLimitedFile {
    
    /// Synchronously writes `data` at the end of the file.
    ///
    /// - Parameter data: The data to be written.
    /// - Throws: Throws an error if no free space is left on the file system, or if any other writing error occurs.
    ///           Throws `SizeLimitedFileQuotaReached` if allowed size limit would be exceeded.
    func write(_ data: Data) throws
    
    /// Writes all in-memory data to permanent storage and closes the file.
    func synchronizeAndCloseFile()
}

/// Allows writing to a file while respecting allowed size limit.
final class SizeLimitedFileImpl {
    
    private let file: OSFileHandle
    private let sizeLimit: UInt64
    private var currentSize: UInt64
    
    /// Initializes new SizeLimitedFileImpl instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the file.
    ///   - fileSizeLimit: Maximum size the file can reach in bytes.
    /// - Throws: An error that may occur while the file is being opened for writing.
    init(fileURL: URL, fileSizeLimit: UInt64, fileFactory: FileFactory) throws {
        file = try fileFactory.makeInstance(forWritingTo: fileURL)
        self.sizeLimit = fileSizeLimit
        currentSize = file.seekToEndOfFile()
    }
}

extension SizeLimitedFileImpl: SizeLimitedFile {
    
    func write(_ data: Data) throws {
        let dataSize = UInt64(data.count)
        guard currentSize + dataSize <= sizeLimit else {
            throw SizeLimitedFileQuotaReached()
        }
        try file.swift_write(data)
        currentSize += dataSize
    }
    
    func synchronizeAndCloseFile() {
        file.synchronizeFile()
        file.closeFile()
    }
}
