import SwiftUI


class Card: ObservableObject, Identifiable{
    init(quizQuestion: QuizQuestion, color: Color?) {
        self.quizQuestion = quizQuestion
        self.color = color ?? Color.white
    }
    
    var id:String { quizQuestion.id }
    let quizQuestion: QuizQuestion
    let color: Color
    
    @Published var offset: CGSize = .zero
    @Published var showAnswer = false
    @Published var discarded = false
    @Published var initialRotation = Double.random(in: -5...5)
}

struct CardView: View {
    @ObservedObject var card: Card
    @GestureState private var gestureOffset: CGSize = .zero

    var onPlaceAtBottom: () -> Void
    var onDiscard: () -> Void
    
    var body: some View {
        VStack {
            Text(card.quizQuestion.question)
                .padding()
            ZStack {
                Text(card.quizQuestion.answer)
                    .padding()
                    .background(Color.clear) // This ensures the Text size is calculated correctly
                    .overlay(
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(card.color)
                                .rotationEffect(.degrees(5))
                                .opacity(card.showAnswer ? 0 : 1)
                                .brightness(0.1)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    )
            }
            
        }
        .frame(width: 300, height: 500)
        .background(card.color)
        .foregroundColor(Color.black)
        .cornerRadius(10)
        .rotationEffect(.degrees(card.initialRotation + Double(card.offset.width / 20)))
        .offset(x: card.offset.width, y: card.offset.height)
        .shadow(color: Color.black.opacity(0.1), radius: 2)

        .gesture(
            DragGesture()
                .updating($gestureOffset) { value, state, _ in
                    if (!card.discarded) {
                        state = value.translation
                    }
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
                            DispatchQueue.main.asyncAfter(deadline: .now()) {
                                withAnimation(.spring()) {
                                    card.offset = .zero
                                }
                            }
                        }
                    } else if value.predictedEndTranslation.width < -200 {
                        card.discarded = true
                        onDiscard()
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
    var deck: PartialDeckPackage
    @Binding var path: NavigationPath
    @State private var stackedCards: [Card]
    
    init(deck: PartialDeckPackage, path: Binding<NavigationPath>) {
         self.deck = deck
         self._path = path
        
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
        
        let cards = deck.quiz.questions.shuffled().enumerated().map { (index,question) in Card.init(quizQuestion: question, color: pastelColors[index % 9])}
        self._stackedCards = State(initialValue: cards)
    }
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                VStack {
                    Text("You made it!")
                }
                
                ForEach(stackedCards) { card in
                    CardView(card: card) {
                        moveToBottom(card:card)
                    } onDiscard: {
                        resetDeckIfAllCardsAreDiscarded()
                    }
                }
            }
            Spacer()
        }.navigationBarBackButtonHidden()
            .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                customBackButton
            }
        }
    }
    
    func resetDeckIfAllCardsAreDiscarded()
    {
        if (!stackedCards.allSatisfy { $0.discarded }) {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline:  .now() + 1.0) {
            stackedCards.forEach { card in
                card.discarded = false
                withAnimation(.spring(duration: Double.random(in: 0.3...1.3))) {
                    card.offset = .zero
                }
                card.showAnswer = false
            }
        }
    }
    
    func moveToBottom(card: Card)
    {
        stackedCards.removeAll { $0.id == card.id }
        stackedCards.insert(card, at: 0)
    }
    
    
    private var customBackButton: some View {
        Button(action: {
            path = NavigationPath()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text("Back")
            }
        }
    }
}

func dummyDeck() -> PartialDeckPackage
{
    let funnyQuestions = [
        QuizQuestion(question: "Why don't scientists trust atoms?",
             answer: "Because they make up everything!",
             locationOfAnswerInMaterial: "Chapter 1"
             ),
        
        QuizQuestion(question: "What do you call a fake noodle?",
             answer: "An impasta!",
                     locationOfAnswerInMaterial: "Chapter 2"
             ),
        QuizQuestion(question: "Why did the scarecrow win an award?",
             answer: "He was outstanding in his field!",
                     locationOfAnswerInMaterial: "Chapter 3"
             ),
        QuizQuestion(question: "Why don't eggs tell jokes?",
             answer: "They'd crack each other up!",
                     locationOfAnswerInMaterial: "Chapter 4"
             ),
        QuizQuestion(question: "What do you call a bear with no teeth?",
             answer: "A gummy bear!",
                     locationOfAnswerInMaterial: "Chapter 5"
             ),
        QuizQuestion(question: "Why did the math book look so sad?",
             answer: "Because it had too many problems!",
                     locationOfAnswerInMaterial: "Chapter 6"
             ),
        QuizQuestion(question: "What do you call a sleeping bull?",
             answer: "A bulldozer!",
                     locationOfAnswerInMaterial: "Chapter 7"
             ),
        QuizQuestion(question: "Why can't a nose be 12 inches long?",
             answer: "Because then it would be a foot!",
                     locationOfAnswerInMaterial: "Chapter 8"
             ),
        QuizQuestion(question: "What do you call a can opener that doesn't work?",
             answer: "A can't opener!",
                     locationOfAnswerInMaterial: "Chapter 9"
             ),
        QuizQuestion(question: "Why did the golfer bring two pairs of pants?",
             answer: "In case he got a hole in one!",
                     locationOfAnswerInMaterial: "Chapter 10"
             )
    ]
    let quiz = Quiz.init(language: "English", title: "Dad Jokes \(Int.random(in: 100...999))", questions: funnyQuestions)
    return .init(quiz:quiz, creationDate: Date())

}

#Preview {
    return NavigationView {
        DeckView(deck: dummyDeck(), path:.constant(NavigationPath()))
    }
}
