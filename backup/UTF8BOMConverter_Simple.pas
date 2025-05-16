unit UTF8BOMConverter_Simple;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Math;

type
  TConversionResult = record
    Success: Boolean;
    ErrorMessage: string;
    constructor Create(ASuccess: Boolean; const AErrorMessage: string = '');
  end;

  TUTF8BOMConverter = class
  public
    /// <summary>
    /// 检测文件是否包含UTF-8 BOM
    /// </summary>
    class function HasUTF8BOM(const FileName: string): Boolean;

    /// <summary>
    /// 添加UTF-8 BOM到文件
    /// </summary>
    class function AddUTF8BOM(const FileName: string): TConversionResult;

    /// <summary>
    /// 移除文件中的UTF-8 BOM
    /// </summary>
    class function RemoveUTF8BOM(const FileName: string): TConversionResult;

    /// <summary>
    /// 转换文件编码为UTF-8并添加BOM
    /// </summary>
    class function ConvertToUTF8WithBOM(const FileName: string): TConversionResult;

    /// <summary>
    /// 转换文件编码为UTF-8并移除BOM
    /// </summary>
    class function ConvertToUTF8WithoutBOM(const FileName: string): TConversionResult;

    /// <summary>
    /// 检查文件是否是UTF-8编码（无论有无BOM）
    /// </summary>
    class function IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
  end;

implementation

constructor TConversionResult.Create(ASuccess: Boolean; const AErrorMessage: string = '');
begin
  Success := ASuccess;
  ErrorMessage := AErrorMessage;
end;

{ TUTF8BOMConverter }

class function TUTF8BOMConverter.HasUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := False;

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    OutputDebugString(PChar('HasUTF8BOM: 文件不存在 - ' + FileName));
    Exit;
  end;

  // 检查文件是否可读
  try
    FileStream := nil;
    try
      // 尝试以只读方式打开文件
      FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);

      // 检查文件大小
      if FileStream.Size < 3 then
      begin
        OutputDebugString(PChar('HasUTF8BOM: 文件太小，不可能有BOM - ' + FileName));
        Exit;
      end;

      // 读取前3个字节
      try
        SetLength(Buffer, 3);
        FileStream.Position := 0;
        FileStream.ReadBuffer(Buffer[0], 3);

        // 检查是否是UTF-8 BOM
        Result := (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

        if Result then
          OutputDebugString(PChar('HasUTF8BOM: 检测到UTF-8 BOM - ' + FileName))
        else
          OutputDebugString(PChar('HasUTF8BOM: 未检测到UTF-8 BOM - ' + FileName));
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('HasUTF8BOM: 读取文件内容失败 - ' + E.Message));
          Result := False;
        end;
      end;
    finally
      // 确保释放文件流
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('HasUTF8BOM: 打开文件失败 - ' + E.Message));
      Result := False;
    end;
  end;
end;

class function TUTF8BOMConverter.IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  I, Len: Integer;
  IsValid: Boolean;
