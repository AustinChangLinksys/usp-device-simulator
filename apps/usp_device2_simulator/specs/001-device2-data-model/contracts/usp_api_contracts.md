# USP Data Model Engine API Contracts

**Feature Branch**: `001-device2-data-model` | **Date**: 2025-11-21
**Spec**: `specs/001-device2-data-model/spec.md`

## 總覽 (Overview)

本文件定義了 USP Device:2 資料模型引擎的核心程式介面（API 合約），主要關注其領域層 (Domain Layer) 對外提供的操作。這些合約反映了 USP 協定的主要功能需求，包括資料的獲取、設定、物件的動態管理以及命令執行。

所有介面設計都將遵循 Clean Architecture 原則，確保領域邏輯的純粹性與可測試性。

## 核心介面定義 (Core Interface Definitions)

### IDeviceRepository

`IDeviceRepository` 介面定義了對 `DeviceTree` 聚合根進行操作的抽象合約，這是應用層與領域層互動的主要方式。

#### 1. `getParameterValue(path: UspPath)`

*   **說明**: 根據給定的路徑獲取參數的值。
*   **參數**:
    *   `path`: `UspPath` - 目標參數的完整路徑或部分路徑 (支援通配符)。
*   **回傳**:
    *   `Future<List<UspValue>>` - 如果路徑指向單一參數，則列表包含一個元素；如果包含通配符或部分路徑，則返回所有匹配參數的值列表。
*   **錯誤**:
    *   `UspException` (例如，路徑不存在 - Error 7002)。

#### 2. `setParameterValue(path: UspPath, value: UspValue)`

*   **說明**: 根據給定的路徑設定參數的值。
*   **參數**:
    *   `path`: `UspPath` - 目標參數的完整路徑。
    *   `value`: `UspValue` - 要設定的新值。
*   **回傳**:
    *   `Future<void>`。
*   **錯誤**:
    *   `UspException` (例如，路徑不存在 - Error 7002，參數不可寫 - Error 7003/7004，值類型不符或超出範圍 - Error 7003)。

#### 3. `addObject(parentPath: UspPath, objectTemplateName: String)`

*   **說明**: 在指定父路徑下動態新增一個多實例物件。
*   **參數**:
    *   `parentPath`: `UspPath` - 新增物件的父物件路徑。
    *   `objectTemplateName`: `String` - 要新增的物件的類型名稱 (例如 "WiFi.SSID.")。
*   **回傳**:
    *   `Future<UspPath>` - 新增物件的完整路徑 (包含新分配的 Instance ID)。
*   **錯誤**:
    *   `UspException` (例如，父路徑不存在 - Error 7002，父物件不可新增實例 - Error 7005)。

#### 4. `deleteObject(objectPath: UspPath)`

*   **說明**: 刪除指定路徑的多實例物件。
*   **參數**:
    *   `objectPath`: `UspPath` - 要刪除的物件的完整路徑 (必須是多實例物件的一個實例)。
*   **回傳**:
    *   `Future<void>`。
*   **錯誤**:
    *   `UspException` (例如，路徑不存在 - Error 7002，物件不可刪除 - Error 7006)。

#### 5. `operate(commandPath: UspPath, inputArguments: List<UspValue>)`

*   **說明**: 執行指定路徑的 USP 命令。
*   **參數**:
    *   `commandPath`: `UspPath` - 目標命令的完整路徑。
    *   `inputArguments`: `List<UspValue>` - 命令執行所需的輸入參數。
*   **回傳**:
    *   `Future<List<UspValue>>` - 命令執行後的輸出參數列表。
*   **錯誤**:
    *   `UspException` (例如，命令不存在 - Error 7002，輸入參數不符 - Error 7003)。

## 通知機制 (Notification Mechanisms)

本引擎將透過事件發布機制提供狀態變更通知。這些通知將透過觀察者模式 (或類似的響應式流) 傳遞給訂閱者。

#### 1. `ValueChangeNotification`

*   **觸發條件**: 任何 `UspParameter` 的值被成功修改後。
*   **內容**:
    *   `path`: `UspPath` - 發生變化的參數路徑。
    *   `oldValue`: `UspValue` - 參數的舊值。
    *   `newValue`: `UspValue` - 參數的新值。

#### 2. `ObjectCreationNotification`

*   **觸發條件**: 新的多實例物件被成功新增後。
*   **內容**:
    *   `path`: `UspPath` - 新增物件的完整路徑。

#### 3. `ObjectDeletionNotification`

*   **觸發條件**: 多實例物件被成功刪除後。
*   **內容**:
    *   `path`: `UspPath` - 被刪除物件的完整路徑。

## 錯誤處理合約 (Error Handling Contract)

所有對 `IDeviceRepository` 介面的操作，若遇到預期錯誤情況（如 DBC 違反），必須拋出 `UspException`。該例外將包含符合 TR-369 標準的錯誤碼，允許上層應用程式進行精確的錯誤處理。