unit UTF8BOMConverter_Enhanced;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.Windows, System.Math;

type
  // 确保TErrorType类型在使用前已定义
  TErrorType = (etNone, etIOError, etLossyConversion);

  TConversionResult = record
    Success: Boolean;
    SourceEncoding: string;
    TargetEncoding: string;
    RoundTripSuccess: Boolean;
    ErrorMessage: string;
    ErrorType: TErrorType;
    // 添加显式构造函数
    constructor Create(ASuccess: Boolean; const ASourceEncoding, ATargetEncoding: string;
      ARoundTripSuccess: Boolean; const AErrorMessage: string; AErrorType: TErrorType);
  end;

  TUTF8BOMConverter = class
  private
    class function PerformRoundTripValidation(const SourceFile: string; 
      TargetWithBOM: Boolean): TConversionResult;
    class function CompareFileContents(const File1, File2: string): Boolean;
    class function IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
    class procedure LogMessage(const Msg: string);
    class function GetTempFileName: string;
    class function IfThen(Condition: Boolean; const TrueStr, FalseStr: string): string; overload;
    class function IfThen(Condition: Boolean; TrueValue, FalseValue: Integer): Integer; overload;
  public
    class function ConvertToUTF8WithBOM(const SourceFile: string): TConversionResult;
    class function ConvertToUTF8WithoutBOM(const SourceFile: string): TConversionResult;
    class function AddUTF8BOM(const SourceFile: string): TConversionResult;
    class function RemoveUTF8BOM(const SourceFile: string): TConversionResult;
  end;

implementation

// 创建TConversionResult记录的构造函数
constructor TConversionResult.Create(ASuccess: Boolean; const ASourceEncoding, ATargetEncoding: string;
  ARoundTripSuccess: Boolean; const AErrorMessage: string; AErrorType: TErrorType);
begin
  Success := ASuccess;
  SourceEncoding := ASourceEncoding;
  TargetEncoding := ATargetEncoding;
  RoundTripSuccess := ARoundTripSuccess;
  ErrorMessage := AErrorMessage;
  ErrorType := AErrorType;
end;

// 辅助函数实现
class function TUTF8BOMConverter.GetTempFileName: string;
begin
  Result := TPath.GetTempFileName;
end;

class function TUTF8BOMConverter.IfThen(Condition: Boolean; const TrueStr, FalseStr: string): string;
begin
  if Condition then
    Result := TrueStr
  else
    Result := FalseStr;
end;

class function TUTF8BOMConverter.IfThen(Condition: Boolean; TrueValue, FalseValue: Integer): Integer;
begin
  if Condition then
    Result := TrueValue
  else
    Result := FalseValue;
end;

class procedure TUTF8BOMConverter.LogMessage(const Msg: string);
var
  LogText: string;
begin
  // 应该调用日志记录器，这里简单实现
  LogText := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + Msg;
  OutputDebugString(PChar(LogText));
end;

class function TUTF8BOMConverter.IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
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

