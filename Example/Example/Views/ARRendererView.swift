//
//  ARRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

#if os(iOS)

import SwiftUI
import Forge

struct ARRendererView: View {
    var body: some View {
        ForgeView(renderer: ARRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR")
    }
}

struct ARRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARRendererView()
    }
}

#endif
