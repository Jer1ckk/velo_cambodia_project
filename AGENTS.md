# Repository Coding Instructions

These instructions apply across programming languages, frameworks, architectures, and repository layouts. Discover each project's conventions from its own implementation and configuration. Do not carry assumptions from another codebase into the current one.

This file applies throughout this repository. Nested `AGENTS.md` files may add instructions for their directories. Project documentation has two complementary roles:

- [Project guidelines](docs/PROJECT_GUIDELINES.md): current architecture, data flow, conventions, implementation examples, and known limitations.
- [UI/UX guidelines](docs/UI_UX_GUIDELINES.md): design tokens, screen requirements, and UI acceptance criteria.

## 1. Core Principles

- Inspect the existing code before making changes. Treat verified implementation as the source of truth for current behavior; use the user's requirements to determine the intended change.
- Follow the project's established architecture, folder structure, coding style, naming, and implementation patterns. Prefer consistency over personal preferences or generic best practices.
- Reuse suitable components, utilities, functions, services, and dependencies instead of creating duplicate implementations.
- Make the smallest appropriate change that fully completes the requested task. Avoid unnecessary refactoring, speculative abstractions, and unrelated improvements.
- Preserve existing functionality and compatibility unless the task requires changing them.
- Verify technologies and architectural patterns through configuration and actual code paths; do not infer them solely from names or directories.

## 2. Project Analysis

Before implementing a feature or fix:

1. Read applicable repository instructions and relevant documentation listed below.
2. Inspect the root directory and relevant manifests, build configuration, tool configuration, and entry points to identify languages, frameworks, dependencies, and development tools.
3. Find a similar existing feature and read its relevant implementation, callers, and tests.
4. Trace component responsibilities and communication to establish the actual architecture and dependency direction.
5. Understand relevant data flow, state ownership, persistence, dependency initialization, and external integrations where applicable.
6. Identify existing error handling, validation, logging, testing, and formatting patterns.
7. Check the working tree or equivalent change tracking so existing user changes can be preserved.

Inspect only what is needed for the task. Expand the investigation when an unfamiliar dependency, caller, shared contract, or inconsistency affects the implementation. Do not read or print secret values while inspecting configuration.

## 3. Architecture and Code Organization

- Follow the architecture verified in this project. Do not introduce or replace architectural patterns without an explicit task requirement.
- Put new files in the appropriate existing directories, using nearby features as placement examples.
- Keep responsibilities within the boundaries the project uses for business logic, presentation, data access, infrastructure, and other applicable concerns. Do not impose layers that the project does not have.
- Preserve established dependency direction, communication patterns, and component lifecycle management.
- When changing a shared contract, inspect and update affected callers and implementations, including relevant alternate implementations and tests.
- Add abstractions or layers only when they solve a concrete task requirement and fit the surrounding design.

## 4. Coding Style and Naming

- Match the project's conventions for file names, classes, functions, variables, constants, and other language-specific constructs.
- Follow existing formatting, indentation, import organization, and configured lint rules. Use the project's formatter when available, scoped to changed files where practical.
- Use language features supported by the configured toolchain and consistent with nearby code.
- Write readable code with clear names and straightforward control flow. Avoid adding stylistic churn to unrelated lines.
- Add comments and documentation when they explain non-obvious behavior, constraints, or decisions. Follow existing documentation conventions.
- Do not introduce blanket lint suppressions or weaken checks merely to make a change pass validation.

## 5. Dependencies and Existing Components

- Search for existing functionality and inspect current dependencies before adding a package or implementing a new utility.
- Reuse established components when their behavior fits the requirement; verify behavior rather than relying on names alone.
- Add a dependency only for a clear need that existing facilities do not adequately cover. Explain the reason and account for configuration, platform, and compatibility implications.
- Do not upgrade, remove, or replace dependencies unless the task requires it.
- Follow existing dependency initialization, configuration, package-manager, and lockfile practices. Avoid unrelated dependency resolution changes.
- Keep environment-specific configuration in the locations and mechanisms already used by the project. Never embed secret values in code or documentation.

