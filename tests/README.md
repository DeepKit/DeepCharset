# JCL 扩展编码支持工具

本工具扩展了JEDI Code Library (JCL)的编码支持能力，通过优化的转换测试程序，实现了对多种编码格式的支持，特别是单向转换（从UTF-8到其他编码，以及从其他编码到UTF-8）。

## 支持的编码列表

本工具支持以下编码格式：

### Unicode 编码系列
- UTF-8（带BOM和不带BOM）
- UTF-16LE（Unicode Little Endian）
- UTF-16BE（Unicode Big Endian）
- UTF-32LE（Unicode 32-bit Little Endian）
- UTF-32BE（Unicode 32-bit Big Endian）

### 中文编码
- GBK/GB2312（简体中文，代码页936）
- BIG5（繁体中文，代码页950）
- GB18030（简体中文扩展，代码页54936）

### 日文编码
- Shift-JIS（日文，代码页932）
- EUC-JP（日文扩展Unix编码，代码页20932）
- ISO-2022-JP（日文JIS，代码页50220）
- ISO-2022-JP-MS（日文JIS-Allow 1 byte Kana，代码页50221）
- ISO-2022-JP-JISX0201-1989（日文JIS-Allow 1 byte Kana - SO/SI，代码页50222）

### 韩文编码
- EUC-KR（韩文扩展Unix编码，代码页949）
- JOHAB（韩文Johab，代码页1361）
- ISO-2022-KR（韩文ISO，代码页50225）

### Windows 编码系列
- Windows-1250（中欧，代码页1250）
- Windows-1251（西里尔文，代码页1251）
- Windows-1252（西欧，代码页1252）
- Windows-1253（希腊文，代码页1253）
- Windows-1254（土耳其文，代码页1254）
- Windows-1255（希伯来文，代码页1255）
- Windows-1256（阿拉伯文，代码页1256）
- Windows-1257（波罗的海文，代码页1257）
- Windows-1258（越南文，代码页1258）
- Windows-874（泰文，代码页874）

### ISO 编码系列
- ISO-8859-1（拉丁文1，西欧，代码页28591）
- ISO-8859-2（拉丁文2，中欧，代码页28592）
- ISO-8859-3（拉丁文3，南欧，代码页28593）
- ISO-8859-4（拉丁文4，北欧，代码页28594）
- ISO-8859-5（拉丁文/西里尔文，代码页28595）
- ISO-8859-6（拉丁文/阿拉伯文，代码页28596）
- ISO-8859-7（拉丁文/希腊文，代码页28597）
- ISO-8859-8（拉丁文/希伯来文，代码页28598）
- ISO-8859-9（拉丁文5，土耳其文，代码页28599）
- ISO-8859-13（拉丁文7，波罗的海文，代码页28603）
- ISO-8859-15（拉丁文9，西欧带欧元符号，代码页28605）

### DOS/OEM 编码
- IBM437/CP437（美国，代码页437）
- IBM850/CP850（西欧，代码页850）
- IBM852/CP852（中欧，代码页852）
- IBM855/CP855（OEM西里尔文，代码页855）
- IBM857/CP857（土耳其文，代码页857）
- IBM858/CP858（多语言拉丁文1+欧元符号，代码页858）
- IBM860/CP860（葡萄牙文，代码页860）
- IBM861/CP861（冰岛文，代码页861）
- IBM862/CP862（希伯来文，代码页862）
- IBM863/CP863（加拿大法语，代码页863）
- IBM864/CP864（阿拉伯文，代码页864）
- IBM865/CP865（北欧，代码页865）
- IBM866/CP866（西里尔文，代码页866）
- IBM869/CP869（现代希腊文，代码页869）

### 其他区域编码
- KOI8-R（俄文，代码页20866）
- KOI8-U（乌克兰文，代码页21866）
- Macintosh/MAC（苹果Mac Roman，代码页10000）
- MAC-CYRILLIC（苹果Mac西里尔文，代码页10007）
- X-IA5/ASCII（西欧IA5/ASCII，代码页20105）
- X-ISCII-DE（ISCII梵文，代码页57002）
- X-ISCII-BE（ISCII孟加拉语，代码页57003）
- X-ISCII-TA（ISCII泰米尔语，代码页57004）
- X-ISCII-TE（ISCII泰卢固语，代码页57005）
- X-ISCII-AS（ISCII阿萨姆语，代码页57006）
- X-ISCII-OR（ISCII奥里亚语，代码页57007）
- X-ISCII-KN（ISCII卡纳达语，代码页57008）
- X-ISCII-MA（ISCII马拉雅拉姆语，代码页57009）
- X-ISCII-GU（ISCII古吉拉特语，代码页57010）
- X-ISCII-PA（ISCII旁遮普语，代码页57011）

## 使用方法

### 单向转换测试
```
conversion_roundtrip_test.exe oneway
```
这将执行两种测试：
1. 从UTF-8到各种非Unicode编码的转换测试
2. 从各种非Unicode编码到UTF-8的转换测试

