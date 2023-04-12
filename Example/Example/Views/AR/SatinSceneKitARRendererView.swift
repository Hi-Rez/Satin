//
//  ARSatinSceneKitRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARSatinSceneKitRendererView: View {
    var body: some View {
        ForgeView(renderer: ARSatinSceneKitRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR + Satin + SceneKit")
    }
}

struct ARSatinSceneKitRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARSatinSceneKitRendererView()
    }
}

#endif
