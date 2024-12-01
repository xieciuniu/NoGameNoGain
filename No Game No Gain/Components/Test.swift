//
//  Test.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 01/12/2024.
//

import SwiftUI

struct Test: View {
    var body: some View {
        Grid (horizontalSpacing: 16){
                GridRow {
                    Color.red
                        .frame(width: UIScreen.main.bounds.width * 1/3, height: 150)
                    
                    Color.blue
                        .frame(width: UIScreen.main.bounds.width * 2/3, height: 150)
                }
            }
            .padding()
        }
}

#Preview {
    Test()
}
