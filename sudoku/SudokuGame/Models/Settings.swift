import Foundation

class GameSettings: ObservableObject {
    @Published var highlightInvalidNumbers: Bool {
        didSet {
            UserDefaults.standard.set(highlightInvalidNumbers, forKey: Self.highlightInvalidKey)
        }
    }

    private static let highlightInvalidKey = "highlightInvalidNumbers"

    init() {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: Self.highlightInvalidKey) == nil {
            self.highlightInvalidNumbers = true
        } else {
            self.highlightInvalidNumbers = UserDefaults.standard.bool(forKey: Self.highlightInvalidKey)
        }
    }
}
