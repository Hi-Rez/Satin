//
//  FlockingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct FlockingRendererView: View {
    var body: some View {
        ForgeView(renderer: FlockingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Flocking Particles")
    }
}

struct FlockingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        FlockingRendererView()
    }
}
