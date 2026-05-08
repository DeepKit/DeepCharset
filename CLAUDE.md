# DeepCharset CLAUDE.md

编码检测与批量转换工具。Delphi 12 VCL, Win64 only�?
---

## 架构现状与目�?
### 当前依赖关系（实际）

```
ViewMainCode (3412�?
  ├── 创建并拥�? TAppConfig, TEncodingModel, TUIHelper,
  �?               TEncodingController, TFileHelper
  ├── 直接调用: ModelConfig, ModelEncoding, HelperUI, HelperFiles
  ├── 持有: 语言管理、目录历史、日志缓�?  └── 问题: UI、业务编排、配置、国际化全混在一�?
ControllerEncoding (420�?
  └── 编排: 检�?�?转换（职责清晰，但被 View 绕过�?
HelperLanguage (618�?
  └── 全局变量 LanguageManager（应消除�?
ControllerLanguage (60�?
  └── 纯透传层，直接委托�?HelperLanguage.LanguageManager
```

### 目标依赖方向

```
View �?Controller �?Helper/Model �?Utils
                    �?              Interfaces（接口定义）

依赖只能向右/向下指，不能反向�?```

### 核心原则

1. **View 不做业务判断** �?按钮点击后调�?Controller，Controller 返回结果，View 只负责显�?2. **Controller 不认�?UI** �?不引�?Vcl.Forms/StdCtrls/Dialogs，不知道 TButton/TLabel 的存�?3. **Utils 不认识业�?* �?只做纯技术工具（编码计算、流处理、BOM 操作），不引�?Model/Controller
4. **全局变量逐步消除** �?用构造函数注入替代全局 `var` 声明

---

## 命名约定

| 类型 | 前缀 | 说明 |
|---|---|---|
| Form | `View` | ViewMainCode, ViewSynEdit, ViewMemo |
| 控制�?| `Controller` | ControllerEncoding, ControllerLanguage, ControllerCommandLine |
| 数据模型 | `Model` | ModelEncoding, ModelConfig, ModelLanguage |
| 业务辅助 | `Helper` | HelperFiles, HelperUI, HelperLanguage |
| 纯工�?| `Utils` | UtilsTypes, UtilsEncodingBOM_Improved, ... |
| 接口 | `Interfaces` | InterfacesEncoding |
| JCL 适配 | `Jcl` | JclStreams, JclStrings, ...（第三方修改�?|
| 编码检测器 | `*Detector_Improved` | ChineseEncodingDetector_Improved, ... |
| 编码转换�?| `*Converter_Improved` | EncodingConverter_Improved, ... |

新文件必�?UTF-8 with BOM。禁止默认命名（Unit1, Form1）�?
---

## 跨层引用规则

### 允许

```
View       �?Controller*, Model*, Helper*, UtilsTypes
Controller �?Model*, Helper*, Utils*, Winapi.*, System.*
Model      �?System.*, HelperLanguage（仅国际化字符串�?Helper     �?Model*, Utils*, System.*
Utils      �?System.*, Utils*（仅其他 Utils�?Interfaces �?System.*, UtilsTypes
```

### 禁止

```
Controller �?Vcl.Forms, Vcl.StdCtrls, Vcl.Dialogs（用回调/事件替代 ShowMessage�?Model      �?Vcl.*, Utils*（Model 是纯数据，不碰工具实现）
Utils      �?Model*, Controller*, Helper*（工具不依赖业务�?Interfaces �?任何实现类的 uses
```

### 检�?
```bash
# Controller 引用�?UI�?grep -rn "Vcl\.Forms\|Vcl\.StdCtrls\|ShowMessage" Controller*.pas

# Model 引用�?UI �?Utils�?grep -rn "Vcl\.\|Utils" Model*.pas | grep -v "HelperLanguage"

# Utils 引用了业务层�?grep -rn "Model\|Controller\|Helper" Utils*.pas | grep -v "UtilsTypes\|UtilsEncoding"
```

---

## ViewMainCode.pas 拆分策略

3412 行是项目最大的技术债。不是禁止加代码，而是每次改动都要让它变小一点�?
### 可提取的功能�?
| 功能�?| 当前行数估计 | 目标去向 |
|---|---|---|
| 语言初始�?切换/UI更新 | ~300�?| 已有 HelperLanguage + ControllerLanguage，直接委�?|
| 目录历史管理 | ~100�?| 新建 HelperDirHiDeepDeepDeepDeepDeepStory 或合并进 ModelConfig |
| 文件网格刷新/更新 | ~200�?| HelperUI 已有部分能力，补�?|
| 编码树操�?| ~150�?| HelperUI.SetupEncodingList 已有，补�?|
| 日志缓冲 | ~50�?| 小功能，可留�?View |
| BOM 快捷操作 | ~80�?| 委托 ControllerEncoding |

### 拆分原则

- 每次提取一个功能块，提完能编译能跑
- 提取�?ViewMainCode 只做：创建组�?�?绑定事件 �?�?Controller/Helper �?刷新 UI
- 不追求完美分层，追求**每次改动后比改动前好一�?*

---

## 全局变量

### 现有全局变量

