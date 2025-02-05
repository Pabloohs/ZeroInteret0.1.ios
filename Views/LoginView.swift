import SwiftUI
import Supabase

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var isSuccess = false
    @State private var message = ""
    @State private var profile: Profile? = nil
    @State private var account: Account? = nil
    @State private var nfcCards: [NFCCard]? = nil
    @State private var transactions: [Transaction]? = nil
    @State private var shouldNavigateToProfileView = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 🎨 Fond flouté avec un dégradé subtil
                LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    
                    // 🏦 Illustration d'une banque
                    Image(systemName: "building.columns.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    // 🌟 Nom de la banque avec slogan
                    VStack(spacing: 5) {
                        Text("Zéro Intérêt")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("La banque digitale sans compromis.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)

                    // ✉️ Champ email
                    inputField(title: "Email", text: $email, isSecure: false)
                    
                    // 🔑 Champ mot de passe
                    inputField(title: "Mot de passe", text: $password, isSecure: true)

                    // 🔵 Bouton de connexion modernisé
                    Button(action: signIn) {
                        Text("Se connecter")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)

                    // ⚠️ Message d'erreur ou de succès
                    if showAlert {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(isSuccess ? .green : .red)
                            .padding()
                            .transition(.opacity)
                    }
                }
                .padding()
                
                // Navigation vers ProfileView
                NavigationLink(
                    destination: Group {
                        if let profile = profile,
                           let account = account,
                           let nfcCards = nfcCards,
                           let transactions = transactions {
                            ProfileView(
                                profile: profile,
                                account: account,
                                nfcCards: nfcCards,
                                transactions: transactions
                            )
                        }
                    },
                    isActive: $shouldNavigateToProfileView
                ) { EmptyView() }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Composant de champ de saisie
    private func inputField(title: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isSecure {
                SecureField("", text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            } else {
                TextField("", text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Fonction de connexion
    func signIn() {
        Task {
            do {
                let response = try await supabase.auth.signIn(email: email, password: password)
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // 📡 Récupération des données utilisateur
                async let profileQuery: Profile = try await supabase.database
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                async let accountQuery: Account = try await supabase.database
                    .from("accounts")
                    .select()
                    .eq("user_id", value: userId)
                    .single()
                    .execute()
                    .value
                    
                async let nfcCardsQuery: [NFCCard] = try await supabase.database
                    .from("nfc_cards")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                let (profile, account, nfcCards) = try await (profileQuery, accountQuery, nfcCardsQuery)
                
                // Récupération des transactions
                async let transactionsQuery: [Transaction] = try await supabase.database
                    .from("transactions")
                    .select()
                    .or("from_account_id.eq.\(account.id),to_account_id.eq.\(account.id)")
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()
                    .value
                
                let transactions = try await transactionsQuery
                
                await MainActor.run {
                    isAuthenticated = true
                    isSuccess = true
                    message = "Connexion réussie!"
                    showAlert = true
                    self.profile = profile
                    self.account = account
                    self.nfcCards = nfcCards
                    self.transactions = transactions
                    self.shouldNavigateToProfileView = true
                }
                
            } catch {
                await MainActor.run {
                    isSuccess = false
                    message = "Erreur de connexion: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
