program EncodingTestRunner;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Winapi.Windows,
  UtilsEncodingConstants in 'UtilsEncodingConstants.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingDetect2 in 'UtilsEncodingDetect2.pas',
  UTF8BOMConverter_Simple in 'UTF8BOMConverter_Simple.pas',
  UTF8BOMConverter_Enhanced in 'UTF8BOMConverter_Enhanced.pas',
  UtilsEncodingSpecialChars in 'UtilsEncodingSpecialChars.pas',
  EncodingRoundTripValidator in 'EncodingRoundTripValidator.pas';

type
  TTestMode = (tmDetection, tmConversion, tmRoundTrip, tmSpecialChars, tmAll);

  TCommandLineOptions = record
    TestMode: TTestMode;
    SourceFiles: TArray<string>;
    SourceEncoding: string;
    TargetEncoding: string;
    TestDirectory: string;
    Recursive: Boolean;
    Verbose: Boolean;
    OutputFile: string;
    HelpRequested: Boolean;
    InvalidArgs: Boolean;
    ErrorMessage: string;
    procedure Init;
  end;

  TTestRunner = class
  private
    FOptions: TCommandLineOptions;
    FOutputLog: TStringList;
    
    procedure LogInfo(const Msg: string);
    procedure LogError(const Msg: string);
    procedure LogSuccess(const Msg: string);
    procedure LogWarning(const Msg: string);
    
    function CollectTestFiles: TArray<string>;
    function DetectFileEncoding(const FileName: string): string;
    function ConvertFileEncoding(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): Boolean;
    function ValidateRoundTrip(const SourceFile: string; SourceEncoding, IntermediateEncoding: string): Boolean;
    function ValidateSpecialChars(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): Boolean;
    
    procedure RunDetectionTests;
    procedure RunConversionTests;
    procedure RunRoundTripTests;
    procedure RunSpecialCharsTests;
    procedure RunAllTests;
    
    procedure SaveTestResults;
  public
    constructor Create(const Options: TCommandLineOptions);
    destructor Destroy; override;
    
    procedure Run;
  end;

procedure PrintUsage;
begin
  WriteLn('编码测试程序 - 用法:');
  WriteLn('EncodingTestRunner [选项]');
  WriteLn;
  WriteLn('选项:');
  WriteLn('  -mode <模式>            测试模式: detection(检测), conversion(转换),');
  WriteLn('                          roundtrip(往返), specialchars(特殊字符), all(全部)');
  WriteLn('  -source <文件>          要测试的源文件');
  WriteLn('  -dir <目录>             测试文件所在目录');
  WriteLn('  -recursive              递归处理子目录');
  WriteLn('  -srcenc <编码>          源文件编码');
  WriteLn('  -targenc <编码>         目标编码');
  WriteLn('  -output <文件>          输出结果到文件');
  WriteLn('  -verbose                详细输出');
  WriteLn('  -help                   显示此帮助');
  WriteLn;
  WriteLn('示例:');
  WriteLn('  EncodingTestRunner -mode detection -dir .\TestData -recursive');
  WriteLn('  EncodingTestRunner -mode conversion -source test.txt -srcenc utf-8 -targenc utf-8-bom');
  WriteLn('  EncodingTestRunner -mode roundtrip -source test.txt -srcenc utf-8 -targenc gbk');
  WriteLn('  EncodingTestRunner -mode specialchars -source test.txt -srcenc utf-8 -targenc gbk');
  WriteLn('  EncodingTestRunner -mode all -dir .\TestData');
end;

procedure ParseCommandLine(var Options: TCommandLineOptions);
var
  I: Integer;
  Param, Value: string;
