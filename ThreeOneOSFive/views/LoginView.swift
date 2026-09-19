import SwiftUI

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255.0
        let green = Double((hex >> 8) & 0xff) / 255.0
        let blue = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public struct LoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var licenseKeyInput: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isPasting: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background subtle gradient glow
            RadialGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.12), Color.clear]),
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)
                    
                    // App Logo / Shield Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x1c1c1e))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: Color.orange.opacity(0.2), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "lock.shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.orange)
                        }
                        
                        Text("3105 SECURITY GATEWAY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .tracking(2.0)
                        
                        Text("Free Fire Max External")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Hardware Locked Private Access")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.bottom, 10)
                    
                    // Hardware Fingerprint Info Box
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("DEVICE SECURITY PROFILE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.orange)
                            Spacer()
                            Text("1-DEVICE LOCK")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundColor(.orange)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Text("Device:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("\(authService.deviceName) (\(authService.deviceModel))")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("HWID Hash:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(String(authService.hardwareID.prefix(16)) + "...")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                    .padding(16)
                    .background(Color(hex: 0x151517))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    
                    // License Key Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("LICENSE KEY")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            
                            Button(action: {
                                if let string = UIPasteboard.general.string {
                                    licenseKeyInput = string.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Paste")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange.opacity(0.7))
                            
                            TextField("3105-MAX-XXXX-XXXX-XXXX", text: $licenseKeyInput)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                            
                            if !licenseKeyInput.isEmpty {
                                Button(action: { licenseKeyInput = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(hex: 0x1f1f22))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text("Your key will be permanently bound to this device upon activation.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(16)
                    .background(Color(hex: 0x151517))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    
                    // Activate Button
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        authService.login(licenseKey: licenseKeyInput) { success, error in
                            if !success, let error = error {
                                alertMessage = error
                                showAlert = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("AUTHENTICATE DEVICE")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(authService.isLoading || licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
                    
                    // Support Links
                    VStack(spacing: 8) {
                        Text("Need a key or support?")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 16) {
                            Link(destination: URL(string: "https://discord.gg/KPJzd42rme")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Text("Discord")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                            }
                            
                            Text("•").foregroundColor(.white.opacity(0.3))
                            
                            Link(destination: URL(string: "https://guns.lol/bytenichen7")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.circle.fill")
                                    Text("Developer")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Authentication Failed"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
