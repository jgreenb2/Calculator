//
//  CalculatorButtons.swift
//  Calculator
//
//  Created by jeff greenberg on 5/11/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

// various button classes used for the calculator keys

protocol ButtonEventInspection: class {
    func actionShouldNotBePerformed(_ action: Selector, from source: AnyObject?, to target: AnyObject?, forEvent event: UIEvent? ) -> Bool
}

import UIKit
@IBDesignable
class CalculatorButton: UIButton {
    weak var delegate:ButtonEventInspection?
    
    // catch all actions and check with the delegate to see
    // if it should be performed
    override func sendAction(_ action: Selector, to target: AnyObject?, for event: UIEvent?) {
        if delegate != nil {
            if delegate!.actionShouldNotBePerformed(action, from: self, to: target, forEvent: event) {
                return
            }
        }
        super.sendAction(action, to: target, for: event)
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

class CalculatorDigits: CalculatorButton {    
}

class ShiftableButton: CalculatorButton {
    var customState:UIControlState = UIControlState()
    func setShifted(_ shift:Bool) {
        if shift {
            _ = customState.insert(.Shifted)
        } else {
            customState.remove(.Shifted)
        }
        stateWasUpdated()
    }
    
    func setShiftLocked(_ shiftLocked:Bool) {
        if shiftLocked {
            _ = customState.insert(.ShiftLocked)
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
}

public extension UIControlState {
    static let Shifted = UIControlState(rawValue: 1<<16)
    static let ShiftLocked = UIControlState(rawValue: 1<<17)
}
