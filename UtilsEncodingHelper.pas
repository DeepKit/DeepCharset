unit UtilsEncodingHelper;

{
  通用编码转换辅助单元（无 JCL 依赖）
  - 提供 UTF-8/UTF-16/ANSI 之间的高效转换
  - 基于 WinAPI（MultiByteToWideChar / WideCharToMultiByte）实现
}

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  /// 批量文件转换进度回调
  /// </summary>
  TBatchConversionProgressProc = reference to procedure(const CurrentFile: string; Current, Total: Integer; var Cancel: Boolean);

  /// <summary>
  /// 批量文件转换结果
  /// </summary>
  TBatchConversionResult = record
    TotalFiles: Integer;
    SuccessCount: Integer;
    FailedCount: Integer;
    SkippedCount: Integer;
    FailedFiles: TArray<string>;
  end;

  /// <summary>
  /// 编码转换辅助类（无第三方依赖）
  /// </summary>
  TEncodingHelper = class
  public
    /// <summary>
    /// 尝试使用快速路径进行编码转换（SourceCodePage -> TargetCodePage）
    /// 成功时返回 True，并将结果写入 OutputBuffer；否则返回 False。
    /// </summary>
    class function TryConvertFast(const Buffer: TBytes;
      SourceCodePage, TargetCodePage: Integer;
      out OutputBuffer: TBytes): Boolean;

    /// <summary>UTF-8 转 Unicode 字符串</summary>
    class function UTF8ToUnicode(const Buffer: TBytes): UnicodeString;

    /// <summary>Unicode 字符串转 UTF-8</summary>
    class function UnicodeToUTF8(const Str: UnicodeString): TBytes;

    /// <summary>ANSI 转 Unicode</summary>
    class function AnsiToUnicode(const Buffer: TBytes; CodePage: Integer): UnicodeString;

    /// <summary>Unicode 转 ANSI</summary>
    class function UnicodeToAnsi(const Str: UnicodeString; CodePage: Integer): TBytes;

    /// <summary>
    /// 批量转换目录下的文件
    /// </summary>
    class function BatchConvertFiles(
      const SourceDir: string;
      const FilePattern: string;
      const SourceEncoding, TargetEncoding: string;
      Recursive: Boolean;
      const ProgressProc: TBatchConversionProgressProc = nil): TBatchConversionResult;

    /// <summary>
    /// 批量转换指定文件列表
    /// </summary>
    class function BatchConvertFileList(
      const FileList: TArray<string>;
      const SourceEncoding, TargetEncoding: string;
      const ProgressProc: TBatchConversionProgressProc = nil): TBatchConversionResult;
  end;

implementation

uses
  Winapi.Windows, System.IOUtils, EncodingConverter_Improved, System.Masks;

{ TEncodingHelper }

class function TEncodingHelper.TryConvertFast(const Buffer: TBytes;
  SourceCodePage, TargetCodePage: Integer; out OutputBuffer: TBytes): Boolean;
var
  WideStr: UnicodeString;
