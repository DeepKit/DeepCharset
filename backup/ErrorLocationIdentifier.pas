unit ErrorLocationIdentifier;

interface

uses
  SysUtils, Classes, Generics.Collections, Character;

type
  /// <summary>
  /// 错误类型枚举
  /// </summary>
  TErrorType = (
    /// <summary>
    /// 编码错误（无效字节序列）
    /// </summary>
    etEncoding,
    
    /// <summary>
    /// 字符转换错误（不可逆转换）
    /// </summary>
    etCharacterConversion,
    
    /// <summary>
    /// 特殊字符错误（不支持的字符）
    /// </summary>
    etSpecialCharacter,
    
    /// <summary>
    /// 格式错误（结构问题）
    /// </summary>
    etFormat,
    
    /// <summary>
    /// 溢出错误
    /// </summary>
    etOverflow,
    
    /// <summary>
    /// 其他错误
    /// </summary>
    etOther
  );

  /// <summary>
  /// 错误位置信息
  /// </summary>
  TErrorLocation = record
    /// <summary>
    /// 字节索引位置
    /// </summary>
    ByteIndex: Int64;
    
    /// <summary>
    /// 行号 (1-based)
    /// </summary>
    LineNumber: Integer;
    
    /// <summary>
    /// 列号 (1-based)
    /// </summary>
    ColumnNumber: Integer;
    
    /// <summary>
    /// 错误类型
    /// </summary>
    ErrorType: TErrorType;
    
    /// <summary>
    /// 错误说明
    /// </summary>
    Description: string;
    
    /// <summary>
    /// 原始字节（对于字节错误）
    /// </summary>
    ErrorBytes: TBytes;
    
    /// <summary>
    /// 上下文（错误位置前后的内容）
    /// </summary>
    Context: string;
    
    /// <summary>
    /// 建议修复方法
    /// </summary>
    SuggestedFix: string;
  end;
  
  /// <summary>
  /// 行偏移缓存
  /// </summary>
  TLineOffsetCache = class
  private
    FLineOffsets: TList<Int64>;
    FLastIndex: Integer;
    FMaxOffset: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 添加行偏移
    /// </summary>
    /// <param name="Offset">行偏移字节索引</param>
    procedure AddLineOffset(Offset: Int64);
    
    /// <summary>
    /// 获取行号和列号
    /// </summary>
    /// <param name="ByteIndex">字节索引</param>
    /// <param name="LineNumber">返回行号</param>
    /// <param name="ColumnNumber">返回列号</param>
    procedure GetLineAndColumn(ByteIndex: Int64; var LineNumber, ColumnNumber: Integer);
    
    /// <summary>
    /// 重置缓存
    /// </summary>
    procedure Reset;
    
    /// <summary>
    /// 最大偏移量
    /// </summary>
    property MaxOffset: Int64 read FMaxOffset;
  end;
  
  /// <summary>
  /// 错误位置识别器
  /// </summary>
  TErrorLocationIdentifier = class
  private
    FLineCache: TLineOffsetCache;
    FDetectedErrors: TList<TErrorLocation>;
    FContextSize: Integer;
    FMaxErrorsToTrack: Integer;
    
    function GetDetectedErrorCount: Integer;
    function GetErrorLocation(Index: Integer): TErrorLocation;
  public
    /// <summary>
    /// 创建错误位置识别器
    /// </summary>
    constructor Create;
    
    /// <summary>
    /// 销毁错误位置识别器
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 预处理文本以构建行索引
    /// </summary>
    /// <param name="TextData">文本数据</param>
    /// <param name="Size">数据大小</param>
    procedure PreprocessText(TextData: PByte; Size: Int64);
    
    /// <summary>
    /// 预处理文件以构建行索引
    /// </summary>
    /// <param name="FileName">文件名</param>
    procedure PreprocessFile(const FileName: string);
    
    /// <summary>
    /// 添加错误位置
    /// </summary>
    /// <param name="ByteIndex">字节索引</param>
    /// <param name="ErrorType">错误类型</param>
    /// <param name="Description">错误描述</param>
    /// <param name="ErrorBytes">错误字节数据</param>
    /// <param name="SuggestedFix">建议修复</param>
    /// <returns>错误索引</returns>
    function AddError(ByteIndex: Int64; ErrorType: TErrorType;
                      const Description: string; ErrorBytes: TBytes = nil;
                      const SuggestedFix: string = ''): Integer;
    
    /// <summary>
    /// 从文本数据中提取错误上下文
    /// </summary>
    /// <param name="TextData">文本数据</param>
    /// <param name="Size">数据大小</param>
    /// <param name="ByteIndex">字节索引</param>
    /// <returns>上下文字符串</returns>
    function ExtractContext(TextData: PByte; Size: Int64; ByteIndex: Int64): string;
    
    /// <summary>
    /// 获取完整错误报告
    /// </summary>
    /// <returns>错误报告文本</returns>
    function GetErrorReport: string;
    
    /// <summary>
    /// 获取错误位置的HTML表示
    /// </summary>
    /// <param name="Index">错误索引</param>
    /// <returns>HTML格式的错误位置</returns>
    function GetErrorLocationHTML(Index: Integer): string;
    
    /// <summary>
    /// 清除所有错误
    /// </summary>
    procedure ClearErrors;
    
    /// <summary>
    /// 错误上下文大小（每侧的字符数）
    /// </summary>
    property ContextSize: Integer read FContextSize write FContextSize;
    
    /// <summary>
    /// 跟踪的最大错误数
    /// </summary>
    property MaxErrorsToTrack: Integer read FMaxErrorsToTrack write FMaxErrorsToTrack;
    
    /// <summary>
    /// 检测到的错误数
    /// </summary>
    property DetectedErrorCount: Integer read GetDetectedErrorCount;
    
    /// <summary>
    /// 错误位置
    /// </summary>
    property ErrorLocations[Index: Integer]: TErrorLocation read GetErrorLocation;
  end;

