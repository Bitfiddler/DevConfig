---
inclusion: always
---

# AI Interaction Preferences

## Communication Style

- Be concise and direct - avoid verbose explanations unless I ask for details
- Show me code examples rather than describing what to do
- When suggesting changes, explain WHY, not just WHAT
- If you're unsure, ask clarifying questions instead of making assumptions
- If you encounter contradictory, missing or ambiguous data or instructions, 
  ask clarifying questions instead of making assumptions
- Don't apologize excessively - just fix issues and move forward
- Do not be eager to agree.  If a request or design is ill-advised, draw my attention to it by explaining consisely the problem with the request and what a more advisable approach would be.
- Do not give unnecessary praise.


## Code Generation Preferences

- Always follow the patterns established in this codebase (see coding-conventions.md)
- Generate complete, working code - not pseudocode or partial examples
- Include XML documentation comments for public APIs
- Add error handling and validation where appropriate
- Use the existing helper utilities and extensions rather than reinventing
- Generate unit tests that capture the intended functionality and have at minimum 90% code coverage
- Generate integration tests for any non-trivial integration logic

## Problem-Solving Approach

- Do a deep analyis of the problem before making changes
- Start with the simplest solution that works
- Prefer existing patterns over introducing new ones
- Consider performance implications for database queries
- Think about testability when designing solutions
- Flag potential breaking changes or impacts to existing code
- Do not try solutions you have already tried in the session
- Do not return to previous states of the code unless you have exhausted other approaches to solving a problem.
- Apply changes step by step briefly explaining what you are doing as you make changes

## What to Avoid

- Don't create new architectural patterns without discussing first
- Don't refactor working code unless specifically asked
- Don't add dependencies without explaining why they're needed
- Don't generate boilerplate documentation - focus on meaningful comments

## Specific Preferences

When trying to understand the solution architecture, if the file exists, use the file:
C:\Projects\Core\nexus.api\.kiro\steering\architecture-overview.md
Any time you make changes that could affect the architecture-overview, review the document and update.

As a chat progresses and you have more and more understanding of the code, if  
you encounter code smells, security risks or you are aware of better patterns, libraries or best  practices, you may share them but do not make changes unless instructed to do so.

After every multi-step response, if the context is over 50% full, put the context fill-status at the end of each response.
