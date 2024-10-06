import SwiftUI
import Combine

struct DeckPackage: Codable {
    let quiz: Quiz
    let creationDate: Date
    let images: [UIImage]
    
    enum CodingKeys: String, CodingKey {
        case quiz
        case creationDate
        case images
    }
    
    init(quiz: Quiz, creationDate: Date, images: [UIImage]) {
        self.quiz = quiz
        self.creationDate = creationDate
        self.images = images
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        quiz = try container.decode(Quiz.self, forKey: .quiz)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        
        let imageStrings = try container.decode([String].self, forKey: .images)
        images = imageStrings.compactMap { base64String in
            guard let imageData = Data(base64Encoded: base64String) else { return nil }
            return UIImage(data: imageData)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(quiz, forKey: .quiz)
        try container.encode(creationDate, forKey: .creationDate)
        
        let imageStrings = images.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }
        try container.encode(imageStrings, forKey: .images)
    }
}

struct PartialDeckPackage: Decodable, Identifiable, Hashable {
    let quiz: Quiz
    let creationDate: Date
    
    var id:Date { creationDate }
    
    enum CodingKeys: String, CodingKey {
        case quiz
        case creationDate
    }
    
    init(quiz:Quiz, creationDate: Date)
    {
        self.quiz = quiz
        self.creationDate = creationDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quiz = try container.decode(Quiz.self, forKey: .quiz)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
    }
    
    static func == (lhs: PartialDeckPackage, rhs: PartialDeckPackage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class DeckStorage: ObservableObject {
    static let shared = DeckStorage()
    
    @Published private(set) var decks: [PartialDeckPackage] = []
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        loadDecks()
    }
    
    private func loadDecks() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            let sortedDecks = fileURLs.compactMap { url -> (PartialDeckPackage, Date)? in
                guard url.pathExtension == "json" else { return nil }
                
                do {
                    let data = try Data(contentsOf: url)
                    let partialPackage = try JSONDecoder().decode(PartialDeckPackage.self, from: data)
                    return (partialPackage, partialPackage.creationDate)
                } catch {
                    print("Failed to load deck from \(url.lastPathComponent): \(error)")
                    return nil
                }
            }
            .sorted { $0.1 > $1.1 } // Sort by date, most recent first
            .map { $0.0 } // Extract just the Deck from the tuple
            
            self.decks = sortedDecks
            
            print("Successfully loaded \(sortedDecks.count) decks")
        } catch {
            print("Failed to access document directory: \(error)")
        }
    }

    
    func saveDeckPackage(deckPackage: DeckPackage) -> PartialDeckPackage {
        do {
            let data = try JSONEncoder().encode(deckPackage)
            
            let fileURL = documentsDirectory.appendingPathComponent("\(deckPackage.creationDate).json")
            try data.write(to: fileURL)
            
            let partial = PartialDeckPackage(quiz: deckPackage.quiz, creationDate: deckPackage.creationDate);
            decks.append(partial)
            return partial
    
        } catch {
            print("Failed to save deck package: \(error)")
            return dummyDeck()
        }

    }
    
    func loadImagesForDeck(id: String) -> [UIImage] {
        do {
            let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
            let data = try Data(contentsOf: fileURL)
            let package = try JSONDecoder().decode(DeckPackage.self, from: data)
            return package.images
        } catch {
            print("Failed to load images: \(error)")
            return []
        }
    }
    
    func deleteDecks(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            let deckToDelete = decks[index]
            do {
                let fileURL = documentsDirectory.appendingPathComponent("\(deckToDelete.id).json")
                try FileManager.default.removeItem(at: fileURL)
                decks.removeAll { $0.id == deckToDelete.id }
            } catch {
                print("Failed to delete deck package: \(error)")
            }
        }
        loadDecks()
    }

//    
//    func deleteDeckPackage(id: String) {
//        do {
//            let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
//            try FileManager.default.removeItem(at: fileURL)
//            decks.removeAll { $0.id == id }
//        } catch {
//            print("Failed to delete deck package: \(error)")
//        }
//    }
}