结果将保存在`oneway_conversion_tests.md`文件中。

### 往返转换测试
```
conversion_roundtrip_test.exe roundtrip
```
这将测试从每种非UTF编码到UTF格式的转换，然后再转回原始编码，验证内容一致性。

结果将保存在`roundtrip_tests.md`文件中。

## 支持说明

- **完全支持**：编码检测准确，转换无损，往返转换内容保持一致
- **部分支持**：仅支持单向转换，或在往返转换中可能有字符丢失
- **基本支持**：仅测试，可能有未知问题

### 字符集覆盖范围注意事项

1. **Unicode编码**（UTF-8、UTF-16、UTF-32）能够表示所有Unicode字符集字符，适用于任何语言、符号的存储和传输。

2. **非Unicode编码**只能表示其设计支持的特定字符子集：
   - 中文编码（如GBK）主要支持中文字符
   - 日文编码（如Shift-JIS）主要支持日文字符
   - 韩文编码（如EUC-KR）主要支持韩文字符
   - Windows编码系列和ISO编码系列支持各自区域的字符集

从Unicode转换到非Unicode编码时，如果遇到目标编码不支持的字符，将会：
- 替换为可用的近似字符（如问号或特定替代字符）
- 或者转换失败并报错

## 测试文件说明

为了测试各种编码格式，请在`sample_files`目录下准备包含不同语言和字符的测试文件。建议包含：

- 纯ASCII文本
- 中文文本（简体和繁体）
- 日文文本
- 韩文文本
- 西欧语言文本
- 东欧语言文本
- 俄文文本
- 希伯来文或阿拉伯文
- 混合多语言的文本

## 环境要求

- Delphi 编译器（建议XE7或更新版本）
- JEDI Code Library (JCL)
- Windows 操作系统（对于多语言支持，建议使用Windows 10或更新版本）

## 限制说明

1. 某些编码可能需要系统对应的语言包支持
2. 转换结果的准确性取决于操作系统对相应代码页的支持
3. 某些编码（如ISCII系列）在标准Windows中的支持可能有限
4. 在往返转换中，非Unicode编码之间的相互转换可能导致不可恢复的字符丢失

## 许可声明

本工具基于JEDI Code Library (JCL)开发，遵循与JCL相同的开源许可证条款。

## 在其他Delphi项目中集成JCL转码功能

本节提供如何在您自己的Delphi项目中集成和复用JCL编码检测与转换功能的详细指南。

### 准备工作

