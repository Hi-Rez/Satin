//
//  SubmeshRendererView.swift
//  Example
//
//  Created by Reza Ali on 3/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct PBRSubmeshRendererView: View {
    var body: some View {
        ForgeView(renderer: PBRSubmeshRenderer())
            .ignoresSafeArea()
            .navigationTitle("Submeshes")
    }
}

struct PBRSubmeshRendererView_Previews: PreviewProvider {
    static var previews: some View {
        PBRSubmeshRendererView()
    }
}
