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
    
    private var shouldNavigate: Bool {
       get { navigateToDeckDeck != nil }
       set { navigateToDeckDeck = nil }
   }

    var body: some View {
        VStack {
            Spacer()
            ScrollingFortuneView()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            Spacer()
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let fullDeck = DeckPackage.init(quiz: dummyDeck().quiz, creationDate: Date(),images: [])
                let partialDeck = DeckStorage.shared.saveDeckPackage(deckPackage:fullDeck)
                let route = Route.deck(deck: partialDeck)
                path.append(route)
            }
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
                let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                DispatchQueue.main.async {
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }.resume()
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
