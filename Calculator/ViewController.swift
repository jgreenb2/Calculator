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
    var userIsInTheMiddleOfTypingANumber = false
    var decimalPointEntered = false
    @IBOutlet weak var history: UILabel!
    
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
    
    var operandStack = Array<Double>()

    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        operandStack.append(displayValue)
        history.text = history.text! + "\(displayValue)\n"
        println("operandStack = \(operandStack)")
    }
    
    @IBAction func operate(sender: UIButton) {
        let operation = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        history.text = history.text! + operation + "\n"
        switch operation {
            case "×":
                performOperation {$1 * $0}
            case "÷":
                performOperation {$1 / $0}
            case "+":
                performOperation {$1 + $0}
            case "−":
                performOperation {$1 - $0}
            case "√": performOperation { sqrt($0) }
            case "sin":
                performOperation { sin($0) }
            case "cos":
                performOperation { cos($0) }
            case "π":
                displayValue = M_PI
                enter()
            case "C":
                history.text = ""
                display.text = "0"
                operandStack.removeAll(keepCapacity: false)
        default: break
        }
    }
    
    private func performOperation(operation: (Double, Double) -> Double) {
        if operandStack.count >= 2 {
            displayValue = operation(operandStack.removeLast(),operandStack.removeLast())
            enter()
        }
    }
    
    private func performOperation(operation: Double -> Double) {
        if operandStack.count >= 1 {
            displayValue = operation(operandStack.removeLast())
            enter()
        }
    }
    
    var displayValue: Double {
        get {
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            display.text = "\(newValue)"
            userIsInTheMiddleOfTypingANumber = false
        }
    }
}
