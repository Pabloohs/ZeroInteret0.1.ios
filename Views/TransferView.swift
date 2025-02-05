import SwiftUI
import CryptoKit
import CommonCrypto

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

struct TransferView: View {
    let nfcCards: [NFCCard]
    @State private var selectedCardId: UUID? = nil
    @State private var accountNumber: String = ""
    @State private var nfcCode: String = ""
    @State private var amount: String = ""
    @State private var isSearching = false
    @State private var foundAccount: Account? = nil
    @State private var foundProfile: Profile? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private var activeCards: [NFCCard] {
        nfcCards.filter { $0.isActive }
    }
    
    private var selectedCard: NFCCard? {
        activeCards.first(where: { $0.id == selectedCardId })
    }
    
    private var isNFCCodeValid: Bool {
        selectedCard?.uid == nfcCode
    }
    
    private var canInitiateTransfer: Bool {
        let amountValue = Double(amount) ?? 0
        return foundAccount != nil &&
               isNFCCodeValid &&
               amountValue > 0 &&
               !isSearching
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    cardSelectionSection
                    accountSearchSection
                    
                    if let account = foundAccount, let profile = foundProfile {
                        accountDetailsSection(account: account, profile: profile)
                    }
                    
                    if foundAccount != nil {
                        nfcAndAmountSection
                    }
                    
                    if foundAccount != nil && isNFCCodeValid {
                        transferButton
                    }
                }
                .padding()
            }
            .navigationTitle("Nouveau virement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Annuler") {
                dismiss()
            })
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("succès") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Sections de la vue
    
    private var cardSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("1. Sélectionnez votre carte")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeCards) { card in
                        CardSelectionView(
                            cardName: card.cardName ?? "Carte \(card.uid)",
                            isSelected: selectedCardId == card.id
                        )
                        .onTapGesture {
                            selectedCardId = card.id
                        }
                    }
                }
            }
        }
    }
    
    private var accountSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2. Compte du destinataire")
                .font(.headline)
            
            TextField("Numéro de compte", text: $accountNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSearching)
            
            Button(action: verifyAccount) {
                if isSearching {
                    ProgressView()
                } else {
                    Text("Rechercher")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(accountNumber.isEmpty || isSearching)
        }
    }
    
    private func accountDetailsSection(account: Account, profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("3. Détails du destinataire")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Email: \(profile.email ?? "Non disponible")")
                Text("Compte: \(account.accountNumber)")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var nfcAndAmountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4. Validation et montant")
                .font(.headline)
            
            SecureField("Code NFC", text: $nfcCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isNFCCodeValid {
                TextField("Montant en EUR", text: $amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var transferButton: some View {
        Button(action: processTransfer) {
            Text("Effectuer le virement")
                .frame(maxWidth: .infinity)
                .padding()
                .background(canInitiateTransfer ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!canInitiateTransfer)
    }
    
    // MARK: - Fonctions
    
    private func verifyAccount() {
        isSearching = true
        
        Task {
            do {
                let currentUserId = supabase.auth.session.user.id
                
                let query = "*, profiles!inner(*)"
                let accounts: [Account] = try await supabase.database
                    .from("accounts")
                    .select(query)
                    .eq("account_number", value: accountNumber)
                    .execute()
                    .value
                
                if accounts.isEmpty {
                    await MainActor.run {
                        self.alertMessage = "Aucun compte trouvé avec ce numéro"
                        self.showAlert = true
                        self.foundAccount = nil
                        self.foundProfile = nil
                        self.isSearching = false
                    }
                    return
                }
                
                let profiles: [Profile] = try await supabase.database
                    .from("profiles")
                    .select()
                    .eq("id", value: accounts.first?.userId.uuidString ?? "")
                    .execute()
                    .value
                
                await MainActor.run {
                    if let account = accounts.first, let profile = profiles.first {
                        if account.userId == currentUserId {
                            self.alertMessage = "Vous ne pouvez pas effectuer un virement vers votre propre compte"
                            self.showAlert = true
                            self.foundAccount = nil
                            self.foundProfile = nil
                        } else {
                            self.foundAccount = account
                            self.foundProfile = profile
                            self.alertMessage = "Compte trouvé"
                        }
                    } else {
                        self.alertMessage = "Aucun compte trouvé avec ce numéro"
                        self.showAlert = true
                    }
                    
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Erreur lors de la recherche: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isSearching = false
                }
            }
        }
    }
    
    func encryptDataAES256CBC(_ data: String, using key: Data) -> (ciphertext: String, iv: String)? {
        guard let plaintextData = data.data(using: .utf8) else { return nil }

        let keyLength = kCCKeySizeAES256
        var ivBytes = [UInt8](repeating: 0, count: kCCBlockSizeAES128)
        let status = SecRandomCopyBytes(kSecRandomDefault, ivBytes.count, &ivBytes)
        guard status == errSecSuccess else { return nil }
        let iv = Data(ivBytes)


        let bufferSize = plaintextData.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0

        let cryptStatus = buffer.withUnsafeMutableBytes { bufferBytes in
            plaintextData.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding), // ✅ Padding activé pour CBC
                            keyBytes.baseAddress, keyLength,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, plaintextData.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        guard cryptStatus == kCCSuccess else {
            print("Encryption failed")
            return nil
        }

        buffer.count = numBytesEncrypted
        return (
            buffer.base64EncodedString(),
            iv.base64EncodedString()
        )
    }


    private func processTransfer() {
        guard let amountValue = Double(amount),
              let destinationAccount = foundAccount,
              let card = selectedCard else {
            print("Erreur : Montant invalide ou compte/carte non sélectionné")
            return
        }

        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id

                let currentUserAccounts: [Account] = try await supabase.database
                    .from("accounts")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value

                guard let senderAccount = currentUserAccounts.first else {
                    throw NSError(domain: "TransferError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Compte expéditeur non trouvé"])
                }

                // Génération d'une clé AES-256 (SHA-256 de la passphrase)
                // Génération de la clé AES-256
                func generateAESKey(from passphrase: String) -> Data {
                    let keyData = SHA256.hash(data: passphrase.data(using: .utf8)!)
                    return Data(keyData)
                }

                let keyData = generateAESKey(from: "CoucouNFC1234567890ABCDEF12345678")

                // ✅ Maintenant on peut afficher la taille
                print("✅ Taille de la clé AES : \(keyData.count) octets")
                print("✅ Clé de chiffrement générée : \(keyData.base64EncodedString())")


                // Chiffrement des données sensibles
                let jsonData = try JSONSerialization.data(withJSONObject: [
                    "from_account_id": senderAccount.id.uuidString,
                    "to_account_id": destinationAccount.id.uuidString,
                    "amount": String(amountValue),
                    "transaction_type": "transfer",
                    "status": "completed",
                    "card_id": card.id.uuidString
                ])

                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                print("✅ JSON avant chiffrement : \(jsonString)")

                guard let encryptedData = encryptDataAES256CBC(jsonString, using: keyData) else {
                    print("Erreur de chiffrement")
                    return
                }

                print("✅ Ciphertext : \(encryptedData.ciphertext)")
                print("✅ IV : \(encryptedData.iv)")

                // Structure Encodable pour envoyer au serveur
                struct EncryptedPayload: Encodable {
                    let ciphertext: String
                    let iv: String
                }

                let encryptedPayload = EncryptedPayload(
                    ciphertext: encryptedData.ciphertext,
                    iv: encryptedData.iv
                )

                // Envoi au serveur PostgreSQL
                let response = try await supabase.database
                    .rpc("process_transfer", params: encryptedPayload)
                    .execute()


                debugPrint("Réponse reçue du serveur :", response)

                await MainActor.run {
                    alertMessage = "Virement effectué avec succès !"
                    showAlert = true
                    isSearching = false
                }
            } catch {
                debugPrint("Erreur lors du virement :", error)
                await MainActor.run {
                    alertMessage = "Erreur lors du virement: \(error.localizedDescription)"
                    showAlert = true
                    isSearching = false
                }
            }
        }
    }


}

// MARK: - Modèles

struct TransferRequest: Encodable {
    let from_account_id: String
    let to_account_id: String
    let amount: Double
    let transaction_type: String
    let status: String
    let card_id: String
}

struct CardSelectionView: View {
    let cardName: String
    let isSelected: Bool
    
    var body: some View {
        Text(cardName)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
    }
}
