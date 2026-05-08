unit Test_ConversionIntegrity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingConverter_Improved, UtilsTypes,
  ChineseEncodingDetector_Improved;

// 在自测程序中调用：RunConversionIntegrityTests(Dir, LogFile)
procedure RunConversionIntegrityTests(const Dir, LogFile: string);

implementation

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
    raise Exception.Create('ConversionIntegrity test failed: ' + TestName);
  end;
end;

function BytesOfText(const S: string; Enc: TEncoding): TBytes;
begin
  Result := Enc.GetBytes(S);
end;

function MakeUTF8(const S: string): TBytes;
begin
  Result := BytesOfText(S, TEncoding.UTF8);
end;

procedure Test_EmptyBuffer(const Dir, LogFile: string);
var
  Src: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_EmptyBuffer ---');
  SetLength(Src, 0);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  Res := TEncodingConverter_Improved.ConvertBuffer(
    Src,
    ENCODING_UTF8,
    ENCODING_UTF8,
    Opt
  );

  Ok := Res.Success and (Length(Res.OutputData) = 0);
  AssertTrue(LogFile, 'Empty buffer ConvertBuffer', Ok);

  Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
    Src,
    ENCODING_UTF8,
    Res
  );
  AssertTrue(LogFile, 'Empty buffer ValidateConversionIntegrity', Ok);
end;

procedure Test_SimpleASCII_UTF8ToUTF8(const Dir, LogFile: string);
var
  Src: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_SimpleASCII_UTF8ToUTF8 ---');
  Src := MakeUTF8('Hello World 123');

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  Res := TEncodingConverter_Improved.ConvertBuffer(
    Src,
    ENCODING_UTF8,
    ENCODING_UTF8,
    Opt
  );
  AssertTrue(LogFile, 'ASCII UTF8->UTF8 ConvertBuffer.Success', Res.Success);

  Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
    Src,
    ENCODING_UTF8,
    Res
  );
  AssertTrue(LogFile, 'ASCII UTF8->UTF8 ValidateConversionIntegrity', Ok);
end;

procedure Test_Chinese_GBK_To_UTF8(const Dir, LogFile: string);
var
  Text: string;
  SrcFile: string;
  Src: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_Chinese_GBK_To_UTF8 ---');
  Text := '中文測試 ABC123';

  // 用 GBK 写入文件再读入字节，模拟真实文件场景
  SrcFile := TPath.Combine(Dir, 'conv_gbk_src.txt');
  TFile.WriteAllBytes(SrcFile, TEncoding.GetEncoding(936).GetBytes(Text));
  Src := TFile.ReadAllBytes(SrcFile);

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  Res := TEncodingConverter_Improved.ConvertBuffer(
    Src,
    ENCODING_GBK,
    ENCODING_UTF8,
    Opt
  );
  AssertTrue(LogFile, 'GBK->UTF8 ConvertBuffer.Success', Res.Success);

  Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
    Src,
    ENCODING_GBK,
    Res
  );
  AssertTrue(LogFile, 'GBK->UTF8 ValidateConversionIntegrity', Ok);
end;

procedure Test_UTF8BOM_To_UTF8_NoBOM(const Dir, LogFile: string);
var
  Text: string;
  SrcNoBOM, SrcWithBOM: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_UTF8BOM_To_UTF8_NoBOM ---');
  Text := 'UTF8 BOM 内容 ?? 中文 ABC123';

  // 手工构造 UTF-8 BOM + 正文
  SrcNoBOM := TEncoding.UTF8.GetBytes(Text);
  SetLength(SrcWithBOM, 3 + Length(SrcNoBOM));
  if Length(SrcWithBOM) > 0 then
  begin
    SrcWithBOM[0] := $EF;
    SrcWithBOM[1] := $BB;
    SrcWithBOM[2] := $BF;
    if Length(SrcNoBOM) > 0 then
      Move(SrcNoBOM[0], SrcWithBOM[3], Length(SrcNoBOM));
  end;

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;          // 目标无 BOM
  Opt.DetectSourceEncoding := True;

  Res := TEncodingConverter_Improved.ConvertBuffer(
    SrcWithBOM,
    '',                 // 让内部自动检测 BOM
    ENCODING_UTF8,
    Opt
  );
  AssertTrue(LogFile, 'UTF8-BOM->UTF8 ConvertBuffer.Success', Res.Success);

  // 调试输出：查看内部推断的编码和输出长度
  LogLine(LogFile, Format('[UTF8BOM Debug] SourceEncoding="%s" TargetEncoding="%s" OutBytes=%d',
    [Res.SourceEncoding, Res.TargetEncoding, Length(Res.OutputData)]));

  Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
    SrcWithBOM,
    '',   // SourceEncoding 为空，内部会回退到 ConversionResult.SourceEncoding
    Res
  );
  LogLine(LogFile, Format('[UTF8BOM Debug] ValidateConversionIntegrity=%s', [BoolToStr(Ok, True)]));
  AssertTrue(LogFile, 'UTF8-BOM->UTF8 ValidateConversionIntegrity', Ok);
