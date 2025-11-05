program SelfTest_Encoding;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingConverter_Improved, UtilsTypes;

function HasUTF8BOM(const Bytes: TBytes): Boolean;
begin
  Result := (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF);
end;

procedure WriteAllTextUTF8NoBOM(const FileName, S: string);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(S);
  TFile.WriteAllBytes(FileName, Bytes);
end;

procedure WriteAllTextUTF8WithBOM(const FileName, S: string);
var
  Bytes: TBytes;
  WithBOM: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(S);
  SetLength(WithBOM, 3 + Length(Bytes));
  if Length(WithBOM) > 0 then
  begin
    WithBOM[0] := $EF; WithBOM[1] := $BB; WithBOM[2] := $BF;
    if Length(Bytes) > 0 then
      Move(Bytes[0], WithBOM[3], Length(Bytes));
  end;
  TFile.WriteAllBytes(FileName, WithBOM);
end;

procedure PrintResult(const Title, FilePath: string);
var
  B: TBytes;
  Info: string;
begin
  if TFile.Exists(FilePath) then
  begin
    B := TFile.ReadAllBytes(FilePath);
    if HasUTF8BOM(B) then Info := 'UTF-8+BOM' else Info := 'UTF-8(no BOM)';
    Writeln(Format('%s => %s, size=%d', [Title, Info, Length(B)]));
  end
  else
    Writeln(Format('%s => file not found: %s', [Title, FilePath]));
end;

procedure RunTests;
var
  Root, Dir, F1, F2, F3: string;
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
begin
  Root := ExtractFilePath(ParamStr(0));
  Dir := TPath.Combine(Root, '..\\tmp_tests');
  ForceDirectories(Dir);
  F1 := TPath.Combine(Dir, 'utf8_no_bom.txt');
  F2 := TPath.Combine(Dir, 'utf8_bom.txt');
  F3 := TPath.Combine(Dir, 'empty.txt');

  // Prepare samples
  WriteAllTextUTF8NoBOM(F1, 'Hello 世界, UTF8 NO BOM');
  WriteAllTextUTF8WithBOM(F2, 'Hello 世界, UTF8 WITH BOM');
  TFile.WriteAllBytes(F3, nil);

  // Options
  Opt := TEncodingConverter_Improved.CreateDefaultOptions;

  // 1) UTF-8 (no BOM) -> UTF-8+BOM (in-place)
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1, F1, 'UTF-8', 'UTF-8 with BOM', Opt);
  Writeln(Format('[1] noBOM -> BOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [1]', F1);

  // 2) UTF-8+BOM -> UTF-8 (in-place)
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F2, F2, 'UTF-8 with BOM', 'UTF-8', Opt);
  Writeln(Format('[2] BOM -> noBOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [2]', F2);

  // 3) empty file noBOM -> BOM (in-place)
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F3, F3, 'UTF-8', 'UTF-8 with BOM', Opt);
  Writeln(Format('[3] empty noBOM -> BOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [3]', F3);

  // 4) Verify content preservation for typical text
  // Create content file and roundtrip
  var F4 := TPath.Combine(Dir, 'roundtrip.txt');
  WriteAllTextUTF8NoBOM(F4, 'RoundTrip 内容 12345\n新行');
  // noBOM->BOM
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8', 'UTF-8 with BOM', Opt);
  // BOM->noBOM
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8 with BOM', 'UTF-8', Opt);
  PrintResult('After [4] roundtrip', F4);
end;

begin
  try
    Writeln('=== Encoding Self Test Start ===');
    RunTests;
    Writeln('=== Encoding Self Test End ===');
  except
    on E: Exception do
      Writeln('Exception: ' + E.ClassName + ': ' + E.Message);
  end;
end.
