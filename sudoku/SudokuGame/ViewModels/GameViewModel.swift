import Foundation
import SwiftUI
import Combine

struct SavedGameData: Codable {
    let board: SudokuBoard
    let difficulty: Difficulty
    let isNotesMode: Bool
    let moveHistory: [Move]
    let redoHistory: [Move]
    let isGameWon: Bool
}

class GameViewModel: ObservableObject {
    @Published var board: SudokuBoard
    @Published var gameState: GameState
    @Published var dragSourceCell: (row: Int, col: Int)?
    @Published var showDifficultyPicker = false
    @Published var currentDifficulty: Difficulty = .medium
    @Published var showAutoFillPrompt = false
    @Published var showGameHistory = false
    @Published var showSettings = false
    @Published var showProfileSwitcher = false
    @Published var hintAnimationCell: (row: Int, col: Int)?

    let historyManager = GameHistoryManager()
    let settings = GameSettings()
    let profileManager = ProfileManager()
    private var currentGameId: UUID = UUID()
    private var currentGameStartDate: Date = Date()
    private var gameStartTime: Date?

    private let generator = PuzzleGenerator()
    private var cancellables = Set<AnyCancellable>()

    private static let saveKey = "savedSudokuGame"
    private static let currentGameIdKey = "currentSudokuGameId"

    init() {
        board = SudokuBoard()
        gameState = GameState()

        // Forward gameState changes to this view model
        gameState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Forward profileManager changes to this view model
        profileManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Try to load saved game, otherwise start new
        if !loadGame() {
            startNewGame(difficulty: .medium)
        }
    }

    func startNewGame(difficulty: Difficulty = .medium) {
        // Save current game to history before starting new one
        saveCurrentGameToHistory()

        currentDifficulty = difficulty
        currentGameId = UUID()
        currentGameStartDate = Date()
        gameStartTime = Date()

        let (puzzle, solution) = generator.generatePuzzle(difficulty: difficulty.cellsToRemove)

        board = SudokuBoard()
        board.solution = solution

        for row in 0..<9 {
            for col in 0..<9 {
                if let value = puzzle[row][col] {
                    board[row, col] = Cell(value: value, isFixed: true)
                } else {
                    board[row, col] = Cell()
                }
            }
        }

        gameState.reset()
        clearSavedGame()

        // Record game started for profile stats
        profileManager.recordGameStarted()
    }

    func selectCell(row: Int, col: Int) {
        gameState.select(row: row, col: col)
    }

    func inputNumber(_ number: Int) {
        guard let row = gameState.selectedRow,
              let col = gameState.selectedCol,
              !board[row, col].isFixed else { return }

        if gameState.isNotesMode {
            inputNote(number, row: row, col: col)
        } else {
            inputValue(number, row: row, col: col)
        }
    }

    private func inputValue(_ number: Int, row: Int, col: Int) {
        let previousValue = board[row, col].value
        let previousNotes = board[row, col].notes

        // Don't add to history if same value
        if previousValue == number { return }

        let move = Move(
            row: row,
            col: col,
            previousValue: previousValue,
            newValue: number,
            previousNotes: previousNotes,
            newNotes: [],
            isNoteMove: false
        )
        gameState.addMove(move)

        board[row, col].value = number
        board[row, col].clearNotes()
        board.updateErrors()

        checkWinCondition()

        // Check if auto-fill should be offered
        if !gameState.isGameWon {
            checkAutoFill()
        }
    }

    private func inputNote(_ number: Int, row: Int, col: Int) {
        // Can only add notes to empty cells
        guard board[row, col].value == nil else { return }

        let previousNotes = board[row, col].notes
        board[row, col].toggleNote(number)
        let newNotes = board[row, col].notes

        let move = Move(
            row: row,
            col: col,
            previousValue: nil,
            newValue: nil,
            previousNotes: previousNotes,
            newNotes: newNotes,
            isNoteMove: true
        )
        gameState.addMove(move)
    }

    func clearCell() {
        guard let row = gameState.selectedRow,
              let col = gameState.selectedCol,
              !board[row, col].isFixed else { return }

        let previousValue = board[row, col].value
        let previousNotes = board[row, col].notes

        // Don't add to history if already empty
        if previousValue == nil && previousNotes.isEmpty { return }

        let move = Move(
            row: row,
            col: col,
            previousValue: previousValue,
            newValue: nil,
            previousNotes: previousNotes,
            newNotes: [],
            isNoteMove: false
        )
        gameState.addMove(move)

        board[row, col].value = nil
        board[row, col].clearNotes()
        board.updateErrors()
    }

