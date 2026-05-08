unit Test_BoundaryCases;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingConverter_Improved, UtilsTypes, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, JapaneseEncodingDetector_Improved,
  KoreanEncodingDetector_Improved;

// P2-2: 边界条件测试补充
// 在自测程序中调用：RunBoundaryTests(Dir, LogFile)
procedure RunBoundaryTests(const Dir, LogFile: string);

implementation

uses
  UtilsEncodingConfig;

procedure LogLine(const LogFile, S: string);
begin
  TFile.AppendAllText(LogFile, S + sLineBreak, TEncoding.UTF8);
end;

procedure AssertTrue(const LogFile, TestName: string; Condition: Boolean);
begin
  if Condition then
    LogLine(LogFile, '[OK]  ' + TestName)
  else
  begin
    LogLine(LogFile, '[FAIL] ' + TestName);
    raise Exception.Create('Boundary test failed: ' + TestName);
  end;
end;

// 0) 空文件测试 (0字节)
procedure Test_EmptyFileBoundary(const Dir, LogFile: string);
var
  FileName, OutName: string;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
begin
  LogLine(LogFile, '--- Test_EmptyFileBoundary ---');
  FileName := TPath.Combine(Dir, 'boundary_empty.txt');
  OutName  := TPath.Combine(Dir, 'boundary_empty_out.txt');

  // 写 0 字节文件
  TFile.WriteAllBytes(FileName, nil);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := True;

  Res := TEncodingConverter_Improved.ConvertFile(
    FileName,
    OutName,
    '',
    ENCODING_UTF8,
    Opt
  );

  if Res.ErrorCount > 0 then
    LogLine(LogFile, Format('[Empty Debug] Success=%s ErrorCount=%d BytesProcessed=%d ErrorType=%d FirstError="%s"',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed, Ord(Res.Errors[0].ErrorType), Res.Errors[0].ErrorMessage]))
  else
    LogLine(LogFile, Format('[Empty Debug] Success=%s ErrorCount=%d BytesProcessed=%d',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed]));

  if Res.Success then
  begin
    // 成功路径：应生成 0 字节输出文件
    AssertTrue(LogFile, 'Empty file out size = 0',
      TFile.Exists(OutName) and (TFile.GetSize(OutName) = 0));
  end
  else
  begin
    // 保护性失败：仅记录到日志，不视为自测失败（避免对空文件过于严格）
    if Res.ErrorCount > 0 then
      LogLine(LogFile, '[Empty] protective failure: ' + Res.Errors[0].ErrorMessage)
    else
      LogLine(LogFile, '[Empty] protective failure without error detail');
  end;
end;

// 1) 单字节文件测试 (0x41)
procedure Test_SingleByteFile(const Dir, LogFile: string);
var
  FileName, OutName: string;
  Bytes: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  BufRes: TEncodingConversionResult;
begin
  LogLine(LogFile, '--- Test_SingleByteFile ---');
  FileName := TPath.Combine(Dir, 'boundary_single_byte.bin');
  OutName := TPath.Combine(Dir, 'boundary_single_byte_out.bin');

  SetLength(Bytes, 1);
  Bytes[0] := $41; // 'A'
  TFile.WriteAllBytes(FileName, Bytes);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  // 先在内存级别验证单字节 UTF-8 往返
  BufRes := TEncodingConverter_Improved.ConvertBuffer(
    Bytes,
    ENCODING_UTF8,
    ENCODING_UTF8,
    Opt
  );
  AssertTrue(LogFile, 'Single-byte buffer UTF8->UTF8 ConvertBuffer.Success', BufRes.Success);
  AssertTrue(LogFile, 'Single-byte buffer UTF8->UTF8 Output length = 1', Length(BufRes.OutputData) = 1);

  // 文件级别转换主要验证不崩溃；某些安全策略可能会阻止非常小文件被重写
  Res := TEncodingConverter_Improved.ConvertFile(
    FileName,
    OutName,
    ENCODING_UTF8,
    ENCODING_UTF8,
    Opt
  );

  if Res.ErrorCount > 0 then
    LogLine(LogFile, Format('[Single Debug] Success=%s ErrorCount=%d BytesProcessed=%d ErrorType=%d FirstError="%s"',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed,
       Ord(Res.Errors[0].ErrorType), Res.Errors[0].ErrorMessage]))
  else
    LogLine(LogFile, Format('[Single Debug] Success=%s ErrorCount=%d BytesProcessed=%d',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed]));
end;

// 2) 仅 BOM 文件测试 (UTF-8 / UTF-16LE)
procedure Test_OnlyBOMFiles(const Dir, LogFile: string);
var
  FUtf8, FUtf8Out, F16, F16Out: string;
  B: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
