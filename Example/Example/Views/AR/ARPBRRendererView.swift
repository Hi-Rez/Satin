//
//  ARPBRRendererView.swift
//  Example
//
//  Created by Reza Ali on 4/25/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARPBRRendererView: View {
    var body: some View {
        ForgeView(renderer: ARPBRRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR PBR")
    }
}

struct ARPBRRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARPBRRendererView()
    }
}

#endif