begin
  Options.Init;
  
  I := 1;
  while I <= ParamCount do
  begin
    Param := ParamStr(I);
    
    if Param = '-help' then
    begin
      Options.HelpRequested := True;
      Exit;
    end
    else if Param = '-verbose' then
    begin
      Options.Verbose := True;
    end
    else if Param = '-recursive' then
    begin
      Options.Recursive := True;
    end
    else if Param = '-mode' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        Value := ParamStr(I);
        if Value = 'detection' then
          Options.TestMode := tmDetection
        else if Value = 'conversion' then
          Options.TestMode := tmConversion
        else if Value = 'roundtrip' then
          Options.TestMode := tmRoundTrip
        else if Value = 'specialchars' then
          Options.TestMode := tmSpecialChars
        else if Value = 'all' then
          Options.TestMode := tmAll
        else
        begin
          Options.InvalidArgs := True;
          Options.ErrorMessage := '无效的测试模式: ' + Value;
          Exit;
        end;
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少测试模式';
        Exit;
      end;
    end
    else if Param = '-source' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        SetLength(Options.SourceFiles, 1);
        Options.SourceFiles[0] := ParamStr(I);
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少源文件';
        Exit;
      end;
    end
    else if Param = '-dir' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        Options.TestDirectory := ParamStr(I);
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少测试目录';
        Exit;
      end;
    end
    else if Param = '-srcenc' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        Options.SourceEncoding := ParamStr(I);
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少源编码';
        Exit;
      end;
    end
    else if Param = '-targenc' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        Options.TargetEncoding := ParamStr(I);
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少目标编码';
        Exit;
      end;
    end
    else if Param = '-output' then
    begin
      if I < ParamCount then
      begin
        Inc(I);
        Options.OutputFile := ParamStr(I);
      end
      else
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '缺少输出文件';
        Exit;
      end;
    end
    else
    begin
      Options.InvalidArgs := True;
      Options.ErrorMessage := '无效的参数: ' + Param;
      Exit;
    end;
    
    Inc(I);
  end;
  
  // 验证必需参数
  if (Options.TestMode = tmConversion) or (Options.TestMode = tmRoundTrip) or (Options.TestMode = tmSpecialChars) then
  begin
    if Options.SourceEncoding = '' then
    begin
      Options.InvalidArgs := True;
      Options.ErrorMessage := '转换模式需要源编码';
      Exit;
    end;
    
    if Options.TargetEncoding = '' then
    begin
      Options.InvalidArgs := True;
      Options.ErrorMessage := '转换模式需要目标编码';
      Exit;
    end;
  end;
  
  if Length(Options.SourceFiles) = 0 then
  begin
    if Options.TestDirectory = '' then
    begin
      if (Options.TestMode <> tmAll) and (Options.TestMode <> tmDetection) then
      begin
        Options.InvalidArgs := True;
        Options.ErrorMessage := '需要指定源文件或测试目录';
        Exit;
      end;
    end;
  end;
end;

procedure TCommandLineOptions.Init;
begin
  TestMode := tmDetection;
  SetLength(SourceFiles, 0);
  SourceEncoding := '';
  TargetEncoding := '';
  TestDirectory := '';
  Recursive := False;
  Verbose := False;
  OutputFile := '';
  HelpRequested := False;
  InvalidArgs := False;
  ErrorMessage := '';
end;

constructor TTestRunner.Create(const Options: TCommandLineOptions);
begin
  inherited Create;
  FOptions := Options;
  FOutputLog := TStringList.Create;
end;

destructor TTestRunner.Destroy;
begin
  FOutputLog.Free;
  inherited;
end;

procedure TTestRunner.LogInfo(const Msg: string);
begin
  WriteLn(Msg);
  FOutputLog.Add('[INFO] ' + Msg);
end;

procedure TTestRunner.LogError(const Msg: string);
begin
  WriteLn('错误: ' + Msg);
  FOutputLog.Add('[ERROR] ' + Msg);
end;

procedure TTestRunner.LogSuccess(const Msg: string);
begin
  WriteLn('成功: ' + Msg);
  FOutputLog.Add('[SUCCESS] ' + Msg);
end;

procedure TTestRunner.LogWarning(const Msg: string);
begin
  WriteLn('警告: ' + Msg);
  FOutputLog.Add('[WARNING] ' + Msg);
end;

function TTestRunner.CollectTestFiles: TArray<string>;
var
  Files: TStringList;
  SearchOption: TSearchOption;
  FileMask: string;
  
  procedure CollectFilesFromDirectory(const Directory: string);
  var
    FileList: TStringDynArray;
    File: string;
  begin
    try
      FileList := TDirectory.GetFiles(Directory, FileMask, SearchOption);
      for File in FileList do
        Files.Add(File);
    except
      on E: Exception do
        LogError('读取目录失败: ' + Directory + ', 错误: ' + E.Message);
    end;
  end;
  
