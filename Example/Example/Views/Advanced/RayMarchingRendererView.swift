//
//  RayMarchingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct RayMarchingRendererView: View {
    var body: some View {
        ForgeView(renderer: RayMarchingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Ray Marching")
    }
}

struct RayMarchingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RayMarchingRendererView()
    }
}
