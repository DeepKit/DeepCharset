unit UTF8BOMConverter_Simple_Fixed;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

type
  TUTF8BOMConverter = class
  public
    /// <summary>
    /// 检测文件是否包含UTF-8 BOM
    /// </summary>
    class function HasUTF8BOM(const FileName: string): Boolean;

    /// <summary>
    /// 添加UTF-8 BOM到文件
    /// </summary>
    class function AddUTF8BOM(const FileName: string): Boolean;

    /// <summary>
    /// 移除文件中的UTF-8 BOM
    /// </summary>
    class function RemoveUTF8BOM(const FileName: string): Boolean;

    /// <summary>
    /// 转换文件编码为UTF-8并添加BOM
    /// </summary>
    class function ConvertToUTF8WithBOM(const FileName: string): Boolean;

    /// <summary>
    /// 转换文件编码为UTF-8并移除BOM
    /// </summary>
    class function ConvertToUTF8WithoutBOM(const FileName: string): Boolean;
  end;

implementation

{ TUTF8BOMConverter }

class function TUTF8BOMConverter.HasUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead);
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

class function TUTF8BOMConverter.AddUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  BOM: TBytes;
  TempFileName: string;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  if HasUTF8BOM(FileName) then
  begin
    Result := True; // 已经有BOM，无需添加
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead);
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
        TempFileName := FileName + '.tmp';
        TempStream.SaveToFile(TempFileName);

        // 关闭文件流
        FileStream.Free;
        FileStream := nil;

        // 删除原文件并重命名临时文件
        if FileExists(FileName) then
          System.SysUtils.DeleteFile(PChar(FileName));
        System.SysUtils.RenameFile(PChar(TempFileName), PChar(FileName));

        Result := True;
      finally
        TempStream.Free;
      end;
    finally
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

class function TUTF8BOMConverter.RemoveUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  TempFileName: string;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  if not HasUTF8BOM(FileName) then
  begin
    Result := True; // 没有BOM，无需移除
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead);
    try
      TempStream := TMemoryStream.Create;
      try
        // 跳过UTF-8 BOM
        FileStream.Position := 3;

        // 复制剩余内容
        SetLength(Buffer, FileStream.Size - 3);
        if FileStream.Size > 3 then
        begin
          FileStream.ReadBuffer(Buffer[0], FileStream.Size - 3);
          TempStream.WriteBuffer(Buffer[0], FileStream.Size - 3);
        end;

        // 保存到临时文件，然后重命名
        TempFileName := FileName + '.tmp';
        TempStream.SaveToFile(TempFileName);

        // 关闭文件流
        FileStream.Free;
        FileStream := nil;

        // 删除原文件并重命名临时文件
        if FileExists(FileName) then
          System.SysUtils.DeleteFile(PChar(FileName));
        System.SysUtils.RenameFile(PChar(TempFileName), PChar(FileName));

        Result := True;
      finally
        TempStream.Free;
      end;
    finally
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithBOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  Content: string;
  BOM: TBytes;
  TempFileName: string;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  if HasUTF8BOM(FileName) then
  begin
    Result := True; // 已经是UTF-8带BOM，无需转换
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead);
    try
      // 读取文件内容
      SetLength(Buffer, FileStream.Size);
      if FileStream.Size > 0 then
      begin
        FileStream.Position := 0;
        FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      end;

      // 转换为字符串
      Content := TEncoding.Default.GetString(Buffer);

      // 创建UTF-8编码的文件
      TempStream := TMemoryStream.Create;
      try
        // 添加UTF-8 BOM
        SetLength(BOM, 3);
        BOM[0] := $EF;
        BOM[1] := $BB;
        BOM[2] := $BF;
        TempStream.WriteBuffer(BOM[0], 3);

        // 转换内容为UTF-8并写入
        Buffer := TEncoding.UTF8.GetBytes(Content);
        if Length(Buffer) > 0 then
          TempStream.WriteBuffer(Buffer[0], Length(Buffer));

        // 保存到临时文件
        TempFileName := FileName + '.tmp';
        TempStream.SaveToFile(TempFileName);

        // 关闭文件流
        FileStream.Free;
        FileStream := nil;

        // 删除原文件并重命名临时文件
        if FileExists(FileName) then
          System.SysUtils.DeleteFile(PChar(FileName));
        System.SysUtils.RenameFile(PChar(TempFileName), PChar(FileName));

        Result := True;
      finally
        TempStream.Free;
      end;
    finally
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

class function TUTF8BOMConverter.ConvertToUTF8WithoutBOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  TempStream: TMemoryStream;
  Buffer: TBytes;
  Content: string;
  TempFileName: string;
  HasBOM: Boolean;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  // 检查是否已经是UTF-8无BOM
  HasBOM := HasUTF8BOM(FileName);
  
  if HasBOM then
  begin
    // 如果是UTF-8+BOM，简单移除BOM即可
    Result := RemoveUTF8BOM(FileName);
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead);
    try
      // 读取文件内容
      SetLength(Buffer, FileStream.Size);
      if FileStream.Size > 0 then
      begin
        FileStream.Position := 0;
        FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      end;

      // 转换为字符串
      Content := TEncoding.Default.GetString(Buffer);

      // 创建UTF-8编码的文件
      TempStream := TMemoryStream.Create;
      try
        // 转换内容为UTF-8并写入（不添加BOM）
        Buffer := TEncoding.UTF8.GetBytes(Content);
        if Length(Buffer) > 0 then
          TempStream.WriteBuffer(Buffer[0], Length(Buffer));

        // 保存到临时文件
        TempFileName := FileName + '.tmp';
        TempStream.SaveToFile(TempFileName);

        // 关闭文件流
        FileStream.Free;
        FileStream := nil;

        // 删除原文件并重命名临时文件
        if FileExists(FileName) then
          System.SysUtils.DeleteFile(PChar(FileName));
        System.SysUtils.RenameFile(PChar(TempFileName), PChar(FileName));

        Result := True;
      finally
        TempStream.Free;
      end;
    finally
      if Assigned(FileStream) then
        FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

end. 