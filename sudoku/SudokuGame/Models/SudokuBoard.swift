import Foundation

struct SudokuBoard: Codable {
    var cells: [[Cell]]
    var solution: [[Int]]

    init() {
        cells = Array(repeating: Array(repeating: Cell(), count: 9), count: 9)
        solution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    }

    subscript(row: Int, col: Int) -> Cell {
        get { cells[row][col] }
        set { cells[row][col] = newValue }
    }

    func isValidPlacement(row: Int, col: Int, value: Int) -> Bool {
        // Check row
        for c in 0..<9 {
            if c != col && cells[row][c].value == value {
                return false
            }
        }

        // Check column
        for r in 0..<9 {
            if r != row && cells[r][col].value == value {
                return false
            }
        }

        // Check 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if (r != row || c != col) && cells[r][c].value == value {
                    return false
                }
            }
        }

        return true
    }

    func getConflictingCells(row: Int, col: Int, value: Int) -> [(Int, Int)] {
        var conflicts: [(Int, Int)] = []

        // Check row
        for c in 0..<9 {
            if c != col && cells[row][c].value == value {
                conflicts.append((row, c))
            }
        }

        // Check column
        for r in 0..<9 {
            if r != row && cells[r][col].value == value {
                conflicts.append((r, col))
            }
        }

        // Check 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if (r != row || c != col) && cells[r][c].value == value {
                    if !conflicts.contains(where: { $0.0 == r && $0.1 == c }) {
                        conflicts.append((r, c))
                    }
                }
            }
        }

        return conflicts
    }

    func isComplete() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if cells[row][col].value == nil || cells[row][col].isError {
                    return false
                }
            }
        }
        return true
    }

    func isSolved() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard let value = cells[row][col].value else { return false }
                if value != solution[row][col] {
                    return false
                }
            }
        }
        return true
    }

    mutating func updateErrors() {
        // Reset all errors
        for row in 0..<9 {
            for col in 0..<9 {
                cells[row][col].isError = false
            }
        }

        // Check for conflicts
        for row in 0..<9 {
            for col in 0..<9 {
                if let value = cells[row][col].value {
                    let conflicts = getConflictingCells(row: row, col: col, value: value)
                    if !conflicts.isEmpty {
                        cells[row][col].isError = true
                        for (r, c) in conflicts {
                            cells[r][c].isError = true
                        }
                    }
                }
            }
        }
    }

    func countValue(_ value: Int) -> Int {
        var count = 0
        for row in 0..<9 {
            for col in 0..<9 {
                if cells[row][col].value == value {
                    count += 1
                }
            }
        }
        return count
    }
}
