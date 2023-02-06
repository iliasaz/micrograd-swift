//
//  ComputationGraphView.swift
//  
//
//  Created by Ilia Sazonov on 2/3/23.
//

import SwiftUI
import GraphViz

public struct ComputationGraphView: View {
    @State public var v: Value
    @State var nsImg: NSImage = NSImage(size: NSSize(width: 1000, height: 1000))
    
    public init(_ v: Value) {
        self.v = v
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: nsImg)
                .resizable()
                .padding()
                .frame(width: 1000, height: 1000)
                .aspectRatio(contentMode: .fit)
                .onAppear {
                    let graph = getGraph(v)
                    graph.render(using: .dot, to: .png) { result in
                        self.nsImg = try! NSImage(data: result.get())!
                    }
                }
        }
    }
}

struct ComputationGraphView_Previews: PreviewProvider {
    static var previews: some View {
        ComputationGraphView(Value(0.0))
    }
}
