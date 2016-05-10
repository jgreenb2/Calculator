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
   
    @IBOutlet weak var shiftButton: UIShiftableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeShiftButtonStates()
        shiftButton.setTitle("\u{21EA}", forState: [.ShiftLocked, .Shifted])    // UPWARDS WHITE ARROW FROM BAR
        shiftButton.setTitle("\u{21E7}", forState: .Normal)                     // UPWARDS WHITE ARROW
        shiftButton.setTitleColor(UIColor.redColor(), forState: [.ShiftLocked, .Shifted]) 
    }
    
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
    
    var degMode = true
    @IBAction func degRadMode(sender: RoundedButton) {
        degMode = !degMode
        brain.degMode(degMode)
        if degMode {
            sender.setTitle("Deg", forState: .Normal)
        } else {
            sender.setTitle("Rad", forState: .Normal)
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
        var operation:String?
        if sender.state.contains(.Shifted) {
            operation = sender.titleForState(.Shifted)
        } else {
            operation = sender.currentTitle
        }
        displayValue = brain.performOperation(operation!)
        if !shiftButton.shiftLocked {
            shiftedState=false
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
    
    let shiftLabels:[String:String]=["cos":"acos", "sin":"asin", "tan":"atan", "⤾":"⤿"]
    
    var shiftedState = false {
        didSet {
            setButtonsToShifted(shiftedState)
            if !shiftedState {
                 shiftButton.setShiftLocked(false)
            }
        }
    }
    
    // delay the single tap for a short interval in case the user is 
    // actually doing a double tap. Then toggle the shift state.
    @IBAction func shiftOnSingleTap(sender: UIShiftableButton) {
        performSelector(#selector(self.toggleShift), withObject: nil, afterDelay: 0.25)
    }
    
    func toggleShift() {
        shiftedState = !shiftedState
    }
    
    // if there's a double tap, cancel the previous single tap and lock the
    // shift button down.
    @IBAction func shiftLock(sender: UIShiftableButton, forEvent event: UIEvent) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        shiftedState = true
        shiftButton.setShiftLocked(shiftedState)
    }
    
    func setButtonsToShifted(shift:Bool) {
        for v in view.subviews {
            if let sb = v as? UIShiftableButton {
                sb.setShifted(shift)
            }
        }
    }
    
    func initializeShiftButtonStates() {
        for v in view.subviews {
            if let sb = v as? UIShiftableButton {
                sb.setTitleColor(UIColor.redColor(), forState: .Shifted)
                sb.setShifted(false)
                
                if let titleText = sb.titleLabel?.text {
                    if let shiftedLabel = shiftLabels[titleText] {
                        sb.setTitle(shiftedLabel, forState: .Shifted)
                    }
                }
            }
        }
    }
    
    @IBAction func undo() {
        if shiftedState {
            if let newVal = brain.redo() {
                displayValue = newVal
            }
        } else {
            if let newVal = brain.undo() {
                displayValue = newVal
            }
        }
        if !shiftButton.shiftLocked {
            shiftedState=false
        }

    }
    
    
    private enum formatMode {
        case fixed(Int)
        case sci(Int)
    }

    private var outputFormat:formatMode = formatMode.fixed(2)
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
                display.text = formatDouble(v, format: outputFormat)
                userIsInTheMiddleOfTypingANumber = false
            } else {
                display.text = "0.0"
            }
            history.text = brain.description + "="
        }
    }
    
    private func formatDouble(val: Double, format: formatMode) -> String {
        var output:String
        switch format {
            case .fixed(let digits):
                let formatter = NSNumberFormatter()
                formatter.numberStyle = .DecimalStyle
                formatter.maximumFractionDigits = digits
                formatter.minimumFractionDigits = digits
                formatter.maximumIntegerDigits = 16 - digits
                formatter.roundingMode = .RoundHalfDown
                if let s = formatter.stringFromNumber(val) {
                    output = s
                } else {
                    output = "####"
                }
            case .sci(let digits):
                output = "\(val)"
        }
        return output
    }
}
