unit JclBOM;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows;

type
  // BOM类型枚举
  TJclBOMType = (
    bomAnsi,       // 没有BOM
    bomUTF8,       // UTF-8 BOM: EF BB BF
    bomUTF16LE,    // UTF-16 Little Endian BOM: FF FE
    bomUTF16BE,    // UTF-16 Big Endian BOM: FE FF
    bomUTF32LE,    // UTF-32 Little Endian BOM: FF FE 00 00
    bomUTF32BE     // UTF-32 Big Endian BOM: 00 00 FE FF
  );

// 检测流中的BOM类型
function DetectBOM(Stream: TStream): TJclBOMType;

// 获取BOM的字节长度
function GetBOMLength(BOMType: TJclBOMType): Integer;

// 检查字节数组是否是有效的UTF-8编码
function IsUTF8Valid(const Bytes: TBytes; StartIndex, Count: Integer): Boolean;

// 检查字节数组是否是有效的GBK编码
function IsGBKString(const Bytes: TBytes; Length: Integer): Boolean;

// 将字符串从源代码页转换为Unicode
function StringToWideStringEx(const S: AnsiString; CodePage: Cardinal; Length: Integer = -1): WideString;

// 获取当前ANSI代码页
function GetACP: Cardinal;

// 获取最小值
function Min(A, B: Integer): Integer;

// 获取最大值
function Max(A, B: Integer): Integer;

// 条件选择函数
function IfThen(Condition: Boolean; const TrueValue, FalseValue: string): string; overload;

// 常量
const
  CP_UTF16LE = 1200;
  CP_UTF16BE = 1201;
  CP_UTF32LE = 12000;
  CP_UTF32BE = 12001;

implementation

uses
  System.Math, System.StrUtils;

const
  // BOM 字节数组
  BOM_UTF8: array[0..2] of Byte = ($EF, $BB, $BF);
  BOM_UTF16_LE: array[0..1] of Byte = ($FF, $FE);
  BOM_UTF16_BE: array[0..1] of Byte = ($FE, $FF);
  BOM_UTF32_LE: array[0..3] of Byte = ($FF, $FE, $00, $00);
  BOM_UTF32_BE: array[0..3] of Byte = ($00, $00, $FE, $FF);

// 检测流中的BOM类型
function DetectBOM(Stream: TStream): TJclBOMType;
var
  Buffer: array[0..3] of Byte;
  ReadCount: Integer;
  StartPos: Int64;
begin
  Result := bomAnsi; // 默认为ANSI（无BOM）
  
  // 记住当前位置
  StartPos := Stream.Position;
  
  // 读取前4个字节
  FillChar(Buffer, SizeOf(Buffer), 0);
  ReadCount := Stream.Read(Buffer, SizeOf(Buffer));
  
  // 恢复位置
  Stream.Position := StartPos;
  
  if ReadCount >= 4 then
  begin
    // 检查UTF-32
    if (Buffer[0] = BOM_UTF32_BE[0]) and
       (Buffer[1] = BOM_UTF32_BE[1]) and
       (Buffer[2] = BOM_UTF32_BE[2]) and
       (Buffer[3] = BOM_UTF32_BE[3]) then
      Result := bomUTF32BE
    else if (Buffer[0] = BOM_UTF32_LE[0]) and
            (Buffer[1] = BOM_UTF32_LE[1]) and
            (Buffer[2] = BOM_UTF32_LE[2]) and
            (Buffer[3] = BOM_UTF32_LE[3]) then
      Result := bomUTF32LE
    // 检查UTF-8
    else if (Buffer[0] = BOM_UTF8[0]) and
            (Buffer[1] = BOM_UTF8[1]) and
            (Buffer[2] = BOM_UTF8[2]) then
      Result := bomUTF8
    // 检查UTF-16
    else if (Buffer[0] = BOM_UTF16_LE[0]) and
            (Buffer[1] = BOM_UTF16_LE[1]) then
      Result := bomUTF16LE
    else if (Buffer[0] = BOM_UTF16_BE[0]) and
            (Buffer[1] = BOM_UTF16_BE[1]) then
      Result := bomUTF16BE;
  end
  else if ReadCount >= 3 then
  begin
    // 只检查UTF-8
    if (Buffer[0] = BOM_UTF8[0]) and
       (Buffer[1] = BOM_UTF8[1]) and
       (Buffer[2] = BOM_UTF8[2]) then
      Result := bomUTF8
    // 检查UTF-16
    else if (Buffer[0] = BOM_UTF16_LE[0]) and
            (Buffer[1] = BOM_UTF16_LE[1]) then
      Result := bomUTF16LE
    else if (Buffer[0] = BOM_UTF16_BE[0]) and
            (Buffer[1] = BOM_UTF16_BE[1]) then
      Result := bomUTF16BE;
  end
  else if ReadCount >= 2 then
  begin
    // 只检查UTF-16
    if (Buffer[0] = BOM_UTF16_LE[0]) and
       (Buffer[1] = BOM_UTF16_LE[1]) then
      Result := bomUTF16LE
    else if (Buffer[0] = BOM_UTF16_BE[0]) and
            (Buffer[1] = BOM_UTF16_BE[1]) then
      Result := bomUTF16BE;
  end;
