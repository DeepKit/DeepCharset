unit TestEncodingConfig;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON, System.IOUtils;

type
  /// <summary>
  /// 编码测试配置类型
  /// </summary>
  TEncodingTestType = (
    ettDetection,   // 编码检测测试
    ettConversion,  // 编码转换测试
    ettComparison,  // 编码对比测试
    ettPerformance, // 性能测试
    ettRoundTrip,   // 往返转换测试
    ettBoundary     // 边界情况测试
  );

  /// <summary>
  /// 编码对比工具类型
  /// </summary>
  TComparisonToolType = (
    cttWindows,     // Windows API
    cttIconv,       // iconv工具
    cttICU,         // ICU库
    cttPython,      // Python编码模块
    cttOnline,      // 在线编码工具
    cttCustom       // 自定义工具
  );

  /// <summary>
  /// 测试配置项
  /// </summary>
  TTestConfigItem = class
  private
    FName: string;
    FDescription: string;
    FEnabled: Boolean;
    FPriority: Integer;
    FTags: TArray<string>;
  public
    constructor Create; virtual;
    procedure LoadFromJSON(AJson: TJSONObject); virtual;
    function SaveToJSON: TJSONObject; virtual;

    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Priority: Integer read FPriority write FPriority;
    property Tags: TArray<string> read FTags write FTags;
  end;

  /// <summary>
  /// 编码测试文件配置
  /// </summary>
  TTestFileConfig = class(TTestConfigItem)
  private
    FFilePath: string;
    FSourceEncoding: string;
    FExpectedEncoding: string;
    FFileType: string;
    FLanguage: string;
    FHasBOM: Boolean;
    FFileSize: Int64;
    FCreatedDate: TDateTime;
    FModifiedDate: TDateTime;
  public
    constructor Create; override;
    procedure LoadFromJSON(AJson: TJSONObject); override;
    function SaveToJSON: TJSONObject; override;
    
    // 检查文件是否存在且可访问
    function IsFileAccessible: Boolean;
    
    // 获取文件信息
    procedure UpdateFileInfo;

    property FilePath: string read FFilePath write FFilePath;
    property SourceEncoding: string read FSourceEncoding write FSourceEncoding;
    property ExpectedEncoding: string read FExpectedEncoding write FExpectedEncoding;
    property FileType: string read FFileType write FFileType;
    property Language: string read FLanguage write FLanguage;
    property HasBOM: Boolean read FHasBOM write FHasBOM;
    property FileSize: Int64 read FFileSize;
    property CreatedDate: TDateTime read FCreatedDate;
    property ModifiedDate: TDateTime read FModifiedDate;
  end;

  /// <summary>
  /// 编码转换测试配置
  /// </summary>
  TConversionTestConfig = class(TTestConfigItem)
  private
    FSourceEncoding: string;
    FTargetEncoding: string;
    FWithBOM: Boolean;
    FTestFiles: TObjectList<TTestFileConfig>;
    FExpectedSuccess: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromJSON(AJson: TJSONObject); override;
    function SaveToJSON: TJSONObject; override;
    
    // 添加测试文件
    procedure AddTestFile(ATestFile: TTestFileConfig);
    
    // 移除测试文件
    procedure RemoveTestFile(AIndex: Integer);
    
    // 清空测试文件
    procedure ClearTestFiles;

    property SourceEncoding: string read FSourceEncoding write FSourceEncoding;
    property TargetEncoding: string read FTargetEncoding write FTargetEncoding;
    property WithBOM: Boolean read FWithBOM write FWithBOM;
    property TestFiles: TObjectList<TTestFileConfig> read FTestFiles;
    property ExpectedSuccess: Boolean read FExpectedSuccess write FExpectedSuccess;
  end;

  /// <summary>
  /// 编码对比测试配置
  /// </summary>
  TComparisonTestConfig = class(TTestConfigItem)
  private
    FSourceEncoding: string;
    FTargetEncoding: string;
    FComparisonTools: TArray<TComparisonToolType>;
    FTestFiles: TObjectList<TTestFileConfig>;
    FTimeout: Integer; // 超时时间（毫秒）
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromJSON(AJson: TJSONObject); override;
    function SaveToJSON: TJSONObject; override;
    
    // 添加测试文件
    procedure AddTestFile(ATestFile: TTestFileConfig);
    
    // 移除测试文件
    procedure RemoveTestFile(AIndex: Integer);
    
    // 清空测试文件
    procedure ClearTestFiles;
    
    // 添加对比工具
    procedure AddComparisonTool(ATool: TComparisonToolType);
    
    // 移除对比工具
    procedure RemoveComparisonTool(ATool: TComparisonToolType);
    
    // 清空对比工具
    procedure ClearComparisonTools;

    property SourceEncoding: string read FSourceEncoding write FSourceEncoding;
    property TargetEncoding: string read FTargetEncoding write FTargetEncoding;
    property ComparisonTools: TArray<TComparisonToolType> read FComparisonTools write FComparisonTools;
    property TestFiles: TObjectList<TTestFileConfig> read FTestFiles;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

  /// <summary>
  /// 测试套件配置
  /// </summary>
  TTestSuiteConfig = class
  private
    FName: string;
    FDescription: string;
    FCreatedDate: TDateTime;
    FModifiedDate: TDateTime;
    FVersion: string;
    FAuthor: string;
    FConversionTests: TObjectList<TConversionTestConfig>;
    FComparisonTests: TObjectList<TComparisonTestConfig>;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 从JSON文件加载
    procedure LoadFromFile(const AFileName: string);
    
    // 保存到JSON文件
    procedure SaveToFile(const AFileName: string);
    
    // 从JSON对象加载
    procedure LoadFromJSON(AJson: TJSONObject);
    
    // 转换为JSON对象
    function SaveToJSON: TJSONObject;
    
    // 添加转换测试
    procedure AddConversionTest(ATest: TConversionTestConfig);
    
    // 移除转换测试
    procedure RemoveConversionTest(AIndex: Integer);
    
    // 清空转换测试
    procedure ClearConversionTests;
    
    // 添加对比测试
    procedure AddComparisonTest(ATest: TComparisonTestConfig);
    
    // 移除对比测试
    procedure RemoveComparisonTest(AIndex: Integer);
    
    // 清空对比测试
    procedure ClearComparisonTests;

    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property CreatedDate: TDateTime read FCreatedDate write FCreatedDate;
    property ModifiedDate: TDateTime read FModifiedDate write FModifiedDate;
    property Version: string read FVersion write FVersion;
    property Author: string read FAuthor write FAuthor;
    property ConversionTests: TObjectList<TConversionTestConfig> read FConversionTests;
    property ComparisonTests: TObjectList<TComparisonTestConfig> read FComparisonTests;
  end;

  /// <summary>
  /// 测试用例管理器
  /// </summary>
  TTestCaseManager = class
  private
    FSuites: TObjectList<TTestSuiteConfig>;
    FBasePath: string;
    
    // 获取测试用例文件路径
    function GetTestCaseFilePath(const ASuiteName: string): string;
  public
    constructor Create(const ABasePath: string = '');
    destructor Destroy; override;
    
    // 加载所有测试套件
    procedure LoadAllSuites;
    
    // 保存所有测试套件
    procedure SaveAllSuites;
    
    // 加载指定测试套件
    function LoadSuite(const ASuiteName: string): TTestSuiteConfig;
    
    // 保存指定测试套件
    procedure SaveSuite(ASuite: TTestSuiteConfig);
    
    // 创建新测试套件
    function CreateSuite(const ASuiteName: string): TTestSuiteConfig;
    
    // 删除测试套件
    procedure DeleteSuite(const ASuiteName: string);
    
    // 获取所有测试套件名称
    function GetAllSuiteNames: TArray<string>;
    
    // 检查测试套件是否存在
    function SuiteExists(const ASuiteName: string): Boolean;

    property BasePath: string read FBasePath write FBasePath;
    property Suites: TObjectList<TTestSuiteConfig> read FSuites;
  end;

