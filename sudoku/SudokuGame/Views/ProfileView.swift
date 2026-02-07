import SwiftUI

struct ProfileSwitcherView: View {
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddProfile = false
    @State private var newProfileName = ""
    @State private var selectedSymbol = UserProfile.availableSymbols[0]
    @State private var selectedColor = "blue"

    var body: some View {
        NavigationView {
            List {
                // Current profile card
                if let current = profileManager.currentProfile {
                    Section {
                        ProfileCardView(profile: current, isCurrentProfile: true)
                    } header: {
                        Text("Current Profile")
                    }
                }

                // Other profiles
                let otherProfiles = profileManager.profiles.filter { $0.id != profileManager.currentProfileId }
                if !otherProfiles.isEmpty {
                    Section {
                        ForEach(otherProfiles) { profile in
                            ProfileRowView(profile: profile)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    profileManager.switchToProfile(profile)
                                    dismiss()
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                profileManager.deleteProfile(otherProfiles[index])
                            }
                        }
                    } header: {
                        Text("Switch Profile")
                    }
                }

                // Add new profile
                Section {
                    Button(action: { showAddProfile = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add New Profile")
                        }
                    }
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                AddProfileView(
                    profileManager: profileManager,
                    isPresented: $showAddProfile
                )
            }
        }
    }
}

struct ProfileCardView: View {
    let profile: UserProfile
    let isCurrentProfile: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Avatar and name
            HStack(spacing: 16) {
                Image(systemName: profile.avatarSymbol)
                    .font(.system(size: 50))
                    .foregroundColor(profile.color)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if isCurrentProfile {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    Text("Playing since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItemView(title: "Played", value: "\(profile.gamesPlayed)")
                StatItemView(title: "Completed", value: "\(profile.gamesCompleted)")
                StatItemView(title: "Win Rate", value: String(format: "%.0f%%", profile.winRate))
            }

            Divider()

            // Best times
            VStack(alignment: .leading, spacing: 8) {
                Text("Best Times")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 20) {
                    BestTimeView(difficulty: "Easy", time: profile.formattedBestTime(profile.bestTimeEasy), color: .green)
                    BestTimeView(difficulty: "Medium", time: profile.formattedBestTime(profile.bestTimeMedium), color: .orange)
                    BestTimeView(difficulty: "Hard", time: profile.formattedBestTime(profile.bestTimeHard), color: .red)
                }
            }

            // Completion breakdown
            if profile.gamesCompleted > 0 {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed by Difficulty")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        CompletionBadge(label: "Easy", count: profile.easyCompleted, color: .green)
                        CompletionBadge(label: "Medium", count: profile.mediumCompleted, color: .orange)
                        CompletionBadge(label: "Hard", count: profile.hardCompleted, color: .red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatItemView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BestTimeView: View {
    let difficulty: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(time)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(difficulty)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompletionBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ProfileRowView: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: profile.avatarSymbol)
                .font(.system(size: 36))
                .foregroundColor(profile.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.headline)
                Text("\(profile.gamesCompleted) games completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct AddProfileView: View {
    @ObservedObject var profileManager: ProfileManager
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var selectedSymbol = UserProfile.availableSymbols[0]
    @State private var selectedColor = "blue"

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                } header: {
                    Text("Profile Name")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(UserProfile.availableSymbols, id: \.self) { symbol in
                            Button(action: { selectedSymbol = symbol }) {
                                Image(systemName: symbol)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedSymbol == symbol ? colorFromString(selectedColor) : .gray)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .stroke(selectedSymbol == symbol ? colorFromString(selectedColor) : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Avatar")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(UserProfile.availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                }

                // Preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 60))
                                .foregroundColor(colorFromString(selectedColor))
                            Text(name.isEmpty ? "New Player" : name)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let profile = UserProfile(
                            name: name.isEmpty ? "Player \(profileManager.profiles.count + 1)" : name,
                            avatarSymbol: selectedSymbol,
                            avatarColor: selectedColor
                        )
                        profileManager.addProfile(profile)
                        isPresented = false
                    }
                }
            }
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

struct AvatarButton: View {
    let profile: UserProfile?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let profile = profile {
                Image(systemName: profile.avatarSymbol)
                    .font(.system(size: 28))
                    .foregroundColor(profile.color)
            } else {
                Image(systemName: "person.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ProfileSwitcherView(profileManager: ProfileManager())
}
