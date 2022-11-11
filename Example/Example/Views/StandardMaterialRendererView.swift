//
//  StandardMaterialRendererView.swift
//  Example
//
//  Created by Reza Ali on 11/11/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct StandardMaterialRendererView: View {
    var body: some View {
        ForgeView(renderer: StandardMaterialRenderer())
            .ignoresSafeArea()
            .navigationTitle("Standard PBR Material")
    }
}

struct StandardMaterialRendererView_Previews: PreviewProvider {
    static var previews: some View {
        StandardMaterialRendererView()
    }
}
