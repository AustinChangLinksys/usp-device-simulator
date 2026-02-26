# Data Model: TR-181 Device:2 資料模型引擎

**Feature Branch**: `001-device2-data-model` | **Date**: 2025-11-21
**Spec**: `specs/001-device2-data-model/spec.md`

## 核心實體 (Core Entities)

基於領域驅動設計 (DDD) 原則，以下是本專案的核心領域實體與值物件：

### 聚合根 (Aggregate Root)

*   **DeviceTree (資料模型樹)**
    *   **職責**: 維護整個 TR-181 資料模型的階層結構和一致性。作為對外操作的唯一入口點。
    *   **屬性**: 包含根節點，以及管理所有子節點的機制。
    *   **行為**: 
        *   提供方法以根據 `UspPath` 獲取、設定、新增、刪除節點。
        *   確保所有操作均符合 TR-181 標準和內部不變量 (Invariants)。
        *   在狀態變更時觸發通知。

### 實體 (Entities)

*   **UspNode (節點)**
    *   **職責**: 所有資料模型中元素的通用基類。
    *   **屬性**:
        *   `path`: `UspPath` (該節點的完整路徑)。
        *   `name`: `String` (節點名稱)。
        *   `attributes`: `Map<String, dynamic>` (TR-181 定義的屬性，如 `writable`, `creatable` 等)。
    *   **行為**: 提供抽象介面供具體子類實現。

*   **UspObject (物件)**
    *   **職責**: 表示資料模型中的物件節點，可以包含子物件、參數和命令。
    *   **繼承**: `UspNode`。
    *   **屬性**:
        *   `children`: `Map<String, UspNode>` (子節點集合)。
        *   `isMultiInstance`: `bool` (是否為多實例物件，例如 `Device.WiFi.Radio.{i}.`)。
        *   `nextInstanceId`: `int` (僅用於多實例物件，追蹤下一個可用的實例 ID)。

*   **UspParameter (參數)**
    *   **職責**: 表示資料模型中的參數節點，持有其值和驗證規則。
    *   **繼承**: `UspNode`。
    *   **屬性**:
        *   `value`: `UspValue<T>` (泛型值物件，包含實際資料與型別資訊)。
        *   `validationRules`: `List<ValidationRule>` (基於 Schema 定義的驗證規則，如類型、範圍、正則表達式)。
        *   `isWritable`: `bool` (參數是否可寫)。
        *   `isReadable`: `bool` (參數是否可讀)。
    *   **行為**: 提供 `validate(UspValue<T> newValue)` 方法以檢查新值是否符合規則。

*   **UspCommand (命令)**
    *   **職責**: 表示資料模型中的可執行操作。
    *   **繼承**: `UspNode`。
    *   **屬性**:
        *   `inputArguments`: `List<UspParameter>` (命令的輸入參數)。
        *   `outputArguments`: `List<UspParameter>` (命令的輸出參數)。
    *   **行為**: 提供 `execute()` 方法以模擬命令執行。

### 值物件 (Value Objects)

*   **UspPath (路徑)**
    *   **職責**: 封裝 USP 協定中路徑的邏輯，提供解析、匹配和操作功能。
    *   **屬性**:
        *   `segments`: `List<String>` (路徑的各個組成部分，例如 `["Device", "WiFi", "Radio", "1", "Status"]`)。
        *   `hasWildcard`: `bool` (是否包含通配符 `*`)。
        *   `aliasFilter`: `Map<String, String>` (如果路徑包含別名篩選)。
    *   **行為**:
        *   `parse(String rawPath)`: 解析原始路徑字串。
        *   `matches(UspPath otherPath)`: 判斷是否匹配另一個路徑 (支援通配符)。
        *   `isMultiInstancePath()`: 判斷是否指向多實例物件。

*   **UspValue<T> (參數值)**
    *   **職責**: 封裝參數的實際值，並包含其型別資訊，確保型別安全與一致性。
    *   **屬性**:
        *   `value`: `T` (實際的參數值，T 可以是 String, int, bool 等)。
        *   `type`: `UspValueType` (值的類型，例如 `UspValueType.string`, `UspValueType.int`, `UspValueType.unsignedInt`, `UspValueType.long`, `UspValueType.unsignedLong`, `UspValueType.boolean` 等)。
    *   **行為**:
        *   提供類型轉換和值比較功能。
        *   `equals(UspValue<T> other)`: 比較值物件的內容。

