---
inclusion: always
---

# Coding Conventions and Standards

## General C# Standards

### Language Version
- **C# 12** with .NET 8
- **Nullable reference types enabled** - All projects use `<Nullable>enable</Nullable>`
- **Implicit usings enabled** - Common namespaces imported automatically

### Code Style
- Follow standard C# naming conventions
- Use `sealed` for classes that shouldn't be inherited
- Use `readonly` for fields that don't change after construction
- Prefer expression-bodied members for simple properties/methods

## Project Organization

### Feature Folders
Organize code by feature/domain, not by technical layer:

```
Features/
  ├── [FeatureName]/
  │   ├── Endpoints/          # API endpoints
  │   ├── Services/           # Business logic
  │   ├── Repositories/       # Data access
  │   ├── Validators/         # FluentValidation validators
  │   ├── Mapping/            # Request/Response mapping
  │   ├── Models/             # Domain models
  │   └── [FeatureName]Extensions.cs  # Endpoint registration
```

### Naming Conventions

**Endpoints**
- Pattern: `{Verb}{Entity}{Action}Endpoint.cs`
- Examples: `GetTrainByIdEndpoint.cs`, `UpdateStationTimesEndpoint.cs`
- Each endpoint is a static class with:
  - `public const string Name` - Endpoint name constant
  - `Map{Action}` extension method - Registration method
  - Private handler method - Actual endpoint logic

**Services**
- Pattern: `{Entity}Service.cs`
- Examples: `TrainService.cs`, `RoutePointService.cs`
- Marked with `[Service]` attribute for auto-registration
- Implement interface for testability (e.g., `ITrainService`)

**Repositories**
- Pattern: `{Entity}Repository.cs`
- Examples: `TrainRepository.cs`, `RoutePointRepository.cs`
- Inherit from `RepositoryBase`
- Implement interface (e.g., `ITrainRepository`)
- Auto-registered via reflection

**Validators**
- Pattern: `{Request/Args}Validator.cs`
- Examples: `TrainIdValidator.cs`, `GetTrainsRequestValidator.cs`
- Inherit from `AbstractValidator<T>`
- Auto-registered via FluentValidation assembly scanning

**Mapping**
- Extension methods for mapping between layers
- Pattern: `{Source}To{Destination}` methods
- Examples: `MapToArgs()`, `MapToResponse()`, `MapToEntity()`

## Endpoint Patterns

### Standard Endpoint Structure

```csharp
public static class GetTrainByIdEndpoint
{
    public const string Name = "GetTrainById";

    public static IEndpointRouteBuilder MapGetTrainById(this IEndpointRouteBuilder app)
    {
        app.MapPost(ApiEndpoints.Trains.GetById, GetTrainById)
           .Produces<GetTrainsResponse>()
           .Produces<ServerErrorResponse>(StatusCodes.Status500InternalServerError)
           .WithName(Name)
           .WithTags(TrainsExtensions.GroupName)
           .WithOpenApi(o =>
           {
               o.OperationId = Name;
               return o;
           });
        return app;
    }

    /// <summary>
    /// XML documentation for Swagger
    /// </summary>
    private static async Task<Ok<GetTrainsResponse>> GetTrainById(
        GetByTrainIdRequest request,
        TrainService trainService,
        CancellationToken token)
    {
        var args = request.MapToArgs();
        var result = await trainService.GetByIdAsync(args, token);
        var response = result.MapToResponse();
        return TypedResults.Ok(response);
    }
}
```

### Endpoint Registration Pattern

Each feature has an extensions class that registers all endpoints:

```csharp
public static class TrainsExtensions
{
    public const string GroupName = "Trains";

    public static IEndpointRouteBuilder MapTrainsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGetTrainsByName()
           .MapGetTrainById()
           .MapGetLocomotivesByTrainId();
        return app;
    }
}
```

## Dependency Injection

### Service Registration

**Auto-Registration via Attribute**
```csharp
[Service]
public sealed class TrainService : ITrainService
{
    // Implementation
}
```

**Manual Registration**
```csharp
services.AddSingleton<ITimeZoneConverter, TimeZoneConverter>();
services.AddScoped<RippleRetrieverFactory>();
```

### Dependency Injection in Endpoints

Dependencies are injected as method parameters (not constructor):

```csharp
private static async Task<Ok<Response>> Handler(
    Request request,              // From request body
    SomeService service,          // Injected
    CancellationToken token)      // Injected
{
    // Implementation
}
```

## Validation Patterns

### FluentValidation Usage

