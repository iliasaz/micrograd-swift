import Foundation
import SwiftUI
import PlaygroundSupport
import micrograd

let SVGOutputFilePath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path

public func draw(_ v: Value?) {
    guard let v else { return }
    PlaygroundPage.current.setLiveView(ComputationGraphView(v))
}


let p = Value(1.0)
let q = p * 2.0 + 3.0
q.backward()
//draw(q)

// Neuron
let x1 = Value(2.0, label: "x1")
let x2 = Value(0.0, label: "x2")
let w1 = Value(-3.0, label: "w1")
let w2 = Value(1.0, label: "w2")
let b = Value(6.8813735870195432, label: "b")
let x1w1 = x1*w1; x1w1.label = "x1w1"
let x2w2 = x2*w2; x2w2.label = "x2w2"
let x1w1x2w2 = x1w1 + x2w2; x1w1x2w2.label = "x1w1+x2w2"
let activation = x1w1x2w2 + b; activation.label = "n"
let o = activation.tanh(); o.label = "o"
o.backward()
draw(o)

// mix of numerics and Values
//let x1 = Value(2.0, label: "x1")
//let x2 = Value(0.0, label: "x2")
//let y = 3*x1 - 4*x2**2 - 5
//y.backward()
//draw(y)

// MLP - multilayer perceptron
let x = [2.0, 3.0].enumerated().map { Value($1, label: "i\($0)") }
let nn = Neuron(numberOfInputs: 2)
nn(x)

let l = Layer(numberOfInputs: 2, numberOfOutputs: 3)
l(x)

let mlp = MLP(numberOfInputs: 3, layerSizes: [2,1])
mlp(x)
draw(mlp(x).first)


// full network
// inputs, with labels
var xs = [
    [2.0, 3.0, -1.0].enumerated().map { Value($1, label: "i\($0)") },
    [3.0, -1.0, 0.5].enumerated().map { Value($1, label: "i\($0)") },
    [0.5, 1.0, 1.0].enumerated().map { Value($1, label: "i\($0)") },
    [1.0, 1.0, -1.0].enumerated().map { Value($1, label: "i\($0)") },
]
// desired targets, with labels
let ys = [1.0, -1.0, -1.0, 1.0].map { Value($0, label: "ys") }

var ypred = [Value(0.0)]
var loss = Value(0.0)
var n = MLP(numberOfInputs: 3, layerSizes: [4,4,1])

// one cycle
ypred = n.pred(xs).map { $0.first! } // last layer has just one neuron
for (idx, _) in ypred.enumerated() { ypred[idx].label = "yp" }
loss = lossMSE(target: ys, pred: ypred)
n.layers.first!.neurons.first!.w.first!.data
loss.zeroGrad()
loss.backward()
print("one cycle loss: \(loss)")
n.layers.first!.neurons.first!.w.first!.grad
n.layers.first!.neurons.first!.w.first!.data
n.update(lr: 0.1)
n.layers.first!.neurons.first!.w.first!.data

// another cycle
ypred = n.pred(xs).map { $0.first! }
for (idx, _) in ypred.enumerated() { ypred[idx].label = "yp" }
loss = lossMSE(target: ys, pred: ypred)
loss.zeroGrad()
loss.backward()
print("second cycle loss: \(loss)")
n.layers.first!.neurons.first!.w.first!.grad
n.layers.first!.neurons.first!.w.first!.data
n.update(lr: 0.1)
n.layers.first!.neurons.first!.w.first!.data

draw(loss)
//saveGraph(for: loss, to: "\(SVGOutputFilePath)/out.svg")

print(">>>>> starting training loop")
n = MLP(numberOfInputs: 3, layerSizes: [4,4,1])
for k in 0..<1 {
    ypred = n.pred(xs).map { $0.first! } // last layer has just one neuron
    for (idx, _) in ypred.enumerated() { ypred[idx].label = "yp" }
    loss = lossMSE(target: ys, pred: ypred)
    n.zeroGrad()
    loss.backward()
    saveGraph(for: loss, to: "\(SVGOutputFilePath)/out\(k).svg")
    n.update(lr: 0.1)
//    print("Full MKP: \(n)")
//    print("Full Loss: \(loss.fullDescription)")
    print("iter: \(k), pred: \(ypred.map{$0.data}), loss: \(loss.data)")
}


