import Foundation
import AppKit

// Protocol for all clip types
protocol ClipItem: Identifiable, Equatable {
    var id: UUID { get }
    var createdAt: Date { get }
    var isPinned: Bool { get set }
}

// Text clip model
struct TextClip: ClipItem {
    let id: UUID
    let createdAt: Date
    var isPinned: Bool
    let text: String
    
    init(text: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.isPinned = false
        self.text = text
    }
    
    static func == (lhs: TextClip, rhs: TextClip) -> Bool {
        lhs.id == rhs.id
    }
}

// Image clip model
struct ImageClip: ClipItem {
    let id: UUID
    let createdAt: Date
    var isPinned: Bool
    let imageData: Data
    let width: Int
    let height: Int
    
    private var _thumbnail: NSImage?
    
    init?(imageData: Data, maxSize: Int = 10_000_000) {
        // Limit image size to prevent memory issues
        guard imageData.count <= maxSize else { return nil }
        
        guard let nsImage = NSImage(data: imageData) else { return nil }
        guard let representation = nsImage.representations.first else { return nil }
        
        self.id = UUID()
        self.createdAt = Date()
        self.isPinned = false
        self.imageData = imageData
        self.width = representation.pixelsWide
        self.height = representation.pixelsHigh
        self._thumbnail = nil
    }
    
    // Generate thumbnail on-demand
    func thumbnail(size: CGSize = CGSize(width: 64, height: 64)) -> NSImage? {
        guard let original = NSImage(data: imageData) else { return nil }
        
        let targetSize: CGSize
        let originalSize = original.size
        let aspectRatio = originalSize.width / originalSize.height
        
        if aspectRatio > 1 {
            targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
        } else {
            targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
        }
        
        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        original.draw(in: NSRect(origin: .zero, size: targetSize),
                     from: NSRect(origin: .zero, size: originalSize),
                     operation: .copy,
                     fraction: 1.0)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    func fullImage() -> NSImage? {
        NSImage(data: imageData)
    }
    
    static func == (lhs: ImageClip, rhs: ImageClip) -> Bool {
        lhs.id == rhs.id
    }
}

// Unified container for both types
enum ClipType: Identifiable, Equatable {
    case text(TextClip)
    case image(ImageClip)
    
    var id: UUID {
        switch self {
        case .text(let clip): return clip.id
        case .image(let clip): return clip.id
        }
    }
    
    var createdAt: Date {
        switch self {
        case .text(let clip): return clip.createdAt
        case .image(let clip): return clip.createdAt
        }
    }
    
    var isPinned: Bool {
        get {
            switch self {
            case .text(let clip): return clip.isPinned
            case .image(let clip): return clip.isPinned
            }
        }
        set {
            switch self {
            case .text(var clip):
                clip.isPinned = newValue
                self = .text(clip)
            case .image(var clip):
                clip.isPinned = newValue
                self = .image(clip)
            }
        }
    }
    
    static func == (lhs: ClipType, rhs: ClipType) -> Bool {
        lhs.id == rhs.id
    }
}
