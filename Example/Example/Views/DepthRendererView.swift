//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct DepthMaterialRendererView: View {
    var body: some View {
        ForgeView(renderer: DepthMaterialRenderer())
            .ignoresSafeArea()
            .navigationTitle("Depth Material")
    }
}

struct DepthMaterialRendererView_Previews: PreviewProvider {
    static var previews: some View {
        DepthMaterialRendererView()
    }
}