begin
  Files := TStringList.Create;
  try
    if Length(FOptions.SourceFiles) > 0 then
    begin
      for var SourceFile in FOptions.SourceFiles do
        if FileExists(SourceFile) then
          Files.Add(SourceFile)
        else
          LogError('文件不存在: ' + SourceFile);
    end;
    
    if FOptions.TestDirectory <> '' then
    begin
      if FOptions.Recursive then
        SearchOption := TSearchOption.soAllDirectories
      else
        SearchOption := TSearchOption.soTopDirectoryOnly;
      
      FileMask := '*.*';
      
      if DirectoryExists(FOptions.TestDirectory) then
        CollectFilesFromDirectory(FOptions.TestDirectory)
      else
        LogError('目录不存在: ' + FOptions.TestDirectory);
    end;
    
    // 排序文件列表，使结果更稳定
    Files.Sort;
    
    // 转换为数组
    SetLength(Result, Files.Count);
    for var I := 0 to Files.Count - 1 do
      Result[I] := Files[I];
  finally
    Files.Free;
  end;
end;

function TTestRunner.DetectFileEncoding(const FileName: string): string;
var
  Detector: TEncodingDetector2;
  Result2: TEncodingDetectionResult;
begin
  Detector := TEncodingDetector2.Create;
  try
    Result2 := Detector.DetectFileEncoding(FileName);
    Result := Result2.Encoding;
    
    if FOptions.Verbose then
      LogInfo(Format('文件 %s 检测编码: %s (置信度: %.2f, 有BOM: %s)',
        [ExtractFileName(FileName), Result2.Encoding, 
         Result2.Confidence, BoolToStr(Result2.HasBOM, True)]));
  finally
    Detector.Free;
  end;
end;

function TTestRunner.ConvertFileEncoding(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): Boolean;
var
  SourceBuffer, TargetBuffer: TBytes;
  SourceText: string;
  Success: Boolean;
  TargetCP: Integer;
  BOM: TBytes;
