//
//  CalculatorViews.swift
//  Calculator
//
//  Created by jeff greenberg on 6/19/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//
// a variety of view classes used the calculator front panel
// mostly here so I can set @IBInspectable properties

import UIKit
@IBDesignable
class MainNumericalDisplay: UILabel {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }

}

@IBDesignable
class RoundedButtons: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}