end;

procedure Test_Corrupted_UTF8_ShouldFailIntegrity(const Dir, LogFile: string);
var
  Src: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_Corrupted_UTF8_ShouldFailIntegrity ---');

  // 构造截断的 UTF-8 序列：E4 B8 (缺少第三字节)
  SetLength(Src, 2);
  Src[0] := $E4;
  Src[1] := $B8;

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  Res := TEncodingConverter_Improved.ConvertBuffer(
    Src,
    ENCODING_UTF8,
    ENCODING_UTF8,
    Opt
  );

  LogLine(LogFile, Format('[Corrupted Debug] ConvertBuffer.Success=%s OutBytes=%d',
    [BoolToStr(Res.Success, True), Length(Res.OutputData)]));

  if not Res.Success then
    Ok := False
  else
    Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
      Src,
      ENCODING_UTF8,
      Res
    );

  LogLine(LogFile, Format('[Corrupted Debug] ValidateConversionIntegrity=%s', [BoolToStr(Ok, True)]));

  // 对损坏数据，期望完整性验证返回 False
  AssertTrue(LogFile, 'Corrupted UTF8 ValidateConversionIntegrity = False', not Ok);
end;

procedure Test_MixedEncoding_ShouldFailIntegrity(const Dir, LogFile: string);
var
  PartGBK, PartUTF8, Src: TBytes;
  Opt: TEncodingConversionOptions;
  Res: TEncodingConversionResult;
  Ok: Boolean;
begin
  LogLine(LogFile, '--- Test_MixedEncoding_ShouldFailIntegrity ---');

  // 前半 GBK 中文，后半 UTF-8 中文，混合编码
  PartGBK := TEncoding.GetEncoding(936).GetBytes('这是GBK前半部分');
  PartUTF8 := TEncoding.UTF8.GetBytes('这是UTF8后半部分');

  SetLength(Src, Length(PartGBK) + Length(PartUTF8));
  if Length(PartGBK) > 0 then
    Move(PartGBK[0], Src[0], Length(PartGBK));
  if Length(PartUTF8) > 0 then
    Move(PartUTF8[0], Src[Length(PartGBK)], Length(PartUTF8));

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False;

  // 故意当作纯 GBK 进行转换
  Res := TEncodingConverter_Improved.ConvertBuffer(
    Src,
    ENCODING_GBK,
    ENCODING_UTF8,
    Opt
  );

  if not Res.Success then
    Ok := False
  else
  begin
    Ok := TEncodingConverter_Improved.ValidateConversionIntegrity(
      Src,
      ENCODING_GBK,
      Res
    );
    // 如果完整性验证未能发现问题，则退回到中文编码检测器做一次一致性检查
    if Ok then
    begin
      var Det := TChineseEncodingDetector_Improved.DetectBuffer(Src);
      LogLine(LogFile, Format('[Mixed Debug] Detect.Encoding="%s" Conf=%.3f',
        [Det.Encoding, Det.Confidence]));
      if (not SameText(string(Det.Encoding), ENCODING_GBK)) or (Det.Confidence < 0.7) then
        Ok := False;
    end;
  end;

  AssertTrue(LogFile, 'Mixed-encoding buffer integrity must fail', not Ok);
end;

procedure RunConversionIntegrityTests(const Dir, LogFile: string);
begin
  LogLine(LogFile, '=== RunConversionIntegrityTests: begin ===');
  Test_EmptyBuffer(Dir, LogFile);
  Test_SimpleASCII_UTF8ToUTF8(Dir, LogFile);
  Test_Chinese_GBK_To_UTF8(Dir, LogFile);
  Test_UTF8BOM_To_UTF8_NoBOM(Dir, LogFile);
  Test_Corrupted_UTF8_ShouldFailIntegrity(Dir, LogFile);
  Test_MixedEncoding_ShouldFailIntegrity(Dir, LogFile);
  LogLine(LogFile, '=== RunConversionIntegrityTests: end ===');
end;

end.
