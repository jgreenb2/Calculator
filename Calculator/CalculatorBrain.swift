//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/31/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
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
        static let Cos = "cos"
        static let Tan = "tan"
        static let XSquared = "x²"
        static let XCubed = "x³"
        static let XInv = "1/x"
        static let yToX = "yˣ"
        static let NaturalLog = "ln"
        static let eToX = "ℯˣ"
    }
    typealias AlternateName = (name: String, postfix: Bool)
    private var alternateOperatorDescription = [String:AlternateName]()
    
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case Constant(String,()->Double)
        case Symbol(String,(String)-> Double?)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .Constant(let constant, _):
                    return constant
                case .Symbol(let symbol,_):
                    return symbol
                case .UnaryOperation(let symbol,_):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperation(let operation, _):
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
                case .UnaryOperation(_, _):
                    return 400
                default:
                    return Int.max
                }
            }
        }
    }
  
    // the operator stack, operator and variable dictionarys
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    var variableValues = [String:Double]()
    private var preserveStack: Bool = false
    
    // initialize by setting all of the operations
    // that the calculator can do
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation(OperatorSymbols.Multiplication, *))
        learnOp(Op.BinaryOperation(OperatorSymbols.Subtraction) {$1 - $0})
        learnOp(Op.BinaryOperation(OperatorSymbols.Addition,+))
        learnOp(Op.BinaryOperation(OperatorSymbols.Division) {$1 / $0})
        learnOp(Op.UnaryOperation(OperatorSymbols.SquareRoot, sqrt))
        learnOp(Op.UnaryOperation(OperatorSymbols.Sin, sin))
        learnOp(Op.UnaryOperation(OperatorSymbols.Cos, cos))
        learnOp(Op.UnaryOperation(OperatorSymbols.Tan, tan))
        learnOp(Op.Constant(OperatorSymbols.Pi) {M_PI})
        learnOp(Op.UnaryOperation(OperatorSymbols.PlusMinus) { -1 * $0 })
        learnOp(Op.UnaryOperation(OperatorSymbols.eToX) { exp($0) })
        learnOp(Op.UnaryOperation(OperatorSymbols.NaturalLog) { log($0) })
        learnOp(Op.UnaryOperation(OperatorSymbols.XCubed) { $0*$0*$0 })
        learnOp(Op.UnaryOperation(OperatorSymbols.XInv) { 1/$0 })
        learnOp(Op.UnaryOperation(OperatorSymbols.XSquared) { $0*$0 })
        learnOp(Op.BinaryOperation(OperatorSymbols.yToX) { pow($1,$0) })
        

        alternateOperatorDescription[OperatorSymbols.eToX] = ("exp", postfix: false)
        alternateOperatorDescription[OperatorSymbols.XCubed] = ("³", postfix: true)
        alternateOperatorDescription[OperatorSymbols.XInv] = ("inv", postfix: false)
        alternateOperatorDescription[OperatorSymbols.XSquared] = ("²", postfix: true)
        alternateOperatorDescription[OperatorSymbols.yToX] = ("^", postfix: false)
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
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(Op.Symbol(opSymbol,{self.variableValues[$0]}))
                    }
                }
                opStack = newOpStack
            }
        }
    }

    // clear the stack and variable memory
    func clear() {
        opStack.removeAll(keepCapacity: false)
        variableValues.removeAll(keepCapacity: false)
    }
    
    // push an operand on the stack and return the
    // new evaluation
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    // push a variable on the stack and return the
    // new evaluation
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Symbol(symbol,{self.variableValues[$0]}))
        return evaluate()
    }
    
    // set a variable to a value and re-evaluate the stack
    func setVariable(symbol: String, value: Double?) -> Double? {
        variableValues[symbol] = value
        return evaluate()
    }
    
    // perform an operation and re-evaluate the stack
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func changeSign() -> Double? {
        return performOperation(OperatorSymbols.PlusMinus)
    }
    
    func swapXY() {
        var (_, remainder1,_) = nextExpression(opStack)
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
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Symbol(let symbol, let value):
                return (value(symbol), remainingOps)
            case .Constant( _, let value):
                return (value(), remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_,let operation):
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
    private func parseStack(fullStack: [Op]) -> String {
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
    private func nextExpression(var stack: [Op]) -> ExpressionType {
        if !stack.isEmpty {
            var token = stack.removeLast()
            switch token {
                case .Operand(let value):
                    return ("\(value)", stack,token.precedence)
                case .Symbol(let symbol,_):
                    return (symbol, stack, token.precedence)
                case .Constant(let constant, _):
                    return (constant, stack, token.precedence)
                case .UnaryOperation(let operation,_):
                    let expression = nextExpression(stack)
                    let formattedExpression = formatUnaryExpression(operation, expression)
                    return (formattedExpression, expression.remainingStack, token.precedence)
                case .BinaryOperation(let operation, _):
                    let expression2 = nextExpression(stack)
                    let expression1 = nextExpression(expression2.remainingStack)
                    let expression = formatBinaryExpression(operation, expression1, expression2 , token.precedence)
                    return (expression, expression1.remainingStack, token.precedence)
            }
        } else {
            return ("?",stack,Int.max)
        }
        
    }
    
    private func formatBinaryExpression(var operation: String, _ expression1: ExpressionType,
        _ expression2: ExpressionType, _ operatorPrecedence: Int) -> String {
        
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
    
    private func formatUnaryExpression(operation: String, _ expression: ExpressionType) -> String {
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
    func addParens(s: String) -> String {
        return "("+s+")"
    }
    
    // computed variable returning the infix rep of the entire global stack
    var description: String {
        let desc = parseStack(opStack)
        return desc
    }
}

private extension Array {
    func tail(head: Array) -> Array {
        return Array(self[head.count...self.endIndex-1])
    }
}