*   **InstanceId (實例 ID)**
    *   **職責**: 識別多實例物件中的特定實例。
    *   **屬性**: `int` (實例的唯一數字 ID)。
    *   **行為**: 提供 ID 的生成和驗證。

### 其他關鍵概念 (Other Key Concepts)

*   **UspException (USP 例外)**
    *   **職責**: 系統處理錯誤時拋出的特定例外，包含標準 TR-369 錯誤碼。
    *   **屬性**: `errorCode`: `int`, `message`: `String`。

*   **裝置資料存取介面 (IDeviceRepository)**
    *   **職責**: 定義對 `DeviceTree` 進行操作的抽象合約，如 `get`, `set`, `add`, `delete` 等。

*   **XML Schema 載入器 (SchemaLoader)**
    *   **職責**: 負責解析 TR-181 XML Schema，並將其轉換為記憶體中的 `DeviceTree` 結構。

*   **JsonConfigLoader (JSON 配置載入器)**
    *   **職責**: 負責讀取 JSON 檔案，解析配置數據，並使用 `updateInternally` 機制將其應用到資料模型中，覆蓋現有預設值。

*   **資料持久化服務 (PersistenceService)**
    *   **職責**: 負責 `DeviceTree` 配置和狀態的儲存與恢復。

## 關係 (Relationships)

*   `DeviceTree` 聚合 `UspObject`, `UspParameter`, `UspCommand` (通過 `UspNode` 關係)。
*   `UspObject` 可以包含多個 `UspNode` (作為子節點)。
*   `UspParameter` 包含 `UspValue` 和 `ValidationRule`。
*   `UspCommand` 包含 `UspParameter` 作為輸入/輸出。
*   所有 `UspNode` 實體都具有一個 `UspPath`。
*   `IDeviceRepository` 依賴 `DeviceTree` 進行操作。
*   `SchemaLoader` 負責構建 `DeviceTree`。
*   `PersistenceService` 負責保存和恢復 `DeviceTree` 的狀態。

### 3.3 狀態變更策略 (State Mutation Strategy)

為嚴格遵守憲章定義的 **不可變狀態 (Immutable State)** 原則，本系統採用 **Copy-on-Write** 機制來處理所有狀態變更。嚴禁直接修改 `UspNode` 實例的內部屬性。

#### 3.3.1 UspNode 不可變性 (Immutability)
* 所有 `UspNode` 及其子類別 (`UspParameter`, `UspObject`) 的屬性必須宣告為 `final`。
* 禁止在 Entity 內部提供 `set` 方法來修改屬性。
* 變更邏輯必須透過回傳新實例的方法來實現 (例如 `setValue` 回傳新的 `UspParameter`)。

#### 3.3.2 變更流程標準 (Mutation Flow Standard)
當 UseCase 需要修改某個節點的狀態時，必須遵循以下三步驟流程：

1.  **讀取 (Read):** 從 Repository 取得目前的節點實例 (Old Instance)。
2.  **複製並修改 (Copy & Modify):** 呼叫節點的 `copyWith` (或封裝好的 domain method 如 `setValue`)，傳入新值。此方法將回傳一個全新的節點實例 (New Instance)，舊實例保持不變。
3.  **替換 (Replace):** 將新實例傳遞給 `repository.saveNode(newNode)`。Repository 負責在底層儲存結構 (Map) 中，將該 Path 對應的 Value 替換為新實例，並觸發 Riverpod 通知。

**程式碼範例 (Concept):**

```dart
// 錯誤 (Violates Charter):
// node.value = newValue; 

// 正確 (Complies with Charter):
final oldNode = repository.getNode(path);
final newNode = oldNode.setValue(newValue); // Returns new instance via copyWith
repository.saveNode(newNode); // Replaces the entry in DeviceTree Map
```