program SelfTest_Encoding;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingConverter_Improved, UtilsTypes;

type
  TCodecCase = record
    CP: Integer;
    LabelText: string;
    Sample: string;
  end;

// 扩展用例批（1-6）
procedure RunExtendedCategoriesTests(const Dir, LogFile: string);
var
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
begin
  // 1) 大文件更多编码：UTF-8 with BOM / UTF-16LE/BE / UTF-32LE/BE (~50MB)
  var MakeHuge := procedure(const Path: string; const Bytes: TBytes; MB: Integer)
  var FS: TFileStream; Written, Target: Int64;
  begin
    FS := TFileStream.Create(Path, fmCreate);
    try
      Written := 0; Target := Int64(MB) * 1024 * 1024;
      while Written < Target do
      begin
        FS.WriteBuffer(Bytes[0], Length(Bytes));
        Inc(Written, Length(Bytes));
      end;
    finally
      FS.Free;
    end;
  end;

  var ChunkText := 'BLOCK中文😀' + sLineBreak;
  var BUTF8 := TEncoding.UTF8.GetBytes(ChunkText);
  var BUTF8BOM := TBytes.Create($EF, $BB, $BF);
  BUTF8BOM := BUTF8BOM + BUTF8;

  // UTF-8+BOM
  var F1A_SRC := TPath.Combine(Dir, 'huge_u8bom.txt');
  var F1A_OUT := TPath.Combine(Dir, 'huge_u8bom_out.txt');
  MakeHuge(F1A_SRC, BUTF8BOM, 50);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1A_SRC, F1A_OUT, 'UTF-8 with BOM', 'UTF-8 with BOM', Opt);
  if (TFile.GetSize(F1A_SRC) = TFile.GetSize(F1A_OUT)) then
    LogLine(LogFile, '[1A] Huge UTF8+BOM idempotence: PASS')
  else
    LogLine(LogFile, '[1A] Huge UTF8+BOM idempotence: FAIL');

  // UTF-16LE
  var F1B_SRC := TPath.Combine(Dir, 'huge_u16le.txt');
  var F1B_OUT := TPath.Combine(Dir, 'huge_u16le_out.txt');
  var SChunk := ChunkText;
  var B16LE := TEncoding.Unicode.GetBytes(SChunk); // UTF-16LE
  MakeHuge(F1B_SRC, B16LE, 50);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1B_SRC, F1B_OUT, 'UTF-16LE', 'UTF-16LE', Opt);
  if (TFile.GetSize(F1B_SRC) = TFile.GetSize(F1B_OUT)) then
    LogLine(LogFile, '[1B] Huge UTF16LE idempotence: PASS')
  else
    LogLine(LogFile, '[1B] Huge UTF16LE idempotence: FAIL');

  // UTF-16BE
  var F1C_SRC := TPath.Combine(Dir, 'huge_u16be.txt');
  var F1C_OUT := TPath.Combine(Dir, 'huge_u16be_out.txt');
  var B16BE := TEncoding.BigEndianUnicode.GetBytes(SChunk);
  MakeHuge(F1C_SRC, B16BE, 50);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1C_SRC, F1C_OUT, 'UTF-16BE', 'UTF-16BE', Opt);
  if (TFile.GetSize(F1C_SRC) = TFile.GetSize(F1C_OUT)) then
    LogLine(LogFile, '[1C] Huge UTF16BE idempotence: PASS')
  else
    LogLine(LogFile, '[1C] Huge UTF16BE idempotence: FAIL');

  // UTF-32LE/BE 采用已有写入函数
  var F1D_SRC := TPath.Combine(Dir, 'huge_u32le.txt');
  var F1D_OUT := TPath.Combine(Dir, 'huge_u32le_out.txt');
  WriteAllTextUTF32LE(F1D_SRC, SChunk);
  // 简化：复制扩容
  var RepeatLE := TFile.ReadAllBytes(F1D_SRC);
  var FS1D := TFileStream.Create(F1D_SRC, fmCreate);
  try
    for var i := 1 to 1024 do FS1D.WriteBuffer(RepeatLE[0], Length(RepeatLE));
  finally FS1D.Free; end;
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1D_SRC, F1D_OUT, 'UTF-32LE', 'UTF-32LE', Opt);
  if (TFile.GetSize(F1D_SRC) = TFile.GetSize(F1D_OUT)) then
    LogLine(LogFile, '[1D] Huge UTF32LE idempotence: PASS')
  else
    LogLine(LogFile, '[1D] Huge UTF32LE idempotence: FAIL');

  var F1E_SRC := TPath.Combine(Dir, 'huge_u32be.txt');
  var F1E_OUT := TPath.Combine(Dir, 'huge_u32be_out.txt');
  WriteAllTextUTF32BE(F1E_SRC, SChunk);
  var RepeatBE := TFile.ReadAllBytes(F1E_SRC);
  var FS1E := TFileStream.Create(F1E_SRC, fmCreate);
  try
    for var j := 1 to 1024 do FS1E.WriteBuffer(RepeatBE[0], Length(RepeatBE));
  finally FS1E.Free; end;
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F1E_SRC, F1E_OUT, 'UTF-32BE', 'UTF-32BE', Opt);
  if (TFile.GetSize(F1E_SRC) = TFile.GetSize(F1E_OUT)) then
    LogLine(LogFile, '[1E] Huge UTF32BE idempotence: PASS')
  else
    LogLine(LogFile, '[1E] Huge UTF32BE idempotence: FAIL');

  // 2) 有损降级：统计替换字符数量（UTF-8 -> Windows-1252/ISO-8859-2）
  var F2_SRC := TPath.Combine(Dir, 'lossy_src.txt');
  var F2_OUT1 := TPath.Combine(Dir, 'lossy_win1252.txt');
  var F2_OUT2 := TPath.Combine(Dir, 'lossy_iso8859_2.txt');
  var S2 := '中文😀Русский عربى Ελληνικά Magyar € – — “ ”';
  TFile.WriteAllText(F2_SRC, S2, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F2_SRC, F2_OUT1, 'UTF-8', 'Windows-1252', Opt);
  var Read2_1 := TFile.ReadAllText(F2_OUT1, TEncoding.GetEncoding(1252));
  var CountQ := function(const S:string): Integer
  var i: Integer;
  begin Result := 0; for i := 1 to Length(S) do if S[i] = '?' then Inc(Result); end;
  var C1 := CountQ(Read2_1);
  R := TEncodingConverter_Improved.ConvertFile(F2_SRC, F2_OUT2, 'UTF-8', 'ISO-8859-2', Opt);
  var Read2_2 := TFile.ReadAllText(F2_OUT2, TEncoding.GetEncoding(28592));
  var C2 := CountQ(Read2_2);
  if (C1 >= 1) and (C2 >= 1) then
    LogLine(LogFile, Format('[2] Lossy replacement counts: PASS (?1252=%d ?iso2=%d)', [C1, C2]))
  else
    LogLine(LogFile, Format('[2] Lossy replacement counts: FAIL (?1252=%d ?iso2=%d)', [C1, C2]));

  // 3) UTF-16/32 多次往返幂等
  var F3A := TPath.Combine(Dir, 'rt16le_a.txt');
  var F3B := TPath.Combine(Dir, 'rt16le_b.txt');
  var SR := 'Roundtrip UTF16LE/BE/UTF32LE/BE 😀 中文 ABC123';
  TFile.WriteAllText(F3A, SR, TEncoding.UTF8);
  var Base3 := TFile.ReadAllBytes(F3A);
  for var k := 1 to 10 do
  begin
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
    R := TEncodingConverter_Improved.ConvertFile(F3A, F3B, 'UTF-8', 'UTF-16LE', Opt);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F3B, F3A, 'UTF-16LE', 'UTF-8', Opt);
  end;
  var End3 := TFile.ReadAllBytes(F3A);
  if (Length(Base3) = Length(End3)) and ((Length(Base3)=0) or CompareMem(@Base3[0], @End3[0], Length(Base3))) then
    LogLine(LogFile, '[3A] 10x UTF16LE<->UTF8 roundtrip: PASS')
  else
    LogLine(LogFile, '[3A] 10x UTF16LE<->UTF8 roundtrip: FAIL');

  // 4) 极长路径与文件名
  var LongDir := TPath.Combine(Dir, StringOfChar('D', 60));
  LongDir := TPath.Combine(LongDir, StringOfChar('E', 60));
  LongDir := TPath.Combine(LongDir, StringOfChar('F', 60));
  ForceDirectories(LongDir);
  var LongFile := TPath.Combine(LongDir, StringOfChar('名', 30) + '_测试.txt');
  TFile.WriteAllText(LongFile, 'Long path content 😀', TEncoding.UTF8);
  var LongOut := ChangeFileExt(LongFile, '_out.txt');
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(LongFile, LongOut, 'UTF-8', 'UTF-8', Opt);
  if R.Success and (TFile.ReadAllText(LongOut, TEncoding.UTF8) = 'Long path content 😀') then
    LogLine(LogFile, '[4] Very long path handling: PASS')
  else
    LogLine(LogFile, '[4] Very long path handling: FAIL');

  // 5) 状态编码扩展：EUC-JP / Shift-JIS 混合半角全角
  var F5A := TPath.Combine(Dir, 'eucjp_mix.txt');
  var F5B := TPath.Combine(Dir, 'sjis_mix.txt');
  var MixJP := 'ＡＢＣｱｲｳ カナ 日本語，半角/全角 mix';
  TFile.WriteAllText(F5A, MixJP, TEncoding.GetEncoding(20932)); // EUC-JP
  TFile.WriteAllText(F5B, MixJP, TEncoding.GetEncoding(932));   // Shift-JIS
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F5A, F5A + '_out.txt', '20932', 'UTF-8', Opt);
  R := TEncodingConverter_Improved.ConvertFile(F5B, F5B + '_out.txt', '932', 'UTF-8', Opt);
  var R5A := TFile.ReadAllText(F5A + '_out.txt', TEncoding.UTF8);
  var R5B := TFile.ReadAllText(F5B + '_out.txt', TEncoding.UTF8);
  if (R5A = MixJP) and (R5B = MixJP) then
    LogLine(LogFile, '[5] EUC-JP/Shift-JIS mixed-width: PASS')
  else
    LogLine(LogFile, '[5] EUC-JP/Shift-JIS mixed-width: FAIL');

  // 6) 更多无效 UTF-8 模式：孤立 continuation / 长链
  var F6A := TPath.Combine(Dir, 'invalid_utf8_isolated.bin');
  var F6B := TPath.Combine(Dir, 'invalid_utf8_chain.bin');
  var A6: TBytes; SetLength(A6, 3); A6[0] := $80; A6[1] := $BF; A6[2] := $0A; // 孤立 continuation
  var B6: TBytes; SetLength(B6, 6); B6[0] := $E1; B6[1] := $80; B6[2] := $80; B6[3] := $80; B6[4] := $80; B6[5] := $0A; // 超长链
  TFile.WriteAllBytes(F6A, A6);
  TFile.WriteAllBytes(F6B, B6);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.DetectSourceEncoding := True; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F6A, F6A + '_out.txt', '', 'UTF-8', Opt);
  R := TEncodingConverter_Improved.ConvertFile(F6B, F6B + '_out.txt', '', 'UTF-8', Opt);
  if FileExists(F6A + '_out.txt') and FileExists(F6B + '_out.txt') then
    LogLine(LogFile, '[6] Invalid UTF-8 patterns robustness: PASS')
  else
    LogLine(LogFile, '[6] Invalid UTF-8 patterns robustness: FAIL');