implementation

{ TTestConfigItem }

constructor TTestConfigItem.Create;
begin
  FEnabled := True;
  FPriority := 0;
  SetLength(FTags, 0);
end;

procedure TTestConfigItem.LoadFromJSON(AJson: TJSONObject);
var
  TagArray: TJSONArray;
  I: Integer;
begin
  if AJson.TryGetValue<string>('name', FName) then;
  if AJson.TryGetValue<string>('description', FDescription) then;
  if AJson.TryGetValue<Boolean>('enabled', FEnabled) then;
  if AJson.TryGetValue<Integer>('priority', FPriority) then;
  
  if AJson.TryGetValue<TJSONArray>('tags', TagArray) then
  begin
    SetLength(FTags, TagArray.Count);
    for I := 0 to TagArray.Count - 1 do
      FTags[I] := TagArray.Items[I].Value;
  end;
end;

function TTestConfigItem.SaveToJSON: TJSONObject;
var
  TagArray: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', FName);
  Result.AddPair('description', FDescription);
  Result.AddPair('enabled', TJSONBool.Create(FEnabled));
  Result.AddPair('priority', TJSONNumber.Create(FPriority));
  
  TagArray := TJSONArray.Create;
  for I := 0 to High(FTags) do
    TagArray.Add(FTags[I]);
  
  Result.AddPair('tags', TagArray);
