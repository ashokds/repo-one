import Foundation

struct GameRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let difficulty: Difficulty
    let board: SudokuBoard
    let moveHistory: [Move]
    let isNotesMode: Bool
    let isCompleted: Bool
    let completedDate: Date?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        difficulty: Difficulty,
        board: SudokuBoard,
        moveHistory: [Move],
        isNotesMode: Bool,
        isCompleted: Bool,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.difficulty = difficulty
        self.board = board
        self.moveHistory = moveHistory
        self.isNotesMode = isNotesMode
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var statusText: String {
        if isCompleted {
            return "Completed"
        } else {
            let filledCells = countFilledCells()
            return "\(filledCells)/81 cells"
        }
    }

    private func countFilledCells() -> Int {
        var count = 0
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row, col].value != nil {
                    count += 1
                }
            }
        }
        return count
    }
}

class GameHistoryManager: ObservableObject {
    @Published var records: [GameRecord] = []

    private static let historyKey = "sudokuGameHistory"
    private static let maxRecords = 50

    init() {
        loadHistory()
    }

    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey) else {
            records = []
            return
        }

        do {
            records = try JSONDecoder().decode([GameRecord].self, from: data)
        } catch {
            print("Failed to load game history: \(error)")
            records = []
        }
    }

    func saveHistory() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        } catch {
            print("Failed to save game history: \(error)")
        }
    }

    func addRecord(_ record: GameRecord) {
        // Check if we're updating an existing record
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }

        // Limit history size
        if records.count > Self.maxRecords {
            records = Array(records.prefix(Self.maxRecords))
        }

        saveHistory()
    }

    func deleteRecord(_ record: GameRecord) {
        records.removeAll { $0.id == record.id }
        saveHistory()
    }

    func clearHistory() {
        records = []
        saveHistory()
    }

    var completedGames: [GameRecord] {
        records.filter { $0.isCompleted }
    }

    var incompleteGames: [GameRecord] {
        records.filter { !$0.isCompleted }
    }
}
