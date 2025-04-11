unit ControllerEncoding;

{$DEFINE UNUSED} // 定义此条件编译标记以显示未使用的方法

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.SyncObjs,
  System.Types, System.TypInfo, // 添加这些单元以支持跨平台的文件属性
  ModelEncoding, Winapi.Windows, JclEncodingUtils;

type
  // 日志回调类型
  TLogCallback = procedure(const Msg: string) of object;

  // 编码控制器类
  TEncodingController = class
  private
    // 日志记录回调
    FLogCallback: TLogCallback;

    // 日志记录辅助方法
    procedure Log(const Msg: string);
    procedure LogFmt(const Fmt: string; const Args: array of const);

    // 内部编码转换辅助函数
    function TryCopyTempToOriginal(const TempFile, OriginalFile: string): Boolean;

    // 以下方法已弃用，保留仅供参考
    {$IFDEF UNUSED}
    function CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
    procedure CreateBackupFile(const SourceFile: string; var BackupFile: string);
    procedure LogConversionSuccess(const SourceFile: string);
    procedure RestoreFromBackup(const OriginalFile, BackupFile: string);
    {$ENDIF}

    // 使用JCL进行编码转换
    function ConvertWithJCL(const SourceFile, TargetFile: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;

    // NEW: Internal helper to perform single file conversion using names
    function DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; AddBOM: Boolean = False; const TargetFile: string = ''): TConversionResult;

  public
    constructor Create(ALogCallback: TLogCallback);
    destructor Destroy; override;

    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;

    // 检查文件是否有BOM标记
    function HasBOM(const FileName: string; Encoding: TEncoding = nil): Boolean;

    // 检测文件编码 - 使用JCL
    function DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;

    // 转换单个文件编码
    function ConvertFileEncoding(const SourceFile, TargetFile: string;
      TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;

    // 批量转换文件夹中的文件
    procedure ConvertFilesToEncoding(const FolderPath: string;
      const FileExtensions: TArray<string>; SelectedFiles: TArray<string>;
      TargetEncoding: TEncoding; AddBOM: Boolean);

    // 转换选中的文件
    procedure ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
      TargetEncoding: TEncoding; AddBOM: Boolean);

    // --- NEW Public Methods using Encoding Names ---
    procedure ConvertFilesByName(const SelectedFiles: TArray<string>;
                                 const TargetEncodingName: string;
                                 AddBOM: Boolean;
                                 UpdateCallback: TProc<string>);

    function ConvertSingleFileByName(const SourceFile: string;
                                     const TargetEncodingName: string;
                                     AddBOM: Boolean;
                                     UpdateCallback: TProc<string>): Boolean;
    // --- End of NEW Public Methods ---
  end;

implementation

uses System.Threading;

{ TEncodingController }

procedure TEncodingController.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingController.LogFmt(const Fmt: string; const Args: array of const);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Format(Fmt, Args));
end;

constructor TEncodingController.Create(ALogCallback: TLogCallback);
begin
  inherited Create;
  FLogCallback := ALogCallback;

  // 记录日志
  Log('JCL编码处理功能已初始化');
end;

destructor TEncodingController.Destroy;
begin
  inherited;
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
      Break;
    end;
  end;
end;

function TEncodingController.HasBOM(const FileName: string; Encoding: TEncoding): Boolean;
var
  Stream: TFileStream;
  Preamble: TBytes;
  DetectedBytes: TBytes;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if Encoding = nil then
        Encoding := TEncoding.UTF8;

      Preamble := Encoding.GetPreamble;

      if Length(Preamble) = 0 then
        Exit(False);

      SetLength(DetectedBytes, Length(Preamble));

      if Stream.Size < Length(Preamble) then
        Exit(False);

      Stream.ReadBuffer(DetectedBytes[0], Length(Preamble));

      // 比较BOM标记
      for var i := 0 to High(Preamble) do
      begin
        if Preamble[i] <> DetectedBytes[i] then
          Exit(False);
      end;

      Result := True;
    finally
      Stream.Free;
    end;
  except
    // 如果读取失败，假设没有BOM
    Result := False;
  end;
end;