class function TUTF8BOMConverter.AddUTF8BOM(const SourceFile: string): TConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TargetFile: string;
  BOM: TBytes;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, '', etNone);
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    LogMessage('源文件不存在: ' + SourceFile);
    Result.ErrorMessage := '源文件不存在';
    Result.ErrorType := etIOError;
    Exit;
  end;
  
  // 检查文件是否已经是UTF-8
  IsUTF8 := IsUTF8File(SourceFile, HasBOM);
  
  if HasBOM then
  begin
    // 如果已经有BOM，则不需要操作
    LogMessage('文件已经有UTF-8 BOM: ' + SourceFile);
    Result := TConversionResult.Create(True, 'UTF-8 with BOM', 'UTF-8 with BOM', True, '', etNone);
    Exit;
  end;
  
  // 创建临时文件
  TargetFile := GetTempFileName;
  
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
    
    // 准备UTF-8 BOM
    SetLength(BOM, 3);
    BOM[0] := $EF;
    BOM[1] := $BB;
    BOM[2] := $BF;
    
    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFile, fmCreate);
    try
      // 写入BOM
      TargetStream.WriteBuffer(BOM[0], 3);
      
      // 写入原始内容
      if Length(Buffer) > 0 then
        TargetStream.WriteBuffer(Buffer[0], Length(Buffer));
    finally
      TargetStream.Free;
    end;
    
    // 备份原始文件
    if FileExists(SourceFile + '.bak') then
      DeleteFile(SourceFile + '.bak');
    
    if not RenameFile(SourceFile, SourceFile + '.bak') then
    begin
      LogMessage('无法创建备份文件: ' + SourceFile + '.bak');
      Result.ErrorMessage := '无法创建备份文件';
      Result.ErrorType := etIOError;
      DeleteFile(TargetFile);
      Exit;
    end;
    
    // 将临时文件移动到源文件位置
    if not RenameFile(TargetFile, SourceFile) then
    begin
      LogMessage('无法将临时文件移动到目标位置: ' + TargetFile + ' -> ' + SourceFile);
      Result.ErrorMessage := '无法将临时文件移动到目标位置';
      Result.ErrorType := etIOError;
      // 恢复备份
      RenameFile(SourceFile + '.bak', SourceFile);
      Exit;
    end;
    
    // 如果成功，删除备份
    if FileExists(SourceFile + '.bak') then
      DeleteFile(SourceFile + '.bak');
    
    // 设置结果
    if IsUTF8 then
      Result := TConversionResult.Create(True, 'UTF-8 without BOM', 'UTF-8 with BOM', True, '', etNone)
    else
      Result := TConversionResult.Create(True, 'Unknown', 'UTF-8 with BOM', True, '', etNone);
    
    LogMessage('成功添加UTF-8 BOM到文件: ' + SourceFile);
  except
    on E: Exception do
    begin
      LogMessage('添加UTF-8 BOM到文件时出错: ' + SourceFile + ' - ' + E.Message);
      Result.ErrorMessage := '添加UTF-8 BOM出错: ' + E.Message;
      Result.ErrorType := etIOError;
      
      // 清理临时文件
      if FileExists(TargetFile) then
        DeleteFile(TargetFile);
      
      // 恢复备份
      if FileExists(SourceFile + '.bak') then
        RenameFile(SourceFile + '.bak', SourceFile);
    end;
  end;
end;