begin
  Result := False;
  SetLength(OutputBuffer, 0);

  if Length(Buffer) = 0 then
  begin
    Result := True;
    Exit;
  end;

  // 同一代码页的情况（包括 UTF-16/UTF-32 等），直接透传缓冲区，由上层负责 BOM 等规范化
  if SourceCodePage = TargetCodePage then
  begin
    OutputBuffer := Copy(Buffer);
    Result := True;
    Exit;
  end;

  try
    // UTF-8 -> UTF-16 (CP 1200)
    if (SourceCodePage = CP_UTF8) and (TargetCodePage = 1200) then
    begin
      WideStr := UTF8ToUnicode(Buffer);
      SetLength(OutputBuffer, Length(WideStr) * 2);
      if Length(WideStr) > 0 then
        Move(WideStr[1], OutputBuffer[0], Length(OutputBuffer));
      Result := True;
      Exit;
    end;

    // UTF-16 (CP 1200) -> UTF-8
    if (SourceCodePage = 1200) and (TargetCodePage = CP_UTF8) then
    begin
      SetLength(WideStr, Length(Buffer) div 2);
      if Length(WideStr) > 0 then
        Move(Buffer[0], WideStr[1], Length(Buffer));
      OutputBuffer := UnicodeToUTF8(WideStr);
      Result := True;
      Exit;
    end;

    // 通用路径：Source -> Unicode -> Target
    if SourceCodePage = CP_UTF8 then
      WideStr := UTF8ToUnicode(Buffer)
    else if SourceCodePage = 1200 then
    begin
      SetLength(WideStr, Length(Buffer) div 2);
      if Length(WideStr) > 0 then
        Move(Buffer[0], WideStr[1], Length(Buffer));
    end
    else
      WideStr := AnsiToUnicode(Buffer, SourceCodePage);

    if TargetCodePage = CP_UTF8 then
      OutputBuffer := UnicodeToUTF8(WideStr)
    else if TargetCodePage = 1200 then
    begin
      SetLength(OutputBuffer, Length(WideStr) * 2);
      if Length(WideStr) > 0 then
        Move(WideStr[1], OutputBuffer[0], Length(OutputBuffer));
    end
    else
      OutputBuffer := UnicodeToAnsi(WideStr, TargetCodePage);

    Result := True;
  except
    Result := False;
  end;
end;

class function TEncodingHelper.UTF8ToUnicode(const Buffer: TBytes): UnicodeString;
var
  Len: Integer;
begin
  if Length(Buffer) = 0 then
  begin
    Result := '';
    Exit;
  end;

  Len := MultiByteToWideChar(CP_UTF8, 0, @Buffer[0], Length(Buffer), nil, 0);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    MultiByteToWideChar(CP_UTF8, 0, @Buffer[0], Length(Buffer), PWideChar(Result), Len);
  end
  else
    Result := '';
end;

class function TEncodingHelper.UnicodeToUTF8(const Str: UnicodeString): TBytes;
var
  Len: Integer;
begin
  if Length(Str) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  Len := WideCharToMultiByte(CP_UTF8, 0, PWideChar(Str), Length(Str), nil, 0, nil, nil);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    WideCharToMultiByte(CP_UTF8, 0, PWideChar(Str), Length(Str), @Result[0], Len, nil, nil);
  end
  else
    SetLength(Result, 0);
end;

class function TEncodingHelper.AnsiToUnicode(const Buffer: TBytes;
  CodePage: Integer): UnicodeString;
var
  Len: Integer;
  CharCount, i: Integer;
  P: PByte;
  W: Word;
begin
  if Length(Buffer) = 0 then
  begin
    Result := '';
    Exit;
  end;

  // 专门处理 UTF-16LE/UTF-16BE，避免依赖 MultiByteToWideChar 对 1200/1201 的支持差异
  if (CodePage = 1200) or (CodePage = 1201) then
  begin
    CharCount := Length(Buffer) div SizeOf(WideChar);
    if CharCount <= 0 then
    begin
      Result := '';
      Exit;
    end;

    SetLength(Result, CharCount);
    P := @Buffer[0];
    for i := 0 to CharCount - 1 do
    begin
      if CodePage = 1200 then
        // UTF-16LE: 低字节在前
        W := Word(P[0] or (P[1] shl 8))
      else
        // UTF-16BE: 高字节在前
        W := Word((P[0] shl 8) or P[1]);
      Result[i+1] := WideChar(W);
      Inc(P, 2);
    end;
    Exit;
  end;

  // 专门处理 UTF-32LE/UTF-32BE（项目内 UTF-32 文件，每个 32bit 低 16bit 存实际字符）
  if (CodePage = 12000) or (CodePage = 12001) then
  begin
    CharCount := Length(Buffer) div 4;
    if CharCount <= 0 then
    begin
      Result := '';
      Exit;
    end;

    SetLength(Result, CharCount);
    P := @Buffer[0];
    for i := 0 to CharCount - 1 do
    begin
      if CodePage = 12000 then
        // UTF-32LE: 低两个字节是 UTF-16 单元
        W := Word(P[0] or (P[1] shl 8))
      else
        // UTF-32BE: 高两个字节承载 UTF-16 单元
        W := Word((P[2] shl 8) or P[3]);
      Result[i+1] := WideChar(W);
      Inc(P, 4);
    end;
    Exit;
  end;

  // 其他代码页仍然走 MultiByteToWideChar
  Len := MultiByteToWideChar(CodePage, 0, @Buffer[0], Length(Buffer), nil, 0);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    MultiByteToWideChar(CodePage, 0, @Buffer[0], Length(Buffer), PWideChar(Result), Len);
  end
  else
    Result := '';
