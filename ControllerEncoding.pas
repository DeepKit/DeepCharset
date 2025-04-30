unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, System.TypInfo, ModelEncoding,
  Winapi.Windows, UtilsEncodingBOM_Simple, UTF8BOMConverter_Simple, JclBOM, JclEncodingUtils,
  HelperFiles;

type
  TEncodingConversionResult = (crSuccess, crFailed, crSkipped);

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
  FileStream: TFileStream;
  BOMType: TJclBOMType;
  FileExt: string;
  IsUTF8: Boolean;
begin
  // 使用FileHelper的检测函数，它更全面
  if Assigned(FFileHelper) then
  begin
    Result := FFileHelper.DetectFileEncoding(FileName, HasBOM);
    Log(Format('使用FileHelper检测到文件 %s 的编码为: %s (BOM: %s)',
      [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
    Exit;
  end;

  // 如果FileHelper不可用，使用自己的检测逻辑
  Log(Format('FileHelper不可用，使用内部逻辑检测文件编码: %s', [FileName]));

  // 获取文件扩展名
  FileExt := LowerCase(ExtractFileExt(FileName));
  Log(Format('文件扩展名: %s', [FileExt]));

  try
    // 首先检查是否有BOM
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      BOMType := JclBOM.DetectBOM(FileStream);
      HasBOM := BOMType <> JclBOM.bomAnsi;

      Log(Format('BOM检测结果: %s', [GetEnumName(TypeInfo(TJclBOMType), Ord(BOMType))]));

      // 根据BOM确定编码
      case BOMType of
        bomUTF8: Result := 'UTF-8 with BOM';
        bomUTF16LE: Result := 'UTF-16LE';
        bomUTF16BE: Result := 'UTF-16BE';
        bomUTF32LE: Result := 'UTF-32LE';
        bomUTF32BE: Result := 'UTF-32BE';
        else
          // 对于特定的文本文件类型，优先考虑UTF-8
          if (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.json') or
             (FileExt = '.xml') or (FileExt = '.html') or (FileExt = '.htm') or
             (FileExt = '.css') or (FileExt = '.js') or (FileExt = '.ts') or
             (FileExt = '.yaml') or (FileExt = '.yml') then
          begin
            // 使用改进的UTF-8检测器
            Log('文件类型适合UTF-8，使用改进的UTF-8检测器');

            IsUTF8 := UTF8BOMConverter_Simple.TUTF8BOMConverter.IsUTF8File(FileName, HasBOM);

            Log(Format('UTF-8检测结果: %s', [BoolToStr(IsUTF8, True)]));

            if IsUTF8 then
              Result := 'UTF-8'
            else
              // 如果不是UTF-8，使用JCL的检测函数
              Result := JclEncodingUtils.DetectFileEncoding(FileName);
          end
          else
          begin
            // 对于其他类型的文件，先使用JCL的检测函数
            Log('使用JCL编码检测函数');

            Result := JclEncodingUtils.DetectFileEncoding(FileName);

            // 如果JCL检测为ANSI，再尝试使用UTF-8检测器
            if (Result = 'ANSI') or (Result = '') then
            begin
              Log('JCL检测为ANSI，尝试使用UTF-8检测器');

              IsUTF8 := UTF8BOMConverter_Simple.TUTF8BOMConverter.IsUTF8File(FileName, HasBOM);

              Log(Format('UTF-8检测结果: %s', [BoolToStr(IsUTF8, True)]));

              if IsUTF8 then
                Result := 'UTF-8';
            end;
          end;
      end;

      // 记录详细日志
      Log(Format('检测到文件 %s 的编码为: %s (BOM: %s)',
        [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
    finally
      FileStream.Free;
    end;
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
  TempFile: string;
  IsUTF8BOMTarget: Boolean;
  UTF8Converter: TUTF8BOMConverter;
begin
  Result := False;

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    Log(Format(string('文件不存在: %s'), [FileName]));
    Exit;
  end;

  // 检查文件是否可访问
  if not IsFileAccessible(FileName) then
  begin
    Log(Format(string('文件无法访问: %s'), [FileName]));
    Exit;
  end;

  // 检查文件是否在不支持列表中
  if IsUnsupportedFile(FileName) then
    Exit;

  // 检测源文件编码
  SourceEncodingName := DetectFileEncoding(FileName, HasBOM);

  // 创建临时文件路径
  TempFile := GetTempFilePath;

  // 检查UTF-8 BOM目标 - 改进识别逻辑
  IsUTF8BOMTarget := (SameText(TargetEncoding, 'UTF-8 with BOM') or
                      SameText(TargetEncoding, 'UTF-8-BOM') or
                      SameText(TargetEncoding, 'UTF8-BOM') or
                      (SameText(TargetEncoding, 'UTF-8') and WithBOM));

  // 输出详细调试信息
  Log(Format(string('目标是否UTF-8+BOM: %s, 目标编码: %s, WithBOM: %s'),
    [BoolToStr(IsUTF8BOMTarget, True), TargetEncoding, BoolToStr(WithBOM, True)]));

  // 详细日志：源和目标编码信息
  var BOMText := '';
  if IsUTF8BOMTarget then
    BOMText := ' (带BOM)'
  else if WithBOM then
    BOMText := ' (带BOM)';

  // 确保日志使用UTF-8编码
  Log(Format(string('准备转换: 从 %s 到 %s%s'),
    [SourceEncodingName, TargetEncoding, BOMText]));

  try
    // 特殊处理UTF-8相关的转换
    if IsUTF8BOMTarget then
    begin
      // 使用UTF8BOMConverter进行转换
      Log(string('使用UTF8BOMConverter进行UTF-8 BOM转换...'));

      // 如果源文件已经是UTF-8（无论有无BOM），直接添加BOM
      if SameText(SourceEncodingName, 'UTF-8') or SameText(SourceEncodingName, 'UTF-8 with BOM') then
      begin
        var ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.ConvertToUTF8WithBOM(FileName);
        Result := ConvResult.Success;

        if Result then
          Log(string('成功将UTF-8文件转换为UTF-8+BOM'))
        else
          Log(string('将UTF-8文件转换为UTF-8+BOM失败: ') + ConvResult.ErrorMessage);
      end
      else
      begin
        // 其他编码转换为UTF-8+BOM
        var ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.ConvertToUTF8WithBOM(FileName);
        Result := ConvResult.Success;

        if Result then
          Log(Format(string('成功将%s文件转换为UTF-8+BOM'), [SourceEncodingName]))
        else
          Log(Format(string('将%s文件转换为UTF-8+BOM失败: %s'), [SourceEncodingName, ConvResult.ErrorMessage]));
      end;
    end
    else if SameText(TargetEncoding, 'UTF-8') and not WithBOM then
    begin
      // 转换为不带BOM的UTF-8
      Log(string('使用UTF8BOMConverter进行UTF-8无BOM转换...'));

      try
        // 特别处理从UTF-8+BOM到UTF-8无BOM的转换
        if SameText(SourceEncodingName, 'UTF-8 with BOM') then
        begin
          Log(string('从UTF-8+BOM转换为UTF-8无BOM，使用专用方法...'));

          // 确保文件存在且可访问
          if not FileExists(FileName) then
          begin
            Log(string('文件不存在，无法转换: ') + FileName);
            Result := False;
            Exit;
          end;

          // 检查文件是否可写
          try
            var FileAttr := FileGetAttr(FileName);
            if (FileAttr and faReadOnly) <> 0 then
            begin
              Log(string('文件为只读，无法修改: ') + FileName);
              Result := False;
              Exit;
            end;
          except
            on E: Exception do
            begin
              Log(string('检查文件属性失败: ') + E.Message);
              Result := False;
              Exit;
            end;
          end;

          // 使用专用方法移除BOM
          var ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.RemoveUTF8BOM(FileName);
          Result := ConvResult.Success;

          if Result then
          begin
            Log(string('成功将UTF-8+BOM文件转换为UTF-8无BOM'));

            // 验证转换结果
            var NewHasBOM: Boolean;
            var NewEncoding := DetectFileEncoding(FileName, NewHasBOM);

            if NewHasBOM then
            begin
              Log(string('警告：转换后文件仍然包含BOM，可能转换失败'));
              // 尝试再次转换
              ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.RemoveUTF8BOM(FileName);
              if ConvResult.Success then
                Log(string('第二次尝试移除BOM成功'))
              else
                Log(string('第二次尝试移除BOM失败: ') + ConvResult.ErrorMessage);
            end;
          end
          else
          begin
            Log(string('将UTF-8+BOM文件转换为UTF-8无BOM失败: ') + ConvResult.ErrorMessage);
          end;
        end
        else
        begin
          // 其他编码转换为UTF-8无BOM
          var ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.ConvertToUTF8WithoutBOM(FileName);
          Result := ConvResult.Success;

          if Result then
          begin
            Log(Format(string('成功将%s文件转换为UTF-8无BOM'), [SourceEncodingName]));

            // 验证转换结果
            var NewHasBOM: Boolean;
            var NewEncoding := DetectFileEncoding(FileName, NewHasBOM);

            if NewHasBOM then
            begin
              Log(string('警告：转换后文件仍然包含BOM，尝试再次移除'));
              // 尝试使用专用方法移除BOM
              ConvResult := UTF8BOMConverter_Simple.TUTF8BOMConverter.RemoveUTF8BOM(FileName);
              if ConvResult.Success then
                Log(string('使用专用方法移除BOM成功'))
              else
                Log(string('使用专用方法移除BOM失败: ') + ConvResult.ErrorMessage);
            end;
          end
          else
          begin
            Log(Format(string('将%s文件转换为UTF-8无BOM失败: %s'), [SourceEncodingName, ConvResult.ErrorMessage]));
          end;
        end;
      except
        on E: Exception do
        begin
          Log(string('转换过程中发生异常: ') + E.Message);
          Result := False;
        end;
      end;
    end
    else
    begin
      // 其他编码转换，使用传统方法
      Log('使用传统方法进行编码转换...');

      // 复制文件到临时文件
      try
        TFile.Copy(FileName, TempFile, True);

        // 使用传统方法进行转换
        // 这里需要实现其他编码的转换逻辑
        // 暂时返回失败
        Result := False;
        Log(string('暂不支持其他编码的转换'));
      except
        on E: Exception do
        begin
          Log(Format(string('复制文件失败: %s - %s'), [FileName, E.Message]));
          Result := False;
        end;
      end;
    end;

    // 如果转换成功，记录结果
    if Result then
    begin
      // 重新检测文件编码，确认转换结果
      var NewEncoding: string;
      var NewHasBOM: Boolean;
      NewEncoding := DetectFileEncoding(FileName, NewHasBOM);

      // 记录转换结果
      var BOMInfo := '';
      if NewHasBOM then
        BOMInfo := ' (带BOM)';

      Log(Format(string('成功转换文件: %s (从 %s 到 %s%s)'),
        [ExtractFileName(FileName), SourceEncodingName, NewEncoding, BOMInfo]));

      // 调用成功回调
      if Assigned(OnSuccess) then
        OnSuccess(FileName);
    end
    else
    begin
      Log(Format(string('转换文件失败: %s'), [FileName]));
    end;
  finally
    // 删除临时文件
    if FileExists(TempFile) then
    begin
      try
        DeleteFile(PChar(TempFile));
      except
        // 忽略删除临时文件的错误
      end;
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

  Log(Format(string('开始批量转换 %d 个文件到 %s (BOM: %s)...'),
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
      Log(Format(string('进度: %d/%d (%.1f%%) - 成功: %d, 失败: %d'),
        [i + 1, TotalCount, (i + 1) / TotalCount * 100, SuccessCount, FailCount]));
    end;
  end;

  // 计算总耗时
  EndTime := Now;
  ElapsedSeconds := (EndTime - StartTime) * 86400; // 转换为秒

  // 输出详细的完成报告
  Log('');
  Log(Format(string('批量转换完成: 成功 %d/%d 个文件'), [SuccessCount, TotalCount]));
  Log(Format(string('- 总文件数: %d'), [TotalCount]));
  Log(Format(string('- 成功转换: %d (%.1f%%)'), [SuccessCount, SuccessCount / TotalCount * 100]));
  Log(Format(string('- 转换失败: %d (%.1f%%)'), [FailCount, FailCount / TotalCount * 100]));
  Log(Format(string('- 总耗时: %.2f秒 (平均每文件 %.2f毫秒)'),
    [ElapsedSeconds, ElapsedSeconds * 1000 / TotalCount]));

  // 如果有失败的文件，建议用户查看日志
  if FailCount > 0 then
    Log(string('请查看上方日志了解失败详情'));
end;

end.
