//
//  ViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/30/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if digit=="."  && display.text!.rangeOfString(".") != nil { return }
        if userIsInTheMiddleOfTypingANumber {
            display.text = display.text! + digit
        } else {
            display.text = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    @IBAction func changeSign() {
        if userIsInTheMiddleOfTypingANumber {
            display.text = "-" + display.text!
        } else if abs(displayValue!) > 0.0 {
            displayValue = brain.performOperation("±")!

        }
    }
    
    @IBAction func backspace() {
        if userIsInTheMiddleOfTypingANumber {
            switch count(display.text!) {
                case 1:
                    displayValue=0
                default:
                    display.text = dropLast(display.text!)
            }
        } else if displayValue != 0 {
            displayValue = 0
            enter()
        }
    }
    
    @IBAction func clear() {
        brain.clear()
        displayValue=0
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
        }
    }

    @IBAction func memSet() {
        userIsInTheMiddleOfTypingANumber=false
        brain.setVariable("M", value: displayValue)
    }

    @IBAction func memGet() {
        if userIsInTheMiddleOfTypingANumber {
            userIsInTheMiddleOfTypingANumber=false
            //enter()
        }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if displayValue != nil {
            displayValue = brain.pushOperand(displayValue!)
        }
    }
    
    var displayValue: Double? {
        get {
            if let num=NSNumberFormatter().numberFromString(display.text!) {
                return num.doubleValue
            } else {
                return nil
            }
        }
        
        set {
            if let v = newValue {
                display.text = "\(v)"
                userIsInTheMiddleOfTypingANumber = false
            } else {
                display.text = " "
            }
            history.text = brain.description + "="
        }
    }
}
