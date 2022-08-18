//
//  SuperShapesRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/18/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Forge
import Satin
import SwiftUI

struct SuperShapesRendererView: View {
    var renderer = SuperShapesRenderer()
    @ObservedObject var parameters: ParameterGroup
    @State var dragLocation: CGPoint?

    init() {
        self.parameters = renderer.parameters
    }
    
    var body: some View {
        ZStack {
            ForgeView(renderer: renderer)
                .ignoresSafeArea()
                .navigationTitle("Super Shapes")

            VStack(alignment: .leading, spacing: 4) {
                ForEach(renderer.parameters.params, id: \.label) { param in
                    if let floatParam = param as? FloatParameter {
                        Text("\(param.label): \(floatParam.value)")
                            .multilineTextAlignment(.leading)
                            .padding(4)
                            .background(Color.black.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .gesture(
                                DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                                    .onChanged { drag in
                                        renderer.cameraController.disable()
                                        let location = drag.location
                                        if let oldDragLocation = dragLocation {
                                            let delta = location.x - oldDragLocation.x
                                            floatParam.value += Float(delta * 0.01)
                                        }
                                        dragLocation = location
                                    }
                                    .onEnded { _ in
                                        renderer.cameraController.enable()
                                        dragLocation = nil
                                    })
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
        }
    }
}

struct SuperShapesRendererView_Previews: PreviewProvider {
    static var previews: some View {
        SuperShapesRendererView()
    }
}
