//
//  CalculatorViews.swift
//  Calculator
//
//  Created by jeff greenberg on 6/19/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
@IBDesignable
class CalculatorDisplay: UILabel {
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

    @IBInspectable var rightInset: CGFloat=0
    override func drawTextInRect(rect: CGRect) {
        let inset = UIEdgeInsetsMake(0, 0, 0, rightInset)
        return super.drawTextInRect(UIEdgeInsetsInsetRect(rect, inset))
    }
}
