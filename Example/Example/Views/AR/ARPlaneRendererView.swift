//
//  ARPlaneRendererView.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARPlanesRendererView: View {
    var body: some View {
        ForgeView(renderer: ARPlanesRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR Planes")
    }
}

struct ARPlaneRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlanesRendererView()
    }
}

#endif
