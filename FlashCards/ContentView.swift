import SwiftUI

struct ContentView: View {
    @State private var decks: [Deck] = []
    
    var body: some View {
        NavigationStack {
            if decks.isEmpty {
                NavigationLink(destination: AddPhotosView(decks: $decks)) {
                    Text("Creating a new deck...")
                }
            } else {
                List {
                    Section(header: Text("Decks")) {
                        NavigationLink(destination: AddPhotosView(decks: $decks)) {
                            Text("Make a new deck")
                        }
                        
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckView(deck: $decks[getDeckIndex(deck)])) {
                                Text(deck.title)
                            }
                        }
                    }
                }
                .navigationTitle("Flashcard Decks")
            }
        }
    }
    
    func getDeckIndex(_ deck: Deck) -> Int {
        print("Getting index for deck with title: \(deck.title)")
        return decks.firstIndex(where: { $0.id == deck.id }) ?? 0
    }
}

struct AddPhotosView: View {
    @Binding var decks: [Deck]
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isCreatingDeck = false
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images, id: \..self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding()
                    }
                }
            }
            
            Button("Take Photos") {
                print("Take Photos button tapped")
                showImagePicker = true
            }
            .padding()
            
            Button("Create Flashcards from these Photos") {
                print("Create Flashcards button tapped")
                isCreatingDeck = true
                uploadPhotos()
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $images)
        }
        .navigationDestination(isPresented: $isCreatingDeck) {
            DeckView(deck: Binding(get: {
                decks.last ?? Deck(title: "", questions: [])
            }, set: { newDeck in
                if let lastIndex = decks.indices.last {
                    decks[lastIndex] = newDeck
                }
            }))
        }
    }
    
    func uploadPhotos() {
        guard let url = URL(string: "https://flashcards.lucasmeijer.com/fake") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Assuming images are to be sent as base64 encoded strings in JSON
        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }
        let json: [String: Any] = ["images": imageData]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
            print("HTTP body created with image data")
        } catch {
            print("Error creating JSON body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error with HTTP request: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received from server")
                return
            }
            
            do {
                let jsonResponse = try JSONDecoder().decode(Deck.self, from: data)
                DispatchQueue.main.async {
                    print("Successfully decoded response, adding new deck titled: \(jsonResponse.title)")
                    decks.append(jsonResponse)
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }.resume()
    }
}

struct DeckView: View {
    @Binding var deck: Deck
    
    var body: some View {
        VStack {
            ZStack {
                ForEach(deck.questions.indices.reversed(), id: \..self) { index in
                    CardView(card: $deck.questions[index])
                        .offset(x: 0, y: CGFloat(index) * 5)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.interactiveSpring()) {
                                        print("Dragging card with question: \(deck.questions[index].question)")
                                        deck.questions[index].offset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    print("Drag ended for card with question: \(deck.questions[index].question)")
                                    handleSwipe(value.translation.width, at: index)
                                    withAnimation(.spring()) {
                                        deck.questions[index].offset = .zero
                                    }
                                }
                        )
                        .animation(.spring(), value: deck.questions[index].offset)
                }
            }
            .padding()
        }
        .navigationTitle(deck.title)
    }
    
    func handleSwipe(_ width: CGFloat, at index: Int) {
        if width < -100 {
            print("Swiped left on card with question: \(deck.questions[index].question), discarding it")
            deck.questions.remove(at: index)
        } else if width > 100 {
            print("Swiped right on card with question: \(deck.questions[index].question), moving it to the bottom")
            let card = deck.questions.remove(at: index)
            deck.questions.insert(card, at: 0)
        }
    }
}

struct CardView: View {
    @Binding var card: Card
    @State private var showAnswer = false
    
    var body: some View {
        VStack {
            if showAnswer {
                Text(card.answer)
                    .font(.title)
                    .padding()
            } else {
                Text(card.question)
                    .font(.title)
                    .padding()
            }
        }
        .frame(width: 300, height: 200)
        .background(Color.blue)
        .cornerRadius(10)
        .shadow(radius: 5)
        .offset(card.offset)
        .onTapGesture {
            withAnimation {
                showAnswer.toggle()
                print("Card tapped. Showing answer: \(showAnswer)")
            }
        }
    }
}

struct Deck: Codable, Identifiable {
    var id: String {
        let concatenatedString = title + questions.map { $0.question }.joined(separator: "_")
        return String(concatenatedString.hashValue)
    }
    
    var title: String
    var questions: [Card]
}

struct Card: Codable, Identifiable {
    var id: String {
        return "\(question.hashValue)_\(answer.hashValue)"
    }
    
    var question: String
    var answer: String
    var locationofanswerinmaterial: String?
    var offset: CGSize = .zero
    
    enum CodingKeys: String, CodingKey {
        case question, answer, locationofanswerinmaterial
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        question = try container.decode(String.self, forKey: .question)
        answer = try container.decode(String.self, forKey: .answer)
        locationofanswerinmaterial = try container.decodeIfPresent(String.self, forKey: .locationofanswerinmaterial)
    }

    init(question: String, answer: String, locationofanswerinmaterial: String? = nil) {
      self.question = question
      self.answer = answer
      self.locationofanswerinmaterial = locationofanswerinmaterial
    }

}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
                print("Image added to the list. Total images: \(parent.images.count)")
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Info.plist entry (not part of the code, but add this to Info.plist):
// <key>NSCameraUsageDescription</key>
// <string>This app requires access to the camera to allow you to take photos of learning material for creating flashcards.</string>
