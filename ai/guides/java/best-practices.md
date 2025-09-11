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

### Keep Services Focused on Orchestration

- **Service layer should parse and validate requests only**
- **Handle mapping internal exceptions to appropriate client errors**
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

### Function-Specific Over Feature-Specific Naming

- Name directories by **what they do**, not **what feature they belong to**
- Use clear, descriptive names that indicate purpose

```
✅ Good Structure:
├── action/            # Business logic operations
├── client/            # External service clients
├── mapper/            # Data transformation logic
├── storage/           # Data persistence layer
├── utils/             # Shared utility functions
├── service/           # API service implementations
├── entity/            # Domain objects
└── exception/         # Custom exception types

❌ Avoid Feature-Based:
├── orders/
├── payments/
├── user-management/
```

### Consistent Package Organization

- Group related functionality in focused packages
- Use singular nouns for package names where possible
- Keep package depth reasonable (3-4 levels max from base application package, e.g., from `com/spotify/servicename/`)

## 3. Utilities and Helper Classes

### Create Focused Utility Classes

- **Always use dedicated utils files for shared functionality**
- Keep utilities as static classes with no dependencies and focused on single responsibilities
- Use clear, descriptive naming

```java
// Examples of well-organized utils:
ServiceUtils.java        // Request validation helpers
GrpcStatusMapperUtil.java // Exception to gRPC status mapping
ProtoUtils.java          // Protobuf serialization/deserialization
TimestampUtil.java       // Date/time conversion utilities
EntityMetadataUtil.java  // Domain-specific metadata helpers
```

### Utility Method Patterns

```java
// Good: Static, focused utility methods
public class ServiceUtils {
  public static <TRequest> void isRequestValid(
      Logger logger, String grpcMethodName, TRequest request,
      Context context, Function<TRequest, BinderResult<TRequest>> validator) {
    // Validation logic
  }
}

// Good: Proto conversion utilities
public class ProtoUtils {
  public static String toJson(Message message) { /* ... */ }
  public static <T extends Message> T fromJson(String json, Class<T> clazz) { /* ... */ }
}
```

## 4. Proto File Management

### Import Hygiene

- **Only import what you actually use in proto files**
- Remove unused imports during code review
- Group imports logically (Google, internal dependencies, local)

```protobuf
// Good: Only necessary imports
syntax = "proto3";
package com.example.myservice.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/wrappers.proto";
import "com/example/common/identifiers.proto";

// Bad: Unused imports
import "google/protobuf/any.proto";      // ❌ Not used
import "google/protobuf/duration.proto"; // ❌ Not used
```

### Proto Organization

- Keep related message types in the same file
- Use clear, descriptive message and field names
- Version your APIs appropriately (v1, v2, v3)

## 5. Dependency Injection Patterns

### Follow Existing Repository Structure

- **Match the DI approach already used in your repository**
- Some repos use Dagger with modules and `@Provides` methods
- Others use manual DI with registry classes or factory patterns
- Examine existing DI classes to understand the established pattern
- default to manual DI

## 6. Mapper and Transformation Patterns

### Dedicated Mapper Classes

- Create specific mappers for different transformation needs
- Keep mapping logic separate from business logic
- Use descriptive names that indicate source and target

```java
// Good mapper naming:
ShowEpisodeTrackEntityMapper.java
EmailEpisodeEntityMapper.java
EpisodeInfoEntityMapper.java
```

### Mapper Method Patterns

```java
// Static methods for stateless transformations
public class ShowEpisodeTrackEntityMapper {
  public static List<Episode> buildEpisodes(List<ShowEpisodeTrackEntity> entities) {
    return entities.stream()
        .map(ShowEpisodeTrackEntityMapper::buildEpisode)
        .collect(Collectors.toList());
  }
}
```

### Handling Nulls with Optional

- Use `Optional.ofNullable()` for potentially null fields during mapping
- Apply `.map()`, `.flatMap()`, `.filter()`, `.orElse()`, and `.orElseGet()` for safe transformations
- Use `.orElseThrow()` when absence indicates an error condition
- **Never use `.get()`** - it's an anti-pattern that throws exceptions
- Prefer `.ifPresent()` over `.isPresent()` + `.get()` pattern
- Prevents NullPointerExceptions in mapper logic

## 7. Error Handling and Logging

### Exception Mapping Patterns

- **Prefer `CompletionResult` and `Result.error(Status)`** for graceful error handling
- The underlying contract: wrapping `CompletionStage` is never in exception state

```java
// Preferred: Result-based error handling
return CompletionResult.fromCompletionStage(
  CompletableFuture.completedFuture(Result.error(Status.NOT_FOUND))
);

// Traditional exception mapping (when needed)
public static StatusRuntimeException statusFromException(Throwable ex) {
  Throwable cause = ex.getCause();
  if (cause instanceof EntityNotFoundException) {
    return Status.NOT_FOUND.withDescription("entity not found").asRuntimeException();
  }
  return Status.INTERNAL.withCause(ex).withDescription(ex.getMessage()).asRuntimeException();
}
```