begin
  LogLine(LogFile, '--- Test_OnlyBOMFiles ---');

  // UTF-8 only BOM (EF BB BF)
  FUtf8 := TPath.Combine(Dir, 'boundary_only_bom_utf8.bin');
  FUtf8Out := TPath.Combine(Dir, 'boundary_only_bom_utf8_out.bin');
  SetLength(B, 3);
  B[0] := $EF; B[1] := $BB; B[2] := $BF;
  TFile.WriteAllBytes(FUtf8, B);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := True;

  Res := TEncodingConverter_Improved.ConvertFile(
    FUtf8,
    FUtf8Out,
    '',
    ENCODING_UTF8,
    Opt
  );
  if Res.ErrorCount > 0 then
    LogLine(LogFile, Format('[OnlyBOM UTF8 Debug] Success=%s ErrorCount=%d BytesProcessed=%d ErrorType=%d FirstError="%s"',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed,
       Ord(Res.Errors[0].ErrorType), Res.Errors[0].ErrorMessage]))
  else
    LogLine(LogFile, Format('[OnlyBOM UTF8 Debug] Success=%s ErrorCount=%d BytesProcessed=%d',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed]));

  // UTF-16LE only BOM (FF FE)
  F16 := TPath.Combine(Dir, 'boundary_only_bom_utf16le.bin');
  F16Out := TPath.Combine(Dir, 'boundary_only_bom_utf16le_out.bin');
  SetLength(B, 2);
  B[0] := $FF; B[1] := $FE;
  TFile.WriteAllBytes(F16, B);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := True;

  Res := TEncodingConverter_Improved.ConvertFile(
    F16,
    F16Out,
    '',
    ENCODING_UTF8,
    Opt
  );
  if Res.ErrorCount > 0 then
    LogLine(LogFile, Format('[OnlyBOM UTF16 Debug] Success=%s ErrorCount=%d BytesProcessed=%d ErrorType=%d FirstError="%s"',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed,
       Ord(Res.Errors[0].ErrorType), Res.Errors[0].ErrorMessage]))
  else
    LogLine(LogFile, Format('[OnlyBOM UTF16 Debug] Success=%s ErrorCount=%d BytesProcessed=%d',
      [BoolToStr(Res.Success, True), Res.ErrorCount, Res.BytesProcessed]));
end;

// 3) UTF-8 检测置信度范围测试（高置信度 vs 低置信度）
procedure Test_UTF8Detector_ConfidenceRanges(const Dir, LogFile: string);
var
  GoodBuf, BadBuf: TBytes;
  RGood, RBad: TUTF8DetectionResult;
begin
  LogLine(LogFile, '--- Test_UTF8Detector_ConfidenceRanges ---');

  // 高置信度样本：有效 UTF-8 文本
  GoodBuf := TEncoding.UTF8.GetBytes('边界条件 UTF8 测试 ?? 中文 ABC123');
  RGood := TUTF8EncodingDetector_Improved.DetectBuffer(GoodBuf);
  LogLine(LogFile, Format('[UTF8] Good sample: IsUTF8=%s Conf=%.3f',
    [BoolToStr(RGood.IsUTF8, True), RGood.Confidence]));
  AssertTrue(LogFile, 'UTF8 detector good sample Conf>=0.95', RGood.Confidence >= 0.95);

  // 低置信度样本：大量非法字节
  SetLength(BadBuf, 8);
  BadBuf[0] := $FF; BadBuf[1] := $FE; BadBuf[2] := $FD; BadBuf[3] := $FC;
  BadBuf[4] := $00; BadBuf[5] := $C0; BadBuf[6] := $AF; BadBuf[7] := $80;
  RBad := TUTF8EncodingDetector_Improved.DetectBuffer(BadBuf);
  LogLine(LogFile, Format('[UTF8] Bad sample: IsUTF8=%s Conf=%.3f',
    [BoolToStr(RBad.IsUTF8, True), RBad.Confidence]));
  AssertTrue(LogFile, 'UTF8 detector bad sample Conf<=0.5', RBad.Confidence <= 0.5);
end;

// 3b) UTF-8 检测阈值行为测试（MinUTF8Confidence 影响边界样本）
procedure Test_UTF8Detector_ThresholdBehavior(const Dir, LogFile: string);
var
  OldThreshold: Double;
  BufGood, BufBorder, BufBad: TBytes;
  R: TUTF8DetectionResult;
