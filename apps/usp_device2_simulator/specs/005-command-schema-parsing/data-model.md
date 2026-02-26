# Data Model: Command Node & Schema Parsing

This document outlines the new data entities required to represent USP/TR-181 commands within the device's data model tree.

## New Entities

### 1. UspCommandNode

Represents an executable function or command within the `DeviceTree`. This node is created by the `XmlSchemaLoader` when it encounters a `<command>` tag in the data model XML.

*   **Inheritance**: `UspNode`
*   **Purpose**: To store all metadata related to a command, including its arguments and asynchronous behavior.

**Properties**:

| Property     | Type                                     | Description                                                                                             |
| :----------- | :--------------------------------------- | :------------------------------------------------------------------------------------------------------ |
| `isCommand`  | `bool`                                   | Always returns `true` to identify this node as a command.                                               |
| `isAsync`    | `bool`                                   | Derived from the XML `commandType` attribute. `true` if the type is 'asynchronous', otherwise `false`.  |
| `inputArgs`  | `Map<String, UspArgumentDefinition>`     | A map containing the metadata for all defined input arguments required by the command. The key is the argument name. |
| `outputArgs` | `Map<String, UspArgumentDefinition>`     | A map containing the metadata for all defined output arguments returned by the command. The key is the argument name. |

### 2. UspArgumentDefinition

A Data Transfer Object (DTO) used to hold the metadata for a single command argument.

*   **Purpose**: To provide a structured representation of a command's input or output parameters.

**Properties**:

| Property | Type           | Description                                                              |
| :------- | :------------- | :----------------------------------------------------------------------- |
| `name`   | `String`       | The name of the argument.                                                |
| `type`   | `UspValueType` | The data type of the argument, derived from the `<syntax>` tag in the XML. |