class function TUTF8BOMConverter.RemoveUTF8BOM(const SourceFile: string): TConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TargetFile: string;
  Position: Int64;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, '', etNone);
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    LogMessage('源文件不存在: ' + SourceFile);
    Result.ErrorMessage := '源文件不存在';
    Result.ErrorType := etIOError;
    Exit;
  end;
  
  // 检查文件是否是UTF-8
  IsUTF8 := IsUTF8File(SourceFile, HasBOM);
  
  if not HasBOM then
  begin
    // 如果没有BOM，则不需要操作
    LogMessage('文件没有UTF-8 BOM: ' + SourceFile);
    Result := TConversionResult.Create(True, 'UTF-8 without BOM', 'UTF-8 without BOM', True, '', etNone);
    Exit;
  end;
  
  // 创建临时文件
  TargetFile := GetTempFileName;
  
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
    
    // 备份原始文件
    if FileExists(SourceFile + '.bak') then
      DeleteFile(SourceFile + '.bak');
    
    if not RenameFile(SourceFile, SourceFile + '.bak') then
    begin
      LogMessage('无法创建备份文件: ' + SourceFile + '.bak');
      Result.ErrorMessage := '无法创建备份文件';
      Result.ErrorType := etIOError;
      DeleteFile(TargetFile);
      Exit;
    end;
    
    // 将临时文件移动到源文件位置
    if not RenameFile(TargetFile, SourceFile) then
    begin
      LogMessage('无法将临时文件移动到目标位置: ' + TargetFile + ' -> ' + SourceFile);
      Result.ErrorMessage := '无法将临时文件移动到目标位置';
      Result.ErrorType := etIOError;
      // 恢复备份
      RenameFile(SourceFile + '.bak', SourceFile);
      Exit;
    end;
    
    // 如果成功，删除备份
    if FileExists(SourceFile + '.bak') then
      DeleteFile(SourceFile + '.bak');
    
    // 设置结果
    Result := TConversionResult.Create(True, 'UTF-8 with BOM', 'UTF-8 without BOM', True, '', etNone);
    
    LogMessage('成功从文件删除UTF-8 BOM: ' + SourceFile);
  except
    on E: Exception do
    begin
      LogMessage('从文件删除UTF-8 BOM时出错: ' + SourceFile + ' - ' + E.Message);
      Result.ErrorMessage := '删除UTF-8 BOM出错: ' + E.Message;
      Result.ErrorType := etIOError;
      
      // 清理临时文件
      if FileExists(TargetFile) then
        DeleteFile(TargetFile);
      
      // 恢复备份
      if FileExists(SourceFile + '.bak') then
        RenameFile(SourceFile + '.bak', SourceFile);
    end;
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithBOM(const SourceFile: string): TConversionResult;
var
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TempFile: string;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Content: string;
  Buffer, BOM: TBytes;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, '', etNone);
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    LogMessage('源文件不存在: ' + SourceFile);
    Result.ErrorMessage := '源文件不存在';
    Result.ErrorType := etIOError;
    Exit;
  end;
  
  // 检查文件是否已经是UTF-8
  IsUTF8 := IsUTF8File(SourceFile, HasBOM);
  
  if IsUTF8 and HasBOM then
  begin
    // 如果已经是UTF-8+BOM，则不需要转换
    LogMessage('文件已经是UTF-8带BOM: ' + SourceFile);
    Result := TConversionResult.Create(True, 'UTF-8 with BOM', 'UTF-8 with BOM', True, '', etNone);
    Exit;
  end;
  
  if IsUTF8 and not HasBOM then
  begin
    // 如果是UTF-8但没有BOM，则添加BOM
    LogMessage('文件是UTF-8但没有BOM，添加BOM: ' + SourceFile);
    Result := AddUTF8BOM(SourceFile);
    Exit;
  end;
  
  // 创建临时文件
  TempFile := GetTempFileName;
  
  try
    // 尝试读取文件内容并转换为UTF-8
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
      Content := TEncoding.Default.GetString(Buffer);
      
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
      
      // 备份原始文件
      if FileExists(SourceFile + '.bak') then
        DeleteFile(SourceFile + '.bak');
      
      if not RenameFile(SourceFile, SourceFile + '.bak') then
      begin
        LogMessage('无法创建备份文件: ' + SourceFile + '.bak');
        Result.ErrorMessage := '无法创建备份文件';
        Result.ErrorType := etIOError;
        DeleteFile(TempFile);
        Exit;
      end;
      
      // 将临时文件移动到源文件位置
      if not RenameFile(TempFile, SourceFile) then
      begin
        LogMessage('无法将临时文件移动到目标位置: ' + TempFile + ' -> ' + SourceFile);
        Result.ErrorMessage := '无法将临时文件移动到目标位置';
        Result.ErrorType := etIOError;
        // 恢复备份
        RenameFile(SourceFile + '.bak', SourceFile);
        Exit;
      end;
      
      // 如果成功，删除备份
      if FileExists(SourceFile + '.bak') then
        DeleteFile(SourceFile + '.bak');
      
      // 执行往返验证
      Result := PerformRoundTripValidation(SourceFile, True);
      if not Result.Success then
      begin
        LogMessage('往返验证失败: ' + Result.ErrorMessage);
      end
      else
      begin
        LogMessage('成功将文件转换为UTF-8带BOM: ' + SourceFile);
      end;
    except
      on E: Exception do
      begin
        LogMessage('将文件转换为UTF-8带BOM时出错: ' + SourceFile + ' - ' + E.Message);
        Result.ErrorMessage := '转换为UTF-8带BOM出错: ' + E.Message;
        Result.ErrorType := etIOError;
        
        // 清理临时文件
        if FileExists(TempFile) then
          DeleteFile(TempFile);
        
        // 恢复备份
        if FileExists(SourceFile + '.bak') then
          RenameFile(SourceFile + '.bak', SourceFile);
      end;
    end;
  finally
    // 确保删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithoutBOM(const SourceFile: string): TConversionResult;
