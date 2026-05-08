program TestBOM;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  EncodingConverter_Improved in '..\EncodingConverter_Improved.pas';

var
  SourceBytes: TBytes;
  Options: TEncodingConversionOptions;
  Result: TEncodingConversionResult;
  I: Integer;
begin
  // 创建 GBK 编码的测试数据："这是"
  SetLength(SourceBytes, 4);
  SourceBytes[0] := $D5; // �?  SourceBytes[1] := $E2;
  SourceBytes[2] := $CA; // �?  SourceBytes[3] := $C7;

  Writeln('Source bytes (GBK): ', Length(SourceBytes));
  Write('Hex: ');
  for I := 0 to Length(SourceBytes) - 1 do
    Write(Format('%02X ', [SourceBytes[I]]));
  Writeln;

  // 设置选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  Options.DetectSourceEncoding := False; // 禁用自动检测，强制使用指定�?GBK

  // 转换
  Result := TEncodingConverter_Improved.ConvertBuffer(SourceBytes, 'GBK', 'UTF-8 with BOM', Options);

  Writeln('Conversion success: ', Result.Success);
  Writeln('Detected source encoding: ', Result.SourceEncoding);
  Writeln('Target encoding: UTF-8 with BOM');
  Writeln('AddBOM option: ', Options.AddBOM);
  Writeln('Output bytes: ', Length(Result.OutputData));
  
  if Length(Result.OutputData) > 0 then
  begin
    Write('Output hex: ');
    for I := 0 to Min(Length(Result.OutputData) - 1, 15) do
      Write(Format('%02X ', [Result.OutputData[I]]));
    Writeln;
    
    if Length(Result.OutputData) >= 3 then
    begin
      if (Result.OutputData[0] = $EF) and (Result.OutputData[1] = $BB) and (Result.OutputData[2] = $BF) then
        Writeln('BOM detected: YES')
      else
        Writeln('BOM detected: NO');
    end;
  end;

end.
