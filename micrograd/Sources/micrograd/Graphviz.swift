//
//  Graphviz.swift
//  micrograd
//
//  Created by Ilia Sazonov on 2/3/23.
//

import Foundation
import GraphViz

public func trace(_ root: Value) -> (Set<Value>, Set<HashableEdge>) {
    var nodes = Set<Value>(), edges = Set<HashableEdge>()
    func build(_ v: Value) {
        if !nodes.contains(v) {
            nodes.insert(v)
            for child in v._prev {
                edges.insert(HashableEdge(from: child, to: v))
                build(child)
            }
        }
    }
    build(root)
    return (nodes, edges)
}

public func getGraph(_ root: Value) -> Graph {
    let (nodes, edges) = trace(root)
    var dot = Graph(directed: true)
//    dot[keyPath: \.rankDirection] = Graph.RankDirection.leftToRight
    
    // adding nodes
    for n in nodes {
        var node = Node("\(n.id)")
        node[keyPath: \.label] = "\(n.label) | data \(formatted: n.data) | grad \(formatted: n.grad)"
        node[keyPath: \.shape] = .rectangle
        
        // color code certain important nodes
        switch n.label {
            case let s where s.contains("w"): node[keyPath: \.fillColor] = .named(.lightcyan)
            case let s where s.contains("b"): node[keyPath: \.fillColor] = .named(.lightgoldenrodyellow)
            case let s where s.contains("ys"): node[keyPath: \.fillColor] = .named(.yellow1)
            case let s where s.contains("yp"): node[keyPath: \.fillColor] = .named(.lightpink)
            case let s where s.contains("i"): node[keyPath: \.fillColor] = .named(.green)
            default: break
        }
        
        dot.append(node)
        // special handling of operations
        if !n._op.isEmpty {
            var opNode = Node("\(n.id)\(n._op)")
            opNode[keyPath: \.label] = "op: \(n._op)"
            dot.append(opNode)
            dot.append(GraphViz.Edge(from: opNode, to: node))
        }
    }
    
    // adding edges
    for e in edges {
        let edge = GraphViz.Edge.init(from: "\(e.from.id)", to: "\(e.to.id)\(e.to._op)")
        dot.append(edge)
    }
    return dot
}

public func getGraph(_ root: MLP) -> Graph {
    var dot = Graph(directed: true)
    return dot
}



public func saveGraph(for v: Value?, to filePath: String) {
    guard let v else { return }
    let graph = getGraph(v)
    graph.render(using: .dot, to: .svg) { result in
        switch result {
        case .success(let data):
            let svg = String(data: data, encoding: .utf8)
            try! svg?.write(toFile: filePath, atomically: true, encoding: .utf8)
        case .failure(let error): fatalError(error.localizedDescription)
        }
    }
}