function TEncodingController.DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;
var
  HasUTF8BOM: Boolean;
  Stream: TFileStream;
  BOMBytes: TBytes;
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    EncodingName := '';
    Result := False;
    Exit;
  end;

  // 首先检查是否有UTF-8 BOM
  HasUTF8BOM := False;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size >= 3 then
      begin
        SetLength(BOMBytes, 3);
        Stream.ReadBuffer(BOMBytes[0], 3);

        // UTF-8 BOM: EF BB BF
        HasUTF8BOM := (BOMBytes[0] = $EF) and (BOMBytes[1] = $BB) and (BOMBytes[2] = $BF);
      end;
    finally
      Stream.Free;
    end;
  except
    // 如果读取失败，假设没有BOM
    HasUTF8BOM := False;
  end;

  if HasUTF8BOM then
  begin
    EncodingName := 'UTF-8 with BOM';
    Result := True;

    Log('检测到UTF-8 BOM: ' + FileName);
    Exit;
  end;

  // 使用JCL库检测文件编码
  try
    // 调用JCL的编码检测方法
    EncodingName := JclEncodingUtils.DetectFileEncoding(FileName);
    Result := EncodingName <> 'Unknown';

    // 如果检测成功，但编码不明确或不是UTF-8，优先建议使用UTF-8+BOM
    if Result then
    begin
      Log('JCL检测到文件编码: ' + FileName + ' -> ' + EncodingName);

      // 如果是UTF-8但没有BOM，标记为普通UTF-8
      if SameText(EncodingName, 'UTF-8') and not HasUTF8BOM then
        EncodingName := 'UTF-8';
    end
    else
    begin
      // 如果检测失败，默认假设为ANSI
      EncodingName := 'ANSI';
      Result := True;

      Log('无法检测编码，默认使用ANSI: ' + FileName);
    end;
  except
    on E: Exception do
    begin
      Log('编码检测出错: ' + E.Message);

      // 发生异常时，也默认使用ANSI
      EncodingName := 'ANSI';
      Result := True;
    end;
  end;
end;