```csharp
public sealed class TrainIdValidator : AbstractValidator<GetByTrainIdArgs>
{
    public TrainIdValidator()
    {
        RuleFor(x => x.TrainPlanLegId)
            .NotEmpty()
            .When(x => string.IsNullOrWhiteSpace(x.MtpTitanNumber))
            .WithMessage("Either TrainPlanLegId or MtpTitanNumber must be provided");
    }
}
```

### Validation Error Handling

- `ValidationMappingMiddleware` catches `ValidationException`
- Returns 400 Bad Request with structured error response
- Response format: `ValidationFailureResponse` with list of errors

## Error Handling

### Exception Handling Strategy

1. **Validation Errors** - Caught by `ValidationMappingMiddleware` → 400
2. **All Other Exceptions** - Caught by `ErrorLoggerMiddleware` → 500
3. **Structured Responses** - `ServerErrorResponse` and `ValidationFailureResponse`

### Error Response Format

```csharp
public class ServerErrorResponse
{
    public string ErrorMessage { get; set; }
    public string StackTrace { get; set; }
}

public class ValidationFailureResponse
{
    public List<ValidationResponse> Errors { get; set; }
}
```

## Data Access Patterns

### Repository Pattern

```csharp
public class TrainRepository : RepositoryBase, ITrainRepository
{
    public TrainRepository(IDbConnectionFactory connectionFactory) 
        : base(connectionFactory)
    {
    }

    public async Task<Train> GetByIdAsync(int id, CancellationToken token)
    {
        using var connection = await ConnectionFactory.CreateConnectionAsync(token);
        return await connection.QuerySingleOrDefaultAsync<Train>(
            "SELECT * FROM TRAINS WHERE ID = :Id",
            new { Id = id });
    }
}
```

### Dapper Usage

- Use parameterized queries with `:ParameterName` syntax (Oracle)
- Use anonymous objects for parameters
- Use `QueryAsync<T>`, `QuerySingleOrDefaultAsync<T>`, `ExecuteAsync`
- Map column names via `Dapper.FluentMap` in `DatabaseMappings.Initialize()`

## Configuration Patterns

### Options Pattern

```csharp
public class NexusOptions
{
    public const string SectionName = "NexusOptions";
    
    public string ConnectionString { get; set; } = string.Empty;
    public int TrainNotesLockExpiryInMinutes { get; set; }
    public int TrainNotesMaxBatchSize { get; set; }
    public bool EnforceClientAppNameHeader { get; set; }
}

// Registration
services.AddOptions<NexusOptions>()
    .Bind(config.GetSection(NexusOptions.SectionName))
    .ValidateOnStart();
```

## Logging Patterns

### Serilog Usage

```csharp
private readonly ILoggerAdapter<MyClass> _logger;

_logger.LogInformation("Processing train {TrainId}", trainId);
_logger.LogError(ex, "Failed to process train {TrainId}", trainId);
```

### Structured Logging

- Use structured logging with named parameters
- Avoid string interpolation in log messages
- Use `ILoggerAdapter<T>` from CPKC.Logging for consistency

## API Documentation

### XML Comments

All public endpoints must have XML documentation:

```csharp
/// <summary>
/// Fetches a specific Train by either of its primary system identifiers.
/// </summary>
/// <remarks>
/// If the given ID is not found, a 'not found' exception will be thrown.
/// </remarks>
```

### Swagger Configuration

- XML comments automatically included in Swagger
- Use `.Produces<T>()` to document response types
- Use `.WithName()` for operation names
- Use `.WithTags()` for grouping
- Use `.WithOpenApi()` for additional metadata

## Testing Conventions

### Unit Test Naming

- Pattern: `MethodName_Scenario_ExpectedBehavior`
- Example: `GetByIdAsync_WhenTrainExists_ReturnsTrainData`

### Test Organization

- One test class per class under test
- Use `[Fact]` for simple tests
- Use `[Theory]` with `[InlineData]` for parameterized tests
- Use `InternalsVisibleTo` attribute to test internal members

## File Organization

### Assembly Info

- `GlobalAssemblyInfo.cs` at solution root contains shared assembly attributes
- Linked into each project via `<Compile Include="..\..\GlobalAssemblyInfo.cs">`
- `GenerateAssemblyInfo` set to `false` in Directory.Build.props

### Internal Visibility

Projects expose internals to test projects via:

```csharp
[assembly: InternalsVisibleTo("ProjectName.Tests.Unit")]
```

## Performance Considerations

- Use `async`/`await` for all I/O operations
- Pass `CancellationToken` through the call chain
- Use `IAsyncEnumerable<T>` for streaming large datasets
- Consider connection pooling (handled by Oracle.ManagedDataAccess)
- Use `TimeProvider.System` for testable time operations
