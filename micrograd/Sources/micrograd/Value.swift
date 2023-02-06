//
//  Value.swift
//  micrograd
//
//  Created by Ilia Sazonov on 2/3/23.
//

import Foundation

public final class Value: Hashable, CustomStringConvertible {
    let id = UUID()
    public var data: Double
    public private(set) var grad: Double
    public var label: String
    private(set) var _prev: Set<Value>
    private(set) var _op: String
    private var _backward: () -> ()
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init(_ data: some Numeric, _ _children: Set<Value> = Set<Value>(), _ _op: String = "", _ _backward: @escaping () -> () = {}, label: String = "" ) {
        switch data {
            case let v as Double: self.data = v
            case let v as Int: self.data = Double(v)
            case let v as Float: self.data = Double(v)
            default: fatalError("Could not convert data of type \(type(of: data)) to Value")
        }
        self.grad = 0.0
        self._prev = _children
        self._op = _op
        self._backward = _backward
        self.label = label
    }

    public static func + (lhs: Value, rhs: Value) -> Value {
        let out = Value(lhs.data + rhs.data, [lhs, rhs], "+")

        out._backward = {
            lhs.grad += out.grad
            rhs.grad += out.grad
        }
        
        return out
    }
    
    public static func + (lhs: Value, rhsNumeric: some Numeric) -> Value {
        let rhs = Value(rhsNumeric)
        return lhs + rhs
    }
    
    public static func + (lhsNumeric: some Numeric, rhs: Value) -> Value {
        let lhs = Value(lhsNumeric)
        return lhs + rhs
    }

    public static func * (lhs: Value, rhs: Value) -> Value {
        let out = Value(lhs.data * rhs.data, [lhs, rhs], "*")
        
        out._backward = {
            lhs.grad += rhs.data * out.grad
            rhs.grad += lhs.data * out.grad
        }
        
        return out
    }
    
    public static func * (lhs: Value, rhsNumeric: some Numeric) -> Value {
        let rhs = Value(rhsNumeric)
        return lhs * rhs
    }
    
    public static func * (lhsNumeric: some Numeric, rhs: Value) -> Value {
        let lhs = Value(lhsNumeric)
        return lhs * rhs
    }
    
    public static func - (lhs: Value, rhs: Value) -> Value {
        return lhs + rhs * (-1.0)
    }

    public static func - (lhs: Value, rhs: some Numeric) -> Value {
        return lhs + Value(rhs) * (-1.0)
    }
    
    public static func / (lhs: Value, rhs: Value) -> Value {
        return lhs * rhs ** -1.0
    }
    
    public static func / (lhs: Value, rhsNumeric: some Numeric) -> Value {
        let rhs = Value(rhsNumeric)
        return lhs / rhs
    }

    public func tanh () -> Value {
        let t = Foundation.tanh(self.data)
        let out = Value(t, [self], "tanh")
        out._backward = {
            self.grad += (1.0 - t ** 2.0) * out.grad
        }
        return out
    }
    
    public func exp () -> Value {
        let out = Value(Foundation.exp(self.data), [self], "exp")
        out._backward = {
            self.grad += out.data * out.grad
        }
        return out
    }
    
    public func relu() -> Value {
        let out = Value(self.data > 0.0 ? self.data : 0.0, [self], "relu")
        out._backward = {
            self.grad += (out.data > 0.0 ? 1.0 : 0.0) * out.grad
        }
        return out
    }
    
    public func lrelu() -> Value {
        let out = Value(self.data > 0.0 ? self.data : 0.01 * self.data, [self], "lrelu")
        out._backward = {
            self.grad += (out.data > 0.0 ? 1.0 : 0.01) * out.grad
        }
        return out
    }
    
    public static func ** (lhs: Value, rhs: some Numeric) -> Value {
        let rhsD: Double
        switch rhs {
            case let v as Double: rhsD = v
            case let v as Int: rhsD = Double(v)
            case let v as Float: rhsD = Double(v)
            default: fatalError("Could not convert data of type \(type(of: rhs)) to Value")
        }
        let out = Value(lhs.data ** rhsD, [lhs], "**\(rhs)")
        
        out._backward = {
            lhs.grad += rhsD * lhs.data ** (rhsD-1.0) * out.grad
        }
        return out
    }
    
    public static func == (lhs: Value, rhs: Value) -> Bool {
        lhs.id == rhs.id
    }
    
    public func backward() {
        var topo = [Value]()
        var visited = Set<Value>()
        
        func buildTopo(_ v: Value) {
            if !visited.contains(v) {
                visited.insert(v)
                for child in v._prev {
                    buildTopo(child)
                }
                topo.append(v)
            }
        }
        
        buildTopo(self)
        
        // go one variable at a time and apply the chain rule to get its gradient
        self.grad = 1
        for v in topo.reversed() {
            v._backward()
        }
    }
    
    public func zeroGrad() { grad = 0.0 }
    
    public var description: String {
        "Value(label: \(self.label) | data=\(self.data), grad=\(self.grad), op=\(self._op))"
    }
    
    public var fullDescription: String { "\(description) >>> \(_prev.map { $0.fullDescription }.joined(separator: "\n"))" }
}

public struct HashableEdge: Equatable, CustomStringConvertible, Hashable {
    let from: Value
    let to: Value
    public var description: String { "from: \(from) to \(to)" }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(formatted value: Double) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4

        if let result = formatter.string(from: value as NSNumber) {
            appendLiteral(result)
        }
    }
}

precedencegroup ExponentiationPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator ** : ExponentiationPrecedence
infix operator **= : AssignmentPrecedence

public func ** (lhs: Double, rhs: Double) -> Double {
    return pow(lhs, rhs)
}

public func **= (lhs: inout Double, rhs: Double) {
    lhs = pow(lhs, rhs)
}