function TEncodingController.ConvertWithJCL(const SourceFile, TargetFile: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
var
  SysErrorCode: Cardinal;
  ActualTargetEncoding: string;
begin
  Result := False;

  try
    if not FileExists(SourceFile) then
    begin
      Log('文件不存在: ' + SourceFile);
      Exit;
    end;

    // 检查文件是否可访问
    try
      var TestStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
      try
        // 只测试是否可以读取，不做实际操作
      finally
        TestStream.Free;
      end;
    except
      on E: Exception do
      begin
        Log('文件访问错误: ' + E.Message);
        Exit;
      end;
    end;

    // 特殊处理UTF-8 BOM的情况
    ActualTargetEncoding := TargetEncoding;
    if (SameText(TargetEncoding, 'UTF-8 BOM') or SameText(TargetEncoding, 'UTF-8-BOM') or
       SameText(TargetEncoding, 'UTF8-BOM')) then
    begin
      ActualTargetEncoding := 'UTF-8';
      AddBOM := True;

      Log('注意: 目标编码"' + TargetEncoding + '"已规范化为"UTF-8"并设置AddBOM=True');
    end;

    LogFmt('开始转换: %s -> %s, 从 [%s] 到 [%s], BOM: %s',
           [SourceFile, TargetFile, SourceEncoding, ActualTargetEncoding,
            BoolToStr(AddBOM, True)]);

    // 使用JclEncodingUtils的ConvertFileByName函数
    try
      Result := JclEncodingUtils.ConvertFileByName(SourceFile, TargetFile,
                                               SourceEncoding, ActualTargetEncoding, AddBOM);
    except
      on E: EFOpenError do
      begin
        SysErrorCode := GetLastError;
        LogFmt('文件打开错误 (代码: %d): %s', [SysErrorCode, E.Message]);
        Result := False;
        Exit;
      end;
      on E: EFCreateError do
      begin
        SysErrorCode := GetLastError;
        LogFmt('文件创建错误 (代码: %d): %s', [SysErrorCode, E.Message]);
        Result := False;
        Exit;
      end;
      on E: EWriteError do
      begin
        SysErrorCode := GetLastError;
        LogFmt('文件写入错误 (代码: %d): %s', [SysErrorCode, E.Message]);
        Result := False;
        Exit;
      end;
      on E: Exception do
        raise; // 重新抛出其他异常
    end;

    if Result then
    begin
      if Assigned(FLogCallback) then
      begin
        FLogCallback(Format('JCL转换调用完成: %s (源编码: %s, 目标编码: %s, AddBOM: %s)',
                           [TargetFile, SourceEncoding, ActualTargetEncoding, BoolToStr(AddBOM, True)]));

        // 验证转换结果
        var ResultEncodingName: string;
        if DetectFileEncoding(TargetFile, ResultEncodingName) then
        begin
          FLogCallback(Format('转换后的文件编码: %s -> %s', [TargetFile, ResultEncodingName]));

          // 特殊情况: 如果目标应为UTF-8 BOM但检测为其他编码，尝试手动添加BOM
          if AddBOM and SameText(ActualTargetEncoding, 'UTF-8') and
             not SameText(ResultEncodingName, 'UTF-8 with BOM') then
          begin
            FLogCallback('检测到目标应为UTF-8 BOM但未成功添加BOM，尝试手动修复...');
            var TempFile := TargetFile + '.fix';

            try
              // 读取原文件内容
              var Content := TFile.ReadAllBytes(TargetFile);
              var BOMBytes := TBytes.Create($EF, $BB, $BF); // UTF-8 BOM

              // 检查是否已有BOM
              var HasBOMAlready := (Length(Content) >= 3) and
                                   (Content[0] = $EF) and (Content[1] = $BB) and (Content[2] = $BF);

              if not HasBOMAlready then
              begin
                // 合并BOM和内容
                var FinalContent: TBytes;
                SetLength(FinalContent, Length(BOMBytes) + Length(Content));
                if Length(BOMBytes) > 0 then
                  Move(BOMBytes[0], FinalContent[0], Length(BOMBytes));
                if Length(Content) > 0 then
                  Move(Content[0], FinalContent[Length(BOMBytes)], Length(Content));

                // 写入修复后的文件
                TFile.WriteAllBytes(TempFile, FinalContent);

                // 替换原文件
                if FileExists(TempFile) then
                begin
                  // 删除原文件
                  DeleteFile(PChar(TargetFile));
                  if RenameFile(TempFile, TargetFile) then
                  begin
                    FLogCallback('成功手动添加UTF-8 BOM');
                    // 重新检测以确认
                    if DetectFileEncoding(TargetFile, ResultEncodingName) then
                      FLogCallback(Format('修复后的文件编码: %s -> %s', [TargetFile, ResultEncodingName]));
                  end
                  else
                  begin
                    SysErrorCode := GetLastError;
                    FLogCallback(Format('无法重命名修复文件 (错误码: %d)', [SysErrorCode]));
                    // 尝试直接复制
                    if CopyFile(PChar(TempFile), PChar(TargetFile), False) then
                    begin
                      FLogCallback('使用复制方式成功添加UTF-8 BOM');
                      DeleteFile(PChar(TempFile));
                    end;
                  end;
                end;
              end;
            except
              on E: Exception do
                FLogCallback('手动添加BOM失败: ' + E.Message);
            end;
          end;
        end
        else
          FLogCallback('无法检测转换后的文件编码');
      end;
    end
    else
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('JCL转换失败: %s -> %s', [SourceEncoding, ActualTargetEncoding]));
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('JCL转换出错: ' + E.Message);
      Result := False;
    end;
  end;
end;

// NEW: Internal helper to perform single file conversion using names
function TEncodingController.DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; AddBOM: Boolean = False; const TargetFile: string = ''): TConversionResult;
var
  TempFile: string;
  ActualFile: string;
begin
  Result := crFailed;

  // 验证源文件存在
  if not FileExists(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误：源文件不存在: ' + SourceFile);
    Exit;
  end;

  // 设置目标文件
  if TargetFile = '' then
  begin
    TempFile := ChangeFileExt(SourceFile, '.tmp');
    ActualFile := SourceFile;
  end
  else
  begin
    TempFile := TargetFile;
    ActualFile := TargetFile;
  end;

  // 转换文件
  try
    if ConvertWithJCL(SourceFile, TempFile, 'ANSI', TargetEncodingName, AddBOM) then
    begin
      // 如果需要替换原文件
      if TargetFile = '' then
      begin
        if TryCopyTempToOriginal(TempFile, SourceFile) then
          Result := crSuccess
        else
          Result := crFailed;
      end
      else
        Result := crSuccess;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('转换过程中发生异常: %s', [E.Message]));
      Result := crFailed;
    end;
  end;
end;

