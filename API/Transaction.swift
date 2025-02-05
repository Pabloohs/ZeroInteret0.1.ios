//
//  Transaction.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//

import Foundation
// Transaction.swift
// Transaction.swift
struct Transaction: Codable, Identifiable {
    let id: UUID
    let fromAccountId: UUID?
    let toAccountId: UUID?
    let amount: Decimal
    let transactionType: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromAccountId = "from_account_id"
        case toAccountId = "to_account_id"
        case amount
        case transactionType = "transaction_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

