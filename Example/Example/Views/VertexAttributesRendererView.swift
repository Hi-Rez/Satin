//
//  VertexAttributesRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct VertexAttributesRendererView: View {
    var body: some View {
        ForgeView(renderer: VertexAttributesRenderer())
            .ignoresSafeArea()
            .navigationTitle("Custom Vertex Attributes")
    }
}

struct VertexAttributesRendererView_Previews: PreviewProvider {
    static var previews: some View {
        VertexAttributesRendererView()
    }
}
