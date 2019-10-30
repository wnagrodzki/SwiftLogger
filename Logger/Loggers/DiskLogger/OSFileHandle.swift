//
//  OSFileHandle.swift
//  Logger
//
//  Created by Wojciech Nagrodzki on 30/10/2019.
//  Copyright © 2019 Wojciech Nagrodzki. All rights reserved.
//

import Foundation

protocol OSFileHandle {
    func seekToEndOfFile() -> UInt64
    func swift_write(_ data: Data) throws
    func synchronizeFile()
    func closeFile()
}

extension FileHandle: OSFileHandle {
    
    func swift_write(_ data: Data) throws {
        try __write(data, error: ())
    }
}
