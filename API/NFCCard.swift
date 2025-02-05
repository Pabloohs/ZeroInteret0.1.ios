//
//  NFCCard.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//
import Foundation

struct NFCCard: Codable, Identifiable {
    let id: UUID
    let uid: String
    let userId: UUID
    let isActive: Bool
    let cardName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case userId = "user_id"
        case isActive = "is_active"
        case cardName = "card_name"
    }
}
