unit JclStrings;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

// BOM检测函数
function DetectUTFBOMCodePage(const Buffer: TBytes; out BOMLength: Integer): Integer;

// 检查字节序列是否是有效的UTF-8
function IsUTF8Valid(const Buffer: PByte; BufferSize: Integer): Boolean;

// 检查字节序列是否是有效的UTF-16LE/BE
function IsUTF16Valid(const Buffer: PByte; BufferSize: Integer; IsBigEndian: Boolean): Boolean;

// 字符串转换函数
function StringToUnicodeStringEx(const S: PAnsiChar; CodePage: Cardinal; Length: Integer = -1): UnicodeString;
function UnicodeStringToStringEx(const WS: UnicodeString; CodePage: Cardinal): AnsiString;

implementation

// 检测UTF BOM并返回相应代码页
function DetectUTFBOMCodePage(const Buffer: TBytes; out BOMLength: Integer): Integer;
begin
  BOMLength := 0;
  Result := 0; // 默认返回0表示无BOM
  
  if Length(Buffer) >= 2 then
  begin
    // UTF-16 LE: FF FE
    if (Buffer[0] = $FF) and (Buffer[1] = $FE) then
    begin
      // 检查是否是UTF-32 LE: FF FE 00 00
      if (Length(Buffer) >= 4) and (Buffer[2] = $00) and (Buffer[3] = $00) then
      begin
        Result := 12000;  // UTF-32 LE
        BOMLength := 4;
      end
      else
      begin
        Result := 1200;   // UTF-16 LE
        BOMLength := 2;
      end;
    end
    // UTF-16 BE: FE FF
    else if (Buffer[0] = $FE) and (Buffer[1] = $FF) then
    begin
      Result := 1201;     // UTF-16 BE
      BOMLength := 2;
    end
    // 检查UTF-8 BOM: EF BB BF
    else if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
    begin
      Result := 65001;    // UTF-8
      BOMLength := 3;
    end
    // 检查UTF-32 BE: 00 00 FE FF
    else if (Length(Buffer) >= 4) and (Buffer[0] = $00) and (Buffer[1] = $00) and (Buffer[2] = $FE) and (Buffer[3] = $FF) then
    begin
      Result := 12001;    // UTF-32 BE
      BOMLength := 4;
    end;
  end;
end;

// 检查字节序列是否是有效的UTF-8
function IsUTF8Valid(const Buffer: PByte; BufferSize: Integer): Boolean;
var
  I, CharSize: Integer;
begin
  Result := True;
  I := 0;
  
  while I < BufferSize do
  begin
    // 检查第一个字节，确定UTF-8字符的字节数
    if (Buffer[I] and $80) = 0 then
      CharSize := 1  // ASCII
    else if (Buffer[I] and $E0) = $C0 then
      CharSize := 2  // 2字节UTF-8
    else if (Buffer[I] and $F0) = $E0 then
      CharSize := 3  // 3字节UTF-8
    else if (Buffer[I] and $F8) = $F0 then
      CharSize := 4  // 4字节UTF-8
    else
    begin
      Result := False; // 无效的UTF-8开始字节
      Exit;
    end;
    
    // 确保我们有足够的字节
    if I + CharSize - 1 >= BufferSize then
    begin
      Result := False;
      Exit;
    end;
    
    // 验证后续字节
    for var J := 1 to CharSize - 1 do
    begin
      if (Buffer[I + J] and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    end;
    
    Inc(I, CharSize);
  end;
end;

// 检查字节序列是否是有效的UTF-16LE/BE
function IsUTF16Valid(const Buffer: PByte; BufferSize: Integer; IsBigEndian: Boolean): Boolean;
var
  I: Integer;
  FirstByte, SecondByte: Byte;
  CharCount: Integer;
begin
  Result := False;
  
  // 确保至少有2个字节，并且总长度是偶数
  if (BufferSize < 2) or (BufferSize mod 2 <> 0) then
    Exit;
    
  // 确保不全是零字节（通常是二进制文件）
  CharCount := 0;
  
  for I := 0 to (BufferSize div 2) - 1 do
  begin
    if IsBigEndian then
    begin
      FirstByte := Buffer[I * 2];
      SecondByte := Buffer[I * 2 + 1];
    end
    else
    begin
      FirstByte := Buffer[I * 2 + 1];
      SecondByte := Buffer[I * 2];
    end;
    
    // 如果包含非ASCII字符，更有可能是UTF-16
    if (FirstByte <> 0) or (SecondByte > 127) then
      Inc(CharCount);
      
    // 特殊情况检查：一些UTF-16字符如代理对
    if ((FirstByte >= $D8) and (FirstByte <= $DB)) then
    begin
      // 检查是否有足够的字节
      if I + 1 >= BufferSize div 2 then
        Exit;
        
      // 下一个字符应该是低代理区域
      var NextHighByte, NextLowByte: Byte;
      if IsBigEndian then
      begin
        NextHighByte := Buffer[(I+1) * 2];
        NextLowByte := Buffer[(I+1) * 2 + 1];
      end
      else
      begin
        NextHighByte := Buffer[(I+1) * 2 + 1];
        NextLowByte := Buffer[(I+1) * 2];
      end;
      
      if not ((NextHighByte >= $DC) and (NextHighByte <= $DF)) then
        Exit; // 无效的UTF-16代理对
    end;
  end;
  
  // 如果至少25%的字符是非ASCII的，则可能是有效的UTF-16
  Result := CharCount >= BufferSize div 8;
end;

// 从源代码页转换为Unicode
function StringToUnicodeStringEx(const S: PAnsiChar; CodePage: Cardinal; Length: Integer): UnicodeString;
var
  InputLen, OutputLen: Integer;
  Buffer: array of WideChar;
begin
  Result := '';
  if (S = nil) then Exit;
  
  // 确定输入长度
  if Length < 0 then
    InputLen := System.Length(S)
  else
    InputLen := Length;
    
  if InputLen = 0 then Exit;
  
  // 先计算所需的输出缓冲区大小
  OutputLen := MultiByteToWideChar(CodePage, 0, S, InputLen, nil, 0);
  if OutputLen <= 0 then Exit;
  
  // 分配缓冲区并执行转换
  SetLength(Buffer, OutputLen);
  OutputLen := MultiByteToWideChar(CodePage, 0, S, InputLen, PWideChar(Buffer), OutputLen);
  
  if OutputLen > 0 then
  begin
    SetLength(Result, OutputLen);
    Move(Buffer[0], Result[1], OutputLen * SizeOf(WideChar));
  end;
end;

// 从Unicode转换为目标代码页
function UnicodeStringToStringEx(const WS: UnicodeString; CodePage: Cardinal): AnsiString;
var
  InputLen, OutputLen: Integer;
  Buffer: array of Byte;
begin
  Result := '';
  InputLen := Length(WS);
  if InputLen = 0 then Exit;
  
  // 先计算所需的输出缓冲区大小
  OutputLen := WideCharToMultiByte(CodePage, 0, PWideChar(WS), InputLen, nil, 0, nil, nil);
  if OutputLen <= 0 then Exit;
  
  // 分配缓冲区并执行转换
  SetLength(Buffer, OutputLen);
  OutputLen := WideCharToMultiByte(CodePage, 0, PWideChar(WS), InputLen, @Buffer[0], OutputLen, nil, nil);
  
  if OutputLen > 0 then
  begin
    SetLength(Result, OutputLen);
    Move(Buffer[0], Result[1], OutputLen);
  end;
end;

end. 