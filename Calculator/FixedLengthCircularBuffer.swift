//
//  FixedLengthCircularBuffer.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/6/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

import Foundation
class FixedLengthCircularBuffer<T> {
    private var pWrite:Int
    private var pos:Int
    private var size:Int
    private var stack:[T?]
    
    
    init(N: Int) {
        pWrite = -1
        pos = -1
        size = N
        stack = [T?](count: N, repeatedValue: nil)
        stack.reserveCapacity(N)
    }
    
    func add(item: T) {
        pWrite = inc(pos)
        pos = pWrite
        stack[pWrite]=item
    }
    
    func next() -> T? {
        if (pos == pWrite) {
            return nil
        }
        pos = inc(pos)
        return stack[pos]
    }
    
    func prev() -> T? {
        if (dec(pos) == pWrite || pos < 0 || stack[dec(pos)]==nil ) {
            return nil
        }
        pos = dec(pos)
        return stack[pos]
    }
    
    func cur() -> T? {
        return stack[pos]
    }
    
    func clear() {
        pWrite = -1
        pos = -1
        stack = [T?](count: size, repeatedValue: nil)
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