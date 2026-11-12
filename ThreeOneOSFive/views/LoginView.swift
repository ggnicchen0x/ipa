import SwiftUI
import UIKit


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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var licenseKeyInput: String = ""
    @State private var activeAlert: ActiveAlert? = nil
    @State private var lastTapTime: Date = Date.distantPast
    @State private var showDeviceInfoSheet: Bool = false
    @State private var isVisible: Bool = false
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background Base (slightly deeper for a subtler fade)
            Color(hex: 0x060608)
                .ignoresSafeArea()

            // Refined ambient highlight (soft, restrained purple vignette)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: 0xa855f7).opacity(0.09),
                    Color(hex: 0x060608).opacity(0.0)
                ]),
                center: .top,
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()

            // Bottom-edge fade — just a hint, keeps the card floating
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    // MARK: - Brand Area
                    brandHeader
                        .padding(.bottom, 28)
                    
                    // MARK: - Context Banners (Maintenance & Spam Cooldown)
                    if authService.maintenanceDetected {
                        maintenanceBanner
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    if authService.isLockedOut {
                        lockoutBanner
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // MARK: - Authentication Card
                    authenticationCard
                        .padding(.bottom, 20)
                    
                    // MARK: - Primary Action Button
                    authenticateButton
                        .padding(.bottom, 24)
                    
                    // MARK: - Support & Discreet Device Info
                    footerArea
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 12)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    isVisible = true
                }
            }
            
            loadSavedKeyIfNeeded()
            evaluateInitialAlerts()
        }
        .onReceive(authService.$maintenanceDetected) { isMaintenance in
            if isMaintenance {
                activeAlert = ActiveAlert(
                    title: "Service Under Maintenance",
                    message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintenance." : authService.maintenanceMessage,
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
        .sheet(isPresented: $showDeviceInfoSheet) {
            deviceInfoSheet
        }
    }
    
    // MARK: - Brand Header
    private var brandHeader: some View {
        VStack(spacing: 14) {
            // App Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0x141418))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(hex: 0xa855f7).opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: 0xa855f7).opacity(0.16), radius: 14, x: 0, y: 6)
                
                if let logoImg = UIImage(named: "AppLogo") ?? UIImage(named: "AppIcon60x60@2x") ?? Bundle.main.path(forResource: "AppLogo", ofType: "png").flatMap(UIImage.init(contentsOfFile:)) {
                    Image(uiImage: logoImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color(hex: 0xad73fa))
                }
            }
            
            // Typography Hierarchy
            VStack(spacing: 6) {
                Text("BYTE EXTERNAL")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color(hex: 0xd8c4ff)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: 0xa855f7).opacity(0.18), radius: 10, x: 0, y: 2)

                Text("Enter your license key to continue")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
            }
        }
    }
    
    // MARK: - License Key Card
    private var authenticationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label Row with Discreet Paste Action
            HStack {
                Text("LICENSE KEY")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)
                
                Spacer()
                
                Button(action: pasteFromClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 11, weight: .medium))
                        Text("Paste")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color(hex: 0xc084fc))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xa855f7).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(authService.isLockedOut)
                .opacity(authService.isLockedOut ? 0.4 : 1.0)
            }
            
            // Input Field Container
            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isInputFocused ? Color(hex: 0xc084fc) : Color.white.opacity(0.35))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isInputFocused)
                
                TextField("Enter license key", text: $licenseKeyInput)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .disabled(authService.isLockedOut)
                    .submitLabel(.go)
                    .onSubmit(performAuthentication)
                
                if !licenseKeyInput.isEmpty && !authService.isLockedOut {
                    Button(action: {
                        licenseKeyInput = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(hex: 0x121216))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isInputFocused ? Color(hex: 0xa855f7).opacity(0.65) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isInputFocused)
            
            // Subtle footnote
            Text("License will be bound to this device upon activation.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color.white.opacity(0.35))
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color(hex: 0x111115))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Primary Authenticate Button
    private var authenticateButton: some View {
        Button(action: performAuthentication) {
            ZStack {
                // Background Fill
                if authService.isLockedOut {
                    Color(hex: 0x3b1219)
                } else {
                    LinearGradient(
                        colors: [
                            Color(hex: 0x9333ea),
                            Color(hex: 0x7e22ce)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                // Content
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text("Verifying...")
                            .font(.system(size: 15, weight: .semibold))
                    } else if authService.isLockedOut {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Cooldown (\(authService.formattedLockoutTime))")
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        Text("Authenticate")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        authService.isLockedOut
                            ? Color(hex: 0xef4444).opacity(0.3)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(LoginPressableButtonStyle(reduceMotion: reduceMotion))
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.45 : 1.0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isButtonDisabled)
    }
    
    private var isButtonDisabled: Bool {
        authService.isLoading ||
        authService.isLockedOut ||
        licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Footer Support & Device Info
    private var footerArea: some View {
        VStack(spacing: 16) {
            // Need a key or support
            VStack(spacing: 8) {
                Text("Need assistance or a key?")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.38))
                
                HStack(spacing: 18) {
                    if let discordURL = URL(string: "https://discord.gg/KPJzd42rme") {
                        Link(destination: discordURL) {
                            HStack(spacing: 5) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 11))
                                Text("Discord")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(hex: 0xc084fc))
                        }
                    }
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.2))
                    
                    if let devURL = URL(string: "https://guns.lol/bytenichen7") {
                        Link(destination: devURL) {
                            HStack(spacing: 5) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 11))
                                Text("Developer")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(hex: 0xc084fc))
                        }
                    }
                }
            }
            
            // Secondary discreet device identifier link
            Button(action: {
                showDeviceInfoSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Device Info")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(Color.white.opacity(0.3))
                .padding(.top, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Maintenance Warning Banner
    private var maintenanceBanner: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: 0xf59e0b))
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Service Under Maintenance")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0xf59e0b))
                
                Text(authService.maintenanceMessage.isEmpty ? "The authentication panel is currently undergoing scheduled maintenance." : authService.maintenanceMessage)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: 0x241a0d))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: 0xf59e0b).opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Lockout Banner
    private var lockoutBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .foregroundColor(Color(hex: 0xef4444))
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Cooldown Active")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0xef4444))
                
                Text("Multiple attempts detected. Retry in \(authService.formattedLockoutTime).")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: 0x281014))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: 0xef4444).opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Discreet Secondary Device Info Sheet
    private var deviceInfoSheet: some View {
        ZStack {
            Color(hex: 0x0e0e11).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Device Verification")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showDeviceInfoSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.top, 20)
                
                // Device Data Card
                VStack(spacing: 12) {
                    infoRow(label: "Device Model", value: "\(authService.deviceName) (\(authService.deviceModel))")
                    Divider().background(Color.white.opacity(0.08))
                    infoRow(label: "Hardware ID", value: String(authService.hardwareID.prefix(20)) + "...")
                    Divider().background(Color.white.opacity(0.08))
                    infoRow(label: "App Version", value: "v\(authService.appVersion)")
                }
                .padding(16)
                .background(Color(hex: 0x15151a))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                Text("This hardware fingerprint is used to bind and protect your license key.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Actions & Logic
    private func pasteFromClipboard() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if let string = UIPasteboard.general.string {
            licenseKeyInput = string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func performAuthentication() {
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) >= 1.0 else { return }
        lastTapTime = now
        
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if authService.maintenanceDetected {
            activeAlert = ActiveAlert(
                title: "Service Under Maintenance",
                message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintenance." : authService.maintenanceMessage,
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
                
                if authService.maintenanceDetected || error.localizedCaseInsensitiveContains("maintenance") || error.localizedCaseInsensitiveContains("paused") {
                    let msg = authService.maintenanceMessage.isEmpty ? error : authService.maintenanceMessage
                    activeAlert = ActiveAlert(
                        title: "Service Under Maintenance",
                        message: msg,
                        isUpdate: false
                    )
                } else if error.contains("Spam") || error.localizedCaseInsensitiveContains("timed out") {
                    activeAlert = ActiveAlert(
                        title: "Cooldown Notice",
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
    }
    
    private func loadSavedKeyIfNeeded() {
        if licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let saved = authService.savedLicenseKeyText
            if !saved.isEmpty {
                licenseKeyInput = saved
            }
        }
    }
    
    private func evaluateInitialAlerts() {
        if authService.maintenanceDetected {
            activeAlert = ActiveAlert(
                title: "Service Under Maintenance",
                message: authService.maintenanceMessage.isEmpty ? "Panel is Under Maintenance." : authService.maintenanceMessage,
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
}

// MARK: - Button Press Feedback Style
private struct LoginPressableButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
