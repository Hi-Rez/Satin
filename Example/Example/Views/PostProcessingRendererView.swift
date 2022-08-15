//
//  PostProcessingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct PostProcessingRendererView: View {
    var body: some View {
        ForgeView(renderer: PostProcessingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Post Processing")
    }
}

struct PostProcessingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        PostProcessingRendererView()
    }
}