begin
  Result := False;
  
  if not FileExists(SourceFile) then
  begin
    LogError('源文件不存在: ' + SourceFile);
    Exit;
  end;
  
  try
    // 读取源文件
    SourceBuffer := TFile.ReadAllBytes(SourceFile);
    
    // 处理UTF-8 BOM
    if (SourceEncoding = ENCODING_UTF8_BOM) or (SourceEncoding = 'utf-8-bom') then
    begin
      if (Length(SourceBuffer) >= 3) and (SourceBuffer[0] = $EF) and (SourceBuffer[1] = $BB) and (SourceBuffer[2] = $BF) then
        SourceText := TEncoding.UTF8.GetString(SourceBuffer, 3, Length(SourceBuffer) - 3)
      else
        SourceText := TEncoding.UTF8.GetString(SourceBuffer);
    end
    else if (SourceEncoding = ENCODING_UTF8) or (SourceEncoding = 'utf-8') then
    begin
      SourceText := TEncoding.UTF8.GetString(SourceBuffer);
    end
    else if (SourceEncoding = ENCODING_UTF16_LE) or (SourceEncoding = 'utf-16le') then
    begin
      if (Length(SourceBuffer) >= 2) and (SourceBuffer[0] = $FF) and (SourceBuffer[1] = $FE) then
        SourceText := TEncoding.Unicode.GetString(SourceBuffer, 2, Length(SourceBuffer) - 2)
      else
        SourceText := TEncoding.Unicode.GetString(SourceBuffer);
    end
    else if (SourceEncoding = ENCODING_UTF16_BE) or (SourceEncoding = 'utf-16be') then
    begin
      if (Length(SourceBuffer) >= 2) and (SourceBuffer[0] = $FE) and (SourceBuffer[1] = $FF) then
        SourceText := TEncoding.BigEndianUnicode.GetString(SourceBuffer, 2, Length(SourceBuffer) - 2)
      else
        SourceText := TEncoding.BigEndianUnicode.GetString(SourceBuffer);
    end
    else if (SourceEncoding = ENCODING_GB18030) or (SourceEncoding = 'gb18030') or
            (SourceEncoding = ENCODING_GBK) or (SourceEncoding = 'gbk') then
    begin
      TargetCP := 936; // GBK/GB18030
      var WideLen := MultiByteToWideChar(TargetCP, 0, @SourceBuffer[0], Length(SourceBuffer), nil, 0);
      SetLength(SourceText, WideLen);
      MultiByteToWideChar(TargetCP, 0, @SourceBuffer[0], Length(SourceBuffer), PWideChar(SourceText), WideLen);
    end
    else if (SourceEncoding = ENCODING_BIG5) or (SourceEncoding = 'big5') then
    begin
      TargetCP := 950; // Big5
      var WideLen := MultiByteToWideChar(TargetCP, 0, @SourceBuffer[0], Length(SourceBuffer), nil, 0);
      SetLength(SourceText, WideLen);
      MultiByteToWideChar(TargetCP, 0, @SourceBuffer[0], Length(SourceBuffer), PWideChar(SourceText), WideLen);
    end
    else
    begin
      SourceText := TEncoding.Default.GetString(SourceBuffer);
    end;
    
    // 转换为目标编码
    if (TargetEncoding = ENCODING_UTF8) or (TargetEncoding = 'utf-8') then
    begin
      TargetBuffer := TEncoding.UTF8.GetBytes(SourceText);
    end
    else if (TargetEncoding = ENCODING_UTF8_BOM) or (TargetEncoding = 'utf-8-bom') then
    begin
      var TempBuffer := TEncoding.UTF8.GetBytes(SourceText);
      SetLength(BOM, 3);
      BOM[0] := $EF;
      BOM[1] := $BB;
      BOM[2] := $BF;
      
      SetLength(TargetBuffer, Length(TempBuffer) + 3);
      Move(BOM[0], TargetBuffer[0], 3);
      if Length(TempBuffer) > 0 then
        Move(TempBuffer[0], TargetBuffer[3], Length(TempBuffer));
    end
    else if (TargetEncoding = ENCODING_UTF16_LE) or (TargetEncoding = 'utf-16le') then
    begin
      TargetBuffer := TEncoding.Unicode.GetBytes(SourceText);
      
      // 添加BOM
      SetLength(BOM, 2);
      BOM[0] := $FF;
      BOM[1] := $FE;
      
      var TempBuffer := TargetBuffer;
      SetLength(TargetBuffer, Length(TempBuffer) + 2);
      Move(BOM[0], TargetBuffer[0], 2);
      Move(TempBuffer[0], TargetBuffer[2], Length(TempBuffer));
    end
    else if (TargetEncoding = ENCODING_UTF16_BE) or (TargetEncoding = 'utf-16be') then
    begin
      TargetBuffer := TEncoding.BigEndianUnicode.GetBytes(SourceText);
      
      // 添加BOM
      SetLength(BOM, 2);
      BOM[0] := $FE;
      BOM[1] := $FF;
      
      var TempBuffer := TargetBuffer;
      SetLength(TargetBuffer, Length(TempBuffer) + 2);
      Move(BOM[0], TargetBuffer[0], 2);
      Move(TempBuffer[0], TargetBuffer[2], Length(TempBuffer));
    end
    else if (TargetEncoding = ENCODING_GB18030) or (TargetEncoding = 'gb18030') or
            (TargetEncoding = ENCODING_GBK) or (TargetEncoding = 'gbk') then
    begin
      TargetCP := 936; // GBK/GB18030
      var ByteLen := WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), nil, 0, nil, nil);
      SetLength(TargetBuffer, ByteLen);
      WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), @TargetBuffer[0], ByteLen, nil, nil);
    end
    else if (TargetEncoding = ENCODING_BIG5) or (TargetEncoding = 'big5') then
    begin
      TargetCP := 950; // Big5
      var ByteLen := WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), nil, 0, nil, nil);
      SetLength(TargetBuffer, ByteLen);
      WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), Length(SourceText), @TargetBuffer[0], ByteLen, nil, nil);
    end
    else
    begin
      TargetBuffer := TEncoding.Default.GetBytes(SourceText);
    end;
    
    // 写入目标文件
    TFile.WriteAllBytes(TargetFile, TargetBuffer);
    
    Result := True;
    
    if FOptions.Verbose then
      LogInfo(Format('转换文件 %s 从 %s 到 %s 成功',
        [ExtractFileName(SourceFile), SourceEncoding, TargetEncoding]));
  except
    on E: Exception do
    begin
      LogError(Format('转换文件 %s 失败: %s', [ExtractFileName(SourceFile), E.Message]));
      Result := False;
    end;
  end;
end;

function TTestRunner.ValidateRoundTrip(const SourceFile: string; SourceEncoding, IntermediateEncoding: string): Boolean;
var
  Validator: TRoundTripValidator;
  ValidationResult: TRoundTripValidationResult;
