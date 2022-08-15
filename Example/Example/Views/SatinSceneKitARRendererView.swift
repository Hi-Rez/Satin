//
//  SatinSceneKitARRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

#if os(iOS)

import SwiftUI
import Forge

struct SatinSceneKitARRendererView: View {
    var body: some View {
        ForgeView(renderer: SatinSceneKitARRenderer())
            .ignoresSafeArea()
            .navigationTitle("Satin + SceneKit + AR")
    }
}

struct SatinSceneKitARRendererView_Previews: PreviewProvider {
    static var previews: some View {
        SatinSceneKitARRendererView()
    }
}

#endif