end;

// 获取BOM的字节长度
function GetBOMLength(BOMType: TJclBOMType): Integer;
begin
  case BOMType of
    bomUTF8: Result := 3;
    bomUTF16LE, bomUTF16BE: Result := 2;
    bomUTF32LE, bomUTF32BE: Result := 4;
  else
    Result := 0;
  end;
end;

// 检查字节数组是否是有效的UTF-8编码
function IsUTF8Valid(const Bytes: TBytes; StartIndex, Count: Integer): Boolean;
var
  I, CharSize: Integer;
begin
  Result := True;
  I := StartIndex;
  
  while I < StartIndex + Count do
  begin
    // 检查第一个字节，确定UTF-8字符的字节数
    if (Bytes[I] and $80) = 0 then
      CharSize := 1  // ASCII
    else if (Bytes[I] and $E0) = $C0 then
      CharSize := 2  // 2字节UTF-8
    else if (Bytes[I] and $F0) = $E0 then
      CharSize := 3  // 3字节UTF-8
    else if (Bytes[I] and $F8) = $F0 then
      CharSize := 4  // 4字节UTF-8
    else
    begin
      Result := False; // 无效的UTF-8开始字节
      Exit;
    end;
    
    // 确保我们有足够的字节
    if I + CharSize - 1 >= StartIndex + Count then
    begin
      Result := False;
      Exit;
    end;
    
    // 验证后续字节
    for var J := 1 to CharSize - 1 do
    begin
      if (Bytes[I + J] and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    end;
    
    Inc(I, CharSize);
  end;
end;

// 检查字节数组是否是有效的GBK编码
function IsGBKString(const Bytes: TBytes; Length: Integer): Boolean;
var
  I: Integer;
begin
  Result := True;
  I := 0;
  while I < Length do
  begin
    if Bytes[I] <= $7F then
      Inc(I)
    else if (I + 1 < Length) and (Bytes[I] >= $81) and (Bytes[I] <= $FE) and
            (Bytes[I+1] >= $40) and (Bytes[I+1] <= $FE) then
      Inc(I, 2)
    else
    begin
      Result := False;
      Break;
    end;
  end;
end;

// 将字符串从源代码页转换为Unicode
function StringToWideStringEx(const S: AnsiString; CodePage: Cardinal; Length: Integer = -1): WideString;
var
  InputLength: Integer;
  Bytes: TBytes;
  TempStr: string;
begin
  Result := '';
  if S = '' then
    Exit;

  InputLength := System.Length(S);
  if Length > 0 then
    InputLength := System.Math.Min(InputLength, Length);

  // 将AnsiString转换为字节数组
  SetLength(Bytes, InputLength);
  if InputLength > 0 then
    Move(PAnsiChar(S)^, Bytes[0], InputLength);
    
  // 使用TEncoding更安全地转换
  try
    TempStr := TEncoding.GetEncoding(CodePage).GetString(Bytes);
    Result := TempStr; // 自动转换为WideString
  except
    on E: Exception do
      Result := '';
  end;
end;

// 获取当前ANSI代码页
function GetACP: Cardinal;
begin
  Result := Winapi.Windows.GetACP;
end;

// 获取最小值
function Min(A, B: Integer): Integer;
begin
  Result := System.Math.Min(A, B);
end;

// 获取最大值
function Max(A, B: Integer): Integer;
begin
  Result := System.Math.Max(A, B);
end;

// 条件选择函数
function IfThen(Condition: Boolean; const TrueValue, FalseValue: string): string;
begin
  if Condition then
    Result := TrueValue
  else
    Result := FalseValue;
end;

end. 