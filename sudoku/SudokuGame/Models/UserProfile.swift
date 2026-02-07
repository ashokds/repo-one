import Foundation
import SwiftUI

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatarSymbol: String
    var avatarColor: String
    var createdDate: Date

    // Stats
    var gamesPlayed: Int
    var gamesCompleted: Int
    var easyCompleted: Int
    var mediumCompleted: Int
    var hardCompleted: Int
    var bestTimeEasy: TimeInterval?
    var bestTimeMedium: TimeInterval?
    var bestTimeHard: TimeInterval?
    var totalPlayTime: TimeInterval

    init(
        id: UUID = UUID(),
        name: String,
        avatarSymbol: String = "person.circle.fill",
        avatarColor: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.avatarSymbol = avatarSymbol
        self.avatarColor = avatarColor
        self.createdDate = Date()
        self.gamesPlayed = 0
        self.gamesCompleted = 0
        self.easyCompleted = 0
        self.mediumCompleted = 0
        self.hardCompleted = 0
        self.bestTimeEasy = nil
        self.bestTimeMedium = nil
        self.bestTimeHard = nil
        self.totalPlayTime = 0
    }

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesCompleted) / Double(gamesPlayed) * 100
    }

    var color: Color {
        switch avatarColor {
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

    func formattedBestTime(_ time: TimeInterval?) -> String {
        guard let time = time else { return "--:--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static let availableSymbols = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "bolt.circle.fill",
        "flame.circle.fill",
        "leaf.circle.fill",
        "moon.circle.fill",
        "sun.max.circle.fill",
        "cloud.circle.fill"
    ]

    static let availableColors = [
        "blue", "red", "orange", "yellow", "green", "purple", "pink"
    ]
}

class ProfileManager: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var currentProfileId: UUID?

    private static let profilesKey = "sudokuUserProfiles"
    private static let currentProfileKey = "sudokuCurrentProfile"

    var currentProfile: UserProfile? {
        get {
            profiles.first { $0.id == currentProfileId }
        }
        set {
            if let profile = newValue,
               let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
                saveProfiles()
            }
        }
    }

    init() {
        loadProfiles()

        // Create default profile if none exists
        if profiles.isEmpty {
            let defaultProfile = UserProfile(name: "Player 1")
            profiles.append(defaultProfile)
            currentProfileId = defaultProfile.id
            saveProfiles()
        }

        // Ensure current profile is valid
        if currentProfileId == nil || !profiles.contains(where: { $0.id == currentProfileId }) {
            currentProfileId = profiles.first?.id
            saveCurrentProfile()
        }
    }

    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: Self.profilesKey) {
            do {
                profiles = try JSONDecoder().decode([UserProfile].self, from: data)
            } catch {
                print("Failed to load profiles: \(error)")
                profiles = []
            }
        }

        if let idString = UserDefaults.standard.string(forKey: Self.currentProfileKey),
           let id = UUID(uuidString: idString) {
            currentProfileId = id
        }
    }

    func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: Self.profilesKey)
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }

    func saveCurrentProfile() {
        UserDefaults.standard.set(currentProfileId?.uuidString, forKey: Self.currentProfileKey)
    }

    func addProfile(_ profile: UserProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func deleteProfile(_ profile: UserProfile) {
        profiles.removeAll { $0.id == profile.id }

        // If deleted current profile, switch to another
        if currentProfileId == profile.id {
            currentProfileId = profiles.first?.id
            saveCurrentProfile()
        }

        saveProfiles()
    }

    func switchToProfile(_ profile: UserProfile) {
        currentProfileId = profile.id
        saveCurrentProfile()
    }

    func updateCurrentProfile(_ update: (inout UserProfile) -> Void) {
        guard var profile = currentProfile else { return }
        update(&profile)
        currentProfile = profile
    }

    func recordGameStarted() {
        updateCurrentProfile { profile in
            profile.gamesPlayed += 1
        }
    }

    func recordGameCompleted(difficulty: Difficulty, time: TimeInterval) {
        updateCurrentProfile { profile in
            profile.gamesCompleted += 1

            switch difficulty {
            case .easy:
                profile.easyCompleted += 1
                if profile.bestTimeEasy == nil || time < profile.bestTimeEasy! {
                    profile.bestTimeEasy = time
                }
            case .medium:
                profile.mediumCompleted += 1
                if profile.bestTimeMedium == nil || time < profile.bestTimeMedium! {
                    profile.bestTimeMedium = time
                }
            case .hard:
                profile.hardCompleted += 1
                if profile.bestTimeHard == nil || time < profile.bestTimeHard! {
                    profile.bestTimeHard = time
                }
            }
        }
    }

    func addPlayTime(_ time: TimeInterval) {
        updateCurrentProfile { profile in
            profile.totalPlayTime += time
        }
    }
}
