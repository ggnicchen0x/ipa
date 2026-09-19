import SwiftUI

struct DevInfoView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DEVELOPER & COMMUNITY")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("Official Links")
                            .font(.title2.weight(.bold))
                        Text("Join the community server and check developer updates.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if let discordURL = URL(string: "https://discord.gg/KPJzd42rme") {
                        Link(destination: discordURL) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(red: 0.35, green: 0.40, blue: 0.95).opacity(0.15))
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color(red: 0.35, green: 0.40, blue: 0.95))
                                }
                                .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Discord Server")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("discord.gg/KPJzd42rme")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let devURL = URL(string: "https://guns.lol/bytenichen7") {
                        Link(destination: devURL) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(AppTheme.accent.opacity(0.15))
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Developer Profile")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("guns.lol/bytenichen7")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Direct Links")
                } footer: {
                    Text("Tap any link above to open in your browser or Discord app.")
                }
            }
            .navigationTitle("Dev Info")
        }
    }
}