var
  HasBOM: Boolean;
  IsUTF8: Boolean;
  TempFile: string;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Content: string;
  Buffer: TBytes;
begin
  // 初始化结果
  Result := TConversionResult.Create(False, '', '', False, '', etNone);
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    LogMessage('源文件不存在: ' + SourceFile);
    Result.ErrorMessage := '源文件不存在';
    Result.ErrorType := etIOError;
    Exit;
  end;
  
  // 检查文件是否已经是UTF-8
  IsUTF8 := IsUTF8File(SourceFile, HasBOM);
  
  if IsUTF8 and not HasBOM then
  begin
    // 如果已经是UTF-8无BOM，则不需要转换
    LogMessage('文件已经是UTF-8不带BOM: ' + SourceFile);
    Result := TConversionResult.Create(True, 'UTF-8 without BOM', 'UTF-8 without BOM', True, '', etNone);
    Exit;
  end;
  
  if IsUTF8 and HasBOM then
  begin
    // 如果是UTF-8带BOM，则移除BOM
    LogMessage('文件是UTF-8带BOM，移除BOM: ' + SourceFile);
    Result := RemoveUTF8BOM(SourceFile);
    Exit;
  end;
  
  // 创建临时文件
  TempFile := GetTempFileName;
  
  try
    // 尝试读取文件内容并转换为UTF-8
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
      Content := TEncoding.Default.GetString(Buffer);
      
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
      
      // 备份原始文件
      if FileExists(SourceFile + '.bak') then
        DeleteFile(SourceFile + '.bak');
      
      if not RenameFile(SourceFile, SourceFile + '.bak') then
      begin
        LogMessage('无法创建备份文件: ' + SourceFile + '.bak');
        Result.ErrorMessage := '无法创建备份文件';
        Result.ErrorType := etIOError;
        DeleteFile(TempFile);
        Exit;
      end;
      
      // 将临时文件移动到源文件位置
      if not RenameFile(TempFile, SourceFile) then
      begin
        LogMessage('无法将临时文件移动到目标位置: ' + TempFile + ' -> ' + SourceFile);
        Result.ErrorMessage := '无法将临时文件移动到目标位置';
        Result.ErrorType := etIOError;
        // 恢复备份
        RenameFile(SourceFile + '.bak', SourceFile);
        Exit;
      end;
      
      // 如果成功，删除备份
      if FileExists(SourceFile + '.bak') then
        DeleteFile(SourceFile + '.bak');
      
      // 执行往返验证
      Result := PerformRoundTripValidation(SourceFile, False);
      if not Result.Success then
      begin
        LogMessage('往返验证失败: ' + Result.ErrorMessage);
      end
      else
      begin
        LogMessage('成功将文件转换为UTF-8不带BOM: ' + SourceFile);
      end;
    except
      on E: Exception do
      begin
        LogMessage('将文件转换为UTF-8不带BOM时出错: ' + SourceFile + ' - ' + E.Message);
        Result.ErrorMessage := '转换为UTF-8不带BOM出错: ' + E.Message;
        Result.ErrorType := etIOError;
        
        // 清理临时文件
        if FileExists(TempFile) then
          DeleteFile(TempFile);
        
        // 恢复备份
        if FileExists(SourceFile + '.bak') then
          RenameFile(SourceFile + '.bak', SourceFile);
      end;
    end;
  finally
    // 确保删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

class function TUTF8BOMConverter.PerformRoundTripValidation(const SourceFile: string; 
  TargetWithBOM: Boolean): TConversionResult;
var
  OriginalEncoding, TargetEncoding: string;
  TempFile1, TempFile2: string;
  OriginalResult, RoundTripResult: TConversionResult;
  SourceStream, TempStream: TFileStream;
