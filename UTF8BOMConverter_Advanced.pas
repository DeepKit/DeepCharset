unit UTF8BOMConverter_Advanced;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, 
  Winapi.Windows, UtilsEncodingConstants, UtilsEncodingTypes,
  UtilsEncodingSpecialChars, EncodingRoundTripValidator;

type
  // 错误类型
  TErrorType = (etNone, etIOError, etLossyConversion, etSpecialCharError);

  // 转换结果记录
  TConversionResult = record
    Success: Boolean;
    SourceEncoding: string;
    TargetEncoding: string;
    RoundTripSuccess: Boolean;
    SpecialCharsValid: Boolean;
    ErrorMessage: string;
    ErrorType: TErrorType;
    DetailedMessage: string;
    // 添加显式构造函数
    constructor Create(ASuccess: Boolean; const ASourceEncoding, ATargetEncoding: string;
      ARoundTripSuccess, ASpecialCharsValid: Boolean; const AErrorMessage: string; 
      AErrorType: TErrorType; const ADetailedMessage: string = '');
  end;

  // 高级UTF-8 BOM转换器
  TUTF8BOMConverter_Advanced = class
  private
    class var FRoundTripValidator: TRoundTripValidator;
    class var FSpecialCharValidator: TSpecialCharValidator;
    class var FLogEnabled: Boolean;
    
    class function PerformRoundTripValidation(const SourceFile: string; 
      TargetWithBOM: Boolean): TConversionResult;
    class function ValidateSpecialChars(const SourceFile, TargetFile: string;
      const SourceEncoding, TargetEncoding: string): TConversionResult;
    class function CompareFileContents(const File1, File2: string): Boolean;
    class function IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
    class procedure LogMessage(const Msg: string);
    class function GetTempFileName: string;
    class function IfThen(Condition: Boolean; const TrueStr, FalseStr: string): string; overload;
    class function IfThen(Condition: Boolean; TrueValue, FalseValue: Integer): Integer; overload;
    
  public
    class constructor Create;
    class destructor Destroy;
    
    // 核心功能
    class function ConvertToUTF8WithBOM(const SourceFile: string; 
      ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
    class function ConvertToUTF8WithoutBOM(const SourceFile: string;
      ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
    class function AddUTF8BOM(const SourceFile: string;
      ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
    class function RemoveUTF8BOM(const SourceFile: string;
      ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
      
    // 批处理功能
    class function BatchProcess(const FileList: TArray<string>; TargetEncoding: string;
      ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TArray<TConversionResult>;
    
    // 工具函数
    class function HasUTF8BOM(const FileName: string): Boolean;
    class function DetectFileEncoding(const FileName: string): string;
    
    // 配置
    class procedure EnableLogging(Enable: Boolean);
    class function IsLoggingEnabled: Boolean;
  end;

implementation

uses
  UtilsEncodingDetect2; 

// 创建TConversionResult记录的构造函数
constructor TConversionResult.Create(ASuccess: Boolean; const ASourceEncoding, ATargetEncoding: string;
  ARoundTripSuccess, ASpecialCharsValid: Boolean; const AErrorMessage: string; 
  AErrorType: TErrorType; const ADetailedMessage: string = '');
begin
  Success := ASuccess;
  SourceEncoding := ASourceEncoding;
  TargetEncoding := ATargetEncoding;
  RoundTripSuccess := ARoundTripSuccess;
  SpecialCharsValid := ASpecialCharsValid;
  ErrorMessage := AErrorMessage;
  ErrorType := AErrorType;
  DetailedMessage := ADetailedMessage;
end;

// 类构造函数
class constructor TUTF8BOMConverter_Advanced.Create;
begin
  FRoundTripValidator := TRoundTripValidator.Create;
  FSpecialCharValidator := TSpecialCharValidator.Create;
  FLogEnabled := True;
end;

// 类析构函数
class destructor TUTF8BOMConverter_Advanced.Destroy;
begin
  FRoundTripValidator.Free;
  FSpecialCharValidator.Free;
end;

// 辅助函数实现
class function TUTF8BOMConverter_Advanced.GetTempFileName: string;
begin
  Result := TPath.GetTempFileName;
end;

class function TUTF8BOMConverter_Advanced.IfThen(Condition: Boolean; const TrueStr, FalseStr: string): string;
begin
  if Condition then
    Result := TrueStr
  else
    Result := FalseStr;
end;

class function TUTF8BOMConverter_Advanced.IfThen(Condition: Boolean; TrueValue, FalseValue: Integer): Integer;
begin
  if Condition then
    Result := TrueValue
  else
    Result := FalseValue;
end;

class procedure TUTF8BOMConverter_Advanced.LogMessage(const Msg: string);
var
  LogText: string;
begin
  if not FLogEnabled then
    Exit;
    
  // 应该调用日志记录器，这里简单实现
  LogText := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + Msg;
  OutputDebugString(PChar(LogText));
end;

class procedure TUTF8BOMConverter_Advanced.EnableLogging(Enable: Boolean);
begin
  FLogEnabled := Enable;
end;

class function TUTF8BOMConverter_Advanced.IsLoggingEnabled: Boolean;
begin
  Result := FLogEnabled;
end;

// 检测文件是否为UTF-8
class function TUTF8BOMConverter_Advanced.IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  BOMBuffer: TBytes;
  I, Count: Integer;
  Len: Int64;
  IsValid: Boolean;
begin
  HasBOM := False;
  Result := False;
  
  if not FileExists(FileName) then
    Exit;
  
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      Len := Stream.Size;
      if Len = 0 then
      begin
        // 空文件，默认认为是UTF-8
        Result := True;
        Exit;
      end;
      
      // 检查BOM
      SetLength(BOMBuffer, 3);
      if Len >= 3 then
      begin
        Stream.ReadBuffer(BOMBuffer[0], 3);
        HasBOM := (BOMBuffer[0] = $EF) and (BOMBuffer[1] = $BB) and (BOMBuffer[2] = $BF);
        
        if HasBOM then
        begin
          // 如果有BOM，则确认是UTF-8
          Result := True;
          Exit;
        end;
      end;
      
      // 重置流位置
      Stream.Position := 0;
      
      // 读取文件内容进行UTF-8验证
      // 对于大文件，只读取前10MB进行检测
      Len := Min(Len, 10 * 1024 * 1024); // 限制为最多10MB
      SetLength(Buffer, Len);
      Stream.ReadBuffer(Buffer[0], Len);
      
      // UTF-8验证
      IsValid := True;
      I := 0;
      while I < Len do
      begin
        if Buffer[I] <= $7F then
        begin
          // ASCII字符
          Inc(I);
          Continue;
        end
        else if Buffer[I] >= $C2 then
        begin
          if Buffer[I] <= $DF then
          begin
            // 2字节序列：110xxxxx 10xxxxxx
            if (I + 1 < Len) and 
               ((Buffer[I + 1] and $C0) = $80) then
              Inc(I, 2)
            else
            begin
              IsValid := False;
              Break;
            end;
          end
          else if Buffer[I] <= $EF then
          begin
            // 3字节序列：1110xxxx 10xxxxxx 10xxxxxx
            if (I + 2 < Len) and 
               ((Buffer[I + 1] and $C0) = $80) and
               ((Buffer[I + 2] and $C0) = $80) then
              Inc(I, 3)
            else
            begin
              IsValid := False;
              Break;
            end;
          end
          else if Buffer[I] <= $F7 then
          begin
            // 4字节序列：11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
            if (I + 3 < Len) and 
               ((Buffer[I + 1] and $C0) = $80) and
               ((Buffer[I + 2] and $C0) = $80) and
               ((Buffer[I + 3] and $C0) = $80) then
              Inc(I, 4)
            else
            begin
              IsValid := False;
              Break;
            end;
          end
          else
          begin
            IsValid := False;
            Break;
          end;
        end
        else
        begin
          IsValid := False;
          Break;
        end;
      end;
      
      Result := IsValid;
    finally
      Stream.Free;
    end;
  except
    Result := False;
  end;
end;

// 检查文件是否有UTF-8 BOM
class function TUTF8BOMConverter_Advanced.HasUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      if FileStream.Size < 3 then
        Exit;

      SetLength(Buffer, 3);
      FileStream.ReadBuffer(Buffer[0], 3);

      Result := (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);
    finally
      FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

// 检测文件编码
class function TUTF8BOMConverter_Advanced.DetectFileEncoding(const FileName: string): string;
var
  Detector: TEncodingDetector2;
  Result2: TEncodingDetectionResult;
begin
  if not FileExists(FileName) then
  begin
    Result := ENCODING_UNKNOWN;
    Exit;
  end;
  
  Detector := TEncodingDetector2.Create;
  try
    Result2 := Detector.DetectFileEncoding(FileName);
    Result := Result2.Encoding;
  finally
    Detector.Free;
  end;
end;

class function TUTF8BOMConverter_Advanced.PerformRoundTripValidation(const SourceFile: string; 
  TargetWithBOM: Boolean): TConversionResult;
begin
  // Implementation of PerformRoundTripValidation method
  Result := Default(TConversionResult);
end;

class function TUTF8BOMConverter_Advanced.ValidateSpecialChars(const SourceFile, TargetFile: string;
  const SourceEncoding, TargetEncoding: string): TConversionResult;
begin
  // Implementation of ValidateSpecialChars method
  Result := Default(TConversionResult);
end;

class function TUTF8BOMConverter_Advanced.CompareFileContents(const File1, File2: string): Boolean;
begin
  // Implementation of CompareFileContents method
  Result := False;
end;

// 将文件转换为UTF-8并添加BOM
class function TUTF8BOMConverter_Advanced.ConvertToUTF8WithBOM(const SourceFile: string;
  ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
var
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TempFile: string;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Content: string;
  Buffer, BOM: TBytes;
  SourceEncoding: string;
  RoundTripResult: TRoundTripValidationResult;
  SpecialCharResult: TSpecialCharValidationResult;
  DetailedMsg: TStringBuilder;
  BackupFile: string;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, False, '', etNone);
  DetailedMsg := TStringBuilder.Create;
  try
    DetailedMsg.AppendLine('转换为UTF-8+BOM操作:');
    DetailedMsg.AppendLine('源文件: ' + SourceFile);
    
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      LogMessage('源文件不存在: ' + SourceFile);
      Result.ErrorMessage := '源文件不存在';
      Result.ErrorType := etIOError;
      DetailedMsg.AppendLine('错误: 源文件不存在');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    // 检查文件是否已经是UTF-8+BOM
    IsUTF8 := IsUTF8File(SourceFile, HasBOM);
    
    if IsUTF8 and HasBOM then
    begin
      // 如果已经是UTF-8+BOM，则不需要转换
      LogMessage('文件已经是UTF-8带BOM: ' + SourceFile);
      Result := TConversionResult.Create(True, 'UTF-8 with BOM', 'UTF-8 with BOM', 
                                       True, True, '', etNone);
      DetailedMsg.AppendLine('文件已经是UTF-8带BOM，无需转换');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    if IsUTF8 and not HasBOM then
    begin
      // 如果是UTF-8但没有BOM，则添加BOM
      LogMessage('文件是UTF-8但没有BOM，添加BOM: ' + SourceFile);
      Result := AddUTF8BOM(SourceFile, ValidateRoundTrip, ValidateSpecialChars);
      Exit;
    end;
    
    // 确定源文件编码
    SourceEncoding := DetectFileEncoding(SourceFile);
    if SourceEncoding = ENCODING_UNKNOWN then
      SourceEncoding := 'ansi'; // 默认使用ANSI
      
    DetailedMsg.AppendLine('检测到的源编码: ' + SourceEncoding);
    
    // 创建临时文件
    TempFile := GetTempFileName;
    BackupFile := SourceFile + '.bak';
    
    try
      // 读取原始文件内容
      FileStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
      try
        SetLength(Buffer, FileStream.Size);
        if FileStream.Size > 0 then
          FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      finally
        FileStream.Free;
      end;
      
      // 转换内容为字符串
      case SourceEncoding of
        ENCODING_UTF8, ENCODING_UTF8_BOM:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
              Content := TEncoding.UTF8.GetString(Buffer, 3, Length(Buffer) - 3)
            else
              Content := TEncoding.UTF8.GetString(Buffer);
          end;
        ENCODING_UTF16_LE:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
              Content := TEncoding.Unicode.GetString(Buffer, 2, Length(Buffer) - 2)
            else
              Content := TEncoding.Unicode.GetString(Buffer);
          end;
        ENCODING_UTF16_BE:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
              Content := TEncoding.BigEndianUnicode.GetString(Buffer, 2, Length(Buffer) - 2)
            else
              Content := TEncoding.BigEndianUnicode.GetString(Buffer);
          end;
        ENCODING_GB18030, ENCODING_GBK:
          begin
            var CP := 936; // GBK/GB18030代码页
            if Length(Buffer) = 0 then
              Content := ''
            else
            begin
              var WideLen := MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), nil, 0);
              if WideLen <= 0 then
                Content := ''
              else
              begin
                SetLength(Content, WideLen);
                MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), PWideChar(Content), WideLen);
              end;
            end;
          end;
        ENCODING_BIG5:
          begin
            var CP := 950; // Big5代码页
            if Length(Buffer) = 0 then
              Content := ''
            else
            begin
              var WideLen := MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), nil, 0);
              if WideLen <= 0 then
                Content := ''
              else
              begin
                SetLength(Content, WideLen);
                MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), PWideChar(Content), WideLen);
              end;
            end;
          end;
        else
          Content := TEncoding.Default.GetString(Buffer);
      end;
      
      // 创建UTF-8 BOM
      SetLength(BOM, 3);
      BOM[0] := $EF;
      BOM[1] := $BB;
      BOM[2] := $BF;
      
      // 创建UTF-8编码的文件
      MemStream := TMemoryStream.Create;
      try
        // 写入BOM
        MemStream.WriteBuffer(BOM[0], 3);
        
        // 转换内容为UTF-8并写入
        Buffer := TEncoding.UTF8.GetBytes(Content);
        if Length(Buffer) > 0 then
          MemStream.WriteBuffer(Buffer[0], Length(Buffer));
        
        // 保存到临时文件
        MemStream.SaveToFile(TempFile);
      finally
        MemStream.Free;
      end;
      
      // 验证特殊字符 (如果启用)
      if ValidateSpecialChars then
      begin
        DetailedMsg.AppendLine('执行特殊字符验证...');
        SpecialCharResult := FSpecialCharValidator.ValidateSpecialChars(
          SourceFile, TempFile, SourceEncoding, 'utf-8-bom');
          
        if not SpecialCharResult.Success then
        begin
          LogMessage('特殊字符验证失败: ' + SourceFile);
          Result.ErrorMessage := '特殊字符验证失败: 某些字符可能丢失';
          Result.ErrorType := etSpecialCharError;
          DetailedMsg.AppendLine('特殊字符验证失败: ');
          DetailedMsg.AppendLine(SpecialCharResult.DetailedMessage);
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('特殊字符验证成功');
      end;
      
      // 备份原始文件
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      if not RenameFile(SourceFile, BackupFile) then
      begin
        LogMessage('无法创建备份文件: ' + BackupFile);
        Result.ErrorMessage := '无法创建备份文件';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法创建备份文件');
        Result.DetailedMessage := DetailedMsg.ToString;
        DeleteFile(TempFile);
        Exit;
      end;
      
      // 将临时文件移动到源文件位置
      if not RenameFile(TempFile, SourceFile) then
      begin
        LogMessage('无法将临时文件移动到目标位置: ' + TempFile + ' -> ' + SourceFile);
        Result.ErrorMessage := '无法将临时文件移动到目标位置';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法将临时文件移动到目标位置');
        Result.DetailedMessage := DetailedMsg.ToString;
        // 恢复备份
        RenameFile(BackupFile, SourceFile);
        Exit;
      end;
      
      // 验证往返转换 (如果启用)
      if ValidateRoundTrip then
      begin
        DetailedMsg.AppendLine('执行往返转换验证...');
        RoundTripResult := FRoundTripValidator.ValidateRoundTrip(
          SourceFile, 'utf-8-bom', SourceEncoding);
          
        if not RoundTripResult.Success then
        begin
          LogMessage('往返转换验证失败: ' + SourceFile);
          Result.ErrorMessage := '往返转换验证失败: 内容可能无法正确还原';
          Result.ErrorType := etLossyConversion;
          DetailedMsg.AppendLine('往返转换验证失败: ');
          DetailedMsg.AppendLine(RoundTripResult.DetailedMessage);
          
          // 恢复原始文件
          DeleteFile(SourceFile);
          RenameFile(BackupFile, SourceFile);
          
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('往返转换验证成功');
      end;
      
      // 如果成功，删除备份
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      // 设置结果
      Result := TConversionResult.Create(True, SourceEncoding, 'UTF-8 with BOM', 
                                       ValidateRoundTrip, ValidateSpecialChars, '', etNone);
      
      DetailedMsg.AppendLine('操作成功完成');
      Result.DetailedMessage := DetailedMsg.ToString;
      LogMessage('成功将文件转换为UTF-8带BOM: ' + SourceFile);
    except
      on E: Exception do
      begin
        LogMessage('将文件转换为UTF-8带BOM时出错: ' + SourceFile + ' - ' + E.Message);
        Result.ErrorMessage := '转换为UTF-8带BOM出错: ' + E.Message;
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('异常: ' + E.Message);
        Result.DetailedMessage := DetailedMsg.ToString;
        
        // 清理临时文件
        if FileExists(TempFile) then
          DeleteFile(TempFile);
        
        // 恢复备份
        if FileExists(BackupFile) then
          RenameFile(BackupFile, SourceFile);
      end;
    end;
  finally
    DetailedMsg.Free;
    // 确保删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

