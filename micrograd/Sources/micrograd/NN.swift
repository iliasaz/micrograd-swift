//
//  NN.swift
//  micrograd
//
//  Created by Ilia Sazonov on 2/3/23.
//

import Foundation

public protocol Module {
    func zeroGrad()
    var parameters: [Value] { get }
}

extension Module {
    public func zeroGrad() {
        for p in parameters {
            p.zeroGrad()
        }
    }
}

public struct Neuron: Module, CustomStringConvertible {
    public private(set) var label: String
    public private(set) var w: [Value]
    public private(set) var b: Value
    
    public var parameters: [Value] {
        return self.w + [self.b]
    }

    public init(numberOfInputs: Int, label: String = "") {
        self.label = label
        self.w = [Value](); w.reserveCapacity(numberOfInputs)
        self.b = Value(0.0, label: "\(label)-b")
        for i in 0..<numberOfInputs {
            let v = Double.random(in: -1.0..<1.0)
            w.append(Value(v, label: "\(label)-w\(i)"))
        }
    }
    
    public func callAsFunction(_ x: [Value]) -> Value {
        // activation = w * x + b
        let act = zip(w, x).map(*).reduce(b, +)
        return act.tanh()
//        return act.lrelu()
    }
    
    public var description: String {
        "Ws: ".appending(w.map { "\($0.data) / \($0.grad)" }.joined(separator: ",    ")).appending("    b= \(b.data) / \(b.grad)")
    }
}

public struct Layer: Module, CustomStringConvertible {
    public private(set) var label: String
    public private(set) var neurons: [Neuron]

    public var parameters: [Value] {
        return neurons.flatMap { $0.parameters }
    }

    public init(numberOfInputs: Int, numberOfOutputs: Int, label: String = "") {
        self.label = label
        neurons = [Neuron](); neurons.reserveCapacity(numberOfOutputs)
        for i in 0..<numberOfOutputs {
            neurons.append(Neuron(numberOfInputs: numberOfInputs, label: "\(label)-N\(i)"))
        }
    }
    
    public func callAsFunction(_ x: [Value]) -> [Value] {
        return neurons.map { $0(x) }
    }
    
    public var description: String {
        "\n------------- Layer ---------------\n".appending(neurons.map { $0.description }.joined(separator: "\n"))
    }
}

public struct MLP: Module, CustomStringConvertible {
    public private(set) var layers: [Layer]
    
    public var parameters: [Value] {
        return layers.flatMap { $0.parameters }
    }
    
    public init(numberOfInputs: Int, layerSizes: [Int]) {
        layers = [Layer](); layers.reserveCapacity(layerSizes.count)
        let sz = [numberOfInputs] + layerSizes // concatenate
        for i in 0..<layerSizes.count {
            layers.append(Layer(numberOfInputs: sz[i], numberOfOutputs: sz[i+1], label: "L\(i)"))
        }
    }
    
    public func callAsFunction(_ x: [Value]) -> [Value] {
        var out = x
        for l in layers {
            out = l(out)
        }
        return out
    }
    
    public func callAsFunction(_ x: [Double]) -> [Value] {
        var x = x.map { Value( $0 ) }
        for l in layers {
            x = l(x)
        }
        return x
    }
    
    public func pred(_ x: [Value]) -> [Value] {
        return self(x)
    }

    public func pred(_ x: [[Value]]) -> [[Value]] {
        return x.map { self($0) }
    }
    
    public func pred(_ x: [Double]) -> [Value] {
        return pred(x.map { Value($0) })
    }

    public func pred(_ x: [[Double]]) -> [[Value]] {
        return pred(x.map { $0.map { Value($0) } })
    }
    
    public func update(lr: Double) {
        for p in parameters {
            p.data += p.grad * (-lr)
        }
    }
    
    public var description: String {
        "MLP ================".appending(layers.map {$0.description}.joined()).appending("\n==========================================\n")
    }
}

public func lossMSE(target: [Value], pred: [Value]) -> Value {
    return zip(target, pred).map { ($0.1 - $0.0) ** 2.0 }.reduce(Value(0.0), +) // predicted - target !!!
}

public func lossMSE(target: [Double], pred: [Value]) -> Value {
    let targetValue = target.map { Value($0) }
    return lossMSE(target: targetValue, pred: pred)
}

