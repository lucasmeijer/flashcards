using System.Reflection;
using System.Text.Json.Nodes;

namespace LanguageModels;

static class InputSchemas
{ 
    record InputSchemaProperty(string Name, DescriptionForLanguageModel? DescriptionForLanguageModel, Type Type, bool Required = true);

    public static JsonObject InputSchemaFor(MethodInfo methodInfo)
    {
        InputSchemaProperty PropertyFor(ParameterInfo p) => new(p.Name!.ToLower(), p.GetCustomAttribute<DescriptionForLanguageModel>(), p.ParameterType, true);

        return InputSchemaFor([..methodInfo.GetParameters().Select(PropertyFor)]);
    }
    
    static JsonObject InputSchemaFor(InputSchemaProperty[] inputSchemaProperties)
    {
        var properties = new JsonObject();
        var required = new JsonArray();
        
        foreach (var inputSchemaProperty in inputSchemaProperties)
        {
            var propertyName = inputSchemaProperty.Name.ToLower();

            properties.Add(propertyName, PropertyEntryFor(inputSchemaProperty));
            if (inputSchemaProperty.Required)
                required.Add(propertyName);
        }
        
        return new()
        {
            ["type"] = "object",
            ["properties"] = properties,
            ["required"] = required 
        };

        JsonNode PropertyEntryFor(InputSchemaProperty inputSchemaProperty)
        {
            var result = new JsonObject();
        
            if (inputSchemaProperty.DescriptionForLanguageModel != null)
                result["description"] = inputSchemaProperty.DescriptionForLanguageModel.Description;
        
            var type = TypeFor(inputSchemaProperty.Type);
            if (type == "object")
                return InputSchemaFor(inputSchemaProperty.Type);
            
            result["type"] = type;
            
            if (type == "array")
                result["items"] = InputSchemaFor(inputSchemaProperty.Type.GetElementType() ?? throw new Exception("array without elementtype"));

            return result;
        }
    }

    static JsonObject InputSchemaFor(Type t)
    {
        var inputSchemaProperties = t
            .GetProperties()
            .Select(p =>
            {
                var matchingConstructorParameter = t.GetConstructors()
                    .FirstOrDefault()?
                    .GetParameters()
                    .FirstOrDefault(pa => string.Equals(pa.Name, p.Name, StringComparison.CurrentCultureIgnoreCase))
                    ?.GetCustomAttribute<DescriptionForLanguageModel>();
                
                return new InputSchemaProperty(
                    Name: p.Name.ToLower(),
                    DescriptionForLanguageModel: p.GetCustomAttribute<DescriptionForLanguageModel>() ?? matchingConstructorParameter,
                    Type: p.PropertyType,
                    Required: true);
            })
            .ToArray();
        
        return InputSchemaFor(inputSchemaProperties);
    }

    static string TypeFor(Type t)
    {
        if (t == typeof(string))
            return "string";
        if (t == typeof(decimal) || t == typeof(float) || t == typeof(double))
            return "number";
        if (t == typeof(int))
            return "integer";
        if (t == typeof(bool))
            return "boolean";
        if (t.IsArray)
            return "array";
        return "object";
    }
}