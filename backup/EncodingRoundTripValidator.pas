unit EncodingRoundTripValidator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.Windows,
  UtilsEncodingConstants;

type
  /// <summary>
  /// 往返转换验证结果
  /// </summary>
  TRoundTripValidationResult = record
    Success: Boolean;
    SourceSize: Int64;
    IntermediateSize: Int64;
    TargetSize: Int64;
    OriginalHash: string;
    FinalHash: string;
    SourceEncoding: string;
    IntermediateEncoding: string;
    DetailedMessage: string;
    ErrorMessage: string;
    constructor Create(ASuccess: Boolean; ASourceSize, AIntermediateSize, ATargetSize: Int64; 
                     const AOriginalHash, AFinalHash, ASourceEncoding, AIntermediateEncoding, 
                     ADetailedMessage, AErrorMessage: string);
  end;

  /// <summary>
  /// 往返转换验证器
  /// </summary>
  TRoundTripValidator = class
  private
    FLastErrorMessage: string;
    
    function CalculateFileHash(const FileName: string): string;
    function CalculateBufferHash(const Buffer: TBytes): string;
    function ConvertEncoding(const SourceBuffer: TBytes; SourceEncoding, TargetEncoding: string): TBytes;
    function CreateTempFile: string;
    procedure CleanupTempFile(const FileName: string);
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 执行往返转换验证
    /// </summary>
    function ValidateRoundTrip(const SourceFile: string; SourceEncoding, IntermediateEncoding: string): TRoundTripValidationResult;
    
    /// <summary>
    /// 执行往返转换验证（缓冲区版本）
    /// </summary>
    function ValidateRoundTripBuffers(const SourceBuffer: TBytes; SourceEncoding, IntermediateEncoding: string): TRoundTripValidationResult;
    
    /// <summary>
    /// 批量执行往返转换验证
    /// </summary>
    function BatchValidateRoundTrip(const SourceFiles: TArray<string>; SourceEncoding, IntermediateEncoding: string): TArray<TRoundTripValidationResult>;
    
    /// <summary>
    /// 获取最后一次错误信息
    /// </summary>
    function GetLastError: string;
    
    property LastErrorMessage: string read FLastErrorMessage;
  end;

implementation

uses
  System.Hash;

// 构造函数
constructor TRoundTripValidationResult.Create(ASuccess: Boolean; ASourceSize, AIntermediateSize, ATargetSize: Int64; 
                                            const AOriginalHash, AFinalHash, ASourceEncoding, AIntermediateEncoding, 
                                            ADetailedMessage, AErrorMessage: string);
begin
  Success := ASuccess;
  SourceSize := ASourceSize;
  IntermediateSize := AIntermediateSize;
  TargetSize := ATargetSize;
  OriginalHash := AOriginalHash;
  FinalHash := AFinalHash;
  SourceEncoding := ASourceEncoding;
  IntermediateEncoding := AIntermediateEncoding;
  DetailedMessage := ADetailedMessage;
  ErrorMessage := AErrorMessage;
end;

constructor TRoundTripValidator.Create;
begin
  inherited Create;
  FLastErrorMessage := '';
end;

destructor TRoundTripValidator.Destroy;
begin
  inherited;
end;

function TRoundTripValidator.GetLastError: string;
begin
  Result := FLastErrorMessage;
end;

