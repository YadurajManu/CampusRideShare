import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var currentPage = 0
    @State private var email = ""
    @State private var isShowingSignIn = false
    @State private var animateBackground = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let pages = [
        OnboardingPage(title: "Welcome to Campus Share", 
                      description: "Your trusted campus ride-sharing community",
                      systemImage: "car.fill",
                      backgroundColor: Color.blue.opacity(0.8)),
        OnboardingPage(title: "Find Your Ride", 
                      description: "Connect with fellow students heading your way",
                      systemImage: "map.fill",
                      backgroundColor: Color.green.opacity(0.8)),
        OnboardingPage(title: "Safe & Secure", 
                      description: "Verified campus members only",
                      systemImage: "shield.fill",
                      backgroundColor: Color.purple.opacity(0.8))
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        pages[currentPage].backgroundColor,
                        pages[currentPage].backgroundColor.opacity(0.6)
                    ]),
                    startPoint: animateBackground ? .topLeading : .bottomTrailing,
                    endPoint: animateBackground ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateBackground)
                
                // Content overlay with glass effect
                VStack(spacing: 20) {
                    // Logo
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "car.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                                .foregroundColor(.white)
                        )
                        .padding(.top, 40)
                    
                    // Page Control
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: 25) {
                                Image(systemName: pages[index].systemImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 160, height: 160)
                                    )
                                    .shadow(radius: 10)
                                
                                VStack(spacing: 15) {
                                    Text(pages[index].title)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(pages[index].description)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .tag(index)
                            .transition(.slide)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .interactive))
                    
                    Spacer()
                    
                    // Sign In Buttons
                    VStack(spacing: 15) {
                        Button(action: { isShowingSignIn = true }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Continue with Campus Email")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(pages[currentPage].backgroundColor)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    authManager.signInWithApple(credential: appleIDCredential)
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                        .frame(height: 50)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            authManager.signInWithGoogle()
                        }) {
                            HStack {
                                Image("google_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $isShowingSignIn) {
                EmailSignInView(email: $email, authManager: authManager)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                animateBackground = true
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
    let backgroundColor: Color
}

struct EmailSignInView: View {
    @Binding var email: String
    @Environment(\.dismiss) var dismiss
    @State private var isEmailValid = false
    @State private var isAnimating = false
    @State private var isLoading = false
    let authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Image(systemName: "envelope.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Sign in with Campus Email")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("Please enter your university email address to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Your campus email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { newValue in
                                isEmailValid = newValue.contains("@") && newValue.contains(".")
                            }
                        
                        if !email.isEmpty {
                            Text(isEmailValid ? "Valid email format" : "Please enter a valid email")
                                .font(.caption)
                                .foregroundColor(isEmailValid ? .green : .red)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        isLoading = true
                        authManager.signInWithEmail(email: email) { success in
                            isLoading = false
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isEmailValid ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .disabled(!isEmailValid || isLoading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                isAnimating = true
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 