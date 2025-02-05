//
//  NFCCardView.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//

import SwiftUI

struct NFCCardView: View {
    var card: NFCCard
    @Binding var isUpdating: Bool
    var onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 25)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onToggle) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(card.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(card.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        if isUpdating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        }
                    }
                }
                .disabled(isUpdating)
            }
            
            Spacer()
            
            // Ici, on utilise la méthode maskedUID()
            Text("UID: \(card.uid.maskedUID())")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            Text(card.cardName ?? "Carte sans nom")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 120)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 5)
    }
}