    func undo() {
        guard let move = gameState.popMove() else { return }

        board[move.row, move.col].value = move.previousValue
        board[move.row, move.col].notes = move.previousNotes
        board.updateErrors()
    }

    func redo() {
        guard let move = gameState.popRedoMove() else { return }

        board[move.row, move.col].value = move.newValue
        board[move.row, move.col].notes = move.newNotes
        board.updateErrors()

        checkWinCondition()
    }

    func toggleNotesMode() {
        gameState.isNotesMode.toggle()
    }

    func useHint() {
        var targetRow: Int
        var targetCol: Int

        // Check if selected cell is empty or has an error
        if let selectedRow = gameState.selectedRow,
           let selectedCol = gameState.selectedCol,
           !board[selectedRow, selectedCol].isFixed,
           (board[selectedRow, selectedCol].value == nil || board[selectedRow, selectedCol].isError) {
            // Use selected cell
            targetRow = selectedRow
            targetCol = selectedCol
        } else {
            // Find all empty cells
            var emptyCells: [(Int, Int)] = []
            for row in 0..<9 {
                for col in 0..<9 {
                    if board[row, col].value == nil {
                        emptyCells.append((row, col))
                    }
                }
            }

            guard !emptyCells.isEmpty else { return }

            // Pick a random empty cell
            let randomCell = emptyCells.randomElement()!
            targetRow = randomCell.0
            targetCol = randomCell.1
        }

        let correctValue = board.solution[targetRow][targetCol]
        let previousValue = board[targetRow, targetCol].value
        let previousNotes = board[targetRow, targetCol].notes

        // Don't hint if already correct
        if previousValue == correctValue { return }

        // Record the move
        let move = Move(
            row: targetRow,
            col: targetCol,
            previousValue: previousValue,
            newValue: correctValue,
            previousNotes: previousNotes,
            newNotes: [],
            isNoteMove: false
        )
        gameState.addMove(move)

        // Select the cell first (for animation)
        gameState.select(row: targetRow, col: targetCol)

        // Trigger hint animation
        hintAnimationCell = (targetRow, targetCol)

        // Set the value with slight delay for animation effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.board[targetRow, targetCol].value = correctValue
            self.board[targetRow, targetCol].clearNotes()
            self.board.updateErrors()
            self.checkWinCondition()

            // Clear animation after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hintAnimationCell = nil
            }
        }
    }

    func isNumberComplete(_ number: Int) -> Bool {
        board.countValue(number) >= 9
    }

    private func checkWinCondition() {
        if board.isSolved() {
            gameState.isGameWon = true
            saveCompletedGameToHistory()

            // Record completion in profile stats
            if let startTime = gameStartTime {
                let completionTime = Date().timeIntervalSince(startTime)
                profileManager.recordGameCompleted(difficulty: currentDifficulty, time: completionTime)
            }
        }
    }

    // MARK: - Auto-fill

    /// Returns numbers that have exactly 8 placements (ready for auto-fill)
    var numbersReadyForAutoFill: [Int] {
        (1...9).filter { board.countValue($0) == 8 }
    }

    /// Check if auto-fill should be offered
    func checkAutoFill() {
        if !numbersReadyForAutoFill.isEmpty && !gameState.isGameWon {
            showAutoFillPrompt = true
        }
    }

    /// Find the empty cell for a number that has 8 placements
    private func findEmptyCellForNumber(_ number: Int) -> (row: Int, col: Int)? {
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row, col].value == nil {
                    // Check if this number belongs here according to solution
                    if board.solution[row][col] == number {
                        return (row, col)
                    }
                }
            }
        }
        return nil
    }

    /// Auto-fill all numbers that have 8 placements
    func autoFillRemaining() {
        for number in numbersReadyForAutoFill {
            if let cell = findEmptyCellForNumber(number) {
                // Record the move
                let previousNotes = board[cell.row, cell.col].notes
                let move = Move(
                    row: cell.row,
                    col: cell.col,
                    previousValue: nil,
                    newValue: number,
                    previousNotes: previousNotes,
                    newNotes: [],
                    isNoteMove: false
                )
                gameState.addMove(move)

                // Fill the cell
                board[cell.row, cell.col].value = number
                board[cell.row, cell.col].clearNotes()
            }
        }

        board.updateErrors()
        checkWinCondition()
    }

    func selectedCellValue() -> Int? {
        guard let row = gameState.selectedRow,
              let col = gameState.selectedCol else { return nil }
        return board[row, col].value
    }

    /// Returns numbers that are invalid for the currently selected cell
    /// (already present in the same 3x3 box)
    func invalidNumbersForSelectedCell() -> Set<Int> {
        guard let row = gameState.selectedRow,
              let col = gameState.selectedCol,
              board[row, col].value == nil else { return [] }

        var invalidNumbers = Set<Int>()

        // Check 3x3 box only
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if let value = board[r, c].value {
                    invalidNumbers.insert(value)
                }
            }
        }

        return invalidNumbers
    }

    func dropNumber(_ number: Int, atRow row: Int, col: Int) {
        guard !board[row, col].isFixed else {
            dragSourceCell = nil
            return
        }

        // Check if we're moving from another cell
        if let source = dragSourceCell,
           !(source.row == row && source.col == col) {
            // Clear the source cell if it had a value
            if board[source.row, source.col].value != nil {
                board[source.row, source.col].value = nil
                board[source.row, source.col].clearNotes()
            }

            dragSourceCell = nil
        }

        // Select the cell
        gameState.select(row: row, col: col)

        if gameState.isNotesMode {
            inputNote(number, row: row, col: col)
        } else {
            inputValue(number, row: row, col: col)
        }
    }

    func startDraggingCell(row: Int, col: Int) {
        dragSourceCell = (row: row, col: col)
    }

    func cancelDrag() {
        dragSourceCell = nil
    }

    // MARK: - Persistence

    func saveGame() {
        // Don't save if game is won
        guard !gameState.isGameWon else {
            clearSavedGame()
            return
        }

        let savedData = SavedGameData(
            board: board,
            difficulty: currentDifficulty,
            isNotesMode: gameState.isNotesMode,
            moveHistory: gameState.moveHistory,
            redoHistory: gameState.redoHistory,
            isGameWon: gameState.isGameWon
        )

        do {
            let data = try JSONEncoder().encode(savedData)
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        } catch {
            print("Failed to save game: \(error)")
        }
    }

    @discardableResult
    func loadGame() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey) else {
            return false
        }

        do {
            let savedData = try JSONDecoder().decode(SavedGameData.self, from: data)

            // Don't restore won games
            guard !savedData.isGameWon else {
                clearSavedGame()
                return false
            }

            board = savedData.board
            currentDifficulty = savedData.difficulty
            gameState.isNotesMode = savedData.isNotesMode
            gameState.moveHistory = savedData.moveHistory
            gameState.redoHistory = savedData.redoHistory
            gameState.isGameWon = savedData.isGameWon
            gameState.clearSelection()

            return true
        } catch {
            print("Failed to load game: \(error)")
            return false
        }
    }

    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: Self.saveKey)
    }

    var hasSavedGame: Bool {
        UserDefaults.standard.data(forKey: Self.saveKey) != nil
    }

    // MARK: - Game History

    private func saveCurrentGameToHistory() {
        // Don't save empty games or already completed games
        let filledCells = countFilledCells()
        let fixedCells = countFixedCells()

        // Only save if player has made progress
        guard filledCells > fixedCells && !gameState.isGameWon else { return }

        let record = GameRecord(
            id: currentGameId,
            date: currentGameStartDate,
            difficulty: currentDifficulty,
            board: board,
            moveHistory: gameState.moveHistory,
            isNotesMode: gameState.isNotesMode,
            isCompleted: false
        )

        historyManager.addRecord(record)
    }

    private func saveCompletedGameToHistory() {
        let record = GameRecord(
            id: currentGameId,
            date: currentGameStartDate,
            difficulty: currentDifficulty,
            board: board,
            moveHistory: gameState.moveHistory,
            isNotesMode: gameState.isNotesMode,
            isCompleted: true,
            completedDate: Date()
        )

        historyManager.addRecord(record)
        clearSavedGame()
    }

    func loadGameFromHistory(_ record: GameRecord) {
        // Save current game before loading another
        if !gameState.isGameWon {
            saveCurrentGameToHistory()
        }

        currentGameId = record.id
        currentGameStartDate = record.date
        currentDifficulty = record.difficulty
        board = record.board
        gameState.moveHistory = record.moveHistory
        gameState.isNotesMode = record.isNotesMode
        gameState.isGameWon = record.isCompleted
        gameState.clearSelection()

        showGameHistory = false
    }

    func deleteGameFromHistory(_ record: GameRecord) {
        historyManager.deleteRecord(record)
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

    private func countFixedCells() -> Int {
        var count = 0
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row, col].isFixed {
                    count += 1
                }
            }
        }
        return count
    }
}