// 以下是旧的实现，已经被替换
(*
  try
    // 目标文件设置
    if TargetFile = '' then
      TempFile := ChangeFileExt(SourceFile, '.tmp')
    else
      TempFile := TargetFile;

    // 确定最终操作的文件
    if TargetFile = '' then
      ActualFile := SourceFile
    else
      ActualFile := TargetFile;

    // 检查UTF-8 BOM目标 - 改进识别逻辑
    IsUTF8BOMTarget := (SameText(TargetEncodingName, 'UTF-8 with BOM') or
                        SameText(TargetEncodingName, 'UTF-8-BOM') or
                        SameText(TargetEncodingName, 'UTF8-BOM') or
                        (SameText(TargetEncodingName, 'UTF-8') and AddBOM));

    // 详细日志：源和目标编码信息更详细
    var BOMText: string := '';
    if IsUTF8BOMTarget then
      BOMText := ' (带BOM)'
    else if AddBOM then
      BOMText := ' (带BOM)';

    if Assigned(FLogCallback) then
      FLogCallback(Format('源编码: [%s] 目标编码: [%s%s]',
           [SourceEncodingName, TargetEncodingName, BOMText]));

    if IsUTF8BOMTarget then
    begin
      // 使用专用函数处理UTF-8 BOM转换
      if Assigned(FLogCallback) then
        FLogCallback(Format('使用专用函数转换为UTF-8 BOM (源编码: %s)...', [SourceEncodingName]));

      // 确保删除已存在的临时文件
      if FileExists(TempFile) then
        DeleteFile(PChar(TempFile));

      try
        // 直接使用JclEncodingUtils.ConvertFileToUTF8BOM转换为UTF-8 BOM
        if JclEncodingUtils.ConvertFileToUTF8BOM(SourceFile, TempFile) then
        begin
          Result := crSuccess;
          if Assigned(FLogCallback) then
            FLogCallback('UTF-8 BOM直接转换成功');
        end
        else
        begin
          SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('UTF-8 BOM直接转换失败，系统错误: %d，尝试替代方法...', [SystemError]));

          // 替代方法：先转换为UTF-8，然后手动添加BOM
          if ConvertWithJCL(SourceFile, TempFile, SourceEncodingName, 'UTF-8', False) then
          begin
            // 读取文件并添加BOM
            var TempContent: TBytes;
            var FinalContent: TBytes;
            var BOMBytes: TBytes;

            try
              if FileExists(TempFile) then
              begin
                TempContent := TFile.ReadAllBytes(TempFile);
                BOMBytes := TBytes.Create($EF, $BB, $BF); // UTF-8 BOM

                // 合并BOM和内容
                SetLength(FinalContent, Length(BOMBytes) + Length(TempContent));
                if Length(BOMBytes) > 0 then
                  Move(BOMBytes[0], FinalContent[0], Length(BOMBytes));
                if Length(TempContent) > 0 then
                  Move(TempContent[0], FinalContent[Length(BOMBytes)], Length(TempContent));

                // 重写文件
                TFile.WriteAllBytes(TempFile, FinalContent);
                Result := crSuccess;
                if Assigned(FLogCallback) then
                  FLogCallback('UTF-8 BOM手动添加成功');
              end;
            except
              on E: Exception do
              begin
                SystemError := GetLastError;
                if Assigned(FLogCallback) then
                  FLogCallback(Format('UTF-8 BOM手动添加失败: %s (错误码: %d)', [E.Message, SystemError]));
                Result := crFailed;
              end;
            end;
          end
          else
          begin
            SystemError := GetLastError;
            if Assigned(FLogCallback) then
              FLogCallback(Format('UTF-8转换失败，无法应用替代方法 (错误码: %d)', [SystemError]));
            Result := crFailed;
          end;
        end;
      except
        on E: Exception do
        begin
          SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('UTF-8 BOM转换异常: %s (系统错误: %d)', [E.Message, SystemError]));
          Result := crFailed;
        end;
      end;
    end
    else
    begin
      // 常规编码转换处理
      ActualTargetName := TargetEncodingName;
      ActualBOM := AddBOM;

      if Assigned(FLogCallback) then
        FLogCallback(Format('使用标准转换流程 %s -> %s (BOM: %s)',
          [SourceEncodingName, ActualTargetName, BoolToStr(ActualBOM, True)]));

      try
        // 正确传递源编码和目标编码参数
        if ConvertWithJCL(SourceFile, TempFile, SourceEncodingName, ActualTargetName, ActualBOM) then
          Result := crSuccess
        else
        begin
          SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('标准转换失败，系统错误: %d', [SystemError]));
          Result := crFailed;
        end;
      except
        on E: Exception do
        begin
          SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('标准转换异常: %s (系统错误: %d)', [E.Message, SystemError]));
          Result := crFailed;
        end;
      end;
    end;

    // 如果转换成功且需要替换原文件
    if (Result = crSuccess) and (TargetFile = '') then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换成功，准备替换原文件...');

      try
        TryCopyTempToOriginal(TempFile, SourceFile);

        // 检查文件复制成功
        if not FileExists(SourceFile) then
        begin
          SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换原文件失败，系统错误: %d', [SystemError]));
          Result := crFailed;
        end;
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换原文件异常: %s', [E.Message]));
          Result := crFailed;
        end;
      end;
    end;

    // 检查转换后的文件编码
    if Result = crSuccess then
    begin
      try
        DestinationFileEncoding := '';

        if FileExists(ActualFile) then
        begin
          if DetectFileEncoding(ActualFile, DestinationFileEncoding) then
          begin
            if Assigned(FLogCallback) then
              FLogCallback(Format('转换完成后的文件编码: %s -> %s', [ActualFile, DestinationFileEncoding]));

            // 验证是否成功转换为目标编码
            if IsUTF8BOMTarget and (Pos('UTF-8', DestinationFileEncoding) = 0) then
            begin
              // 最后一次尝试修复 - 如果检测出来不是UTF-8，但是目标应该是UTF-8 BOM
              if Assigned(FLogCallback) then
                FLogCallback('警告：文件应该是UTF-8 BOM，但检测到: ' + DestinationFileEncoding + '，尝试修复...');

              // 再次尝试添加BOM
              var FixedFile := ActualFile + '.fix';
              if JclEncodingUtils.ConvertFileToUTF8BOM(ActualFile, FixedFile) then
              begin
                if FileExists(FixedFile) then
                begin
                  if DeleteFile(PChar(ActualFile)) then
                  begin
                    if RenameFile(FixedFile, ActualFile) then
                    begin
                      if Assigned(FLogCallback) then
                        FLogCallback('已修复UTF-8 BOM编码问题');

                      // 重新检测以确认
                      if DetectFileEncoding(ActualFile, DestinationFileEncoding) then
                        if Assigned(FLogCallback) then
                          FLogCallback(Format('修复后的文件编码: %s -> %s', [ActualFile, DestinationFileEncoding]));
                    end
                    else
                      if Assigned(FLogCallback) then
                        FLogCallback('无法重命名修复文件');
                  end
                  else
                    if Assigned(FLogCallback) then
                      FLogCallback('无法删除原文件以应用修复');

                  // 如果临时修复文件仍然存在，清理它
                  if FileExists(FixedFile) then
                    DeleteFile(PChar(FixedFile));
                  end;
                end;
              end;
            end;
          end
          else
          begin
            if Assigned(FLogCallback) then
              FLogCallback('警告：无法检测转换后的文件编码');
          end;
        end;
      end;
    end;
  end;

  if not FileExists(ActualFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('警告：转换后的文件不存在: ' + ActualFile);
    Result := crFailed;
  end;

  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测转换后的文件编码失败: %s', [E.Message]));
    end;
  end;
end;
*)

