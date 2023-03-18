//
//  MeshShaderRendererView.swift
//  Example
//
//  Created by Reza Ali on 3/17/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct MeshShaderRendererView: View {
    var body: some View {
        ForgeView(renderer: MeshShaderRenderer())
            .ignoresSafeArea()
            .navigationTitle("Mesh Shader")
    }
}

struct MeshShaderRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MeshShaderRendererView()
    }
}

