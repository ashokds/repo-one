import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var cellsToRemove: Int {
        switch self {
        case .easy: return 35
        case .medium: return 45
        case .hard: return 55
        }
    }
}

struct Move: Codable {
    let row: Int
    let col: Int
    let previousValue: Int?
    let newValue: Int?
    let previousNotes: Set<Int>
    let newNotes: Set<Int>
    let isNoteMove: Bool
}

class GameState: ObservableObject {
    @Published var selectedRow: Int? = nil
    @Published var selectedCol: Int? = nil
    @Published var isNotesMode: Bool = false
    @Published var moveHistory: [Move] = []
    @Published var redoHistory: [Move] = []
    @Published var isGameWon: Bool = false

    var hasSelection: Bool {
        selectedRow != nil && selectedCol != nil
    }

    func select(row: Int, col: Int) {
        selectedRow = row
        selectedCol = col
    }

    func clearSelection() {
        selectedRow = nil
        selectedCol = nil
    }

    func addMove(_ move: Move) {
        moveHistory.append(move)
        // Clear redo history when a new move is made
        redoHistory.removeAll()
    }

    func popMove() -> Move? {
        guard let move = moveHistory.popLast() else { return nil }
        redoHistory.append(move)
        return move
    }

    func popRedoMove() -> Move? {
        guard let move = redoHistory.popLast() else { return nil }
        moveHistory.append(move)
        return move
    }

    func reset() {
        selectedRow = nil
        selectedCol = nil
        isNotesMode = false
        moveHistory.removeAll()
        redoHistory.removeAll()
        isGameWon = false
    }
}