begin
  Result := False;
  
  if not FileExists(SourceFile) then
  begin
    LogError('源文件不存在: ' + SourceFile);
    Exit;
  end;
  
  Validator := TRoundTripValidator.Create;
  try
    ValidationResult := Validator.ValidateRoundTrip(SourceFile, SourceEncoding, IntermediateEncoding);
    
    Result := ValidationResult.Success;
    
    if Result then
      LogSuccess(Format('往返验证 %s (%s -> %s -> %s) 成功',
        [ExtractFileName(SourceFile), SourceEncoding, IntermediateEncoding, SourceEncoding]))
    else
      LogError(Format('往返验证 %s (%s -> %s -> %s) 失败: %s',
        [ExtractFileName(SourceFile), SourceEncoding, IntermediateEncoding, SourceEncoding, 
         ValidationResult.ErrorMessage]));
    
    if FOptions.Verbose then
      LogInfo(ValidationResult.DetailedMessage);
  finally
    Validator.Free;
  end;
end;

function TTestRunner.ValidateSpecialChars(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): Boolean;
var
  Validator: TSpecialCharValidator;
  ValidationResult: TSpecialCharValidationResult;
begin
  Result := False;
  
  if not FileExists(SourceFile) then
  begin
    LogError('源文件不存在: ' + SourceFile);
    Exit;
  end;
  
  if not FileExists(TargetFile) then
  begin
    LogError('目标文件不存在: ' + TargetFile);
    Exit;
  end;
  
  Validator := TSpecialCharValidator.Create;
  try
    ValidationResult := Validator.ValidateSpecialChars(SourceFile, TargetFile, SourceEncoding, TargetEncoding);
    
    Result := ValidationResult.Success;
    
    if Result then
      LogSuccess(Format('特殊字符验证 %s -> %s (%s -> %s) 成功',
        [ExtractFileName(SourceFile), ExtractFileName(TargetFile), SourceEncoding, TargetEncoding]))
    else
      LogError(Format('特殊字符验证 %s -> %s (%s -> %s) 失败: %d 个字符不匹配',
        [ExtractFileName(SourceFile), ExtractFileName(TargetFile), SourceEncoding, TargetEncoding, 
         ValidationResult.MismatchedChars]));
    
    if FOptions.Verbose then
      LogInfo(ValidationResult.DetailedMessage);
  finally
    Validator.Free;
  end;
end;

procedure TTestRunner.RunDetectionTests;
var
  Files: TArray<string>;
  File: string;
  Encoding: string;
  TotalFiles, SuccessCount: Integer;
begin
  LogInfo('开始编码检测测试...');
  
  Files := CollectTestFiles;
  TotalFiles := Length(Files);
  SuccessCount := 0;
  
  if TotalFiles = 0 then
  begin
    LogWarning('没有找到测试文件');
    Exit;
  end;
  
  LogInfo(Format('找到 %d 个测试文件', [TotalFiles]));
  
  for File in Files do
  begin
    Encoding := DetectFileEncoding(File);
    
    if Encoding <> ENCODING_UNKNOWN then
      Inc(SuccessCount);
    
    LogInfo(Format('文件: %s, 检测编码: %s', [ExtractFileName(File), Encoding]));
  end;
  
  LogInfo(Format('编码检测测试完成: %d/%d (%.1f%%) 成功',
    [SuccessCount, TotalFiles, (SuccessCount / TotalFiles) * 100]));
end;

procedure TTestRunner.RunConversionTests;
var
  Files: TArray<string>;
  File, TargetFile: string;
  TotalFiles, SuccessCount: Integer;
begin
  LogInfo('开始编码转换测试...');
  
  Files := CollectTestFiles;
  TotalFiles := Length(Files);
  SuccessCount := 0;
  
  if TotalFiles = 0 then
  begin
    LogWarning('没有找到测试文件');
    Exit;
  end;
  
  LogInfo(Format('找到 %d 个测试文件', [TotalFiles]));
  
  for File in Files do
  begin
    TargetFile := ChangeFileExt(File, '.converted' + ExtractFileExt(File));
    
    if ConvertFileEncoding(File, TargetFile, FOptions.SourceEncoding, FOptions.TargetEncoding) then
    begin
      Inc(SuccessCount);
      LogSuccess(Format('转换成功: %s -> %s', [ExtractFileName(File), ExtractFileName(TargetFile)]));
    end
    else
    begin
      LogError(Format('转换失败: %s', [ExtractFileName(File)]));
    end;
  end;
  
  LogInfo(Format('编码转换测试完成: %d/%d (%.1f%%) 成功',
    [SuccessCount, TotalFiles, (SuccessCount / TotalFiles) * 100]));
