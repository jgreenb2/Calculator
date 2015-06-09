//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/31/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import Foundation

class CalculatorBrain {

    private enum Op: Printable {
        case Operand(Double)
        case Constant(String,()->Double)
        case Symbol(String,(String)-> Double?)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case Operand(let operand):
                    return "\(operand)"
                case .Constant(let constant, _):
                    return constant
                case Symbol(let symbol,_):
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
                        case "+":
                            return 200
                        case "−":
                            return 200
                        case "×":
                            return 300
                        case "÷":
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
  
    //var opStack: Array<Op> = Array<Op()
    //var opStack = Array<Op>()     // same as above
    private var opStack = [Op]()            // same as above
    //var knownOps = Dictionary<String, Op>()
    private var knownOps = [String:Op]()
    var variableValues = [String:Double]()
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", *))
        learnOp(Op.BinaryOperation("−") {$1 - $0})
        learnOp(Op.BinaryOperation("+",+))
        learnOp(Op.BinaryOperation("÷") {$1 / $0})
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.Constant("π") {M_PI})
        learnOp(Op.Symbol("?", {s1 in nil}))
        learnOp(Op.UnaryOperation("±") { -1 * $0 })
    }

    func clear() {
        opStack.removeAll(keepCapacity: false)
        variableValues.removeAll(keepCapacity: false)
    }

    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Symbol(symbol,{self.variableValues[$0]}))
        return evaluate()
    }
    
    func setVariable(symbol: String, value: Double?) -> Double? {
        variableValues[symbol] = value
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Symbol(let symbol, let value):
                return (value(symbol), remainingOps)
            case .Constant(let constant, let value):
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
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        println("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    

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
    
    private func nextExpression(var stack: [Op]) -> (result: String, remainingStack: [Op], precedence: Int) {
        if !stack.isEmpty {
            var token = stack.removeLast()
            switch token {
                case .Operand(let value):
                    return ("\(value)", stack,token.precedence)
                case .Symbol(let symbol,_):
                    if let value = variableValues[symbol] {
                        return (symbol, stack, token.precedence)
                    } else {
                        return (symbol+"?",stack,token.precedence)
                    }
                case .Constant(let constant, _):
                    return (constant, stack, token.precedence)
                case .UnaryOperation(let operation,_):
                    let expression = nextExpression(stack)
                    return (operation+addParens(expression.result), expression.remainingStack, token.precedence)
                case .BinaryOperation(let operation, _):
                    let expression2 = nextExpression(stack)
                    let expression1 = nextExpression(expression2.remainingStack)
                    var expression: String
                    if expression1.precedence < token.precedence {
                        expression = addParens(expression1.result)+operation+expression2.result
                    } else if expression2.precedence < token.precedence {
                        expression = expression1.result+operation+addParens(expression2.result)
                    } else {
                        expression = expression1.result+operation+expression2.result
                    }
                    return (expression, expression1.remainingStack, token.precedence)
            }
        } else {
            return ("?",stack,Int.max)
        }
        
    }
    
    func addParens(s: String) -> String {
        return "("+s+")"
    }
    
    var description: String {
        let desc = parseStack(opStack)
        return desc
    }
}