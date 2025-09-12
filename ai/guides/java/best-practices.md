# Java Best Practices Guide

## Table of Contents

1. [Service Layer Patterns](#1-service-layer-patterns)
2. [Directory Structure & Naming](#2-directory-structure--naming)
3. [Utilities and Helper Classes](#3-utilities-and-helper-classes)
4. [Proto File Management](#4-proto-file-management)
5. [Dependency Injection Patterns](#5-dependency-injection-patterns)
6. [Mapper and Transformation Patterns](#6-mapper-and-transformation-patterns)
7. [Error Handling and Logging](#7-error-handling-and-logging)
8. [Code Organization](#8-code-organization)
9. [Testing Patterns](#9-testing-patterns)
10. [Code Review Checklist](#10-code-review-checklist)

## Code Review Instructions

**For AI Code Reviewers**: When reviewing Java code, you must also read and analyze against the detailed async programming patterns in:

- `/Users/ccasey/dotfiles/ai/guides/java/completable-future.md`

This guide contains comprehensive CompletableFuture patterns, anti-patterns, and best practices that should be applied during code review in addition to the guidelines below.

## Related Guides

- [CompletableFuture Deep Dive](./completable-future.md) - Comprehensive async programming guide

## 1. Service Layer Patterns

- Service layer should parse and validate requests only
- Handle mapping internal exceptions to appropriate client errors
- Delegate business logic to dedicated action classes
- Use dependency injection for clean separation of concerns

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

## 2. Directory Structure & Naming

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

## 3. Utilities and Helper Classes

- Always use dedicated utils files for shared functionality
- Keep utilities as static classes with no dependencies
- Use clear, descriptive naming

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
- Use `Optional.ofNullable()` for potentially null fields
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

### Custom Exception Types

- Create specific exception types for reusable error conditions
- Balance specificity with reusability
- Place in dedicated `exception` package

## 8. Code Organization

- Use business logic classes for complex operations
- Keep each class focused on single responsibilities
- Use intention-revealing names:
  - `*Manager`: Coordination, orchestration, lifecycle management
  - `*Processor`: Data transformation, computation, sequential processing
  - `*Handler`: Event processing, request handling, reactive patterns
- Services orchestrate, business logic classes execute operations
- Use dedicated configuration classes
- Externalize configurable values

## 9. Testing Patterns

- Mirror main package structure in test directories
- Mock external dependencies, not internal domain logic
- Use consistent naming: `mockClient`, `stubStore`, `fakeValidator`
- For async code, use `CompletableFuture.completedFuture()` for test values
- Test both success and failure paths
- Use `@ParameterizedTest` and `@ValueSource` for multiple inputs
- Use JUnit5 as primary testing framework
- Prefer AssertJ's fluent API over JUnit assertions
- Use Mockito as standard mocking framework

- Use `apollo-test` with `ApolloContainer` for Docker containers
- Alternative: `InProcessServer` for same-process testing

## 10. Code Review Checklist

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

### Testing Review

- [ ] Tests mirror production code structure
- [ ] Mocks used appropriately (external deps only)
- [ ] Async test scenarios cover success and failure
- [ ] Test setup is minimal and focused
- [ ] Integration tests use ApolloContainer or InProcessServer
- [ ] JUnit5 used with appropriate assertions

### Performance & Security Review

- [ ] No secrets logged or exposed in error messages
- [ ] Resource cleanup handled properly
- [ ] Thread pools sized appropriately
- [ ] Database queries are efficient and indexed
