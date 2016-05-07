//
//  FixedLengthStack.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/6/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

import Foundation
class FixedLengthStack<T> {
    private var pWrite:Int
    private var pRead:Int
    private var size:Int
    private var stack:[T?]
    
    
    init(N: Int) {
        pWrite = -1
        pRead = -1
        size = N
        stack = [T?](count: N, repeatedValue: nil)
        stack.reserveCapacity(N)
    }
    
    func add(item: T) {
        pWrite = inc(pWrite)
        pRead = pWrite
        stack[pWrite]=item
    }
    
    func next() -> T? {
        if (pRead == pWrite) {
            return nil
        }
        pRead = inc(pRead)
        return stack[pRead]
    }
    
    func prev() -> T? {
        if (dec(pRead) == pWrite || pRead < 0 || stack[dec(pRead)]==nil ) {
            return nil
        }
        pRead = dec(pRead)
        return stack[pRead]
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