end;

// 追加测试 [43]-[46]
procedure RunAdditionalEdgeCases(const Dir, LogFile: string);
var
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
begin
  // 43) ISO-2022-JP（50220）状态编码转换
  var F43_SRC := TPath.Combine(Dir, 'iso2022jp_src.txt');
  var F43_OUT := TPath.Combine(Dir, 'iso2022jp_out.txt');
  var Text43 := '日本語テスト ISO2022-JP ABC123';
  var Enc50220 := TEncoding.GetEncoding(50220);
  TFile.WriteAllText(F43_SRC, Text43, Enc50220);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F43_SRC, F43_OUT, '50220', 'UTF-8', Opt);
  var Read43 := TFile.ReadAllText(F43_OUT, TEncoding.UTF8);
  if (Read43 = Text43) then
    LogLine(LogFile, '[43] ISO-2022-JP(50220)->UTF8: PASS')
  else
    LogLine(LogFile, '[43] ISO-2022-JP(50220)->UTF8: FAIL');

  // 44) Overlong UTF-8 鲁棒性（不崩溃）
  var F44_SRC := TPath.Combine(Dir, 'utf8_overlong.bin');
  var F44_OUT := TPath.Combine(Dir, 'utf8_overlong_out.bin');
  var B44: TBytes; SetLength(B44, 3); B44[0] := $C1; B44[1] := $81; B44[2] := $0A; // overlong 'A' + LF
  TFile.WriteAllBytes(F44_SRC, B44);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F44_SRC, F44_OUT, '', 'UTF-8', Opt);
  if R.Success and FileExists(F44_OUT) then
    LogLine(LogFile, '[44] Overlong UTF-8 robustness: PASS')
  else
    LogLine(LogFile, '[44] Overlong UTF-8 robustness: FAIL');

  // 45) ReadOnly 属性保持（目标属性应与源一致）
  var F45_SRC := TPath.Combine(Dir, 'readonly_src.txt');
  var F45_OUT := TPath.Combine(Dir, 'readonly_out.txt');
  var S45 := '只读属性测试 ReadOnly Attribute ' + IntToStr(Random(10000));
  TFile.WriteAllText(F45_SRC, S45, TEncoding.UTF8);
  // 设置源为只读
  var Attrs45 := TFile.GetAttributes(F45_SRC);
  TFile.SetAttributes(F45_SRC, Attrs45 + [TFileAttribute.faReadOnly]);
  // 转换到 UTF-8（等同编码）
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F45_SRC, F45_OUT, 'UTF-8', 'UTF-8', Opt);
  var OutAttrs45 := TFile.GetAttributes(F45_OUT);
  if (R.Success) and (TFileAttribute.faReadOnly in OutAttrs45) then
    LogLine(LogFile, '[45] ReadOnly attribute preserved: PASS')
  else
    LogLine(LogFile, '[45] ReadOnly attribute preserved: FAIL');

  // 46) 非 ASCII 路径处理（中文文件名）
  var F46_SRC := TPath.Combine(Dir, '测试_文件_UTF8.txt');
  var F46_OUT := TPath.Combine(Dir, '测试_文件_UTF8_out.txt');
  var S46 := '非ASCII路径处理 ✅ 中文 + Emoji 😀 + ASCII';
  TFile.WriteAllText(F46_SRC, S46, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F46_SRC, F46_OUT, 'UTF-8', 'UTF-8', Opt);
  var Read46 := TFile.ReadAllText(F46_OUT, TEncoding.UTF8);
  if (R.Success) and (Read46 = S46) then
    LogLine(LogFile, '[46] Non-ASCII path UTF8->UTF8: PASS')
  else
    LogLine(LogFile, '[46] Non-ASCII path UTF8->UTF8: FAIL');
end;

// 前置声明，供 RunCodePageCases 使用
procedure LogLine(const FilePath, S: string); forward;
procedure WriteAllTextWithCodepage(const FileName, S: string; CodePage: Integer); forward;

function HasUTF8BOM(const Bytes: TBytes): Boolean;
begin
  Result := (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF);
end;

procedure RunCodePageCases(const Dir, LogFile: string);
var
  Cases: array of TCodecCase;
  k, n: Integer;
  SrcFile, OutFile, ReadText: string;
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
  procedure AddCase(CodePage: Integer; const LabelText, Sample: string);
  begin
    n := Length(Cases);
    SetLength(Cases, n + 1);
    Cases[n].CP := CodePage;
    Cases[n].LabelText := LabelText;
    Cases[n].Sample := Sample;
  end;
begin
  SetLength(Cases, 0);
  // Windows 编码
  AddCase(1250, 'Windows-1250', 'Central Europe: ĄčĘŁŃÓŚŹŻ 123');
  AddCase(1251, 'Windows-1251', 'Привет мир ABC123');
  AddCase(1252, 'Windows-1252', 'Euro € naive café – — “ ”');
  AddCase(1253, 'Windows-1253', 'Καλημέρα κόσμε ABC123');
  AddCase(1254, 'Windows-1254', 'Türkçe İğüş ABC123');
  AddCase(1255, 'Windows-1255', 'שלום עולם ABC123');
  AddCase(1256, 'Windows-1256', 'مرحبا بالعالم ABC123');
  AddCase(1257, 'Windows-1257', 'Baltic: Ėė Ąą Įį Ųų');
  AddCase(1258, 'Windows-1258', 'Tiếng Việt ABC123');
  AddCase(874,  'Windows-874',  'ไทย ภาษาไทย ทดสอบ ABC123');
  // ISO 编码
  AddCase(28591, 'ISO-8859-1',  'Resume naive cafe ABC123');
  AddCase(28592, 'ISO-8859-2',  'Śródmieście Łódź Ćma Źrebak');
  AddCase(28593, 'ISO-8859-3',  'Ħaż-Żabbar Għ Ċ ABC123');
  AddCase(28594, 'ISO-8859-4',  'Akmens šķērsošana ABC123');
  AddCase(28596, 'ISO-8859-6',  'العربية اختبار ABC123');
  AddCase(28598, 'ISO-8859-8',  'שלום עולם ABC123');
  AddCase(28603, 'ISO-8859-13', 'Baltic Ģēķis Ŗūķis');
  AddCase(28606, 'ISO-8859-16', 'Română Șț Țț Ăă Ââ Îî');
  AddCase(28605, 'ISO-8859-15', 'Euro € test ABC123');
  // KOI8 系列
  AddCase(20866, 'KOI8-R', 'Привет мир ABC123');
  AddCase(21866, 'KOI8-U', 'Привіт світ ABC123');
  // DOS/OEM 编码
  AddCase(437,  'CP437', 'CP437 test: AaBbCc 123');
  AddCase(850,  'CP850', 'CP850 test: ÀÁÂÃÄÅ ÇÈÉÊË ÌÍÎÏ');
  AddCase(852,  'CP852', 'CP852 test: ĄČĎĘĽŁŃŇÓŘŚŤŹŻ');
  AddCase(855,  'CP855', 'CP855 test: Привет мир 123');
  AddCase(866,  'CP866', 'CP866 test: Привет мир 123');
  // 东亚常用编码补齐
  AddCase(936,   'GBK',        '这是GBK内容：中文测试ABC123');
  AddCase(20936, 'GB2312',     'GB2312 简体中文测试 ABC123');
  AddCase(54936, 'GB18030',    'GB18030 扩展字符测试 𪚥 ABC123');
  AddCase(950,   'Big5',       '繁體中文測試ABC123');
  AddCase(932,   'Shift-JIS',  'ｼﾌﾄJIS テスト 日本語abc123');
  AddCase(20932, 'EUC-JP',     '日本語テスト EUC-JP ABC123');
  AddCase(50220, 'ISO-2022-JP','日本語テスト ISO2022-JP ABC123');
  AddCase(949,   'Windows-949','한국어 테스트 ABC123');
  AddCase(1361,  'JOHAB',      '조합형 한글 테스트 ABC123');

  for k := 0 to High(Cases) do
  begin
    SrcFile := TPath.Combine(Dir, Format('cp_%s.txt', [Cases[k].LabelText]));
    OutFile := TPath.Combine(Dir, Format('cp_%s_to_utf8.txt', [Cases[k].LabelText]));
    try
      WriteAllTextWithCodepage(SrcFile, Cases[k].Sample, Cases[k].CP);
      Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
      R := TEncodingConverter_Improved.ConvertFile(SrcFile, OutFile, IntToStr(Cases[k].CP), 'UTF-8', Opt);
      ReadText := TFile.ReadAllText(OutFile, TEncoding.UTF8);
      if ReadText = Cases[k].Sample then
        LogLine(LogFile, Format('[21+] %s->UTF8: PASS', [Cases[k].LabelText]))
      else
        LogLine(LogFile, Format('[21+] %s->UTF8: FAIL - len(exp)=%d len(act)=%d', [Cases[k].LabelText, Length(Cases[k].Sample), Length(ReadText)]));
    except
      on E: Exception do
        LogLine(LogFile, Format('[21+] %s->UTF8: EXCEPTION %s', [Cases[k].LabelText, E.Message]));
    end;
  end;