end;

{ TTestFileConfig }

constructor TTestFileConfig.Create;
begin
  inherited Create;
  FFileSize := 0;
  FCreatedDate := 0;
  FModifiedDate := 0;
  FHasBOM := False;
end;

function TTestFileConfig.IsFileAccessible: Boolean;
var
  FileHandle: THandle;
begin
  Result := False;
  
  if not FileExists(FFilePath) then
    Exit;
  
  try
    FileHandle := FileOpen(FFilePath, fmOpenRead or fmShareDenyNone);
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      FileClose(FileHandle);
      Result := True;
    end;
  except
    Result := False;
  end;
end;

procedure TTestFileConfig.LoadFromJSON(AJson: TJSONObject);
begin
  inherited LoadFromJSON(AJson);
  
  if AJson.TryGetValue<string>('filePath', FFilePath) then;
  if AJson.TryGetValue<string>('sourceEncoding', FSourceEncoding) then;
  if AJson.TryGetValue<string>('expectedEncoding', FExpectedEncoding) then;
  if AJson.TryGetValue<string>('fileType', FFileType) then;
  if AJson.TryGetValue<string>('language', FLanguage) then;
  if AJson.TryGetValue<Boolean>('hasBOM', FHasBOM) then;
  if AJson.TryGetValue<Int64>('fileSize', FFileSize) then;
  
  var CreatedStr: string;
  if AJson.TryGetValue<string>('createdDate', CreatedStr) then
    FCreatedDate := ISO8601ToDate(CreatedStr);
    
  var ModifiedStr: string;
  if AJson.TryGetValue<string>('modifiedDate', ModifiedStr) then
    FModifiedDate := ISO8601ToDate(ModifiedStr);
end;

function TTestFileConfig.SaveToJSON: TJSONObject;
begin
  Result := inherited SaveToJSON;
  
  Result.AddPair('filePath', FFilePath);
  Result.AddPair('sourceEncoding', FSourceEncoding);
  Result.AddPair('expectedEncoding', FExpectedEncoding);
  Result.AddPair('fileType', FFileType);
  Result.AddPair('language', FLanguage);
  Result.AddPair('hasBOM', TJSONBool.Create(FHasBOM));
  Result.AddPair('fileSize', TJSONNumber.Create(FFileSize));
  Result.AddPair('createdDate', DateToISO8601(FCreatedDate));
  Result.AddPair('modifiedDate', DateToISO8601(FModifiedDate));
end;

procedure TTestFileConfig.UpdateFileInfo;
var
  FileInfo: TWin32FileAttributeData;
begin
  if not FileExists(FFilePath) then
    Exit;
    
  // 获取文件大小
  FFileSize := TFile.GetSize(FFilePath);
  
  // 获取文件创建和修改日期
  if GetFileAttributesEx(PChar(FFilePath), GetFileExInfoStandard, @FileInfo) then
  begin
    FCreatedDate := FileTimeToDateTime(FileInfo.ftCreationTime);
    FModifiedDate := FileTimeToDateTime(FileInfo.ftLastWriteTime);
  end;
  
  // 文件类型
  FFileType := ExtractFileExt(FFilePath);
  if FFileType <> '' then
    FFileType := Copy(FFileType, 2, Length(FFileType)); // 去掉开头的点
