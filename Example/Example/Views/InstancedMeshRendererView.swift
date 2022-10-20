//
//  InstancedMeshRendererView.swift
//  Example
//
//  Created by Reza Ali on 10/19/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct InstancedMeshRendererView: View {
    var body: some View {
        ForgeView(renderer: InstancedMeshRenderer())
            .ignoresSafeArea()
            .navigationTitle("Instanced Mesh")
    }
}

struct InstancedMeshRendererView_Previews: PreviewProvider {
    static var previews: some View {
        InstancedMeshRendererView()
    }
}
