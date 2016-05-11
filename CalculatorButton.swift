//
//  CalculatorButton.swift
//  Calculator
//
//  Created by jeff greenberg on 5/11/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

// class exists so that the calculator can inspect button all button events

protocol CalcEntryMode {
    func setEntryModeNormal()
    func isEntryModeNormal() -> Bool
}


import UIKit

class CalculatorButton: UIButton {
    var delegate:CalcEntryMode?
    override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
        if !(self is CalculatorDigits) {
            if delegate != nil {
                if !delegate!.isEntryModeNormal() { 
                    delegate?.setEntryModeNormal()
                    return 
                }
            }
        }
        super.sendAction(action, to: target, forEvent: event)
    }
}

