import SwiftUI

struct DecksListView: View {
    @State private var shouldNavigateToTakePhotos: Bool = false
    @StateObject private var deckStorage = DeckStorage.shared
    
    var body: some View {
        
        List {
            NavigationLink(destination: TakePhotosView(), isActive: $shouldNavigateToTakePhotos) {
                Text("Create new Flash Card deck!")
            }.frame(height:80)
            
            ForEach(deckStorage.decks) { item in
                NavigationLink(destination: DeckView(deck:item)) {
                    Text(item.title)
                }.frame(height:80)
            }.onDelete(perform: { indexSet in
                deckStorage.deleteDeckPackage(id: indexSet)
            })
            
        }.onAppear {
            //set shouldNavigateToTakePhotos
        }
    }
}

#Preview {
    DecksListView()
}
