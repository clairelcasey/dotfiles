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
9. [CompletableFuture and Asynchronous Programming](#9-completablefuture-and-asynchronous-programming)
10. [Testing Patterns](#10-testing-patterns)
11. [Code Review Checklist](#11-code-review-checklist)

## Related Guides
- [CompletableFuture Deep Dive](./completable-future.md) - Comprehensive async programming guide

## 1. Service Layer Patterns

### Keep Services Focused on Orchestration

- **Service layer should parse and validate requests only**
- **Handle mapping internal exceptions to appropriate client errors**
- Delegate business logic to dedicated action/handler classes
- Use dependency injection for clean separation of concerns

```java
// Good: Service focuses on validation and orchestration
public CompletionStage<GetProviderNotifiedResponse> getProviderNotified(
    Context context, GetProviderNotifiedRequest request) {

  // 1. Validate request
  isRequestValid(LOG, "getProviderNotified", request, context,
                 remediationApiProtoRequestBinder::validateGetProviderNotified);

  // 2. Delegate to data layer
  return databaseStore.getProviderNotifiedTimestamp(request.getTracingId())
      .thenApply(timestamp -> buildResponse(timestamp))
      .exceptionally(e -> {
        LOG.error("Error fetching provider notification", e);
        throw GrpcStatusMapperUtil.statusFromException(e);
      });
}
```

### Exception Mapping Pattern

- Create dedicated utility for mapping internal exceptions to gRPC status codes
- Always unwrap CompletionException to get the root cause
- Use consistent error messages and logging

```java
// GrpcStatusMapperUtil.java
public static StatusRuntimeException statusFromException(Throwable ex) {
  Throwable cause = ex.getCause();
  if (cause instanceof EntityNotFoundException) {
    return Status.NOT_FOUND.withDescription("entity not found").asRuntimeException();
  } else if (cause instanceof UserForbiddenException) {
    return Status.PERMISSION_DENIED.withDescription("user forbidden").asRuntimeException();
  }
  return Status.INTERNAL.withCause(ex).withDescription(ex.getMessage()).asRuntimeException();
}
```

## 2. Directory Structure & Naming

### Function-Specific Over Feature-Specific Naming

- Name directories by **what they do**, not **what feature they belong to**
- Use clear, descriptive names that indicate purpose

```
✅ Good Structure:
├── actions/           # Business logic handlers
├── clients/           # External service clients
├── mapper/            # Data transformation logic
├── storage/           # Data persistence layer
├── utils/             # Shared utility functions
├── services/          # API service implementations
├── entities/          # Domain objects
└── Exceptions/        # Custom exception types

❌ Avoid Feature-Based:
├── pcd/
├── remediation/
├── episode-management/
```

### Consistent Package Organization

- Group related functionality in focused packages
- Use singular nouns for package names where possible
- Keep package depth reasonable (3-4 levels max)

## 3. Utilities and Helper Classes

### Create Focused Utility Classes

- **Always use dedicated utils files for shared functionality**
- Keep utilities stateless and focused on single responsibilities
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
- Group imports logically (Google, Spotify internal, local)

```protobuf
// Good: Only necessary imports
syntax = "proto3";
package spotify.pcdremediationsystem.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/wrappers.proto";
import "spotify/podcasters/identifiers/identifiers.proto";

// Bad: Unused imports
import "google/protobuf/any.proto";      // ❌ Not used
import "google/protobuf/duration.proto"; // ❌ Not used
```

### Proto Organization

- Keep related message types in the same file
- Use clear, descriptive message and field names
- Version your APIs appropriately (v1, v2, v3)

## 5. Dependency Injection Patterns

### Module Organization

- Create focused DI modules by functional area
- Use descriptive module names that indicate their purpose

```java
// Examples from codebase:
ConfigurationModule.java    // App configuration
ClientsModule.java         // External service clients
StorageModule.java         // Database and persistence
ValidationModule.java     // Input validation
PubsubModule.java         // Messaging infrastructure
```

### Provider Methods

- Use clear naming for provider methods
- Keep providers focused and testable

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

## 7. Error Handling and Logging

### Consistent Logging Patterns

- Use appropriate log levels (DEBUG, INFO, WARN, ERROR)
- Include relevant context in log messages
- Log errors before throwing exceptions

```java
// Good logging pattern
LOG.info("Received setProviderNotified request for case-id {}", request.getTracingId());

// Log errors with context
LOG.error("Error occurred fetching provider notification for tracing id {}",
          request.getTracingId(), throwable);
```

### Custom Exception Types

- Create specific exception types for different error conditions
- Keep exceptions focused and descriptive
- Place in dedicated `Exceptions` package

## 8. Code Organization

### Action/Handler Pattern

- Use action classes for complex business logic
- Keep actions focused on single responsibilities
- Name actions clearly: `*Handler`, `*Actions`, `*Calculator`

### Constants and Configuration

- Use dedicated configuration classes
- Externalize configurable values
- Use meaningful names for configuration properties

### Testing Support

- Create test utilities in dedicated packages
- Use descriptive test helper methods
- Keep test setup minimal and focused

## 9. CompletableFuture and Asynchronous Programming

> **See also:** [CompletableFuture Deep Dive Guide](./completable-future.md) for comprehensive examples and patterns

### Non-Blocking Composition is Key

- **Never use `.get()` or `.join()`** in application logic - they block threads
- Use `thenCompose()` for dependent operations to avoid nested futures
- Use `thenCombine()` for independent operations that need both results

```java
// ✅ Good: Non-blocking composition from your codebase
public CompletionStage<GetProviderNotifiedResponse> getProviderNotified(
    Context context, GetProviderNotifiedRequest request) {
  
  return databaseStore.getProviderNotifiedTimestamp(request.getTracingId())
      .thenApply(timestamp -> buildResponse(timestamp))
      .exceptionally(e -> {
        LOG.error("Error fetching provider notification", e);
        throw GrpcStatusMapperUtil.statusFromException(e);
      });
}

// ✅ Good: Chaining dependent operations
return getUserById(id)
    .thenCompose(user -> getPermissionsFor(user))
    .thenApply(permissions -> buildAuthResponse(permissions));
```

### Exception Handling in Async Chains

- **Always unwrap `CompletionException`** to get the original cause
- Use `exceptionally()` for simple fallbacks, `handle()` for complex recovery
- Integrate with your existing error mapping utilities

```java
// ✅ Good: Proper exception unwrapping and mapping
.exceptionally(throwable -> {
  Throwable cause = throwable.getCause();
  LOG.error("Operation failed for tracing id {}", 
            request.getTracingId(), cause);
  throw GrpcStatusMapperUtil.statusFromException(cause);
})
```

### Threading Best Practices

- **Use dedicated executors** for blocking operations in async callbacks
- Avoid blocking I/O in `thenApply` - use `thenApplyAsync` with custom executor
- Prefer `CompletionStage<T>` over `CompletableFuture<T>` in public APIs

```java
// ✅ Good: Custom executor for potentially blocking operations
private final Executor databaseExecutor = 
    Executors.newFixedThreadPool(10, namedThreadFactory("db-async"));

return future.thenApplyAsync(this::processDbResult, databaseExecutor);
```

## 10. Testing Patterns

### Test Structure Organization

- **Mirror your main package structure** in test directories
- Use dedicated test utility packages for shared helpers
- Keep test data builders focused and reusable

```java
// ✅ Good: Focused test builders
public class ProviderNotificationTestBuilder {
  public static GetProviderNotifiedRequest.Builder defaultRequest() {
    return GetProviderNotifiedRequest.newBuilder()
        .setTracingId("test-trace-123");
  }
}
```

### Mock and Stub Patterns

- **Mock external dependencies**, not internal domain logic
- Use consistent naming: `mockClient`, `stubStore`, `fakeValidator`
- Verify interactions that matter, not implementation details

### Async Testing

- **Use `CompletableFuture.completedFuture()`** for immediate test values
- Test both success and failure paths in async chains
- Verify proper exception handling and unwrapping

```java
// ✅ Good: Testing async error handling
when(mockStore.getProviderNotifiedTimestamp(any()))
    .thenReturn(CompletableFuture.failedFuture(new EntityNotFoundException()));

// Verify the exception is properly mapped
assertThat(result.isCompletedExceptionally()).isTrue();
```

## 11. Code Review Checklist

### Service Layer Review
- [ ] Services focus on orchestration, not business logic
- [ ] Request validation is present and consistent
- [ ] Exception mapping follows established patterns
- [ ] No blocking calls in async chains

### Code Organization Review
- [ ] Directory structure follows function-over-feature principle
- [ ] Utility classes are stateless and focused
- [ ] Dependencies are properly injected, not instantiated
- [ ] Proto imports are minimal and necessary

### Async Code Review
- [ ] No `.get()` or `.join()` calls in application logic
- [ ] `CompletionException` is properly unwrapped
- [ ] Custom executors used for blocking operations
- [ ] Error handling covers all failure scenarios

### Testing Review
- [ ] Tests mirror production code structure
- [ ] Mocks are used appropriately (external deps only)
- [ ] Async test scenarios cover both success and failure
- [ ] Test setup is minimal and focused

### Performance & Security Review
- [ ] No secrets logged or exposed in error messages
- [ ] Resource cleanup is handled properly
- [ ] Thread pools are sized appropriately
- [ ] Database queries are efficient and indexed

---

_This guide reflects patterns observed in well-structured Java microservices at Spotify and should be adapted to your specific project needs._
