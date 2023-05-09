//
//  ARPointCloudRendererView.swift
//  Example
//
//  Created by Reza Ali on 5/8/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARPointCloudRendererView: View {
    var body: some View {
        ForgeView(renderer: ARPointCloudRenderer())
            .ignoresSafeArea()
            .navigationTitle("AR Point Cloud")
    }
}

struct ARPointCloudRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARPointCloudRendererView()
    }
}

#endif