### gRPC Status Codes

- Use appropriate gRPC status codes to convey error nature to clients
- Common patterns: `NOT_FOUND`, `PERMISSION_DENIED`, `INVALID_ARGUMENT`, `INTERNAL`

### Async Exception Handling

- Use `exceptionally()` for simple fallbacks, `handle()` for complex recovery
- Always unwrap exceptions in async chains
- Prefer returning `Result.error()` over throwing in async contexts

```java
.exceptionally(throwable -> {
  Throwable cause = throwable.getCause();
  LOG.error("Operation failed for id {}", requestId, cause);
  return Result.error(statusFromException(cause).getStatus());
})
```

### Consistent Logging Patterns

- Use appropriate log levels and include relevant context
- Log errors before throwing exceptions
- Never log secrets or sensitive data
- Have a preference for using structured logging with `StructuredArguments.entries()` for better searchability and tracing (see `/Users/ccasey/Documents/houston/services-pilot/java/structured-logging` for full docs)

```java
  LOG.info("Processing request for id {}", requestId);
  LOG.error("Operation failed for id {}", requestId, throwable);

  // Structured logging example
  Map<String, String> context = Map.of("correlationId", correlationId, "userId", userId);
  LOG.info("Processing request: {}", StructuredArguments.entries(context));
```

### Custom Exception Types

- Create specific exception types for different error conditions where it can be reused
- Balance specificity with reusability - avoid creating exceptions for every tiny distinction
- Place in dedicated `exception` package

## 8. Code Organization

### Business Logic Patterns

- Use business logic classes for complex operations
- Keep each class focused on single responsibilities
- Use intention-revealing names for business logic classes:
  - `*Manager`: For coordination, orchestration, and lifecycle management
  - `*Processor`: For data transformation, computation, and sequential processing
  - `*Handler`: For event processing, request handling, and reactive patterns
- Distinguish from service layer: Services orchestrate, business logic classes execute operations

### Constants and Configuration

- Use dedicated configuration classes
- Externalize configurable values
- Use meaningful names for configuration properties

### Testing Support

- Create test utilities in dedicated packages
- Use descriptive test helper methods
- Keep test setup minimal and focused


## 9. Testing Patterns

### Test Organization

- Mirror your main package structure in test directories
- Use dedicated test utility packages for shared helpers
- Keep test data builders focused and reusable

### Testing Guidelines

- **Mock external dependencies**, not internal domain logic
- Use consistent naming: `mockClient`, `stubStore`, `fakeValidator`
- For async code, use `CompletableFuture.completedFuture()` for immediate test values
- Test both success and failure paths
- use `@ParameterizedTest` and `@ValueSource` for running the same test with different inputs

### Frameworks & Assertions

- Use **JUnit5** as the primary testing framework
- Prefer JUnit assertions: `Assertions.assertEquals`, `Assertions.assertTrue`, `Assertions.assertThrows`
- Hamcrest matchers (`assertThat`) provide better error messages and type safety but are no longer recommended by the Backend Advisory Board (BAB)
- Mockito as the standard mocking framework

### Integration Testing

- Test modules working together, not isolated units
- Use `apollo-test` dependency with `ApolloContainer` for Docker containers
- Start containers with `@BeforeAll`, create gRPC channels and clients
- Alternative: `InProcessServer` for same-process testing without network overhead
- Replace dependencies with mock implementations or use production-like environments

## 10. Code Review Checklist

### Service Layer Review

- [ ] Services focus on orchestration, not business logic
- [ ] Request validation is present and consistent
- [ ] Exception mapping follows established patterns
- [ ] No blocking calls in async chains
- [ ] io.grpc.Context is explicitly passed and correctly handled in service methods
- [ ] gRPC service methods return CompletionStage or CompletionResult for asynchronous operations
- [ ] Business logic is delegated to dedicated classes (Manager/Processor/Handler), not implemented in services

### Code Organization Review

- [ ] Directory structure follows function-over-feature principle
- [ ] Utility classes are stateless and focused
- [ ] Dependencies are properly injected, not instantiated
- [ ] Proto imports are minimal and necessary
- [ ] Code adheres to Google Java Style Guide for formatting and naming conventions (e.g., UpperCamelCase for classes, lowerCamelCase for methods)

### Async Code Review

- [ ] Review against comprehensive async patterns in [CompletableFuture Deep Dive Guide](/Users/ccasey/dotfiles/ai/guides/java/completable-future.md)

### Testing Review

- [ ] Tests mirror production code structure
- [ ] Mocks are used appropriately (external deps only)
- [ ] Async test scenarios cover both success and failure
- [ ] Test setup is minimal and focused
- [ ] Integration tests correctly set up ApolloContainer or InProcessServer for gRPC services and their dependencies
- [ ] JUnit5 is used for testing, with appropriate assertions (assertEquals, assertThrows)

### Performance & Security Review

- [ ] No secrets logged or exposed in error messages
- [ ] Resource cleanup is handled properly
- [ ] Thread pools are sized appropriately
- [ ] Database queries are efficient and indexed
