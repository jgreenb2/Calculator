//
//  CalculatorButtons.swift
//  Calculator
//
//  Created by jeff greenberg on 5/11/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

// various button classes used for the calculator keys

protocol ButtonEventInspection {
    func actionShouldNotBePerformed(action: Selector, from source: AnyObject?, to target: AnyObject?, forEvent event: UIEvent? ) -> Bool
}

import UIKit
@IBDesignable
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

@IBDesignable
class RoundedButton: CalculatorButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var sizeTextToFit: Bool = false {
        didSet {
            let label = self.titleLabel
            label?.minimumScaleFactor = 0.5
            label?.adjustsFontSizeToFitWidth = sizeTextToFit
            label?.setNeedsDisplay()
        }
    }
}

@IBDesignable
class CalculatorDigits: RoundedButton {    
}

@IBDesignable
class ShiftableButton: CalculatorButton {
    var customState:UIControlState = .Normal
    func setShifted(shift:Bool) {
        if shift {
            customState.insert(.Shifted)
        } else {
            customState.remove(.Shifted)
        }
        stateWasUpdated()
    }
    
    func setShiftLocked(shiftLocked:Bool) {
        if shiftLocked {
            customState.insert(.ShiftLocked)
        } else {
            customState.remove(.ShiftLocked)
        }
        stateWasUpdated()
    }
    
    override var state: UIControlState {
        get {
            return [super.state, customState]
        }
    }
    
    var shiftLocked:Bool {
        get {
            return state.contains(.ShiftLocked)
        }
    }
    
    var shifted:Bool {
        get {
            return state.contains(.Shifted)
        }
    }
    
    func stateWasUpdated() {
        setNeedsLayout()
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var sizeTextToFit: Bool = false {
        didSet {
            let label = self.titleLabel
            label?.minimumScaleFactor = 0.5
            label?.adjustsFontSizeToFitWidth = sizeTextToFit
            label?.setNeedsDisplay()
        }
    }    
}

public extension UIControlState {
    static let Shifted = UIControlState(rawValue: 1<<16)
    static let ShiftLocked = UIControlState(rawValue: 1<<17)
}