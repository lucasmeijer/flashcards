using SolidGroundClient;

namespace Server;

class FlashCardsSolidGroundVariables : SolidGroundVariables
{
    public readonly SolidGroundVariable<string> Prompt = new("Prompt",
        
        """
        You will receive one or more photos taken of learning material, often a school book.
        Your job is to read all the learning material, and produce a series of quiz questions that can be used by a student to quiz themselves to see if they understand the material.

        You should think in steps:
        - read the material closely.
        - write into <genre></genre> what kind of learning material is in the photos.
        - if the genre is a vocabulary test, analyze which language is the language to learn, and which is the known language. write to <language_to_learn> and <known_language>.
          use the known language for all your quiz questions and quiz answers.
        - if the genre is not cross language learning, write the language used in the material into <language> and use this for all your quiz questions and quiz answers.
        - If the genre is like a text the student wants to learn, write a structured overview of the material in <structuredoverview>.
        - write the topic of the learning material into <topic></topic>
        - first lets only write the questions for the quiz into <questions></questions>.
        - If the material is a vocabulary test, make the questions just be only the input word, and the answer just be the output word. make a question for every vocabulary word in the input material. 
        - Keep writing questions to the point where if a student can answer them all correctly, she fully understands all provided material.
        - now call the **FUNCTION** tool. 
        """);
    
    public readonly SolidGroundVariable<string> SystemPrompt = new("SystemPrompt", "You are a excellent empathetic tutor that helps students learn");
    public readonly SolidGroundVariable<float> Temperature = new("Temperature", 0.5f);
    public readonly SolidGroundVariable<string> LanguageModel = new("LanguageModel", "sonnet35old");
}