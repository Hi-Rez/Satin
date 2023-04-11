//
//  ARLidarMeshRendererView.swift
//  Example
//
//  Created by Reza Ali on 4/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARLidarMeshRendererView: View {
    var body: some View {
        ForgeView(renderer: ARLidarMeshRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR Lidar Mesh")
    }
}

struct ARLidarMeshRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARLidarMeshRendererView()
    }
}

#endif