// 将文件转换为UTF-8并去除BOM
class function TUTF8BOMConverter_Advanced.ConvertToUTF8WithoutBOM(const SourceFile: string;
  ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
var
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TempFile: string;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Content: string;
  Buffer: TBytes;
  SourceEncoding: string;
  RoundTripResult: TRoundTripValidationResult;
  SpecialCharResult: TSpecialCharValidationResult;
  DetailedMsg: TStringBuilder;
  BackupFile: string;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, False, '', etNone);
  DetailedMsg := TStringBuilder.Create;
  try
    DetailedMsg.AppendLine('转换为UTF-8无BOM操作:');
    DetailedMsg.AppendLine('源文件: ' + SourceFile);
    
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      LogMessage('源文件不存在: ' + SourceFile);
      Result.ErrorMessage := '源文件不存在';
      Result.ErrorType := etIOError;
      DetailedMsg.AppendLine('错误: 源文件不存在');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    // 检查文件是否已经是UTF-8无BOM
    IsUTF8 := IsUTF8File(SourceFile, HasBOM);
    
    if IsUTF8 and not HasBOM then
    begin
      // 如果已经是UTF-8无BOM，则不需要转换
      LogMessage('文件已经是UTF-8不带BOM: ' + SourceFile);
      Result := TConversionResult.Create(True, 'UTF-8 without BOM', 'UTF-8 without BOM', 
                                       True, True, '', etNone);
      DetailedMsg.AppendLine('文件已经是UTF-8不带BOM，无需转换');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    if IsUTF8 and HasBOM then
    begin
      // 如果是UTF-8带BOM，则移除BOM
      LogMessage('文件是UTF-8带BOM，移除BOM: ' + SourceFile);
      Result := RemoveUTF8BOM(SourceFile, ValidateRoundTrip, ValidateSpecialChars);
      Exit;
    end;
    
    // 确定源文件编码
    SourceEncoding := DetectFileEncoding(SourceFile);
    if SourceEncoding = ENCODING_UNKNOWN then
      SourceEncoding := 'ansi'; // 默认使用ANSI
      
    DetailedMsg.AppendLine('检测到的源编码: ' + SourceEncoding);
    
    // 创建临时文件
    TempFile := GetTempFileName;
    BackupFile := SourceFile + '.bak';
    
    try
      // 读取原始文件内容
      FileStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
      try
        SetLength(Buffer, FileStream.Size);
        if FileStream.Size > 0 then
          FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      finally
        FileStream.Free;
      end;
      
      // 转换内容为字符串
      case SourceEncoding of
        ENCODING_UTF8, ENCODING_UTF8_BOM:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
              Content := TEncoding.UTF8.GetString(Buffer, 3, Length(Buffer) - 3)
            else
              Content := TEncoding.UTF8.GetString(Buffer);
          end;
        ENCODING_UTF16_LE:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
              Content := TEncoding.Unicode.GetString(Buffer, 2, Length(Buffer) - 2)
            else
              Content := TEncoding.Unicode.GetString(Buffer);
          end;
        ENCODING_UTF16_BE:
          begin
            // 如果有BOM，跳过
            if (Length(Buffer) >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
              Content := TEncoding.BigEndianUnicode.GetString(Buffer, 2, Length(Buffer) - 2)
            else
              Content := TEncoding.BigEndianUnicode.GetString(Buffer);
          end;
        ENCODING_GB18030, ENCODING_GBK:
          begin
            var CP := 936; // GBK/GB18030代码页
            if Length(Buffer) = 0 then
              Content := ''
            else
            begin
              var WideLen := MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), nil, 0);
              if WideLen <= 0 then
                Content := ''
              else
              begin
                SetLength(Content, WideLen);
                MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), PWideChar(Content), WideLen);
              end;
            end;
          end;
        ENCODING_BIG5:
          begin
            var CP := 950; // Big5代码页
            if Length(Buffer) = 0 then
              Content := ''
            else
            begin
              var WideLen := MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), nil, 0);
              if WideLen <= 0 then
                Content := ''
              else
              begin
                SetLength(Content, WideLen);
                MultiByteToWideChar(CP, 0, @Buffer[0], Length(Buffer), PWideChar(Content), WideLen);
              end;
            end;
          end;
        else
          Content := TEncoding.Default.GetString(Buffer);
      end;
      
      // 创建UTF-8编码的文件（不带BOM）
      MemStream := TMemoryStream.Create;
      try
        // 转换内容为UTF-8并写入
        Buffer := TEncoding.UTF8.GetBytes(Content);
        if Length(Buffer) > 0 then
          MemStream.WriteBuffer(Buffer[0], Length(Buffer));
        
        // 保存到临时文件
        MemStream.SaveToFile(TempFile);
      finally
        MemStream.Free;
      end;
      
      // 验证特殊字符 (如果启用)
      if ValidateSpecialChars then
      begin
        DetailedMsg.AppendLine('执行特殊字符验证...');
        SpecialCharResult := FSpecialCharValidator.ValidateSpecialChars(
          SourceFile, TempFile, SourceEncoding, 'utf-8');
          
        if not SpecialCharResult.Success then
        begin
          LogMessage('特殊字符验证失败: ' + SourceFile);
          Result.ErrorMessage := '特殊字符验证失败: 某些字符可能丢失';
          Result.ErrorType := etSpecialCharError;
          DetailedMsg.AppendLine('特殊字符验证失败: ');
          DetailedMsg.AppendLine(SpecialCharResult.DetailedMessage);
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('特殊字符验证成功');
      end;
      
      // 备份原始文件
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      if not RenameFile(SourceFile, BackupFile) then
      begin
        LogMessage('无法创建备份文件: ' + BackupFile);
        Result.ErrorMessage := '无法创建备份文件';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法创建备份文件');
        Result.DetailedMessage := DetailedMsg.ToString;
        DeleteFile(TempFile);
        Exit;
      end;
      
      // 将临时文件移动到源文件位置
      if not RenameFile(TempFile, SourceFile) then
      begin
        LogMessage('无法将临时文件移动到目标位置: ' + TempFile + ' -> ' + SourceFile);
        Result.ErrorMessage := '无法将临时文件移动到目标位置';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法将临时文件移动到目标位置');
        Result.DetailedMessage := DetailedMsg.ToString;
        // 恢复备份
        RenameFile(BackupFile, SourceFile);
        Exit;
      end;
      
      // 验证往返转换 (如果启用)
      if ValidateRoundTrip then
      begin
        DetailedMsg.AppendLine('执行往返转换验证...');
        RoundTripResult := FRoundTripValidator.ValidateRoundTrip(
          SourceFile, 'utf-8', SourceEncoding);
          
        if not RoundTripResult.Success then
        begin
          LogMessage('往返转换验证失败: ' + SourceFile);
          Result.ErrorMessage := '往返转换验证失败: 内容可能无法正确还原';
          Result.ErrorType := etLossyConversion;
          DetailedMsg.AppendLine('往返转换验证失败: ');
          DetailedMsg.AppendLine(RoundTripResult.DetailedMessage);
          
          // 恢复原始文件
          DeleteFile(SourceFile);
          RenameFile(BackupFile, SourceFile);
          
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('往返转换验证成功');
      end;
      
      // 如果成功，删除备份
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      // 设置结果
      Result := TConversionResult.Create(True, SourceEncoding, 'UTF-8 without BOM', 
                                       ValidateRoundTrip, ValidateSpecialChars, '', etNone);
      
      DetailedMsg.AppendLine('操作成功完成');
      Result.DetailedMessage := DetailedMsg.ToString;
      LogMessage('成功将文件转换为UTF-8不带BOM: ' + SourceFile);
    except
      on E: Exception do
      begin
        LogMessage('将文件转换为UTF-8不带BOM时出错: ' + SourceFile + ' - ' + E.Message);
        Result.ErrorMessage := '转换为UTF-8不带BOM出错: ' + E.Message;
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('异常: ' + E.Message);
        Result.DetailedMessage := DetailedMsg.ToString;
        
        // 清理临时文件
        if FileExists(TempFile) then
          DeleteFile(TempFile);
        
        // 恢复备份
        if FileExists(BackupFile) then
          RenameFile(BackupFile, SourceFile);
      end;
    end;
  finally
    DetailedMsg.Free;
    // 确保删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

