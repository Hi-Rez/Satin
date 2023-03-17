//
//  ARRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Forge
import SwiftUI

struct ARDrawingRendererView: View {
    @State var clear: Bool = false

    var body: some View {
        ForgeView(renderer: ARDrawingRenderer(clear: $clear))
            .ignoresSafeArea()
            .navigationTitle("AR Drawing")
            .overlay {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            clear.toggle()
                        }, label: {
                            Image(systemName: "eraser.fill")
                                .renderingMode(.template)
                                .imageScale(.large)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        })
                        .padding(16)
                    }

                }
            }
    }
}

struct ARDrawingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ARDrawingRendererView()
    }
}

#endif
