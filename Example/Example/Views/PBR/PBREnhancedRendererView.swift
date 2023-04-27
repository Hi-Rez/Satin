//
//  EnhancedPBRRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct PBREnhancedRendererView: View {
    var body: some View {
        ForgeView(renderer: PBREnhancedRenderer())
            .ignoresSafeArea()
            .navigationTitle("PBR Physical Material")
    }
}

struct PBREnhancedRendererView_Previews: PreviewProvider {
    static var previews: some View {
        PBREnhancedRendererView()
    }
}