end;

procedure TTestRunner.RunRoundTripTests;
var
  Files: TArray<string>;
  File: string;
  TotalFiles, SuccessCount: Integer;
begin
  LogInfo('开始往返转换测试...');
  
  Files := CollectTestFiles;
  TotalFiles := Length(Files);
  SuccessCount := 0;
  
  if TotalFiles = 0 then
  begin
    LogWarning('没有找到测试文件');
    Exit;
  end;
  
  LogInfo(Format('找到 %d 个测试文件', [TotalFiles]));
  
  for File in Files do
  begin
    if ValidateRoundTrip(File, FOptions.SourceEncoding, FOptions.TargetEncoding) then
      Inc(SuccessCount);
  end;
  
  LogInfo(Format('往返转换测试完成: %d/%d (%.1f%%) 成功',
    [SuccessCount, TotalFiles, (SuccessCount / TotalFiles) * 100]));
end;

procedure TTestRunner.RunSpecialCharsTests;
var
  Files: TArray<string>;
  File, TargetFile: string;
  TotalFiles, SuccessCount: Integer;
begin
  LogInfo('开始特殊字符验证测试...');
  
  Files := CollectTestFiles;
  TotalFiles := Length(Files);
  SuccessCount := 0;
  
  if TotalFiles = 0 then
  begin
    LogWarning('没有找到测试文件');
    Exit;
  end;
  
  LogInfo(Format('找到 %d 个测试文件', [TotalFiles]));
  
  for File in Files do
  begin
    TargetFile := ChangeFileExt(File, '.converted' + ExtractFileExt(File));
    
    // 先转换文件
    if ConvertFileEncoding(File, TargetFile, FOptions.SourceEncoding, FOptions.TargetEncoding) then
    begin
      // 然后验证特殊字符
      if ValidateSpecialChars(File, TargetFile, FOptions.SourceEncoding, FOptions.TargetEncoding) then
        Inc(SuccessCount);
    end
    else
    begin
      LogError(Format('转换失败，无法验证特殊字符: %s', [ExtractFileName(File)]));
    end;
  end;
  
  LogInfo(Format('特殊字符验证测试完成: %d/%d (%.1f%%) 成功',
    [SuccessCount, TotalFiles, (SuccessCount / TotalFiles) * 100]));
end;

procedure TTestRunner.RunAllTests;
begin
  LogInfo('开始所有测试...');
  
  RunDetectionTests;
  
  if (FOptions.SourceEncoding <> '') and (FOptions.TargetEncoding <> '') then
  begin
    RunConversionTests;
    RunRoundTripTests;
    RunSpecialCharsTests;
  end
  else
  begin
    LogWarning('跳过转换相关测试，因为未指定源编码和目标编码');
  end;
  
  LogInfo('所有测试完成');
end;

procedure TTestRunner.SaveTestResults;
begin
  if FOptions.OutputFile <> '' then
  begin
    try
      FOutputLog.SaveToFile(FOptions.OutputFile);
      LogInfo('测试结果已保存到: ' + FOptions.OutputFile);
    except
      on E: Exception do
        LogError('保存测试结果失败: ' + E.Message);
    end;
  end;
end;

procedure TTestRunner.Run;
begin
  try
    case FOptions.TestMode of
      tmDetection:    RunDetectionTests;
      tmConversion:   RunConversionTests;
      tmRoundTrip:    RunRoundTripTests;
      tmSpecialChars: RunSpecialCharsTests;
      tmAll:          RunAllTests;
    end;
    
    SaveTestResults;
  except
    on E: Exception do
      LogError('测试过程中发生错误: ' + E.Message);
  end;
end;

var
  Options: TCommandLineOptions;
  TestRunner: TTestRunner;

begin
  try
    ParseCommandLine(Options);
    
    if Options.HelpRequested then
    begin
      PrintUsage;
      Exit;
    end;
    
    if Options.InvalidArgs then
    begin
      WriteLn('错误: ' + Options.ErrorMessage);
      WriteLn;
      PrintUsage;
      Exit;
    end;
    
    TestRunner := TTestRunner.Create(Options);
    try
      TestRunner.Run;
    finally
      TestRunner.Free;
    end;
  except
    on E: Exception do
      WriteLn('错误: ' + E.Message);
  end;
end. 