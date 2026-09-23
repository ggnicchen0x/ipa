import SwiftUI

public struct ReleaseNotesModalView: View {
    let release: PackageReleaseInfo
    @ObservedObject private var releasesService = ReleasesService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init(release: PackageReleaseInfo) {
        self.release = release
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Badge
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 1.0))
                        
                        Text("NEW UPDATE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 1.0))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35), lineWidth: 1)
                            )
                    )
                    
                    Text(release.packageName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(release.filename)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(release.versionTag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 20)
                
                // "What's New" Section
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's New:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(parseBullets(release.releaseNotes), id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color(red: 0.65, green: 0.45, blue: 1.0))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    
                                    Text(bullet)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(white: 0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        
                        // Verification note
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            
                            Text("Latest patch payload verified & ready in cloud delivery.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 16)
                
                // Action Button: [Continue]
                Button {
                    releasesService.acknowledgeRelease(release: release) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.35, blue: 0.95),
                                Color(red: 0.45, green: 0.25, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func parseBullets(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var bullets: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let clean = trimmed.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty { bullets.append(clean) }
            } else {
                bullets.append(trimmed)
            }
        }
        return bullets.isEmpty ? ["Package updated with latest enhancements and optimizations."] : bullets
    }
}