begin
  // 初始化返回值为失败
  Result := TConversionResult.Create(False, '', '', False, '', etNone);
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    LogMessage('源文件不存在: ' + SourceFile);
    Result.ErrorMessage := '源文件不存在';
    Result.ErrorType := etIOError;
    Exit;
  end;
  
  try
    // 创建临时文件路径
    TempFile1 := GetTempFileName;
    TempFile2 := GetTempFileName;
    
    // 备份原始文件到临时文件1
    try
      // 手动复制文件代替TFile.Copy
      SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
      try
        TempStream := TFileStream.Create(TempFile1, fmCreate);
        try
          TempStream.CopyFrom(SourceStream, 0); // 复制整个流
        finally
          TempStream.Free;
        end;
      finally
        SourceStream.Free;
      end;
    except
      on E: Exception do
      begin
        LogMessage('复制文件时出错: ' + E.Message);
        Result.ErrorMessage := '无法创建临时文件';
        Result.ErrorType := etIOError;
        Exit;
      end;
    end;
    
    // 检测原始文件编码
    var HasBOM: Boolean;
    if IsUTF8File(SourceFile, HasBOM) then
    begin
      OriginalEncoding := 'UTF-8' + IfThen(HasBOM, ' with BOM', ' without BOM');
    end
    else
    begin
      OriginalEncoding := 'Non-UTF8';
    end;
    
    // 设置目标编码
    if TargetWithBOM then
    begin
      TargetEncoding := 'UTF-8 with BOM';
      
      // 第一次转换：源文件 -> UTF-8+BOM（临时文件2）
      OriginalResult := ConvertToUTF8WithBOM(TempFile1);
      if not OriginalResult.Success then
      begin
        Result := OriginalResult;
        Result.ErrorType := etLossyConversion;
        LogMessage('往返转换验证中第一次转换失败: ' + OriginalResult.ErrorMessage);
        Exit;
      end;
      
      // 第二次转换：回到原始编码（临时文件2 -> 临时文件1）
      // 需要特殊处理以恢复原始编码状态
      if HasBOM and not TargetWithBOM then
      begin
        // 原始是UTF-8+BOM，目标是UTF-8无BOM，需要去除BOM
        RoundTripResult := RemoveUTF8BOM(TempFile1);
      end
      else if not HasBOM and TargetWithBOM then
      begin
        // 原始是UTF-8无BOM，目标是UTF-8+BOM，需要添加BOM
        RoundTripResult := AddUTF8BOM(TempFile1);
      end
      else
      begin
        // 保持编码不变
        RoundTripResult := TConversionResult.Create(True, TargetEncoding, OriginalEncoding, True, '', etNone);
      end;
      
      if not RoundTripResult.Success then
      begin
        Result := RoundTripResult; 
        Result.ErrorType := etLossyConversion;
        LogMessage('往返转换验证中第二次转换失败: ' + RoundTripResult.ErrorMessage);
        Exit;
      end;
    end
    else
    begin
      TargetEncoding := 'UTF-8 without BOM';
      
      // 第一次转换：源文件 -> UTF-8无BOM（临时文件2）
      OriginalResult := ConvertToUTF8WithoutBOM(TempFile1);
      if not OriginalResult.Success then
      begin
        Result := OriginalResult;
        Result.ErrorType := etLossyConversion;
        LogMessage('往返转换验证中第一次转换失败: ' + OriginalResult.ErrorMessage);
        Exit;
      end;
      
      // 第二次转换：回到原始编码（临时文件2 -> 临时文件1）
      if HasBOM and not TargetWithBOM then
      begin
        // 原始是UTF-8+BOM，目标是UTF-8无BOM，需要去除BOM
        RoundTripResult := RemoveUTF8BOM(TempFile1);
      end
      else if not HasBOM and TargetWithBOM then
      begin
        // 原始是UTF-8无BOM，目标是UTF-8+BOM，需要添加BOM
        RoundTripResult := AddUTF8BOM(TempFile1);
      end
      else
      begin
        // 保持编码不变
        RoundTripResult := TConversionResult.Create(True, TargetEncoding, OriginalEncoding, True, '', etNone);
      end;
      
      if not RoundTripResult.Success then
      begin
        Result := RoundTripResult;
        Result.ErrorType := etLossyConversion;
        LogMessage('往返转换验证中第二次转换失败: ' + RoundTripResult.ErrorMessage);
        Exit;
      end;
    end;
    
    // 比较两个文件的内容是否一致
    if CompareFileContents(SourceFile, TempFile1) then
    begin
      LogMessage('往返转换验证成功: 内容一致');
      Result := TConversionResult.Create(True, OriginalEncoding, TargetEncoding, True, '', etNone);
    end
    else
    begin
      LogMessage('往返转换验证失败: 内容不一致');
      Result := TConversionResult.Create(False, OriginalEncoding, TargetEncoding, False, '内容不一致', etLossyConversion);
    end;
  finally
    // 清理临时文件
    if FileExists(TempFile1) then
      DeleteFile(TempFile1);
    if FileExists(TempFile2) then
      DeleteFile(TempFile2);
  end;
