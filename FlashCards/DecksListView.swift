import SwiftUI

struct DecksListView: View {
    @State private var shouldNavigateToTakePhotos: Bool = false
    @StateObject private var deckStorage = DeckStorage.shared
    
    var body: some View {
        
        List {
            NavigationLink(value: Route.takePhotos) {
                Text("Create new Flash Card deck!")
            }.frame(height:80)
            
            ForEach(deckStorage.decks) { deck in
                NavigationLink(value: Route.deck(deck: deck)) {
                    ZStack {
                        //Rectangle()
                            //.fill(Color.orange)
                        //    .cornerRadius(10)
                        //    .frame(width: 400)
                        Text(deck.quiz.title)
                    }
                }.frame(height:80)
            }.onDelete(perform: { indexSet in
                deckStorage.deleteDecks(at:indexSet)
            })
            
//            ForEach(deckStorage.decks) { item in
//                NavigationLink(destination: DeckView(deck:item)) {
//                    Text(item.title)
//                }.frame(height:80)
//            }.onDelete(perform: { indexSet in
//              //  deckStorage.deleteDecks(at:indexSet)
//            })
            
        }.onAppear {
            //set shouldNavigateToTakePhotos
        }
    }
}

#Preview {
    DecksListView()
}
