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
            setDegButtonTitle(toDegree: degMode)
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDisplayModes()
        displayValue = brain.loadProgram()
        degMode=brain.degMode
    }
    
    // save current program and modes
    override func viewWillDisappear(_ animated: Bool) {
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
        let defaults = UserDefaults.standard
        if let format = formatMode(propertyListRepresentation: defaults.dictionary(forKey: DefaultKeys.fixSciKey) as? [String:Int]) {
            outputFormat = format
        }
    }
    
    private func saveDisplayModes() {
        let defaults = UserDefaults.standard
        defaults.set(outputFormat.propertyListRepresentation(), forKey: DefaultKeys.fixSciKey)
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
    @IBAction func appendDigit(_ sender: CalculatorDigits) {
        switch entryMode {
            case .formatFix:
                outputFormat = formatMode.fixed(Int(sender.titleLabel!.text!)!)
                displayValue = displayRegister
                entryMode = digitEntryModes.normal
            case .formatSci:
                outputFormat = formatMode.sci(Int(sender.titleLabel!.text!)!)
                displayValue = displayRegister
                entryMode = digitEntryModes.normal
                shiftedState = false
            case .normal:
                let digit = sender.currentTitle!
                if userIsInTheMiddleOfTypingANumber {
                    if digit == "."  && display.text!.range(of: ".") != nil {
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
    @IBAction func degRadMode(_ sender: CalculatorButton) {
        degMode = !degMode
        brain.degMode(degMode)
    }
    
    // the key label displays the current mode
    private func setDegButtonTitle(toDegree mode:Bool) {
        if mode {
            degModeButton.setTitle("Deg", for: UIControlState())
        } else {
            degModeButton.setTitle("Rad", for: UIControlState())
        }
    }
    
    // process the +/- key
    @IBAction func changeSign() {
        if userIsInTheMiddleOfTypingANumber {
            if display.text?.first == "-" {
                display.text = String((display.text!).dropFirst())
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
            switch (display.text!).count {
                case 1:
                    displayValue=0
                default:
                     display.text = String((display.text!).dropLast())
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
    @IBAction func operate(_ sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        var operation:String?
        if sender.state.contains(.Shifted) {
            operation = sender.title(for: .Shifted)
        } else {
            operation = sender.currentTitle
        }
        displayValue = brain.perform(operationName: operation!)
        if !shiftButton.shiftLocked {
            shiftedState=false
        }
    }

    // store current value in variable "M"
    @IBAction func memSet() {
        let v = (userIsInTheMiddleOfTypingANumber ? displayValue : displayRegister)
        displayValue = brain.set(variableName: "M", toValue: v)
        userIsInTheMiddleOfTypingANumber=false
    }

    // recall variable "M"
    @IBAction func memGet() {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        displayValue = brain.push(variableName: "M")
    }
    
    // process enter key
    @IBAction func enter() {
        if displayValue != nil {
            displayValue = brain.push(number: displayValue!)
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
    @IBAction func shiftOnSingleTap(_ sender: ShiftableButton) {
        perform(#selector(self.toggleShift), with: nil, afterDelay: 0.25)
    }
    
    @objc func toggleShift() {
        shiftedState = !shiftedState
    }
    
    // if there's a double tap, cancel the previous single tap and lock the
    // shift button down.
    @IBAction func shiftLock(_ sender: ShiftableButton, forEvent event: UIEvent) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        shiftedState = true
        shiftButton.setShiftLocked(shiftedState)
    }
    
    // puts any ShiftableButton objects into shift mode
    private func setButtonsToShifted(_ shift:Bool) {
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
        shiftButton.setTitle("\u{21EA}", for: [.ShiftLocked, .Shifted])    // UPWARDS WHITE ARROW FROM BAR
        shiftButton.setTitle("\u{21E7}", for: UIControlState())                     // UPWARDS WHITE ARROW
        shiftButton.setTitleColor(#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1), for: [.ShiftLocked, .Shifted]) 
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
                sb.setTitleColor(#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1), for: .Shifted)
                sb.setShifted(false)
                
                if let titleText = sb.titleLabel?.text {
                    if let shiftedLabel = shiftLabels[titleText] {
                        sb.setTitle(shiftedLabel, for: .Shifted)
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
        case fixed(Int)
        case sci(Int)
        
        func propertyListRepresentation() -> [String:Int] {
            switch self {
                case .fixed(let f):
                    return ["Fixed":f]
                case .sci(let s):
                    return ["Sci":s]
            }
        }
        
        init?(propertyListRepresentation:[String:Int]?) {
            guard let val=propertyListRepresentation else {return nil}
            let (s,v) = val.first!
            switch s {
            case "Fixed":
                self = formatMode.fixed(v)
            case "Sci":
                self = formatMode.sci(v)
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
        case formatFix
        case formatSci
        case normal
    }
    
    lazy var formatButtonBackgroundColor:UIColor={self.formatButton.backgroundColor!}()
    private var entryMode:digitEntryModes = digitEntryModes.normal {
        didSet {
            if entryMode != .normal {
                formatButtonBackgroundColor = formatButton.backgroundColor!
                formatButton.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            } else {
                formatButton.backgroundColor = formatButtonBackgroundColor
            }
        }
    }

    @IBAction func setFormat(_ sender: ShiftableButton) {
        if !sender.shifted {
            entryMode = digitEntryModes.formatFix
        } else {
            entryMode = digitEntryModes.formatSci
        }
    }
    
    // This is the ButtonEventInspection protocol function that allows us to
    // inspect a button event and conditionally suppress any action
    func actionShouldNotBePerformed(_ action: Selector, from source: Any?, to target: Any?, forEvent event: UIEvent?) -> Bool {
        if (entryMode == .normal || source is CalculatorDigits) {
            return false
        } else {
            setEntryModeNormal()
            return true
        }
    }
    
    private func setEntryModeNormal() {
        entryMode = digitEntryModes.normal
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
    private var outputFormat:formatMode = formatMode.fixed(2)
    private var displayRegister:Double=0
    private var displayValue: Double? {
        get {
            if userIsInTheMiddleOfTypingANumber {
                let f = NumberFormatter()
                f.usesGroupingSeparator=true
                if let num=f.number(from: display.text!) {
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
                display.text = formatDouble(doubleValue: v, format: outputFormat)
                userIsInTheMiddleOfTypingANumber = false
            } else {
                display.text = "0.0"
            }
            history.text = brain.description + "="
        }
    }
    
    private lazy var displayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.roundingMode = .halfDown
        return formatter
    }()
    
    private func formatDouble(doubleValue val: Double, format: formatMode) -> String {
        var output:String
        switch format {
            case .fixed(let digits):
                displayFormatter.numberStyle = .decimal
                displayFormatter.maximumFractionDigits = digits
                displayFormatter.minimumFractionDigits = digits
                output = displayFormatter.string(from: NSNumber(value: val))!
            case .sci(let digits):
                displayFormatter.numberStyle = .scientific
                displayFormatter.maximumFractionDigits = digits
                displayFormatter.minimumFractionDigits = digits
                output = displayFormatter.string(from: NSNumber(value: val))!
         }
        return output
    }
}