implementation

uses
  StrUtils;

{ TLineOffsetCache }

constructor TLineOffsetCache.Create;
begin
  inherited Create;
  FLineOffsets := TList<Int64>.Create;
  Reset;
end;

destructor TLineOffsetCache.Destroy;
begin
  FLineOffsets.Free;
  inherited;
end;

procedure TLineOffsetCache.AddLineOffset(Offset: Int64);
begin
  FLineOffsets.Add(Offset);
  FMaxOffset := Offset;
end;

procedure TLineOffsetCache.GetLineAndColumn(ByteIndex: Int64;
  var LineNumber, ColumnNumber: Integer);
var
  I: Integer;
begin
  // 默认值
  LineNumber := 1;
  ColumnNumber := 1;
  
  // 如果超出范围，返回默认值
  if (ByteIndex < 0) or (FLineOffsets.Count = 0) then
    Exit;
    
  // 如果超过最大偏移量，使用最后一行
  if ByteIndex > FMaxOffset then
  begin
    LineNumber := FLineOffsets.Count;
    ColumnNumber := Integer(ByteIndex - FLineOffsets[LineNumber - 1] + 1);
    Exit;
  end;
  
  // 尝试从上次查找位置开始，以优化连续查找
  if (FLastIndex >= 0) and (FLastIndex < FLineOffsets.Count - 1) then
  begin
    if (ByteIndex >= FLineOffsets[FLastIndex]) and (ByteIndex < FLineOffsets[FLastIndex + 1]) then
    begin
      LineNumber := FLastIndex + 1;
      ColumnNumber := Integer(ByteIndex - FLineOffsets[FLastIndex] + 1);
      Exit;
    end;
  end;
  
  // 二分查找
  I := 0;
  while I < FLineOffsets.Count - 1 do
  begin
    if (ByteIndex >= FLineOffsets[I]) and (ByteIndex < FLineOffsets[I + 1]) then
    begin
      LineNumber := I + 1;
      ColumnNumber := Integer(ByteIndex - FLineOffsets[I] + 1);
      FLastIndex := I;
      Exit;
    end;
    Inc(I);
  end;
  
  // 如果是最后一行
  if (ByteIndex >= FLineOffsets[FLineOffsets.Count - 1]) then
  begin
    LineNumber := FLineOffsets.Count;
    ColumnNumber := Integer(ByteIndex - FLineOffsets[FLineOffsets.Count - 1] + 1);
    FLastIndex := FLineOffsets.Count - 1;
  end;
end;

procedure TLineOffsetCache.Reset;
begin
  FLineOffsets.Clear;
  FLineOffsets.Add(0); // 第一行从0开始
  FLastIndex := 0;
  FMaxOffset := 0;
end;

{ TErrorLocationIdentifier }

constructor TErrorLocationIdentifier.Create;
begin
  inherited Create;
  FLineCache := TLineOffsetCache.Create;
  FDetectedErrors := TList<TErrorLocation>.Create;
  FContextSize := 20; // 默认上下文大小，每侧20个字符
  FMaxErrorsToTrack := 1000; // 默认最多跟踪1000个错误
end;

destructor TErrorLocationIdentifier.Destroy;
begin
  FLineCache.Free;
  FDetectedErrors.Free;
  inherited;
end;

procedure TErrorLocationIdentifier.PreprocessText(TextData: PByte; Size: Int64);
var
  I: Int64;
  PrevChar, CurChar: Byte;
