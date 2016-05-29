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
class RingBuffer<T> {
    private var pWrite:Int
    private var pRead:Int
    
    private var pBeg:Int
    private var pEnd:Int
    
    private var size:Int
    private var buffer:[T?]
    private var resetState = false
    
    
    
    init(N: Int) {
        pWrite = -1
        pRead = -1
        
        pBeg = 0
        pEnd = 0
        
        size = N
        buffer = [T?](count: N, repeatedValue: nil)
        buffer.reserveCapacity(N)
    }
    
    func addAtCurrentPosition(item: T) {
        pWrite = inc(pRead)
        pRead = pWrite
        pEnd = pWrite
        if pEnd <= pBeg { pBeg = inc(pBeg) }
        buffer[pWrite]=item
    }
    
    func appendToEnd(item: T) {
        pEnd = inc(pEnd)
        pBeg = inc(pBeg)
        pWrite = pEnd
        buffer[pWrite] = item
    }
    
    func reset() {
        guard pRead != -1 else { return }
        
        pRead = dec(pBeg)
        pWrite = pEnd
        resetState = true
    }
    
    func setToEnd() {
        self.reset()
        while self.next() != nil {}
    }
    
    func prependToBeginning(item: T) {
        pBeg = dec(pBeg)
        pEnd = dec(pEnd)
        pWrite = pBeg
        buffer[pWrite] = item
    }
    
    func next() -> T? {
        guard (pRead != pEnd || resetState) else {
            return nil
        }
        
        resetState = false
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
        guard pRead >= 0 else { return nil }
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
