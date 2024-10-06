import SwiftUI

struct ContentView: View {
    
    var body: some View {
       Text("hallo")
    }
}

struct CreateNewDeckView: View {
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isCreatingDeck = false
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images, id: \.self) { image in
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
            
//            do {
//                let jsonResponse = try JSONDecoder().decode(Deck.self, from: data)
//                DispatchQueue.main.async {
//                    print("Successfully decoded response, adding new deck titled: \(jsonResponse.title)")
//                    isCreatingDeck = true
//                }
//            } catch {
//                print("Error decoding response: \(error)")
//            }
        }.resume()
    }
}
//
//
//// Add this function at the top level of your file, outside of any struct
//func saveDecks(_ decks: [Deck]) {
//    do {
//        let encodedData = try JSONEncoder().encode(decks)
//        UserDefaults.standard.set(encodedData, forKey: "savedDecks")
//        print("Decks saved successfully")
//    } catch {
//        print("Error saving decks: \(error.localizedDescription)")
//    }
//}



struct Deck: Identifiable, Decodable {
    let language: String
    let title: String
    let questions: [QuizQuestion]
    
    var id: String {
        let concatenatedString = language + title + questions.map { $0.question }.joined(separator: "_")
        return String(concatenatedString.hashValue)
    }
}


struct QuizQuestion: Identifiable, Decodable {
    let question: String
    let answer: String
    let locationofanswerinmaterial: String
    
    var id: String {
        return "\(question.hashValue)_\(answer.hashValue)_\(locationofanswerinmaterial.hashValue)"
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
