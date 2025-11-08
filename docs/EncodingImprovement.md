# 编码检测与转换改进

本项目实现了改进的编码检测和转换功能，解决了UTF-8文件被错误检测为ANSI以及UTF-8到UTF-8+BOM转换问题等问题。

## 主要功能

1. **改进的UTF-8检测**：
   - 更精确的UTF-8序列验证
   - 基于多种特征的UTF-8置信度评分
   - 亚洲语言特征分析
   - 混合内容智能检测

2. **改进的BOM检测**：
   - 支持UTF-8、UTF-16LE/BE、UTF-32LE/BE的BOM检测
   - 提供BOM添加和移除功能

3. **改进的中文编码检测**：
   - 支持GBK、GB18030、Big5、GB2312编码检测
   - 基于字节特征和频率分析的置信度评分

4. **改进的编码转换**：
   - 支持各种编码之间的转换
   - 提供错误处理策略
   - 支持批量转换
   - 转换结果验证

5. **UTF-8 BOM转换**：
   - 专门的UTF-8 BOM添加和移除功能
   - 解决UTF-8到UTF-8+BOM转换问题

## 架构与数据流

### 核心模块架构

```
┌─────────────────────────────────────────────────────────────┐
│                    应用层 / UI 层                            │
│         (ViewMainCode.pas / 命令行工具)                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              EncodingConverter_Improved.pas                  │
│  - ConvertFile() / ConvertBuffer() / ConvertStream()        │
│  - GetCodePage() [带缓存]                                    │
│  - 快速路径优化 (同编码直通)                                 │
└────────┬────────────────────────────┬───────────────────────┘
         │                            │
         ▼                            ▼
┌──────────────────────┐    ┌──────────────────────────────┐
│  编码检测层           │    │  UTF-8 BOM 处理层             │
│                      │    │                              │
│ - BOM检测 (优化)     │    │ UTF8BOMConverter_Improved    │
│ - UTF-8检测          │    │ - CleanUTF8Artifacts()       │
│ - 中文编码检测        │    │ - 清理内嵌BOM与六字节序列     │
│ - 日韩编码检测        │    └──────────────────────────────┘
└──────────────────────┘
```

### 数据流说明

1. **输入阶段**
   - 读取源文件/流/缓冲区
   - BOM 检测（仅读取头部 4 字节，优化性能）
   - 编码推断（可选，根据 `DetectSourceEncoding` 标志）

2. **转换阶段**
   - 快速路径判断：同编码且非 UTF-8 → 直接复制
   - UTF-8 同编码 → 应用清理逻辑
   - 跨编码转换 → WinAPI `MultiByteToWideChar` / `WideCharToMultiByte`

3. **清理与规范化阶段**
   - 移除内嵌 BOM 片段 (`EF BB BF`)
   - 移除误编码六字节序列 (`C3 AF C2 BB C2 BF` 对应 "ï»¿")
   - 根据目标编码添加/移除首部 BOM

4. **输出阶段**
   - 建议：在相同环境（CPU/磁盘/杀软）下对比不同版本结果，避免外界因素干扰。

## 性能优化总结

本项目已实施以下性能优化措施：

1. **GetCodePage 缓存**：避免重复解析编码名称（32 项缓存槽位）
2. **BOM 检测优化**：`DetectBOMFromFile()` 仅读取文件头部 4 字节，而非全文
3. **快速路径**：同编码且非 UTF-8 时直接复制，跳过转换流程
4. **UTF-8 同编码优化**：仅应用清理逻辑，避免不必要的 WinAPI 调用
5. **内存分配策略**：预分配缓冲区，减少动态扩展开销

实测效果（基于 `/perf` 模式）：
- 关键用例集（/crit）：约 200-500ms（取决于硬件与样本规模）
- 跨码页回归（/cp）：约 100-300ms
- 快速冒烟测试（/quick）：< 10s（可选）

## 文件说明

- `UtilsEncodingTypes.pas`：编码类型定义
- `UtilsEncodingBOM_Improved.pas`：改进的BOM检测（优化：仅读取文件头部）
- `UtilsEncodingUTF8Detector_Improved.pas`：改进的UTF-8检测
- `ChineseEncodingDetector_Improved.pas`：改进的中文编码检测
- `UTF8BOMConverter_Improved.pas`：改进的UTF-8 BOM转换与清理
- `EncodingConverter_Improved.pas`：改进的编码转换（带缓存与快速路径）
- `Tests/SelfTest_Encoding.dpr`：自测主程序
- `tests_run.bat`：自测脚本（支持 /crit /cp /quick /perf /openlogs）

## 使用方法

### 检测文件编码

```delphi
// 检测文件编码
var
  EncodingName: string;
begin
  // 使用UTF-8检测器
  var UTF8Result := TUTF8EncodingDetector_Improved.DetectFile('example.txt');
  if UTF8Result.IsUTF8 then
    EncodingName := ENCODING_UTF8
  else
  begin
    // 使用中文编码检测器
    var ChineseResult := TChineseEncodingDetector_Improved.DetectFile('example.txt');
    EncodingName := ChineseResult.Encoding;
  end;
  
  ShowMessage('检测到的编码: ' + EncodingName);
end;
```

### 转换文件编码

```delphi
// 转换文件编码
var
  Options: TEncodingConversionOptions;
  Result: TEncodingConversionResult;
begin
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  
  // 转换文件
  Result := TEncodingConverter_Improved.ConvertFile(
    'source.txt',
    'target.txt',
    ENCODING_GBK,
    ENCODING_UTF8_BOM,
    Options
  );
  
  if Result.Success then
    ShowMessage('转换成功!')
  else
    ShowMessage('转换失败: ' + IntToStr(Result.ErrorCount) + ' 个错误');
end;
```

