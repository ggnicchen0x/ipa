import SwiftUI

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255.0
        let green = Double((hex >> 8) & 0xff) / 255.0
        let blue = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public struct ActiveAlert: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let isUpdate: Bool
    
    public init(title: String, message: String, isUpdate: Bool = false) {
        self.title = title
        self.message = message
        self.isUpdate = isUpdate
    }
}

public struct LoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var licenseKeyInput: String = ""
    @State private var activeAlert: ActiveAlert? = nil
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
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(hex: 0x1c1c1e))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
                                 )
                                .shadow(color: AppTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                            
                            if let logoImg = UIImage(named: "AppLogo") ?? UIImage(named: "AppIcon60x60@2x") ?? Bundle.main.path(forResource: "AppLogo", ofType: "png").flatMap(UIImage.init(contentsOfFile:)) {
                                Image(uiImage: logoImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 76, height: 76)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            } else {
                                Image(systemName: "lock.shield.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(AppTheme.accent)
                            }
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
                    
                    // Live Maintenance Warning Banner
                    if authService.maintenanceDetected {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: 0xf59e0b))
                                .font(.system(size: 22))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SERVICE UNDER MAINTENANCE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: 0xf59e0b))
                                Text(authService.maintenanceMessage.isEmpty ? "Panel is Under Maintainance." : authService.maintenanceMessage)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.9))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: 0xf59e0b).opacity(0.16))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xf59e0b).opacity(0.45), lineWidth: 1)
                        )
                    }
                    
                    // Spam Lockout Warning Banner
                    if authService.isLockedOut {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: 0xef4444))
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SPAM TIMEOUT ACTIVE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: 0xef4444))
                                Text("Repeated login taps detected. Cooldown in progress: \(authService.formattedLockoutTime)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: 0xef4444).opacity(0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xef4444).opacity(0.35), lineWidth: 1)
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
                            Text("DEVICE LOCK")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.accent.opacity(0.25))
                                .cornerRadius(4)
                                .foregroundColor(Color(hex: 0xd8b4fe))
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
                            
                            TextField("BYTE-XXXX-XXXX-XXXX", text: $licenseKeyInput)
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
                        if now.timeIntervalSince(lastTapTime) < 1.0 {
                            return
                        }
                        lastTapTime = now
                        
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        // If maintenance is already known
                        if authService.maintenanceDetected {
                            activeAlert = ActiveAlert(
                                title: "Service Under Maintenance",
                                message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintainance." : authService.maintenanceMessage,
                                isUpdate: false
                            )
                            return
                        }
                        
                        authService.login(licenseKey: licenseKeyInput) { success, error in
                            if !success, let error = error {
                                if error == "UPDATE_REQUIRED" || authService.updateDetected {
                                    activeAlert = ActiveAlert(
                                        title: authService.updateTitle,
                                        message: authService.updateMessage,
                                        isUpdate: true
                                    )
                                    return
                                }
                                
                                if authService.maintenanceDetected || error.contains("Maintenance") || error.contains("maintenance") || error.contains("paused") {
                                    let msg = authService.maintenanceMessage.isEmpty ? error : authService.maintenanceMessage
                                    activeAlert = ActiveAlert(
                                        title: "Service Under Maintenance",
                                        message: msg,
                                        isUpdate: false
                                    )
                                } else if error.contains("Spam") || error.contains("timed out") {
                                    activeAlert = ActiveAlert(
                                        title: "Security Warning: Spam Detected",
                                        message: error,
                                        isUpdate: false
                                    )
                                } else {
                                    activeAlert = ActiveAlert(
                                        title: "Authentication Failed",
                                        message: error,
                                        isUpdate: false
                                    )
                                }
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
                        .background(
                            authService.isLockedOut
                                ? AnyView(Color(hex: 0x7f1d1d))
                                : AnyView(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: 0xb76ef8), Color(hex: 0x8b36e8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(
                            color: authService.isLockedOut
                                ? Color.red.opacity(0.3)
                                : Color(hex: 0xa855f7).opacity(0.45),
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(authService.isLoading || authService.isLockedOut || licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authService.isLockedOut) ? 0.78 : 1.0)
                    
                    // Support Links
                    VStack(spacing: 8) {
                        Text("Need a key or support?")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 16) {
                            if let discordURL = URL(string: "https://discord.gg/KPJzd42rme") {
                                Link(destination: discordURL) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                        Text("Discord")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                                }
                            }
                            
                            Text("•").foregroundColor(.white.opacity(0.3))
                            
                            if let devURL = URL(string: "https://guns.lol/bytenichen7") {
                                Link(destination: devURL) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.circle.fill")
                                        Text("Developer")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let saved = authService.savedLicenseKeyText
                if !saved.isEmpty {
                    licenseKeyInput = saved
                }
            }
            if authService.maintenanceDetected {
                activeAlert = ActiveAlert(
                    title: "Service Under Maintenance",
                    message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintainance." : authService.maintenanceMessage,
                    isUpdate: false
                )
            } else if authService.updateDetected {
                activeAlert = ActiveAlert(
                    title: authService.updateTitle,
                    message: authService.updateMessage,
                    isUpdate: true
                )
            }
        }
        .onReceive(authService.$maintenanceDetected) { isMaintenance in
            if isMaintenance {
                activeAlert = ActiveAlert(
                    title: "Service Under Maintenance",
                    message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintainance." : authService.maintenanceMessage,
                    isUpdate: false
                )
            }
        }
        .onReceive(authService.$updateDetected) { detected in
            if detected && !authService.maintenanceDetected {
                activeAlert = ActiveAlert(
                    title: authService.updateTitle,
                    message: authService.updateMessage,
                    isUpdate: true
                )
            }
        }
        .alert(item: $activeAlert) { item in
            if item.isUpdate {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("OK")) {
                        let target = authService.updateDownloadURL.isEmpty ? "https://github.com/nicchen0xf/Swift-ios/releases" : authService.updateDownloadURL
                        if let url = URL(string: target) {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            } else {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("Understood"))
                )
            }
        }
    }
}
