//
//  CalculatorViewController.swift
//  Calculator
//
//  View controller for the main calculator control panel
//
//  Created by Jeff Greenberg on 5/30/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

// types that conform to propertyListReadable can
// be serialized for storage in NSUserDefaults
protocol propertyListReadable {
    associatedtype ValueType
    func propertyListRepresentation() -> [String:ValueType]
    init?(propertyListRepresentation:[String:ValueType]?)
}

// ButtonEventInspection is a protocol that allows inspection of
// button events and conditional suppression of the associated
// action. It's used to implement the fix/sci button semantics

class CalculatorViewController: UIViewController, ButtonEventInspection {
    
    // state variables
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()                   // brain is the calc model
    
    private var degMode = true {
        didSet {
            setDegButtonTitle(degMode)
        }
    }
   
    // shift and mode buttons need special handling so we
    // retain outlets to them here
    @IBOutlet weak var shiftButton: ShiftableButton!
    @IBOutlet weak var formatButton: ShiftableButton!
    @IBOutlet weak var degModeButton: CalculatorButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeButtons()
    }
    
    // restore programs and modes from the last session
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadDisplayModes()
        displayValue = brain.loadProgram()
        degMode=brain.degMode
    }
    
    // save current program and modes
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        brain.saveProgram()
        saveDisplayModes()
    }
    
    // keys for storage
    private struct DefaultKeys {
        static let fixSciKey = "_fixSciKey_"
    }
    
    // formatMode is an enum which can't be saved directly by NSUserDefaults.
    // formatMode conforms to the propertyListReadable protocol which allows
    // it to be serialized for storage.
    private func loadDisplayModes() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let format = formatMode(propertyListRepresentation: defaults.dictionaryForKey(DefaultKeys.fixSciKey) as? [String:Int]) {
            outputFormat = format
        }
    }
    
    private func saveDisplayModes() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(outputFormat.propertyListRepresentation(), forKey: DefaultKeys.fixSciKey)
    }

    // the main numeric display
    @IBOutlet weak var display: UILabel! {
        didSet { 
            display.layer.cornerRadius=8
            display.adjustsFontSizeToFitWidth = true
            display.minimumScaleFactor=0.8
        }
    }
    
    // displays the calculator 'tape' in infix format
    @IBOutlet weak var history: UILabel!
    
    // process the 0-9 keys
    @IBAction func appendDigit(sender: CalculatorDigits) {
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

    // process deg/rad key
    @IBAction func degRadMode(sender: CalculatorButton) {
        degMode = !degMode
        brain.degMode(degMode)
    }
    
    // the key label displays the current mode
    private func setDegButtonTitle(mode:Bool) {
        if mode {
            degModeButton.setTitle("Deg", forState: .Normal)
        } else {
            degModeButton.setTitle("Rad", forState: .Normal)
        }
    }
    
    // process the +/- key
    @IBAction func changeSign() {
        if userIsInTheMiddleOfTypingANumber {
            if display.text?.characters.first == "-" {
                display.text = String((display.text!).characters.dropFirst())
            } else {
                display.text = "-" + display.text!
            }
        } else if abs(displayValue!) > 0.0 {
            displayValue = brain.changeSign()!
        }
    }
    
    // erase one digit if still entering, else clear the display
    @IBAction func backspace() {
        if userIsInTheMiddleOfTypingANumber {
            switch (display.text!).characters.count {
                case 1:
                    displayValue=0
                default:
                     display.text = String((display.text!).characters.dropLast())
            }
        } else if displayValue != 0 {
            displayValue = 0
            enter()
        }
    }
    
    // process clear key
    @IBAction func clear() {
        brain.clear()
        displayValue=0
    }
    
    // process math operations. some of these have shifted functions.
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

    // store current value in variable "M"
    @IBAction func memSet() {
        if userIsInTheMiddleOfTypingANumber {
            displayValue = brain.setVariable("M", value: displayValue)
        } else {
            displayValue = brain.setVariable("M", value: displayRegister)
        }
        userIsInTheMiddleOfTypingANumber=false
    }

    // recall variable "M"
    @IBAction func memGet() {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        displayValue = brain.pushNumber("M")
    }
    
    // process enter key
    @IBAction func enter() {
        if displayValue != nil {
            displayValue = brain.pushNumber(displayValue!)
        }
        userIsInTheMiddleOfTypingANumber = false
    }
    
    // swap the first two items on the stack
    @IBAction func swapXY() {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        brain.swapXY()
        displayValue = brain.evaluate()
    }
    
    // shifted keys are ShiftableButtons. Shifted labels go here.
    private let shiftLabels:[String:String]=["cos":"acos", "sin":"asin", "tan":"atan", "⤾":"⤿","Fix":"Sci", "ℯˣ":"10ˣ", "ln":"log"]
    // track the shift state
    private var shiftedState = false {
        didSet {
            setButtonsToShifted(shiftedState)
            if !shiftedState {
                 shiftButton.setShiftLocked(false)
            }
        }
    }
    
    // delay the single tap on the shift key for a short interval in case the user is
    // actually doing a double tap. Then toggle the shift state.
    @IBAction func shiftOnSingleTap(sender: ShiftableButton) {
        performSelector(#selector(self.toggleShift), withObject: nil, afterDelay: 0.25)
    }
    
    func toggleShift() {
        shiftedState = !shiftedState
    }
    
    // if there's a double tap, cancel the previous single tap and lock the
    // shift button down.
    @IBAction func shiftLock(sender: ShiftableButton, forEvent event: UIEvent) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        shiftedState = true
        shiftButton.setShiftLocked(shiftedState)
    }
    
    // puts any ShiftableButton objects into shift mode
    private func setButtonsToShifted(shift:Bool) {
        for v in view.subviews {
            if let sb = v as? ShiftableButton {
                sb.setShifted(shift)
            }
        }
    }
    
    // set up calculator buttons
    private func initializeButtons() {
        initializeShiftButtonStates()
        setCalcButtonDelegates()
        shiftButton.setTitle("\u{21EA}", forState: [.ShiftLocked, .Shifted])    // UPWARDS WHITE ARROW FROM BAR
        shiftButton.setTitle("\u{21E7}", forState: .Normal)                     // UPWARDS WHITE ARROW
        shiftButton.setTitleColor(UIColor.redColor(), forState: [.ShiftLocked, .Shifted]) 
    }
    
    // Calculator buttons can cooperate with the ButtonEventInspection protocol
    // which is implemented here. So set the delegate to self.
    private func setCalcButtonDelegates() {
        for v in view.subviews {
            if let cb = v as? CalculatorButton {
                cb.delegate = self
            }
        }
    }
    
    // shifted state buttons change label and color. Set up the shifted state
    // definitions here.
    private func initializeShiftButtonStates() {
        for v in view.subviews {
            if let sb = v as? ShiftableButton {
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
    
    // process undo key
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

    // this is a trivial enum to handle the format modes.
    //
    // unfortunately, we can't store enums directly so the rest of
    // this code conforms to the propertyListReadable protocol which
    // serializes an enum into a Dictionary which can be stored
    private enum formatMode: propertyListReadable {
        typealias ValueType=Int
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
            default:
                return nil
            }
        }
    }
   
    // In FormatFix or FormatSci mode the next key *must* be 0-9 
    // This sets the number of digits after the decimal point.
    //
    // If the next key is anything other than a digit the keypress is discarded
    // and the mode is set back to Normal/Unshifted
    //
    // The CalculatorButton has a ButtonEventInspection delegate that allows
    // the view controller to inspect key presses
    //
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

    @IBAction func setFormat(sender: ShiftableButton) {
        if !sender.shifted {
            entryMode = digitEntryModes.FormatFix
        } else {
            entryMode = digitEntryModes.FormatSci
        }
    }
    
    // This is the ButtonEventInspection protocol function that allows us to
    // inspect a button event and conditionally suppress any action
    func actionShouldNotBePerformed(action: Selector, from source: AnyObject?, to target: AnyObject?, forEvent event: UIEvent?) -> Bool {
        if (entryMode == .Normal || source is CalculatorDigits) {
            return false
        } else {
            setEntryModeNormal()
            return true
        }
    }
    
    private func setEntryModeNormal() {
        entryMode = digitEntryModes.Normal
        shiftedState=false
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
    private var displayValue: Double? {
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
    
    private lazy var displayFormatter: NSNumberFormatter = {
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
