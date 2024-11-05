using System.Text;
using System.Text.Json;
using Amazon.BedrockRuntime.Model;
using LanguageModels;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Server;
using SolidGroundClient;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks().AddCheck("Health", () => HealthCheckResult.Healthy("OK"));
builder.Services.AddLanguageModels();
builder.Services.AddSolidGround<FlashCardsSolidGroundVariables>();
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

app.MapSolidGroundEndpoint();

app.MapPost("/fake", () => Results.Json(new Quiz("Nederlands", "Neppe quiz", [
    new("wie is de beste", "lucas"),
    new("wat is 4+4", "8"),
    new("leg uit wat plagiaat is", "copieren"),
    new("wat is lucas zn programmeertaal","csharp"),
])));

app.MapPost("/photos", async (AnthropicLanguageModels models, CancellationToken cancellationToken, HttpRequest httpRequest,
    SolidGroundSession solidGroundPayload, FlashCardsSolidGroundVariables variables) =>
{
    await solidGroundPayload.CaptureRequestAsync();

    var form = httpRequest.Form;

    var functions = CSharpBackedFunctions.Create([new Functions2()]);

    //var imageMessages = await Task.WhenAll(form.Files.Select(async f => new ImageMessage("user", f.ContentType, await f.ToBase64Async())));
    var imageMessages = new List<ImageMessage>();
    foreach (var file in form.Files)
    {
        var base64 = await file.ToBase64Async();
        imageMessages.Add(new ImageMessage("user", file.ContentType, base64));
    }

    
    var systemPrompt = variables.SystemPrompt.Value;
    var cr = new ChatRequest()
    {
        SystemPrompt = systemPrompt,
        Messages =
        [
            new ChatMessage("user", variables.Prompt.Value.Replace("**FUNCTION**", functions.Single().Name)),
            ..imageMessages
        ],
        Functions = functions,
        Temperature = variables.Temperature.Value,
        //MandatoryFunction = functions.Single()
    };

    solidGroundPayload.AddArtifactJson("chatrequest", cr with { Messages = [..cr.Messages.Where(m => m is not ImageMessage)] });

    ILanguageModel ModelToUse()
    {
        return variables.LanguageModel.Value switch
        {
            "sonnet35old" => models.Sonnet35,
            "sonnet35new" => models.Sonnet35New
        };
    }
    
    await using var result = models.Sonnet35.Execute(cr, cancellationToken);

    await foreach (var message in result.ReadCompleteMessagesAsync())
    {
        if (message is ChatMessage cm)
        {
            solidGroundPayload.AddArtifact("response_chatmessage", cm.Text);
            Console.WriteLine(cm.Text);
        }

        if (message is FunctionInvocation functionInvocation)
        {
            var s = JsonSerializer.Serialize(functionInvocation.Parameters.RootElement,
                new JsonSerializerOptions { WriteIndented = true });
            Console.WriteLine(s);

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var quiz = functionInvocation.Parameters.Deserialize<Quiz>(options) ??
                       throw new InternalServerException("Unparseable functioninvocation");

            //solidGroundPayload.AddName(quiz.Title);
            solidGroundPayload.AddResult(FlatTextOf(quiz));

            string FlatTextOf(Quiz quiz)
            {
                var sb = new StringBuilder();
                sb.AppendLine(quiz.Title);
                sb.AppendLine(quiz.Language);
                sb.AppendLine();
                foreach (var question in quiz.Questions)
                {
                    sb.AppendLine("Q: " +question.Question);
                    sb.AppendLine("A: " +question.Answer);
                    sb.AppendLine();
                }

                return sb.ToString();
            }

            return Results.Json(quiz);
        }
    }

    return Results.InternalServerError("No functioncall");
}).DisableAntiforgery();

app.Run();

record Quiz(
    string Language,
    string Title,
    Question2[] Questions);

record Question2(
    [DescriptionForLanguageModel("A question about the material")]
    string Question,
    [DescriptionForLanguageModel("The correct answer to the question. do not repeat the question in the answer.")]
    string Answer);

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

static class Extensions
{
    public static async Task<string> ToBase64Async(this IFormFile self)
    {
        await using var fileStream = self.OpenReadStream();
        using var ms = new MemoryStream();
        await fileStream.CopyToAsync(ms);
        return Convert.ToBase64String(ms.ToArray());
    }
}