// 从文件中移除UTF-8 BOM
class function TUTF8BOMConverter_Advanced.RemoveUTF8BOM(const SourceFile: string;
  ValidateRoundTrip: Boolean = True; ValidateSpecialChars: Boolean = True): TConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TargetFile, BackupFile, OriginalFile: string;
  Position: Int64;
  ValidationResult: TConversionResult;
  RoundTripResult: TRoundTripValidationResult;
  SpecialCharResult: TSpecialCharValidationResult;
  DetailedMsg: TStringBuilder;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, False, '', etNone);
  DetailedMsg := TStringBuilder.Create;
  try
    DetailedMsg.AppendLine('移除UTF-8 BOM操作:');
    DetailedMsg.AppendLine('源文件: ' + SourceFile);
    
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      LogMessage('源文件不存在: ' + SourceFile);
      Result.ErrorMessage := '源文件不存在';
      Result.ErrorType := etIOError;
      DetailedMsg.AppendLine('错误: 源文件不存在');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    // 检查文件是否是UTF-8并且有BOM
    IsUTF8 := IsUTF8File(SourceFile, HasBOM);
    
    if not HasBOM then
    begin
      // 如果没有BOM，则不需要操作
      LogMessage('文件没有UTF-8 BOM: ' + SourceFile);
      Result := TConversionResult.Create(True, 'UTF-8 without BOM', 'UTF-8 without BOM', 
                                      True, True, '', etNone);
      DetailedMsg.AppendLine('文件已经没有UTF-8 BOM, 无需转换');
      Result.DetailedMessage := DetailedMsg.ToString;
      Exit;
    end;
    
    // 创建临时文件
    TargetFile := GetTempFileName;
    BackupFile := SourceFile + '.bak';
    OriginalFile := SourceFile;
    
    try
      // 读取源文件
      SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
      try
        SetLength(Buffer, SourceStream.Size);
        if SourceStream.Size > 0 then
          SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);
      finally
        SourceStream.Free;
      end;
      
      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFile, fmCreate);
      try
        // 跳过BOM
        Position := 3; // UTF-8 BOM的长度
        if Length(Buffer) > Position then
          TargetStream.WriteBuffer(Buffer[Position], Length(Buffer) - Position);
      finally
        TargetStream.Free;
      end;
      
      // 验证特殊字符 (如果启用)
      if ValidateSpecialChars then
      begin
        DetailedMsg.AppendLine('执行特殊字符验证...');
        SpecialCharResult := FSpecialCharValidator.ValidateSpecialChars(
          SourceFile, TargetFile, 'utf-8-bom', 'utf-8');
          
        if not SpecialCharResult.Success then
        begin
          LogMessage('特殊字符验证失败: ' + SourceFile);
          Result.ErrorMessage := '特殊字符验证失败: 某些字符可能丢失';
          Result.ErrorType := etSpecialCharError;
          DetailedMsg.AppendLine('特殊字符验证失败: ');
          DetailedMsg.AppendLine(SpecialCharResult.DetailedMessage);
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('特殊字符验证成功');
      end;
      
      // 备份原始文件
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      if not RenameFile(SourceFile, BackupFile) then
      begin
        LogMessage('无法创建备份文件: ' + BackupFile);
        Result.ErrorMessage := '无法创建备份文件';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法创建备份文件');
        Result.DetailedMessage := DetailedMsg.ToString;
        DeleteFile(TargetFile);
        Exit;
      end;
      
      // 将临时文件移动到源文件位置
      if not RenameFile(TargetFile, SourceFile) then
      begin
        LogMessage('无法将临时文件移动到目标位置: ' + TargetFile + ' -> ' + SourceFile);
        Result.ErrorMessage := '无法将临时文件移动到目标位置';
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('错误: 无法将临时文件移动到目标位置');
        Result.DetailedMessage := DetailedMsg.ToString;
        // 恢复备份
        RenameFile(BackupFile, SourceFile);
        Exit;
      end;
      
      // 验证往返转换 (如果启用)
      if ValidateRoundTrip then
      begin
        DetailedMsg.AppendLine('执行往返转换验证...');
        RoundTripResult := FRoundTripValidator.ValidateRoundTrip(
          SourceFile, 'utf-8', 'utf-8-bom');
          
        if not RoundTripResult.Success then
        begin
          LogMessage('往返转换验证失败: ' + SourceFile);
          Result.ErrorMessage := '往返转换验证失败: 内容可能无法正确还原';
          Result.ErrorType := etLossyConversion;
          DetailedMsg.AppendLine('往返转换验证失败: ');
          DetailedMsg.AppendLine(RoundTripResult.DetailedMessage);
          
          // 恢复原始文件
          DeleteFile(SourceFile);
          RenameFile(BackupFile, SourceFile);
          
          Result.DetailedMessage := DetailedMsg.ToString;
          Exit;
        end;
        
        DetailedMsg.AppendLine('往返转换验证成功');
      end;
      
      // 如果成功，删除备份
      if FileExists(BackupFile) then
        DeleteFile(BackupFile);
      
      // 设置结果
      Result := TConversionResult.Create(True, 'UTF-8 with BOM', 'UTF-8 without BOM', 
                                      ValidateRoundTrip, ValidateSpecialChars, '', etNone);
      
      DetailedMsg.AppendLine('操作成功完成');
      Result.DetailedMessage := DetailedMsg.ToString;
      LogMessage('成功从文件删除UTF-8 BOM: ' + SourceFile);
    except
      on E: Exception do
      begin
        LogMessage('从文件删除UTF-8 BOM时出错: ' + SourceFile + ' - ' + E.Message);
        Result.ErrorMessage := '删除UTF-8 BOM出错: ' + E.Message;
        Result.ErrorType := etIOError;
        DetailedMsg.AppendLine('异常: ' + E.Message);
        Result.DetailedMessage := DetailedMsg.ToString;
        
        // 清理临时文件
        if FileExists(TargetFile) then
          DeleteFile(TargetFile);
        
        // 恢复备份
        if FileExists(BackupFile) and not FileExists(OriginalFile) then
          RenameFile(BackupFile, OriginalFile);
      end;
    end;
  finally
    DetailedMsg.Free;
  end;
