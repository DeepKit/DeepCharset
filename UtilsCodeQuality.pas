unit UtilsCodeQuality;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections;

type
  /// <summary>
  /// 代码质量问题类型
  /// </summary>
  TCodeQualityIssueType = (
    cqitError,           // 错误
    cqitWarning,         // 警告
    cqitSuggestion,      // 建议
    cqitInfo             // 信息
  );

  /// <summary>
  /// 代码质量问题
  /// </summary>
  TCodeQualityIssue = record
    IssueType: TCodeQualityIssueType;
    FileName: string;
    LineNumber: Integer;
    ColumnNumber: Integer;
    Message: string;
    Rule: string;
    Severity: Integer;  // 1-10, 10最严重
    
    function ToString: string;
    function GetSeverityText: string;
  end;

  /// <summary>
  /// 代码质量检查结果
  /// </summary>
  TCodeQualityResult = record
    TotalFiles: Integer;
    ProcessedFiles: Integer;
    Issues: TArray<TCodeQualityIssue>;
    ErrorCount: Integer;
    WarningCount: Integer;
    SuggestionCount: Integer;
    InfoCount: Integer;
    
    procedure AddIssue(const Issue: TCodeQualityIssue);
    function GetSummary: string;
    function GetIssuesByType(IssueType: TCodeQualityIssueType): TArray<TCodeQualityIssue>;
  end;

  /// <summary>
  /// 代码质量检查器
  /// </summary>
  TCodeQualityChecker = class
  private
    FLogCallback: TProc<string>;
    FFileExtensions: TArray<string>;
    
    function CheckPascalFile(const FileName: string): TArray<TCodeQualityIssue>;
    function CheckForCommonIssues(const FileName: string; const Content: string): TArray<TCodeQualityIssue>;
    function CheckForMemoryLeaks(const Content: string): TArray<TCodeQualityIssue>;
    function CheckForPerformanceIssues(const Content: string): TArray<TCodeQualityIssue>;
    function CheckForSecurityIssues(const Content: string): TArray<TCodeQualityIssue>;
    function CheckForMaintainabilityIssues(const Content: string): TArray<TCodeQualityIssue>;
    
    function GetLineNumber(const Content: string; Position: Integer): Integer;
    function CreateIssue(IssueType: TCodeQualityIssueType; const FileName: string; 
      LineNumber: Integer; const Message, Rule: string; Severity: Integer = 5): TCodeQualityIssue;
    
  public
    constructor Create(LogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 设置要检查的文件扩展名
    /// </summary>
    procedure SetFileExtensions(const Extensions: TArray<string>);
    
    /// <summary>
    /// 检查单个文件
    /// </summary>
    function CheckFile(const FileName: string): TArray<TCodeQualityIssue>;
    
    /// <summary>
    /// 检查目录中的所有文件
    /// </summary>
    function CheckDirectory(const DirPath: string; Recursive: Boolean = True): TCodeQualityResult;
    
    /// <summary>
    /// 生成HTML报告
    /// </summary>
    function GenerateHTMLReport(const Result: TCodeQualityResult; const OutputFile: string): Boolean;
  end;

implementation

{ TCodeQualityIssue }

function TCodeQualityIssue.ToString: string;
begin
  Result := Format('%s(%d,%d): %s [%s] %s (严重度: %d)',
    [ExtractFileName(FileName), LineNumber, ColumnNumber, 
     GetSeverityText, Rule, Message, Severity]);
end;

function TCodeQualityIssue.GetSeverityText: string;
begin
  case IssueType of
    cqitError: Result := '错误';
    cqitWarning: Result := '警告';
    cqitSuggestion: Result := '建议';
    cqitInfo: Result := '信息';
  else
    Result := '未知';
  end;
end;

{ TCodeQualityResult }

procedure TCodeQualityResult.AddIssue(const Issue: TCodeQualityIssue);
begin
  SetLength(Issues, Length(Issues) + 1);
  Issues[High(Issues)] := Issue;
  
  case Issue.IssueType of
    cqitError: Inc(ErrorCount);
    cqitWarning: Inc(WarningCount);
    cqitSuggestion: Inc(SuggestionCount);
    cqitInfo: Inc(InfoCount);
  end;
end;

function TCodeQualityResult.GetSummary: string;
begin
  Result := Format('代码质量检查完成: 处理文件 %d/%d, 问题总数 %d (错误: %d, 警告: %d, 建议: %d, 信息: %d)',
    [ProcessedFiles, TotalFiles, Length(Issues), ErrorCount, WarningCount, SuggestionCount, InfoCount]);
end;

function TCodeQualityResult.GetIssuesByType(IssueType: TCodeQualityIssueType): TArray<TCodeQualityIssue>;
var
  Issue: TCodeQualityIssue;
  FilteredIssues: TList<TCodeQualityIssue>;
begin
  FilteredIssues := TList<TCodeQualityIssue>.Create;
  try
    for Issue in Issues do
    begin
      if Issue.IssueType = IssueType then
        FilteredIssues.Add(Issue);
    end;
    Result := FilteredIssues.ToArray;
  finally
    FilteredIssues.Free;
  end;
end;

{ TCodeQualityChecker }

constructor TCodeQualityChecker.Create(LogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := LogCallback;
  // 默认检查Pascal文件
  FFileExtensions := ['.pas', '.dpr', '.dpk', '.inc'];
end;

procedure TCodeQualityChecker.SetFileExtensions(const Extensions: TArray<string>);
begin
  FFileExtensions := Extensions;
end;

function TCodeQualityChecker.CreateIssue(IssueType: TCodeQualityIssueType; const FileName: string; 
  LineNumber: Integer; const Message, Rule: string; Severity: Integer): TCodeQualityIssue;
begin
  Result.IssueType := IssueType;
  Result.FileName := FileName;
  Result.LineNumber := LineNumber;
  Result.ColumnNumber := 1;
  Result.Message := Message;
  Result.Rule := Rule;
  Result.Severity := Severity;
end;

function TCodeQualityChecker.GetLineNumber(const Content: string; Position: Integer): Integer;
var
  I: Integer;
begin
  Result := 1;
  for I := 1 to Min(Position, Length(Content)) do
  begin
    if Content[I] = #10 then
      Inc(Result);
  end;
end;

function TCodeQualityChecker.CheckFile(const FileName: string): TArray<TCodeQualityIssue>;
var
  Ext: string;
begin
  SetLength(Result, 0);
  
  if not FileExists(FileName) then
    Exit;
    
  Ext := LowerCase(ExtractFileExt(FileName));
  
  // 检查是否是支持的文件类型
  var IsSupported := False;
  for var SupportedExt in FFileExtensions do
  begin
    if Ext = LowerCase(SupportedExt) then
    begin
      IsSupported := True;
      Break;
    end;
  end;
  
  if not IsSupported then
    Exit;
    
  // 根据文件类型进行检查
  if (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.dpk') or (Ext = '.inc') then
    Result := CheckPascalFile(FileName);
end;

function TCodeQualityChecker.CheckPascalFile(const FileName: string): TArray<TCodeQualityIssue>;
var
  Content: string;
  Issues: TList<TCodeQualityIssue>;
  CommonIssues, MemoryIssues, PerfIssues, SecurityIssues, MaintainIssues: TArray<TCodeQualityIssue>;
  Issue: TCodeQualityIssue;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    try
      Content := TFile.ReadAllText(FileName, TEncoding.UTF8);
    except
      on E: Exception do
      begin
        Issues.Add(CreateIssue(cqitError, FileName, 1, '无法读取文件: ' + E.Message, 'FILE_READ_ERROR', 10));
        Result := Issues.ToArray;
        Exit;
      end;
    end;
    
    // 执行各种检查
    CommonIssues := CheckForCommonIssues(FileName, Content);
    MemoryIssues := CheckForMemoryLeaks(Content);
    PerfIssues := CheckForPerformanceIssues(Content);
    SecurityIssues := CheckForSecurityIssues(Content);
    MaintainIssues := CheckForMaintainabilityIssues(Content);
    
    // 合并所有问题
    for Issue in CommonIssues do Issues.Add(Issue);
    for Issue in MemoryIssues do Issues.Add(Issue);
    for Issue in PerfIssues do Issues.Add(Issue);
    for Issue in SecurityIssues do Issues.Add(Issue);
    for Issue in MaintainIssues do Issues.Add(Issue);
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckForCommonIssues(const FileName: string; const Content: string): TArray<TCodeQualityIssue>;
var
  Issues: TList<TCodeQualityIssue>;
  Lines: TStringList;
  I: Integer;
  Line: string;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    Lines := TStringList.Create;
    try
      Lines.Text := Content;
      
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Lines[I];
        
        // 检查长行
        if Length(Line) > 120 then
          Issues.Add(CreateIssue(cqitSuggestion, FileName, I + 1, 
            Format('行太长 (%d 字符), 建议不超过 120 字符', [Length(Line)]), 'LONG_LINE', 3));
        
        // 检查制表符
        if Pos(#9, Line) > 0 then
          Issues.Add(CreateIssue(cqitSuggestion, FileName, I + 1, 
            '使用制表符，建议使用空格', 'TAB_USAGE', 2));
        
        // 检查行尾空格
        if (Length(Line) > 0) and (Line[Length(Line)] = ' ') then
          Issues.Add(CreateIssue(cqitSuggestion, FileName, I + 1, 
            '行尾有多余空格', 'TRAILING_SPACE', 1));
        
        // 检查TODO注释
        if ContainsText(Line, 'TODO') or ContainsText(Line, 'FIXME') or ContainsText(Line, 'HACK') then
          Issues.Add(CreateIssue(cqitInfo, FileName, I + 1, 
            '包含待办事项注释', 'TODO_COMMENT', 2));
      end;
      
    finally
      Lines.Free;
    end;
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckForMemoryLeaks(const Content: string): TArray<TCodeQualityIssue>;
var
  Issues: TList<TCodeQualityIssue>;
  CreatePos, FreePos: Integer;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    // 检查Create/Free配对
    CreatePos := Pos('.Create', UpperCase(Content));
    while CreatePos > 0 do
    begin
      // 简单检查：在Create后是否有对应的Free
      FreePos := PosEx('.Free', UpperCase(Content), CreatePos);
      if FreePos = 0 then
      begin
        Issues.Add(CreateIssue(cqitWarning, '', GetLineNumber(Content, CreatePos), 
          '可能的内存泄漏：Create后没有找到对应的Free', 'MEMORY_LEAK', 8));
      end;
      
      CreatePos := PosEx('.Create', UpperCase(Content), CreatePos + 1);
    end;
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckForPerformanceIssues(const Content: string): TArray<TCodeQualityIssue>;
var
  Issues: TList<TCodeQualityIssue>;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    // 检查字符串连接
    if Pos(' + ', Content) > 0 then
    begin
      var StringConcatCount := 0;
      var Pos := 1;
      while Pos > 0 do
      begin
        Pos := PosEx(' + ', Content, Pos + 1);
        if Pos > 0 then
          Inc(StringConcatCount);
      end;
      
      if StringConcatCount > 5 then
        Issues.Add(CreateIssue(cqitSuggestion, '', 1, 
          Format('大量字符串连接操作 (%d 处)，考虑使用StringBuilder', [StringConcatCount]), 
          'STRING_CONCAT', 4));
    end;
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckForSecurityIssues(const Content: string): TArray<TCodeQualityIssue>;
var
  Issues: TList<TCodeQualityIssue>;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    // 检查SQL注入风险
    if ContainsText(Content, 'SELECT') and ContainsText(Content, '+') then
      Issues.Add(CreateIssue(cqitWarning, '', 1, 
        '可能的SQL注入风险：使用字符串拼接构建SQL', 'SQL_INJECTION', 9));
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckForMaintainabilityIssues(const Content: string): TArray<TCodeQualityIssue>;
var
  Issues: TList<TCodeQualityIssue>;
  Lines: TStringList;
  ProcedureCount, FunctionCount: Integer;
begin
  Issues := TList<TCodeQualityIssue>.Create;
  try
    Lines := TStringList.Create;
    try
      Lines.Text := Content;
      
      // 计算方法数量
      ProcedureCount := 0;
      FunctionCount := 0;
      
      for var Line in Lines do
      begin
        if StartsText('procedure ', Trim(Line)) then
          Inc(ProcedureCount);
        if StartsText('function ', Trim(Line)) then
          Inc(FunctionCount);
      end;
      
      var TotalMethods := ProcedureCount + FunctionCount;
      if TotalMethods > 50 then
        Issues.Add(CreateIssue(cqitSuggestion, '', 1, 
          Format('文件包含过多方法 (%d 个)，考虑拆分', [TotalMethods]), 
          'TOO_MANY_METHODS', 6));
      
      // 检查文件大小
      if Lines.Count > 1000 then
        Issues.Add(CreateIssue(cqitSuggestion, '', 1, 
          Format('文件过大 (%d 行)，考虑拆分', [Lines.Count]), 
          'LARGE_FILE', 5));
      
    finally
      Lines.Free;
    end;
    
    Result := Issues.ToArray;
  finally
    Issues.Free;
  end;
end;

function TCodeQualityChecker.CheckDirectory(const DirPath: string; Recursive: Boolean): TCodeQualityResult;
var
  Files: TArray<string>;
  FileName: string;
  FileIssues: TArray<TCodeQualityIssue>;
  Issue: TCodeQualityIssue;
  SearchOption: TSearchOption;
begin
  // 初始化结果
  Result.TotalFiles := 0;
  Result.ProcessedFiles := 0;
  Result.ErrorCount := 0;
  Result.WarningCount := 0;
  Result.SuggestionCount := 0;
  Result.InfoCount := 0;
  SetLength(Result.Issues, 0);
  
  if not DirectoryExists(DirPath) then
    Exit;
    
  if Recursive then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
  
  // 获取所有支持的文件
  for var Ext in FFileExtensions do
  begin
    var ExtFiles := TDirectory.GetFiles(DirPath, '*' + Ext, SearchOption);
    for var ExtFile in ExtFiles do
    begin
      SetLength(Files, Length(Files) + 1);
      Files[High(Files)] := ExtFile;
    end;
  end;
  
  Result.TotalFiles := Length(Files);
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始检查 %d 个文件...', [Result.TotalFiles]));
  
  // 检查每个文件
  for FileName in Files do
  begin
    try
      FileIssues := CheckFile(FileName);
      
      for Issue in FileIssues do
        Result.AddIssue(Issue);
        
      Inc(Result.ProcessedFiles);
      
      if Assigned(FLogCallback) and (Result.ProcessedFiles mod 10 = 0) then
        FLogCallback(Format('已处理 %d/%d 文件...', [Result.ProcessedFiles, Result.TotalFiles]));
        
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback(Format('检查文件 %s 时出错: %s', [FileName, E.Message]));
      end;
    end;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback(Result.GetSummary);
end;

function TCodeQualityChecker.GenerateHTMLReport(const Result: TCodeQualityResult; const OutputFile: string): Boolean;
var
  HTML: TStringList;
  Issue: TCodeQualityIssue;
begin
  HTML := TStringList.Create;
  try
    HTML.Add('<!DOCTYPE html>');
    HTML.Add('<html><head><title>代码质量检查报告</title>');
    HTML.Add('<style>');
    HTML.Add('body { font-family: Arial, sans-serif; margin: 20px; }');
    HTML.Add('.summary { background: #f0f0f0; padding: 10px; margin-bottom: 20px; }');
    HTML.Add('.error { color: red; }');
    HTML.Add('.warning { color: orange; }');
    HTML.Add('.suggestion { color: blue; }');
    HTML.Add('.info { color: green; }');
    HTML.Add('table { border-collapse: collapse; width: 100%; }');
    HTML.Add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    HTML.Add('th { background-color: #f2f2f2; }');
    HTML.Add('</style></head><body>');
    
    HTML.Add('<h1>代码质量检查报告</h1>');
    HTML.Add('<div class="summary">');
    HTML.Add('<h2>摘要</h2>');
    HTML.Add(Format('<p>处理文件: %d/%d</p>', [Result.ProcessedFiles, Result.TotalFiles]));
    HTML.Add(Format('<p>问题总数: %d</p>', [Length(Result.Issues)]));
    HTML.Add(Format('<p>错误: %d, 警告: %d, 建议: %d, 信息: %d</p>', 
      [Result.ErrorCount, Result.WarningCount, Result.SuggestionCount, Result.InfoCount]));
    HTML.Add('</div>');
    
    if Length(Result.Issues) > 0 then
    begin
      HTML.Add('<h2>详细问题</h2>');
      HTML.Add('<table>');
      HTML.Add('<tr><th>类型</th><th>文件</th><th>行号</th><th>规则</th><th>描述</th><th>严重度</th></tr>');
      
      for Issue in Result.Issues do
      begin
        var CssClass := '';
        case Issue.IssueType of
          cqitError: CssClass := 'error';
          cqitWarning: CssClass := 'warning';
          cqitSuggestion: CssClass := 'suggestion';
          cqitInfo: CssClass := 'info';
        end;
        
        HTML.Add(Format('<tr class="%s">', [CssClass]));
        HTML.Add(Format('<td>%s</td>', [Issue.GetSeverityText]));
        HTML.Add(Format('<td>%s</td>', [ExtractFileName(Issue.FileName)]));
        HTML.Add(Format('<td>%d</td>', [Issue.LineNumber]));
        HTML.Add(Format('<td>%s</td>', [Issue.Rule]));
        HTML.Add(Format('<td>%s</td>', [Issue.Message]));
        HTML.Add(Format('<td>%d</td>', [Issue.Severity]));
        HTML.Add('</tr>');
      end;
      
      HTML.Add('</table>');
    end;
    
    HTML.Add('</body></html>');
    
    try
      HTML.SaveToFile(OutputFile, TEncoding.UTF8);
      Result := True;
    except
      Result := False;
    end;
    
  finally
    HTML.Free;
  end;
end;

end.
