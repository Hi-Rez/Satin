//
//  InstancingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct InstancingRendererView: View {
    var body: some View {
        ForgeView(renderer: InstancingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Instancing")
    }
}

struct InstancingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        InstancingRendererView()
    }
}