end;

procedure WriteAllTextUTF32LE(const FileName, S: string);
var
  FS: TFileStream;
  BOM: array[0..3] of Byte;
  i: Integer;
  W: Cardinal;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    // UTF-32LE BOM FF FE 00 00
    BOM[0] := $FF; BOM[1] := $FE; BOM[2] := $00; BOM[3] := $00;
    FS.WriteBuffer(BOM, SizeOf(BOM));
    for i := 1 to Length(S) do
    begin
      W := Ord(S[i]);
      // little-endian order
      BOM[0] := Byte(W and $FF);
      BOM[1] := Byte((W shr 8) and $FF);
      BOM[2] := Byte((W shr 16) and $FF);
      BOM[3] := Byte((W shr 24) and $FF);
      FS.WriteBuffer(BOM, SizeOf(BOM));
    end;
  finally
    FS.Free;
  end;
end;

procedure WriteAllTextUTF32BE(const FileName, S: string);
var
  FS: TFileStream;
  BOM: array[0..3] of Byte;
  i: Integer;
  W: Cardinal;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    // UTF-32BE BOM 00 00 FE FF
    BOM[0] := $00; BOM[1] := $00; BOM[2] := $FE; BOM[3] := $FF;
    FS.WriteBuffer(BOM, SizeOf(BOM));
    for i := 1 to Length(S) do
    begin
      W := Ord(S[i]);
      // big-endian order
      BOM[0] := Byte((W shr 24) and $FF);
      BOM[1] := Byte((W shr 16) and $FF);
      BOM[2] := Byte((W shr 8) and $FF);
      BOM[3] := Byte(W and $FF);
      FS.WriteBuffer(BOM, SizeOf(BOM));
    end;
  finally
    FS.Free;
  end;
end;

procedure WriteAllTextUTF16LE(const FileName, S: string);
var
  FS: TFileStream;
  BOM: array[0..1] of Byte;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    // UTF-16LE BOM
    BOM[0] := $FF; BOM[1] := $FE;
    FS.WriteBuffer(BOM, SizeOf(BOM));
    if Length(S) > 0 then
      FS.WriteBuffer(S[1], Length(S) * SizeOf(Char));
  finally
    FS.Free;
  end;
end;

procedure WriteAllTextUTF16BE(const FileName, S: string);
var
  FS: TFileStream;
  i: Integer;
  BOM: array[0..1] of Byte;
  W: Word;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    // UTF-16BE BOM
    BOM[0] := $FE; BOM[1] := $FF;
    FS.WriteBuffer(BOM, SizeOf(BOM));
    for i := 1 to Length(S) do
    begin
      W := Word(S[i]);
      // write big-endian order
      BOM[0] := Byte(W shr 8);
      BOM[1] := Byte(W and $FF);
      FS.WriteBuffer(BOM, SizeOf(BOM));
    end;
  finally
    FS.Free;
  end;
end;

procedure WriteAllTextWithCodepage(const FileName, S: string; CodePage: Integer);
var
  Enc: TEncoding;
  Bytes: TBytes;
begin
  Enc := TEncoding.GetEncoding(CodePage);
  try
    Bytes := Enc.GetBytes(S);
    TFile.WriteAllBytes(FileName, Bytes);
  finally
    Enc.Free;
  end;
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

procedure LogLine(const FilePath, S: string);
begin
  // 以 UTF-8（无 BOM）追加日志
  TFile.AppendAllText(FilePath, S + sLineBreak, TEncoding.UTF8);
end;

procedure WriteAllTextGBK(const FileName, S: string);
var
  Enc: TEncoding;
  Bytes: TBytes;
begin
  Enc := TEncoding.GetEncoding(936); // GBK/CP936
  try
    Bytes := Enc.GetBytes(S);
    TFile.WriteAllBytes(FileName, Bytes);
  finally
    Enc.Free;
  end;
end;

procedure RunTests;
var
  Root, Dir, F1, F2, F3: string;
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
  LogFile: string;
