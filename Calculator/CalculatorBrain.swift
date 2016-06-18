//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/31/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import Foundation

class CalculatorBrain {
    let degPerRad = 180.0/M_PI
    var degMode = true
    
    /*  the basic operator type
        includes a computed variable that can be referenced
        to return the precedence level of the operation
    */
    private struct OperatorSymbols {
        static let Addition = "+"
        static let Subtraction = "−"
        static let Multiplication = "×"
        static let Division = "÷"
        static let SquareRoot = "√"
        static let Pi = "π"
        static let PlusMinus = "±"
        static let Sin = "sin"
        static let ASin = "asin"
        static let Cos = "cos"
        static let ACos = "acos"
        static let Tan = "tan"
        static let ATan = "atan"
        static let XSquared = "x²"
        static let XCubed = "x³"
        static let XInv = "1/x"
        static let yToX = "yˣ"
        static let NaturalLog = "ln"
        static let Base10Log = "log"
        static let eToX = "ℯˣ"
        static let tenToX = "10ˣ"
    }
    typealias AlternateName = (name: String, postfix: Bool)
    private var alternateOperatorDescription = [String:AlternateName]()
    
    private enum Op: CustomStringConvertible {
        case number(Double)
        case symbolicConstant(String,Double)
        case variable(String,(String)-> Double?)
        case unaryOperation(String, (Double) -> Double)
        case binaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case .number(let number):
                    return "\(number)"
                case .symbolicConstant(let constant, _):
                    return constant
                case .variable(let variable,_):
                    return variable
                case .unaryOperation(let symbol,_):
                    return symbol
                case .binaryOperation(let symbol, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .binaryOperation(let operation, _):
                    switch operation {
                        case OperatorSymbols.Addition:
                            return 200
                        case OperatorSymbols.Subtraction:
                            return 200
                        case OperatorSymbols.Multiplication:
                            return 300
                        case OperatorSymbols.Division:
                            return 300
                        default:
                            return 0
                        }
                case .unaryOperation(_, _):
                    return 400
                default:
                    return Int.max
                }
            }
        }
    }
    
    
    private var undoOrRedoInProgress = false
    private var undoStack = CircularBuffer<[Op]>(N: 10)   // N levels of undo/redo
    
    // the operator stack, operator and variable dictionarys
    private var opStack = [Op]() {
        willSet(newOpStack) {
            if !undoOrRedoInProgress {
                undoStack.add(newOpStack)
            }
        }
    }
    
    private var knownOps = [String:Op]()
    typealias variableDict = [String:Double]
    var variableValues = variableDict()
    
    // initialize by setting all of the operations
    // that the calculator can do
    init() {
        func learnOp(_ op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.binaryOperation(OperatorSymbols.Multiplication,      *               ))
        learnOp(Op.binaryOperation(OperatorSymbols.Subtraction,         {$1 - $0}       ))
        learnOp(Op.binaryOperation(OperatorSymbols.Addition,            +               ))
        learnOp(Op.binaryOperation(OperatorSymbols.Division,            {$1 / $0}       ))
        learnOp(Op.unaryOperation(OperatorSymbols.SquareRoot,           sqrt            ))
        learnOp(Op.unaryOperation(OperatorSymbols.Sin,                  calcSin         ))
        learnOp(Op.unaryOperation(OperatorSymbols.ASin,                 calcASin        ))
        learnOp(Op.unaryOperation(OperatorSymbols.Cos,                  calcCos         ))
        learnOp(Op.unaryOperation(OperatorSymbols.ACos,                 calcACos        ))
        learnOp(Op.unaryOperation(OperatorSymbols.Tan,                  calcTan         ))
        learnOp(Op.unaryOperation(OperatorSymbols.ATan,                 calcATan        ))
        learnOp(Op.symbolicConstant(OperatorSymbols.Pi,                 M_PI            ))
        learnOp(Op.unaryOperation(OperatorSymbols.PlusMinus,            { -1 * $0 }     ))
        learnOp(Op.unaryOperation(OperatorSymbols.eToX,                 { exp($0) }     ))
        learnOp(Op.unaryOperation(OperatorSymbols.tenToX,               { pow(10,$0) }  ))
        learnOp(Op.unaryOperation(OperatorSymbols.NaturalLog,           { log($0) }     ))
        learnOp(Op.unaryOperation(OperatorSymbols.Base10Log,            { log10($0) }   ))
        learnOp(Op.unaryOperation(OperatorSymbols.XCubed,               { $0*$0*$0 }    ))
        learnOp(Op.unaryOperation(OperatorSymbols.XInv,                 { 1/$0 }        ))
        learnOp(Op.unaryOperation(OperatorSymbols.XSquared,             { $0*$0 }       ))
        learnOp(Op.binaryOperation(OperatorSymbols.yToX,                { pow($1,$0) }  ))
        

        alternateOperatorDescription[OperatorSymbols.eToX] = ("exp", postfix: false)
        alternateOperatorDescription[OperatorSymbols.XCubed] = ("³", postfix: true)
        alternateOperatorDescription[OperatorSymbols.XInv] = ("inv", postfix: false)
        alternateOperatorDescription[OperatorSymbols.XSquared] = ("²", postfix: true)
        alternateOperatorDescription[OperatorSymbols.yToX] = ("^", postfix: false)
        alternateOperatorDescription[OperatorSymbols.tenToX] = ("10^", postfix: false)
    }
    
    
    var program: AnyObject {
        get {
            return opStack.map {$0.description}
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let number = NumberFormatter().number(from: opSymbol)?.doubleValue {
                        newOpStack.append(.number(number))
                    } else {
                        newOpStack.append(Op.variable(opSymbol,{self.variableValues[$0]}))
                    }
                }
                opStack = newOpStack
            }
        }
    }

    // clear the stack and variable memory
    func clear() {
        opStack.removeAll(keepingCapacity: false)
        variableValues.removeAll(keepingCapacity: false)
        undoStack.clear()
    }
    
    // push an operand on the stack and return the
    // new evaluation
    func pushNumber(_ number: Double) -> Double? {
        opStack.append(Op.number(number))
        return evaluate()
    }
    
    // push a variable on the stack and return the
    // new evaluation
    func pushNumber(_ variable: String) -> Double? {
        opStack.append(Op.variable(variable,{self.variableValues[$0]}))
        return evaluate()
    }
    
    // set a variable to a value and re-evaluate the stack
    func setVariable(_ symbol: String, value: Double?) -> Double? {
        variableValues[symbol] = value
        return evaluate()
    }
    
    // perform an operation and re-evaluate the stack
    func performOperation(_ symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    // if we have 2 consecutive sign changes we just undo the last one so that
    // we don't clutter up the stack and the infix rep
    func changeSign() -> Double? {
        if ((undoStack.cur()! as [Op]).last?.description == OperatorSymbols.PlusMinus) {
            return undo()
        } else {
            return performOperation(OperatorSymbols.PlusMinus)
        }
    }
    
    func swapXY() {
        let (_, remainder1,_) = nextExpression(opStack)
        if !remainder1.isEmpty {
            let X = opStack.tail(remainder1)
            let (_, remainder2,_) = nextExpression(remainder1)
            let Y = remainder1.tail(remainder2)
            opStack = X+Y
        }
    }
    
    // function that evaluates the gloal opStack
    func evaluate() -> Double? {
            let (result, _) = evaluate(opStack)
            return result
    }
        
    // helper function that evaluates an arbitrary stack
    private func evaluate(_ ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .number(let number):
                return (number, remainingOps)
            case .variable(let variable, let value):
                return (value(variable) ?? 0, remainingOps)
            case .symbolicConstant( _, let value):
                return (value, remainingOps)
            case .unaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .binaryOperation(_,let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1,operand2),op2Evaluation.remainingOps)
                    }
                }
            }
        }
        
        return (nil, ops)
    }
 
    // turn a stack into an infix string representation
    private func parseStack(_ fullStack: [Op]) -> String {
        var display=""
        var stack = fullStack
        while !stack.isEmpty {
            let expression = nextExpression(stack)
            stack = expression.remainingStack
            if display == "" {
                display = expression.result
            } else {
                display = expression.result + "," + display
            }
        }
        return display
    }
    
    // pull an expression off the stack and return an infix string rep
    //
    // precedence is an int returning the precedence of the expression.
    // Expression precedence is defined as the precedence of the operator enclosed in the expression
    // It's used to determine when parens are needed in the infix rep
    private typealias ExpressionType = (result: String, remainingStack: [Op], precedence: Int)
    private func nextExpression(_ stack: [Op]) -> ExpressionType {
        var stack = stack
        if !stack.isEmpty {
            let token = stack.removeLast()
            switch token {
                case .number(let number):
                    return ("\(number)", stack,token.precedence)
                case .variable(let variable,_):
                    return (variable, stack, token.precedence)
                case .symbolicConstant(let constant, _):
                    return (constant, stack, token.precedence)
                case .unaryOperation(let operation,_):
                    let expression = nextExpression(stack)
                    let formattedExpression = formatUnaryExpression(operation, expression)
                    return (formattedExpression, expression.remainingStack, token.precedence)
                case .binaryOperation(let operation, _):
                    let expression2 = nextExpression(stack)
                    let expression1 = nextExpression(expression2.remainingStack)
                    let expression = formatBinaryExpression(operation, expression1, expression2 , token.precedence)
                    return (expression, expression1.remainingStack, token.precedence)
            }
        } else {
            return ("?",stack,Int.max)
        }
        
    }
    
    private func formatBinaryExpression(_ operation: String, _ expression1: ExpressionType,
        _ expression2: ExpressionType, _ operatorPrecedence: Int) -> String {
        
        var operation = operation
        var expression:String
        if let alternate = alternateOperatorDescription[operation] {
            operation = alternate.name
        }
        if expression1.precedence < operatorPrecedence {
            expression = addParens(expression1.result)+operation+expression2.result
        } else if expression2.precedence < operatorPrecedence {
            expression = expression1.result+operation+addParens(expression2.result)
        } else {
            expression = expression1.result+operation+expression2.result
        }
        return expression
    }
    
    private func formatUnaryExpression(_ operation: String, _ expression: ExpressionType) -> String {
        var formattedExpr: String
        if let alternate = alternateOperatorDescription[operation] {
            if alternate.postfix {
                formattedExpr = addParens(expression.result)+alternate.name
            } else {
                formattedExpr = alternate.name+addParens(expression.result)
            }
        } else {
            formattedExpr = operation+addParens(expression.result)
        }
        return formattedExpr
    }
    
    // utility function to add parentheses
    func addParens(_ s: String) -> String {
        return "("+s+")"
    }
    
    // computed variable returning the infix rep of the entire global stack
    var description: String {
        let desc = parseStack(opStack)
        return desc
    }
    
    // methods to save and restore the current program
    
    private struct SavedProgramKeys {
        static let programKey = "_programKey_"
        static let variablesKey = "_variablesKey_"
        static let degRadModeKey = "_degRadModeKey_"
    }
    
    func saveProgram() {
        let defaults = UserDefaults.standard()
        defaults.set(program, forKey: SavedProgramKeys.programKey)
        defaults.set(variableValues, forKey: SavedProgramKeys.variablesKey)
        defaults.set(degMode, forKey: SavedProgramKeys.degRadModeKey)
    }
    
    func loadProgram()-> Double? {
        let defaults = UserDefaults.standard()
        if let restoredVariables = defaults.dictionary(forKey: SavedProgramKeys.variablesKey) as? variableDict {
            variableValues = restoredVariables
        }
        if let restoredMode = defaults.object(forKey: SavedProgramKeys.degRadModeKey) as? Bool {
            degMode = restoredMode
        }
        if let restoredProgram = defaults.object(forKey: SavedProgramKeys.programKey) {
            program = restoredProgram
            return evaluate()
        } else {
            return 0
        }
    }
    
    func redo()->Double? {
        undoOrRedoInProgress = true
        var result:Double? = nil
        if let nxtOpStack = undoStack.next() {
            opStack = nxtOpStack
            result = evaluate()
        } else {
            result = nil
        }
        undoOrRedoInProgress=false
        return result
    }
    
    func undo()-> Double? {
        undoOrRedoInProgress = true
        var result:Double? = nil
        if let prvOpStack = undoStack.prev() {
            opStack = prvOpStack
            result = evaluate()
        } else {
            result = nil
        }
        undoOrRedoInProgress = false
        return result
    }
    
    func degMode(_ mode: Bool) {
        degMode = mode
    }
    
    func calcSin(_ theta: Double)->Double {
        let angle = (degMode ? theta/degPerRad : theta)
        return sin(angle)
    }
    
    func calcASin(_ sval: Double)->Double {
        let angle = asin(sval)
        return (degMode ? angle*degPerRad : angle)
    }
    
    func calcCos(_ theta: Double)->Double {
        let angle = (degMode ? theta/degPerRad : theta)
        return cos(angle)
    }
    
    func calcACos(_ sval: Double)->Double {
        let angle = acos(sval)
        return (degMode ? angle*degPerRad : angle)
    }
    
    func calcTan(_ theta: Double)->Double {
        let angle = (degMode ? theta/degPerRad : theta)
        return tan(angle)
    }
    
    func calcATan(_ sval: Double)->Double {
        let angle = atan(sval)
        return (degMode ? angle*degPerRad : angle)
    }
}

private extension Array {
    func tail(_ head: Array) -> Array {
        return Array(self[head.count...self.endIndex-1])
    }
}
