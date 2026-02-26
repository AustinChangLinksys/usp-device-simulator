# Quickstart: Verifying Command Parsing

This guide provides a simple way to verify that the command parsing feature is working correctly.

## Verification Steps

1.  **Prepare a Test Schema**:
    Ensure you have a TR-181 XML schema file that contains at least one `<command>` tag. A good example is the `Device.IP.Diagnostics.IPPing` command, as it includes both input and output arguments.

    *Example Snippet from a test XML:*
    ```xml
    <command name="IPPing()">
        <input>
            <parameter name="Host" access="readWrite" activeNotify="canDeny">
                <syntax>
                    <string>
                        <size value="256"/>
                    </string>
                </syntax>
            </parameter>
            ...
        </input>
        <output>
            <parameter name="Status" access="readOnly">
                <syntax>
                    <string>
                        <enum value="Success"/>
                        <enum value="Failure"/>
                    </string>
                </syntax>
            </parameter>
            ...
        </output>
    </command>
    ```

2.  **Load the Schema**:
    Use the `XmlSchemaLoader` to load your test schema and build the `DeviceTree`.

3.  **Inspect the Device Tree**:
    After the schema is loaded, access the node corresponding to the command and inspect its properties.

    *Example verification in a test environment:*
    ```dart
    // Assume 'deviceTree' is your loaded DeviceTree instance
    final ipPingNode = deviceTree.getNode('Device.IP.Diagnostics.IPPing.');

    // 1. Verify it is a command node
    expect(ipPingNode, isA<UspCommandNode>());

    // 2. Cast and inspect properties
    final commandNode = ipPingNode as UspCommandNode;
    print('Is command: ${commandNode.isCommand}'); // Expected: true
    print('Is async: ${commandNode.isAsync}');

    // 3. Check input arguments
    print('Input args: ${commandNode.inputArgs.keys}'); // Expected: {'Host', ...}
    final hostArg = commandNode.inputArgs['Host'];
    print('Host arg type: ${hostArg?.type}'); // Expected: UspValueType.string

    // 4. Check output arguments
    print('Output args: ${commandNode.outputArgs.keys}'); // Expected: {'Status', ...}
    ```

By following these steps, you can quickly confirm that the `XmlSchemaLoader` is correctly parsing command tags and their associated argument metadata, making them available in the `DeviceTree`.
