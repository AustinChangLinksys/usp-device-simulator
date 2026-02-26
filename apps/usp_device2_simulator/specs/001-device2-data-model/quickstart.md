# Quickstart Guide: TR-181 Device:2 資料模型引擎

**Feature Branch**: `001-device2-data-model` | **Date**: 2025-11-21
**Spec**: `specs/001-device2-data-model/spec.md`

## 總覽 (Overview)

本快速入門指南旨在協助開發人員快速理解並開始使用 TR-181 Device:2 資料模型引擎。它將提供設定專案、載入 TR-181 XML Schema 以及執行基本 USP 操作的步驟。

## 專案設定 (Project Setup)

1.  **環境要求**:
    *   確保您的開發環境已安裝 Dart SDK (版本 >= 3.0)。
    *   確保您的專案已配置為 Dart 專案。

2.  **新增依賴 (Add Dependencies)**:
    *   在您的 `pubspec.yaml` 檔案中新增必要的依賴。雖然此核心引擎是純 Dart 領域邏輯，但為了 Schema 解析和可能的持久化，您可能需要 `xml` 和 `json_serializable` 相關套件。
        ```yaml
        dependencies:
          # your other dependencies
          xml: ^latest_version # for XML Schema parsing
          json_serializable: ^latest_version # for data persistence
          build_runner: ^latest_version # dev dependency for json_serializable
        ```
    *   執行 `dart pub get` 安裝依賴。

## 載入 TR-181 XML Schema (Loading TR-181 XML Schema)

資料模型引擎的核心特性是其 Schema 驅動能力。您需要提供一個標準的 TR-181 XML Schema 文件來建構記憶體中的 `DeviceTree`。

1.  **準備 Schema 文件**: 獲取官方 TR-181 XML Schema 文件 (例如 `tr-181-2-16-0.xml`) 並放置在專案的適當位置。

2.  **使用 `SchemaLoader` 載入**:
    ```dart
    import 'package:your_project/infrastructure/schema/schema_loader.dart';
    import 'package:your_project/domain/models/device_tree.dart';
    import 'dart:io';

    Future<DeviceTree> initializeDeviceTree(String schemaFilePath) async {
      final file = File(schemaFilePath);
      final xmlContent = await file.readAsString();
      final schemaLoader = XmlSchemaLoader(); // 假設這是您的實作
      final deviceTree = await schemaLoader.loadSchema(xmlContent);
      return deviceTree;
    }

    void main() async {
      final deviceTree = await initializeDeviceTree('path/to/your/tr-181-2-16-0.xml');
      print('DeviceTree initialized successfully!');
      // 您現在可以開始使用 deviceTree 執行 USP 操作
    }
    ```

## 執行基本 USP 操作 (Performing Basic USP Operations)

一旦 `DeviceTree` 初始化完成，您可以透過 `IDeviceRepository` 介面執行標準的 USP CRUD 操作。

1.  **獲取參數值 (Get Parameter Value)**:
    ```dart
    import 'package:your_project/domain/repositories/i_device_repository.dart';
    import 'package:your_project/domain/models/usp_path.dart';
    // 假設您已有了 IDeviceRepository 的實現
    import 'package:your_project/infrastructure/state/device_repository_impl.dart';

    void main() async {
      final deviceTree = await initializeDeviceTree('path/to/your/tr-181-2-16-0.xml');
      final deviceRepository = DeviceRepositoryImpl(deviceTree); // 假設這是您的實作

      final path = UspPath.parse('Device.DeviceInfo.Manufacturer');
      try {
        final values = await deviceRepository.getParameterValue(path);
        if (values.isNotEmpty) {
          print('Manufacturer: ${values.first.value}');
        }
      } on UspException catch (e) {
        print('Error getting parameter: ${e.message} (Code: ${e.errorCode})');
      }
    }
    ```

2.  **設定參數值 (Set Parameter Value)**:
    ```dart
    import 'package:your_project/domain/models/usp_value.dart';

    void main() async {
      final deviceTree = await initializeDeviceTree('path/to/your/tr-181-2-16-0.xml');
      final deviceRepository = DeviceRepositoryImpl(deviceTree);

      final path = UspPath.parse('Device.LocalAgent.Name');
      final newValue = UspValue<String>('MySimulatorAgent');

      try {
        await deviceRepository.setParameterValue(path, newValue);
        print('Agent name set to MySimulatorAgent');
      } on UspException catch (e) {
        print('Error setting parameter: ${e.message} (Code: ${e.errorCode})');
      }
    }
    ```

3.  **新增物件 (Add Object)**:
    ```dart
    // ... 假設已初始化 deviceRepository
    final parentPath = UspPath.parse('Device.WiFi.Radio.1.'); // 注意這裡的 .
    final objectTemplateName = 'SSID'; // 根據 TR-181 Schema

    try {
      final newObjectPath = await deviceRepository.addObject(parentPath, objectTemplateName);
      print('New SSID object added at: ${newObjectPath.fullPath}');
    } on UspException catch (e) {
      print('Error adding object: ${e.message} (Code: ${e.errorCode})');
    }
    ```

## 錯誤處理 (Error Handling)

所有操作都可能拋出 `UspException`，開發人員應捕獲這些例外並根據其中的錯誤碼進行處理，以符合 TR-369 協議標準。

## 下一步 (Next Steps)

*   查閱 `data-model.md` 了解詳細的領域模型結構。
*   查閱 `contracts/usp_api_contracts.md` 了解所有可用的 API 介面。
*   探索專案的測試案例，了解如何驗證核心邏輯。