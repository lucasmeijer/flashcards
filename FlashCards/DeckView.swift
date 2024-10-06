import SwiftUI


struct Card
{
    let quizQuestion: QuizQuestion
    var offset: CGSize = .zero
    var color: Color = Color.white
    
    var showAnswer = false
    var discarded = false
    var initialRotation = Double.random(in: -5...5)
}

struct CardView: View {
    @State var card: Card
    @GestureState private var gestureOffset: CGSize = .zero

    var onPlaceAtBottom: () -> Void
    
    var body: some View {
        VStack {
            Text(card.quizQuestion.question)
                .padding()
            ZStack {
                Text(card.quizQuestion.answer)
                    .padding()
                
                Rectangle()
                    .fill(card.color)
                    .rotationEffect(.degrees(5))
                    .frame(height: 100)
                    .opacity(card.showAnswer ? 0 : 1)
                    .brightness(0.1)
            }
            
        }
        .frame(width: 300, height: 500)
        .background(card.color)
        .foregroundColor(Color.black)
        .cornerRadius(10)
        .rotationEffect(.degrees(card.initialRotation + Double(card.offset.width / 20)))
        .offset(x: card.offset.width, y: card.offset.height)
        .shadow(radius: 2)
//        .shadow(radius: shouldShowShadow ? 10 : 0)
//        .onChange(of: shouldShowShadow) { _, newValue in
//            withAnimation(.easeInOut(duration: 0.5))
//            {
//                shouldShowShadow = newValue
//            }
//        }
        .gesture(
            DragGesture()
                .updating($gestureOffset) { value, state, _ in
                    if (!card.discarded) {
                        state = value.translation
                    }
                    //offset = value.translation
                }
                .onChanged { value in
                    card.offset = value.translation
                }
                .onEnded { value in
                    
                    if value.predictedEndTranslation.width > 200 {
                        withAnimation(.spring()) {
                            card.offset = .init(width: 500, height:0)
                        } completion: {
                            onPlaceAtBottom()
                            card.showAnswer = false
                            withAnimation(.spring()) {
                                card.offset = .zero
                            }
                        }
                    } else if value.predictedEndTranslation.width < -200 {
                        card.discarded = true
                        withAnimation(.spring()) {
                            card.offset = .init(width: -500, height:0)
                        }
                    } else {
                        withAnimation(.spring()) {
                            card.offset = .zero
                        }
                    }
                }
        )
       
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                card.showAnswer = true
            }
        }
    }
}

struct DeckView: View {
    var deck: Deck
    
    @State private var stackedCards: [Card]
    
    init(deck: Deck) {
        self.deck = deck
        
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
        
        let cards = deck.questions.enumerated().map { (index,question) in Card.init(quizQuestion: question, color: pastelColors[index])}
        self._stackedCards = State(initialValue: cards)
    }
    
    var body: some View {
        VStack {
            Text(deck.title)
            Spacer()
            ZStack {
                Text("Congratulations! You've gone through all the cards!")
                    .padding()
                
                ForEach(stackedCards, id: \.quizQuestion.id) { card in
                    CardView(card: card) {
                      //onPlaceAtBottom:
                        if let index = stackedCards.firstIndex(where: { $0.quizQuestion.id == card.quizQuestion.id }) {
                           stackedCards.remove(at: index)
                           stackedCards.insert(card, at: 0)
                       }
                    }
                }
            }
            Spacer()
        }
    }
}

func dummyDeck() -> Deck
{

    
    let funnyQuestions = [
        QuizQuestion(question: "Why don't scientists trust atoms?",
             answer: "Because they make up everything!",
             locationofanswerinmaterial: "Chapter 1"
             ),
        
        QuizQuestion(question: "What do you call a fake noodle?",
             answer: "An impasta!",
             locationofanswerinmaterial: "Chapter 2"
             ),
        QuizQuestion(question: "Why did the scarecrow win an award?",
             answer: "He was outstanding in his field!",
             locationofanswerinmaterial: "Chapter 3"
             ),
        QuizQuestion(question: "Why don't eggs tell jokes?",
             answer: "They'd crack each other up!",
             locationofanswerinmaterial: "Chapter 4"
             ),
        QuizQuestion(question: "What do you call a bear with no teeth?",
             answer: "A gummy bear!",
             locationofanswerinmaterial: "Chapter 5"
             ),
        QuizQuestion(question: "Why did the math book look so sad?",
             answer: "Because it had too many problems!",
             locationofanswerinmaterial: "Chapter 6"
             ),
        QuizQuestion(question: "What do you call a sleeping bull?",
             answer: "A bulldozer!",
             locationofanswerinmaterial: "Chapter 7"
             ),
        QuizQuestion(question: "Why can't a nose be 12 inches long?",
             answer: "Because then it would be a foot!",
             locationofanswerinmaterial: "Chapter 8"
             ),
        QuizQuestion(question: "What do you call a can opener that doesn't work?",
             answer: "A can't opener!",
             locationofanswerinmaterial: "Chapter 9"
             ),
        QuizQuestion(question: "Why did the golfer bring two pairs of pants?",
             answer: "In case he got a hole in one!",
             locationofanswerinmaterial: "Chapter 10"
             )
    ]
    
    return Deck.init(language: "English", title: "Dad Jokes 101", questions: funnyQuestions)

}

#Preview {
    return NavigationView {
        DeckView(deck: dummyDeck())
    }
}
