---
trigger: always_on
---

# Project Guidelines

## Build & Test Workflow
This project utilizes **Tuist** for project structure and management.

- **Project Management**: Use `tuist` for all project-related tasks.
- **Project Generation**: Run `tuist generate` if the Xcode project is missing or out of sync.
- **Dependencies**: Run `tuist install` to fetch dependencies defined in `Tuist/Package.swift`.
- **Building & Testing**: ALWAYS use the command `tuist build` to compile and test the project.
    - **CRITICAL**: Do NOT use raw `xcodebuild` unless explicitly required.
    - **Note**: Run this command from the directory containing `Project.swift`.
- **Verification**: 
    - **MANDATORY**: Always ensure the project remains buildable after *any* code change.
    - Run `tuist build` to verify that your changes are valid and do not introduce build errors.

## Test-Driven Development (TDD)
- **Mandatory TDD**: All new features and bug fixes MUST follow the Test-Driven Development workflow:
    1. **Red**: Write a failing test case that defines the desired behavior.
    2. **Green**: Write the minimum amount of code necessary to pass the test.
    3. **Refactor**: Improve code structure and quality while ensuring tests still pass.
- **Verification**: Ensure all tests pass before completing a task.
- **Framework**: Use the **Swift Testing** framework (via `swift test` or appropriate Tuist targets) for all new tests. Prefer the modern macro-based Swift Testing over XCTest.

## Technology Stack
- **Data Persistence**: Use **SwiftData** exclusively.
    - **Do NOT use Core Data**. If existing code uses Core Data, refactor to SwiftData when touching that part of the codebase.
