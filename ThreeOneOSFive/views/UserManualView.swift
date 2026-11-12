import SwiftUI

struct UserManualView: View {
    @Environment(\.appLanguage) private var language
    @State private var expandedSection: String? = nil

    private struct GuideSection: Identifiable {
        let id: String
        let title: String
        let icon: String
        let subtitle: String
        let steps: [String]
    }

    private let sections: [GuideSection] = [
        GuideSection(
            id: "aim_drag",
            title: "Aim Drag",
            icon: "scope",
            subtitle: "Smooth crosshair stabilization & drag assist",
            steps: [
                "Open the game.",
                "When the loading screen reaches around 40%, minimize the game.",
                "Open this application and toggle Aim Drag ON (select CS Rank or Rooms mode).",
                "Return to the game and continue.",
                "After you reach the lobby, minimize the game again.",
                "Come back to this application and toggle Aim Drag OFF.",
                "Safe mode engaged — enjoy the match."
            ]
        ),
        GuideSection(
            id: "fps_unlock",
            title: "144 FPS Unlock",
            icon: "speedometer",
            subtitle: "Bypass frame rate caps for high refresh displays",
            steps: [
                "Toggle 144 FPS Unlock ON first.",
                "Open the game.",
                "Confirm the frame rate counter reflects the unlocked cap."
            ]
        ),
        GuideSection(
            id: "aim_body",
            title: "Aim Body",
            icon: "bolt.fill",
            subtitle: "Target acquisition lock for torso hits",
            steps: [
                "Fully open the game and reach the lobby.",
                "While in the lobby, toggle Aim Body ON.",
                "Enter a match.",
                "After you are inside the match, toggle Aim Body OFF."
            ]
        ),
        GuideSection(
            id: "magic_bullet",
            title: "Magic Bullet",
            icon: "flame.fill",
            subtitle: "High precision bullet trajectory alignment",
            steps: [
                "Fully open the game and reach the lobby.",
                "While in the lobby, toggle Magic Bullet ON.",
                "Enter a match.",
                "After you are inside the match, toggle Magic Bullet OFF."
            ]
        ),
        GuideSection(
            id: "visuals",
            title: "Visuals",
            icon: "eye.fill",
            subtitle: "Hologram player indicators and positioning",
            steps: [
                "Toggle Visuals ON first.",
                "Open the game and reach the lobby.",
                "Go to Training ground.",
                "While inside Training, toggle Visuals OFF.",
                "Return to the game — that's it."
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Header hero card
                    headerCard
                        .staggeredAppearance(index: 0)

                    // Sections
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        guideCard(for: section, index: index + 1)
                            .staggeredAppearance(index: index + 1)
                    }

                    // Bottom safe usage note
                    footerCard
                        .staggeredAppearance(index: sections.count + 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppTheme.bgBase.ignoresSafeArea())
            .navigationTitle("New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("USER GUIDE")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadge(text: "OPERATIONAL MANUAL", style: .active)
                Spacer()
                Text("v1.1.6")
                    .font(.caption2.monospaced())
                    .foregroundStyle(AppTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Timing & Execution")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Follow the exact timing below to activate external modifications safely and avoid state desync.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(2)
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

    private func guideCard(for section: GuideSection, index: Int) -> some View {
        let isExpanded = expandedSection == section.id || expandedSection == nil

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(AppAnimation.springStandard) {
                    if expandedSection == section.id {
                        expandedSection = ""
                    } else {
                        expandedSection = section.id
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.accentMuted)
                            .frame(width: 36, height: 36)
                        Image(systemName: section.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(section.subtitle)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(section.steps.enumerated()), id: \.offset) { stepIndex, step in
                        stepRow(number: stepIndex + 1, text: step)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isExpanded ? AppTheme.borderFocused : AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(AppTheme.accentMuted)
                        .overlay(Circle().stroke(AppTheme.accent.opacity(0.3), lineWidth: 0.8))
                )

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(2)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var footerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Safety Guard")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Always verify kernel patch status in the Menu tab before launching external sessions.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }
}
