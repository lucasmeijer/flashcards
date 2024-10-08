using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Server;

class SolidGroundPayload<T>(T input, HttpClient httpClient) : IAsyncDisposable
{
    JsonObject _outputs = new();

    public void AddResult(string value) => AddArtifact("result", value);
    public void AddResultJson(object value) => AddArtifactJson("result", value);
    public void AddArtifact(string name, string value) => _outputs[name] = value;
    public void AddArtifactJson(string name, object value) => AddArtifact(name,JsonSerializer.Serialize(value));
    
    public async ValueTask DisposeAsync()
    {
        Console.WriteLine("ABOUT TO SEND!!!");
        await httpClient.PostAsJsonAsync("https://localhost:7109/api/execution2", new
        {
            input = input,
            output = _outputs,
            name = "production"
        });
    }
}

public static class SolidGroundExtensions
{
    public static void AddSolidGround<T>(this IServiceCollection serviceCollection) where T : class
    {
        // serviceCollection.AddHttpContextAccessor();
        // serviceCollection.AddScoped<SolidGroundPayload>(sp => 
        // {
        //     var httpContextAccessor = sp.GetRequiredService<IHttpContextAccessor>();
        //     var httpContext = httpContextAccessor.HttpContext ?? throw new InvalidOperationException("HttpContext is null");
        //     
        //     if (!httpContext.Items.TryGetValue(typeof(T).Name, out var paramsObject))
        //         throw new InvalidOperationException($"No {typeof(T).Name} found");
        //     
        //     if (paramsObject == null)
        //         throw new InvalidOperationException("Params object is null");
        //     
        //     return new(sp.GetRequiredService<HttpClient>(), (T)paramsObject);
        // });
    }
}