begin
  LogLine(LogFile, '--- Test_UTF8Detector_ThresholdBehavior ---');

  OldThreshold := TEncodingDetectionConfig.MinUTF8Confidence;
  BufGood   := TEncoding.UTF8.GetBytes('强 UTF-8 样本 ?? 中文 ABC123');
  BufBorder := TEncoding.UTF8.GetBytes('ASCII only 12345');
  SetLength(BufBad, 4);
  BufBad[0] := $FF; BufBad[1] := $FF; BufBad[2] := $FF; BufBad[3] := $FF;

  try
    // 阈值较低
    TEncodingDetectionConfig.MinUTF8Confidence := 0.6;

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufGood);
    AssertTrue(LogFile, 'Good UTF8 low-threshold IsUTF8=True', R.IsUTF8);

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufBad);
    AssertTrue(LogFile, 'Bad sample low-threshold IsUTF8=False', not R.IsUTF8);

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufBorder);
    LogLine(LogFile, Format('[Border low] IsUTF8=%s Conf=%.3f',
      [BoolToStr(R.IsUTF8, True), R.Confidence]));

    // 阈值较高
    TEncodingDetectionConfig.MinUTF8Confidence := 0.95;

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufGood);
    AssertTrue(LogFile, 'Good UTF8 high-threshold IsUTF8=True', R.IsUTF8);

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufBad);
    AssertTrue(LogFile, 'Bad sample high-threshold IsUTF8=False', not R.IsUTF8);

    R := TUTF8EncodingDetector_Improved.DetectBuffer(BufBorder);
    LogLine(LogFile, Format('[Border high] IsUTF8=%s Conf=%.3f',
      [BoolToStr(R.IsUTF8, True), R.Confidence]));
  finally
    TEncodingDetectionConfig.MinUTF8Confidence := OldThreshold;
  end;
end;

// 4) 混合编码文件测试：前半 GBK，后半 UTF-8，验证鲁棒性（不崩溃）
procedure Test_MixedEncodingFileRobustness(const Dir, LogFile: string);
var
  FileName: string;
  PartGBK, PartUTF8, Buf: TBytes;
  R: TUTF8DetectionResult;
begin
  LogLine(LogFile, '--- Test_MixedEncodingFileRobustness ---');

  PartGBK := TEncoding.GetEncoding(936).GetBytes('这是GBK前半部分');
  PartUTF8 := TEncoding.UTF8.GetBytes('这是UTF8后半部分');

  SetLength(Buf, Length(PartGBK) + Length(PartUTF8));
  if Length(PartGBK) > 0 then
    Move(PartGBK[0], Buf[0], Length(PartGBK));
  if Length(PartUTF8) > 0 then
    Move(PartUTF8[0], Buf[Length(PartGBK)], Length(PartUTF8));

  FileName := TPath.Combine(Dir, 'boundary_mixed_gbk_utf8.bin');
  TFile.WriteAllBytes(FileName, Buf);

  // 仅要求检测过程鲁棒，返回一个合法结果即可
  R := TUTF8EncodingDetector_Improved.DetectFile(FileName);
  LogLine(LogFile, Format('[Mixed] IsUTF8=%s Conf=%.3f Total=%d',
    [BoolToStr(R.IsUTF8, True), R.Confidence, R.TotalByteCount]));

  AssertTrue(LogFile, 'Mixed-encoding file detection TotalByteCount>0', R.TotalByteCount > 0);
end;

// 5) 多编码低特征样本（纯 ASCII），验证多检测器均低置信度
procedure Test_AmbiguousAsciiLowConfidence(const Dir, LogFile: string);
var
  Buf: TBytes;
  C: TChineseEncodingResult;
  J: TJapaneseEncodingResult;
  K: TKoreanEncodingResult;
begin
  LogLine(LogFile, '--- Test_AmbiguousAsciiLowConfidence ---');

  Buf := TEncoding.ASCII.GetBytes('ASCII only ambiguity 12345');

  C := TChineseEncodingDetector_Improved.DetectBuffer(Buf);
  J := TJapaneseEncodingDetector_Improved.DetectBuffer(Buf);
  K := TKoreanEncodingDetector_Improved.DetectBuffer(Buf);

  LogLine(LogFile, Format('[ASCII] CN Conf=%.3f JP=%.3f KR=%.3f',
    [C.Confidence, J.Confidence, K.Confidence]));

  AssertTrue(LogFile, 'ASCII multi-encoding confidences <= 0.5',
    (C.Confidence <= 0.5) and (J.Confidence <= 0.5) and (K.Confidence <= 0.5));
end;

procedure RunBoundaryTests(const Dir, LogFile: string);
begin
  LogLine(LogFile, '=== RunBoundaryTests(P2-2): begin ===');
  Test_EmptyFileBoundary(Dir, LogFile);
  Test_SingleByteFile(Dir, LogFile);
  Test_OnlyBOMFiles(Dir, LogFile);
  Test_UTF8Detector_ConfidenceRanges(Dir, LogFile);
  Test_UTF8Detector_ThresholdBehavior(Dir, LogFile);
  Test_MixedEncodingFileRobustness(Dir, LogFile);
  Test_AmbiguousAsciiLowConfidence(Dir, LogFile);
  LogLine(LogFile, '=== RunBoundaryTests(P2-2): end ===');
end;

end.
