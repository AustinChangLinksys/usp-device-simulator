# Research: Command Node & Schema Parsing

## Research Summary

No significant research was required for this feature. The implementation path is straightforward and relies on existing patterns within the `XmlSchemaLoader`.

The approach will be to add a new parsing pass to the loader, reusing the existing `xml` package to iterate through `<command>` tags and their children. The logic will mirror the existing parsing for objects and parameters.

## Decisions

*   **Technology**: Continue using the `xml` package for parsing.
*   **Approach**: Implement a new, dedicated parsing pass within `XmlSchemaLoader` to handle commands. This is preferred over trying to merge command parsing into the object/parameter passes, as it keeps the logic clean and separated.
