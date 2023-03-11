//
//  SubmeshRendererView.swift
//  Example
//
//  Created by Reza Ali on 3/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct SubmeshRendererView: View {
    var body: some View {
        ForgeView(renderer: SubmeshRenderer())
            .ignoresSafeArea()
            .navigationTitle("Submeshes")
    }
}

struct SubmeshRendererView_Previews: PreviewProvider {
    static var previews: some View {
        SubmeshRendererView()
    }
}
