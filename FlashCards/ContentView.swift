import SwiftUI

struct ContentView: View {
    
    var body: some View {
       Text("hallo")
    }
}

struct Quiz: Identifiable, Decodable, Encodable {
    let language: String
    let title: String
    let questions: [QuizQuestion]
    
    var id: String {
        let concatenatedString = language + title + questions.map { $0.question }.joined(separator: "_")
        return String(concatenatedString.hashValue)
    }
}


struct QuizQuestion: Identifiable, Decodable, Encodable {
    let question: String
    let answer: String
    let locationofanswerinmaterial: String
    
    var id: String {
        return "\(question.hashValue)_\(answer.hashValue)_\(locationofanswerinmaterial.hashValue)"
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