begin
  // 重置行缓存
  FLineCache.Reset;
  
  if (TextData = nil) or (Size <= 0) then
    Exit;
    
  PrevChar := 0;
  
  // 遍历文本数据，查找行终止符
  for I := 0 to Size - 1 do
  begin
    CurChar := PByte(NativeUInt(TextData) + I)^;
    
    // 检测行终止符：CR+LF, CR, LF
    if ((CurChar = 10) and (PrevChar <> 13)) or (CurChar = 13) then
      FLineCache.AddLineOffset(I + 1);
      
    PrevChar := CurChar;
  end;
end;

procedure TErrorLocationIdentifier.PreprocessFile(const FileName: string);
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
  TotalRead: Int64;
  PrevChar, CurChar: Byte;
  I: Integer;
  BufferSize: Integer;
begin
  // 重置行缓存
  FLineCache.Reset;
  
  if not FileExists(FileName) then
    Exit;
    
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    BufferSize := 65536; // 64KB缓冲区
    SetLength(Buffer, BufferSize);
    
    PrevChar := 0;
    TotalRead := 0;
    
    // 逐块读取文件以减少内存使用
    repeat
      BytesRead := FileStream.Read(Buffer[0], BufferSize);
      
      for I := 0 to BytesRead - 1 do
      begin
        CurChar := Buffer[I];
        
        // 检测行终止符：CR+LF, CR, LF
        if ((CurChar = 10) and (PrevChar <> 13)) or (CurChar = 13) then
          FLineCache.AddLineOffset(TotalRead + I + 1);
          
        PrevChar := CurChar;
      end;
      
      Inc(TotalRead, BytesRead);
    until BytesRead < BufferSize;
  finally
    FileStream.Free;
  end;
end;

function TErrorLocationIdentifier.AddError(ByteIndex: Int64;
  ErrorType: TErrorType; const Description: string;
  ErrorBytes: TBytes; const SuggestedFix: string): Integer;
var
  Error: TErrorLocation;
begin
  // 如果已达到最大错误数，不再添加
  if FDetectedErrors.Count >= FMaxErrorsToTrack then
  begin
    Result := -1;
    Exit;
  end;
  
  // 初始化错误记录
  FillChar(Error, SizeOf(Error), 0);
  Error.ByteIndex := ByteIndex;
  Error.ErrorType := ErrorType;
  Error.Description := Description;
  
  // 复制错误字节
  if ErrorBytes <> nil then
    Error.ErrorBytes := Copy(ErrorBytes);
    
  Error.SuggestedFix := SuggestedFix;
  
  // 计算行和列
  FLineCache.GetLineAndColumn(ByteIndex, Error.LineNumber, Error.ColumnNumber);
  
  // 添加到错误列表
  Result := FDetectedErrors.Add(Error);
end;

function TErrorLocationIdentifier.ExtractContext(TextData: PByte; Size: Int64;
  ByteIndex: Int64): string;
var
  StartPos, EndPos: Int64;
  ContextLength: Integer;
  TempBytes: TBytes;
  I: Int64;
begin
  Result := '';
  
  // 验证参数
  if (TextData = nil) or (Size <= 0) or (ByteIndex < 0) or (ByteIndex >= Size) then
    Exit;
    
  // 计算上下文范围
  StartPos := Max(0, ByteIndex - FContextSize);
  EndPos := Min(Size - 1, ByteIndex + FContextSize);
  ContextLength := Integer(EndPos - StartPos + 1);
  
  // 提取上下文字节
  SetLength(TempBytes, ContextLength);
  for I := 0 to ContextLength - 1 do
    TempBytes[I] := PByte(NativeUInt(TextData) + StartPos + I)^;
    
  // 尝试转换为字符串（如果包含无效字符，将被替换为'?'）
  SetString(Result, PAnsiChar(@TempBytes[0]), ContextLength);
  
  // 标记错误位置
  if (ByteIndex >= StartPos) and (ByteIndex <= EndPos) then
  begin
    // 在错误位置添加标记 [!]
    Insert('[!]', Result, Integer(ByteIndex - StartPos + 1));
  end;
end;

function TErrorLocationIdentifier.GetErrorReport: string;
var
  I: Integer;
  Error: TErrorLocation;
  ErrorTypeStr: string;
