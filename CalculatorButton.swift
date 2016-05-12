//
//  CalculatorButton.swift
//  Calculator
//
//  Created by jeff greenberg on 5/11/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

// class exists so that the calculator can inspect all button events

protocol CalcEntryMode {
    func setEntryModeNormal()
    func isEntryModeNormal() -> Bool
}


import UIKit

class CalculatorButton: UIButton {
    var delegate:CalcEntryMode?
    
    // catch all actions make sure that only a digit key can
    // be pressed in format mode.
    override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
        guard (self is CalculatorDigits) || (delegate?.isEntryModeNormal())! else {
            delegate?.setEntryModeNormal()
            return
        }
        super.sendAction(action, to: target, forEvent: event)
    }
}

