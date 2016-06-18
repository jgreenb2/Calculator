//
//  CircularBuffer.swift
//  circular buffer suitable for managing undo/redo
//
//  Created by Jeff Greenberg on 5/6/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

import Foundation
class CircularBuffer<T> {
    private var pEnd:Int
    private var pCur:Int
    private var size:Int
    private var stack:[T?]
    
    
    init(N: Int) {
        pEnd = -1
        pCur = -1
        size = N
        stack = [T?](repeating: nil, count: N)
        stack.reserveCapacity(N)
    }
    
    func add(_ item: T) {
        pEnd = inc(pCur)
        pCur = pEnd
        stack[pEnd]=item
    }
    
    func next() -> T? {
        guard (pCur != pEnd) else {
            return nil
        }
        
        pCur = inc(pCur)
        return stack[pCur]
    }
    
    func prev() -> T? {
        guard (dec(pCur) != pEnd && pCur >= 0 && stack[dec(pCur)] != nil ) else {
            return nil
        }
        
        pCur = dec(pCur)
        return stack[pCur]
    }
    
    func cur() -> T? {
        return stack[pCur]
    }
    
    func clear() {
        pEnd = -1
        pCur = -1
        stack = [T?](repeating: nil, count: size)
    }
    
    private func inc(_ i: Int) -> Int {
        return (i + 1) % size
    }
    
    private func dec(_ i: Int) -> Int {
        if (i - 1) < 0 {
            return size-1
        } else {
            return i - 1
        }
    }
}