1. **确保已安装JCL库**
   - 从[JEDI Code Library官网](https://github.com/project-jedi/jcl)下载最新版JCL
   - 按照安装说明完成JCL在Delphi中的安装
   - 确认JCL库的包在Delphi IDE中可见

2. **将必要的单元添加到您的项目中**
   - 复制以下关键单元到您的项目目录或确保它们在搜索路径中:
     - `JclStrings.pas` - 字符串处理核心函数
     - `JclStringConversions.pas` - 编码转换功能
     - `JclFileUtils.pas` - 文件操作相关函数
     - `JclStreams.pas` - 流操作函数
     - `JclBOM.pas` - BOM检测相关函数

### 集成编码检测功能

将以下代码复制到您的项目中以添加编码检测功能：

```pascal
// 检测文件编码
function DetectFileEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
  BOMLen: Integer;
  BOMType: TJclBOMType;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := 'Unknown';
  
  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 首先检测BOM
    BOMType := DetectBOM(FileStream);
    BOMLen := GetBOMLength(BOMType);
    
    // 根据BOM返回编码
    Result := 'Unknown';
    if BOMType = bomAnsi then
      Result := 'ANSI'
    else if BOMType = bomUTF8 then
      Result := 'UTF-8 with BOM'
    else if BOMType = bomUTF16LE then
      Result := 'UTF-16LE'
    else if BOMType = bomUTF16BE then
      Result := 'UTF-16BE'
    else if BOMType = bomUTF32LE then
      Result := 'UTF-32LE'
    else if BOMType = bomUTF32BE then
      Result := 'UTF-32BE';
    
    // 无BOM，尝试检测内容
    if Result = 'Unknown' then
    begin
      FileStream.Position := 0;
      var FileSize: Int64 := FileStream.Size;
      var MaxSize: Int64 := 4096;
      var ReadSize: Integer;
      if FileSize < MaxSize then
        ReadSize := Integer(FileSize)
      else
        ReadSize := 4096;
      SetLength(Buffer, ReadSize); // 读取前4KB进行分析
      if ReadSize > 0 then
        FileStream.Read(Buffer[0], ReadSize);
      BytesRead := ReadSize;
      
      // 尝试检测UTF-8
      if BytesRead > 0 then
      begin
        if IsUTF8Valid(Buffer, 0, BytesRead) then
        begin
          Result := 'UTF-8 without BOM';
          Exit;
        end;
      end;
      
      // 尝试其他编码
      // 检查是否符合GB2312/GBK/GB18030
      if BytesRead > 1 then
      begin
        if IsGBKString(Buffer, BytesRead) then
        begin
          Result := 'GBK/GB2312';
          Exit;
        end;
      end;
      
      // 默认假设为ANSI/CP系列
      Result := 'ANSI (CP' + IntToStr(GetACP) + ')';
    end;
  finally
    FileStream.Free;
  end;
end;
```

### 集成编码转换功能

以下是用于文件编码转换的关键函数：

```pascal
// 获取编码的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperEncName: string;
begin
  UpperEncName := UpperCase(EncodingName);
  
  // Unicode编码
  if (UpperEncName = 'UTF-8') or (UpperEncName = 'UTF8') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-8-BOM') or (UpperEncName = 'UTF8-BOM') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-16LE') or (UpperEncName = 'UTF16LE') or (UpperEncName = 'UNICODE') then
    Result := 1200
  else if (UpperEncName = 'UTF-16BE') or (UpperEncName = 'UTF16BE') then
    Result := 1201
  else if (UpperEncName = 'UTF-32LE') or (UpperEncName = 'UTF32LE') then
    Result := 12000
  else if (UpperEncName = 'UTF-32BE') or (UpperEncName = 'UTF32BE') then
    Result := 12001
  
  // 中文编码
  else if (UpperEncName = 'GBK') or (UpperEncName = 'GB2312') or (UpperEncName = '936') then
    Result := 936
  else if (UpperEncName = 'BIG5') or (UpperEncName = '950') then
    Result := 950
  else if UpperEncName = 'GB18030' then
    Result := 54936
  
  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了
  
  // 未知的编码
  else
    Result := GetACP(); // 返回系统默认代码页
end;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string; SourceCodePage, TargetCodePage: Integer): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString, TargetString: string;
begin
  Result := False;
  
  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;
    
    // 从源编码转换到Unicode字符串
    SourceString := TEncoding.GetEncoding(SourceCodePage).GetString(SourceBytes);
    
    // 从Unicode字符串转换到目标编码
    TargetBytes := TEncoding.GetEncoding(TargetCodePage).GetBytes(SourceString);
    
    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFileName, fmCreate);
    try
      if Length(TargetBytes) > 0 then
        TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
      Result := True;
    finally
      TargetStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 处理错误
      Result := False;
    end;
  end;
end;
```

### 示例用法

下面是在您的应用程序中使用上述功能的示例：

```pascal
procedure TForm1.btnDetectEncodingClick(Sender: TObject);
var
  FileName: string;
  EncodingName: string;
begin
  if OpenDialog1.Execute then
  begin
    FileName := OpenDialog1.FileName;
    EncodingName := DetectFileEncoding(FileName);
    ShowMessage('文件 "' + ExtractFileName(FileName) + '" 的编码是: ' + EncodingName);
  end;
end;

procedure TForm1.btnConvertClick(Sender: TObject);
var
  SourceFile, TargetFile: string;
  SourceCP, TargetCP: Integer;
begin
  if OpenDialog1.Execute then
  begin
    SourceFile := OpenDialog1.FileName;
    if SaveDialog1.Execute then
    begin
      TargetFile := SaveDialog1.FileName;
      
      // 获取代码页
      SourceCP := GetEncodingCodePage(cmbSourceEncoding.Text);
      TargetCP := GetEncodingCodePage(cmbTargetEncoding.Text);
      
      if ConvertFile(SourceFile, TargetFile, SourceCP, TargetCP) then
        ShowMessage('转换成功!')
      else
        ShowMessage('转换失败!');
    end;
  end;
end;
```

### 常见问题解决

1. **代码页不支持问题**
   - 确保您使用的代码页在当前Windows系统中受支持
   - 使用`IsValidCodePage()`函数检查代码页有效性
   - 对于不确定是否支持的代码页，建议先尝试在小文件上进行测试

2. **字符转换问题**
   - 当转换不同字符集范围的编码时（如Unicode到非Unicode），可能会出现字符丢失
   - 建议添加代码检测不可转换字符，并为用户提供警告
   - 对于多语言文本，始终推荐使用UTF-8编码

3. **性能优化**
   - 对于大文件，考虑分块读取和处理，避免一次性加载整个文件到内存
   - 可以实现进度报告机制以提升用户体验

### 完整项目示例

为方便集成，我们提供了一个[示例项目](https://github.com/yourusername/JclEncodingTools)，展示了如何在实际应用中使用JCL编码检测和转换功能。您可以直接从该项目中复制必要的代码到您自己的项目中。

### 依赖性管理

建议在您的项目中明确指定JCL的版本依赖：

```pascal
{$IFDEF VER340} // Delphi 10.4 Sydney
  {$DEFINE JCL_VERSION_2_8_0_OR_HIGHER}
{$ENDIF}

{$IFDEF JCL_VERSION_2_8_0_OR_HIGHER}
  // 使用新版JCL功能
{$ELSE}
  // 使用兼容旧版JCL的替代实现
{$ENDIF}
```

### 许可说明

在您的项目中使用本代码时，请确保遵守JCL的开源许可条款。 