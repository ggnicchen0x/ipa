import SwiftUI
import UIKit

struct UserAccountView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.15))
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(UIDevice.current.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("BYTE IOS External User")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    LabeledContent {
                        Text(UIDevice.current.name)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Device Name", systemImage: "iphone")
                    }

                    LabeledContent {
                        Text(AppInfo.hardwareDisplayName)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Hardware Model", systemImage: "laptopcomputer.and.iphone")
                    }

                    LabeledContent {
                        Text("\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("iOS Version", systemImage: "apple.logo")
                    }

                    LabeledContent {
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("App Version", systemImage: "info.circle")
                    }
                } header: {
                    Text("Device & System Info")
                }

                Section {
                    HStack {
                        Label("Kernel Status", systemImage: "bolt.shield")
                        Spacer()
                        Text(appState.exploitStatus.isSuccess ? "Active & Rooted" : "Ready to Exploit")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(appState.exploitStatus.isSuccess ? .green : .orange)
                    }

                    HStack {
                        Label("Exploit Engine", systemImage: "cpu")
                        Spacer()
                        Text(appState.exploitStatus.displayText)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Security & Core Status")
                }

                Section {
                    LabeledContent {
                        Text(AuthService.shared.activeLicense.isEmpty ? "Authorized Session" : AuthService.shared.activeLicense)
                            .font(.footnote.monospaced())
                            .foregroundStyle(AppTheme.accent)
                    } label: {
                        Label("License Key", systemImage: "key.fill")
                    }

                    LabeledContent {
                        Text(AuthService.shared.formattedExpirationText)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AuthService.shared.formattedExpirationText.contains("Expired") ? Color.red : (AuthService.shared.formattedExpirationText == "LIFETIME" ? AppTheme.accent : Color.primary))
                    } label: {
                        Label("Plan Expiry", systemImage: "clock.badge.checkmark")
                    }

                    Button(role: .destructive) {
                        AuthService.shared.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Sign Out / Switch License", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                } header: {
                    Text("License & Authentication")
                }
            }
            .navigationTitle("Account")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "2.0 (ATH)"
    }
}
