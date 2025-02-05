//
//  Account.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//

import Foundation

struct Account: Codable {
    let id: UUID
    let userId: UUID
    let accountNumber: String
    let balance: Double
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case accountNumber = "account_number"
        case balance
        case currency
    }
}