end;

{ TConversionTestConfig }

constructor TConversionTestConfig.Create;
begin
  inherited Create;
  FWithBOM := False;
  FExpectedSuccess := True;
  FTestFiles := TObjectList<TTestFileConfig>.Create(True);
end;

destructor TConversionTestConfig.Destroy;
begin
  FTestFiles.Free;
  inherited;
end;

procedure TConversionTestConfig.AddTestFile(ATestFile: TTestFileConfig);
begin
  FTestFiles.Add(ATestFile);
end;

procedure TConversionTestConfig.ClearTestFiles;
begin
  FTestFiles.Clear;
end;

procedure TConversionTestConfig.LoadFromJSON(AJson: TJSONObject);
var
  FilesArray: TJSONArray;
  I: Integer;
  FileConfig: TTestFileConfig;
  FileJson: TJSONObject;
begin
  inherited LoadFromJSON(AJson);
  
  if AJson.TryGetValue<string>('sourceEncoding', FSourceEncoding) then;
  if AJson.TryGetValue<string>('targetEncoding', FTargetEncoding) then;
  if AJson.TryGetValue<Boolean>('withBOM', FWithBOM) then;
  if AJson.TryGetValue<Boolean>('expectedSuccess', FExpectedSuccess) then;
  
  if AJson.TryGetValue<TJSONArray>('testFiles', FilesArray) then
  begin
    FTestFiles.Clear;
    for I := 0 to FilesArray.Count - 1 do
    begin
      FileJson := FilesArray.Items[I] as TJSONObject;
      FileConfig := TTestFileConfig.Create;
      FileConfig.LoadFromJSON(FileJson);
      FTestFiles.Add(FileConfig);
    end;
  end;
end;

procedure TConversionTestConfig.RemoveTestFile(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FTestFiles.Count) then
    FTestFiles.Delete(AIndex);
end;

function TConversionTestConfig.SaveToJSON: TJSONObject;
var
  FilesArray: TJSONArray;
  I: Integer;
begin
  Result := inherited SaveToJSON;
  
  Result.AddPair('sourceEncoding', FSourceEncoding);
  Result.AddPair('targetEncoding', FTargetEncoding);
  Result.AddPair('withBOM', TJSONBool.Create(FWithBOM));
  Result.AddPair('expectedSuccess', TJSONBool.Create(FExpectedSuccess));
  
  FilesArray := TJSONArray.Create;
  for I := 0 to FTestFiles.Count - 1 do
    FilesArray.Add(FTestFiles[I].SaveToJSON);
  
  Result.AddPair('testFiles', FilesArray);
end;

{ TComparisonTestConfig }

constructor TComparisonTestConfig.Create;
begin
  inherited Create;
  FTestFiles := TObjectList<TTestFileConfig>.Create(True);
  SetLength(FComparisonTools, 0);
  FTimeout := 30000; // 默认30秒超时
end;

destructor TComparisonTestConfig.Destroy;
begin
  FTestFiles.Free;
  inherited;
end;

procedure TComparisonTestConfig.AddComparisonTool(ATool: TComparisonToolType);
var
  Len: Integer;
begin
  // 检查工具是否已存在
  for var I := 0 to High(FComparisonTools) do
    if FComparisonTools[I] = ATool then
      Exit;
  
  // 添加工具
  Len := Length(FComparisonTools);
  SetLength(FComparisonTools, Len + 1);
  FComparisonTools[Len] := ATool;
end;

procedure TComparisonTestConfig.AddTestFile(ATestFile: TTestFileConfig);
begin
  FTestFiles.Add(ATestFile);
end;

procedure TComparisonTestConfig.ClearComparisonTools;
begin
  SetLength(FComparisonTools, 0);
end;

procedure TComparisonTestConfig.ClearTestFiles;
begin
  FTestFiles.Clear;