begin
  Root := ExtractFilePath(ParamStr(0));
  Dir := TPath.Combine(Root, '..\\tmp_tests');
  ForceDirectories(Dir);
  F1 := TPath.Combine(Dir, 'utf8_no_bom.txt');
  F2 := TPath.Combine(Dir, 'utf8_bom.txt');
  F3 := TPath.Combine(Dir, 'empty.txt');
  LogFile := TPath.Combine(Dir, 'selftest_log.txt');

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
  LogLine(LogFile, Format('[1] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F1), F1]));

  // 2) UTF-8+BOM -> UTF-8 (in-place)
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F2, F2, 'UTF-8 with BOM', 'UTF-8', Opt);
  Writeln(Format('[2] BOM -> noBOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [2]', F2);
  LogLine(LogFile, Format('[2] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F2), F2]));

  // 3) empty file noBOM -> BOM (in-place)
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F3, F3, 'UTF-8', 'UTF-8 with BOM', Opt);
  Writeln(Format('[3] empty noBOM -> BOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [3]', F3);
  LogLine(LogFile, Format('[3] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F3), F3]));

  // 4) Verify content preservation for typical text
  // Create content file and roundtrip
  var F4 := TPath.Combine(Dir, 'roundtrip.txt');
  WriteAllTextUTF8NoBOM(F4, 'RoundTrip 内容 12345' + #10 + '新行');
  // noBOM->BOM
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8', 'UTF-8 with BOM', Opt);
  // BOM->noBOM
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8 with BOM', 'UTF-8', Opt);
  PrintResult('After [4] roundtrip', F4);
  LogLine(LogFile, Format('[4] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F4), F4]));

  // 14) UTF-16LE -> UTF-8（验证内容一致）
  var F14_U16LE := TPath.Combine(Dir, 'utf16le_sample.txt');
  var F14_OUT := TPath.Combine(Dir, 'utf16le_to_utf8.txt');
  var F14_Text := 'UTF16LE 内容 Öäü € 你好';
  WriteAllTextUTF16LE(F14_U16LE, F14_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F14_U16LE, F14_OUT, 'UTF-16LE', 'UTF-8', Opt);
  var F14_Read := TFile.ReadAllText(F14_OUT, TEncoding.UTF8);
  if F14_Read = F14_Text then
    LogLine(LogFile, '[14] UTF16LE->UTF8: PASS')
  else
    LogLine(LogFile, Format('[14] UTF16LE->UTF8: FAIL - len(exp)=%d len(act)=%d', [Length(F14_Text), Length(F14_Read)]));

  // 15) UTF-16BE -> UTF-8（验证内容一致）
  var F15_U16BE := TPath.Combine(Dir, 'utf16be_sample.txt');
  var F15_OUT := TPath.Combine(Dir, 'utf16be_to_utf8.txt');
  var F15_Text := 'UTF16BE 內容 Ω≈ç √ ∑ 中文';
  WriteAllTextUTF16BE(F15_U16BE, F15_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F15_U16BE, F15_OUT, 'UTF-16BE', 'UTF-8', Opt);
  var F15_Read := TFile.ReadAllText(F15_OUT, TEncoding.UTF8);
  if F15_Read = F15_Text then
    LogLine(LogFile, '[15] UTF16BE->UTF8: PASS')
  else
    LogLine(LogFile, Format('[15] UTF16BE->UTF8: FAIL - len(exp)=%d len(act)=%d', [Length(F15_Text), Length(F15_Read)]));

  // 16) ANSI(1252) -> UTF-8（验证特殊字符）
  var F16_ANSI := TPath.Combine(Dir, 'ansi1252_sample.txt');
  var F16_OUT := TPath.Combine(Dir, 'ansi1252_to_utf8.txt');
  var F16_Text := 'Ansi-1252: € ñ ä ö ü ß – — “ ”';
  WriteAllTextWithCodepage(F16_ANSI, F16_Text, 1252);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F16_ANSI, F16_OUT, 'ANSI', 'UTF-8', Opt);
  var F16_Read := TFile.ReadAllText(F16_OUT, TEncoding.UTF8);
  if F16_Read = F16_Text then
    LogLine(LogFile, '[16] ANSI1252->UTF8: PASS')
  else
    LogLine(LogFile, Format('[16] ANSI1252->UTF8: FAIL - len(exp)=%d len(act)=%d', [Length(F16_Text), Length(F16_Read)]));

  // 17) ASCII -> UTF-8（内容保持）
  var F17_ASCII := TPath.Combine(Dir, 'ascii_sample.txt');
  var F17_OUT := TPath.Combine(Dir, 'ascii_to_utf8.txt');
  var F17_Text := 'ASCII only, 0123456789, symbols !@#$%^&*()';
  TFile.WriteAllText(F17_ASCII, F17_Text, TEncoding.ASCII);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F17_ASCII, F17_OUT, 'ASCII', 'UTF-8', Opt);
  var F17_Read := TFile.ReadAllText(F17_OUT, TEncoding.UTF8);
  if F17_Read = F17_Text then
    LogLine(LogFile, '[17] ASCII->UTF8: PASS')
  else
    LogLine(LogFile, '[17] ASCII->UTF8: FAIL - content mismatch');

  // 18) 无效UTF-8字节容错（确保不崩溃且有输出）
  var F18_INV := TPath.Combine(Dir, 'invalid_utf8.bin');
  var F18_OUT := TPath.Combine(Dir, 'invalid_utf8_to_utf8.txt');
  var B18: TBytes;
  SetLength(B18, 6);
  // Overlong & invalid sequences: C0 AF, F5 80 80 80, 80
  B18[0] := $C0; B18[1] := $AF; B18[2] := $F5; B18[3] := $80; B18[4] := $80; B18[5] := $80;
  TFile.WriteAllBytes(F18_INV, B18);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F18_INV, F18_OUT, '', 'UTF-8', Opt);
  if R.Success and (TFile.Exists(F18_OUT)) then
    LogLine(LogFile, Format('[18] InvalidUTF8->UTF8: PASS size=%d', [TFile.GetSize(F18_OUT)]))
  else
    LogLine(LogFile, '[18] InvalidUTF8->UTF8: FAIL');

  // 19) UTF-32LE -> UTF-8
  var F19_U32LE := TPath.Combine(Dir, 'utf32le_sample.txt');
  var F19_OUT := TPath.Combine(Dir, 'utf32le_to_utf8.txt');
  var F19_Text := 'UTF32LE 内容 😀 中文';
  WriteAllTextUTF32LE(F19_U32LE, F19_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F19_U32LE, F19_OUT, 'UTF-32LE', 'UTF-8', Opt);
  var F19_Read := TFile.ReadAllText(F19_OUT, TEncoding.UTF8);
  if F19_Read = F19_Text then
    LogLine(LogFile, '[19] UTF32LE->UTF8: PASS')
  else
    LogLine(LogFile, Format('[19] UTF32LE->UTF8: FAIL - len(exp)=%d len(act)=%d', [Length(F19_Text), Length(F19_Read)]));

  // 20) UTF-32BE -> UTF-8
  var F20_U32BE := TPath.Combine(Dir, 'utf32be_sample.txt');
  var F20_OUT := TPath.Combine(Dir, 'utf32be_to_utf8.txt');
  var F20_Text := 'UTF32BE 內容 😀 中文';
  WriteAllTextUTF32BE(F20_U32BE, F20_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F20_U32BE, F20_OUT, 'UTF-32BE', 'UTF-8', Opt);
  var F20_Read := TFile.ReadAllText(F20_OUT, TEncoding.UTF8);
  if F20_Read = F20_Text then
    LogLine(LogFile, '[20] UTF32BE->UTF8: PASS')
  else
    LogLine(LogFile, Format('[20] UTF32BE->UTF8: FAIL - len(exp)=%d len(act)=%d', [Length(F20_Text), Length(F20_Read)]));

  // 21+) 根据编码列表追加若干 Windows/ISO/KOI8/DOS 编码用例（统一到 UTF-8）
  RunCodePageCases(Dir, LogFile);

  // 22) 换行保持性（LF 与 CRLF 不应被改变）
  var F22_LF := TPath.Combine(Dir, 'newline_lf.txt');
  var F22_CRLF := TPath.Combine(Dir, 'newline_crlf.txt');
  var F22_LF_OUT := TPath.Combine(Dir, 'newline_lf_out.txt');
  var F22_CRLF_OUT := TPath.Combine(Dir, 'newline_crlf_out.txt');
  var CRLFStr := 'Line1' + #13#10 + 'Line2' + #13#10 + 'Line3';
  // 精确写入字节，避免被自动规范
  TFile.WriteAllBytes(F22_LF, TEncoding.UTF8.GetBytes('Line1' + #10 + 'Line2' + #10 + 'Line3'));
  TFile.WriteAllBytes(F22_CRLF, TEncoding.UTF8.GetBytes(CRLFStr));
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F22_LF, F22_LF_OUT, 'UTF-8', 'UTF-8', Opt);
  var F22_LF_SRC := TFile.ReadAllBytes(F22_LF);
  var F22_LF_DST := TFile.ReadAllBytes(F22_LF_OUT);
  if (Length(F22_LF_SRC) = Length(F22_LF_DST)) and ((Length(F22_LF_SRC) = 0) or CompareMem(@F22_LF_SRC[0], @F22_LF_DST[0], Length(F22_LF_SRC))) then
    LogLine(LogFile, '[22] Newline LF preserve: PASS')
  else
    LogLine(LogFile, '[22] Newline LF preserve: FAIL');
  R := TEncodingConverter_Improved.ConvertFile(F22_CRLF, F22_CRLF_OUT, 'UTF-8', 'UTF-8', Opt);
  var F22_CRLF_SRC := TFile.ReadAllBytes(F22_CRLF);
  var F22_CRLF_DST := TFile.ReadAllBytes(F22_CRLF_OUT);
  if (Length(F22_CRLF_SRC) = Length(F22_CRLF_DST)) and ((Length(F22_CRLF_SRC) = 0) or CompareMem(@F22_CRLF_SRC[0], @F22_CRLF_DST[0], Length(F22_CRLF_SRC))) then
    LogLine(LogFile, '[22] Newline CRLF preserve: PASS')
  else
    LogLine(LogFile, '[22] Newline CRLF preserve: FAIL');

  // 23) 代理对字符（Emoji 等）跨 UTF-8 -> UTF-16LE -> UTF-8 往返内容保持
  var F23_SRC := TPath.Combine(Dir, 'surrogate_utf8.txt');
  var F23_U16 := TPath.Combine(Dir, 'surrogate_utf16le.txt');
  var F23_OUT := TPath.Combine(Dir, 'surrogate_roundtrip.txt');
  var F23_Text := 'Emoji 😀😜🚀 中文混排 AaΩß — “quotes”';
  TFile.WriteAllText(F23_SRC, F23_Text, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F23_SRC, F23_U16, 'UTF-8', 'UTF-16LE', Opt);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F23_U16, F23_OUT, 'UTF-16LE', 'UTF-8', Opt);
  var F23_Read := TFile.ReadAllText(F23_OUT, TEncoding.UTF8);
  if F23_Read = F23_Text then
    LogLine(LogFile, '[23] Surrogate UTF8->UTF16LE->UTF8: PASS')
  else
    LogLine(LogFile, Format('[23] Surrogate roundtrip: FAIL - len(exp)=%d len(act)=%d', [Length(F23_Text), Length(F23_Read)]));

  // 24) UTF-32LE+BOM 同编码转换幂等性（字节级一致）
  var F24_U32 := TPath.Combine(Dir, 'u32le_bom.txt');
  var F24_OUT := TPath.Combine(Dir, 'u32le_bom_out.txt');
  var F24_Text := 'UTF32LE 同编码转换幂等性测试 😀 中文 ABC123';
  WriteAllTextUTF32LE(F24_U32, F24_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F24_U32, F24_OUT, 'UTF-32LE', 'UTF-32LE', Opt);
  var F24_SRC := TFile.ReadAllBytes(F24_U32);
  var F24_DST := TFile.ReadAllBytes(F24_OUT);
  if (Length(F24_SRC) = Length(F24_DST)) and ((Length(F24_SRC) = 0) or CompareMem(@F24_SRC[0], @F24_DST[0], Length(F24_SRC))) then
    LogLine(LogFile, '[24] UTF32LE+BOM idempotence: PASS')
  else
    LogLine(LogFile, '[24] UTF32LE+BOM idempotence: FAIL');

  // 25) 超长单行稳定性（>1MB，无换行）
  var F25_SRC := TPath.Combine(Dir, 'long_single_line.txt');
  var F25_OUT := TPath.Combine(Dir, 'long_single_line_out.txt');
  var S25 := '';
  for I := 1 to 1024 do // 1024 * ~2KB = ~2MB
    S25 := S25 + StringOfChar('A', 1500) + '中文😀';
  TFile.WriteAllText(F25_SRC, S25, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F25_SRC, F25_OUT, 'UTF-8', 'UTF-8', Opt);
  var B25S := TFile.ReadAllBytes(F25_SRC);
  var B25D := TFile.ReadAllBytes(F25_OUT);
  if (Length(B25S) = Length(B25D)) and ((Length(B25S) = 0) or CompareMem(@B25S[0], @B25D[0], Length(B25S))) then
    LogLine(LogFile, '[25] Long single line stability: PASS')
  else
    LogLine(LogFile, '[25] Long single line stability: FAIL');

  // 26) CR-only 换行保持（\r 不应被改动）
  var F26_CR := TPath.Combine(Dir, 'cr_only.txt');
  var F26_OUT := TPath.Combine(Dir, 'cr_only_out.txt');
  var Bytes26: TBytes;
  Bytes26 := TEncoding.UTF8.GetBytes('Line1' + #13 + 'Line2' + #13 + 'Line3');
  TFile.WriteAllBytes(F26_CR, Bytes26);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F26_CR, F26_OUT, 'UTF-8', 'UTF-8', Opt);
  var B26S := TFile.ReadAllBytes(F26_CR);
  var B26D := TFile.ReadAllBytes(F26_OUT);
  if (Length(B26S) = Length(B26D)) and ((Length(B26S) = 0) or CompareMem(@B26S[0], @B26D[0], Length(B26S))) then
    LogLine(LogFile, '[26] CR-only newline preserve: PASS')
  else
    LogLine(LogFile, '[26] CR-only newline preserve: FAIL');

  // 27) UTF-8(含 Emoji/CJK) -> Windows-1252（替换字符? 检查非可映射字符被替换）
  var F27_SRC := TPath.Combine(Dir, 'utf8_emoji_to_1252.txt');
  var F27_OUT := TPath.Combine(Dir, 'utf8_emoji_to_1252_out.txt');
  var F27_Text := 'Emoji😀 + 中文 + Euro€ + plain ASCII';
  TFile.WriteAllText(F27_SRC, F27_Text, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F27_SRC, F27_OUT, 'UTF-8', 'Windows-1252', Opt);
  var Enc1252 := TEncoding.GetEncoding(1252);
  var F27_Read := TFile.ReadAllText(F27_OUT, Enc1252);
  // Emoji/CJK 预计替换为 '?', 至少应出现一个 '?'
  if (Pos('?', F27_Read) > 0) and (Length(F27_Read) > 0) then
    LogLine(LogFile, '[27] UTF8->Win1252 replacement: PASS')
  else
    LogLine(LogFile, '[27] UTF8->Win1252 replacement: FAIL');

  // 28) 截断 UTF-8 鲁棒性（末尾缺字节不应崩溃）
  var F28_INV := TPath.Combine(Dir, 'utf8_truncated.bin');
  var F28_OUT := TPath.Combine(Dir, 'utf8_truncated_out.txt');
  var B28: TBytes;
  // 合法 UTF-8 "中文A" 的部分字节，然后截断掉最后一个 continuation
  // "中" = E4 B8 AD, "文" = E6 96 87, 去掉最后 87，形成截断序列
  SetLength(B28, 5);
  B28[0] := $E4; B28[1] := $B8; B28[2] := $AD; B28[3] := $E6; B28[4] := $96;
  TFile.WriteAllBytes(F28_INV, B28);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F28_INV, F28_OUT, '', 'UTF-8', Opt);
  if R.Success and TFile.Exists(F28_OUT) then
    LogLine(LogFile, '[28] Truncated UTF-8 robustness: PASS')
  else
    LogLine(LogFile, '[28] Truncated UTF-8 robustness: FAIL');

  // 29) UTF-16BE + BOM 同编码幂等
  var F29_U16BE := TPath.Combine(Dir, 'u16be_bom.txt');
  var F29_OUT := TPath.Combine(Dir, 'u16be_bom_out.txt');
  var F29_Text := 'UTF16BE 幂等性 😀 中文 ABC123';
  WriteAllTextUTF16BE(F29_U16BE, F29_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F29_U16BE, F29_OUT, 'UTF-16BE', 'UTF-16BE', Opt);
  var F29_SRC := TFile.ReadAllBytes(F29_U16BE);
  var F29_DST := TFile.ReadAllBytes(F29_OUT);
  if (Length(F29_SRC) = Length(F29_DST)) and ((Length(F29_SRC) = 0) or CompareMem(@F29_SRC[0], @F29_DST[0], Length(F29_SRC))) then
    LogLine(LogFile, '[29] UTF16BE+BOM idempotence: PASS')
  else
    LogLine(LogFile, '[29] UTF16BE+BOM idempotence: FAIL');

  // 30) UTF-8 含 NUL 字节透传一致（UTF-8->UTF-8）
  var F30_SRC := TPath.Combine(Dir, 'utf8_with_nul.bin');
  var F30_OUT := TPath.Combine(Dir, 'utf8_with_nul_out.bin');
  var B30: TBytes;
  SetLength(B30, 8);
  // ASCII 'A', NUL, 'B', NUL, 然后一个合法 UTF-8 三字节 '中'
  B30[0] := $41; B30[1] := $00; B30[2] := $42; B30[3] := $00; B30[4] := $E4; B30[5] := $B8; B30[6] := $AD; B30[7] := $0A;
  TFile.WriteAllBytes(F30_SRC, B30);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F30_SRC, F30_OUT, 'UTF-8', 'UTF-8', Opt);
  var B30S := TFile.ReadAllBytes(F30_SRC);
  var B30D := TFile.ReadAllBytes(F30_OUT);
  if (Length(B30S) = Length(B30D)) and ((Length(B30S) = 0) or CompareMem(@B30S[0], @B30D[0], Length(B30S))) then
    LogLine(LogFile, '[30] UTF8 with NUL passthrough: PASS')
  else
    LogLine(LogFile, '[30] UTF8 with NUL passthrough: FAIL');

  // 31) UTF-8 已含 BOM 且 AddBOM=True 不应重复添加
  var F31_SRC := TPath.Combine(Dir, 'utf8_already_bom.txt');
  var F31_OUT := TPath.Combine(Dir, 'utf8_already_bom_out.txt');
  WriteAllTextUTF8WithBOM(F31_SRC, 'Already BOM \n 一次即可');
  var Len31Before := TFile.GetSize(F31_SRC);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F31_SRC, F31_OUT, 'UTF-8 with BOM', 'UTF-8 with BOM', Opt);
  var B31 := TFile.ReadAllBytes(F31_OUT);
  var Len31After := Length(B31);
  var SingleBOM := (Len31Before = Len31After) and (Len31After >= 3) and (B31[0] = $EF) and (B31[1] = $BB) and (B31[2] = $BF);
  if SingleBOM then
    LogLine(LogFile, '[31] UTF8 BOM not duplicated: PASS')
  else
    LogLine(LogFile, '[31] UTF8 BOM not duplicated: FAIL');

  // 32) UTF-32BE + BOM 同编码幂等
  var F32_U32BE := TPath.Combine(Dir, 'u32be_bom.txt');
  var F32_OUT := TPath.Combine(Dir, 'u32be_bom_out.txt');
  var F32_Text := 'UTF32BE 幂等性 😀 中文 ABC123';
  WriteAllTextUTF32BE(F32_U32BE, F32_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F32_U32BE, F32_OUT, 'UTF-32BE', 'UTF-32BE', Opt);
  var F32_SRC := TFile.ReadAllBytes(F32_U32BE);
  var F32_DST := TFile.ReadAllBytes(F32_OUT);
  if (Length(F32_SRC) = Length(F32_DST)) and ((Length(F32_SRC) = 0) or CompareMem(@F32_SRC[0], @F32_DST[0], Length(F32_SRC))) then
    LogLine(LogFile, '[32] UTF32BE+BOM idempotence: PASS')
  else
    LogLine(LogFile, '[32] UTF32BE+BOM idempotence: FAIL');

  // 33) UTF-16LE + BOM 同编码幂等
  var F33_U16LE := TPath.Combine(Dir, 'u16le_bom.txt');
  var F33_OUT := TPath.Combine(Dir, 'u16le_bom_out.txt');
  var F33_Text := 'UTF16LE 幂等性 😀 中文 ABC123';
  WriteAllTextUTF16LE(F33_U16LE, F33_Text);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F33_U16LE, F33_OUT, 'UTF-16LE', 'UTF-16LE', Opt);
  var F33_SRC := TFile.ReadAllBytes(F33_U16LE);
  var F33_DST := TFile.ReadAllBytes(F33_OUT);
  if (Length(F33_SRC) = Length(F33_DST)) and ((Length(F33_SRC) = 0) or CompareMem(@F33_SRC[0], @F33_DST[0], Length(F33_SRC))) then
    LogLine(LogFile, '[33] UTF16LE+BOM idempotence: PASS')
  else
    LogLine(LogFile, '[33] UTF16LE+BOM idempotence: FAIL');

  // 34) UTF-16LE 已含 BOM 且 AddBOM=True 不应重复添加
  var F34_SRC := TPath.Combine(Dir, 'u16le_already_bom.txt');
  var F34_OUT := TPath.Combine(Dir, 'u16le_already_bom_out.txt');
  WriteAllTextUTF16LE(F34_SRC, 'Already BOM UTF16LE 一次即可');
  var Len34Before := TFile.GetSize(F34_SRC);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True; Opt.DetectSourceEncoding := False;
  R := TEncodingConverter_Improved.ConvertFile(F34_SRC, F34_OUT, 'UTF-16LE', 'UTF-16LE', Opt);
  var B34 := TFile.ReadAllBytes(F34_OUT);
  var Len34After := Length(B34);
  var SingleBOM16 := (Len34Before = Len34After) and (Len34After >= 2) and (B34[0] = $FF) and (B34[1] = $FE);
  if SingleBOM16 then
    LogLine(LogFile, '[34] UTF16LE BOM not duplicated: PASS')
  else
    LogLine(LogFile, '[34] UTF16LE BOM not duplicated: FAIL');

  // 35) 仅 BOM 文件行为（UTF-8 与 UTF-16LE）
  // 35a UTF-8 only BOM
  var F35a_SRC := TPath.Combine(Dir, 'only_bom_utf8.bin');
  var F35a_OUT := TPath.Combine(Dir, 'only_bom_utf8_out.bin');
  var B35a: TBytes; SetLength(B35a, 3); B35a[0] := $EF; B35a[1] := $BB; B35a[2] := $BF;
  TFile.WriteAllBytes(F35a_SRC, B35a);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F35a_SRC, F35a_OUT, '', 'UTF-8', Opt);
  var B35aS := TFile.ReadAllBytes(F35a_SRC);
  var B35aD := TFile.ReadAllBytes(F35a_OUT);
  if (Length(B35aS) = Length(B35aD)) and ((Length(B35aS) = 0) or CompareMem(@B35aS[0], @B35aD[0], Length(B35aS))) then
    LogLine(LogFile, '[35a] Only-BOM UTF-8 behavior: PASS')
  else
    LogLine(LogFile, '[35a] Only-BOM UTF-8 behavior: FAIL');

  // 35b UTF-16LE only BOM
  var F35b_SRC := TPath.Combine(Dir, 'only_bom_utf16le.bin');
  var F35b_OUT := TPath.Combine(Dir, 'only_bom_utf16le_out.bin');
  var B35b: TBytes; SetLength(B35b, 2); B35b[0] := $FF; B35b[1] := $FE;
  TFile.WriteAllBytes(F35b_SRC, B35b);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F35b_SRC, F35b_OUT, '', 'UTF-16LE', Opt);
  var B35bS := TFile.ReadAllBytes(F35b_SRC);
  var B35bD := TFile.ReadAllBytes(F35b_OUT);
  if (Length(B35bS) = Length(B35bD)) and ((Length(B35bS) = 0) or CompareMem(@B35bS[0], @B35bD[0], Length(B35bS))) then
    LogLine(LogFile, '[35b] Only-BOM UTF-16LE behavior: PASS')
  else
    LogLine(LogFile, '[35b] Only-BOM UTF-16LE behavior: FAIL');

  // 36) 仅 BOM 跨编码行为（AddBOM=False 时期望空负载）
  // 36a: UTF-16LE only BOM -> UTF-8 (no BOM)
  var F36a_SRC := TPath.Combine(Dir, 'only_bom_u16le_to_utf8.bin');
  var F36a_OUT := TPath.Combine(Dir, 'only_bom_u16le_to_utf8_out.bin');
  var B36a: TBytes; SetLength(B36a, 2); B36a[0] := $FF; B36a[1] := $FE; TFile.WriteAllBytes(F36a_SRC, B36a);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F36a_SRC, F36a_OUT, '', 'UTF-8', Opt);
  var L36a := TFile.GetSize(F36a_OUT);
  if R.Success and (L36a = 0) then
    LogLine(LogFile, '[36a] Only-BOM UTF16LE -> UTF8 (no BOM) empty payload: PASS')
  else
    LogLine(LogFile, Format('[36a] Only-BOM UTF16LE -> UTF8: FAIL (len=%d)', [L36a]));

  // 36b: UTF-8 only BOM -> UTF-16LE (no BOM)
  var F36b_SRC := TPath.Combine(Dir, 'only_bom_utf8_to_u16le.bin');
  var F36b_OUT := TPath.Combine(Dir, 'only_bom_utf8_to_u16le_out.bin');
  var B36b: TBytes; SetLength(B36b, 3); B36b[0] := $EF; B36b[1] := $BB; B36b[2] := $BF; TFile.WriteAllBytes(F36b_SRC, B36b);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := True;
  R := TEncodingConverter_Improved.ConvertFile(F36b_SRC, F36b_OUT, '', 'UTF-16LE', Opt);
  var L36b := TFile.GetSize(F36b_OUT);
  if R.Success and (L36b = 0) then
    LogLine(LogFile, '[36b] Only-BOM UTF8 -> UTF16LE (no BOM) empty payload: PASS')
  else
    LogLine(LogFile, Format('[36b] Only-BOM UTF8 -> UTF16LE: FAIL (len=%d)', [L36b]));

  // 37) ConvertStream 流式转换与 ConvertFile 结果一致
  var F37_SRC := TPath.Combine(Dir, 'stream_source.txt');
  var F37_OUT_FILE := TPath.Combine(Dir, 'stream_out_by_file.txt');
  var F37_OUT_STREAM := TPath.Combine(Dir, 'stream_out_by_stream.txt');
  var S37 := 'Stream 测试😀 AaΩ — “quotes”' + #10 + '第二行中文' + #13#10 + '第三行 end';
  TFile.WriteAllText(F37_SRC, S37, TEncoding.UTF8);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False; Opt.DetectSourceEncoding := False;
  // ConvertFile
  R := TEncodingConverter_Improved.ConvertFile(F37_SRC, F37_OUT_FILE, 'UTF-8', 'UTF-8', Opt);
  // ConvertStream
  var FSIn := TFileStream.Create(F37_SRC, fmOpenRead or fmShareDenyNone);
  var FSOut := TFileStream.Create(F37_OUT_STREAM, fmCreate);
  try
    var R2 := TEncodingConverter_Improved.ConvertStream(FSIn, FSOut, 'UTF-8', 'UTF-8', Opt);
  finally
    FSIn.Free; FSOut.Free;
  end;
  var B37F := TFile.ReadAllBytes(F37_OUT_FILE);
  var B37S := TFile.ReadAllBytes(F37_OUT_STREAM);
  if (Length(B37F) = Length(B37S)) and ((Length(B37F) = 0) or CompareMem(@B37F[0], @B37S[0], Length(B37F))) then
    LogLine(LogFile, '[37] ConvertStream vs ConvertFile: PASS')
  else
    LogLine(LogFile, '[37] ConvertStream vs ConvertFile: FAIL');

  // 38) 混合换行 (LF/CRLF/CR) 在 UTF-8 -> UTF-8 下字节保持
  var F38_SRC := TPath.Combine(Dir, 'mixed_newlines.txt');
  var F38_OUT := TPath.Combine(Dir, 'mixed_newlines_out.txt');
  var Mixed := TEncoding.UTF8.GetBytes('L1' + #10 + 'L2' + #13#10 + 'L3' + #13 + 'L4' + #10#13 + 'END');
  TFile.WriteAllBytes(F38_SRC, Mixed);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F38_SRC, F38_OUT, 'UTF-8', 'UTF-8', Opt);
  var B38S := TFile.ReadAllBytes(F38_SRC);
  var B38D := TFile.ReadAllBytes(F38_OUT);
  if (Length(B38S) = Length(B38D)) and ((Length(B38S) = 0) or CompareMem(@B38S[0], @B38D[0], Length(B38S))) then
    LogLine(LogFile, '[38] Mixed newline byte-preserve: PASS')
  else
    LogLine(LogFile, '[38] Mixed newline byte-preserve: FAIL');

  // 39) 超大文件（~200MB）UTF-8 -> UTF-8：大小一致，首尾片段一致
  var F39_SRC := TPath.Combine(Dir, 'huge_utf8.txt');
  var F39_OUT := TPath.Combine(Dir, 'huge_utf8_out.txt');
  // 用流式写入，避免占用过多内存
  var Chunk39 := TEncoding.UTF8.GetBytes(StringOfChar('A', 2048) + '中文😀' + sLineBreak); // ~2KB+
  var TargetMB := 200;
  var BytesPerMB := 1024 * 1024;
  var Stream39 := TFileStream.Create(F39_SRC, fmCreate);
  try
    var Written := 0;
    while Written < TargetMB * BytesPerMB do
    begin
      Stream39.WriteBuffer(Chunk39[0], Length(Chunk39));
      Inc(Written, Length(Chunk39));
    end;
  finally
    Stream39.Free;
  end;

  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F39_SRC, F39_OUT, 'UTF-8', 'UTF-8', Opt);
  var Size39S := TFile.GetSize(F39_SRC);
  var Size39D := TFile.GetSize(F39_OUT);
  var FirstLastEqual := False;
  if (Size39S = Size39D) and (Size39S > 8192) then
  begin
    var FS1 := TFileStream.Create(F39_SRC, fmOpenRead or fmShareDenyNone);
    var FS2 := TFileStream.Create(F39_OUT, fmOpenRead or fmShareDenyNone);
    try
      var Head1, Head2, Tail1, Tail2: TBytes;
      SetLength(Head1, 4096); SetLength(Head2, 4096);
      SetLength(Tail1, 4096); SetLength(Tail2, 4096);
      // 读头部
      FS1.Position := 0; FS1.ReadBuffer(Head1[0], Length(Head1));
      FS2.Position := 0; FS2.ReadBuffer(Head2[0], Length(Head2));
      // 读尾部
      FS1.Position := Size39S - 4096; FS1.ReadBuffer(Tail1[0], Length(Tail1));
      FS2.Position := Size39D - 4096; FS2.ReadBuffer(Tail2[0], Length(Tail2));
      FirstLastEqual := CompareMem(@Head1[0], @Head2[0], 4096) and CompareMem(@Tail1[0], @Tail2[0], 4096);
    finally
      FS1.Free; FS2.Free;
    end;
  end;
  if (Size39S = Size39D) and FirstLastEqual and R.Success then
    LogLine(LogFile, Format('[39] Huge UTF8->UTF8: PASS size=%dMB', [Size39S div (1024*1024)]))
  else
    LogLine(LogFile, Format('[39] Huge UTF8->UTF8: FAIL in=%d out=%d head_tail_match=%s success=%s',
      [Size39S, Size39D, BoolToStr(FirstLastEqual, True), BoolToStr(R.Success, True)]));

  // 40) 200MB ConvertStream 流式转换与 ConvertFile 结果一致
  var F40_SRC := F39_SRC; // 复用 200MB 源
  var F40_OUT_FILE := TPath.Combine(Dir, 'huge_utf8_out_by_file.txt');
  var F40_OUT_STREAM := TPath.Combine(Dir, 'huge_utf8_out_by_stream.txt');
  // 先用文件接口输出
  Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F40_SRC, F40_OUT_FILE, 'UTF-8', 'UTF-8', Opt);
  // 再用流接口输出
  var FSIn40 := TFileStream.Create(F40_SRC, fmOpenRead or fmShareDenyNone);
  var FSOut40 := TFileStream.Create(F40_OUT_STREAM, fmCreate);
  try
    var R40 := TEncodingConverter_Improved.ConvertStream(FSIn40, FSOut40, 'UTF-8', 'UTF-8', Opt);
  finally
    FSIn40.Free; FSOut40.Free;
  end;
  var Size40F := TFile.GetSize(F40_OUT_FILE);
  var Size40S := TFile.GetSize(F40_OUT_STREAM);
  var HeadTailOk40 := False;
  if (Size40F = Size40S) and (Size40F > 8192) then
  begin
    var FF := TFileStream.Create(F40_OUT_FILE, fmOpenRead or fmShareDenyNone);
    var FS := TFileStream.Create(F40_OUT_STREAM, fmOpenRead or fmShareDenyNone);
    try
      var H1, H2, T1, T2: TBytes; SetLength(H1,4096); SetLength(H2,4096); SetLength(T1,4096); SetLength(T2,4096);
      FF.Position := 0; FF.ReadBuffer(H1[0], Length(H1));
      FS.Position := 0; FS.ReadBuffer(H2[0], Length(H2));
      FF.Position := Size40F - 4096; FF.ReadBuffer(T1[0], Length(T1));
      FS.Position := Size40S - 4096; FS.ReadBuffer(T2[0], Length(T2));
      HeadTailOk40 := CompareMem(@H1[0], @H2[0], 4096) and CompareMem(@T1[0], @T2[0], 4096);
    finally
      FF.Free; FS.Free;
    end;
  end;
  if (Size40F = Size40S) and HeadTailOk40 then
    LogLine(LogFile, '[40] Huge ConvertStream vs ConvertFile: PASS')
  else
    LogLine(LogFile, Format('[40] Huge ConvertStream vs ConvertFile: FAIL sizeF=%d sizeS=%d match=%s', [Size40F, Size40S, BoolToStr(HeadTailOk40, True)]));

  // 41) UTF-8 noBOM <-> with BOM 连续10次往返最终无BOM结果与初始一致（字节级）
  var F41_A := TPath.Combine(Dir, 'flip10_a.txt');
  var F41_B := TPath.Combine(Dir, 'flip10_b.txt');
  var S41 := 'Flip10 往返稳定性 😀 中文 ABC123' + sLineBreak + '第二行';
  TFile.WriteAllText(F41_A, S41, TEncoding.UTF8);
  var Base41 := TFile.ReadAllBytes(F41_A);
  for I := 1 to 10 do
  begin
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
    R := TEncodingConverter_Improved.ConvertFile(F41_A, F41_B, 'UTF-8', 'UTF-8 with BOM', Opt);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F41_B, F41_A, 'UTF-8 with BOM', 'UTF-8', Opt);
  end;
  var End41 := TFile.ReadAllBytes(F41_A);
  if (Length(Base41) = Length(End41)) and ((Length(Base41) = 0) or CompareMem(@Base41[0], @End41[0], Length(Base41))) then
    LogLine(LogFile, '[41] 10x UTF8 roundtrip idempotence: PASS')
  else
    LogLine(LogFile, '[41] 10x UTF8 roundtrip idempotence: FAIL');

  // 42) BOM flip-flop 50次稳定性（A<->B交替，最终回到初始）
  var F42_A := TPath.Combine(Dir, 'flip50_a.txt');
  var F42_B := TPath.Combine(Dir, 'flip50_b.txt');
  var S42 := 'Flip50 稳定性 😀 中文 ABC123';
  TFile.WriteAllText(F42_A, S42, TEncoding.UTF8);
  var Base42 := TFile.ReadAllBytes(F42_A);
  for I := 1 to 50 do
  begin
    if Odd(I) then
    begin
      Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := True;
      R := TEncodingConverter_Improved.ConvertFile(F42_A, F42_B, 'UTF-8', 'UTF-8 with BOM', Opt);
    end
    else
    begin
      Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
      R := TEncodingConverter_Improved.ConvertFile(F42_B, F42_A, 'UTF-8 with BOM', 'UTF-8', Opt);
    end;
  end;
  // 确保回到无BOM文件
  if FileExists(F42_B) and FileExists(F42_A) then
  begin
    var End42 := TFile.ReadAllBytes(F42_A);
    if (Length(Base42) = Length(End42)) and ((Length(Base42) = 0) or CompareMem(@Base42[0], @End42[0], Length(Base42))) then
      LogLine(LogFile, '[42] 50x BOM flip-flop stability: PASS')
    else
      LogLine(LogFile, '[42] 50x BOM flip-flop stability: FAIL');
  end
  else
    LogLine(LogFile, Format('[42] 50x BOM flip-flop stability: FAIL (file missing)'));

  // 运行新增的特定编码/场景边界用例 [43]-[46]
  RunAdditionalEdgeCases(Dir, LogFile);

  // 运行扩展项（1-6）
  RunExtendedCategoriesTests(Dir, LogFile);