// 计算文件的MD5哈希值
function TRoundTripValidator.CalculateFileHash(const FileName: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := '';
  
  if not FileExists(FileName) then
  begin
    FLastErrorMessage := '文件不存在: ' + FileName;
    Exit;
  end;
  
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      
      Result := CalculateBufferHash(Buffer);
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastErrorMessage := '计算文件哈希值时发生错误: ' + E.Message;
      Result := '';
    end;
  end;
end;

// 计算缓冲区的MD5哈希值
function TRoundTripValidator.CalculateBufferHash(const Buffer: TBytes): string;
begin
  if Length(Buffer) = 0 then
    Result := ''
  else
    Result := THashMD5.GetHashString(Buffer);
end;

// 创建临时文件
function TRoundTripValidator.CreateTempFile: string;
begin
  Result := TPath.GetTempFileName;
end;

// 清理临时文件
procedure TRoundTripValidator.CleanupTempFile(const FileName: string);
begin
  if FileExists(FileName) then
    try
      DeleteFile(FileName);
    except
      // 忽略清理临时文件时的错误
    end;
end;

// 转换编码
function TRoundTripValidator.ConvertEncoding(const SourceBuffer: TBytes; SourceEncoding, TargetEncoding: string): TBytes;
var
  SourceText, TargetText: string;
  SourceCP, TargetCP: Integer;
begin
  // 将源缓冲区转换为Unicode字符串
  case SourceEncoding of
    ENCODING_UTF8, ENCODING_UTF8_BOM:
      begin
        // 如果有BOM，跳过
        if (Length(SourceBuffer) >= 3) and (SourceBuffer[0] = $EF) and (SourceBuffer[1] = $BB) and (SourceBuffer[2] = $BF) then
          SourceText := TEncoding.UTF8.GetString(SourceBuffer, 3, Length(SourceBuffer) - 3)
        else
          SourceText := TEncoding.UTF8.GetString(SourceBuffer);
      end;
    ENCODING_UTF16_LE:
      begin
        // 如果有BOM，跳过
        if (Length(SourceBuffer) >= 2) and (SourceBuffer[0] = $FF) and (SourceBuffer[1] = $FE) then
          SourceText := TEncoding.Unicode.GetString(SourceBuffer, 2, Length(SourceBuffer) - 2)
        else
          SourceText := TEncoding.Unicode.GetString(SourceBuffer);
      end;
    ENCODING_UTF16_BE:
      begin
        // 如果有BOM，跳过
        if (Length(SourceBuffer) >= 2) and (SourceBuffer[0] = $FE) and (SourceBuffer[1] = $FF) then
          SourceText := TEncoding.BigEndianUnicode.GetString(SourceBuffer, 2, Length(SourceBuffer) - 2)
        else
          SourceText := TEncoding.BigEndianUnicode.GetString(SourceBuffer);
      end;
    ENCODING_GB18030, ENCODING_GBK:
      begin
        SourceCP := 936; // GBK/GB18030
        if Length(SourceBuffer) = 0 then
          SourceText := ''
        else
        begin
          var WideLen := MultiByteToWideChar(SourceCP, 0, @SourceBuffer[0], Length(SourceBuffer), nil, 0);
          if WideLen <= 0 then
            SourceText := ''
          else
          begin
            SetLength(SourceText, WideLen);
            MultiByteToWideChar(SourceCP, 0, @SourceBuffer[0], Length(SourceBuffer), PWideChar(SourceText), WideLen);
          end;
        end;
      end;
    ENCODING_BIG5:
      begin
        SourceCP := 950; // Big5
        if Length(SourceBuffer) = 0 then
          SourceText := ''
        else
        begin
          var WideLen := MultiByteToWideChar(SourceCP, 0, @SourceBuffer[0], Length(SourceBuffer), nil, 0);
          if WideLen <= 0 then
            SourceText := ''
          else
          begin
            SetLength(SourceText, WideLen);
            MultiByteToWideChar(SourceCP, 0, @SourceBuffer[0], Length(SourceBuffer), PWideChar(SourceText), WideLen);
          end;
        end;
      end;
    else
      SourceText := TEncoding.Default.GetString(SourceBuffer);
  end;
  
  // 将Unicode字符串转换为目标编码
  case TargetEncoding of
    ENCODING_UTF8:
      Result := TEncoding.UTF8.GetBytes(SourceText);
    ENCODING_UTF8_BOM:
      begin
        var TempBytes := TEncoding.UTF8.GetBytes(SourceText);
        SetLength(Result, Length(TempBytes) + 3);
        Result[0] := $EF;
        Result[1] := $BB;
        Result[2] := $BF;
        if Length(TempBytes) > 0 then
          Move(TempBytes[0], Result[3], Length(TempBytes));
      end;
    ENCODING_UTF16_LE:
      begin
        var TempBytes := TEncoding.Unicode.GetBytes(SourceText);
        SetLength(Result, Length(TempBytes) + 2);
        Result[0] := $FF;
        Result[1] := $FE;
        if Length(TempBytes) > 0 then
          Move(TempBytes[0], Result[2], Length(TempBytes));
      end;
    ENCODING_UTF16_BE:
      begin
        var TempBytes := TEncoding.BigEndianUnicode.GetBytes(SourceText);
        SetLength(Result, Length(TempBytes) + 2);
        Result[0] := $FE;
        Result[1] := $FF;
        if Length(TempBytes) > 0 then
          Move(TempBytes[0], Result[2], Length(TempBytes));
      end;
    ENCODING_GB18030, ENCODING_GBK:
      begin
        TargetCP := 936; // GBK/GB18030
        if SourceText = '' then
          Result := nil
        else
        begin
          var ByteLen := WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), nil, 0, nil, nil);
          if ByteLen <= 0 then
            Result := nil
          else
          begin
            SetLength(Result, ByteLen);
            WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), @Result[0], ByteLen, nil, nil);
          end;
        end;
      end;
    ENCODING_BIG5:
      begin
        TargetCP := 950; // Big5
        if SourceText = '' then
          Result := nil
        else
        begin
          var ByteLen := WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), nil, 0, nil, nil);
          if ByteLen <= 0 then
            Result := nil
          else
          begin
            SetLength(Result, ByteLen);
            WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), @Result[0], ByteLen, nil, nil);
          end;
        end;
      end;
    else
      Result := TEncoding.Default.GetBytes(SourceText);
  end;