begin
  Result := Format('错误报告 - 共检测到 %d 个错误'#13#10, [FDetectedErrors.Count]);
  Result := Result + StringOfChar('-', 60) + #13#10;
  
  for I := 0 to FDetectedErrors.Count - 1 do
  begin
    Error := FDetectedErrors[I];
    
    // 转换错误类型为字符串
    case Error.ErrorType of
      etEncoding: ErrorTypeStr := '编码错误';
      etCharacterConversion: ErrorTypeStr := '字符转换错误';
      etSpecialCharacter: ErrorTypeStr := '特殊字符错误';
      etFormat: ErrorTypeStr := '格式错误';
      etOverflow: ErrorTypeStr := '溢出错误';
      else ErrorTypeStr := '其他错误';
    end;
    
    // 格式化错误信息
    Result := Result + Format('错误 #%d (字节位置: %d, 行: %d, 列: %d)'#13#10, 
                              [I + 1, Error.ByteIndex, Error.LineNumber, Error.ColumnNumber]);
    Result := Result + Format('类型: %s'#13#10, [ErrorTypeStr]);
    Result := Result + Format('描述: %s'#13#10, [Error.Description]);
    
    // 添加上下文，如果有
    if Error.Context <> '' then
      Result := Result + Format('上下文: %s'#13#10, [Error.Context]);
      
    // 添加建议修复，如果有
    if Error.SuggestedFix <> '' then
      Result := Result + Format('建议修复: %s'#13#10, [Error.SuggestedFix]);
      
    // 添加错误字节十六进制表示，如果有
    if Length(Error.ErrorBytes) > 0 then
    begin
      Result := Result + '错误字节: ';
      for I := 0 to Length(Error.ErrorBytes) - 1 do
        Result := Result + IntToHex(Error.ErrorBytes[I], 2) + ' ';
      Result := Result + #13#10;
    end;
    
    Result := Result + StringOfChar('-', 60) + #13#10;
  end;
end;

function TErrorLocationIdentifier.GetErrorLocationHTML(Index: Integer): string;
var
  Error: TErrorLocation;
  ErrorTypeStr, ContextHTML: string;
  I: Integer;
begin
  Result := '';
  
  if (Index < 0) or (Index >= FDetectedErrors.Count) then
    Exit;
    
  Error := FDetectedErrors[Index];
  
  // 转换错误类型为字符串
  case Error.ErrorType of
    etEncoding: ErrorTypeStr := '编码错误';
    etCharacterConversion: ErrorTypeStr := '字符转换错误';
    etSpecialCharacter: ErrorTypeStr := '特殊字符错误';
    etFormat: ErrorTypeStr := '格式错误';
    etOverflow: ErrorTypeStr := '溢出错误';
    else ErrorTypeStr := '其他错误';
  end;
  
  // 如果有上下文，创建带有错误高亮的HTML
  ContextHTML := '';
  if Error.Context <> '' then
  begin
    // 将[!]标记替换为HTML高亮标记
    ContextHTML := StringReplace(
      StringReplace(Error.Context, '<', '&lt;', [rfReplaceAll]),
      '>', '&gt;', [rfReplaceAll]
    );
    ContextHTML := StringReplace(ContextHTML, '[!]', '<span class="error-mark">&lt;!&gt;</span>', [rfReplaceAll]);
    ContextHTML := '<pre class="error-context">' + ContextHTML + '</pre>';
  end;
  
  // 构建错误字节的HTML表示
  var BytesHTML := '';
  if Length(Error.ErrorBytes) > 0 then
  begin
    BytesHTML := '<div class="error-bytes">错误字节: ';
    for I := 0 to Length(Error.ErrorBytes) - 1 do
      BytesHTML := BytesHTML + '<span class="byte">' + IntToHex(Error.ErrorBytes[I], 2) + '</span> ';
    BytesHTML := BytesHTML + '</div>';
  end;
  
  // 生成HTML
  Result := 
    '<div class="error-location">' +
    Format('<div class="error-header">错误 #%d - %s</div>', [Index + 1, ErrorTypeStr]) +
    Format('<div class="error-position">位置: 字节 %d (行 %d, 列 %d)</div>', 
           [Error.ByteIndex, Error.LineNumber, Error.ColumnNumber]) +
    Format('<div class="error-description">%s</div>', [Error.Description]);
    
  if ContextHTML <> '' then
    Result := Result + ContextHTML;
    
  if BytesHTML <> '' then
    Result := Result + BytesHTML;
    
  if Error.SuggestedFix <> '' then
    Result := Result + Format('<div class="suggested-fix">建议修复: %s</div>', [Error.SuggestedFix]);
    
  Result := Result + '</div>';
end;

procedure TErrorLocationIdentifier.ClearErrors;
begin
  FDetectedErrors.Clear;
end;

function TErrorLocationIdentifier.GetDetectedErrorCount: Integer;
begin
  Result := FDetectedErrors.Count;
end;

function TErrorLocationIdentifier.GetErrorLocation(Index: Integer): TErrorLocation;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  if (Index >= 0) and (Index < FDetectedErrors.Count) then
    Result := FDetectedErrors[Index];
end;

end. 