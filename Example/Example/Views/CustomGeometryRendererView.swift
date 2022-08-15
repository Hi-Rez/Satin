//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct CustomGeometryRendererView: View {
    var body: some View {
        ForgeView(renderer: CustomGeometryRenderer())
            .ignoresSafeArea()
            .navigationTitle("Custom Geometry")
    }
}

struct CustomGeometryRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CustomGeometryRendererView()
    }
}
