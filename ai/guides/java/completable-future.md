---
ruleType: AgentRequested
description: "A complete and comprehensive guide with best practices for using Java's CompletableFuture."
---

When working with `CompletableFuture` in Java, the primary goal is to write non-blocking, declarative, and readable asynchronous code. This guide covers the core principles, from composition and error handling to API design and threading.

### 1. The Core Principle: Non-Blocking Composition

The most important rule is to **avoid blocking calls**. Instead of blocking, you should compose a pipeline of actions to be executed when results become available.

#### Do Not Use `.get()` or `.join()`

Never use these methods in your main application logic. They block the current thread, which can lead to performance bottlenecks and deadlocks.

- **Bad Practice:**

  ```java
  // BLOCKS the current thread, very bad!
  String result = myFuture.get();
  System.out.println(result);
  ```

- **Good Practice (Asynchronous Composition):**
  ```java
  // Composes an action to run when the future completes. Non-blocking.
  myFuture.thenAccept(result -> {
      System.out.println(result);
  });
  ```

#### Chain Dependent Operations with `thenCompose`

When an operation depends on the result of a previous one, use `thenCompose()` to keep the pipeline flat and readable.

- **Good Practice:**
  ```java
  // Creates a clean CompletableFuture<String> instead of a nested one.
  CompletableFuture<String> result = getUser().thenCompose(user -> getAddressFor(user));
  ```

#### Combine Independent Operations with `thenCombine`

When you have two independent futures and need both results to proceed, use `thenCombine()`.

- **Good Practice:**

  ```java
  CompletableFuture<User> userFuture = fetchUser();
  CompletableFuture<Permissions> permissionsFuture = fetchPermissions();

  CompletableFuture<String> combined = userFuture.thenCombine(
      permissionsFuture,
      (user, permissions) -> "User: " + user.getName() + " has " + permissions.getLevel()
  );
  ```

### 2. Handling Multiple Futures

#### Use `allOf()` to Wait for All Futures

To perform an action only after a collection of futures have _all_ completed, use `CompletableFuture.allOf()`.

- **Good Practice:**

  ```java
  List<CompletableFuture<String>> futures = List.of(future1, future2, future3);

  CompletableFuture<Void> allDone = CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]));

  allDone.thenRun(() -> System.out.println("All futures are complete!"));
  ```

#### Use `anyOf()` to Wait for the First Future

To perform an action as soon as _any one_ of a collection of futures completes, use `CompletableFuture.anyOf()`.

- **Good Practice:**

  ```java
  CompletableFuture<String> source1 = fetchFromSource1();
  CompletableFuture<String> source2 = fetchFromSource2();

  CompletableFuture<Object> firstResult = CompletableFuture.anyOf(source1, source2);

  firstResult.thenAccept(result -> System.out.println("First result received: " + result));
  ```

### 3. Robust Error Handling

#### Use `exceptionally()` for Simple Recovery

Use `.exceptionally()` to provide a fallback value or action when an exception occurs. It's the asynchronous equivalent of a `catch` block.

#### Use `handle()` for Complex Recovery and Transformation

For more advanced scenarios, use `handle()`. It is **always called**, regardless of success or failure, allowing you to process both the result and the exception.

- **Good Practice (`handle()`):**
  ```java
  fetchData().handle((result, ex) -> {
      if (ex != null) {
          log.error("An error occurred: {}", ex.getCause().getMessage());
          return "Default Fallback Value"; // Recover from failure
      }
      return "Transformed: " + result; // Transform successful result
  });
  ```

#### Unwrap `CompletionException`

Exceptions thrown inside a stage are **wrapped in a `CompletionException`**. To get the original exception, you must call `.getCause()` on it.

- **Good Practice (Unwrapping):**
  ```java
  .exceptionally(ex -> {
      // 'ex' is a CompletionException, unwrap it to get the real cause.
      Throwable originalException = ex.getCause();
      log.error("Failed due to: {}", originalException.getMessage());
      return "Default Value";
  })
  ```
- **Note for Spotify Users:** The utility `com.spotify.zuul.exceptions.Exceptions.unwrapException(ex)` can handle this logic for you.

### 4. Threading and Resource Management

#### Pitfall: Don't Block Inside a Callback

A critical anti-pattern is performing blocking I/O (database calls, network requests) or other long-running tasks inside a non-async callback like `thenApply`. This can starve the underlying thread pool (often the common `ForkJoinPool`) and cripple the entire application.

#### Solution: Specify an Executor for `*Async` Methods

Always provide a dedicated `Executor` to `*Async` methods for any non-trivial task. This isolates the task's execution from other asynchronous processes.

- **Good Practice:**
  ```java
  Executor myExecutor = Executors.newFixedThreadPool(4);
  future.thenApplyAsync(this::someLongRunningTask, myExecutor);
  ```

### 5. Safe API Design

#### Pitfall: Don't Complete a Future You Did Not Create

You should only call `.complete()` or `.completeExceptionally()` on a future that your code created. Completing a future received from another system breaks its owner's contract and leads to unpredictable behavior.

#### Solution: Use `CompletionStage` for API Method Parameters

In your public APIs, prefer accepting `CompletionStage<T>` over `CompletableFuture<T>`. This provides the caller with all the non-blocking composition methods while preventing them from completing a future they don't own.

- **Good Practice:**
  ```java
  // This API is safe; the implementation can trust the stage won't be completed externally.
  public void processData(CompletionStage<Data> dataStage) { /* ... */ }
  ```

### 6. Creating Futures from Scratch

To wrap a legacy API that uses callbacks or runs on a different thread, you can create a `CompletableFuture` manually. The creator of the future is responsible for completing it.

- **Good Practice (Wrapping a callback API):**

  ```java
  public CompletableFuture<String> askQuestionAsync(String question) {
      // 1. Create the future that you will return to your client.
      CompletableFuture<String> future = new CompletableFuture<>();

      // 2. Start the async operation and provide a callback.
      legacyApi.ask(question, new Callback() {
          @Override
          public void onComplete(String result) {
              // 3. Complete the future with the successful result.
              future.complete(result);
          }

          @Override
          public void onFailure(Exception e) {
              // 3. Complete the future with the exception.
              future.completeExceptionally(e);
          }
      });

      // 4. Return the future immediately.
      return future;
  }
  ```
