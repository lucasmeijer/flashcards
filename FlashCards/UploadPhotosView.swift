//
//  UploadPhotosView.swift
//  FlashCards
//
//  Created by Lucas Meijer on 06/10/2024.
//

import SwiftUI

struct UploadPhotosView: View {
    @Binding var path: NavigationPath
    let images: [UIImage]
    //@State var navigateToDeckView:Bool = false
    @State var navigateToDeckDeck:PartialDeckPackage? = nil
    
    @State var displayError: String?
    
    private var shouldNavigate: Bool {
       get { navigateToDeckDeck != nil }
       set { navigateToDeckDeck = nil }
   }

    var body: some View {
        VStack {
            Spacer()
            if let error = displayError {
                Text("Error")
                Text(error)
            }
            ScrollingFortuneView()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            Spacer()
        }.onAppear {
            uploadPhotos()
        }
    }
    
    func uploadPhotos() {
        guard let url = URL(string: "https://flashcards.lucasmeijer.com/photos") else {
            print("Invalid URL")
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600
        var body = Data()
        
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.5) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image\(index)\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                SetDisplayError("Error with HTTP request: \(error)")
                return
            }
            
            if let data2 = data {
                // Print JSON string representation
                if let jsonString = String(data: data2, encoding: .utf8) {
                    print("JSON received: \(jsonString)")
                } else {
                    print("Unable to convert data to string")
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                SetDisplayError("Invalid response")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                SetDisplayError("HTTP Error: \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                SetDisplayError("No data received from server")
                return
            }
            
            
            do {
                let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                
                DispatchQueue.main.async {
                    let fullDeck = DeckPackage(quiz: quiz, creationDate: Date(), images: images)
                    let partialDeck = DeckStorage.shared.saveDeckPackage(deckPackage: fullDeck)
                    let route = Route.deck(deck: partialDeck)
                    path.append(route)
                }
            } catch {
                SetDisplayError("Error decoding response: \(error)")
            }
        }.resume()
    }
    
    func SetDisplayError(_ msg:String)
    {
        DispatchQueue.main.async {
            self.displayError = msg
        }
    }
}


struct FortuneView: View {
    @State private var currentFortune = ""
    @State private var nextFortune = ""
    @State private var offset: CGFloat = 0
    
    let fortunes = [
        "Almost ready.",
        "Giving your homework to the dog",
        "Going through your schoolbooks",
        "Telling your teacher!",
        "Here's an parrot emoji:  🦜",
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text(currentFortune)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: geometry.size.width)
                    .offset(x: offset)
                
                Text(nextFortune)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: geometry.size.width)
                    .offset(x: offset + geometry.size.width)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                offset = -UIScreen.main.bounds.width
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                currentFortune = nextFortune
                nextFortune = fortunes.randomElement() ?? ""
                offset = 0
            }
        }
        .onAppear {
            currentFortune = fortunes.randomElement() ?? ""
            nextFortune = fortunes.randomElement() ?? ""
        }
    }
}


struct ScrollingFortuneView: View {
    let fortunes = [
        "Almost ready.",
        "Giving your homework to the dog",
        "Going through your schoolbooks",
        "Telling your teacher!",
        "Here's an parrot emoji:  🦜",
    ]
    
    @State private var currentIndex = 0
    
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(0..<fortunes.count, id: \.self) { index in
                        Text(fortunes[index])
                            .font(.title)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(10)
                            .id(index)
                    }
                }
            }
            .onReceive(timer) { _ in
                withAnimation(.spring()) {
                    currentIndex = (currentIndex + 1) % fortunes.count
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
        .onAppear {
            UIScrollView.appearance().isPagingEnabled = true
        }
    }
}
#Preview {
    UploadPhotosView(path:.constant(NavigationPath()), images: [])
}
