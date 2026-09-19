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
    @State private var alertTitle: String = "Authentication Failed"
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isPasting: Bool = false
    @State private var lastTapTime: Date = Date.distantPast
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background subtle gradient glow
            RadialGradient(
                gradient: Gradient(colors: [AppTheme.accent.opacity(0.18), Color.clear]),
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
                                        .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1.5)
                                )
                                .shadow(color: AppTheme.accent.opacity(0.25), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "lock.shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(AppTheme.accent)
                        }
                        
                        Text("BYTE IOS SECURITY GATEWAY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.accent)
                            .tracking(2.0)
                        
                        Text("BYTE IOS EXTERNAL")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Hardware Locked Private Access • v\(authService.appVersion)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.bottom, 10)
                    
                    // Spam Lockout Warning Banner
                    if authService.isLockedOut {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: 0xf59e0b))
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SPAM TIMEOUT ACTIVE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: 0xf59e0b))
                                Text("Repeated login taps detected. Cooldown in progress: \(authService.formattedLockoutTime)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: 0xf59e0b).opacity(0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xf59e0b).opacity(0.35), lineWidth: 1)
                        )
                    }
                    
                    // Hardware Fingerprint Info Box
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(AppTheme.accent)
                                .font(.system(size: 14))
                            Text("DEVICE SECURITY PROFILE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(AppTheme.accent)
                            Spacer()
                            Text("1-DEVICE LOCK")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundColor(AppTheme.accent)
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
                                .foregroundColor(AppTheme.accent.opacity(0.85))
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
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accent.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(AppTheme.accent.opacity(0.8))
                            
                            TextField("3105-MAX-XXXX-XXXX-XXXX", text: $licenseKeyInput)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .disabled(authService.isLockedOut)
                            
                            if !licenseKeyInput.isEmpty && !authService.isLockedOut {
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
                                .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
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
                    
                    // Activate Button with Lockout & Debounce
                    Button(action: {
                        let now = Date()
                        if now.timeIntervalSince(lastTapTime) < 1.5 {
                            // Debounce rapid clicking
                            return
                        }
                        lastTapTime = now
                        
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        authService.login(licenseKey: licenseKeyInput) { success, error in
                            if !success, let error = error {
                                if error.contains("New update") || error.contains("Update Required") {
                                    alertTitle = "New Update Detected"
                                } else if error.contains("Server Maintenance") || error.contains("maintenance") || error.contains("paused") {
                                    alertTitle = "Service Under Maintenance"
                                } else if error.contains("Spam") || error.contains("timed out") {
                                    alertTitle = "Security Warning: Spam Detected"
                                } else {
                                    alertTitle = "Authentication Failed"
                                }
                                alertMessage = error
                                showAlert = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else if authService.isLockedOut {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("LOCKED OUT (\(authService.formattedLockoutTime))")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("AUTHENTICATE DEVICE")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(authService.isLockedOut ? Color(hex: 0x7f1d1d) : AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: authService.isLockedOut ? Color.red.opacity(0.3) : AppTheme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(authService.isLoading || authService.isLockedOut || licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authService.isLockedOut) ? 0.6 : 1.0)
                    
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
                                .foregroundColor(AppTheme.accent)
                            }
                            
                            Text("•").foregroundColor(.white.opacity(0.3))
                            
                            Link(destination: URL(string: "https://guns.lol/bytenichen7")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.circle.fill")
                                    Text("Developer")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
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
            if alertTitle == "New Update Detected" || alertTitle == "Service Under Maintenance" {
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("Open Discord")) {
                        if let url = URL(string: "https://discord.gg/KPJzd42rme") {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text("Close"))
                )
            } else {
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Understood"))
                )
            }
        }
    }
}
