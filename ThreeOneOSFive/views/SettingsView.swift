import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // App Logo & Build Hero Card
                    appHeroCard
                        .staggeredAppearance(index: 0)

                    // Language Selector
                    languageSection
                        .staggeredAppearance(index: 1)

                    // Feature Visibility Toggles
                    featureTogglesSection
                        .staggeredAppearance(index: 2)

                    // Device Specifications
                    deviceSpecSection
                        .staggeredAppearance(index: 3)

                    // Social & Community Credits
                    creditsSection
                        .staggeredAppearance(index: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppTheme.bgBase.ignoresSafeArea())
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private var appHeroCard: some View {
        HStack(spacing: 16) {
            AppLogo()

            VStack(alignment: .leading, spacing: 3) {
                Text("3105 External Engine")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(language.text("common.version", appVersion))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            StatusBadge(
                text: appState.isSupported ? "SUPPORTED" : "UNSUPPORTED",
                style: appState.isSupported ? .active : .neutral
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text("settings.language"), systemImage: "globe")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)

            Picker(language.text("settings.language"), selection: $languageCode) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var featureTogglesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.text("dashboard.features"), systemImage: "slider.horizontal.3")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 8) {
                PremiumToggleRow(
                    title: language.text("tab.cleaner"),
                    subtitle: "Deep cache and memory garbage collection",
                    icon: "sparkles",
                    isOn: $cleanerEnabled
                )

                PremiumToggleRow(
                    title: language.text("settings.developer_mode"),
                    subtitle: language.text("settings.developer_mode_footer"),
                    icon: "hammer.fill",
                    isOn: $developerModeEnabled
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var deviceSpecSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.text("common.device"), systemImage: "iphone")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 1) {
                specRow(
                    title: language.text("dashboard.hardware_model"),
                    value: AppInfo.displayMachineName
                )
                Divider().background(AppTheme.borderSubtle)
                specRow(
                    title: language.text("settings.ios_version"),
                    value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                )
            }
            .background(AppTheme.bgElevated.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.text("settings.credits"), systemImage: "heart.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 1) {
                creditsRow(
                    name: "Nicchen",
                    role: language.text("credit.yangjiii"),
                    url: "https://t.me/ioscrackvn"
                )
                Divider().background(AppTheme.borderSubtle)
                creditsRow(
                    name: "0xjohnnydev",
                    role: language.text("credit.filzaslop"),
                    url: "https://github.com/0xjohnnydev/FilzaSlop"
                )
                Divider().background(AppTheme.borderSubtle)
                creditsRow(
                    name: "LeminLimez",
                    role: language.text("credit.pocket_poster"),
                    url: "https://github.com/leminlimez/Pocket-Poster"
                )
                Divider().background(AppTheme.borderSubtle)
                creditsRow(
                    name: "CrazyMind90",
                    role: language.text("credit.sandbox_escape"),
                    url: "https://github.com/CrazyMind90"
                )
            }
            .background(AppTheme.bgElevated.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private func specRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(role)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.1.6"
    }
}
