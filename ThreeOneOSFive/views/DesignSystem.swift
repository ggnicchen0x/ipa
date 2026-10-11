import SwiftUI
import UIKit

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255.0
        let green = Double((hex >> 8) & 0xff) / 255.0
        let blue = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Design Tokens

enum AppTheme {
    // Core Purple Palette
    static let accent = Color(red: 0.68, green: 0.45, blue: 0.98)        // #ad73fa
    static let purple = Color(red: 0.68, green: 0.45, blue: 0.98)
    static let purpleDark = Color(red: 0.45, green: 0.18, blue: 0.82)
    static let purpleLight = Color(red: 0.85, green: 0.71, blue: 0.99)    // #d8b4fe
    static let purpleGlow = Color(red: 0.66, green: 0.33, blue: 0.97)     // #a855f7
    static let purpleMuted = Color(red: 0.49, green: 0.23, blue: 0.93)    // #7c3aed

    // Gradient Presets
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.72, green: 0.43, blue: 0.97), Color(red: 0.49, green: 0.23, blue: 0.93)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let subtleGradient = LinearGradient(
        colors: [accent.opacity(0.18), accent.opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Surfaces
    static let pageBackground = Color(uiColor: UIColor { _ in UIColor(red: 0.035, green: 0.035, blue: 0.043, alpha: 1.0) }) // #09090b
    static let cardBackground = Color(red: 0.071, green: 0.071, blue: 0.082)  // #121215
    static let cardBackgroundElevated = Color(red: 0.09, green: 0.09, blue: 0.1) // #171719
    static let consoleBackground = Color(uiColor: UIColor { _ in UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00) })

    // Borders
    static let cardBorder = Color.white.opacity(0.06)
    static let cardBorderActive = accent.opacity(0.35)
    static let subtleBorder = Color.white.opacity(0.04)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // Surface Aliases
    static let bgBase = pageBackground
    static let bgCard = cardBackground
    static let bgElevated = cardBackgroundElevated
    static let borderSubtle = cardBorder
    static let borderFocused = cardBorderActive
    static let textMuted = textTertiary
    static let accentMuted = accent.opacity(0.15)
    static let gradientPurple = accentGradient

    // Spacing
    static let pageInset: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let iconCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24

    // Icon sizing
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18

    // Legacy
    static let contentCardCornerRadius: CGFloat = 20
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}

// MARK: - Animation Constants

enum AppAnimation {
    static let defaultDuration: Double = 0.5
    static let quickDuration: Double = 0.25
    static let microDuration: Double = 0.15

    static let smooth: Animation = .spring(response: 0.5, dampingFraction: 0.82)
    static let springStandard: Animation = .spring(response: 0.5, dampingFraction: 0.82)
    static let quick: Animation = .spring(response: 0.3, dampingFraction: 0.85)
    static let micro: Animation = .easeOut(duration: 0.15)
    static let expand: Animation = .spring(response: 0.45, dampingFraction: 0.78)

    /// Returns nil if reduce-motion is active, otherwise returns the given animation
    static func respectingMotion(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    /// Stagger delay for list item animations
    static func staggerDelay(index: Int, base: Double = 0.04) -> Double {
        Double(index) * base
    }
}

// MARK: - AppCardBorder

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color(uiColor: .separator).opacity(0.22),
            lineWidth: 0.5
        )
        .accessibilityHidden(true)
    }
}

// MARK: - AppRowIcon (Enhanced)

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.08), lineWidth: 0.5)
                )
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

// MARK: - Premium Section Header

struct PremiumSectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.accent.opacity(0.9))
                .tracking(0.8)
        }
    }
}

// MARK: - Premium Toggle Row

struct PremiumToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var isProcessing: Bool = false
    var isDisabled: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>,
        isProcessing: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
        self.isProcessing = isProcessing
        self.isDisabled = isDisabled
    }

    init(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        isProcessing: Bool = false,
        isDisabled: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.isProcessing = isProcessing
        self.isDisabled = isDisabled
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                        .fill(isOn ? AppTheme.accent.opacity(0.15) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                                .stroke(isOn ? AppTheme.accent.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isOn ? AppTheme.accent : .secondary)
                }
                .frame(width: 32, height: 32)
                .animation(AppAnimation.respectingMotion(AppAnimation.quick, reduceMotion: reduceMotion), value: isOn)

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if isProcessing {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppTheme.accent)
                }
            }
        }
        .tint(AppTheme.accent)
        .disabled(isDisabled || isProcessing)
    }
}

// MARK: - Gradient Action Button

struct GradientActionButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum ButtonVariant {
        case primary, destructive, secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(buttonBackground)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous)
                    .stroke(buttonBorderColor, lineWidth: 0.5)
            )
            .shadow(color: buttonShadowColor, radius: 12, x: 0, y: 4)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            AppTheme.accentGradient
        case .destructive:
            LinearGradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .secondary:
            LinearGradient(colors: [AppTheme.cardBackgroundElevated, AppTheme.cardBackground], startPoint: .top, endPoint: .bottom)
        }
    }

    private var buttonBorderColor: Color {
        switch style {
        case .primary: return AppTheme.accent.opacity(0.4)
        case .destructive: return Color.red.opacity(0.4)
        case .secondary: return Color.white.opacity(0.08)
        }
    }

    private var buttonShadowColor: Color {
        switch style {
        case .primary: return AppTheme.purpleGlow.opacity(0.3)
        case .destructive: return Color.red.opacity(0.2)
        case .secondary: return Color.clear
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    var color: Color = AppTheme.accent
    var isActive: Bool = true

    enum BadgeStyle {
        case active, neutral, warning, error
    }

    init(text: String, style: BadgeStyle = .active) {
        self.text = text
        switch style {
        case .active:
            self.color = AppTheme.accent
            self.isActive = true
        case .neutral:
            self.color = Color.gray
            self.isActive = false
        case .warning:
            self.color = Color.orange
            self.isActive = true
        case .error:
            self.color = Color.red
            self.isActive = true
        }
    }

    init(text: String, color: Color = AppTheme.accent, isActive: Bool = true) {
        self.text = text
        self.color = color
        self.isActive = isActive
    }

    var body: some View {
        HStack(spacing: 5) {
            if isActive {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .shadow(color: color.opacity(0.6), radius: 3)
            }
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppTheme.accent.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Animated Appearance Modifier

struct StaggeredAppearance: ViewModifier {
    let index: Int
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(AppAnimation.smooth.delay(AppAnimation.staggerDelay(index: index))) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func staggeredAppearance(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }
}

// MARK: - AppSearchField

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - AppLogo

struct AppLogo: View {
    var size: CGFloat = 44

    private static let cachedIcon: UIImage? = {
        UIImage(named: "AppLogo")
            ?? UIImage(named: "AppIcon60x60")
            ?? UIImage(named: "AppIcon")
            ?? Bundle.main.path(forResource: "AppLogo", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
            ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
    }()

    var body: some View {
        Group {
            if let icon = Self.cachedIcon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }
}