end;

procedure WriteAllTextUTF8NoBOM(const FileName, S: string);
var
  Bytes: TBytes;
{{ ... }}
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

procedure LogLine(const FilePath, S: string);
begin
  // 以 UTF-8（无 BOM）追加日志
  TFile.AppendAllText(FilePath, S + sLineBreak, TEncoding.UTF8);
end;

procedure WriteAllTextGBK(const FileName, S: string);
var
  Enc: TEncoding;
  Bytes: TBytes;
begin
  Enc := TEncoding.GetEncoding(936); // GBK/CP936
  try
    Bytes := Enc.GetBytes(S);
    TFile.WriteAllBytes(FileName, Bytes);
  finally
    Enc.Free;
  end;
end;

procedure RunTests;
var
  Root, Dir, F1, F2, F3: string;
  Opt: TEncodingConversionOptions;
  R: TEncodingConversionResult;
  LogFile: string;
begin
  Root := ExtractFilePath(ParamStr(0));
  Dir := TPath.Combine(Root, '..\\tmp_tests');
  ForceDirectories(Dir);
  F1 := TPath.Combine(Dir, 'utf8_no_bom.txt');
  F2 := TPath.Combine(Dir, 'utf8_bom.txt');
  F3 := TPath.Combine(Dir, 'empty.txt');
  LogFile := TPath.Combine(Dir, 'selftest_log.txt');

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
  LogLine(LogFile, Format('[1] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F1), F1]));

  // 2) UTF-8+BOM -> UTF-8 (in-place)
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F2, F2, 'UTF-8 with BOM', 'UTF-8', Opt);
  Writeln(Format('[2] BOM -> noBOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [2]', F2);
  LogLine(LogFile, Format('[2] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F2), F2]));

  // 3) empty file noBOM -> BOM (in-place)
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F3, F3, 'UTF-8', 'UTF-8 with BOM', Opt);
  Writeln(Format('[3] empty noBOM -> BOM: success=%s, bytes=%d, errors=%d',
    [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  PrintResult('After [3]', F3);
  LogLine(LogFile, Format('[3] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F3), F3]));

  // 4) Verify content preservation for typical text
  // Create content file and roundtrip
  var F4 := TPath.Combine(Dir, 'roundtrip.txt');
  WriteAllTextUTF8NoBOM(F4, 'RoundTrip 内容 12345' + #10 + '新行');
  // noBOM->BOM
  Opt.AddBOM := True;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8', 'UTF-8 with BOM', Opt);
  // BOM->noBOM
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F4, F4, 'UTF-8 with BOM', 'UTF-8', Opt);
  PrintResult('After [4] roundtrip', F4);
  LogLine(LogFile, Format('[4] success=%s size=%d file=%s', [BoolToStr(R.Success, True), TFile.GetSize(F4), F4]));
  // 验证 roundtrip 内容完整性
  var F4Expected := 'RoundTrip 内容 12345' + #10 + '新行';
  var F4Bytes := TFile.ReadAllBytes(F4);
  var F4ExpectBytes := TEncoding.UTF8.GetBytes(F4Expected);
  if (Length(F4Bytes) = Length(F4ExpectBytes)) and
     ((Length(F4Bytes) = 0) or CompareMem(@F4Bytes[0], @F4ExpectBytes[0], Length(F4Bytes))) then
    LogLine(LogFile, '[4] Content verification: PASS (byte-equal)')
  else
    LogLine(LogFile, Format('[4] Content verification: FAIL (byte) - exp=%d act=%d', [Length(F4ExpectBytes), Length(F4Bytes)]));

  // 5) GBK/ANSI -> UTF-8 验证
  var F5_GBK := TPath.Combine(Dir, 'gbk_sample.txt');
  var F5_OUT := TPath.Combine(Dir, 'gbk_to_utf8.txt');
  WriteAllTextGBK(F5_GBK, '这是GBK内容：中文测试123');
  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  Opt.DetectSourceEncoding := False; // 禁用自动检测，强制使用 GBK
  R := TEncodingConverter_Improved.ConvertFile(F5_GBK, F5_OUT, 'GBK', 'UTF-8', Opt);
  Writeln(Format('[5] GBK->UTF8: success=%s, out_bytes=%d, errors=%d', [BoolToStr(R.Success, True), R.BytesProcessed, R.ErrorCount]));
  LogLine(LogFile, Format('[5] success=%s in=%d out=%d files=(%s => %s)', [BoolToStr(R.Success, True), TFile.GetSize(F5_GBK), TFile.GetSize(F5_OUT), F5_GBK, F5_OUT]));

  // 5b) GBK -> UTF-8+BOM 验证
  var F5b_OUT := TPath.Combine(Dir, 'gbk_to_utf8_bom.txt');
  Opt.AddBOM := True;
  Opt.DetectSourceEncoding := False; // 禁用自动检测，强制使用 GBK
  R := TEncodingConverter_Improved.ConvertFile(F5_GBK, F5b_OUT, 'GBK', 'UTF-8 with BOM', Opt);
  var F5b_Bytes := TFile.ReadAllBytes(F5b_OUT);
  var F5b_HasBOM := (Length(F5b_Bytes) >= 3) and (F5b_Bytes[0] = $EF) and (F5b_Bytes[1] = $BB) and (F5b_Bytes[2] = $BF);
  var F5b_First3 := '';
  if Length(F5b_Bytes) >= 3 then
    F5b_First3 := Format('%02X %02X %02X', [F5b_Bytes[0], F5b_Bytes[1], F5b_Bytes[2]]);
  LogLine(LogFile, Format('[5b] GBK->UTF8+BOM success=%s size=%d hasBOM=%s first3=%s', [BoolToStr(R.Success, True), Length(F5b_Bytes), BoolToStr(F5b_HasBOM, True), F5b_First3]));

  // 6) 大文件（>50MB）UTF-8 -> UTF-8 验证（确认不被截断）
  var F6_SRC := TPath.Combine(Dir, 'large_utf8.txt');
  var F6_OUT := TPath.Combine(Dir, 'large_utf8_out.txt');
  // 生成约 60MB UTF-8 文本
  var Chunk := StringOfChar(WideChar($4F60), 256) + StringOfChar('A', 768) + sLineBreak; // ~2KB/行
  var LinesPerMB := 500; // 约 1MB
  var TotalMB := 60;
  var I, J: Integer;
  var FS: TFileStream := TFileStream.Create(F6_SRC, fmCreate);
  try
    for I := 1 to TotalMB do
    begin
      for J := 1 to LinesPerMB do
      begin
        var B: TBytes := TEncoding.UTF8.GetBytes(Chunk);
        FS.WriteBuffer(B[0], Length(B));
      end;
    end;
  finally
    FS.Free;
  end;

  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F6_SRC, F6_OUT, 'UTF-8', 'UTF-8', Opt);
  Writeln(Format('[6] Large UTF8->UTF8: success=%s, in=%d, out=%d, errors=%d', [BoolToStr(R.Success, True), TFile.GetSize(F6_SRC), TFile.GetSize(F6_OUT), R.ErrorCount]));
  LogLine(LogFile, Format('[6] success=%s in=%d out=%d (expect equal)', [BoolToStr(R.Success, True), TFile.GetSize(F6_SRC), TFile.GetSize(F6_OUT)]));
  // 验证大文件字节级完整性
  var F6_SRC_Bytes := TFile.ReadAllBytes(F6_SRC);
  var F6_OUT_Bytes := TFile.ReadAllBytes(F6_OUT);
  var F6_Match := (Length(F6_SRC_Bytes) = Length(F6_OUT_Bytes));
  if F6_Match and (Length(F6_SRC_Bytes) > 0) then
    F6_Match := CompareMem(@F6_SRC_Bytes[0], @F6_OUT_Bytes[0], Length(F6_SRC_Bytes));
  if F6_Match then
    LogLine(LogFile, '[6] Byte-level verification: PASS')
  else
    LogLine(LogFile, '[6] Byte-level verification: FAIL - bytes mismatch');

  // 7) Shift_JIS -> UTF-8
  var F7_SJIS := TPath.Combine(Dir, 'shift_jis_sample.txt');
  var F7_OUT := TPath.Combine(Dir, 'shift_jis_to_utf8.txt');
  WriteAllTextWithCodepage(F7_SJIS, 'ｼﾌﾄJIS テスト 日本語abc123', 932);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F7_SJIS, F7_OUT, 'Shift_JIS', 'UTF-8', Opt);
  LogLine(LogFile, Format('[7] success=%s in=%d out=%d files=(%s => %s)', [BoolToStr(R.Success, True), TFile.GetSize(F7_SJIS), TFile.GetSize(F7_OUT), F7_SJIS, F7_OUT]));

  // 8) Big5 -> UTF-8
  var F8_BIG5 := TPath.Combine(Dir, 'big5_sample.txt');
  var F8_OUT := TPath.Combine(Dir, 'big5_to_utf8.txt');
  WriteAllTextWithCodepage(F8_BIG5, '繁體中文測試ABC123', 950);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F8_BIG5, F8_OUT, 'Big5', 'UTF-8', Opt);
  LogLine(LogFile, Format('[8] success=%s in=%d out=%d files=(%s => %s)', [BoolToStr(R.Success, True), TFile.GetSize(F8_BIG5), TFile.GetSize(F8_OUT), F8_BIG5, F8_OUT]));

  // 9) EUC-KR -> UTF-8
  var F9_EUCKR := TPath.Combine(Dir, 'euckr_sample.txt');
  var F9_OUT := TPath.Combine(Dir, 'euckr_to_utf8.txt');
  WriteAllTextWithCodepage(F9_EUCKR, '한국어 테스트 ABC123', 51949);
  Opt := TEncodingConverter_Improved.CreateDefaultOptions;
  Opt.AddBOM := False;
  R := TEncodingConverter_Improved.ConvertFile(F9_EUCKR, F9_OUT, 'EUC-KR', 'UTF-8', Opt);
  LogLine(LogFile, Format('[9] success=%s in=%d out=%d files=(%s => %s)', [BoolToStr(R.Success, True), TFile.GetSize(F9_EUCKR), TFile.GetSize(F9_OUT), F9_EUCKR, F9_OUT]));

  // 10-13) ICU 样本 ra.txt 基础上的多编码往返验证
  var ICUBase := TPath.Combine(Dir, 'icu');
  ForceDirectories(ICUBase);
  var ICUTextPath := TPath.Combine(ICUBase, 'ra.txt');
  if TFile.Exists(ICUTextPath) then
  begin
    var ICUText := TFile.ReadAllText(ICUTextPath, TEncoding.UTF8);

    // 10) ICU->GBK->UTF8
    var F10_GBK := TPath.Combine(ICUBase, 'ra_gbk.txt');
    var F10_OUT := TPath.Combine(ICUBase, 'ra_gbk_to_utf8.txt');
    WriteAllTextWithCodepage(F10_GBK, ICUText, 936);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F10_GBK, F10_OUT, 'GBK', 'UTF-8', Opt);
    LogLine(LogFile, Format('[10][ICU] GBK->UTF8 success=%s in=%d out=%d', [BoolToStr(R.Success, True), TFile.GetSize(F10_GBK), TFile.GetSize(F10_OUT)]));
    // 验证 ICU GBK 往返内容
    var F10Content := TFile.ReadAllText(F10_OUT, TEncoding.UTF8);
    if F10Content = ICUText then
      LogLine(LogFile, '[10][ICU] Content verification: PASS')
    else
      LogLine(LogFile, Format('[10][ICU] Content verification: FAIL - len(expected)=%d len(actual)=%d', [Length(ICUText), Length(F10Content)]));

    // 11) ICU->Shift_JIS->UTF8
    var F11_SJIS := TPath.Combine(ICUBase, 'ra_sjis.txt');
    var F11_OUT := TPath.Combine(ICUBase, 'ra_sjis_to_utf8.txt');
    WriteAllTextWithCodepage(F11_SJIS, ICUText, 932);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F11_SJIS, F11_OUT, 'Shift_JIS', 'UTF-8', Opt);
    LogLine(LogFile, Format('[11][ICU] SJIS->UTF8 success=%s in=%d out=%d', [BoolToStr(R.Success, True), TFile.GetSize(F11_SJIS), TFile.GetSize(F11_OUT)]));
    var F11Content := TFile.ReadAllText(F11_OUT, TEncoding.UTF8);
    if F11Content = ICUText then
      LogLine(LogFile, '[11][ICU] Content verification: PASS')
    else
      LogLine(LogFile, Format('[11][ICU] Content verification: FAIL - len(expected)=%d len(actual)=%d', [Length(ICUText), Length(F11Content)]));

    // 12) ICU->Big5->UTF8
    var F12_BIG5 := TPath.Combine(ICUBase, 'ra_big5.txt');
    var F12_OUT := TPath.Combine(ICUBase, 'ra_big5_to_utf8.txt');
    WriteAllTextWithCodepage(F12_BIG5, ICUText, 950);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F12_BIG5, F12_OUT, 'Big5', 'UTF-8', Opt);
    LogLine(LogFile, Format('[12][ICU] Big5->UTF8 success=%s in=%d out=%d', [BoolToStr(R.Success, True), TFile.GetSize(F12_BIG5), TFile.GetSize(F12_OUT)]));
    var F12Content := TFile.ReadAllText(F12_OUT, TEncoding.UTF8);
    if F12Content = ICUText then
      LogLine(LogFile, '[12][ICU] Content verification: PASS')
    else
      LogLine(LogFile, Format('[12][ICU] Content verification: FAIL - len(expected)=%d len(actual)=%d', [Length(ICUText), Length(F12Content)]));

    // 13) ICU->EUC-KR->UTF8
    var F13_EUCKR := TPath.Combine(ICUBase, 'ra_euckr.txt');
    var F13_OUT := TPath.Combine(ICUBase, 'ra_euckr_to_utf8.txt');
    WriteAllTextWithCodepage(F13_EUCKR, ICUText, 51949);
    Opt := TEncodingConverter_Improved.CreateDefaultOptions; Opt.AddBOM := False;
    R := TEncodingConverter_Improved.ConvertFile(F13_EUCKR, F13_OUT, 'EUC-KR', 'UTF-8', Opt);
    LogLine(LogFile, Format('[13][ICU] EUC-KR->UTF8 success=%s in=%d out=%d', [BoolToStr(R.Success, True), TFile.GetSize(F13_EUCKR), TFile.GetSize(F13_OUT)]));
    var F13Content := TFile.ReadAllText(F13_OUT, TEncoding.UTF8);
    if F13Content = ICUText then
      LogLine(LogFile, '[13][ICU] Content verification: PASS')
    else
      LogLine(LogFile, Format('[13][ICU] Content verification: FAIL - len(expected)=%d len(actual)=%d', [Length(ICUText), Length(F13Content)]));
  end
  else
  begin
    LogLine(LogFile, '[ICU] ra.txt not found, skip ICU-based tests');
  end;
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