end;

// 执行往返转换验证
function TRoundTripValidator.ValidateRoundTrip(const SourceFile: string; SourceEncoding, IntermediateEncoding: string): TRoundTripValidationResult;
var
  SourceBuffer, IntermediateBuffer, FinalBuffer: TBytes;
  OriginalHash, FinalHash: string;
  DetailedMessage: TStringBuilder;
  IntermediateFile, FinalFile: string;
  Success: Boolean;
begin
  FLastErrorMessage := '';
  DetailedMessage := TStringBuilder.Create;
  IntermediateFile := '';
  FinalFile := '';
  
  try
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      FLastErrorMessage := '源文件不存在: ' + SourceFile;
      Result := TRoundTripValidationResult.Create(False, 0, 0, 0, '', '', SourceEncoding, 
                                               IntermediateEncoding, '', FLastErrorMessage);
      Exit;
    end;
    
    // 读取源文件内容
    try
      SourceBuffer := TFile.ReadAllBytes(SourceFile);
    except
      on E: Exception do
      begin
        FLastErrorMessage := '读取源文件时发生错误: ' + E.Message;
        Result := TRoundTripValidationResult.Create(False, 0, 0, 0, '', '', SourceEncoding, 
                                                 IntermediateEncoding, '', FLastErrorMessage);
        Exit;
      end;
    end;
    
    // 计算源文件哈希值
    OriginalHash := CalculateBufferHash(SourceBuffer);
    if OriginalHash = '' then
    begin
      Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, '', '', 
                                               SourceEncoding, IntermediateEncoding, '', FLastErrorMessage);
      Exit;
    end;
    
    DetailedMessage.AppendLine('往返转换验证开始:');
    DetailedMessage.AppendLine(Format('源文件: %s', [SourceFile]));
    DetailedMessage.AppendLine(Format('源编码: %s', [SourceEncoding]));
    DetailedMessage.AppendLine(Format('中间编码: %s', [IntermediateEncoding]));
    DetailedMessage.AppendLine(Format('源文件大小: %d 字节', [Length(SourceBuffer)]));
    DetailedMessage.AppendLine(Format('源文件哈希值: %s', [OriginalHash]));
    DetailedMessage.AppendLine('----------------------------');
    
    // 第一步转换: 源编码 -> 中间编码
    try
      IntermediateBuffer := ConvertEncoding(SourceBuffer, SourceEncoding, IntermediateEncoding);
      if Length(IntermediateBuffer) = 0 then
      begin
        FLastErrorMessage := '转换到中间编码失败';
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, OriginalHash, 
                                                 '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
      
      // 创建临时文件保存中间结果（用于调试）
      IntermediateFile := CreateTempFile;
      TFile.WriteAllBytes(IntermediateFile, IntermediateBuffer);
      
      DetailedMessage.AppendLine(Format('中间文件大小: %d 字节', [Length(IntermediateBuffer)]));
      DetailedMessage.AppendLine(Format('中间文件哈希值: %s', [CalculateBufferHash(IntermediateBuffer)]));
    except
      on E: Exception do
      begin
        FLastErrorMessage := '转换到中间编码时发生错误: ' + E.Message;
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, OriginalHash, 
                                                 '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
    end;
    
    // 第二步转换: 中间编码 -> 源编码
    try
      FinalBuffer := ConvertEncoding(IntermediateBuffer, IntermediateEncoding, SourceEncoding);
      if Length(FinalBuffer) = 0 then
      begin
        FLastErrorMessage := '从中间编码转换回源编码失败';
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), Length(IntermediateBuffer), 
                                                 0, OriginalHash, '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
      
      // 创建临时文件保存最终结果（用于调试）
      FinalFile := CreateTempFile;
      TFile.WriteAllBytes(FinalFile, FinalBuffer);
      
      // 计算最终哈希值
      FinalHash := CalculateBufferHash(FinalBuffer);
      
      DetailedMessage.AppendLine(Format('最终文件大小: %d 字节', [Length(FinalBuffer)]));
      DetailedMessage.AppendLine(Format('最终文件哈希值: %s', [FinalHash]));
    except
      on E: Exception do
      begin
        FLastErrorMessage := '从中间编码转换回源编码时发生错误: ' + E.Message;
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), Length(IntermediateBuffer), 
                                                 0, OriginalHash, '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
    end;
    
    // 比较源文件和最终文件是否一致
    Success := (OriginalHash = FinalHash);
    
    if Success then
      DetailedMessage.AppendLine('结果: 往返转换成功，内容完全一致!')
    else
      DetailedMessage.AppendLine('结果: 往返转换失败，内容不一致!');
    
    Result := TRoundTripValidationResult.Create(Success, Length(SourceBuffer), Length(IntermediateBuffer), 
                                             Length(FinalBuffer), OriginalHash, FinalHash, 
                                             SourceEncoding, IntermediateEncoding, 
                                             DetailedMessage.ToString, '');
  finally
    DetailedMessage.Free;
    
    // 清理临时文件
    if IntermediateFile <> '' then
      CleanupTempFile(IntermediateFile);
    if FinalFile <> '' then
      CleanupTempFile(FinalFile);
  end;
