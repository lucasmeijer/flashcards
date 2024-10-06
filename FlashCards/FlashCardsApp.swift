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
            //ContentView()
            DeckView(deck: dummyDeck())
        }
    }
}
