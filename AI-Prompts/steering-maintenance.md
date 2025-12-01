---
inclusion: always
---

# Steering Document Maintenance Guide

This document explains how to keep the steering documents up-to-date as the codebase evolves.

## When to Update Steering Documents

### Update `codebase-map.md` when:

1. **Adding a new feature area**
   - Add entry under "Feature Areas" with location, services, repositories, endpoints, and Swagger tag
   - Add route registration to "Quick Reference: Adding a New Feature"

2. **Adding a new service**
   - Update the relevant feature area section with the new service name
   - If it's a cross-cutting service, add to "Cross-Cutting Concerns"

3. **Adding a new repository**
   - Update the relevant feature area section with the new repository name and interface

4. **Adding new endpoints**
   - Add endpoint routes to the relevant feature area
   - Include HTTP method and brief description

5. **Adding middleware**
   - Add to "Middleware (Execution Order)" in the correct position
   - Order matters - document why it's in that position

6. **Adding health checks**
   - Add to "Health Checks" section with brief description

7. **Adding external SDKs or shared libraries**
   - Add to appropriate section with location, purpose, and key classes/interfaces

### Update `coding-conventions.md` when:

1. **Establishing new patterns**
   - Document the pattern with code examples
   - Explain when and why to use it

2. **Changing naming conventions**
   - Update the relevant section
   - Provide migration guidance if needed

3. **Adding new validation rules**
   - Add to "Validation Patterns" section

4. **Changing error handling approach**
   - Update "Error Handling" section

5. **Adding new configuration patterns**
   - Add to "Configuration Patterns" section with example

### Update `architecture-overview.md` when:

1. **Adding new projects to the solution**
   - Add to "Solution Structure" under appropriate category
   - Include brief description of purpose

2. **Changing technology stack**
   - Update "Technology Stack" section
   - Document migration path if applicable

3. **Modifying middleware pipeline**
   - Update "Middleware Pipeline" section
   - Explain the change and reasoning

4. **Changing deployment process**
   - Update "Deployment" section

5. **Adding new architectural patterns**
   - Add to "Key Architectural Patterns" with explanation and examples

### Update `ai-interaction-preferences.md` when:

1. **Team preferences change**
   - Update relevant sections
   - Be specific about what you want

2. **New team members join**
   - Review and adjust preferences to match team consensus

3. **You notice AI making repeated mistakes**
   - Add specific guidance to prevent the issue

### Update spec `tasks.md` Known Issues section when:

1. **A task introduces a compilation or runtime error that will be fixed by a later task**
   - Add to "Active Issues" section with:
     - Error message/type
     - Location (file path)
     - Root cause explanation
     - Which task will resolve it
     - Status note (e.g., "Expected - do not fix manually")

2. **A task resolves a known issue**
   - Move the issue from "Active Issues" to "Resolved Issues"
   - Add resolution details (task number, date if relevant)
   - Keep resolved issues for reference during the feature implementation

3. **Completing any task in a spec**
   - Review "Active Issues" to see if the completed task resolved any issues
   - Update issue status accordingly
   - If new errors appear, document them if they're expected to be resolved by future tasks

4. **Starting work on a new task**
   - Check "Active Issues" to understand expected compilation/runtime errors
   - Don't attempt to fix issues that are marked as "Expected"

### Update spec `tasks.md` Implementation Notes section when:

1. **Making temporary changes during task implementation**
   - Add entry to "Implementation Notes" section at the end of tasks.md
   - Document what was changed, where, why, and which task will address it
   - Include file paths and line numbers for easy reference
   - Mark with clear "Action Required" pointing to the resolving task

2. **Completing a task that resolves temporary changes**
   - Mark the corresponding Implementation Notes entry as resolved
   - Add resolution details (task number, what was done)
   - Remove the entry after verification that the change is permanent

3. **At checkpoint tasks**
   - Review all Implementation Notes entries
   - Verify which ones have been resolved
   - Clean up resolved entries
   - Ensure remaining entries are still accurate

4. **Format for Implementation Notes entries**:
   ```markdown
   ### Temporary Changes Made During Task X
   
   **Date**: [Task number and brief description]
   
   **Changes**:
   1. **[Description of change]**:
      - Location: [File path and line number if applicable]
      - Reason: [Why this temporary change was needed]
      - **Action Required**: [Which task will address this]
   
   **Status**: [Current status and expected resolution]
   ```

**Purpose**: The Implementation Notes section tracks temporary workarounds, commented-out code, or interim solutions that are needed to keep the build working while implementing a multi-task feature. This is different from Known Issues which tracks expected compilation errors.

## Maintenance Checklist

When making significant changes to the codebase, review these documents:

- [ ] Does `codebase-map.md` reflect the current feature areas?
- [ ] Are all services and repositories documented?
- [ ] Are all endpoints listed with correct routes?
- [ ] Does `coding-conventions.md` match current patterns?
- [ ] Does `architecture-overview.md` reflect current architecture?
- [ ] Are there new patterns that should be documented?
- [ ] If working on a spec, is the `tasks.md` Known Issues section up to date?
- [ ] If working on a spec, is the `tasks.md` Implementation Notes section up to date?

## Auto-Update Triggers

Consider updating steering documents when:

- Creating a new feature branch for a major feature
- Completing a sprint/iteration
- Onboarding new team members
- After architectural reviews
- When you notice AI suggestions don't match current patterns

## Document Structure Rules

### All steering documents should:
- Use `---` frontmatter with `inclusion: always` (or conditional rules)
- Use clear, hierarchical headings
- Include code examples for patterns
- Be concise but complete
- Focus on "what" and "why", not just "how"

### Avoid in steering documents:
- Outdated information (remove or update)
- Overly verbose explanations
- Duplicate information across documents
- Implementation details that change frequently
- Personal opinions without team consensus

## Quick Update Commands

When AI helps you add a feature, remind it to:
```
"Update codebase-map.md with the new [Feature] area including services, repositories, and endpoints"
```

When establishing a new pattern:
```
"Document this pattern in coding-conventions.md with an example"
```

When changing architecture:
```
"Update architecture-overview.md to reflect the new [architectural change]"
```

## Validation

Periodically validate steering documents by:
1. Checking that documented endpoints exist in `ApiEndpoints.cs`
2. Verifying services listed have `[Service]` attribute
3. Confirming repositories inherit from `RepositoryBase`
4. Ensuring middleware order matches `Program.cs`
5. Validating feature folders exist at documented locations

## Notes for AI Assistants

When working with this codebase:
1. **Always check** `codebase-map.md` before asking where something is
2. **Follow patterns** documented in `coding-conventions.md`
3. **Understand architecture** from `architecture-overview.md`
4. **Respect preferences** in `ai-interaction-preferences.md`
5. **Update documents** when making structural changes
6. **Ask before** introducing patterns not documented here
7. **Flag inconsistencies** between code and documentation
8. **When working on spec tasks**, check the Known Issues section in `tasks.md` to understand expected errors
9. **After completing a spec task**, update the Known Issues section if the task resolved or introduced any tracked issues
10. **When making temporary changes during spec implementation**, document them in the Implementation Notes section at the end of `tasks.md`
11. **At checkpoint tasks**, review and clean up the Implementation Notes section

## Document Ownership

These steering documents are living documentation:
- **Owned by**: The development team
- **Updated by**: Developers and AI assistants working on the code
- **Reviewed by**: Tech leads during code reviews
- **Validated by**: Regular audits against actual codebase

Keep them accurate, keep them current, keep them useful.