begin
  HasBOM := False;
  Result := False;

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    OutputDebugString(PChar('IsUTF8File: 文件不存在 - ' + FileName));
    Exit;
  end;

  try
    // 尝试打开文件
    try
      Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('IsUTF8File: 打开文件失败 - ' + E.Message));
        Exit;
      end;
    end;

    try
      // 获取文件大小
      Len := Stream.Size;
      if Len = 0 then
      begin
        // 空文件，默认认为是UTF-8
        OutputDebugString(PChar('IsUTF8File: 空文件，默认为UTF-8 - ' + FileName));
        Result := True;
        Exit;
      end;

      // 检查BOM
      if Len >= 3 then
      begin
        try
          SetLength(Buffer, 3);
          Stream.Position := 0;
          Stream.ReadBuffer(Buffer[0], 3);
          HasBOM := (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

          if HasBOM then
          begin
            // 如果有BOM，则确认是UTF-8
            OutputDebugString(PChar('IsUTF8File: 检测到UTF-8 BOM - ' + FileName));
            Result := True;
            Exit;
          end;
        except
          on E: Exception do
          begin
            OutputDebugString(PChar('IsUTF8File: 读取BOM失败 - ' + E.Message));
            Exit;
          end;
        end;
      end;

      // 重置流位置
      try
        Stream.Position := 0;
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('IsUTF8File: 重置流位置失败 - ' + E.Message));
          Exit;
        end;
      end;

      try
        // 读取文件内容进行UTF-8验证
        // 对于大文件，只读取前1MB进行检测
        Len := Min(Len, 1024 * 1024); // 限制为最多1MB
        SetLength(Buffer, Len);
        Stream.ReadBuffer(Buffer[0], Len);
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('IsUTF8File: 读取文件内容失败 - ' + E.Message));
          Exit;
        end;
      end;

      try
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

        if Result then
          OutputDebugString(PChar('IsUTF8File: 文件是有效的UTF-8编码 - ' + FileName))
        else
          OutputDebugString(PChar('IsUTF8File: 文件不是UTF-8编码 - ' + FileName));
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('IsUTF8File: UTF-8验证过程中出错 - ' + E.Message));
          Result := False;
        end;
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('IsUTF8File错误: ' + E.Message));
      Result := False;
    end;
  end;
end;

class function TUTF8BOMConverter.AddUTF8BOM(const FileName: string): TConversionResult;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  BOM: TBytes;
  TempFileName: string;
  HasBOM: Boolean;
  IsUTF8: Boolean;
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit(TConversionResult.Create(False, string('文件不存在')));

  // 检查文件是否已经有BOM
  if HasUTF8BOM(FileName) then
    Exit(TConversionResult.Create(True));

  // 检查文件是否是UTF-8
  IsUTF8 := IsUTF8File(FileName, HasBOM);
  if not IsUTF8 then
    OutputDebugString(PChar('警告: 文件不是UTF-8编码，添加BOM可能导致内容错误: ' + FileName));

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      TempStream := TMemoryStream.Create;
      try
        // 添加UTF-8 BOM
        SetLength(BOM, 3);
        BOM[0] := $EF;
        BOM[1] := $BB;
        BOM[2] := $BF;
        TempStream.WriteBuffer(BOM[0], 3);

        // 复制文件内容
        SetLength(Buffer, FileStream.Size);
        if FileStream.Size > 0 then
        begin
          FileStream.Position := 0;
          FileStream.ReadBuffer(Buffer[0], FileStream.Size);
          TempStream.WriteBuffer(Buffer[0], FileStream.Size);
        end;

        // 保存到临时文件，然后重命名
        TempFileName := ChangeFileExt(FileName, '.tmp');
        TempStream.SaveToFile(TempFileName);

        // 关闭文件流以便替换文件
        FileStream.Free;
        FileStream := nil;

        // 创建备份文件
        if FileExists(FileName + '.bak') then
          DeleteFile(PChar(FileName + '.bak'));

        if not RenameFile(PChar(FileName), PChar(FileName + '.bak')) then
          OutputDebugString(PChar('无法创建备份文件: ' + FileName + '.bak'));

        // 删除原文件并重命名临时文件
        if FileExists(FileName) then
          if not DeleteFile(PChar(FileName)) then
            Exit(TConversionResult.Create(False, string('无法删除原始文件')));

        if not RenameFile(PChar(TempFileName), PChar(FileName)) then
          Exit(TConversionResult.Create(False, string('无法重命名临时文件')));

        Result := TConversionResult.Create(True);
      finally
        TempStream.Free;
      end;
    finally
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result := TConversionResult.Create(False, string('处理文件时发生错误: ' + E.Message));
      OutputDebugString(PChar('AddUTF8BOM错误: ' + E.Message));
    end;
  end;
end;

