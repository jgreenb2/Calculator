//
//  ViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/30/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit


class CalculatorViewController: UIViewController {
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        displayValue = brain.loadProgram()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        brain.saveProgram()
    }
    
    @IBOutlet weak var display: UILabel! {
        didSet { 
            display.layer.cornerRadius=8
            display.adjustsFontSizeToFitWidth = true
            display.minimumScaleFactor=0.8
        }
    }
    @IBOutlet weak var history: UILabel!
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            if digit == "."  && display.text!.rangeOfString(".") != nil {
                return
            }
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
            displayValue = brain.changeSign()!
        }
    }
    
    @IBAction func backspace() {
        if userIsInTheMiddleOfTypingANumber {
            switch (display.text!).characters.count {
                case 1:
                    displayValue=0
                default:
                    //display.text = String(dropLast((display.text!).characters))
                    display.text = String((display.text!).characters.dropLast())
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
        displayValue = brain.setVariable("M", value: displayValue)
    }

    @IBAction func memGet() {
        if userIsInTheMiddleOfTypingANumber {
            userIsInTheMiddleOfTypingANumber=false
            enter()
        }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if displayValue != nil {
            displayValue = brain.pushOperand(displayValue!)
        }
    }
    
    @IBAction func swapXY() {
        if userIsInTheMiddleOfTypingANumber {
            userIsInTheMiddleOfTypingANumber=false
            enter()
        }
        brain.swapXY()
        displayValue = brain.evaluate()
    }
    
    private struct ShiftKeyLabels {
        struct UnShifted {
            static let cos = "cos"
            static let sin = "sin"
            static let tan = "tan"
            static let undo = "⤾"
        }
        struct Shifted {
            static let cos = "acos"
            static let sin = "asin"
            static let tan = "atan"
            static let undo = "⤿"
        }
    }
    
    var shiftedState = false
    @IBAction func shiftMode(sender: AnyObject) {

        let shiftButton = sender as! UIButton
        if shiftedState {
            shiftedState = false
            shiftButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        } else {
            shiftedState = true
            shiftButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        }
    }
    
    @IBAction func undo() {
        displayValue = brain.undo()
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
                display.text = "0.0"
            }
            history.text = brain.description + "="
        }
    }
}