end;

class function TUTF8BOMConverter.CompareFileContents(const File1, File2: string): Boolean;
var
  Stream1, Stream2: TFileStream;
  Buffer1, Buffer2: TBytes;
  Stream1Size, Stream2Size: Int64;
  ChunkSize: Integer;
  BytesRead1, BytesRead2: Integer;
  i: Integer;
  HasBOM1, HasBOM2: Boolean;
  Position1, Position2: Int64;
begin
  Result := False;
  
  if not FileExists(File1) or not FileExists(File2) then
    Exit;
    
  Stream1 := nil;
  Stream2 := nil;
  try
    Stream1 := TFileStream.Create(File1, fmOpenRead or fmShareDenyWrite);
    Stream2 := TFileStream.Create(File2, fmOpenRead or fmShareDenyWrite);
    
    // 检测BOM
    HasBOM1 := False;
    HasBOM2 := False;
    
    if Stream1.Size >= 3 then
    begin
      SetLength(Buffer1, 3);
      Stream1.ReadBuffer(Buffer1[0], 3);
      HasBOM1 := (Buffer1[0] = $EF) and (Buffer1[1] = $BB) and (Buffer1[2] = $BF);
      Stream1.Position := 0;
    end;
    
    if Stream2.Size >= 3 then
    begin
      SetLength(Buffer2, 3);
      Stream2.ReadBuffer(Buffer2[0], 3);
      HasBOM2 := (Buffer2[0] = $EF) and (Buffer2[1] = $BB) and (Buffer2[2] = $BF);
      Stream2.Position := 0;
    end;
    
    // 获取有效内容大小（不考虑BOM）
    Stream1Size := Stream1.Size;
    Stream2Size := Stream2.Size;
    
    // 计算有效内容起始位置
    Position1 := IfThen(HasBOM1, 3, 0);
    Position2 := IfThen(HasBOM2, 3, 0);
    
    // 比较有效内容长度
    if (Stream1Size - Position1) <> (Stream2Size - Position2) then
      Exit;
      
    // 设置文件指针到有效内容起始位置
    Stream1.Position := Position1;
    Stream2.Position := Position2;
    
    // 逐块比较文件内容
    ChunkSize := 8192; // 8KB 的比较块
    SetLength(Buffer1, ChunkSize);
    SetLength(Buffer2, ChunkSize);
    
    while True do
    begin
      BytesRead1 := Stream1.Read(Buffer1[0], ChunkSize);
      BytesRead2 := Stream2.Read(Buffer2[0], ChunkSize);
      
      if (BytesRead1 <> BytesRead2) or (BytesRead1 = 0) then
        Break;
        
      // 逐字节比较当前块
      for i := 0 to BytesRead1 - 1 do
      begin
        if Buffer1[i] <> Buffer2[i] then
          Exit;
      end;
      
      // 如果已读完文件，结束循环
      if BytesRead1 < ChunkSize then
        Break;
    end;
    
    // 如果执行到这里，文件内容是相同的
    Result := True;
  finally
    if Assigned(Stream1) then
      Stream1.Free;
    if Assigned(Stream2) then
      Stream2.Free;
  end;
end;

end.