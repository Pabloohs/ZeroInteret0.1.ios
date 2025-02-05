//
//  VisualEffectBlur.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//


import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