// NEW Public Method Implementation: ConvertSingleFileByName
function TEncodingController.ConvertSingleFileByName(const SourceFile: string;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>): Boolean;
var
  ConversionResult: TConversionResult;
begin
  // 调用内部方法进行转换
  ConversionResult := DoConvertSingleFileByName(SourceFile, TargetEncodingName, AddBOM, '');

  // 检查转换结果
  Result := (ConversionResult = crSuccess);

  // 如果转换成功并且回调函数已分配，调用回调
  if Result and Assigned(UpdateCallback) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback(Format('单文件转换成功，调用回调: %s', [SourceFile]));
    UpdateCallback(SourceFile);
  end;
end;

// NEW Public Method Implementation: ConvertFilesByName
procedure TEncodingController.ConvertFilesByName(const SelectedFiles: TArray<string>;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>);
var
  FileToConvert: string;
  ConversionResult: TConversionResult;
  Tasks: array of ITask;
  TaskResults: array of TConversionResult;
  FileIndex, i, SuccessCount: Integer;
  MaxConcurrentTasks: Integer;
  CriticalSection: TCriticalSection;
begin
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始批量转换 %d 个文件到 %s', [Length(SelectedFiles), TargetEncodingName]));

  // 如果没有文件需要转换，直接返回
  if Length(SelectedFiles) = 0 then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('没有文件需要转换。');
    Exit;
  end;

  // 如果只有一个文件，使用单文件转换方式
  if Length(SelectedFiles) = 1 then
  begin
    FileToConvert := SelectedFiles[0];
    ConversionResult := DoConvertSingleFileByName(FileToConvert, TargetEncodingName, AddBOM, '');

    if (ConversionResult = crSuccess) and Assigned(UpdateCallback) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('文件转换成功，调用回调: %s', [FileToConvert]));
      UpdateCallback(FileToConvert);
    end;

    if Assigned(FLogCallback) then
      FLogCallback('批量转换完成。');
    Exit;
  end;

  // 并行处理多个文件
  try
    // 初始化并发控制
    CriticalSection := TCriticalSection.Create;

    // 根据 CPU 核心数确定最大并发任务数，但不超过 8 个
    // 使用 Math 单元中的 Min 函数
    if TThread.ProcessorCount < 8 then
      MaxConcurrentTasks := TThread.ProcessorCount
    else
      MaxConcurrentTasks := 8;

    if MaxConcurrentTasks > Length(SelectedFiles) then
      MaxConcurrentTasks := Length(SelectedFiles);

    if Assigned(FLogCallback) then
      FLogCallback(Format('使用 %d 个并行任务进行批量转换', [MaxConcurrentTasks]));

    // 初始化任务数组
    SetLength(Tasks, Length(SelectedFiles));
    SetLength(TaskResults, Length(SelectedFiles));

    // 创建并启动所有任务
    for i := 0 to High(SelectedFiles) do
    begin
      FileIndex := i; // 捕获当前索引以在匿名方法中使用

      // 创建任务
      Tasks[i] := TTask.Create(
        procedure
      var
        LocalFile: string;
        LocalResult: TConversionResult;
      begin
        try
          LocalFile := SelectedFiles[FileIndex];
          LocalResult := DoConvertSingleFileByName(LocalFile, TargetEncodingName, AddBOM, '');

          // 安全地存储结果
          CriticalSection.Enter;
          try
            TaskResults[FileIndex] := LocalResult;

            // 如果转换成功并且回调函数已分配，调用回调
            if (LocalResult = crSuccess) and Assigned(UpdateCallback) then
            begin
              if Assigned(FLogCallback) then
                FLogCallback(Format('文件转换成功，调用回调: %s', [LocalFile]));
              UpdateCallback(LocalFile);
            end;
          finally
            CriticalSection.Leave;
          end;
        except
          on E: Exception do
          begin
            CriticalSection.Enter;
            try
              if Assigned(FLogCallback) then
                FLogCallback(Format('并行转换异常: %s - %s', [SelectedFiles[FileIndex], E.Message]));
              TaskResults[FileIndex] := crFailed;
            finally
              CriticalSection.Leave;
            end;
          end;
        end;
      end);

      // 启动任务，但控制并发数量
      if (i mod MaxConcurrentTasks = 0) and (i > 0) then
      begin
        // 等待前面的任务完成
        // 使用条件判断替代 Max 函数
        var StartIndex: Integer;
        if (i - MaxConcurrentTasks > 0) then
          StartIndex := i - MaxConcurrentTasks
        else
          StartIndex := 0;

        for var j := StartIndex to i - 1 do
        begin
          if Assigned(Tasks[j]) then
            Tasks[j].Wait;
        end;
      end;

      Tasks[i].Start;
    end;

    // 等待所有任务完成
    for i := 0 to High(Tasks) do
    begin
      if Assigned(Tasks[i]) then
        Tasks[i].Wait;
    end;

    // 统计成功数量
    SuccessCount := 0;
    for i := 0 to High(TaskResults) do
    begin
      if TaskResults[i] = crSuccess then
        Inc(SuccessCount);
    end;

    if Assigned(FLogCallback) then
      FLogCallback(Format('批量转换完成。成功: %d/%d', [SuccessCount, Length(SelectedFiles)]));
  finally
    // 释放资源
    if Assigned(CriticalSection) then
      CriticalSection.Free;
  end;
