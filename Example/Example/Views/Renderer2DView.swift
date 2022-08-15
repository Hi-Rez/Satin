//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct Renderer2DView: View {
    var body: some View {
        ForgeView(renderer: Renderer2D())
            .ignoresSafeArea()
            .navigationTitle("2D")
    }
}

struct Renderer2DView_Previews: PreviewProvider {
    static var previews: some View {
        Renderer2DView()
    }
}
