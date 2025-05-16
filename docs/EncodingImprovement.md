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

## 文件说明

- `UtilsEncodingTypes.pas`：编码类型定义
- `UtilsEncodingBOM_Improved.pas`：改进的BOM检测
- `UtilsEncodingUTF8Detector_Improved.pas`：改进的UTF-8检测
- `ChineseEncodingDetector_Improved.pas`：改进的中文编码检测
- `UTF8BOMConverter_Improved.pas`：改进的UTF-8 BOM转换
- `EncodingConverter_Improved.pas`：改进的编码转换
- `TestEncodingDetection.pas`：编码检测测试
- `TestEncodingIntegration.pas`：编码集成测试
- `TestEncodingMain.dpr`：测试主程序
- `TestEncodingIntegrationMain.dpr`：集成测试主程序
- `EncodingImprovement.groupproj`：项目组文件

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
