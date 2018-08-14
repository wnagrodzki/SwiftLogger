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

final class Logrotate {
    private let fileURL: URL
    private let rotations: Int
    
    init(fileURL: URL, rotations: Int) {
        precondition(rotations > 0)
        self.fileURL = fileURL
        self.rotations = rotations
    }
    
    func rotate() throws {
        let range = 1...rotations
        let pathExtensions = range.map { "\($0)" }
        let rotatedURLs = pathExtensions.map { fileURL.appendingPathExtension($0) }
        let allURLs = [fileURL] + rotatedURLs
        
        let toDelete = rotatedURLs.last!
        let toMove = zip(allURLs, rotatedURLs).reversed()
        
        if FileManager.default.fileExists(atPath: toDelete.path) {
            try FileManager.default.removeItem(at: toDelete)
        }
        for (oldURL, newURL) in toMove {
            guard FileManager.default.fileExists(atPath: oldURL.path) else { continue }
            try FileManager.default.moveItem(at: oldURL, to: newURL)
        }
    }
}