end;

procedure TComparisonTestConfig.LoadFromJSON(AJson: TJSONObject);
var
  FilesArray, ToolsArray: TJSONArray;
  ToolStr: string;
  I: Integer;
  FileConfig: TTestFileConfig;
  FileJson: TJSONObject;
begin
  inherited LoadFromJSON(AJson);
  
  if AJson.TryGetValue<string>('sourceEncoding', FSourceEncoding) then;
  if AJson.TryGetValue<string>('targetEncoding', FTargetEncoding) then;
  if AJson.TryGetValue<Integer>('timeout', FTimeout) then;
  
  if AJson.TryGetValue<TJSONArray>('testFiles', FilesArray) then
  begin
    FTestFiles.Clear;
    for I := 0 to FilesArray.Count - 1 do
    begin
      FileJson := FilesArray.Items[I] as TJSONObject;
      FileConfig := TTestFileConfig.Create;
      FileConfig.LoadFromJSON(FileJson);
      FTestFiles.Add(FileConfig);
    end;
  end;
  
  if AJson.TryGetValue<TJSONArray>('comparisonTools', ToolsArray) then
  begin
    SetLength(FComparisonTools, ToolsArray.Count);
    for I := 0 to ToolsArray.Count - 1 do
    begin
      ToolStr := ToolsArray.Items[I].Value;
      if ToolStr = 'Windows' then
        FComparisonTools[I] := cttWindows
      else if ToolStr = 'Iconv' then
        FComparisonTools[I] := cttIconv
      else if ToolStr = 'ICU' then
        FComparisonTools[I] := cttICU
      else if ToolStr = 'Python' then
        FComparisonTools[I] := cttPython
      else if ToolStr = 'Online' then
        FComparisonTools[I] := cttOnline
      else if ToolStr = 'Custom' then
        FComparisonTools[I] := cttCustom;
    end;
  end;
end;

procedure TComparisonTestConfig.RemoveComparisonTool(ATool: TComparisonToolType);
var
  I, J, Len: Integer;
begin
  Len := Length(FComparisonTools);
  for I := 0 to Len - 1 do
  begin
    if FComparisonTools[I] = ATool then
    begin
      // 移除工具
      for J := I to Len - 2 do
        FComparisonTools[J] := FComparisonTools[J + 1];
      
      SetLength(FComparisonTools, Len - 1);
      Break;
    end;
  end;
end;

procedure TComparisonTestConfig.RemoveTestFile(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FTestFiles.Count) then
    FTestFiles.Delete(AIndex);
end;

function TComparisonTestConfig.SaveToJSON: TJSONObject;
var
  FilesArray, ToolsArray: TJSONArray;
  I: Integer;
  ToolStr: string;
begin
  Result := inherited SaveToJSON;
  
  Result.AddPair('sourceEncoding', FSourceEncoding);
  Result.AddPair('targetEncoding', FTargetEncoding);
  Result.AddPair('timeout', TJSONNumber.Create(FTimeout));
  
  FilesArray := TJSONArray.Create;
  for I := 0 to FTestFiles.Count - 1 do
    FilesArray.Add(FTestFiles[I].SaveToJSON);
  
  Result.AddPair('testFiles', FilesArray);
  
  ToolsArray := TJSONArray.Create;
  for I := 0 to High(FComparisonTools) do
  begin
    case FComparisonTools[I] of
      cttWindows: ToolStr := 'Windows';
      cttIconv: ToolStr := 'Iconv';
      cttICU: ToolStr := 'ICU';
      cttPython: ToolStr := 'Python';
      cttOnline: ToolStr := 'Online';
      cttCustom: ToolStr := 'Custom';
    end;
    ToolsArray.Add(ToolStr);
  end;
  
  Result.AddPair('comparisonTools', ToolsArray);
end;

{ TTestSuiteConfig }

constructor TTestSuiteConfig.Create;
begin
  FCreatedDate := Now;
  FModifiedDate := Now;
  FVersion := '1.0';
  FConversionTests := TObjectList<TConversionTestConfig>.Create(True);
  FComparisonTests := TObjectList<TComparisonTestConfig>.Create(True);
