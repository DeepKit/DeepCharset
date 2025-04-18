program ConvertEncodings;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  ControllerEncoding;

type
  TLogProc = reference to procedure(const Msg: string);

var
  EncodingController: TEncodingController;
  SourceDir: string;
  TargetDir: string;
  TargetEncodingName: string;
  AddBOM: Boolean;
  SuccessCount, TotalCount: Integer;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

function GetEncodingFromName(const EncodingName: string): TEncoding;
begin
  // 根据编码名称获取TEncoding对象
  if SameText(EncodingName, 'utf-8') then
    Result := TEncoding.UTF8
  else if SameText(EncodingName, 'utf-16') or SameText(EncodingName, 'unicode') then
    Result := TEncoding.Unicode
  else if SameText(EncodingName, 'utf-16be') then
    Result := TEncoding.BigEndianUnicode
  else if SameText(EncodingName, 'ascii') then
    Result := TEncoding.ASCII
  else if SameText(EncodingName, 'ansi') then
    Result := TEncoding.Default
  else
  begin
    // 尝试通过代码页获取编码
    try
      var CodePage := StrToIntDef(EncodingName, 0);
      if CodePage > 0 then
        Result := TEncoding.GetEncoding(CodePage)
      else
        Result := TEncoding.UTF8; // 默认使用UTF-8
    except
      Result := TEncoding.UTF8; // 出错时使用UTF-8
    end;
  end;
end;

procedure ConvertFile(const SourceFile, TargetFile: string; TargetEncoding: TEncoding; AddBOM: Boolean);
var
  ConversionResult: TConversionResult;
begin
  // 转换文件编码
  ConversionResult := EncodingController.ConvertFileEncoding(SourceFile, TargetFile, TargetEncoding, AddBOM);

  Inc(TotalCount);
  case ConversionResult of
    crSuccess:
    begin
      Writeln('转换成功: ', SourceFile, ' -> ', TargetFile);
      Inc(SuccessCount);
    end;
    crFailed:
      Writeln('转换失败: ', SourceFile);
    crSkipped:
      Writeln('跳过文件: ', SourceFile);
  end;
end;

procedure ProcessDirectory(const SourceDir, TargetDir: string; TargetEncoding: TEncoding; AddBOM: Boolean);
var
  Files: TArray<string>;
  FilePath: string;
  RelativePath: string;
  TargetFilePath: string;
  TargetFileDir: string;
  Ext: string;
begin
  // 获取源目录中的所有文件
  Files := TDirectory.GetFiles(SourceDir, '*.*', TSearchOption.soAllDirectories);

  for FilePath in Files do
  begin
    // 只处理文本文件
    Ext := ExtractFileExt(FilePath).ToLower();
    if (Ext = '.txt') or (Ext = '.csv') or (Ext = '.ini') or (Ext = '.log') or
       (Ext = '.xml') or (Ext = '.json') or (Ext = '.htm') or (Ext = '.html') or
       (Ext = '.css') or (Ext = '.js') or (Ext = '.md') then
    begin
      // 计算相对路径
      RelativePath := FilePath.Substring(SourceDir.Length + 1);
      TargetFilePath := TPath.Combine(TargetDir, RelativePath);

      // 确保目标文件所在目录存在
      TargetFileDir := ExtractFilePath(TargetFilePath);
      if not DirectoryExists(TargetFileDir) then
        ForceDirectories(TargetFileDir);

      // 转换文件编码
      ConvertFile(FilePath, TargetFilePath, TargetEncoding, AddBOM);
    end;
  end;
end;

begin
  try
    // 检查命令行参数
    if ParamCount < 2 then
    begin
      Writeln('用法: ConvertEncodings.exe <源目录> <目标目录> [目标编码] [添加BOM(true/false)]');
      Exit;
    end;

    SourceDir := ParamStr(1);
    TargetDir := ParamStr(2);

    if not DirectoryExists(SourceDir) then
    begin
      Writeln('错误: 源目录不存在 - ', SourceDir);
      Exit;
    end;

    // 目标编码，默认为UTF-8
    if ParamCount >= 3 then
      TargetEncodingName := ParamStr(3)
    else
      TargetEncodingName := 'utf-8';

    // 是否添加BOM，默认为True
    AddBOM := True;
    if ParamCount >= 4 then
      AddBOM := StrToBoolDef(ParamStr(4), True);

    // 创建目标目录
    if not DirectoryExists(TargetDir) then
      ForceDirectories(TargetDir);

    // 创建编码控制器
    EncodingController := TEncodingController.Create(LogMessage);
    try
      Writeln('开始转换文件编码...');
      Writeln('源目录: ', SourceDir);
      Writeln('目标目录: ', TargetDir);
      Writeln('目标编码: ', TargetEncodingName);
      Writeln('添加BOM: ', BoolToStr(AddBOM, True));
      Writeln(StringOfChar('-', 50));

      // 初始化计数器
      SuccessCount := 0;
      TotalCount := 0;

      // 处理目录
      ProcessDirectory(SourceDir, TargetDir, GetEncodingFromName(TargetEncodingName), AddBOM);

      Writeln(StringOfChar('-', 50));
      Writeln('转换完成! 成功: ', SuccessCount, '/', TotalCount);
    finally
      EncodingController.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
