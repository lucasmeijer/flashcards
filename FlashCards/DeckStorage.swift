import SwiftUI
import Combine

struct DeckPackage: Codable {
    let deck: Deck
    let images: [String: String] // Dictionary of image IDs to base64 encoded image data
}

struct PartialDeckPackage: Decodable {
    let deck: Deck
    
    enum CodingKeys: String, CodingKey {
        case deck
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deck = try container.decode(Deck.self, forKey: .deck)
    }
}

class DeckStorage: ObservableObject {
    static let shared = DeckStorage()
    
    @Published private(set) var decks: [Deck] = []
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        loadDecks()
    }
    
    private func loadDecks() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            self.decks = try fileURLs.compactMap { url -> Deck? in
                guard url.pathExtension == "json" else { return nil }
                let data = try Data(contentsOf: url)
                let partialPackage = try JSONDecoder().decode(PartialDeckPackage.self, from: data)
                return partialPackage.deck
            }
        } catch {
            print("Failed to load decks: \(error)")
        }
    }
    
    func saveDeckPackage(_ deck: Deck, images: [UIImage]) {
        do {
            let imageDict = images.enumerated().reduce(into: [String: String]()) { result, entry in
                if let imageData = entry.element.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
                    result["image\(entry.offset)"] = imageData
                }
            }
            
            let package = DeckPackage(deck: deck, images: imageDict)
            let data = try JSONEncoder().encode(package)
            
            let fileURL = documentsDirectory.appendingPathComponent("\(deck.id).json")
            try data.write(to: fileURL)
            
            if let index = decks.firstIndex(where: { $0.id == deck.id }) {
                decks[index] = deck
            } else {
                decks.append(deck)
            }
        } catch {
            print("Failed to save deck package: \(error)")
        }
    }
    
    func loadImagesForDeck(id: String) -> [UIImage] {
        do {
            let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
            let data = try Data(contentsOf: fileURL)
            let package = try JSONDecoder().decode(DeckPackage.self, from: data)
            
            return package.images.compactMap { _, base64String in
                guard let imageData = Data(base64Encoded: base64String) else { return nil }
                return UIImage(data: imageData)
            }
        } catch {
            print("Failed to load images: \(error)")
            return []
        }
    }
    
    func deleteDeckPackage(id: String) {
        do {
            let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
            try FileManager.default.removeItem(at: fileURL)
            decks.removeAll { $0.id == id }
        } catch {
            print("Failed to delete deck package: \(error)")
        }
    }
}