end;

destructor TTestSuiteConfig.Destroy;
begin
  FConversionTests.Free;
  FComparisonTests.Free;
  inherited;
end;

procedure TTestSuiteConfig.AddComparisonTest(ATest: TComparisonTestConfig);
begin
  FComparisonTests.Add(ATest);
  FModifiedDate := Now;
end;

procedure TTestSuiteConfig.AddConversionTest(ATest: TConversionTestConfig);
begin
  FConversionTests.Add(ATest);
  FModifiedDate := Now;
end;

procedure TTestSuiteConfig.ClearComparisonTests;
begin
  FComparisonTests.Clear;
  FModifiedDate := Now;
end;

procedure TTestSuiteConfig.ClearConversionTests;
begin
  FConversionTests.Clear;
  FModifiedDate := Now;
end;

procedure TTestSuiteConfig.LoadFromFile(const AFileName: string);
var
  FileContent: string;
  Json: TJSONObject;
begin
  if not FileExists(AFileName) then
    Exit;
    
  try
    FileContent := TFile.ReadAllText(AFileName, TEncoding.UTF8);
    Json := TJSONObject.ParseJSONValue(FileContent) as TJSONObject;
    try
      LoadFromJSON(Json);
    finally
      Json.Free;
    end;
  except
    // 加载失败，保持默认值
  end;
end;

procedure TTestSuiteConfig.LoadFromJSON(AJson: TJSONObject);
var
  ConvArray, CompArray: TJSONArray;
  I: Integer;
  ConvConfig: TConversionTestConfig;
  CompConfig: TComparisonTestConfig;
  ConvJson, CompJson: TJSONObject;
  CreatedStr, ModifiedStr: string;
begin
  if AJson.TryGetValue<string>('name', FName) then;
  if AJson.TryGetValue<string>('description', FDescription) then;
  if AJson.TryGetValue<string>('version', FVersion) then;
  if AJson.TryGetValue<string>('author', FAuthor) then;
  
  if AJson.TryGetValue<string>('createdDate', CreatedStr) then
    FCreatedDate := ISO8601ToDate(CreatedStr);
    
  if AJson.TryGetValue<string>('modifiedDate', ModifiedStr) then
    FModifiedDate := ISO8601ToDate(ModifiedStr);
  
  if AJson.TryGetValue<TJSONArray>('conversionTests', ConvArray) then
  begin
    FConversionTests.Clear;
    for I := 0 to ConvArray.Count - 1 do
    begin
      ConvJson := ConvArray.Items[I] as TJSONObject;
      ConvConfig := TConversionTestConfig.Create;
      ConvConfig.LoadFromJSON(ConvJson);
      FConversionTests.Add(ConvConfig);
    end;
  end;
  
  if AJson.TryGetValue<TJSONArray>('comparisonTests', CompArray) then
  begin
    FComparisonTests.Clear;
    for I := 0 to CompArray.Count - 1 do
    begin
      CompJson := CompArray.Items[I] as TJSONObject;
      CompConfig := TComparisonTestConfig.Create;
      CompConfig.LoadFromJSON(CompJson);
      FComparisonTests.Add(CompConfig);
    end;
  end;
end;

procedure TTestSuiteConfig.RemoveComparisonTest(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FComparisonTests.Count) then
  begin
    FComparisonTests.Delete(AIndex);
    FModifiedDate := Now;
  end;
end;

procedure TTestSuiteConfig.RemoveConversionTest(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FConversionTests.Count) then
  begin
    FConversionTests.Delete(AIndex);
    FModifiedDate := Now;
  end;
end;

procedure TTestSuiteConfig.SaveToFile(const AFileName: string);
var
  Json: TJSONObject;
  JsonStr: string;
begin
  Json := SaveToJSON;
  try
    JsonStr := Json.ToString;
    TFile.WriteAllText(AFileName, JsonStr, TEncoding.UTF8);
  finally
    Json.Free;
  end;
end;

