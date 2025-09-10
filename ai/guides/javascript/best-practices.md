# JavaScript Best Practices

## Code Style & Standards
- Use TypeScript for all new JavaScript files
- Prefer functional components over class components in React
- Use arrow functions for inline functions
- Always include explicit return types for functions
- Prefer template literals over string concatenation
- Use meaningful variable names that explain intent
- Prefer async/await over promises for readability
- Use object/array destructuring consistently
- Use early returns and guard clauses to reduce nesting and avoid deep if/else chains
- Organize imports consistently (external, internal, relative)

## Architecture & Design
- Keep functions small and focused (single responsibility)
- Use dependency injection for testability
- Design for scalability and performance
- Consider mobile-first responsive design
- Plan for internationalization from the start
- Implement React error boundaries for graceful error handling
- Validate and type environment variables properly

## Testing & Quality
- Write unit tests for all new functions
- Use descriptive test names that explain what is being tested
- Mock external dependencies in tests
- Aim for high test coverage on business logic
- Include integration tests for critical user flows
- Test error scenarios and edge cases
- Use data-testid attributes for reliable UI testing
- Write comprehensive JSDoc comments for all public functions
- Handle edge cases and null/undefined values
- Implement proper loading and error states in UI

## Organization & Performance
- Keep related files in the same directory
- Use index.ts files for clean exports
- Separate concerns (components, hooks, utils, types)
- Use absolute imports for shared modules
- Group by feature rather than file type when possible
- Lazy load components and routes when appropriate
- Optimize bundle sizes and eliminate dead code
- Use React performance hooks judiciously
- Implement proper caching strategies
- Follow security best practices for authentication/authorization
- Consider accessibility (a11y) in all UI components

## Spotify Guidelines
- Follow Spotify's coding guidelines and design system
- Consider user privacy and data protection (GDPR compliance)
- Implement proper analytics and metrics tracking
- Design for global scale and multiple markets