//
//  UIShiftableButton.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/6/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//

import UIKit

class UIShiftableButton: UIButton {
    var customState:UIControlState = .Normal
    func setShifted(shift:Bool) {
        if shift {
            customState.insert(.Shifted)
        } else {
            customState.remove(.Shifted)
        }
        stateWasUpdated()
    }
    
    override var state: UIControlState {
        get {
            return [super.state, customState]
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
}