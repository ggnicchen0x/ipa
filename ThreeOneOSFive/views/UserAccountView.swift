import SwiftUI
import UIKit

struct UserAccountView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Profile Header Hero Card
                    profileHeroCard
                        .staggeredAppearance(index: 0)

                    // License & Plan Status Card
                    licenseSection
                        .staggeredAppearance(index: 1)

                    // Device & System Specifications Card
                    deviceInfoSection
                        .staggeredAppearance(index: 2)

                    // Community & Support Card
                    supportSection
                        .staggeredAppearance(index: 3)

                    // Sign Out Action
                    signOutButton
                        .staggeredAppearance(index: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppTheme.bgBase.ignoresSafeArea())
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("ACCOUNT")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var profileHeroCard: some View {
        HStack(spacing: 16) {
            // Avatar with gradient purple border
            ZStack {
                Circle()
                    .fill(AppTheme.accentMuted)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.gradientPurple, lineWidth: 2)
                    )

                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(UIDevice.current.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    StatusBadge(text: "AUTHENTICATED", style: .active)
                }

                Text("BYTE IOS External Member")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var licenseSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("License & Entitlement", systemImage: "key.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
            }

            VStack(spacing: 1) {
                accountRow(
                    label: "License Key",
                    icon: "lock.shield.fill",
                    value: AuthService.shared.activeLicense.isEmpty ? "Session Active" : AuthService.shared.activeLicense,
                    isMonospaced: true,
                    highlight: true
                )
                
                Divider().background(AppTheme.borderSubtle)

                accountRow(
                    label: "Plan Expiry",
                    icon: "clock.badge.checkmark",
                    value: AuthService.shared.formattedExpirationText,
                    isMonospaced: false,
                    highlight: AuthService.shared.formattedExpirationText == "LIFETIME"
                )
            }
            .background(AppTheme.bgElevated.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var deviceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Device Specifications", systemImage: "iphone")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
            }

            VStack(spacing: 1) {
                accountRow(
                    label: "Hardware Model",
                    icon: "laptopcomputer.and.iphone",
                    value: AppInfo.hardwareDisplayName
                )
                Divider().background(AppTheme.borderSubtle)

                accountRow(
                    label: "Operating System",
                    icon: "apple.logo",
                    value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                )
                Divider().background(AppTheme.borderSubtle)

                accountRow(
                    label: "App Build",
                    icon: "number.square.fill",
                    value: "v\(appVersion)"
                )
            }
            .background(AppTheme.bgElevated.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var supportSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Community & Support", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
            }

            VStack(spacing: 1) {
                if let discordURL = URL(string: "https://discord.gg/KPJzd42rme") {
                    Link(destination: discordURL) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 22)
                            Text("Official Discord")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }

                Divider().background(AppTheme.borderSubtle)

                if let devURL = URL(string: "https://guns.lol/bytenichen7") {
                    Link(destination: devURL) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 22)
                            Text("Developer Profile")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(AppTheme.bgElevated.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            withAnimation(AppAnimation.springStandard) {
                AuthService.shared.logout()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                Text("Sign Out / Switch License")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.red.opacity(0.12))
            .foregroundStyle(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func accountRow(
        label: String,
        icon: String,
        value: String,
        isMonospaced: Bool = false,
        highlight: Bool = false
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textMuted)
                .frame(width: 22)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(isMonospaced ? .system(size: 12, weight: .medium, design: .monospaced) : .subheadline)
                .foregroundStyle(highlight ? AppTheme.accent : AppTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.1.3"
    }
}
