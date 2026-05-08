program QuickTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes;

procedure TestGBKBytes;
var
  GBKBytes: TBytes;
  UTF8Enc: TEncoding;
  UTF8Str: string;
  UTF8Bytes: TBytes;
begin
  // GBK 字节�?这是"
  SetLength(GBKBytes, 4);
  GBKBytes[0] := $D5;
  GBKBytes[1] := $E2;
  GBKBytes[2] := $CA;
  GBKBytes[3] := $C7;
  
  Writeln('GBK bytes: ', Length(GBKBytes));
  
  // 使用 Delphi 内置方法转换
  var GBKEnc := TEncoding.GetEncoding(936);
  try
    UTF8Str := GBKEnc.GetString(GBKBytes);
    Writeln('Unicode string length: ', Length(UTF8Str));
    
    UTF8Enc := TEncoding.UTF8;
    UTF8Bytes := UTF8Enc.GetBytes(UTF8Str);
    Writeln('UTF8 bytes (no BOM): ', Length(UTF8Bytes));
    
    // 添加 BOM
    var WithBOM: TBytes;
    SetLength(WithBOM, Length(UTF8Bytes) + 3);
    WithBOM[0] := $EF;
    WithBOM[1] := $BB;
    WithBOM[2] := $BF;
    if Length(UTF8Bytes) > 0 then
      Move(UTF8Bytes[0], WithBOM[3], Length(UTF8Bytes));
    
    Writeln('UTF8 bytes (with BOM): ', Length(WithBOM));
    Write('First 10 bytes: ');
    var I: Integer;
    for I := 0 to 9 do
      Write(Format('%02X ', [WithBOM[I]]));
    Writeln;
  finally
    GBKEnc.Free;
  end;
end;

begin
  TestGBKBytes;
end.
