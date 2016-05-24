//
//  UndoBuffer.swift
//  circular buffer suitable for managing undo/redo. The semantics are part stack and part ring buffer.
//  Access wraps like a ring buffer. However the current write position is always set to the position after
//  the last read.
//
//  Created by Jeff Greenberg on 5/6/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

import Foundation
class UndoBuffer<T> {
    private var pWrite:Int
    private var pRead:Int
    private var size:Int
    private var buffer:[T?]
    
    
    init(N: Int) {
        pWrite = -1
        pRead = -1
        size = N
        buffer = [T?](count: N, repeatedValue: nil)
        buffer.reserveCapacity(N)
    }
    
    func add(item: T) {
        pWrite = inc(pRead)
        pRead = pWrite
        buffer[pWrite]=item
    }
    
    func next() -> T? {
        guard (pRead != pWrite) else {
            return nil
        }
        
        pRead = inc(pRead)
        return buffer[pRead]
    }
    
    func prev() -> T? {
        guard (dec(pRead) != pWrite && pRead >= 0 && buffer[dec(pRead)] != nil ) else {
            return nil
        }
        
        pRead = dec(pRead)
        return buffer[pRead]
    }
    
    func cur() -> T? {
        return buffer[pRead]
    }
    
    func clear() {
        pWrite = -1
        pRead = -1
        buffer = [T?](count: size, repeatedValue: nil)
    }
    
    private func inc(i: Int) -> Int {
        return (i + 1) % size
    }
    
    private func dec(i: Int) -> Int {
        if (i - 1) < 0 {
            return size-1
        } else {
            return i - 1
        }
    }
}