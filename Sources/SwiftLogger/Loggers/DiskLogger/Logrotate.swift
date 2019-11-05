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

/// Allows log files rotation.
protocol Logrotate {
    
    /// Rotates log files `rotations` number of times.
    ///
    /// First deletes file at `<fileURL>.<rotations>`.
    /// Next moves files located at:
    ///
    /// `<fileURL>, <fileURL>.1, <fileURL>.2 ... <fileURL>.<rotations - 1>`
    ///
    /// to `<fileURL>.1, <fileURL>.2 ... <fileURL>.<rotations>`
    func rotate() throws
}

final class LogrotateImpl {
    
    private let fileURL: URL
    private let rotations: Int
    private let fileManager: OSFileManager
    
    /// Initializes new Logrotate instance.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the log file.
    ///   - rotations: Number of times log files are rotated before being removed.
    init(fileURL: URL, rotations: Int, fileManager: OSFileManager) {
        precondition(rotations > 0)
        self.fileURL = fileURL
        self.rotations = rotations
        self.fileManager = fileManager
    }
}

extension LogrotateImpl: Logrotate {
    
    func rotate() throws {
        let range = 1...rotations
        let pathExtensions = range.map { "\($0)" }
        let rotatedURLs = pathExtensions.map { fileURL.appendingPathExtension($0) }
        let allURLs = [fileURL] + rotatedURLs
        
        let toDelete = rotatedURLs.last!
        let toMove = zip(allURLs, rotatedURLs).reversed()
        
        if fileManager.itemExists(at: toDelete) {
            try fileManager.removeItem(at: toDelete)
        }
        for (oldURL, newURL) in toMove {
            guard fileManager.itemExists(at: oldURL) else { continue }
            try fileManager.moveItem(at: oldURL, to: newURL)
        }
    }
}
