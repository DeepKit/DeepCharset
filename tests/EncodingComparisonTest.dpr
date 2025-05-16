program EncodingComparisonTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  TestEncodingConfig in 'TestEncodingConfig.pas',
  TestStandardSamples in 'TestStandardSamples.pas',
  TestStandardSamplesGenerator in 'TestStandardSamplesGenerator.pas';

procedure GenerateStandardSamples;
var
  SamplesManager: TStandardSamplesManager;
  Generator: TStandardSamplesGenerator;
  OutputDir: string;
begin
  OutputDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SampleFiles');
  ForceDirectories(OutputDir);
  
  Writeln('正在生成标准测试样本...');
  Writeln('输出目录: ', OutputDir);
  
  SamplesManager := TStandardSamplesManager.Create(OutputDir);
  try
    Generator := TStandardSamplesGenerator.Create(SamplesManager, OutputDir);
    try
      Generator.GenerateAllSamples;
      Writeln('生成完成，共生成样本文件: ', SamplesManager.Samples.Count);
    finally
      Generator.Free;
    end;
  finally
    SamplesManager.Free;
  end;
end;

procedure ShowUsage;
begin
  Writeln('使用方法:');
  Writeln('  EncodingComparisonTest [命令] [参数]');
  Writeln('');
  Writeln('命令:');
  Writeln('  gensample   - 生成标准测试样本');
  Writeln('  createtest  - 创建测试配置');
  Writeln('  runtest     - 执行测试');
  Writeln('  help        - 显示帮助信息');
  Writeln('');
  Writeln('示例:');
  Writeln('  EncodingComparisonTest gensample');
end;

var
  Command: string;
begin
  try
    if ParamCount = 0 then
    begin
      ShowUsage;
      Exit;
    end;
    
    Command := ParamStr(1).ToLower;
    
    if Command = 'gensample' then
      GenerateStandardSamples
    else if Command = 'createtest' then
      Writeln('创建测试配置功能尚未实现')
    else if Command = 'runtest' then
      Writeln('执行测试功能尚未实现')
    else if Command = 'help' then
      ShowUsage
    else
      Writeln('未知命令: ', Command);
      
    Writeln('按任意键继续...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end. 