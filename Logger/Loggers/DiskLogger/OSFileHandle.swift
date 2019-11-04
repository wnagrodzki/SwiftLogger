//
//  OSFileHandle.swift
//  Logger
//
//  Created by Wojciech Nagrodzki on 30/10/2019.
//  Copyright © 2019 Wojciech Nagrodzki. All rights reserved.
//

import Foundation

protocol OSFileHandle {
    func osSeekToEndOfFile() throws -> UInt64
    func osWrite(_ data: Data) throws
    func osSynchronizeFile() throws
    func osCloseFile() throws
}

extension FileHandle: OSFileHandle {
    
    func osSeekToEndOfFile() throws -> UInt64 {
        if #available(iOS 13.0, *) {
            var offsetInFile: UInt64 = 0
            try __seek(toEndReturningOffset:&offsetInFile)
            return offsetInFile
        } else {
            fatalError()
        }
    }
    
    func osWrite(_ data: Data) throws {
        if #available(iOS 13.0, *) {
            try __write(data, error: ())
        } else {
            fatalError()
        }
    }
    
    func osSynchronizeFile() throws {
        if #available(iOS 13.0, *) {
            try synchronize()
        } else {
            fatalError()
        }
    }
    
    func osCloseFile() throws {
        if #available(iOS 13.0, *) {
            try close()
        } else {
            fatalError()
        }
    }
}
