import SwiftUI

struct ProfileView: View {
    var profile: Profile
    var account: Account?
    @State var nfcCards: [NFCCard]
    @State var transactions: [Transaction]
    @State private var userTransactions: [UserTransaction] = []
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - En-tête (Salutations & Solde)
                    headerView()
                    
                    // MARK: - Section des Cartes NFC
                    nfcCardsSection()
                    
                    // MARK: - Historique des Transactions
                    transactionsSection()
                    
                    // MARK: - Bouton de virement
                    virementButton()
                    
                    // MARK: - Bouton de déconnexion
                    signOutButton()
                }
            }
            .navigationTitle("Mon Profil")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .alert("Mise à jour de la carte", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Sous-vues et composants
extension ProfileView {
    @ViewBuilder
    private func headerView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingMessage())
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(profile.firstName ?? "Utilisateur")")
                .font(.title2)
                .foregroundColor(.gray)
            
            if let account = account {
                HStack {
                    Text("Solde disponible:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f %@", account.balance, account.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func nfcCardsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mes Cartes NFC")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(nfcCards) { card in
                        NFCCardView(
                            card: card,
                            isUpdating: $isUpdating,
                            onToggle: { toggleCardStatus(card) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func transactionsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Historique des Transactions")
                .font(.headline)
                .padding(.horizontal)
            
            if userTransactions.isEmpty {
                Text("Aucune transaction disponible")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(userTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding(.top, 10)
        .onAppear {
            fetchUserTransactions()
        }
    }
    
    private func fetchUserTransactions() {
        Task {
            do {
                let response = try await supabase.database
                    .rpc("get_user_transactions", params: ["profile_id": profile.id])
                    .execute()
                    
                guard let jsonString = String(data: response.data, encoding: .utf8),
                      let jsonData = jsonString.data(using: .utf8) else {
                    print("Erreur de conversion des données")
                    return
                }
                
                let decoder = JSONDecoder()
                let transactions = try decoder.decode([UserTransaction].self, from: jsonData)
                
                await MainActor.run {
                    self.userTransactions = transactions
                }
            } catch {
                print("Erreur lors de la récupération des transactions: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func virementButton() -> some View {
        NavigationLink(destination: TransferView(nfcCards: nfcCards)) {
            Text("Effectuer un Virement")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
    @ViewBuilder
    private func signOutButton() -> some View {
        Button(action: signOut) {
            Text("Se déconnecter")
                .foregroundColor(.red)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

// MARK: - Fonctions métier
extension ProfileView {
    /// Fonction de déconnexion
    func signOut() {
        Task {
            do {
                try await supabase.auth.signOut()
                await MainActor.run {
                    isAuthenticated = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Erreur lors de la déconnexion: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    /// Fonction pour basculer l'état d'une carte NFC
    func toggleCardStatus(_ card: NFCCard) {
        isUpdating = true
        
        Task {
            do {
                // Mise à jour dans Supabase
                try await supabase.database
                    .from("nfc_cards")
                    .update(["is_active": !card.isActive])
                    .eq("id", value: card.id)
                    .execute()
                
                // Mise à jour locale
                if let index = nfcCards.firstIndex(where: { $0.id == card.id }) {
                    await MainActor.run {
                        nfcCards[index] = NFCCard(
                            id: card.id,
                            uid: card.uid,
                            userId: card.userId,
                            isActive: !card.isActive,
                            cardName: card.cardName
                        )
                        alertMessage = "Carte mise à jour avec succès"
                        showAlert = true
                        isUpdating = false
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Erreur lors de la mise à jour : \(error.localizedDescription)"
                    showAlert = true
                    isUpdating = false
                }
            }
        }
    }
    
    /// Affiche un message personnalisé selon l'heure
    func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Bonjour"
        case 12..<18:
            return "Bonne après-midi"
        default:
            return "Bonsoir"
        }
    }
}
