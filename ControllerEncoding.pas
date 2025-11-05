unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, System.TypInfo, System.DateUtils,
  ModelEncoding, Winapi.Windows, HelperFiles, UtilsEncodingTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, JapaneseEncodingDetector_Improved, KoreanEncodingDetector_Improved,
  UTF8BOMConverter_Improved, EncodingConverter_Improved;

type
  TEncodingConversionResultType = (crSuccess, crFailed, crSkipped);

  // 编码控制器类
  TEncodingController = class
  private
    // 日志记录回调
    FLogCallback: TProc<string>;

    // 临时文件路径
    FTempPath: string;

    // 文件助手
    FFileHelper: TFileHelper;

    // 记录日志
    procedure Log(const Msg: string);

    // 获取临时文件路径
    function GetTempFilePath: string;

    // 检查文件是否可以访问
    function IsFileAccessible(const FileName: string): Boolean;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;

    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;

    // 转换单个文件
    function ConvertSingleFile(const FileName, TargetEncoding: string; WithBOM: Boolean;
      OnSuccess: TProc<string> = nil): Boolean;

    // 批量转换文件
    procedure ConvertFiles(const FileNames: TArray<string>; const TargetEncoding: string;
      WithBOM: Boolean; OnSuccess: TProc<string> = nil);
  end;

implementation

const
  // 不支持的文件列表
  UNSUPPORTED_FILES: array[0..5] of string = (
    'desktop.ini', 'thumbs.db', 'ntuser.dat', 'pagefile.sys', 'hiberfil.sys', 'swapfile.sys'
  );

{ TEncodingController }

constructor TEncodingController.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FTempPath := TPath.GetTempPath;

  // 创建文件助手
  FFileHelper := TFileHelper.Create(ALogCallback);

  // 记录日志
  Log(string('编码控制器已初始化'));
end;

destructor TEncodingController.Destroy;
begin
  // 释放文件助手
  if Assigned(FFileHelper) then
    FFileHelper.Free;

  inherited;
end;

procedure TEncodingController.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingController.GetTempFilePath: string;
begin
  Result := TPath.Combine(FTempPath, 'TransSuccess_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.tmp');
end;