## 6. Implementation Workflow

For each coding task:

1. Establish the requested behavior, scope, constraints, and completion criteria.
2. Inspect relevant code, applicable instructions, and project-specific guidelines.
3. Identify the files, components, contracts, and tests affected by the change.
4. Implement the smallest complete solution using the project's conventions and reusable facilities.
5. Handle relevant validation, errors, state transitions, and resource cleanup according to existing patterns.
6. Run appropriate available tests, static analysis, formatting checks, or other validation using commands verified from the project's configuration or documentation.
7. Review the final diff for regressions, accidental changes, compatibility issues, and consistency with nearby implementations.
8. Summarize what changed, how it was validated, and any unresolved issues or limitations.

Scale validation to the change. Add or update meaningful behavioral tests when warranted; do not create tests that merely repeat the implementation. Do not assume a test suite exists or introduce a testing framework solely for an unrelated task.

Never claim that a command or test succeeded unless it was executed and its result checked. Distinguish checks that passed, failed, or were not run. If validation is blocked by missing tooling or another constraint, explain the limitation. Separate verified pre-existing failures from regressions; do not label a failure pre-existing without evidence.

## 7. Uncertainty and Conflicts

- Investigate discrepancies between documentation, configuration, and implementation before relying on a disputed convention.
- Follow applicable instructions and explicit user requirements; use implementation evidence to establish current behavior. Existing behavior does not override a requested behavior change.
- If several patterns coexist, choose the closest relevant, verified pattern and explain a consequential choice. Do not silently standardize unrelated features.
- Make reasonable implementation choices within the authorized scope. Ask for clarification when an important requirement or consequential decision cannot be determined safely, and continue independent work when possible.
- Do not invent requirements, architecture rules, unsupported behavior, or missing implementation details. State material assumptions and unresolved questions explicitly.

## 8. Project-Specific Guidelines

- Use [docs/PROJECT_GUIDELINES.md](docs/PROJECT_GUIDELINES.md) as the main reference for project-specific architecture, file placement, coding conventions, and implementation examples.
- Verify guidance against relevant source and configuration, especially when it appears outdated or conflicts with current code.
- If the guidelines are absent, follow conventions established directly through inspection. Their absence alone does not require creating a new guidelines document.
- Keep reusable instructions independent of any particular framework, architecture, folder name, or state-management tool. Keep project-specific facts in project-specific documentation.
- Never copy another project's assumptions into the current implementation.

## 9. Scope and Safety

- Modify only files needed for the requested task. Avoid unrelated formatting, generated-file changes, renames, deletions, and refactoring.
- Preserve existing user changes. Integrate around them; do not overwrite, revert, or discard them without explicit authorization.
- Do not perform destructive operations without explicit authorization. Use reversible actions where practical.
- Do not expose secrets, credentials, or environment-variable values in output, logs, examples, commits, or documentation. Inspect configuration structure and variable names without revealing values.
- Preserve backward compatibility where appropriate. When a required change affects public interfaces, stored data, configuration, or integrations, account for affected consumers and any necessary migration.
- Explain important trade-offs and required deviations from established patterns. Do not use a task as authorization to repair unrelated issues.
- Before finishing, confirm that the requested work is complete, review the changed-file scope, and report material remaining limitations accurately.

## 10. Documentation Discovery

Before working on a task, identify which project documentation is relevant.

- Read [docs/PROJECT_GUIDELINES.md](docs/PROJECT_GUIDELINES.md) when working with architecture, business logic, data flow, repositories, state management, or implementation conventions.
- Read [docs/UI_UX_GUIDELINES.md](docs/UI_UX_GUIDELINES.md) when working with UI design, layouts, styling, navigation, interactions, or accessibility.
- Follow applicable `AGENTS.md` instructions in nested directories.
- Use documentation as guidance, but verify important implementation details against the actual source code.
- Do not read unrelated documentation unless the task requires it.
