using System.Text.Json;
using LanguageModels;
using Microsoft.AspNetCore.Mvc.Formatters;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks().AddCheck("Health", () => HealthCheckResult.Healthy("OK"));
builder.Services.AddLanguageModels();

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(10);
    serverOptions.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(10);
    serverOptions.Limits.MaxRequestBodySize = null;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseHealthChecks("/up");

app.MapPost("/fake", () =>
{
    return Results.Json(new Quiz("Nederlands", "Neppe quiz", [
        new("wie is de beste", "lucas", "staat in je boek"),
        new("wat is 4+4", "8", "is gewoon zo"),
        new("leg uit wat plagiaat is", "dat je iets pikt van een ander zonder te zeggen dat dat zo is", "pagina 3"),
        new("wat is lucas zn programmeertaal","C#", "lucas vragen"),
    ]));
});

app.MapPost("/photos",
    async (HttpRequest request, AnthropicLanguageModels models, CancellationToken cancellationToken) =>
    {
        var form = await request.ReadFormAsync(cancellationToken);

        var functions = CSharpBackedFunctions.Create([new Functions2()]);

        var cr = new ChatRequest()
        {
            SystemPrompt = "You are a excellent empathetic tutor that helps students learn",
            Messages =
            [
                new ChatMessage("user", $"""
                                         You will receive one or more photos taken of learning material, often a school book.
                                         Your job is to read all the learning material, and produce a series of quiz questions that can be used by a student to quiz themselves to see if they understand the material.

                                         You should think in steps:
                                         - write the language used by the learning material in <language></language>
                                         - use this language for all your quiz questions and quiz answers.
                                         - read the material closely. If the material looks like it's text based, write a structured overview of the material in <structuredoverview>.
                                         - write the topic of the learning material into <topic></topic>
                                         - first lets only write the questions for the quiz into <questions></questions>. If the material is a vocabulary test, make the questions just be only the input word, and the answer just be the output word. make a question for every vocabulary word in the input material. 
                                           Keep writing questions to the point where if a student can answer them all correctly, she fully understands all provided material.
                                         - now call the {functions.Single().Name} tool. 
                                         """),
                ..await Task.WhenAll(form.Files.Select(async f => await ImageMessageFor(f.OpenReadStream())))
            ],
            Functions = functions,
            Temperature = 0.5f,
            //MandatoryFunction = functions.Single()
        };

        await using var result = models.Sonnet35.Execute(cr, cancellationToken);

        await foreach (var message in result.ReadCompleteMessagesAsync())
        {
            if (message is ChatMessage cm)
                Console.WriteLine(cm.Text);

            if (message is FunctionInvocation functionInvocation)
            {
                var s = JsonSerializer.Serialize(functionInvocation.Parameters.RootElement,
                    new JsonSerializerOptions { WriteIndented = true });
                Console.WriteLine(s);

                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var quiz = functionInvocation.Parameters.Deserialize<Quiz>(options);

                return Results.Json(quiz);
            }
        }

        return Results.InternalServerError("No functioncall");

        async Task<ImageMessage> ImageMessageFor(Stream s)
        {
            var ms = new MemoryStream();
            await s.CopyToAsync(ms);
            return new("user", "image/jpeg", Convert.ToBase64String(ms.ToArray()));
        }
    }); 

app.Run();

record Quiz(
    string Language,
    string Title,
    Question2[] Questions);

record Question2(
    [DescriptionForLanguageModel("A question about the material")]
    string Question, 
    [DescriptionForLanguageModel("The correct answer to the question. do not repeat the question in the answer.")]
    string Answer, 
    [DescriptionForLanguageModel("A sentence that the tutor could speak to the student to tell her where she can find the answer to this question in the material she took photos of")]
    string LocationOfAnswerInMaterial);

class Functions2
{
    [DescriptionForLanguageModel("Call this function to provide the quiz")]
    public void ProduceQuiz(
        [DescriptionForLanguageModel("The language in which the quiz' questions are written ")] string Language,
        [DescriptionForLanguageModel("A short topic for this quiz that fits in a button.")] string Title, 
        [DescriptionForLanguageModel("the actual questions and answers of the quiz")] Question2[] Questions)
    {
    }
}

