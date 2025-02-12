import SwiftUI
import AuthenticationServices

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    static let shared = AuthenticationManager()
    
    private init() {}
    
    func signInWithEmail(email: String, completion: @escaping (Bool) -> Void) {
        // TODO: Implement actual email authentication
        // For now, just simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = true
            self.currentUser = User(id: UUID().uuidString,
                                  name: "Campus User",
                                  email: email,
                                  profileImage: nil)
            completion(true)
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        // TODO: Implement actual Apple sign in
        self.isAuthenticated = true
        self.currentUser = User(id: credential.user,
                              name: "\(credential.fullName?.givenName ?? "") \(credential.fullName?.familyName ?? "")",
                              email: credential.email ?? "",
                              profileImage: nil)
    }
    
    func signInWithGoogle() {
        // TODO: Implement actual Google sign in
        self.isAuthenticated = true
        self.currentUser = User(id: UUID().uuidString,
                              name: "Google User",
                              email: "user@gmail.com",
                              profileImage: nil)
    }
    
    func signOut() {
        self.isAuthenticated = false
        self.currentUser = nil
    }
}

struct User {
    let id: String
    let name: String
    let email: String
    let profileImage: String?
} 