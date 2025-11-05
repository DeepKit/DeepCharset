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
  end;

implementation

uses
  Winapi.Windows;

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
begin
  if Length(Buffer) = 0 then
  begin
    Result := '';
    Exit;
  end;

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

end.