end;

// Existing ConvertFileEncoding (marked as incompatible)
function TEncodingController.ConvertFileEncoding(const SourceFile, TargetFile: string;
  TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;
// No local variables needed
begin
  // This implementation uses Delphi's TEncoding.Convert
  // It needs significant rework to use JCL with TEncodingInfo.ShortName
  // For now, it's likely incompatible with the new approach.

  Result := crSkipped; // Mark as skipped/failed for now
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertFileEncoding (TEncoding version) 当前未实现 JCL 支持。');

  // --- Original code commented out ---
  (*
  var
    TempFile, BackupFile: string;
    UseTemp: Boolean;
    SourceEncoding: TEncoding;
    SourceStream, DestStream: TMemoryStream;
    Reader: TStreamReader;
    Writer: TStreamWriter;
  begin
    Result := crFailed;
    ...
  end;
  *)
end;

// Existing ConvertFilesToEncoding (marked as incompatible)
procedure TEncodingController.ConvertFilesToEncoding(const FolderPath: string;
  const FileExtensions: TArray<string>; SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
// No local variables needed
begin
 // This implementation likely calls ConvertFileEncoding internally.
 // It needs similar rework as ConvertFileEncoding.
  Log('警告: ConvertFilesToEncoding (TEncoding version) 当前未实现 JCL 支持。');
  // --- Original code commented out ---
  (*
  var
    Files: TArray<string>;
    ...
  begin
  ...
  end;
  *)
end;

// Existing ConvertSelectedFilesToEncoding (marked as incompatible)
procedure TEncodingController.ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
// No local variables needed
begin
 // This implementation likely calls ConvertFileEncoding internally.
 // It needs similar rework as ConvertFileEncoding.
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertSelectedFilesToEncoding (TEncoding version) 当前未实现 JCL 支持。');
  // --- Original code commented out ---
  (*
  var
    FilePath: string;
    ...
  begin
  ...
  end;
  *)
end;

// Helper function implementations (CheckFileAccessibility, CreateBackupFile, etc.)
// Assuming these helpers are already implemented correctly.
function TEncodingController.CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
begin
  Result := False;
  UseTemp := True; // Default to using temp file
  if not FileExists(FileName) then Exit;

  try
    // Try to open with write access
    var Stream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareExclusive);
    Stream.Free;
    UseTemp := False; // Can overwrite directly
    Result := True;
  except
    on E: EFOpenError do
    begin
      // Cannot open exclusively, try read-only to see if it exists and is readable
      try
        var ReadStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        ReadStream.Free;
        UseTemp := True; // Need temp file
        Result := True;
      except
        Result := False; // Cannot even read the file
      end;
    end
    else
      Result := False; // Other error
  end;
end;

procedure TEncodingController.CreateBackupFile(const SourceFile: string; var BackupFile: string);
begin
  BackupFile := TPath.ChangeExtension(SourceFile, '.bakconv');
  try
    if FileExists(BackupFile) then
      DeleteFile(PChar(BackupFile));
    TFile.Copy(SourceFile, BackupFile);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('创建备份失败 (' + SourceFile + '): ' + E.Message);
      BackupFile := ''; // Indicate backup failed
    end;
  end;
end;

function TEncodingController.TryCopyTempToOriginal(const TempFile, OriginalFile: string): Boolean;
const
  MAX_RETRY = 3; // 最大重试次数
var
  RetryCount: Integer;
  Success: Boolean;
  ErrCode: Cardinal;
begin
  // 初始化返回值为失败，确保即使出现意外情况也有定义的返回值
  Result := False;

  RetryCount := 0;
  Success := False; // 默认为失败

  try
    repeat
      Inc(RetryCount);

      // 详细日志
      if Assigned(FLogCallback) then
      begin
        if RetryCount > 1 then
          FLogCallback(Format('尝试复制(第%d次): %s -> %s', [RetryCount, TempFile, OriginalFile]))
        else
          FLogCallback(Format('开始复制: %s -> %s', [TempFile, OriginalFile]));
      end;

      // 检查临时文件是否存在
      if not FileExists(TempFile) then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('错误: 临时文件不存在: ' + TempFile);
        Success := False;
        Exit;
      end;

      // 确保原始文件是可写的
      if FileExists(OriginalFile) then
      begin
        // 先尝试设置文件为可写
        try
          // 检查文件是否为只读
          var Attrs := TFile.GetAttributes(OriginalFile);
          if (TFileAttribute.faReadOnly in Attrs) then
          begin
            // 使用 IOUtils 中的跨平台方法
            Attrs := Attrs - [TFileAttribute.faReadOnly];
            TFile.SetAttributes(OriginalFile, Attrs);
          end;
        except
          on E: Exception do
          begin
            ErrCode := GetLastError;
            if Assigned(FLogCallback) then
              FLogCallback(Format('警告: 无法设置文件为可写 (错误码: %d): %s', [ErrCode, OriginalFile]));
          end;
        end;
        // 然后删除文件
        if not DeleteFile(PChar(OriginalFile)) then
        begin
          ErrCode := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('无法删除原始文件 (错误码: %d): %s', [ErrCode, OriginalFile]));

          // 如果是"文件正在使用"错误，等待一下再重试
          if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('文件可能正在被使用，等待后重试...');
            Sleep(500); // 等待500毫秒
            Continue;
          end
          else
          begin
            Success := False;
            Exit; // 其他错误直接退出
          end;
        end;
      end;

      // 使用CopyFile函数进行复制，而不是TFile.Move
      if CopyFile(PChar(TempFile), PChar(OriginalFile), False) then
      begin
        Success := True;

        // 删除临时文件
        if FileExists(TempFile) then
        begin
          if not DeleteFile(PChar(TempFile)) then
          begin
            ErrCode := GetLastError;
            if Assigned(FLogCallback) then
              FLogCallback(Format('警告: 无法删除临时文件 (错误码: %d): %s', [ErrCode, TempFile]));
          end;
        end;

        if Assigned(FLogCallback) then
          FLogCallback('成功复制: ' + TempFile + ' -> ' + OriginalFile);

        Break; // 成功则退出循环
      end
      else
      begin
        ErrCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('复制失败 (错误码: %d): %s -> %s', [ErrCode, TempFile, OriginalFile]));

        // 对于一些特定的错误，可以重试
        if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) or
           (ErrCode = ERROR_LOCK_VIOLATION) then
        begin
          if RetryCount < MAX_RETRY then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('文件可能正在被使用，等待后重试...');
            Sleep(500 * RetryCount); // 等待时间逐次延长
            Continue;
          end;
        end;
      end;
    until RetryCount >= MAX_RETRY;

    // 如果所有重试都失败
    if not Success and Assigned(FLogCallback) then
      FLogCallback(Format('复制文件失败，已达到最大重试次数(%d): %s -> %s',
                         [MAX_RETRY, TempFile, OriginalFile]));
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('从临时文件复制时异常: ' + E.Message);
      Success := False; // 确保异常情况下也设置 Success 的值
    end;
  end;
  Result := Success;
