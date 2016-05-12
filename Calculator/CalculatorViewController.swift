//
//  ViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/30/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
protocol propertyListReadable {
    associatedtype ValueType
    func propertyListRepresentation() -> Dictionary<String, ValueType>
    init?(propertyListRepresentation:Dictionary<String, ValueType>)
}

class CalculatorViewController: UIViewController, CalcEntryMode {
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
   
    @IBOutlet weak var shiftButton: UIShiftableButton!
    @IBOutlet weak var formatButton: UIShiftableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        displayValue = brain.loadProgram()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        brain.saveProgram()
    }
    
    private struct DefaultKeys {
        static let fixSciKey = "_fixSciKey_"
    }
    
    private func loadDisplayModes() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let format = defaults.objectForKey(DefaultKeys.fixSciKey) as? formatMode {
            outputFormat = format
        }
    }
    
    private func saveDisplayModes() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(<#T##value: AnyObject?##AnyObject?#>, forKey: <#T##String#>)
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
        switch entryMode {
            case .FormatFix:
                outputFormat = formatMode.Fixed(Int(sender.titleLabel!.text!)!)
                displayValue = displayRegister
                entryMode = digitEntryModes.Normal
            case .FormatSci:
                outputFormat = formatMode.Sci(Int(sender.titleLabel!.text!)!)
                displayValue = displayRegister
                entryMode = digitEntryModes.Normal
                shiftedState = false
            case .Normal:
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
        if userIsInTheMiddleOfTypingANumber {
            displayValue = brain.setVariable("M", value: displayValue)
        } else {
            displayValue = brain.setVariable("M", value: displayRegister)
        }
        userIsInTheMiddleOfTypingANumber=false
    }

    @IBAction func memGet() {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func enter() {
        if displayValue != nil {
            displayValue = brain.pushOperand(displayValue!)
        }
        userIsInTheMiddleOfTypingANumber = false
    }
    
    @IBAction func swapXY() {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        brain.swapXY()
        displayValue = brain.evaluate()
    }
    
    let shiftLabels:[String:String]=["cos":"acos", "sin":"asin", "tan":"atan", "⤾":"⤿","Fix":"Sci"]
    
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
    
    func initializeButtons() {
        initializeShiftButtonStates()
        setCalcButtonDelegates()
        shiftButton.setTitle("\u{21EA}", forState: [.ShiftLocked, .Shifted])    // UPWARDS WHITE ARROW FROM BAR
        shiftButton.setTitle("\u{21E7}", forState: .Normal)                     // UPWARDS WHITE ARROW
        shiftButton.setTitleColor(UIColor.redColor(), forState: [.ShiftLocked, .Shifted]) 
    }
    
    func setCalcButtonDelegates() {
        for v in view.subviews {
            if let cb = v as? CalculatorButton {
                cb.delegate = self
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

    
    private enum formatMode: propertyListReadable {
        case Fixed(Int)
        case Sci(Int)
        
        func propertyListRepresentation() -> [String:Int] {
            switch self {
                case .Fixed(let f):
                    return ["Fixed":f]
                case .Sci(let s):
                    return ["Sci":s]
            }
        }
        
        init?(propertyListRepresentation:[String:Int]?) {
            guard let val=propertyListRepresentation else {return nil}
            let (s,v) = val.first!
            switch s {
                case "Fixed":
                    self = formatMode.Fixed(v)
                case "Sci":
                    self = formatMode.Sci(v)
            }
        }
    }
    
    private enum digitEntryModes {
        case FormatFix
        case FormatSci
        case Normal
    }
    
    lazy var formatButtonBackgroundColor:UIColor={self.formatButton.backgroundColor!}()
    private var entryMode:digitEntryModes = digitEntryModes.Normal {
        didSet {
            if entryMode != .Normal {
                formatButtonBackgroundColor = formatButton.backgroundColor!
                formatButton.backgroundColor = UIColor.blackColor()
            } else {
                formatButton.backgroundColor = formatButtonBackgroundColor
            }
        }
    }

    @IBAction func setFormat(sender: UIShiftableButton) {
        if !sender.shifted {
            entryMode = digitEntryModes.FormatFix
        } else {
            entryMode = digitEntryModes.FormatSci
        }
    }
    
    func setEntryModeNormal() {
        entryMode = digitEntryModes.Normal
        shiftedState=false
    }
    
    func isEntryModeNormal() -> Bool {
        return entryMode == .Normal
    }
    
    // displayValue is a computed var that returns either
    // the actual Double that is the result of the last stack
    // eval (i.e. displayRegister) OR a string->num conversion
    // of the text currently displayed
    //
    // The text representation is only used when the user is actively
    // entering a number because at that point, the displayRegister
    // is not yet valid
    //
    // setting the displayValue updates the displayRegister and
    // creates a string representation of displayRegister according
    // to the current format settings. This string representation is
    // placed in the display textField.
    //
    private var outputFormat:formatMode = formatMode.Fixed(2)
    private var displayRegister:Double=0
    var displayValue: Double? {
        get {
            if userIsInTheMiddleOfTypingANumber {
                let f = NSNumberFormatter()
                f.usesGroupingSeparator=true
                if let num=f.numberFromString(display.text!) {
                    return num.doubleValue
                } else {
                    return nil
                }
            } else {
                return displayRegister
            }
        }
        
        set {
            if let v = newValue {
                displayRegister = v
                display.text = formatDouble(v, format: outputFormat)
                userIsInTheMiddleOfTypingANumber = false
            } else {
                display.text = "0.0"
            }
            history.text = brain.description + "="
        }
    }
    
    lazy var displayFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.roundingMode = .RoundHalfDown
        return formatter
    }()
    
    private func formatDouble(val: Double, format: formatMode) -> String {
        var output:String
        switch format {
            case .Fixed(let digits):
                displayFormatter.numberStyle = .DecimalStyle
                displayFormatter.maximumFractionDigits = digits
                displayFormatter.minimumFractionDigits = digits
                output = displayFormatter.stringFromNumber(val)!
            case .Sci(let digits):
                displayFormatter.numberStyle = .ScientificStyle
                displayFormatter.maximumFractionDigits = digits
                displayFormatter.minimumFractionDigits = digits
                output = displayFormatter.stringFromNumber(val)!
         }
        return output
    }
}
