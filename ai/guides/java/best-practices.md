# Java Best Practices Guide

## Table of Contents

1. [Service Layer Patterns](#1-service-layer-patterns)
2. [Code Organization](#2-code-organization)
3. [Utilities and Helper Classes](#3-utilities-and-helper-classes)
4. [Proto File Management](#4-proto-file-management)
5. [Dependency Injection Patterns](#5-dependency-injection-patterns)
6. [Mapper and Transformation Patterns](#6-mapper-and-transformation-patterns)
7. [Error Handling and Logging](#7-error-handling-and-logging)
8. [Testing Patterns](#8-testing-patterns)
9. [Modern Java Standards](#9-modern-java-standards)
10. [Library Standards](#10-library-standards)
11. [Code Review Checklist](#11-code-review-checklist)

## Code Review Instructions

**For AI Code Reviewers**: When reviewing Java code, you must also read and analyze against the detailed async programming patterns in:

- `/Users/ccasey/dotfiles/ai/guides/java/completable-future.md`

This guide contains comprehensive CompletableFuture patterns, anti-patterns, and best practices that should be applied during code review in addition to the guidelines below.

## Related Guides

- [CompletableFuture Deep Dive](./completable-future.md) - Comprehensive async programming guide
- [Database Patterns Guide](./database-patterns.md) - Database design patterns and best practices

## 1. Service Layer Patterns

- Service layer should parse and validate requests only
- Handle mapping internal exceptions to appropriate client errors
- Delegate business logic to dedicated action classes
- Use dependency injection for clean separation of concerns

### gRPC Context Propagation

- **Always explicitly propagate gRPC context** - pass `io.grpc.Context` from service Impl to all downstream calls
- **Never use `Context.current()`** except in tests - implicit context propagation causes bugs and incidents
- **Use Contextual Protoc Plugin** - generated clients require explicit `Context` parameter for safer context handling

```java
// Good: Service focuses on validation and orchestration
public CompletionStage<GetProviderNotifiedResponse> getProviderNotified(
    Context context, GetProviderNotifiedRequest request) {

  // 1. Validate request
  isRequestValid(LOG, "getProviderNotified", request, context,
                 requestValidator::validateRequest);

  // 2. Delegate to data layer
  return databaseStore.getProviderNotifiedTimestamp(request.getTracingId())
      .thenApply(timestamp -> buildResponse(timestamp))
      .exceptionally(e -> {
        LOG.error("Error fetching provider notification", e);
        throw GrpcStatusMapperUtil.statusFromException(e);
      });
}
```

## 2. Code Organization

### Package & Directory Structure

- Name directories by what they do, not what feature they belong to
- Use clear, descriptive names that indicate purpose

```
Good Structure:
├── action/            # Business logic operations
├── client/            # External service clients
├── mapper/            # Data transformation logic
├── storage/           # Data persistence layer
├── utils/             # Shared utility functions
├── service/           # API service implementations
├── entity/            # Domain objects
└── exception/         # Custom exception types

Avoid Feature-Based:
├── orders/
├── payments/
├── user-management/
```

- Group related functionality in focused packages
- Use singular nouns for package names
- Keep package depth reasonable (3-4 levels max)

### Class Organization

- Use business logic classes for complex operations
- Keep each class focused on single responsibilities
- Use intention-revealing names:
  - `*Manager`: Coordination, orchestration, lifecycle management
  - `*Processor`: Data transformation, computation, sequential processing
  - `*Handler`: Event processing, request handling, reactive patterns
- Services orchestrate, business logic classes execute operations
- Use dedicated configuration classes
- Externalize configurable values

## 3. Utilities and Helper Classes

- Always use dedicated utils files for shared functionality
- Keep utilities as static classes with no dependencies
- Use clear, descriptive naming
- Never include constructors in utility classes that are never meant to be instantiated

```java
// Examples: ServiceUtils.java, GrpcStatusMapperUtil.java, ProtoUtils.java
public class ServiceUtils {
  public static <TRequest> void isRequestValid(
      Logger logger, String grpcMethodName, TRequest request,
      Context context, Function<TRequest, BinderResult<TRequest>> validator) {
    // Validation logic
  }
}
```

## 4. Proto File Management

- Only import what you actually use in proto files
- Remove unused imports during code review
- Group imports logically (Google, internal dependencies, local)
- Keep related message types in the same file
- Version your APIs appropriately (v1, v2, v3)
- see if any issues here can be handled via deterministic linter rules

```protobuf
syntax = "proto3";
package com.example.myservice.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/wrappers.proto";
import "com/example/common/identifiers.proto";
```

## 5. Dependency Injection Patterns

- Match the DI approach already used in your repository
- Some repos use Dagger with modules and `@Provides` methods
- Others use manual DI with registry classes or factory patterns
- Default to manual DI

## 6. Mapper and Transformation Patterns

- Create specific mappers for different transformation needs
- Keep mapping logic separate from business logic
- Use descriptive names that indicate source and target
- Use `Optional.ofNullable()` for potentially null fields.
- See about deterministic linter rules if there is an issue with null handling.
- Never use `.get()` - prefer `.orElse()`, `.orElseThrow()`, `.ifPresent()`

```java
public class ShowEpisodeTrackEntityMapper {
  public static List<Episode> buildEpisodes(List<ShowEpisodeTrackEntity> entities) {
    return entities.stream()
        .map(ShowEpisodeTrackEntityMapper::buildEpisode)
        .collect(Collectors.toList());
  }
}
```

## 7. Error Handling and Logging

- Prefer `CompletionResult` and `Result.error(Status)` for graceful error handling
- Use appropriate gRPC status codes: `NOT_FOUND`, `PERMISSION_DENIED`, `INVALID_ARGUMENT`, `INTERNAL`
- Use `exceptionally()` for simple fallbacks, `handle()` for complex recovery
- Always unwrap exceptions in async chains
- Never log secrets or sensitive data
- Prefer structured logging with `StructuredArguments.entries()`

```java
// Preferred: Result-based error handling
return CompletionResult.fromCompletionStage(
  CompletableFuture.completedFuture(Result.error(Status.NOT_FOUND))
);

// Exception handling
.exceptionally(throwable -> {
  Throwable cause = throwable.getCause();
  LOG.error("Operation failed for id {}", requestId, cause);
  return Result.error(statusFromException(cause).getStatus());
})
```

### Logging Patterns

- Use appropriate log levels and include relevant context
- Never log secrets or sensitive data
- Prefer structured logging with `StructuredArguments.entries()` for searchability

```java
LOG.info("Processing request for id {}", requestId);
Map<String, String> context = Map.of("correlationId", correlationId, "userId", userId);
LOG.info("Processing request: {}", StructuredArguments.entries(context));
```

### gRPC Error Handling Patterns

- **Use top-level exception handler** - centralize exception mapping in service Impl with single `.exceptionally()` call
- **Unwrap exception wrappers** - always unwrap `CompletionException` and `ExecutionException` to get real cause
- **Map to appropriate gRPC status** - use `RpcHandlerException` for custom exceptions with proper status codes
- **Handle client errors appropriately** - map HTTP status codes to gRPC status for Apollo/HTTP clients
- **Throw exceptions close to source** - create exceptions where errors are detected, not higher up the call stack
- **Let exceptions bubble up** - avoid catching and re-throwing unless you need to add context or change error type

_Reference: [Spotify gRPC Documentation](https://backstage.spotify.net/docs/default/component/grpc/) | Local: [gRPC Golden Path](/Users/ccasey/Documents/houston/spotify-wide/talk-mission-docs/docs/golden_path/Backend_Golden_Path_for_Podcast_Mission/Spotify_Backends/Developing_Your_Backend_Service/2_grpc.md)_

### Custom Exception Types

- Create specific exception types for reusable error conditions
- Balance specificity with reusability
- Place reusable exception types in dedicated `exception` package


## 8. Testing Patterns

### Test Dependency Strategy

Follow the **Real > Fake > Mock** principle when injecting dependencies:

- **Prefer Real**: Use actual objects when practical (e.g., simple domain objects)
- **Then Fakes**: Create simple implementations for interfaces with large APIs
- **Finally Mocks**: Use for complex behaviors or when state management is needed

_Reference: [Spotify Backend Testing Guidelines](https://backstage.spotify.net/docs/default/component/backend/coding/testing/) | Local: [Testing Guidelines](/Users/ccasey/Documents/houston/spotify-wide/backend-docs/docs/coding/testing/index.md) | [Talk Mission Testing Best Practices](/Users/ccasey/Documents/houston/spotify-wide/talk-mission-docs/docs/backend/Backend Testing Best Practices.md)_

### Test Organization

- Mirror main package structure in test directories
- Use consistent naming: `mockClient`, `stubStore`, `fakeValidator`
- For async code, use `CompletableFuture.completedFuture()` for test values
- Test both success and failure paths
- Use `@ParameterizedTest` and `@ValueSource` for multiple inputs

### Test Libraries & Tools

- **JUnit5** as primary testing framework
- **AssertJ** for fluent assertions (preferred over Hamcrest)
- **Mockito** for mocking when needed
- **junit5-extensions** for Spotify-specific helpers and containers
- **apollo-test** with `ApolloContainer` for Docker containers
- Alternative: `InProcessServer` for same-process testing

### Data Builders

Use data builder patterns to reduce test setup duplication:

- Static response builders for simple cases
- Helper methods/factories for common objects
- MakeItEasy or Proto-test-builder for complex scenarios

_Reference: [Testing Data Builders](https://backstage.spotify.net/docs/default/component/backend/coding/testing/#data-builder) | Local: [Testing Guidelines](/Users/ccasey/Documents/houston/spotify-wide/backend-docs/docs/coding/testing/index.md)_

## 9. Modern Java Standards

Follow modern Java standards: streams/Optional over loops/nulls, immutability (final/records), functional patterns (Modern Java in Action - Manning), builder patterns (Effective Java).

## 10. Library Standards

**Serialization**: Jackson (com.fasterxml.jackson.*) - standard across Spotify
**Value Types**: Records + @AutoMatter (Java ≥14) or AutoMatter (Java <14)
**HTTP Clients**: apollo-async-http-client - integrates with CompletionStage async model

_Reference: [Spotify Library Standards](https://backstage.spotify.net/docs/default/component/backend/coding/libraries/) | Local: [Libraries](/Users/ccasey/Documents/houston/spotify-wide/backend-docs/docs/coding/libraries/index.md)_

## 11. Code Review Checklist

### Service Layer Review

- [ ] Services focus on orchestration, not business logic
- [ ] Request validation is present and consistent
- [ ] Exception mapping follows established patterns
- [ ] No blocking calls in async chains
- [ ] io.grpc.Context is explicitly passed and correctly handled
- [ ] gRPC service methods return CompletionStage or CompletionResult
- [ ] Business logic delegated to dedicated classes (Manager/Processor/Handler)

### Code Organization Review

- [ ] Directory structure follows function-over-feature principle
- [ ] Utility classes are stateless and focused
- [ ] Dependencies are properly injected, not instantiated
- [ ] Proto imports are minimal and necessary
- [ ] Code adheres to Google Java Style Guide

### Async Code Review

- [ ] Review against [CompletableFuture Deep Dive Guide](/Users/ccasey/dotfiles/ai/guides/java/completable-future.md)

### gRPC Review

- [ ] Context propagation is explicit - no use of `Context.current()` except in tests
- [ ] Top-level exception handler centralizes error mapping with single `.exceptionally()` call
- [ ] Exception unwrapping handles `CompletionException` and `ExecutionException`
- [ ] Appropriate gRPC status codes used (`NOT_FOUND`, `INVALID_ARGUMENT`, `INTERNAL`, etc.)
- [ ] Client error handling maps HTTP status codes to gRPC status correctly
- [ ] `RpcHandlerException` used for custom exceptions instead of `StatusRuntimeException`
- [ ] Exceptions thrown close to error source, not higher up call stack

### Testing Review

- [ ] Tests mirror production code structure
- [ ] Mocks used appropriately (external deps only)
- [ ] Async test scenarios cover success and failure
- [ ] Test setup is minimal and focused
- [ ] Integration tests use ApolloContainer or InProcessServer
- [ ] JUnit5 used with appropriate assertions

### Modern Java Standards Review

- [ ] Follows modern Java standards and patterns

### Database Changes Review

- [ ] If database changes included, review against [Database Patterns Guide](./database-patterns.md)

### Library Standards Review

- [ ] Jackson used for serialization
- [ ] Records + @AutoMatter for value types (Java ≥14)
- [ ] apollo-async-http-client used for HTTP clients
- [ ] AssertJ used for test assertions (not Hamcrest)
- [ ] junit5-extensions used for Spotify-specific test helpers

### Performance & Security Review

- [ ] No secrets logged or exposed in error messages
- [ ] Resource cleanup handled properly
- [ ] Thread pools sized appropriately
- [ ] Database queries are efficient and indexed