```delphi
// HelperLanguage.pas �?最需要消除的
var
  LanguageManager: TLanguageManager;

// ViewMainCode.pas �?Form 全局变量，VCL 标准模式，可接受
var
  Form1: TForm1;
```

### 规则

- `Form1: TForm1` �?VCL 惯例，保�?- `LanguageManager` 应改为通过构造函数注入，ControllerLanguage �?View 都不直接访问全局变量
- 新增代码禁止创建新的全局可变变量

---

## 配置管理

配置集中�?`ModelConfig.TAppConfig`。INI 文件有两个：
- `DeepCharset.ini` �?应用配置（编码、目录、BOM 开关）
- `ui.ini` �?窗口位置/大小

规则�?- 读写配置统一通过 `TAppConfig` 的方�?- 禁止�?ViewMainCode 里直�?`TIniFile.Create`

```bash
grep -rn "TIniFile\.Create" *.pas | grep -v "ModelConfig"
# 出现的地方应该迁移到 ModelConfig
```

---

## 日志

项目有两套日志：
1. `UtilsEncodingLogger.ILogger` �?结构化日志接口（Info/Warn/Error/Debug�?2. `TProc<string>` 回调 �?Controller/Helper 通过构造函数接�?
实际使用中两者混用。简化方向：
- 非底层模块统一�?`TProc<string>` 回调，由 View 传入
- Utils 内部可以�?ILogger
- 禁止 `OutputDebugString` 作为主要日志手段

---

## 异常处理

```delphi
// 最低要求：记录异常
except
  on E: Exception do
    Log('XXX failed: ' + E.Message);
end;

// 禁止�?except
except
  // ignore
end;
```

---

## Helper 层的定位

Helper 不是"放不进去的代�?。每�?Helper 有明确职责：

| 单元 | 职责 | 知道 UI�?|
|---|---|---|
| HelperFiles | 文件操作（遍历、检测、转换） | �?|
| HelperUI | UI 控件操作（Grid/TreeView 操作封装�?| 是（操作 VCL 控件�?|
| HelperLanguage | 国际化（加载语言、翻译） | �?|

HelperUI 是个特例 �?它操�?VCL 控件但不�?Form。它存在的意义是�?操作 TStringGrid �?�?这种�?UI 机械操作�?ViewMainCode 中抽出来。这是合理的�?
---

## 编码处理模块

### 检测器

所有检测器实现 `InterfacesEncoding.IEncodingDetector`�?- `DetectBuffer(Buffer)` / `DetectFile(FileName)` / `DetectStream(Stream)`
- 返回 `IEncodingDetectionResult`（Encoding + Confidence + HasBOM�?
### 转换�?
- `EncodingConverter_Improved` �?通用编码转换
- `UTF8BOMConverter_Improved` �?UTF-8 BOM 添加/移除
- 通过 `HelperFiles.TFileHelper` 统一调用

### 内存安全

- 大文件用流式处理，不一次�?LoadFromFile
- 临时文件通过 `UtilsTempFileSecurity` 管理
- 缓冲区复�?`UtilsBufferPool`

---

## 第三方库

| �?| 用�?| 备注 |
|---|---|---|
| SynEdit | 代码预览/语法高亮 | `D:\ProgramData\delphi\SynEdit-master` |
| JCL | 底层编码/流处�?| `Jcl*` 单元是项目修改版 |
| madExcept | 异常追踪 | 当前禁用（`{.$DEFINE USE_MADEXCEPT}`�?|

引入新库前先确认 `D:\ProgramData\delphi\` 下没有替代品�?
---

## 编译

```bash
# 64�?Debug
cmd /c "call \"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat\" && msbuild DeepCharset.dproj /p:Config=Debug /p:Platform=Win64"

# 输出: Win64\Debug\DeepCharset.exe
# 配置: Win64\Debug\ini\DeepCharset.ini
```

测试: `Tests/SelfTest_Encoding.dpr`, `Tests/Test_BoundaryCases.pas`, `Tests/Test_ConversionIntegrity.pas`

---

## 文件大小参�?
当前文件行数分布（Top 10）：

```
3412  ViewMainCode.pas          �?目标: 逐次拆分�?1500 以下
1810  EncodingConverter_Improved.pas  �?编码转换核心，合�?1428  JclEncodingUtils.pas      �?JCL 修改版，不动
 884  UtilsEncodingLogger.pas   �?可简�? 813  ChineseEncodingDetector_Improved.pas
 740  HelperUI.pas
 735  ViewSynEdit.pas
 720  EncodingAdapters.pas
 716  HelperFiles.pas
 706  JapaneseEncodingDetector_Improved.pas
```

新建文件目标 �?600 行。超过时考虑是否职责过多�?
---

## 提交规范

```
<类型>�?中文简�?

类型: feat | fix | refactor | docs | test | chore
```

每轮改动控制在可 review 的范围内。大重构分多次提交，每次能编译能跑�?
---

## AI 自检（修改代码前�?
1. 看目标文件的 `uses` �?确认不引入违规依�?2. 如果�?ViewMainCode �?改完后行数是否减少？至少不增�?3. 如果加新功能 �?是否应该放在 Controller �?Helper 而不�?View
4. except �?�?是否有日志记�?5. 编译 �?改完能编译通过
