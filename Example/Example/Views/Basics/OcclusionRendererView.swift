//
//  OcclusionRendererView.swift
//  Example
//
//  Created by Reza Ali on 1/13/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct OcclusionRendererView: View {
    var body: some View {
        ForgeView(renderer: OcclusionRenderer())
            .ignoresSafeArea()
            .navigationTitle("Occlusion")
    }
}

struct OcclusionRendererView_Previews: PreviewProvider {
    static var previews: some View {
        OcclusionRendererView()
    }
}
