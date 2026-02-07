import SwiftUI

struct CellView: View {
    let cell: Cell
    let isSelected: Bool
    let isSameNumber: Bool
    let isInSelectedRowOrCol: Bool
    let isInSelectedBox: Bool
    var isHinting: Bool = false

    var body: some View {
        ZStack {
            backgroundColor
                .animation(.easeInOut(duration: 0.1), value: isSelected)

            if let value = cell.value {
                Text("\(value)")
                    .font(.system(size: 24, weight: cell.isFixed ? .bold : .medium))
                    .foregroundColor(textColor)
                    .scaleEffect(isHinting ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHinting)
            } else if !cell.notes.isEmpty {
                notesGrid
            }

            // Selection border
            if isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.blue, lineWidth: 3)
                    .padding(1)
            }

            // Hint animation overlay
            if isHinting {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green.opacity(0.3))
                    .animation(.easeInOut(duration: 0.2), value: isHinting)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.25)
        } else if cell.isError {
            return Color.red.opacity(0.3)
        } else if isSameNumber {
            return Color.blue.opacity(0.2)
        } else if isInSelectedBox {
            return Color(UIColor.systemGray4).opacity(0.5)
        } else if isInSelectedRowOrCol {
            return Color(UIColor.systemGray5).opacity(0.5)
        } else {
            return Color(UIColor.systemBackground).opacity(0.001)
        }
    }

    private var textColor: Color {
        if cell.isError {
            return .red
        } else if cell.isFixed {
            return .primary
        } else {
            return .blue
        }
    }

    private var notesGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3) { col in
                        let number = row * 3 + col + 1
                        Text(cell.notes.contains(number) ? "\(number)" : " ")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
    }
}

#Preview {
    HStack {
        CellView(
            cell: Cell(value: 5, isFixed: true),
            isSelected: false,
            isSameNumber: false,
            isInSelectedRowOrCol: false,
            isInSelectedBox: false,
            isHinting: false
        )
        .frame(width: 40, height: 40)
        .border(Color.gray)

        CellView(
            cell: Cell(value: 3, isFixed: false),
            isSelected: true,
            isSameNumber: false,
            isInSelectedRowOrCol: false,
            isInSelectedBox: false,
            isHinting: true
        )
        .frame(width: 40, height: 40)
        .border(Color.gray)

        CellView(
            cell: {
                var cell = Cell()
                cell.notes = [1, 3, 5, 7]
                return cell
            }(),
            isSelected: false,
            isSameNumber: false,
            isInSelectedRowOrCol: false,
            isInSelectedBox: false,
            isHinting: false
        )
        .frame(width: 40, height: 40)
        .border(Color.gray)
    }
}
