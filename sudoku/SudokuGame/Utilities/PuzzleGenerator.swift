import Foundation

class PuzzleGenerator {
    private var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)

    func generatePuzzle(difficulty: Int = 45) -> (board: [[Int?]], solution: [[Int]]) {
        // Generate a complete valid solution
        grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid()

        let solution = grid

        // Create puzzle by removing numbers
        var puzzle: [[Int?]] = grid.map { row in row.map { $0 } }
        var cellsToRemove = difficulty

        var positions: [(Int, Int)] = []
        for row in 0..<9 {
            for col in 0..<9 {
                positions.append((row, col))
            }
        }
        positions.shuffle()

        for (row, col) in positions {
            if cellsToRemove <= 0 { break }

            let backup = puzzle[row][col]
            puzzle[row][col] = nil

            // Check if puzzle still has unique solution
            if hasUniqueSolution(puzzle) {
                cellsToRemove -= 1
            } else {
                puzzle[row][col] = backup
            }
        }

        return (puzzle, solution)
    }

    private func fillGrid() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    var numbers = Array(1...9)
                    numbers.shuffle()

                    for num in numbers {
                        if isValid(row: row, col: col, num: num) {
                            grid[row][col] = num
                            if fillGrid() {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }

    private func isValid(row: Int, col: Int, num: Int) -> Bool {
        // Check row
        for c in 0..<9 {
            if grid[row][c] == num { return false }
        }

        // Check column
        for r in 0..<9 {
            if grid[r][col] == num { return false }
        }

        // Check 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if grid[r][c] == num { return false }
            }
        }

        return true
    }

    private func hasUniqueSolution(_ puzzle: [[Int?]]) -> Bool {
        var testGrid = puzzle.map { row in row.map { $0 ?? 0 } }
        var solutionCount = 0

        func solve() -> Bool {
            for row in 0..<9 {
                for col in 0..<9 {
                    if testGrid[row][col] == 0 {
                        for num in 1...9 {
                            if isValidInGrid(&testGrid, row: row, col: col, num: num) {
                                testGrid[row][col] = num
                                if solve() {
                                    if solutionCount > 1 { return true }
                                }
                                testGrid[row][col] = 0
                            }
                        }
                        return false
                    }
                }
            }
            solutionCount += 1
            return solutionCount > 1
        }

        _ = solve()
        return solutionCount == 1
    }

    private func isValidInGrid(_ grid: inout [[Int]], row: Int, col: Int, num: Int) -> Bool {
        for c in 0..<9 {
            if grid[row][c] == num { return false }
        }

        for r in 0..<9 {
            if grid[r][col] == num { return false }
        }

        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if grid[r][c] == num { return false }
            }
        }

        return true
    }
}