end;

procedure TEncodingController.LogConversionSuccess(const SourceFile: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback('转换成功: ' + SourceFile);
end;

procedure TEncodingController.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  try
    if (BackupFile <> '') and FileExists(BackupFile) then
    begin
      // 确保原始文件是可写的
      if FileExists(OriginalFile) then
      begin
        // 先尝试设置文件为可写
        try
          // 检查文件是否为只读
          var Attrs := TFile.GetAttributes(OriginalFile);
          if (TFileAttribute.faReadOnly in Attrs) then
          begin
            // 使用 IOUtils 中的跨平台方法
            Attrs := Attrs - [TFileAttribute.faReadOnly];
            TFile.SetAttributes(OriginalFile, Attrs);
          end;
        except
          on E: Exception do
          begin
            if Assigned(FLogCallback) then
              FLogCallback('警告: 无法设置文件为可写: ' + OriginalFile);
          end;
        end;

        // 然后删除文件
        if not DeleteFile(PChar(OriginalFile)) then
        begin
          var ErrCode := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('恢复备份时无法删除原始文件 (错误码: %d): %s', [ErrCode, OriginalFile]));
          Exit;
        end;
      end;

      // 使用CopyFile函数进行复制
      if not CopyFile(PChar(BackupFile), PChar(OriginalFile), False) then
      begin
        var ErrCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('从备份恢复失败 (错误码: %d): %s -> %s', [ErrCode, BackupFile, OriginalFile]));
        Exit;
      end;

      if Assigned(FLogCallback) then
        FLogCallback('已从备份恢复: ' + OriginalFile);
    end
    else
    begin
      if Assigned(FLogCallback) then
        FLogCallback('没有可用的备份文件: ' + BackupFile);
    end;
  except
    on E: Exception do
      if Assigned(FLogCallback) then
        FLogCallback('从备份恢复时出错: ' + E.Message);
  end;
end;

end.