function TEncodingController.IsFileAccessible(const FileName: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;

  try
    // 尝试以只读方式打开文件
    FileHandle := FileOpen(FileName, fmOpenRead or fmShareDenyNone);
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      FileClose(FileHandle);
      Result := True;
    end;
  except
    // 如果发生异常，文件不可访问
    Result := False;
  end;
end;

function TEncodingController.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  JapaneseResult: TJapaneseEncodingResult;
  KoreanResult: TKoreanEncodingResult;
  FileStream: TFileStream;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  FileExt: string;
  StartTime: TDateTime;
  ElapsedTime: Int64;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
begin
  // 使用FileHelper的检测函数，它更全面
  if Assigned(FFileHelper) then
  begin
    Result := FFileHelper.DetectFileEncoding(FileName, HasBOM);
    Log(Format('使用FileHelper检测到文件 %s 的编码为: %s (BOM: %s)',
      [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
    Exit;
  end;

  // 如果FileHelper不可用，使用改进版的检测逻辑
  Log(Format('使用改进版检测算法检测文件编码: %s', [FileName]));

  // 获取文件扩展名
  FileExt := LowerCase(ExtractFileExt(FileName));
  Log(Format('文件扩展名: %s', [FileExt]));

  // 初始化检测器（这些类都是静态类，不需要创建实例）

  try
    // 记录开始时间
    StartTime := Now;

    // 首先检查文件是否存在
    if not FileExists(FileName) then
    begin
      Log(Format('文件不存在: %s', [FileName]));
      Result := 'Unknown';
      HasBOM := False;
      Exit;
    end;

    // 读取文件内容
    try
      FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      try
        // 读取文件内容（最多读取前4MB）
        SetLength(Buffer, Min(FileStream.Size, 4 * 1024 * 1024));
        if Length(Buffer) > 0 then
          FileStream.ReadBuffer(Buffer[0], Length(Buffer));
      finally
        FileStream.Free;
      end;
    except
      on E: Exception do
      begin
        Log(Format('读取文件失败: %s - %s', [FileName, E.Message]));
        Result := 'ANSI';
        HasBOM := False;
        Exit;
      end;
    end;

    // 首先检测BOM
    BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
    if BOMResult.BOMType <> 0 then
    begin
      // 有BOM，直接返回结果
      Result := BOMResult.Encoding;
      HasBOM := True;

      // 记录详细日志
      ElapsedTime := MilliSecondsBetween(StartTime, Now);
      Log(Format('BOM检测成功: %s, 耗时: %d ms',
        [Result, ElapsedTime]));
    end
    else
    begin
      // 没有BOM，尝试检测UTF-8
      UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);
      if UTF8Result.IsUTF8 then
      begin
        // 是UTF-8
        Result := 'UTF-8';
        HasBOM := False;

        // 记录详细日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        Log(Format('UTF-8检测成功: 置信度: %.2f, 有效字节: %d, 无效字节: %d, 耗时: %d ms',
          [UTF8Result.Confidence, UTF8Result.ValidByteCount,
           UTF8Result.InvalidByteCount, ElapsedTime]));
      end
      else
      begin
        // 不是中文编码，尝试检测日文编码
        JapaneseResult := TJapaneseEncodingDetector_Improved.DetectBuffer(Buffer);

        if (JapaneseResult.Confidence >= 0.75) and (JapaneseResult.Encoding <> ENCODING_ANSI) and (JapaneseResult.Encoding <> ENCODING_UNKNOWN) then
        begin
          // 是日文编码
          Result := JapaneseResult.Encoding;
          HasBOM := JapaneseResult.HasBOM;

          // 记录详细日志
          ElapsedTime := MilliSecondsBetween(Now, StartTime);
          Log(Format('日文编码检测成功: %s, 置信度: %.2f, 耗时: %d ms',
            [Result, JapaneseResult.Confidence, ElapsedTime]));
        end
        else
        begin
          // 不是日文编码，尝试检测韩文编码
          KoreanResult := TKoreanEncodingDetector_Improved.DetectBuffer(Buffer);

          if (KoreanResult.Confidence >= 0.75) and (KoreanResult.Encoding <> ENCODING_ANSI) and (KoreanResult.Encoding <> ENCODING_UNKNOWN) then
          begin
            // 是韩文编码
            Result := KoreanResult.Encoding;
            HasBOM := KoreanResult.HasBOM;

            // 记录详细日志
            ElapsedTime := MilliSecondsBetween(Now, StartTime);
            Log(Format('韩文编码检测成功: %s, 置信度: %.2f, 耗时: %d ms',
              [Result, KoreanResult.Confidence, ElapsedTime]));
          end
          else
          begin
            // 不是韩文编码，使用默认编码
            Result := 'ANSI';
            HasBOM := False;

            // 记录详细日志
            ElapsedTime := MilliSecondsBetween(Now, StartTime);
            Log(Format('未能确定编码，使用默认编码: %s, 耗时: %d ms',
              [Result, ElapsedTime]));
          end;
        end;
      end;
    end;

    // 记录最终结果
    Log(Format('检测到文件 %s 的编码为: %s (BOM: %s)',
      [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
  except
    on E: Exception do
    begin
      // 如果检测失败，使用默认值
      Result := 'ANSI';
      HasBOM := False;

      // 记录错误
      Log(Format('检测文件编码失败: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

function TEncodingController.IsUnsupportedFile(const Filename: string): Boolean;
var
  BaseName: string;
  i: Integer;
begin
  BaseName := ExtractFileName(Filename);
  Result := False;

  for i := Low(UNSUPPORTED_FILES) to High(UNSUPPORTED_FILES) do
  begin
    if SameText(BaseName, UNSUPPORTED_FILES[i]) then
    begin
      Result := True;
      Log(Format(string('文件 %s 在不支持列表中，跳过处理'), [BaseName]));
      Break;
    end;
  end;
end;

function TEncodingController.ConvertSingleFile(const FileName, TargetEncoding: string;
  WithBOM: Boolean; OnSuccess: TProc<string> = nil): Boolean;
var
  SourceEncodingName: string;
  HasBOM: Boolean;
  Options: TEncodingConversionOptions;
  ConversionResult: TEncodingConversionResult;
  FinalTargetEncoding: string;
begin
  Result := False;

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    Log(Format('文件不存在: %s', [FileName]));
    Exit;
  end;

  // 检查文件是否在不支持列表中
  if IsUnsupportedFile(FileName) then
    Exit;

  // 检测源文件编码
  SourceEncodingName := DetectFileEncoding(FileName, HasBOM);

  // 确定最终目标编码
  if SameText(TargetEncoding, 'UTF-8') and WithBOM then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF-8 with BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF-8-BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF8-BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF8BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else
    FinalTargetEncoding := TargetEncoding;

  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := WithBOM;
  Options.DetectSourceEncoding := False; // 我们已经检测过了

  // 记录转换信息
  Log(Format('准备转换: 从 %s 到 %s (BOM: %s)',
    [SourceEncodingName, FinalTargetEncoding, BoolToStr(WithBOM, True)]));

  try
    // 执行转换
    ConversionResult := TEncodingConverter_Improved.ConvertFile(
      FileName, FileName, SourceEncodingName, FinalTargetEncoding, Options);

    // 检查结果
    if ConversionResult.Success then
    begin
      Result := True;
      Log(Format('成功将文件 %s 从 %s 转换为 %s',
        [ExtractFileName(FileName), SourceEncodingName, FinalTargetEncoding]));

      // 调用成功回调
      if Assigned(OnSuccess) then
        OnSuccess(FileName);
    end
    else
    begin
      Result := False;
      Log(Format('转换文件 %s 失败，错误数: %d',
        [ExtractFileName(FileName), ConversionResult.ErrorCount]));

      // 记录详细错误信息
      for var i := 0 to ConversionResult.ErrorCount - 1 do
        Log(Format('  错误 #%d: %s (位置: %d)',
          [i+1, ConversionResult.Errors[i].ErrorMessage, ConversionResult.Errors[i].Position]));
    end;
  except
    on E: Exception do
    begin
      Result := False;
      Log(Format('转换文件时发生异常: %s - %s',
        [ExtractFileName(FileName), E.Message]));
    end;
  end;
end;

procedure TEncodingController.ConvertFiles(const FileNames: TArray<string>;
  const TargetEncoding: string; WithBOM: Boolean; OnSuccess: TProc<string> = nil);
var
  i, SuccessCount, FailCount, TotalCount: Integer;
  ProgressInterval, LastProgressReport: Integer;
  StartTime, EndTime: TDateTime;
  ElapsedSeconds: Double;
begin
  SuccessCount := 0;
  FailCount := 0;
  TotalCount := Length(FileNames);
  StartTime := Now;

  // 设置进度报告间隔，每5%或至少每10个文件报告一次进度
  ProgressInterval := Max(1, Min(TotalCount div 20, 10));
  LastProgressReport := 0;

  Log(Format('开始批量转换 %d 个文件到 %s (BOM: %s)...',
    [TotalCount, TargetEncoding, BoolToStr(WithBOM, True)]));

  for i := 0 to High(FileNames) do
  begin
    // 转换单个文件
    if ConvertSingleFile(FileNames[i], TargetEncoding, WithBOM, OnSuccess) then
      Inc(SuccessCount)
    else
      Inc(FailCount);

    // 报告进度
    if (i + 1 - LastProgressReport >= ProgressInterval) or (i = High(FileNames)) then
    begin
      LastProgressReport := i + 1;
      Log(Format('进度: %d/%d (%.1f%%) - 成功: %d, 失败: %d',
        [i + 1, TotalCount, (i + 1) / TotalCount * 100, SuccessCount, FailCount]));
    end;
  end;

  // 计算总耗时
  EndTime := Now;
  ElapsedSeconds := (EndTime - StartTime) * 86400; // 转换为秒

  // 输出详细的完成报告
  Log('');
  Log(Format('批量转换完成: 成功 %d/%d 个文件', [SuccessCount, TotalCount]));
  Log(Format('- 总文件数: %d', [TotalCount]));
  Log(Format('- 成功转换: %d (%.1f%%)', [SuccessCount, SuccessCount / TotalCount * 100]));
  Log(Format('- 转换失败: %d (%.1f%%)', [FailCount, FailCount / TotalCount * 100]));
  Log(Format('- 总耗时: %.2f秒 (平均每文件 %.2f毫秒)',
    [ElapsedSeconds, ElapsedSeconds * 1000 / TotalCount]));

  // 如果有失败的文件，建议用户查看日志
  if FailCount > 0 then
    Log('请查看上方日志了解失败详情');
end;

end.
