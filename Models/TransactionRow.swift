import SwiftUI

struct TransactionRow: View {
    var transaction: UserTransaction
    
    var formattedAmount: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "€"
        return numberFormatter.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "0.00 €"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.counterpartyName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(transaction.transactionDirection)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(transaction.createdAt)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(transaction.transactionDirection == "Reçu" ? "+\(formattedAmount)" : "-\(formattedAmount)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.transactionDirection == "Reçu" ? .green : .red)
                
                Text(transaction.status)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}