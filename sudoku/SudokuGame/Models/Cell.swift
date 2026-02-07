import Foundation

struct Cell: Identifiable, Equatable, Codable {
    let id: UUID
    var value: Int?
    var isFixed: Bool
    var notes: Set<Int>
    var isError: Bool

    init(value: Int? = nil, isFixed: Bool = false) {
        self.id = UUID()
        self.value = value
        self.isFixed = isFixed
        self.notes = []
        self.isError = false
    }

    var isEmpty: Bool {
        value == nil
    }

    mutating func toggleNote(_ number: Int) {
        if notes.contains(number) {
            notes.remove(number)
        } else {
            notes.insert(number)
        }
    }

    mutating func clearNotes() {
        notes.removeAll()
    }
}
