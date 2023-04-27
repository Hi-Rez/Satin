//
//  ContactShadowRendererView.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct ContactShadowRendererView: View {
    var body: some View {
        ForgeView(renderer: ContactShadowRenderer())
            .ignoresSafeArea()
            .navigationTitle("Contact Shadow")
            .preferredColorScheme(.light)
    }
}

struct ContactShadowRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ContactShadowRendererView()
    }
}
