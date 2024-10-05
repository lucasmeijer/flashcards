var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.MapPost("/photos", () =>
{
    return new Deck("Lichaamsdelen", 
        [
            new(
                Question: "hoe werkt je enkel", 
                Answer: "met een schanier", 
                Context: "staat in je boek!")
        ]);
});

app.Run();

record Deck(string Title, Card[] Cards);
record Card(string Question, string Answer, string Context);

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
