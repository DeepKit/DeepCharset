# 编码检测与转换工具

## 概述

本工具提供了强大的文件编码检测和转换功能，支持多种编码格式，包括UTF-8、UTF-16、UTF-32、GBK、Big5等。工具的主要特点包括：

1. **准确的编码检测**：使用多种算法和启发式规则，提高编码检测的准确性
2. **支持多种编码**：支持国际标准编码和亚洲语言编码
3. **BOM处理**：支持检测、添加和移除BOM（字节顺序标记）
4. **批量转换**：支持批量文件编码转换
5. **详细日志**：提供详细的操作日志和错误信息

## 支持的编码

- **国际标准**：UTF-8、UTF-16 LE/BE、UTF-32 LE/BE、ASCII、ANSI
- **中文**：GBK、GB2312、GB18030、Big5
- **日文**：Shift-JIS、EUC-JP、ISO-2022-JP
- **韩文**：EUC-KR、ISO-2022-KR

## 使用方法

### 编码检测

```pascal
uses
  EncodingUtils;

var
  Result: TEncodingDetectionResult;
begin
  // 检测文件编码
  Result := TEncodingUtils.DetectFileEncoding('example.txt');
  
  // 输出检测结果
  WriteLn('编码: ', Result.Encoding);
  WriteLn('是否有BOM: ', BoolToStr(Result.HasBOM, True));
  WriteLn('置信度: ', Result.Confidence:0.2);
  WriteLn('检测方法: ', Result.DetectionMethod);
end;
```

### 编码转换

```pascal
uses
  EncodingUtils;

var
  Success: Boolean;
begin
  // 转换文件编码（例如：从ANSI转换为UTF-8带BOM）
  Success := TEncodingUtils.ConvertFileEncoding(
    'source.txt',      // 源文件
    'target.txt',      // 目标文件
    ENCODING_ANSI,     // 源编码
    ENCODING_UTF8,     // 目标编码
    True               // 添加BOM
  );
  
  if Success then
    WriteLn('转换成功')
  else
    WriteLn('转换失败: ', TEncodingUtils.GetLastError);
end;
```

### 批量转换

```pascal
uses
  EncodingUtils;

var
  FileNames: TArray<string>;
  SuccessCount: Integer;
begin
  // 设置要转换的文件
  FileNames := ['file1.txt', 'file2.txt', 'file3.txt'];
  
  // 批量转换文件编码
  SuccessCount := TEncodingUtils.BatchConvertFileEncoding(
    FileNames,         // 文件名数组
    'C:\SourceDir',    // 源目录
    'C:\TargetDir',    // 目标目录
    ENCODING_UNKNOWN,  // 源编码（ENCODING_UNKNOWN表示自动检测）
    ENCODING_UTF8,     // 目标编码
    True               // 添加BOM
  );
  
  WriteLn(Format('成功转换 %d / %d 个文件', [SuccessCount, Length(FileNames)]));
end;
```

### BOM操作

```pascal
uses
  EncodingUtils;

var
  Success: Boolean;
begin
  // 添加BOM到文件
  Success := TEncodingUtils.AddBOMToFile('example.txt', ENCODING_UTF8);
  
  if Success then
    WriteLn('添加BOM成功')
  else
    WriteLn('添加BOM失败: ', TEncodingUtils.GetLastError);
    
  // 移除文件的BOM
  Success := TEncodingUtils.RemoveBOMFromFile('example.txt');
  
  if Success then
    WriteLn('移除BOM成功')
  else
    WriteLn('移除BOM失败: ', TEncodingUtils.GetLastError);
end;
```

### 日志回调

```pascal
uses
  EncodingUtils;

procedure LogCallback(const Msg: string);
begin
  WriteLn(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Msg);
end;

begin
  // 设置日志回调函数
  TEncodingUtils.SetLogCallback(LogCallback);
  
  // 执行操作...
end;
```

## 技术细节

### 编码检测算法

编码检测使用多种算法和启发式规则，包括：

1. **BOM检测**：首先检测文件是否包含BOM（字节顺序标记）
2. **UTF-8有效性检测**：检查UTF-8多字节序列的有效性
3. **亚洲语言字符检测**：检测中文、日文、韩文等亚洲语言字符
4. **统计分析**：分析字节分布和模式
5. **文件类型判断**：根据文件扩展名判断可能的编码
6. **系统语言环境判断**：根据系统语言环境判断可能的编码

### 编码转换流程

编码转换的基本流程如下：

1. **检测源文件编码**：如果源编码为ENCODING_UNKNOWN，则自动检测
2. **读取源文件内容**：读取源文件的字节内容
3. **移除BOM**：如果源文件有BOM，则移除
4. **转换编码**：将内容从源编码转换为目标编码
5. **添加BOM**：如果需要，添加目标编码的BOM
6. **写入目标文件**：将转换后的内容写入目标文件

## 注意事项

1. 编码检测不是100%准确的，特别是对于短文本或混合编码的文件
2. 对于二进制文件，工具会自动跳过处理
3. 转换过程中可能会丢失一些不支持的字符
4. 建议在转换前备份重要文件

## 测试

工具包含一个完整的测试套件，可以通过运行EncodingUtilsTest.dpr项目来测试功能。测试结果会保存在TestResults.log文件中。
