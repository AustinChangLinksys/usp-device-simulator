# Actionable Tasks for: Refactor to use usp_protocol_common library

**Branch**: `002-refactor-usp-protocol-dependency` | **Spec**: [spec.md](./spec.md)

This task list is broken down by phase and user story, enabling parallel execution and independent testing.

## Phase 1: Setup

- [X] T001 Add `usp_protocol_common` as a local path dependency in `pubspec.yaml`. The path should point to the location of the `usp_protocol_common` library on your local machine.
- [X] T002 Run `flutter pub get` to fetch the new dependency

## Phase 2: User Story 1 - Remove duplicated code

**Goal**: As a developer, I want to remove the code that is now available in the `usp_protocol_common` library, so that the codebase is smaller and easier to maintain.

**Independent Test**: The project should compile and all existing tests should pass after removing the duplicated code and adding the dependency to `usp_protocol_common`.

### Implementation Tasks

- [X] T003 [US1] Identify all files in `lib/` and `test/` that contain code now available in `usp_protocol_common`.
- [X] T004 [US1] Go through each identified file and replace the duplicated code with imports and usages from the `usp_protocol_common` library.
- [X] T005 [US1] Delete any files that are now empty or contain only code that has been replaced.
- [X] T006 [US1] Update all import statements across the project to point to the `usp_protocol_common` library where necessary.
- [ ] T007 [US1] Run `flutter analyze` to ensure there are no analysis errors.
- [ ] T008 [US1] Run `flutter test` to ensure all existing tests pass.

## Phase 3: Polish & Cross-Cutting Concerns

- [ ] T009 Review the changes to ensure that no unnecessary code remains.
- [ ] T010 Final verification of the project by running all checks one last time.

## Dependencies

- User Story 1 is the only user story and has no dependencies on other stories.

## Parallel Execution

- Many of the refactoring tasks in T004 can be done in parallel, as changes to different files may not conflict. However, it is recommended to work on a small set of related files at a time to make it easier to track changes and resolve issues.

## Implementation Strategy

The implementation will follow a simple, single-phase approach focused on the main user story.

1.  **Setup**: Add the new dependency.
2.  **Refactor**: Systematically go through the codebase to replace the old code with the new library code.
3.  **Verify**: Run all tests and analysis to ensure the refactoring was successful.
