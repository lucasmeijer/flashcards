using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace LanguageModels;

public record AmazonBedrockCredentials(string AmazonAccessKey, string AmazonSecretAccessKey, string Region)
{
    // ReSharper disable once UnusedMember.Global
    public AmazonBedrockCredentials(IConfiguration configuration, ILogger<AmazonBedrockCredentials> logger) : this(configuration.GetMandatory("AMAZON_ACCESS_KEY"),
        configuration.GetMandatory("AMAZON_SECRET_ACCESS_KEY"),
        configuration.GetMandatory("AMAZON_REGION"))
    {
    }
}