# Data Model

This feature does not introduce any new data models. Instead, it involves refactoring the existing implementation to use the `usp_protocol_common` library.

The key changes to the data model are:

- **Removal of Duplicated Models**: All data models related to the USP protocol that are now defined in the `usp_protocol_common` library will be removed from this project.
- **Dependency on External Models**: The project will now depend on the data models provided by the `usp_protocol_common` library. This includes entities, value objects, and other data structures related to the USP protocol.
- **No Change in Behavior**: The overall behavior of the data model will remain the same from the perspective of an external consumer of this project's API. The internal implementation will be different, but the public contracts will not change.
