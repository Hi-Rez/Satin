//
//  ProjectedShadowRendererView.swift
//  Example
//
//  Created by Reza Ali on 1/25/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct ProjectedShadowRendererView: View {
    var body: some View {
        ForgeView(renderer: ProjectedShadowRenderer())
            .ignoresSafeArea()
            .navigationTitle("Projected Shadow")
            .preferredColorScheme(.light)
    }
}

struct ProjectedShadowRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectedShadowRendererView()
    }
}