class function TUTF8BOMConverter.RemoveUTF8BOM(const FileName: string): TConversionResult;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  TempFileName: string;
  FileAttr: Integer;
  BackupCreated: Boolean;
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit(TConversionResult.Create(False, string('文件不存在')));

  // 检查文件是否可写
  try
    FileAttr := FileGetAttr(FileName);
    if (FileAttr and faReadOnly) <> 0 then
      Exit(TConversionResult.Create(False, string('文件为只读，无法修改')));
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检查文件属性失败: ' + E.Message)));
  end;

  // 检查文件是否有BOM
  try
    if not HasUTF8BOM(FileName) then
    begin
      OutputDebugString(PChar('文件没有UTF-8 BOM，无需移除'));
      Exit(TConversionResult.Create(True));
    end;
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检测BOM失败: ' + E.Message)));
  end;

  // 生成唯一的临时文件名
  TempFileName := ChangeFileExt(FileName, '.' + IntToStr(GetTickCount) + '.tmp');
  BackupCreated := False;

  try
    try
      // 打开源文件
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
      except
        on E: Exception do
          Exit(TConversionResult.Create(False, string('无法打开源文件: ' + E.Message)));
      end;

      try
        // 创建内存流
        TempStream := TMemoryStream.Create;
        try
          // 读取文件内容（跳过BOM）
          try
            // 确保文件大小足够
            if FileStream.Size <= 3 then
            begin
              // 文件太小，只有BOM或者更小，创建空文件
              OutputDebugString(PChar('文件只包含BOM或更小，将创建空文件'));
            end
            else
            begin
              // 跳过UTF-8 BOM
              FileStream.Position := 3;

              // 复制剩余内容
              SetLength(Buffer, FileStream.Size - 3);
              FileStream.ReadBuffer(Buffer[0], FileStream.Size - 3);
              TempStream.WriteBuffer(Buffer[0], FileStream.Size - 3);
            end;
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('读取文件内容失败: ' + E.Message)));
          end;

          // 保存到临时文件
          try
            TempStream.SaveToFile(TempFileName);
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('保存临时文件失败: ' + E.Message)));
          end;
        finally
          TempStream.Free;
        end;
      finally
        // 关闭文件流以便替换文件
        FileStream.Free;
        FileStream := nil;
      end;

      // 创建备份文件
      try
        if FileExists(FileName + '.bak') then
        begin
          if not DeleteFile(PChar(FileName + '.bak')) then
            OutputDebugString(PChar('无法删除旧的备份文件: ' + FileName + '.bak'));
        end;

        if RenameFile(PChar(FileName), PChar(FileName + '.bak')) then
          BackupCreated := True
        else
          OutputDebugString(PChar('无法创建备份文件: ' + FileName + '.bak'));
      except
        on E: Exception do
          OutputDebugString(PChar('创建备份文件时出错: ' + E.Message));
      end;

      // 重命名临时文件为原文件
      try
        if FileExists(FileName) then
        begin
          if not DeleteFile(PChar(FileName)) then
            Exit(TConversionResult.Create(False, string('无法删除原始文件')));
        end;

        if not RenameFile(PChar(TempFileName), PChar(FileName)) then
          Exit(TConversionResult.Create(False, string('无法重命名临时文件')));
      except
        on E: Exception do
        begin
          // 如果重命名失败，尝试恢复备份
          if BackupCreated then
          begin
            try
              if RenameFile(PChar(FileName + '.bak'), PChar(FileName)) then
                OutputDebugString(PChar('已恢复原始文件'))
              else
                OutputDebugString(PChar('无法恢复原始文件'));
            except
              // 忽略恢复过程中的错误
            end;
          end;
          Exit(TConversionResult.Create(False, string('重命名文件失败: ' + E.Message)));
        end;
      end;

      Result := TConversionResult.Create(True);
    except
      on E: Exception do
      begin
        // 清理临时文件
        if FileExists(TempFileName) then
        begin
          try
            DeleteFile(PChar(TempFileName));
          except
            // 忽略删除临时文件的错误
          end;
        end;
        Result := TConversionResult.Create(False, string('处理文件时发生错误: ' + E.Message));
        OutputDebugString(PChar('RemoveUTF8BOM错误: ' + E.Message));
      end;
    end;
  finally
    // 确保清理临时文件
    if FileExists(TempFileName) then
    begin
      try
        DeleteFile(PChar(TempFileName));
      except
        // 忽略删除临时文件的错误
      end;
    end;
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithBOM(const FileName: string): TConversionResult;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer, OutputBuffer: TBytes;
  BOM: TBytes;
  TempFileName: string;
  HasBOM: Boolean;
  IsUTF8WithoutBOM: Boolean;
  FileAttr: Integer;
  BackupCreated: Boolean;
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit(TConversionResult.Create(False, string('文件不存在')));

  // 检查文件是否可写
  try
    FileAttr := FileGetAttr(FileName);
    if (FileAttr and faReadOnly) <> 0 then
      Exit(TConversionResult.Create(False, string('文件为只读，无法修改')));
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检查文件属性失败: ' + E.Message)));
  end;

  // 检查文件是否已经是UTF-8带BOM
  try
    IsUTF8WithoutBOM := IsUTF8File(FileName, HasBOM);
    if IsUTF8WithoutBOM and HasBOM then
    begin
      OutputDebugString(PChar('文件已经是UTF-8带BOM，无需转换'));
      Exit(TConversionResult.Create(True));
    end;
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检测文件编码失败: ' + E.Message)));
  end;

  // 生成唯一的临时文件名
  TempFileName := ChangeFileExt(FileName, '.' + IntToStr(GetTickCount) + '.tmp');
  BackupCreated := False;

  try
    try
      // 打开源文件
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
      except
        on E: Exception do
          Exit(TConversionResult.Create(False, string('无法打开源文件: ' + E.Message)));
      end;

      try
        // 创建内存流
        TempStream := TMemoryStream.Create;
        try
          // 读取文件内容
          try
            SetLength(Buffer, FileStream.Size);
            if FileStream.Size > 0 then
            begin
              FileStream.Position := 0;
              FileStream.ReadBuffer(Buffer[0], FileStream.Size);
            end;
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('读取文件内容失败: ' + E.Message)));
          end;

          // 处理文件内容
          try
            // 添加UTF-8 BOM
            SetLength(BOM, 3);
            BOM[0] := $EF;
            BOM[1] := $BB;
            BOM[2] := $BF;
            TempStream.WriteBuffer(BOM[0], 3);

            if (FileStream.Size >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
            begin
              // 如果已经有BOM，直接复制内容（跳过BOM）
              OutputDebugString(PChar('检测到UTF-8 BOM，保留内容'));
              if FileStream.Size > 3 then
                TempStream.WriteBuffer(Buffer[3], FileStream.Size - 3);
            end
            else if IsUTF8WithoutBOM then
            begin
              // 如果是UTF-8无BOM，直接复制内容
              OutputDebugString(PChar('检测到UTF-8无BOM，添加BOM'));
              TempStream.WriteBuffer(Buffer[0], FileStream.Size);
            end
            else
            begin
              // 其他编码，需要转换为UTF-8
              OutputDebugString(PChar('检测到非UTF-8编码，转换为UTF-8带BOM'));
              var Content := TEncoding.Default.GetString(Buffer);
              OutputBuffer := TEncoding.UTF8.GetBytes(Content);
              if Length(OutputBuffer) > 0 then
                TempStream.WriteBuffer(OutputBuffer[0], Length(OutputBuffer));
            end;
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('处理文件内容失败: ' + E.Message)));
          end;

          // 保存到临时文件
          try
            TempStream.SaveToFile(TempFileName);
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('保存临时文件失败: ' + E.Message)));
          end;
        finally
          TempStream.Free;
        end;
      finally
        // 关闭文件流以便替换文件
        FileStream.Free;
        FileStream := nil;
      end;

      // 创建备份文件
      try
        if FileExists(FileName + '.bak') then
        begin
          if not DeleteFile(PChar(FileName + '.bak')) then
            OutputDebugString(PChar('无法删除旧的备份文件: ' + FileName + '.bak'));
        end;

        if RenameFile(PChar(FileName), PChar(FileName + '.bak')) then
          BackupCreated := True
        else
          OutputDebugString(PChar('无法创建备份文件: ' + FileName + '.bak'));
      except
        on E: Exception do
          OutputDebugString(PChar('创建备份文件时出错: ' + E.Message));
      end;

      // 重命名临时文件为原文件
      try
        if FileExists(FileName) then
        begin
          if not DeleteFile(PChar(FileName)) then
            Exit(TConversionResult.Create(False, string('无法删除原始文件')));
        end;

        if not RenameFile(PChar(TempFileName), PChar(FileName)) then
          Exit(TConversionResult.Create(False, string('无法重命名临时文件')));
      except
        on E: Exception do
        begin
          // 如果重命名失败，尝试恢复备份
          if BackupCreated then
          begin
            try
              if RenameFile(PChar(FileName + '.bak'), PChar(FileName)) then
                OutputDebugString(PChar('已恢复原始文件'))
              else
                OutputDebugString(PChar('无法恢复原始文件'));
            except
              // 忽略恢复过程中的错误
            end;
          end;
          Exit(TConversionResult.Create(False, string('重命名文件失败: ' + E.Message)));
        end;
      end;

      Result := TConversionResult.Create(True);
    except
      on E: Exception do
      begin
        // 清理临时文件
        if FileExists(TempFileName) then
        begin
          try
            DeleteFile(PChar(TempFileName));
          except
            // 忽略删除临时文件的错误
          end;
        end;
        Result := TConversionResult.Create(False, string('处理文件时发生错误: ' + E.Message));
        OutputDebugString(PChar('ConvertToUTF8WithBOM错误: ' + E.Message));
      end;
    end;
  finally
    // 确保清理临时文件
    if FileExists(TempFileName) then
    begin
      try
        DeleteFile(PChar(TempFileName));
      except
        // 忽略删除临时文件的错误
      end;
    end;
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithoutBOM(const FileName: string): TConversionResult;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer, OutputBuffer: TBytes;
  TempFileName: string;
  HasBOM: Boolean;
  IsUTF8WithoutBOM: Boolean;
  FileAttr: Integer;
  BackupCreated: Boolean;
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit(TConversionResult.Create(False, string('文件不存在')));

  // 检查文件是否可写
  try
    FileAttr := FileGetAttr(FileName);
    if (FileAttr and faReadOnly) <> 0 then
      Exit(TConversionResult.Create(False, string('文件为只读，无法修改')));
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检查文件属性失败: ' + E.Message)));
  end;

  // 检查文件是否已经是UTF-8无BOM
  try
    IsUTF8WithoutBOM := IsUTF8File(FileName, HasBOM);
    if IsUTF8WithoutBOM and not HasBOM then
    begin
      OutputDebugString(PChar('文件已经是UTF-8无BOM，无需转换'));
      Exit(TConversionResult.Create(True));
    end;
  except
    on E: Exception do
      Exit(TConversionResult.Create(False, string('检测文件编码失败: ' + E.Message)));
  end;

  // 生成唯一的临时文件名
  TempFileName := ChangeFileExt(FileName, '.' + IntToStr(GetTickCount) + '.tmp');
  BackupCreated := False;

  try
    try
      // 打开源文件
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
      except
        on E: Exception do
          Exit(TConversionResult.Create(False, string('无法打开源文件: ' + E.Message)));
      end;

      try
        // 创建内存流
        TempStream := TMemoryStream.Create;
        try
          // 读取文件内容
          try
            SetLength(Buffer, FileStream.Size);
            if FileStream.Size > 0 then
            begin
              FileStream.Position := 0;
              FileStream.ReadBuffer(Buffer[0], FileStream.Size);
            end;
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('读取文件内容失败: ' + E.Message)));
          end;

          // 处理文件内容
          try
            if (FileStream.Size >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
            begin
              // 如果已经有BOM，只复制内容（跳过BOM）
              OutputDebugString(PChar('检测到UTF-8 BOM，移除BOM'));
              if FileStream.Size > 3 then
                TempStream.WriteBuffer(Buffer[3], FileStream.Size - 3);
            end
            else if IsUTF8WithoutBOM then
            begin
              // 如果是UTF-8无BOM，直接复制内容
              OutputDebugString(PChar('检测到UTF-8无BOM，保持不变'));
              TempStream.WriteBuffer(Buffer[0], FileStream.Size);
            end
            else
            begin
              // 其他编码，需要转换为UTF-8
              OutputDebugString(PChar('检测到非UTF-8编码，转换为UTF-8无BOM'));
              var Content := TEncoding.Default.GetString(Buffer);
              OutputBuffer := TEncoding.UTF8.GetBytes(Content);
              if Length(OutputBuffer) > 0 then
                TempStream.WriteBuffer(OutputBuffer[0], Length(OutputBuffer));
            end;
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('处理文件内容失败: ' + E.Message)));
          end;

          // 保存到临时文件
          try
            TempStream.SaveToFile(TempFileName);
          except
            on E: Exception do
              Exit(TConversionResult.Create(False, string('保存临时文件失败: ' + E.Message)));
          end;
        finally
          TempStream.Free;
        end;
      finally
        // 关闭文件流以便替换文件
        FileStream.Free;
        FileStream := nil;
      end;

      // 创建备份文件
      try
        if FileExists(FileName + '.bak') then
        begin
          if not DeleteFile(PChar(FileName + '.bak')) then
            OutputDebugString(PChar('无法删除旧的备份文件: ' + FileName + '.bak'));
        end;

        if RenameFile(PChar(FileName), PChar(FileName + '.bak')) then
          BackupCreated := True
        else
          OutputDebugString(PChar('无法创建备份文件: ' + FileName + '.bak'));
      except
        on E: Exception do
          OutputDebugString(PChar('创建备份文件时出错: ' + E.Message));
      end;

      // 重命名临时文件为原文件
      try
        if FileExists(FileName) then
        begin
          if not DeleteFile(PChar(FileName)) then
            Exit(TConversionResult.Create(False, string('无法删除原始文件')));
        end;

        if not RenameFile(PChar(TempFileName), PChar(FileName)) then
          Exit(TConversionResult.Create(False, string('无法重命名临时文件')));
      except
        on E: Exception do
        begin
          // 如果重命名失败，尝试恢复备份
          if BackupCreated then
          begin
            try
              if RenameFile(PChar(FileName + '.bak'), PChar(FileName)) then
                OutputDebugString(PChar('已恢复原始文件'))
              else
                OutputDebugString(PChar('无法恢复原始文件'));
            except
              // 忽略恢复过程中的错误
            end;
          end;
          Exit(TConversionResult.Create(False, string('重命名文件失败: ' + E.Message)));
        end;
      end;

      Result := TConversionResult.Create(True);
    except
      on E: Exception do
      begin
        // 清理临时文件
        if FileExists(TempFileName) then
        begin
          try
            DeleteFile(PChar(TempFileName));
          except
            // 忽略删除临时文件的错误
          end;
        end;
        Result := TConversionResult.Create(False, string('处理文件时发生错误: ' + E.Message));
        OutputDebugString(PChar('ConvertToUTF8WithoutBOM错误: ' + E.Message));
      end;
    end;
  finally
    // 确保清理临时文件
    if FileExists(TempFileName) then
    begin
      try
        DeleteFile(PChar(TempFileName));
      except
        // 忽略删除临时文件的错误
      end;
    end;
  end;
end;

end.
