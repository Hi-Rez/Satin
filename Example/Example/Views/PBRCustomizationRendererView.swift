//
//  PBRCustomizationRendererView.swift
//  Example
//
//  Created by Reza Ali on 4/4/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct PBRCustomizationRendererView: View {
    var body: some View {
        ForgeView(renderer: PBRCustomizationRenderer())
            .ignoresSafeArea()
            .navigationTitle("PBR Customization")
    }
}

struct PBRCustomizationRendererView_Previews: PreviewProvider {
    static var previews: some View {
        PBRCustomizationRendererView()
    }
}

