//
//  CalculatorButton.swift
//  Calculator
//
//  Created by jeff greenberg on 5/11/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

// class exists so that the calculator can inspect all button events

protocol ButtonEventInspection {
    func actionShouldNotBePerformed(action: Selector, from source: AnyObject?, to target: AnyObject?, forEvent event: UIEvent? ) -> Bool
}

import UIKit

class CalculatorButton: UIButton {
    var delegate:ButtonEventInspection?
    
    // catch all actions make sure that only a digit key can
    // be pressed in format mode.
    override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
        if delegate != nil {
            if delegate!.actionShouldNotBePerformed(action, from: self, to: target, forEvent: event) {
                return
            }
        }
        super.sendAction(action, to: target, forEvent: event)
    }
}