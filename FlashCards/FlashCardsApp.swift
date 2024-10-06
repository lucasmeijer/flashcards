//
//  FlashCardsApp.swift
//  FlashCards
//
//  Created by Lucas Meijer on 05/10/2024.
//

import SwiftUI

@main
struct FlashCardsApp: App {
    
    
    var body: some Scene {
        WindowGroup {
            MyRoot()
        }
    }
}

struct MyRoot : View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            DecksListView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .takePhotos:
                        TakePhotosView()
                    case .uploadPhotos(let images):
                        UploadPhotosView(path: $path, images:images)
                    case .deck(let deck):
                        DeckView(deck: deck, path:$path)
                    }
                }
        }
    }
}


enum Route: Hashable {
    case takePhotos
    case uploadPhotos(images: [UIImage])
    case deck(deck: PartialDeckPackage)
}