end;

class function TEncodingHelper.UnicodeToAnsi(const Str: UnicodeString;
  CodePage: Integer): TBytes;
var
  Len: Integer;
begin
  if Length(Str) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  Len := WideCharToMultiByte(CodePage, 0, PWideChar(Str), Length(Str), nil, 0, nil, nil);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    WideCharToMultiByte(CodePage, 0, PWideChar(Str), Length(Str), @Result[0], Len, nil, nil);
  end
  else
    SetLength(Result, 0);
end;

class function TEncodingHelper.BatchConvertFiles(
  const SourceDir: string;
  const FilePattern: string;
  const SourceEncoding, TargetEncoding: string;
  Recursive: Boolean;
  const ProgressProc: TBatchConversionProgressProc): TBatchConversionResult;
var
  Files: TArray<string>;
  SearchOption: TSearchOption;
begin
  Result.TotalFiles := 0;
  Result.SuccessCount := 0;
  Result.FailedCount := 0;
  Result.SkippedCount := 0;
  SetLength(Result.FailedFiles, 0);

  if not TDirectory.Exists(SourceDir) then
    Exit;

  if Recursive then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;

  Files := TDirectory.GetFiles(SourceDir, FilePattern, SearchOption);
  Result := BatchConvertFileList(Files, SourceEncoding, TargetEncoding, ProgressProc);
end;

class function TEncodingHelper.BatchConvertFileList(
  const FileList: TArray<string>;
  const SourceEncoding, TargetEncoding: string;
  const ProgressProc: TBatchConversionProgressProc): TBatchConversionResult;
var
  i: Integer;
  Cancel: Boolean;
  Options: TEncodingConversionOptions;
  ConvResult: TEncodingConversionResult;
begin
  Result.TotalFiles := Length(FileList);
  Result.SuccessCount := 0;
  Result.FailedCount := 0;
  Result.SkippedCount := 0;
  SetLength(Result.FailedFiles, 0);

  Cancel := False;
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.DetectSourceEncoding := (SourceEncoding = '') or (SourceEncoding = 'auto');

  for i := 0 to High(FileList) do
  begin
    if Assigned(ProgressProc) then
    begin
      ProgressProc(FileList[i], i + 1, Result.TotalFiles, Cancel);
      if Cancel then
      begin
        Result.SkippedCount := Result.TotalFiles - i;
        Break;
      end;
    end;

    try
      ConvResult := TEncodingConverter_Improved.ConvertFile(
        FileList[i],
        FileList[i],
        SourceEncoding,
        TargetEncoding,
        Options);

      if ConvResult.Success then
        Inc(Result.SuccessCount)
      else
      begin
        Inc(Result.FailedCount);
        SetLength(Result.FailedFiles, Length(Result.FailedFiles) + 1);
        Result.FailedFiles[High(Result.FailedFiles)] := FileList[i];
      end;
    except
      on E: Exception do
      begin
        Inc(Result.FailedCount);
        SetLength(Result.FailedFiles, Length(Result.FailedFiles) + 1);
        Result.FailedFiles[High(Result.FailedFiles)] := FileList[i] + ' (' + E.Message + ')';
      end;
    end;
  end;
end;

end.
