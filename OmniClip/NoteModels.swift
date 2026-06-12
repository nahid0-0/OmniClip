import Foundation

// MARK: - Form Item

struct FormItem: Identifiable, Codable, Equatable {
    var id: UUID
    var value: String   // The text that gets copied (e.g. "John Doe")
    var label: String   // Optional display label (e.g. "Full Name") — may be empty

    init(id: UUID = UUID(), value: String, label: String = "") {
        self.id = id
        self.value = value
        self.label = label
    }
}

// MARK: - Note Content

enum NoteContent: Codable, Equatable {
    case plainText(String)
    case form([FormItem])

    // Custom Codable because Swift enums with associated values need it
    private enum CodingKeys: String, CodingKey {
        case type, text, items
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .plainText(let text):
            try container.encode("plainText", forKey: .type)
            try container.encode(text, forKey: .text)
        case .form(let items):
            try container.encode("form", forKey: .type)
            try container.encode(items, forKey: .items)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "form":
            let items = try container.decode([FormItem].self, forKey: .items)
            self = .form(items)
        default:
            let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self = .plainText(text)
        }
    }

    var typeName: String {
        switch self {
        case .plainText: return "Text"
        case .form:      return "Form"
        }
    }

    var typeIcon: String {
        switch self {
        case .plainText: return "doc.text"
        case .form:      return "list.bullet.clipboard"
        }
    }
}

// MARK: - Note

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: NoteContent
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(),
         title: String,
         content: NoteContent,
         createdAt: Date = Date(),
         modifiedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// A brief one-line preview string shown in the card
    var preview: String {
        switch content {
        case .plainText(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
                       .components(separatedBy: .newlines).first ?? ""
        case .form(let items):
            return items.map { $0.value }.joined(separator: " · ")
        }
    }
}
