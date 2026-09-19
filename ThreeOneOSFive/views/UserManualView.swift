import SwiftUI

struct UserManualView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USER MANUAL")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("BYTE IOS External Guide")
                            .font(.title2.weight(.bold))
                        Text("Follow the exact timing below to activate external modifications safely.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // 1. Aim Drag
                Section {
                    ManualStepRow(number: 1, text: "Open the game.")
                    ManualStepRow(number: 2, text: "When the loading screen reaches around 40%, minimize the game.")
                    ManualStepRow(number: 3, text: "Open this application and toggle Aim Drag ON.")
                    ManualStepRow(number: 4, text: "Return to the game and continue.")
                    ManualStepRow(number: 5, text: "After you reach the lobby, minimize the game again.")
                    ManualStepRow(number: 6, text: "Come back to this application and toggle Aim Drag OFF.")
                    ManualStepRow(number: 7, text: "That's it.")
                } header: {
                    Label("Aim Drag", systemImage: "scope")
                        .foregroundStyle(.red)
                }

                // 2. 144 FPS Unlock
                Section {
                    ManualStepRow(number: 1, text: "Toggle 144 FPS Unlock ON first.")
                    ManualStepRow(number: 2, text: "Open the game.")
                    ManualStepRow(number: 3, text: "You will see the FPS is unlocked.")
                } header: {
                    Label("144 FPS Unlock", systemImage: "speedometer")
                        .foregroundStyle(.green)
                }

                // 3. Aim Body
                Section {
                    ManualStepRow(number: 1, text: "Fully open the game and reach the lobby.")
                    ManualStepRow(number: 2, text: "While in the lobby, toggle Aim Body ON.")
                    ManualStepRow(number: 3, text: "Enter a match.")
                    ManualStepRow(number: 4, text: "After you are inside the match, toggle Aim Body OFF.")
                } header: {
                    Label("Aim Body", systemImage: "bolt.fill")
                        .foregroundStyle(.blue)
                }

                // 4. Magic Bullet
                Section {
                    ManualStepRow(number: 1, text: "Fully open the game and reach the lobby.")
                    ManualStepRow(number: 2, text: "While in the lobby, toggle Magic Bullet ON.")
                    ManualStepRow(number: 3, text: "Enter a match.")
                    ManualStepRow(number: 4, text: "After you are inside the match, toggle Magic Bullet OFF.")
                } header: {
                    Label("Magic Bullet", systemImage: "flame.fill")
                        .foregroundStyle(.purple)
                }
            }
            .navigationTitle("New")
        }
    }
}

private struct ManualStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22, height: 22)
                .background(AppTheme.accent.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