end;

// 执行批量处理
class function TUTF8BOMConverter_Advanced.BatchProcess(const FileList: TArray<string>; 
  TargetEncoding: string; ValidateRoundTrip: Boolean = True; 
  ValidateSpecialChars: Boolean = True): TArray<TConversionResult>;
var
  I: Integer;
  TempResults: TList<TConversionResult>;
begin
  TempResults := TList<TConversionResult>.Create;
  try
    LogMessage('开始批量处理 ' + IntToStr(Length(FileList)) + ' 个文件...');
    
    for I := 0 to Length(FileList) - 1 do
    begin
      if not FileExists(FileList[I]) then
      begin
        LogMessage('文件不存在，跳过: ' + FileList[I]);
        TempResults.Add(TConversionResult.Create(False, '', '', False, False, 
                                              '文件不存在', etIOError));
        Continue;
      end;
      
      LogMessage('处理文件 ' + IntToStr(I+1) + '/' + IntToStr(Length(FileList)) + ': ' + FileList[I]);
      
      if TargetEncoding = 'utf-8-bom' then
        TempResults.Add(ConvertToUTF8WithBOM(FileList[I], ValidateRoundTrip, ValidateSpecialChars))
      else if TargetEncoding = 'utf-8' then
        TempResults.Add(ConvertToUTF8WithoutBOM(FileList[I], ValidateRoundTrip, ValidateSpecialChars))
      else
      begin
        LogMessage('不支持的目标编码: ' + TargetEncoding);
        TempResults.Add(TConversionResult.Create(False, '', '', False, False, 
                                              '不支持的目标编码: ' + TargetEncoding, etIOError));
      end;
    end;
    
    LogMessage('批量处理完成，共处理 ' + IntToStr(TempResults.Count) + ' 个文件');
    
    // 转换为数组
    SetLength(Result, TempResults.Count);
    for I := 0 to TempResults.Count - 1 do
      Result[I] := TempResults[I];
  finally
    TempResults.Free;
  end;
end;

class function TUTF8BOMConverter_Advanced.HasUTF8BOM(const FileName: string): Boolean;
begin
  // Implementation of HasUTF8BOM method
  Result := False;
end;

class function TUTF8BOMConverter_Advanced.DetectFileEncoding(const FileName: string): string;
begin
  // Implementation of DetectFileEncoding method
  Result := ENCODING_UNKNOWN;
end;

class function TUTF8BOMConverter_Advanced.EnableLogging(Enable: Boolean): Boolean;
begin
  // Implementation of EnableLogging method
  Result := False;
end;

class function TUTF8BOMConverter_Advanced.IsLoggingEnabled: Boolean;
begin
  // Implementation of IsLoggingEnabled method
  Result := False;
end;
end. 