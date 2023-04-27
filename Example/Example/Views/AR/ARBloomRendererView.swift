//
//  ARBloomRendererView.swift
//  Example
//
//  Created by Reza Ali on 4/26/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARBloomRendererView: View {
    var body: some View {
        ForgeView(renderer: ARBloomRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR Bloom")
    }
}

struct ARBloomRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARBloomRendererView()
    }
}

#endif

