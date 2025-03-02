//
//  Extension.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/16/24.
//

import Foundation
import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func standardBackButton(dismiss: DismissAction) -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
