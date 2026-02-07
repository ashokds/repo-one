import SwiftUI

struct CellDropTarget: View {
    @ObservedObject var viewModel: GameViewModel
    let row: Int
    let col: Int
    let cellSize: CGFloat
    let isSelected: Bool
    let isSameNumber: Bool
    let isInSelectedRowOrCol: Bool
    let isInSelectedBox: Bool
    let cellBackground: Color

    @State private var isTargeted = false
    @State private var isDragging = false

    private var cell: Cell {
        viewModel.board[row, col]
    }

    private var isDraggable: Bool {
        cell.value != nil && !cell.isFixed
    }

    private var isHinting: Bool {
        if let hintCell = viewModel.hintAnimationCell {
            return hintCell.row == row && hintCell.col == col
        }
        return false
    }

    var body: some View {
        cellContent
            .frame(width: cellSize, height: cellSize)
            .background(cellBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green, lineWidth: 3)
                    .opacity(isTargeted && !cell.isFixed ? 1 : 0)
            )
            .opacity(isDragging ? 0.3 : 1.0)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectCell(row: row, col: col)
            }
            .dropDestination(for: String.self) { items, _ in
                guard let item = items.first,
                      let number = Int(item),
                      number >= 1 && number <= 9 else { return false }
                viewModel.dropNumber(number, atRow: row, col: col)
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTargeted = targeted
                }
            }
    }

    @ViewBuilder
    private var cellContent: some View {
        if isDraggable, let value = cell.value {
            CellView(
                cell: cell,
                isSelected: isSelected,
                isSameNumber: isSameNumber,
                isInSelectedRowOrCol: isInSelectedRowOrCol,
                isInSelectedBox: isInSelectedBox,
                isHinting: isHinting
            )
            .draggable("\(value)") {
                DragPreviewView(number: value)
                    .onAppear {
                        viewModel.startDraggingCell(row: row, col: col)
                        isDragging = true
                    }
            }
            .onChange(of: viewModel.dragSourceCell == nil) { _ in
                let isNil = viewModel.dragSourceCell == nil
                if isNil {
                    isDragging = false
                }
            }
        } else {
            CellView(
                cell: cell,
                isSelected: isSelected,
                isSameNumber: isSameNumber,
                isInSelectedRowOrCol: isInSelectedRowOrCol,
                isInSelectedBox: isInSelectedBox,
                isHinting: isHinting
            )
        }
    }
}

struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let cellSize = size / 9

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color(UIColor.label).opacity(0.2), radius: 5)

                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                CellDropTarget(
                                    viewModel: viewModel,
                                    row: row,
                                    col: col,
                                    cellSize: cellSize,
                                    isSelected: isSelected(row: row, col: col),
                                    isSameNumber: hasSameNumber(row: row, col: col),
                                    isInSelectedRowOrCol: isInSelectedRowOrCol(row: row, col: col),
                                    isInSelectedBox: isInSelectedBox(row: row, col: col),
                                    cellBackground: cellBackground(row: row, col: col)
                                )
                            }
                        }
                    }
                }

                // Grid lines (non-interactive)
                gridLines(cellSize: cellSize)
                    .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func isSelected(row: Int, col: Int) -> Bool {
        viewModel.gameState.selectedRow == row && viewModel.gameState.selectedCol == col
    }

    private func hasSameNumber(row: Int, col: Int) -> Bool {
        guard let selectedValue = viewModel.selectedCellValue(),
              let cellValue = viewModel.board[row, col].value else { return false }
        return selectedValue == cellValue && !isSelected(row: row, col: col)
    }

    private func isInSelectedRowOrCol(row: Int, col: Int) -> Bool {
        guard let selectedRow = viewModel.gameState.selectedRow,
              let selectedCol = viewModel.gameState.selectedCol else { return false }
        return (row == selectedRow || col == selectedCol) && !isSelected(row: row, col: col)
    }

    private func isInSelectedBox(row: Int, col: Int) -> Bool {
        guard let selectedRow = viewModel.gameState.selectedRow,
              let selectedCol = viewModel.gameState.selectedCol else { return false }
        let selectedBoxRow = selectedRow / 3
        let selectedBoxCol = selectedCol / 3
        let cellBoxRow = row / 3
        let cellBoxCol = col / 3
        return selectedBoxRow == cellBoxRow && selectedBoxCol == cellBoxCol && !isSelected(row: row, col: col)
    }

    private func cellBackground(row: Int, col: Int) -> Color {
        let boxRow = row / 3
        let boxCol = col / 3
        let isAlternateBox = (boxRow + boxCol) % 2 == 1
        return isAlternateBox ? Color(UIColor.systemGray6) : Color.clear
    }

    private func gridLines(cellSize: CGFloat) -> some View {
        ZStack {
            // Thin lines
            Path { path in
                for i in 1..<9 {
                    if i % 3 != 0 {
                        let pos = CGFloat(i) * cellSize
                        path.move(to: CGPoint(x: pos, y: 0))
                        path.addLine(to: CGPoint(x: pos, y: cellSize * 9))
                        path.move(to: CGPoint(x: 0, y: pos))
                        path.addLine(to: CGPoint(x: cellSize * 9, y: pos))
                    }
                }
            }
            .stroke(Color(UIColor.separator), lineWidth: 1)

            // Thick lines for 3x3 boxes
            Path { path in
                for i in 0...3 {
                    let pos = CGFloat(i * 3) * cellSize
                    path.move(to: CGPoint(x: pos, y: 0))
                    path.addLine(to: CGPoint(x: pos, y: cellSize * 9))
                    path.move(to: CGPoint(x: 0, y: pos))
                    path.addLine(to: CGPoint(x: cellSize * 9, y: pos))
                }
            }
            .stroke(Color(UIColor.label), lineWidth: 2)
        }
    }
}

#Preview {
    BoardView(viewModel: GameViewModel())
        .padding()
}
