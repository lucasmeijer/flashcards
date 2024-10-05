using Amazon;
using Amazon.BedrockRuntime;
using Amazon.Runtime;
using Microsoft.Extensions.DependencyInjection;

namespace LanguageModels;

static class BedrockExtensions
{
    internal static void SetupAmazonBedrock(this IServiceCollection serviceCollection)
    {
        serviceCollection.AddSingleton<AmazonBedrockCredentials>();
        serviceCollection.AddSingleton<AmazonBedrockRuntimeClient>(sp =>
        {
            var creds = sp.GetRequiredService<AmazonBedrockCredentials>();
            var credsRegion = creds.Region;
            return new(
                credentials: new BasicAWSCredentials(
                    accessKey: creds.AmazonAccessKey, 
                    secretKey: creds.AmazonSecretAccessKey),
                region: RegionEndpoint.GetBySystemName(credsRegion)
            );
        });
        serviceCollection.AddSingleton<BedrockModels>();
    }
}