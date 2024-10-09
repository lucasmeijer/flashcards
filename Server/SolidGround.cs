using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using LanguageModels;

namespace Server;

class SolidGroundPayload(HttpClient httpClient, HttpContext httpContext, IConfiguration config)
{
    HttpRequest Request => httpContext.Request;

    string? _serviceBaseUrl = config["SOLIDGROUND_BASE_URL"];
    
    string? _outputIdInHeader = httpContext.Request.Headers.TryGetValue("SolidGroundOutputId", out var id) ? id.ToString() : null;
    JsonObject? _capturedRequest;
    JsonObject _outputs = new();
    
    public async Task CaptureRequestAsync()
    {
        Request.EnableBuffering();
        using var memoryStream = new MemoryStream();
        var pos = Request.Body.Position;
        Request.Body.Position = 0;
        await Request.Body.CopyToAsync(memoryStream);
        Request.Body.Position = pos;
        
        _capturedRequest = new()
        {
            ["body_base64"] = Convert.ToBase64String(memoryStream.ToArray()),
            ["content_type"] = Request.ContentType,
            ["host"] = Request.Host.Value,
            ["route"] = Request.Path.Value,
        };
     
        if (_serviceBaseUrl != null)
            httpContext.Response.OnCompleted(SendPayload);
    }

    async Task SendPayload()
    {
        if (_outputIdInHeader != null)
        {
            //This is a rerun being executed by solidground. In this scenario we only have to upload the output under the requested id.
            await httpClient.PostAsync($"{_serviceBaseUrl}/api/output/{_outputIdInHeader}",
                new StringContent(JsonSerializer.Serialize(_outputs),
                    Encoding.UTF8,
                    "application/json"));
            return;
        }
        
        //this is the normal production flow where we emit a complete execution + input + output
        await httpClient.PostAsJsonAsync($"{_serviceBaseUrl}/api/input", new
        {
            request = _capturedRequest ?? throw new ArgumentException("Captured request is null"),
            output = _outputs,
            name = "production"
        });
    }
    
    public void AddResult(string value) => AddArtifact("result", value);
    public void AddResultJson(object value) => AddArtifactJson("result", value);
    public void AddArtifact(string name, string value) => _outputs[name] = value;
    public void AddArtifactJson(string name, object value) => AddArtifact(name,JsonSerializer.Serialize(value));

}

public static class SolidGroundExtensions
{
    public static void AddSolidGround(this IServiceCollection serviceCollection)
    {
        serviceCollection.AddHttpContextAccessor();
        serviceCollection.AddScoped<SolidGroundPayload>(sp => 
        {
            var httpContextAccessor = sp.GetRequiredService<IHttpContextAccessor>();
            var httpContext = httpContextAccessor.HttpContext ?? throw new InvalidOperationException("HttpContext is null");
            return new(sp.GetRequiredService<HttpClient>(), httpContext, sp.GetRequiredService<IConfiguration>());
        });
    }
}