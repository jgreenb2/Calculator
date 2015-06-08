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
        case Symbol(String,(String)-> Double?)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case Operand(let operand):
                    return "\(operand)"
                case Symbol(let symbol,_):
                    return symbol
                case .UnaryOperation(let symbol,_):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
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
        learnOp(Op.Symbol("π", {s1 in M_PI}))
        learnOp(Op.Symbol("?", {s1 in nil}))
        learnOp(Op.UnaryOperation("±") { -1 * $0 })
    }

    func clear() {
        opStack.removeAll(keepCapacity: false)
    }

    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Symbol(symbol,{self.variableValues[$0]}))
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
                    } else {
                        opStack.insert(knownOps["?"]!, atIndex: ops.count - 2 )
                        println("op2 missing=\(ops.count - 2)")
                    }
                } else {
                    opStack.insert(knownOps["?"]!, atIndex: ops.count - 1 )
                    println("op1 missing=\(ops.count - 1)")
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
    
    private func nextExpression(var stack: [Op]) -> (result: String, remainingStack: [Op]) {
        if !stack.isEmpty {
            var token = stack.removeLast()
            switch token {
                case .Operand(let value):
                    return ("\(value)", stack)
                case .Symbol(let symbol,_):
                    return (symbol, stack)
                case .UnaryOperation(let operation,_):
                    let expression = nextExpression(stack)
                    return (operation+"("+expression.result+")", expression.remainingStack)
                case .BinaryOperation(let operation, _):
                    let expression2 = nextExpression(stack)
                    let expression1 = nextExpression(expression2.remainingStack)
                    return ("("+expression1.result+operation+expression2.result+")", expression1.remainingStack)
            }
        } else {
            return ("?",stack)
        }
        
    }
    var description: String {
        let desc = parseStack(opStack)
        return desc
    }
}