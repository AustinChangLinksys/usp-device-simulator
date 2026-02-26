# Quickstart

This document provides instructions on how to work with the project after the refactoring to use the `usp_protocol_common` library.

## Getting Started

1.  **Install Dependencies**: Run `flutter pub get` to install all the project dependencies, including the new `usp_protocol_common` library.

2.  **Run Tests**: Run `flutter test` to execute all the unit and integration tests to ensure that the refactoring was successful and that everything is working as expected.

## Development

When developing new features, be aware of the following:

- **Use the Shared Library**: All USP protocol-related functionality should be consumed from the `usp_protocol_common` library. Do not add any new code to this project that duplicates functionality from the shared library.
- **API Consistency**: The public API of this project should remain consistent. If you need to make changes to the USP protocol implementation, those changes should be made in the `usp_protocol_common` library, not in this project.
- **Dependency Management**: The `usp_protocol_common` dependency is managed in the `pubspec.yaml` file. Ensure that the version is pinned to a specific version to avoid breaking changes.
