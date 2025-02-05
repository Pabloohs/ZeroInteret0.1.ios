import Foundation

struct UserTransaction: Codable, Identifiable {
    var id: UUID { UUID() }
    let counterpartyName: String
    let amount: Decimal
    let transactionType: String
    let status: String
    let createdAt: String
    let transactionDirection: String
    
    enum CodingKeys: String, CodingKey {
        case counterpartyName = "counterparty_name"
        case amount
        case transactionType = "transaction_type"
        case status
        case createdAt = "created_at"
        case transactionDirection = "transaction_direction"
    }
} 