end;

// 执行往返转换验证（缓冲区版本）
function TRoundTripValidator.ValidateRoundTripBuffers(const SourceBuffer: TBytes; SourceEncoding, IntermediateEncoding: string): TRoundTripValidationResult;
var
  IntermediateBuffer, FinalBuffer: TBytes;
  OriginalHash, FinalHash: string;
  DetailedMessage: TStringBuilder;
  Success: Boolean;
begin
  FLastErrorMessage := '';
  DetailedMessage := TStringBuilder.Create;
  
  try
    if Length(SourceBuffer) = 0 then
    begin
      FLastErrorMessage := '源缓冲区为空';
      Result := TRoundTripValidationResult.Create(False, 0, 0, 0, '', '', SourceEncoding, 
                                               IntermediateEncoding, '', FLastErrorMessage);
      Exit;
    end;
    
    // 计算源缓冲区哈希值
    OriginalHash := CalculateBufferHash(SourceBuffer);
    if OriginalHash = '' then
    begin
      Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, '', '', 
                                               SourceEncoding, IntermediateEncoding, '', FLastErrorMessage);
      Exit;
    end;
    
    DetailedMessage.AppendLine('往返转换验证开始:');
    DetailedMessage.AppendLine(Format('源编码: %s', [SourceEncoding]));
    DetailedMessage.AppendLine(Format('中间编码: %s', [IntermediateEncoding]));
    DetailedMessage.AppendLine(Format('源缓冲区大小: %d 字节', [Length(SourceBuffer)]));
    DetailedMessage.AppendLine(Format('源缓冲区哈希值: %s', [OriginalHash]));
    DetailedMessage.AppendLine('----------------------------');
    
    // 第一步转换: 源编码 -> 中间编码
    try
      IntermediateBuffer := ConvertEncoding(SourceBuffer, SourceEncoding, IntermediateEncoding);
      if Length(IntermediateBuffer) = 0 then
      begin
        FLastErrorMessage := '转换到中间编码失败';
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, OriginalHash, 
                                                 '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
      
      DetailedMessage.AppendLine(Format('中间缓冲区大小: %d 字节', [Length(IntermediateBuffer)]));
      DetailedMessage.AppendLine(Format('中间缓冲区哈希值: %s', [CalculateBufferHash(IntermediateBuffer)]));
    except
      on E: Exception do
      begin
        FLastErrorMessage := '转换到中间编码时发生错误: ' + E.Message;
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), 0, 0, OriginalHash, 
                                                 '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
    end;
    
    // 第二步转换: 中间编码 -> 源编码
    try
      FinalBuffer := ConvertEncoding(IntermediateBuffer, IntermediateEncoding, SourceEncoding);
      if Length(FinalBuffer) = 0 then
      begin
        FLastErrorMessage := '从中间编码转换回源编码失败';
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), Length(IntermediateBuffer), 
                                                 0, OriginalHash, '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
      
      // 计算最终哈希值
      FinalHash := CalculateBufferHash(FinalBuffer);
      
      DetailedMessage.AppendLine(Format('最终缓冲区大小: %d 字节', [Length(FinalBuffer)]));
      DetailedMessage.AppendLine(Format('最终缓冲区哈希值: %s', [FinalHash]));
    except
      on E: Exception do
      begin
        FLastErrorMessage := '从中间编码转换回源编码时发生错误: ' + E.Message;
        Result := TRoundTripValidationResult.Create(False, Length(SourceBuffer), Length(IntermediateBuffer), 
                                                 0, OriginalHash, '', SourceEncoding, IntermediateEncoding, 
                                                 DetailedMessage.ToString, FLastErrorMessage);
        Exit;
      end;
    end;
    
    // 比较源缓冲区和最终缓冲区是否一致
    Success := (OriginalHash = FinalHash);
    
    if Success then
      DetailedMessage.AppendLine('结果: 往返转换成功，内容完全一致!')
    else
      DetailedMessage.AppendLine('结果: 往返转换失败，内容不一致!');
    
    Result := TRoundTripValidationResult.Create(Success, Length(SourceBuffer), Length(IntermediateBuffer), 
                                             Length(FinalBuffer), OriginalHash, FinalHash, 
                                             SourceEncoding, IntermediateEncoding, 
                                             DetailedMessage.ToString, '');
  finally
    DetailedMessage.Free;
  end;
end;

// 批量执行往返转换验证
function TRoundTripValidator.BatchValidateRoundTrip(const SourceFiles: TArray<string>; SourceEncoding, IntermediateEncoding: string): TArray<TRoundTripValidationResult>;
var
  I: Integer;
begin
  SetLength(Result, Length(SourceFiles));
  
  for I := 0 to Length(SourceFiles) - 1 do
    Result[I] := ValidateRoundTrip(SourceFiles[I], SourceEncoding, IntermediateEncoding);
end;

end. 