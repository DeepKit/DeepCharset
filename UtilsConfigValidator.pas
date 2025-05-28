unit UtilsConfigValidator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles, System.Generics.Collections;

type
  /// <summary>
  /// 配置验证结果
  /// </summary>
  TConfigValidationResult = record
    IsValid: Boolean;
    ErrorCount: Integer;
    WarningCount: Integer;
    Messages: TArray<string>;
    
    procedure AddError(const Message: string);
    procedure AddWarning(const Message: string);
    procedure AddInfo(const Message: string);
    function GetSummary: string;
  end;

  /// <summary>
  /// 配置验证器
  /// </summary>
  TConfigValidator = class
  private
    FLogCallback: TProc<string>;
    
    function ValidateIniFile(const FileName: string): TConfigValidationResult;
    function ValidateLanguageFiles(const LanguageDir: string): TConfigValidationResult;
    function ValidateEncodingSupport: TConfigValidationResult;
    function ValidateDirectoryStructure(const RootDir: string): TConfigValidationResult;
    
  public
    constructor Create(LogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 验证应用程序配置
    /// </summary>
    function ValidateApplicationConfig(const RootDir: string): TConfigValidationResult;
    
    /// <summary>
    /// 验证编码转换配置
    /// </summary>
    function ValidateEncodingConfig: TConfigValidationResult;
    
    /// <summary>
    /// 验证语言配置
    /// </summary>
    function ValidateLanguageConfig(const LanguageDir: string): TConfigValidationResult;
    
    /// <summary>
    /// 修复常见配置问题
    /// </summary>
    function RepairCommonIssues(const RootDir: string): TConfigValidationResult;
  end;

implementation

{ TConfigValidationResult }

procedure TConfigValidationResult.AddError(const Message: string);
begin
  Inc(ErrorCount);
  SetLength(Messages, Length(Messages) + 1);
  Messages[High(Messages)] := '[错误] ' + Message;
  IsValid := False;
end;

procedure TConfigValidationResult.AddWarning(const Message: string);
begin
  Inc(WarningCount);
  SetLength(Messages, Length(Messages) + 1);
  Messages[High(Messages)] := '[警告] ' + Message;
end;

procedure TConfigValidationResult.AddInfo(const Message: string);
begin
  SetLength(Messages, Length(Messages) + 1);
  Messages[High(Messages)] := '[信息] ' + Message;
end;

function TConfigValidationResult.GetSummary: string;
var
  Status: string;
begin
  if IsValid then
    Status := '通过'
  else
    Status := '失败';
    
  Result := Format('验证结果: %s (错误: %d, 警告: %d, 总消息: %d)',
    [Status, ErrorCount, WarningCount, Length(Messages)]);
end;

{ TConfigValidator }

constructor TConfigValidator.Create(LogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := LogCallback;
end;

function TConfigValidator.ValidateApplicationConfig(const RootDir: string): TConfigValidationResult;
var
  MainConfigFile: string;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  Result.AddInfo('开始验证应用程序配置...');
  
  // 验证根目录
  if not DirectoryExists(RootDir) then
  begin
    Result.AddError('根目录不存在: ' + RootDir);
    Exit;
  end;
  
  // 验证目录结构
  var DirResult := ValidateDirectoryStructure(RootDir);
  for var Msg in DirResult.Messages do
    SetLength(Result.Messages, Length(Result.Messages) + 1);
    Result.Messages[High(Result.Messages)] := Msg;
  Inc(Result.ErrorCount, DirResult.ErrorCount);
  Inc(Result.WarningCount, DirResult.WarningCount);
  if not DirResult.IsValid then
    Result.IsValid := False;
  
  // 验证主配置文件
  MainConfigFile := TPath.Combine(RootDir, 'TransSuccess.ini');
  if FileExists(MainConfigFile) then
  begin
    var IniResult := ValidateIniFile(MainConfigFile);
    for var Msg in IniResult.Messages do
      SetLength(Result.Messages, Length(Result.Messages) + 1);
      Result.Messages[High(Result.Messages)] := Msg;
    Inc(Result.ErrorCount, IniResult.ErrorCount);
    Inc(Result.WarningCount, IniResult.WarningCount);
    if not IniResult.IsValid then
      Result.IsValid := False;
  end
  else
    Result.AddWarning('主配置文件不存在: ' + MainConfigFile);
  
  // 验证语言文件
  var LanguageDir := TPath.Combine(RootDir, 'ini');
  if DirectoryExists(LanguageDir) then
  begin
    var LangResult := ValidateLanguageFiles(LanguageDir);
    for var Msg in LangResult.Messages do
      SetLength(Result.Messages, Length(Result.Messages) + 1);
      Result.Messages[High(Result.Messages)] := Msg;
    Inc(Result.ErrorCount, LangResult.ErrorCount);
    Inc(Result.WarningCount, LangResult.WarningCount);
    if not LangResult.IsValid then
      Result.IsValid := False;
  end
  else
    Result.AddError('语言目录不存在: ' + LanguageDir);
  
  Result.AddInfo('应用程序配置验证完成');
  
  if Assigned(FLogCallback) then
    FLogCallback(Result.GetSummary);
end;

function TConfigValidator.ValidateDirectoryStructure(const RootDir: string): TConfigValidationResult;
var
  RequiredDirs: TArray<string>;
  Dir: string;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  // 定义必需的目录
  RequiredDirs := ['ini', 'logs', 'config'];
  
  Result.AddInfo('验证目录结构...');
  
  for Dir in RequiredDirs do
  begin
    var FullPath := TPath.Combine(RootDir, Dir);
    if not DirectoryExists(FullPath) then
      Result.AddWarning('推荐目录不存在: ' + Dir);
  end;
  
  // 检查可写权限
  try
    var TestFile := TPath.Combine(RootDir, 'test_write_permission.tmp');
    TFile.WriteAllText(TestFile, 'test');
    if FileExists(TestFile) then
    begin
      DeleteFile(TestFile);
      Result.AddInfo('根目录具有写入权限');
    end;
  except
    on E: Exception do
      Result.AddError('根目录没有写入权限: ' + E.Message);
  end;
end;

function TConfigValidator.ValidateIniFile(const FileName: string): TConfigValidationResult;
var
  IniFile: TIniFile;
  Sections: TStringList;
  Section: string;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  Result.AddInfo('验证INI文件: ' + ExtractFileName(FileName));
  
  try
    IniFile := TIniFile.Create(FileName);
    try
      Sections := TStringList.Create;
      try
        IniFile.ReadSections(Sections);
        
        if Sections.Count = 0 then
          Result.AddWarning('INI文件没有任何节');
        
        for Section in Sections do
        begin
          var Keys := TStringList.Create;
          try
            IniFile.ReadSection(Section, Keys);
            if Keys.Count = 0 then
              Result.AddWarning(Format('节 [%s] 没有任何键值', [Section]));
          finally
            Keys.Free;
          end;
        end;
        
        Result.AddInfo(Format('INI文件包含 %d 个节', [Sections.Count]));
        
      finally
        Sections.Free;
      end;
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
      Result.AddError('无法读取INI文件: ' + E.Message);
  end;
end;

function TConfigValidator.ValidateLanguageFiles(const LanguageDir: string): TConfigValidationResult;
var
  Files: TArray<string>;
  FileName: string;
  RequiredLanguages: TArray<string>;
  Lang: string;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  Result.AddInfo('验证语言文件...');
  
  // 定义必需的语言文件
  RequiredLanguages := ['zh-CN.ini', 'en-US.ini'];
  
  Files := TDirectory.GetFiles(LanguageDir, '*.ini');
  Result.AddInfo(Format('找到 %d 个语言文件', [Length(Files)]));
  
  // 检查必需的语言文件
  for Lang in RequiredLanguages do
  begin
    var LangFile := TPath.Combine(LanguageDir, Lang);
    if not FileExists(LangFile) then
      Result.AddError('缺少必需的语言文件: ' + Lang)
    else
    begin
      // 验证语言文件内容
      var IniResult := ValidateIniFile(LangFile);
      if not IniResult.IsValid then
        Result.AddWarning('语言文件可能有问题: ' + Lang);
    end;
  end;
  
  // 验证每个语言文件
  for FileName in Files do
  begin
    if not FileExists(FileName) then
      Continue;
      
    try
      var IniResult := ValidateIniFile(FileName);
      if not IniResult.IsValid then
        Result.AddWarning('语言文件验证失败: ' + ExtractFileName(FileName));
    except
      on E: Exception do
        Result.AddError('验证语言文件时出错: ' + ExtractFileName(FileName) + ' - ' + E.Message);
    end;
  end;
end;

function TConfigValidator.ValidateEncodingSupport: TConfigValidationResult;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  Result.AddInfo('验证编码支持...');
  
  // 检查系统编码支持
  try
    var TestUTF8 := TEncoding.UTF8;
    var TestUTF16 := TEncoding.Unicode;
    var TestANSI := TEncoding.Default;
    
    if Assigned(TestUTF8) and Assigned(TestUTF16) and Assigned(TestANSI) then
      Result.AddInfo('基本编码支持正常')
    else
      Result.AddError('基本编码支持异常');
      
  except
    on E: Exception do
      Result.AddError('编码支持检查失败: ' + E.Message);
  end;
end;

function TConfigValidator.ValidateEncodingConfig: TConfigValidationResult;
begin
  Result := ValidateEncodingSupport;
end;

function TConfigValidator.ValidateLanguageConfig(const LanguageDir: string): TConfigValidationResult;
begin
  Result := ValidateLanguageFiles(LanguageDir);
end;

function TConfigValidator.RepairCommonIssues(const RootDir: string): TConfigValidationResult;
var
  RequiredDirs: TArray<string>;
  Dir: string;
begin
  // 初始化结果
  Result.IsValid := True;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  SetLength(Result.Messages, 0);
  
  Result.AddInfo('开始修复常见问题...');
  
  // 创建必需的目录
  RequiredDirs := ['ini', 'logs', 'config'];
  
  for Dir in RequiredDirs do
  begin
    var FullPath := TPath.Combine(RootDir, Dir);
    if not DirectoryExists(FullPath) then
    begin
      try
        ForceDirectories(FullPath);
        Result.AddInfo('创建目录: ' + Dir);
      except
        on E: Exception do
          Result.AddError('无法创建目录 ' + Dir + ': ' + E.Message);
      end;
    end;
  end;
  
  Result.AddInfo('常见问题修复完成');
  
  if Assigned(FLogCallback) then
    FLogCallback(Result.GetSummary);
end;

end.
