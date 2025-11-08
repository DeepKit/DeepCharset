unit ControllerCommandLine;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  UtilsTypes,
  UtilsEncodingTypes,
  EncodingConverter_Improved;

type
  // 命令行选项
  TCommandLineOptions = record
    SourceEncoding: string;      // 源编码
    TargetEncoding: string;      // 目标编码
    InputFile: string;           // 输入文件
    OutputFile: string;          // 输出文件（为空则覆盖原文件）
    Recursive: Boolean;          // 递归处理目录
    CreateBackup: Boolean;       // 创建备份
    Verbose: Boolean;            // 显示详细信息
    Quiet: Boolean;              // 安静模式（无输出）
    AddBOM: Boolean;             // 添加BOM
    RemoveBOM: Boolean;          // 移除BOM
    ShowHelp: Boolean;           // 显示帮助
    ShowVersion: Boolean;        // 显示版本
  end;

  // 命令行控制器
  TCommandLineController = class
  private
    FOptions: TCommandLineOptions;
    FConverter: TEncodingConverter_Improved;
    FSuccessCount: Integer;
    FFailureCount: Integer;
    
    procedure ParseCommandLine;
    procedure ShowHelp;
    procedure ShowVersion;
    procedure WriteOutput(const Msg: string; IsError: Boolean = False);
    procedure ProcessSingleFile(const FileName: string);
    procedure ProcessDirectory(const DirPath: string);
    function CreateBackupFile(const FileName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    function Execute: Integer; // 返回错误码：0=成功，1=错误
    
    property Options: TCommandLineOptions read FOptions;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils;

const
  APP_VERSION = '1.2.0';
  APP_NAME = 'TransSuccess';

{ TCommandLineController }

constructor TCommandLineController.Create;
begin
  inherited Create;
  FConverter := TEncodingConverter_Improved.Create;
  FSuccessCount := 0;
  FFailureCount := 0;
  
  // 初始化默认选项
  FOptions.SourceEncoding := 'auto'; // 自动检测
  FOptions.TargetEncoding := 'UTF-8';
  FOptions.Recursive := False;
  FOptions.CreateBackup := False;
  FOptions.Verbose := False;
  FOptions.Quiet := False;
  FOptions.AddBOM := False;
  FOptions.RemoveBOM := False;
  FOptions.ShowHelp := False;
  FOptions.ShowVersion := False;
end;

destructor TCommandLineController.Destroy;
begin
  FConverter.Free;
  inherited;
end;

procedure TCommandLineController.ParseCommandLine;
var
  I: Integer;
  Param, NextParam: string;
begin
  I := 1;
  while I <= ParamCount do
  begin
    Param := ParamStr(I);
    
    // 获取下一个参数（如果存在）
    if I < ParamCount then
      NextParam := ParamStr(I + 1)
    else
      NextParam := '';
    
    // 解析参数
    if (Param = '-h') or (Param = '--help') or (Param = '/?') then
    begin
      FOptions.ShowHelp := True;
      Inc(I);
    end
    else if (Param = '-v') or (Param = '--version') then
    begin
      FOptions.ShowVersion := True;
      Inc(I);
    end
    else if (Param = '-s') or (Param = '--source') then
    begin
      FOptions.SourceEncoding := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-t') or (Param = '--target') then
    begin
      FOptions.TargetEncoding := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-o') or (Param = '--output') then
    begin
      FOptions.OutputFile := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-r') or (Param = '--recursive') then
    begin
      FOptions.Recursive := True;
      Inc(I);
    end
    else if (Param = '-b') or (Param = '--backup') then
    begin
      FOptions.CreateBackup := True;
      Inc(I);
    end
    else if (Param = '--verbose') then
    begin
      FOptions.Verbose := True;
      Inc(I);
    end
    else if (Param = '-q') or (Param = '--quiet') then
    begin
      FOptions.Quiet := True;
      Inc(I);
    end
    else if (Param = '--add-bom') then
    begin
      FOptions.AddBOM := True;
      Inc(I);
    end
    else if (Param = '--remove-bom') then
    begin
      FOptions.RemoveBOM := True;
      Inc(I);
    end
    else if not StartsText('-', Param) then
    begin
      // 非选项参数，作为输入文件
      if FOptions.InputFile = '' then
        FOptions.InputFile := Param;
      Inc(I);
    end
    else
    begin
      WriteOutput('未知参数: ' + Param, True);
      Inc(I);
    end;
  end;
end;

procedure TCommandLineController.ShowHelp;
begin
  WriteLn('用法: ' + APP_NAME + '.exe [选项] <输入文件或目录>');
  WriteLn('');
  WriteLn('编码转换工具 - 支持多种字符编码互转');
  WriteLn('');
  WriteLn('选项:');
  WriteLn('  -s, --source <编码>     源编码 (默认: auto - 自动检测)');
  WriteLn('  -t, --target <编码>     目标编码 (默认: UTF-8)');
  WriteLn('  -o, --output <文件>     输出文件 (默认: 覆盖原文件)');
  WriteLn('  -r, --recursive         递归处理目录');
  WriteLn('  -b, --backup            转换前创建备份文件(.bak)');
  WriteLn('  -q, --quiet             安静模式，不显示输出');
  WriteLn('  --verbose               显示详细信息');
  WriteLn('  --add-bom               添加 BOM (仅UTF-8/UTF-16)');
  WriteLn('  --remove-bom            移除 BOM');
  WriteLn('  -h, --help, /?          显示此帮助信息');
  WriteLn('  -v, --version           显示版本信息');
  WriteLn('');
  WriteLn('支持的编码:');
  WriteLn('  Unicode:   UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE');
  WriteLn('  中文:      GBK, GB2312, GB18030, Big5');
  WriteLn('  日文:      Shift-JIS, EUC-JP, ISO-2022-JP');
  WriteLn('  韩文:      EUC-KR, JOHAB');
  WriteLn('  其他:      Windows-1252, ISO-8859-1, ASCII 等');
  WriteLn('  使用代码页: 936, 950, 65001, 1200 等');
  WriteLn('');
  WriteLn('示例:');
  WriteLn('  # 单文件转换 (GBK -> UTF-8)');
  WriteLn('  ' + APP_NAME + '.exe -s GBK -t UTF-8 input.txt');
  WriteLn('');
  WriteLn('  # 转换并输出到新文件');
  WriteLn('  ' + APP_NAME + '.exe -s auto -t UTF-8 input.txt -o output.txt');
  WriteLn('');
  WriteLn('  # 递归转换目录（带备份）');
  WriteLn('  ' + APP_NAME + '.exe -s GBK -t UTF-8 -r -b C:\MyFiles\');
  WriteLn('');
  WriteLn('  # Big5 转 UTF-8 (添加BOM)');
  WriteLn('  ' + APP_NAME + '.exe -s Big5 -t UTF-8 --add-bom input.txt');
  WriteLn('');
  WriteLn('  # 使用代码页转换');
  WriteLn('  ' + APP_NAME + '.exe -s 936 -t 65001 input.txt');
end;

procedure TCommandLineController.ShowVersion;
begin
  WriteLn(APP_NAME + ' v' + APP_VERSION);
  WriteLn('文件编码转换工具');
  WriteLn('Copyright (c) 2025 TransSuccess Team');
end;

procedure TCommandLineController.WriteOutput(const Msg: string; IsError: Boolean);
begin
  if FOptions.Quiet then
    Exit;
    
  if IsError then
    WriteLn(ErrOutput, '[错误] ' + Msg)
  else
    WriteLn(Msg);
end;

function TCommandLineController.CreateBackupFile(const FileName: string): Boolean;
var
  BackupFileName: string;
begin
  Result := False;
  BackupFileName := FileName + '.bak';
  
  try
    TFile.Copy(FileName, BackupFileName, True);
    if FOptions.Verbose then
      WriteOutput('已创建备份: ' + BackupFileName);
    Result := True;
  except
    on E: Exception do
      WriteOutput('创建备份失败: ' + E.Message, True);
  end;
end;

procedure TCommandLineController.ProcessSingleFile(const FileName: string);
var
  ConvResult: TEncodingConversionResult;
  ConvOptions: TEncodingConversionOptions;
  OutputFileName: string;
begin
  if not FileExists(FileName) then
  begin
    WriteOutput('文件不存在: ' + FileName, True);
    Inc(FFailureCount);
    Exit;
  end;
  
  if FOptions.Verbose then
    WriteOutput('处理文件: ' + FileName);
  
  // 创建备份
  if FOptions.CreateBackup then
    CreateBackupFile(FileName);
  
  // 设置转换选项
  ConvOptions := TEncodingConverter_Improved.CreateDefaultOptions;
  ConvOptions.AddBOM := FOptions.AddBOM;
  // 注：RemoveBOM 功能需要通过 TargetEncoding 配置
  ConvOptions.ErrorHandling := eehsSkip; // 跳过错误字符
  
  // 确定输出文件名
  if FOptions.OutputFile <> '' then
    OutputFileName := FOptions.OutputFile
  else
    OutputFileName := FileName;
  
  try
    // 执行转换
    ConvResult := FConverter.ConvertFile(
      FileName,
      OutputFileName,
      FOptions.SourceEncoding,
      FOptions.TargetEncoding,
      ConvOptions
    );
    
    if ConvResult.Success then
    begin
      Inc(FSuccessCount);
      if FOptions.Verbose then
        WriteOutput(Format('✓ 成功: %s -> %s (%d 字节)', 
          [ConvResult.SourceEncoding, ConvResult.TargetEncoding, ConvResult.BytesProcessed]));
    end
    else
    begin
      Inc(FFailureCount);
      // 从错误列表中获取错误信息
      if ConvResult.ErrorCount > 0 then
        WriteOutput(Format('✗ 失败: %s - %s', [FileName, ConvResult.Errors[0].ErrorMessage]), True)
      else
        WriteOutput(Format('✗ 失败: %s - 转换失败', [FileName]), True);
    end;
  except
    on E: Exception do
    begin
      Inc(FFailureCount);
      WriteOutput(Format('✗ 异常: %s - %s', [FileName, E.Message]), True);
    end;
  end;
end;

procedure TCommandLineController.ProcessDirectory(const DirPath: string);
var
  Files: TArray<string>;
  FileName: string;
  SearchOption: TSearchOption;
begin
  if not DirectoryExists(DirPath) then
  begin
    WriteOutput('目录不存在: ' + DirPath, True);
    Exit;
  end;
  
  if FOptions.Verbose then
    WriteOutput('扫描目录: ' + DirPath);
  
  // 确定搜索选项
  if FOptions.Recursive then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
  
  // 获取所有文件
  try
    Files := TDirectory.GetFiles(DirPath, '*.*', SearchOption);
    
    if Length(Files) = 0 then
    begin
      WriteOutput('目录中没有文件');
      Exit;
    end;
    
    WriteOutput(Format('找到 %d 个文件', [Length(Files)]));
    
    // 处理每个文件
    for FileName in Files do
    begin
      // 跳过备份文件
      if EndsText('.bak', FileName) then
        Continue;
        
      ProcessSingleFile(FileName);
    end;
  except
    on E: Exception do
      WriteOutput('扫描目录失败: ' + E.Message, True);
  end;
end;

function TCommandLineController.Execute: Integer;
begin
  Result := 0; // 默认成功
  
  // 解析命令行参数
  ParseCommandLine;
  
  // 显示帮助或版本
  if FOptions.ShowHelp then
  begin
    ShowHelp;
    Exit;
  end;
  
  if FOptions.ShowVersion then
  begin
    ShowVersion;
    Exit;
  end;
  
  // 检查必要参数
  if FOptions.InputFile = '' then
  begin
    WriteOutput('错误: 未指定输入文件或目录', True);
    WriteOutput('使用 --help 查看帮助信息', True);
    Result := 1;
    Exit;
  end;
  
  // 处理输入
  if DirectoryExists(FOptions.InputFile) then
  begin
    // 处理目录
    ProcessDirectory(FOptions.InputFile);
  end
  else if FileExists(FOptions.InputFile) then
  begin
    // 处理单个文件
    ProcessSingleFile(FOptions.InputFile);
  end
  else
  begin
    WriteOutput('错误: 文件或目录不存在: ' + FOptions.InputFile, True);
    Result := 1;
    Exit;
  end;
  
  // 显示统计信息
  if not FOptions.Quiet then
  begin
    WriteLn('');
    WriteLn('转换完成:');
    WriteLn(Format('  成功: %d', [FSuccessCount]));
    WriteLn(Format('  失败: %d', [FFailureCount]));
  end;
  
  // 如果有失败，返回错误码
  if FFailureCount > 0 then
    Result := 1;
end;

end.