function TTestSuiteConfig.SaveToJSON: TJSONObject;
var
  ConvArray, CompArray: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  
  Result.AddPair('name', FName);
  Result.AddPair('description', FDescription);
  Result.AddPair('version', FVersion);
  Result.AddPair('author', FAuthor);
  Result.AddPair('createdDate', DateToISO8601(FCreatedDate));
  Result.AddPair('modifiedDate', DateToISO8601(FModifiedDate));
  
  ConvArray := TJSONArray.Create;
  for I := 0 to FConversionTests.Count - 1 do
    ConvArray.Add(FConversionTests[I].SaveToJSON);
  
  Result.AddPair('conversionTests', ConvArray);
  
  CompArray := TJSONArray.Create;
  for I := 0 to FComparisonTests.Count - 1 do
    CompArray.Add(FComparisonTests[I].SaveToJSON);
  
  Result.AddPair('comparisonTests', CompArray);
end;

{ TTestCaseManager }

constructor TTestCaseManager.Create(const ABasePath: string);
begin
  FSuites := TObjectList<TTestSuiteConfig>.Create(True);
  
  if ABasePath = '' then
    FBasePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'TestCases')
  else
    FBasePath := ABasePath;
    
  ForceDirectories(FBasePath);
end;

destructor TTestCaseManager.Destroy;
begin
  FSuites.Free;
  inherited;
end;

function TTestCaseManager.CreateSuite(const ASuiteName: string): TTestSuiteConfig;
begin
  Result := TTestSuiteConfig.Create;
  Result.Name := ASuiteName;
  FSuites.Add(Result);
end;

procedure TTestCaseManager.DeleteSuite(const ASuiteName: string);
var
  FileName: string;
  I: Integer;
begin
  FileName := GetTestCaseFilePath(ASuiteName);
  
  // 删除文件
  if FileExists(FileName) then
    TFile.Delete(FileName);
  
  // 从列表中移除
  for I := FSuites.Count - 1 downto 0 do
  begin
    if FSuites[I].Name = ASuiteName then
    begin
      FSuites.Delete(I);
      Break;
    end;
  end;
end;

function TTestCaseManager.GetAllSuiteNames: TArray<string>;
var
  Files: TArray<string>;
  I: Integer;
begin
  Files := TDirectory.GetFiles(FBasePath, '*.json');
  SetLength(Result, Length(Files));
  
  for I := 0 to High(Files) do
    Result[I] := ChangeFileExt(ExtractFileName(Files[I]), '');
end;

function TTestCaseManager.GetTestCaseFilePath(const ASuiteName: string): string;
begin
  Result := TPath.Combine(FBasePath, ASuiteName + '.json');
end;

procedure TTestCaseManager.LoadAllSuites;
var
  Files: TArray<string>;
  I: Integer;
  Suite: TTestSuiteConfig;
begin
  FSuites.Clear;
  Files := TDirectory.GetFiles(FBasePath, '*.json');
  
  for I := 0 to High(Files) do
  begin
    Suite := TTestSuiteConfig.Create;
    Suite.LoadFromFile(Files[I]);
    FSuites.Add(Suite);
  end;
end;

function TTestCaseManager.LoadSuite(const ASuiteName: string): TTestSuiteConfig;
var
  FileName: string;
begin
  FileName := GetTestCaseFilePath(ASuiteName);
  
  if not FileExists(FileName) then
    Exit(nil);
  
  Result := TTestSuiteConfig.Create;
  Result.LoadFromFile(FileName);
  
  // 添加到列表中
  FSuites.Add(Result);
end;

procedure TTestCaseManager.SaveAllSuites;
var
  I: Integer;
begin
  for I := 0 to FSuites.Count - 1 do
    SaveSuite(FSuites[I]);
end;

procedure TTestCaseManager.SaveSuite(ASuite: TTestSuiteConfig);
var
  FileName: string;
begin
  if not Assigned(ASuite) then
    Exit;
    
  FileName := GetTestCaseFilePath(ASuite.Name);
  ASuite.SaveToFile(FileName);
end;

function TTestCaseManager.SuiteExists(const ASuiteName: string): Boolean;
var
  FileName: string;
begin
  FileName := GetTestCaseFilePath(ASuiteName);
  Result := FileExists(FileName);
end;

end. 