# Sudoku Game

A SwiftUI-based Sudoku game for iPhone.

## Features

- **Notes/Pencil Marks**: Toggle notes mode to add small candidate numbers in cells
- **Undo**: Revert moves with full history support
- **Hints**: Reveal a random empty cell's correct value
- **Error Highlighting**: Real-time validation showing conflicts in red
- **Same-Number Highlight**: All cells with the same number as selected cell are highlighted

## Requirements

- iOS 16.0+
- Xcode 15.0+

## Project Structure

```
SudokuGame/
├── SudokuGameApp.swift          # App entry point
├── Models/
│   ├── Cell.swift               # Individual cell model
│   ├── SudokuBoard.swift        # Board state and validation
│   └── GameState.swift          # Game state management
├── ViewModels/
│   └── GameViewModel.swift      # Game logic and state
├── Views/
│   ├── ContentView.swift        # Main game screen
│   ├── BoardView.swift          # 9x9 grid display
│   ├── CellView.swift           # Individual cell UI
│   ├── NumberPadView.swift      # Number input (1-9)
│   └── ToolbarView.swift        # Hints, notes, undo buttons
├── Utilities/
│   └── PuzzleGenerator.swift    # Generate valid puzzles
└── Assets.xcassets              # App icons and colors
```

## Building and Running

1. Open `SudokuGame.xcodeproj` in Xcode
2. Select an iPhone simulator or device
3. Press Cmd+R to build and run

## How to Play

1. Tap a cell to select it
2. Use the number pad to enter a number
3. Toggle Notes mode to add pencil marks instead of values
4. Use Undo to revert mistakes
5. Use Hint if you get stuck
6. Complete the puzzle with no errors to win
