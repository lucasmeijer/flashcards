import SwiftUI


struct CardView: View {
    var card: Card
    @State private var showAnswer = false
    @State private var rotation: Double;
    
    init(card: Card) {
           self.card = card
           _rotation = State(initialValue: Double.random(in: -5...5))
       }

    var body: some View {
        VStack {
            if showAnswer {
                Text(card.answer)
                    .padding()
            } else {
                Text(card.question)
                    .padding()
            }
        }
        .frame(width: 300, height: 500)
        .background(card.color)
        .cornerRadius(10)
        .rotationEffect(.degrees(rotation))
        .onTapGesture {
            showAnswer.toggle()
        }
    }
}

struct DeckView: View {
    var deck: Deck
    
    @State private var stackedCards: [Card]
    
    init(deck: Deck) {
        self.deck = deck
        self.stackedCards = deck.questions
    }
    
    var body: some View {
        VStack {
            Text(deck.title)
            Spacer()
            ZStack {
                ForEach(Array(stackedCards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card)
                        .shadow(radius: index == 9 ? 10 : 0)
                        .onTapGesture {
                            stackedCards.removeAll { $0.id == card.id }
                        }
                }
            }
            Spacer()
        }
    }
}


#Preview {
    let pastelColors: [Color] = [
        Color(red: 0.996, green: 0.906, blue: 0.929), // Soft Pink
        Color(red: 0.929, green: 0.965, blue: 0.996), // Baby Blue
        Color(red: 0.996, green: 0.961, blue: 0.898), // Pale Yellow
        Color(red: 0.898, green: 0.976, blue: 0.965), // Mint Green
        Color(red: 0.965, green: 0.933, blue: 0.996), // Lavender
        Color(red: 0.992, green: 0.929, blue: 0.906), // Peach
        Color(red: 0.929, green: 0.996, blue: 0.957), // Seafoam
        Color(red: 0.996, green: 0.941, blue: 0.902), // Apricot
        Color(red: 0.906, green: 0.961, blue: 0.996), // Sky Blue
        Color(red: 0.976, green: 0.957, blue: 0.929)  // Eggshell
    ]
    
    let funnyQuestions = [
        Card(question: "Why don't scientists trust atoms?",
             answer: "Because they make up everything!",
             locationofanswerinmaterial: "Chapter 1",
             color: pastelColors[0]),
        Card(question: "What do you call a fake noodle?",
             answer: "An impasta!",
             locationofanswerinmaterial: "Chapter 2",
             color: pastelColors[1]),
        Card(question: "Why did the scarecrow win an award?",
             answer: "He was outstanding in his field!",
             locationofanswerinmaterial: "Chapter 3",
             color: pastelColors[2]),
        Card(question: "Why don't eggs tell jokes?",
             answer: "They'd crack each other up!",
             locationofanswerinmaterial: "Chapter 4",
             color: pastelColors[3]),
        Card(question: "What do you call a bear with no teeth?",
             answer: "A gummy bear!",
             locationofanswerinmaterial: "Chapter 5",
             color: pastelColors[4]),
        Card(question: "Why did the math book look so sad?",
             answer: "Because it had too many problems!",
             locationofanswerinmaterial: "Chapter 6",
             color: pastelColors[5]),
        Card(question: "What do you call a sleeping bull?",
             answer: "A bulldozer!",
             locationofanswerinmaterial: "Chapter 7",
             color: pastelColors[6]),
        Card(question: "Why can't a nose be 12 inches long?",
             answer: "Because then it would be a foot!",
             locationofanswerinmaterial: "Chapter 8",
             color: pastelColors[7]),
        Card(question: "What do you call a can opener that doesn't work?",
             answer: "A can't opener!",
             locationofanswerinmaterial: "Chapter 9",
             color: pastelColors[8]),
        Card(question: "Why did the golfer bring two pairs of pants?",
             answer: "In case he got a hole in one!",
             locationofanswerinmaterial: "Chapter 10",
             color: pastelColors[9])
    ]
    
    let deck = Deck(language: "English", title: "Dad Jokes 101", questions: funnyQuestions)
    return NavigationView {
        DeckView(deck: deck)
    }
}