### 添加或移除UTF-8 BOM

```delphi
// 添加UTF-8 BOM
var
  Result: TUTF8BOMConversionResult;
begin
  Result := TUTF8BOMConverter_Improved.AddBOMToUTF8File(
    'source.txt',
    'target.txt'
  );
  
  if Result.Success then
    ShowMessage('添加BOM成功!')
  else
    ShowMessage('添加BOM失败: ' + Result.ErrorMessage);
end;

// 移除UTF-8 BOM
var
  Result: TUTF8BOMConversionResult;
begin
  Result := TUTF8BOMConverter_Improved.RemoveBOMFromUTF8File(
    'source.txt',
    'target.txt'
  );
  
  if Result.Success then
    ShowMessage('移除BOM成功!')
  else
    ShowMessage('移除BOM失败: ' + Result.ErrorMessage);
end;
```

### 批量转换文件

```delphi
// 批量转换文件
var
  FileNames: TArray<string>;
  Options: TEncodingConversionOptions;
  Results: TArray<TEncodingConversionResult>;
begin
  // 设置文件名
  SetLength(FileNames, 3);
  FileNames[0] := 'file1.txt';
  FileNames[1] := 'file2.txt';
  FileNames[2] := 'file3.txt';
  
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  
  // 批量转换
  Results := TEncodingConverter_Improved.BatchConvertFiles(
    FileNames,
    'output',
    ENCODING_UTF8_BOM,
    Options
  );
  
  // 检查结果
  var SuccessCount := 0;
  for var i := 0 to High(Results) do
  begin
    if Results[i].Success then
      Inc(SuccessCount);
  end;
  
  ShowMessage(Format('批量转换完成: %d/%d 成功', [SuccessCount, Length(FileNames)]));
end;
```

## 测试

项目包含两个测试程序：

1. `TestEncodingMain.dpr`：测试编码检测和转换功能
2. `TestEncodingIntegrationMain.dpr`：测试编码集成功能

运行测试程序可以验证编码检测和转换功能的正确性。

## 注意事项

- 编码检测基于统计和特征分析，对于某些特殊情况可能不准确
- 对于小文件或纯ASCII文件，编码检测可能不够准确
- 转换过程中可能会出现字符丢失或替换，特别是在不兼容的编码之间转换时

## 内嵌 BOM 与六字节序列清理策略

为解决 UTF-8 转换后仍残留“内嵌 BOM 片段”与“误作 ANSI 后再转 UTF-8 产生的六字节序列（对应字符“ï»¿”）”的问题，新增统一清理策略：

- 清理对象：
  - UTF-8 BOM 片段：`EF BB BF`
  - 误编码六字节序列：`C3 AF C2 BB C2 BF`（对应“ï»¿”）

- 清理策略：
  - 目标为 `UTF-8（无 BOM）`：移除所有位置的 `EF BB BF` 与 `C3 AF C2 BB C2 BF`
  - 目标为 `UTF-8 with BOM`：确保首部“仅有一个 BOM”，并从索引 3 开始清理所有内部 `EF BB BF` 与 `C3 AF C2 BB C2 BF`

- 实现位置：
  - `EncodingConverter_Improved.pas`
    - `TEncodingConverter_Improved.ConvertBuffer()`：同码页直通也进行清理；UTF-8/UTF-8 with BOM 目标均会规范化结果。
    - `TEncodingConverter_Improved.ConvertFile()`：写盘前进行最终一次规范化清理，双保险。
  - `UTF8BOMConverter_Improved.pas`
    - 新增 `class function CleanUTF8Artifacts(const Buffer: TBytes; EnsureLeadingBOM: Boolean): TBytes` 作为统一清理函数。
    - 在以下路径写出前调用：
      - `AddBOMToUTF8File`、`ConvertToUTF8WithBOM`：`EnsureLeadingBOM=True`
      - `RemoveBOMFromUTF8File`、`ConvertToUTF8WithoutBOM`：`EnsureLeadingBOM=False`

通过上述策略，解决了真实项目中出现的 `?unit` 等由内嵌 BOM 导致的乱码问题，并杜绝“ï»¿”六字节残留。

## 关键自测项与结果

自测入口：`Tests/SelfTest_Encoding.dpr` 中的 `RunCriticalUTF8BOMTests`，构建/运行脚本：`tests_run.bat`。

- 关键专项：
  - [47] 内嵌 BOM 清理
    - `UTF-8（无 BOM）`：确保输出无任何 `EF BB BF`
    - `UTF-8 with BOM`：仅首部保留一个 `EF BB BF`，内部无 BOM
  - [47b] 误编码六字节序列清理
    - 清理 `C3 AF C2 BB C2 BF` 于 `UTF-8（无 BOM）` 与 `UTF-8 with BOM`
  - [UF] 用户文件专项 + [UF-CHK] 内部扫描
    - 对 `tmp_tests/Frame01Intro.pas` 转换产物进行内部扫描，确保无内部 `EF BB BF` 与 `C3 AF C2 BB C2 BF`

- 最新日志（节选 `tmp_tests/selftest_log.txt`）：

```
[47] Inner-BOM cleaned for UTF8(noBOM): PASS
[47] Only leading BOM for UTF8(BOM): PASS
[UF-CHK] noBOM internal scan: PASS
[UF-CHK] BOM internal scan: PASS
[47b] 6bytes cleaned UTF8(noBOM): PASS
[47b] 6bytes cleaned UTF8(BOM): PASS
```

上述结果表明：关键用例均通过，内部 BOM 片段与误编码六字节序列已被彻底清理，带 BOM 版本保证首部仅有一个 BOM。
