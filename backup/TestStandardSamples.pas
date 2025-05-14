unit TestStandardSamples;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  TestEncodingConfig;

type
  /// <summary>
  /// 样本文件类别
  /// </summary>
  TSampleCategory = (
    scPureText,       // 纯文本样本
    scMixedContent,   // 混合内容样本
    scSpecialChars,   // 特殊字符样本
    scBoundary,       // 边界情况样本
    scCornerCase      // 极端情况样本
  );

  /// <summary>
  /// 样本语言类型
  /// </summary>
  TSampleLanguage = (
    slChinese,        // 中文
    slEnglish,        // 英文
    slJapanese,       // 日文
    slKorean,         // 韩文
    slMixed,          // 混合语言
    slSymbols,        // 符号
    slOther           // 其他
  );

  /// <summary>
  /// 标准样本文件
  /// </summary>
  TStandardSample = class
  private
    FFileName: string;
    FFilePath: string;
    FCategory: TSampleCategory;
    FLanguage: TSampleLanguage;
    FEncoding: string;
    FHasBOM: Boolean;
    FDescription: string;
    FCreationDate: TDateTime;
    FFileSize: Int64;
    FMD5Hash: string;
    FTags: TArray<string>;
  public
    constructor Create;
    
    // 从现有文件创建样本
    class function CreateFromFile(const AFilePath: string; ACategory: TSampleCategory; 
      ALanguage: TSampleLanguage; const AEncoding: string; AHasBOM: Boolean; 
      const ADescription: string = ''): TStandardSample;
    
    // 加载样本元数据
    procedure LoadMetadata(const AMetadataFile: string);
    
    // 保存样本元数据
    procedure SaveMetadata(const AMetadataFile: string);
    
    // 验证样本文件
    function Validate: Boolean;
    
    // 转换为测试文件配置
    function ToTestFileConfig: TTestFileConfig;
    
    property FileName: string read FFileName;
    property FilePath: string read FFilePath write FFilePath;
    property Category: TSampleCategory read FCategory write FCategory;
    property Language: TSampleLanguage read FLanguage write FLanguage; 
    property Encoding: string read FEncoding write FEncoding;
    property HasBOM: Boolean read FHasBOM write FHasBOM;
    property Description: string read FDescription write FDescription;
    property CreationDate: TDateTime read FCreationDate write FCreationDate;
    property FileSize: Int64 read FFileSize;
    property MD5Hash: string read FMD5Hash;
    property Tags: TArray<string> read FTags write FTags;
  end;

  /// <summary>
  /// 标准测试集管理器接口
  /// </summary>
  IStandardSamplesManager = interface
    ['{B2D70E5A-6C15-4A42-A1F5-78C32E9D9123}']
    
    // 添加样本
    function AddSample(ASample: TStandardSample): Boolean;
    
    // 移除样本
    function RemoveSample(const ASamplePath: string): Boolean;
    
    // 查找样本
    function FindSample(const ASamplePath: string): TStandardSample;
    
    // 获取特定类别的样本
    function GetSamplesByCategory(ACategory: TSampleCategory): TArray<TStandardSample>;
    
    // 获取特定语言的样本
    function GetSamplesByLanguage(ALanguage: TSampleLanguage): TArray<TStandardSample>;
    
    // 获取特定编码的样本
    function GetSamplesByEncoding(const AEncoding: string): TArray<TStandardSample>;
    
    // 创建测试文件配置
    function CreateTestFileConfigs(ASamples: TArray<TStandardSample>): TArray<TTestFileConfig>;
    
    // 加载样本集
    procedure LoadSampleSet(const ADirectory: string);
    
    // 保存样本集
    procedure SaveSampleSet(const ADirectory: string);
    
    // 创建样本索引
    procedure CreateSampleIndex(const AOutputFile: string);
  end;

  /// <summary>
  /// 标准测试集管理器实现类
  /// </summary>
  TStandardSamplesManager = class(TInterfacedObject, IStandardSamplesManager)
  private
    FSamples: TObjectList<TStandardSample>;
    FBasePath: string;
    
    // 获取样本元数据文件路径
    function GetMetadataFilePath(const ASampleFilePath: string): string;
    
    // 计算文件MD5哈希
    function CalculateMD5(const AFilePath: string): string;
  public
    constructor Create(const ABasePath: string = '');
    destructor Destroy; override;
    
    // IStandardSamplesManager接口实现
    function AddSample(ASample: TStandardSample): Boolean;
    function RemoveSample(const ASamplePath: string): Boolean;
    function FindSample(const ASamplePath: string): TStandardSample;
    function GetSamplesByCategory(ACategory: TSampleCategory): TArray<TStandardSample>;
    function GetSamplesByLanguage(ALanguage: TSampleLanguage): TArray<TStandardSample>;
    function GetSamplesByEncoding(const AEncoding: string): TArray<TStandardSample>;
    function CreateTestFileConfigs(ASamples: TArray<TStandardSample>): TArray<TTestFileConfig>;
    procedure LoadSampleSet(const ADirectory: string);
    procedure SaveSampleSet(const ADirectory: string);
    procedure CreateSampleIndex(const AOutputFile: string);
    
    // 辅助方法
    
    // 创建特定编码的测试样本文件
    function CreateEncodingSample(const AContent: string; const AFilePath: string; 
      const AEncoding: string; AHasBOM: Boolean; ACategory: TSampleCategory; 
      ALanguage: TSampleLanguage; const ADescription: string = ''): TStandardSample;
    
    // 从目录导入样本文件
    function ImportSamplesFromDirectory(const ADirectory: string; 
      ACategory: TSampleCategory; ALanguage: TSampleLanguage; 
      const AEncoding: string; AHasBOM: Boolean): Integer;
    
    // 生成中文编码测试样本
    procedure GenerateChineseEncodingSamples(const AOutputDir: string);
    
    // 生成特殊字符测试样本
    procedure GenerateSpecialCharsSamples(const AOutputDir: string);
    
    // 生成混合内容测试样本
    procedure GenerateMixedContentSamples(const AOutputDir: string);
    
    // 生成边界情况测试样本
    procedure GenerateBoundaryCaseSamples(const AOutputDir: string);
    
    // 验证所有样本文件
    function ValidateAllSamples: Boolean;
    
    property BasePath: string read FBasePath write FBasePath;
    property Samples: TObjectList<TStandardSample> read FSamples;
  end;

  /// <summary>
  /// 编码样本记录，包含样本的基本信息
  /// </summary>
  TEncodingSample = record
    FileName: string;      // 样本文件名
    FilePath: string;      // 样本完整路径
    Encoding: string;      // 样本使用的编码
    Category: string;      // 样本类别，如：纯文本、混合内容、特殊字符等
    Description: string;   // 样本描述
    HasBOM: Boolean;       // 是否包含BOM标记
    ByteSize: Int64;       // 文件字节大小
    CharCount: Integer;    // 字符数量（可能不准确，取决于编码）
    CreatedAt: TDateTime;  // 创建时间
    Tags: TArray<string>;  // 额外标签，用于分类和搜索
    
    constructor Create(const AFileName, AFilePath, AEncoding, ACategory, ADescription: string;
      AHasBOM: Boolean; AByteSize: Int64; ACharCount: Integer;
      ATags: TArray<string>);
  end;

  /// <summary>
  /// 样本注册表类，用于管理所有测试样本
  /// </summary>
  TSampleRegistry = class
  private
    FSamples: TList<TEncodingSample>;
    FBasePath: string;
  public
    constructor Create(const ABasePath: string);
    destructor Destroy; override;
    
    // 样本管理
    procedure AddSample(const ASample: TEncodingSample);
    function GetSampleByIndex(Index: Integer): TEncodingSample;
    function GetSampleCount: Integer;
    function GetSamplesByCategory(const ACategory: string): TArray<TEncodingSample>;
    function GetSamplesByEncoding(const AEncoding: string): TArray<TEncodingSample>;
    function GetSamplesByTag(const ATag: string): TArray<TEncodingSample>;
    
    // 样本创建
    procedure GenerateStandardTestSet;
    procedure GenerateBasicTextSamples;
    procedure GenerateSpecialCharsSamples;
    procedure GenerateMixedContentSamples;
    procedure GenerateEdgeCasesSamples;
    
    // 样本报告
    procedure GenerateSampleReport(const AOutputPath: string);
    procedure ExportSampleIndex(const AOutputPath: string);
  end;

implementation

uses
  System.Hash, System.JSON, System.Generics.Defaults, Winapi.Windows;

const
  METADATA_EXTENSION = '.meta.json';

{ TStandardSample }

constructor TStandardSample.Create;
begin
  inherited Create;
  FCreationDate := Now;
  SetLength(FTags, 0);
end;

class function TStandardSample.CreateFromFile(const AFilePath: string; 
  ACategory: TSampleCategory; ALanguage: TSampleLanguage;
  const AEncoding: string; AHasBOM: Boolean; const ADescription: string): TStandardSample;
var
  FileInfo: TWin32FileAttributeData;
begin
  Result := TStandardSample.Create;
  try
    Result.FFilePath := AFilePath;
    Result.FFileName := ExtractFileName(AFilePath);
    Result.FCategory := ACategory;
    Result.FLanguage := ALanguage;
    Result.FEncoding := AEncoding;
    Result.FHasBOM := AHasBOM;
    Result.FDescription := ADescription;
    
    // 获取文件大小
    if FileExists(AFilePath) then
    begin
      Result.FFileSize := TFile.GetSize(AFilePath);
      
      // 获取文件创建日期
      if GetFileAttributesEx(PChar(AFilePath), GetFileExInfoStandard, @FileInfo) then
        Result.FCreationDate := FileTimeToDateTime(FileInfo.ftCreationTime);
        
      // 计算MD5哈希
      var Stream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
      try
        Result.FMD5Hash := THashMD5.GetHashStringFromStream(Stream);
      finally
        Stream.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TStandardSample.LoadMetadata(const AMetadataFile: string);
var
  Json: TJSONObject;
  JsonValue: TJSONValue;
  TagsArray: TJSONArray;
  I: Integer;
begin
  if not FileExists(AMetadataFile) then
    Exit;
    
  try
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(AMetadataFile)) as TJSONObject;
    try
      if Json.TryGetValue<string>('fileName', FFileName) then;
      if Json.TryGetValue<string>('filePath', FFilePath) then;
      
      JsonValue := Json.GetValue('category');
      if Assigned(JsonValue) then
        FCategory := TSampleCategory(JsonValue.GetValue<Integer>);
        
      JsonValue := Json.GetValue('language');
      if Assigned(JsonValue) then
        FLanguage := TSampleLanguage(JsonValue.GetValue<Integer>);
        
      if Json.TryGetValue<string>('encoding', FEncoding) then;
      if Json.TryGetValue<Boolean>('hasBOM', FHasBOM) then;
      if Json.TryGetValue<string>('description', FDescription) then;
      
      var DateStr: string;
      if Json.TryGetValue<string>('creationDate', DateStr) then
        FCreationDate := ISO8601ToDate(DateStr);
        
      if Json.TryGetValue<Int64>('fileSize', FFileSize) then;
      if Json.TryGetValue<string>('md5Hash', FMD5Hash) then;
      
      TagsArray := Json.GetValue('tags') as TJSONArray;
      if Assigned(TagsArray) then
      begin
        SetLength(FTags, TagsArray.Count);
        for I := 0 to TagsArray.Count - 1 do
          FTags[I] := TagsArray.Items[I].Value;
      end;
    finally
      Json.Free;
    end;
  except
    // 加载失败，保持当前值
  end;
end;

procedure TStandardSample.SaveMetadata(const AMetadataFile: string);
var
  Json: TJSONObject;
  TagsArray: TJSONArray;
  I: Integer;
begin
  Json := TJSONObject.Create;
  try
    Json.AddPair('fileName', FFileName);
    Json.AddPair('filePath', FFilePath);
    Json.AddPair('category', TJSONNumber.Create(Ord(FCategory)));
    Json.AddPair('language', TJSONNumber.Create(Ord(FLanguage)));
    Json.AddPair('encoding', FEncoding);
    Json.AddPair('hasBOM', TJSONBool.Create(FHasBOM));
    Json.AddPair('description', FDescription);
    Json.AddPair('creationDate', DateToISO8601(FCreationDate));
    Json.AddPair('fileSize', TJSONNumber.Create(FFileSize));
    Json.AddPair('md5Hash', FMD5Hash);
    
    TagsArray := TJSONArray.Create;
    for I := 0 to High(FTags) do
      TagsArray.Add(FTags[I]);
    
    Json.AddPair('tags', TagsArray);
    
    ForceDirectories(ExtractFilePath(AMetadataFile));
    TFile.WriteAllText(AMetadataFile, Json.ToString, TEncoding.UTF8);
  finally
    Json.Free;
  end;
end;

function TStandardSample.Validate: Boolean;
var
  ActualFileSize: Int64;
  ActualMD5: string;
  Stream: TFileStream;
begin
  Result := False;
  
  if not FileExists(FFilePath) then
    Exit;
  
  try
    // 验证文件大小
    ActualFileSize := TFile.GetSize(FFilePath);
    if ActualFileSize <> FFileSize then
      Exit;
    
    // 验证MD5哈希
    Stream := TFileStream.Create(FFilePath, fmOpenRead or fmShareDenyNone);
    try
      ActualMD5 := THashMD5.GetHashStringFromStream(Stream);
      if ActualMD5 <> FMD5Hash then
        Exit;
    finally
      Stream.Free;
    end;
    
    Result := True;
  except
    Result := False;
  end;
end;

function TStandardSample.ToTestFileConfig: TTestFileConfig;
begin
  Result := TTestFileConfig.Create;
  Result.Name := FFileName;
  Result.Description := FDescription;
  Result.FilePath := FFilePath;
  Result.SourceEncoding := FEncoding;
  Result.ExpectedEncoding := FEncoding;
  Result.HasBOM := FHasBOM;
  
  case FLanguage of
    slChinese: Result.Language := 'Chinese';
    slEnglish: Result.Language := 'English';
    slJapanese: Result.Language := 'Japanese';
    slKorean: Result.Language := 'Korean';
    slMixed: Result.Language := 'Mixed';
    slSymbols: Result.Language := 'Symbols';
    slOther: Result.Language := 'Other';
  end;
  
  // 设置标签
  Result.Tags := FTags;
  
  // 更新文件信息
  Result.UpdateFileInfo;
end;

constructor TStandardSamplesManager.Create(const ABasePath: string = '');
begin
  inherited Create;
  FSamples := TObjectList<TStandardSample>.Create;
  FBasePath := ABasePath;
end;

destructor TStandardSamplesManager.Destroy;
begin
  FSamples.Free;
  inherited Destroy;
end;

function TStandardSamplesManager.AddSample(ASample: TStandardSample): Boolean;
begin
  Result := FSamples.Add(ASample);
end;

function TStandardSamplesManager.RemoveSample(const ASamplePath: string): Boolean;
var
  Sample: TStandardSample;
begin
  Result := False;
  for Sample in FSamples do
  begin
    if Sample.FilePath = ASamplePath then
    begin
      FSamples.Remove(Sample);
      Result := True;
      Break;
    end;
  end;
end;

function TStandardSamplesManager.FindSample(const ASamplePath: string): TStandardSample;
var
  Sample: TStandardSample;
begin
  Result := nil;
  for Sample in FSamples do
  begin
    if Sample.FilePath = ASamplePath then
    begin
      Result := Sample;
      Break;
    end;
  end;
end;

function TStandardSamplesManager.GetSamplesByCategory(ACategory: TSampleCategory): TArray<TStandardSample>;
var
  Samples: TList<TStandardSample>;
  Sample: TStandardSample;
begin
  Samples := TList<TStandardSample>.Create;
  try
    for Sample in FSamples do
    begin
      if Sample.Category = ACategory then
        Samples.Add(Sample);
    end;
    Result := Samples.ToArray;
  finally
    Samples.Free;
  end;
end;

function TStandardSamplesManager.GetSamplesByLanguage(ALanguage: TSampleLanguage): TArray<TStandardSample>;
var
  Samples: TList<TStandardSample>;
  Sample: TStandardSample;
begin
  Samples := TList<TStandardSample>.Create;
  try
    for Sample in FSamples do
    begin
      if Sample.Language = ALanguage then
        Samples.Add(Sample);
    end;
    Result := Samples.ToArray;
  finally
    Samples.Free;
  end;
end;

function TStandardSamplesManager.GetSamplesByEncoding(const AEncoding: string): TArray<TStandardSample>;
var
  Samples: TList<TStandardSample>;
  Sample: TStandardSample;
begin
  Samples := TList<TStandardSample>.Create;
  try
    for Sample in FSamples do
    begin
      if Sample.Encoding = AEncoding then
        Samples.Add(Sample);
    end;
    Result := Samples.ToArray;
  finally
    Samples.Free;
  end;
end;

function TStandardSamplesManager.CreateTestFileConfigs(ASamples: TArray<TStandardSample>): TArray<TTestFileConfig>;
var
  TestFileConfigs: TList<TTestFileConfig>;
  Sample: TStandardSample;
begin
  TestFileConfigs := TList<TTestFileConfig>.Create;
  try
    for Sample in ASamples do
    begin
      TestFileConfigs.Add(Sample.ToTestFileConfig);
    end;
    Result := TestFileConfigs.ToArray;
  finally
    TestFileConfigs.Free;
  end;
end;

procedure TStandardSamplesManager.LoadSampleSet(const ADirectory: string);
var
  Files: TArray<string>;
  FilePath: string;
  Sample: TStandardSample;
begin
  Files := TDirectory.GetFiles(ADirectory, '*', TSearchOption.soAllDirectories);
  for FilePath in Files do
  begin
    Sample := TStandardSample.CreateFromFile(FilePath, scPureText, slChinese, '', False);
    AddSample(Sample);
  end;
end;

procedure TStandardSamplesManager.SaveSampleSet(const ADirectory: string);
var
  FilePath: string;
  Sample: TStandardSample;
begin
  for Sample in FSamples do
  begin
    FilePath := Sample.FilePath;
    if not TDirectory.Exists(ADirectory) then
      TDirectory.CreateDirectory(ADirectory);
    TFile.Copy(FilePath, ADirectory + '\' + ExtractFileName(FilePath));
  end;
end;

procedure TStandardSamplesManager.CreateSampleIndex(const AOutputFile: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  Sample: TStandardSample;
begin
  Json := TJSONObject.Create;
  try
    JsonArray := TJSONArray.Create;
    for Sample in FSamples do
    begin
      Json.AddPair('fileName', Sample.FileName);
      Json.AddPair('filePath', Sample.FilePath);
      Json.AddPair('category', TJSONNumber.Create(Ord(Sample.Category)));
      Json.AddPair('language', TJSONNumber.Create(Ord(Sample.Language)));
      Json.AddPair('encoding', Sample.Encoding);
      Json.AddPair('hasBOM', TJSONBool.Create(Sample.HasBOM));
      Json.AddPair('description', Sample.Description);
      Json.AddPair('creationDate', DateToISO8601(Sample.CreationDate));
      Json.AddPair('fileSize', TJSONNumber.Create(Sample.FileSize));
      Json.AddPair('md5Hash', Sample.MD5Hash);
      JsonArray.AddElement(TJSONString.Create(Sample.FileName));
    end;
    Json.AddPair('samples', JsonArray);
    TFile.WriteAllText(AOutputFile, Json.ToString);
  finally
    Json.Free;
  end;
end;

function TStandardSamplesManager.CreateEncodingSample(const AContent: string; const AFilePath: string; 
  const AEncoding: string; AHasBOM: Boolean; ACategory: TSampleCategory; 
  ALanguage: TSampleLanguage; const ADescription: string): TStandardSample;
begin
  Result := TStandardSample.Create;
  Result.FFilePath := AFilePath;
  Result.FFileName := ExtractFileName(AFilePath);
  Result.FCategory := ACategory;
  Result.FLanguage := ALanguage;
  Result.FEncoding := AEncoding;
  Result.FHasBOM := AHasBOM;
  Result.FDescription := ADescription;
  Result.FCreationDate := Now;
  Result.FFileSize := Length(AContent);
  Result.FMD5Hash := CalculateMD5(AContent);
  SetLength(Result.FTags, 0);
end;

function TStandardSamplesManager.ImportSamplesFromDirectory(const ADirectory: string; 
  ACategory: TSampleCategory; ALanguage: TSampleLanguage; 
  const AEncoding: string; AHasBOM: Boolean): Integer;
var
  Files: TArray<string>;
  FilePath: string;
  Sample: TStandardSample;
begin
  Result := 0;
  Files := TDirectory.GetFiles(ADirectory, '*', TSearchOption.soAllDirectories);
  for FilePath in Files do
  begin
    Sample := TStandardSample.CreateFromFile(FilePath, ACategory, ALanguage, AEncoding, AHasBOM);
    if AddSample(Sample) then
      Inc(Result);
  end;
end;

procedure TStandardSamplesManager.GenerateChineseEncodingSamples(const AOutputDir: string);
var
  Content: string;
  FilePath: string;
  Sample: TStandardSample;
begin
  for Sample in GetSamplesByLanguage(slChinese) do
  begin
    Content := Sample.Description;
    FilePath := AOutputDir + '\' + Sample.FileName;
    Sample := CreateEncodingSample(Content, FilePath, Sample.Encoding, Sample.HasBOM, Sample.Category, Sample.Language, Sample.Description);
    SaveSample(Sample.FilePath);
  end;
end;

procedure TStandardSamplesManager.GenerateSpecialCharsSamples(const AOutputDir: string);
var
  Content: string;
  FilePath: string;
  Sample: TStandardSample;
begin
  for Sample in GetSamplesByCategory(scSpecialChars) do
  begin
    Content := Sample.Description;
    FilePath := AOutputDir + '\' + Sample.FileName;
    Sample := CreateEncodingSample(Content, FilePath, Sample.Encoding, Sample.HasBOM, Sample.Category, Sample.Language, Sample.Description);
    SaveSample(Sample.FilePath);
  end;
end;

procedure TStandardSamplesManager.GenerateMixedContentSamples(const AOutputDir: string);
var
  Content: string;
  FilePath: string;
  Sample: TStandardSample;
begin
  for Sample in GetSamplesByCategory(scMixedContent) do
  begin
    Content := Sample.Description;
    FilePath := AOutputDir + '\' + Sample.FileName;
    Sample := CreateEncodingSample(Content, FilePath, Sample.Encoding, Sample.HasBOM, Sample.Category, Sample.Language, Sample.Description);
    SaveSample(Sample.FilePath);
  end;
end;

procedure TStandardSamplesManager.GenerateBoundaryCaseSamples(const AOutputDir: string);
var
  Content: string;
  FilePath: string;
  Sample: TStandardSample;
begin
  for Sample in GetSamplesByCategory(scBoundary) do
  begin
    Content := Sample.Description;
    FilePath := AOutputDir + '\' + Sample.FileName;
    Sample := CreateEncodingSample(Content, FilePath, Sample.Encoding, Sample.HasBOM, Sample.Category, Sample.Language, Sample.Description);
    SaveSample(Sample.FilePath);
  end;
end;

function TStandardSamplesManager.ValidateAllSamples: Boolean;
var
  Sample: TStandardSample;
begin
  Result := True;
  for Sample in FSamples do
  begin
    if not Sample.Validate then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TStandardSamplesManager.GetMetadataFilePath(const ASampleFilePath: string): string;
begin
  Result := ASampleFilePath + METADATA_EXTENSION;
end;

function TStandardSamplesManager.CalculateMD5(const AFilePath: string): string;
var
  FileStream: TFileStream;
begin
  if FileExists(AFilePath) then
  begin
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      Result := THashMD5.GetHashStringFromStream(FileStream);
    finally
      FileStream.Free;
    end;
  end
  else
    Result := '';
end;

function TStandardSamplesManager.CalculateMD5(const AContent: string): string;
begin
  Result := THashMD5.GetHashString(AContent);
end;

procedure TStandardSamplesManager.SaveSample(const ASampleFilePath: string);
var
  Sample: TStandardSample;
  MetadataFile: string;
begin
  Sample := FindSample(ASampleFilePath);
  if Assigned(Sample) then
  begin
    MetadataFile := GetMetadataFilePath(ASampleFilePath);
    Sample.SaveMetadata(MetadataFile);
  end;
end;

constructor TSampleRegistry.Create(const ABasePath: string);
begin
  inherited Create;
  FSamples := TList<TEncodingSample>.Create;
  FBasePath := ABasePath;
  
  if not TDirectory.Exists(FBasePath) then
    TDirectory.CreateDirectory(FBasePath);
end;

destructor TSampleRegistry.Destroy;
begin
  FSamples.Free;
  inherited;
end;

procedure TSampleRegistry.AddSample(const ASample: TEncodingSample);
begin
  FSamples.Add(ASample);
end;

function TSampleRegistry.GetSampleByIndex(Index: Integer): TEncodingSample;
begin
  if (Index >= 0) and (Index < FSamples.Count) then
    Result := FSamples[Index]
  else
    raise Exception.CreateFmt('样本索引 %d 超出范围', [Index]);
end;

function TSampleRegistry.GetSampleCount: Integer;
begin
  Result := FSamples.Count;
end;

function TSampleRegistry.GetSamplesByCategory(
  const ACategory: string): TArray<TEncodingSample>;
var
  List: TList<TEncodingSample>;
  I: Integer;
begin
  List := TList<TEncodingSample>.Create;
  try
    for I := 0 to FSamples.Count - 1 do
      if SameText(FSamples[I].Category, ACategory) then
        List.Add(FSamples[I]);
        
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSampleRegistry.GetSamplesByEncoding(
  const AEncoding: string): TArray<TEncodingSample>;
var
  List: TList<TEncodingSample>;
  I: Integer;
begin
  List := TList<TEncodingSample>.Create;
  try
    for I := 0 to FSamples.Count - 1 do
      if SameText(FSamples[I].Encoding, AEncoding) then
        List.Add(FSamples[I]);
        
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TSampleRegistry.GetSamplesByTag(
  const ATag: string): TArray<TEncodingSample>;
var
  List: TList<TEncodingSample>;
  I, J: Integer;
begin
  List := TList<TEncodingSample>.Create;
  try
    for I := 0 to FSamples.Count - 1 do
      for J := Low(FSamples[I].Tags) to High(FSamples[I].Tags) do
        if SameText(FSamples[I].Tags[J], ATag) then
        begin
          List.Add(FSamples[I]);
          Break;
        end;
        
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TSampleRegistry.GenerateStandardTestSet;
begin
  // 生成所有标准测试样本
  GenerateBasicTextSamples;
  GenerateSpecialCharsSamples;
  GenerateMixedContentSamples;
  GenerateEdgeCasesSamples;
end;

procedure TSampleRegistry.GenerateBasicTextSamples;
var
  SampleText: TStringList;
  FilePath: string;
  Sample: TEncodingSample;
  FileStream: TFileStream;
  Tags: TArray<string>;
begin
  SampleText := TStringList.Create;
  try
    // ASCII 纯文本样本
    SampleText.Clear;
    SampleText.Add('ASCII text sample - Only English letters and numbers');
    SampleText.Add('The quick brown fox jumps over the lazy dog.');
    SampleText.Add('0123456789');
    SampleText.Add('Special ASCII chars: !@#$%^&*()_+-=[]{}|;:,./<>?');
    
    FilePath := TPath.Combine(FBasePath, 'ascii_sample.txt');
    SampleText.SaveToFile(FilePath, TEncoding.ASCII);
    
    Tags := ['basic', 'ascii', 'pure_text'];
    Sample := TEncodingSample.Create(
      'ascii_sample.txt',
      FilePath,
      'ASCII',
      '纯文本',
      'ASCII字符样本，仅包含英文字母、数字和标点',
      False, // 无BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // UTF-8 文本样本（含中文）
    SampleText.Clear;
    SampleText.Add('UTF-8中文文本样本');
    SampleText.Add('这是一个包含中文字符的UTF-8编码文本示例。');
    SampleText.Add('It also contains some English characters.');
    SampleText.Add('数字: 0123456789');
    
    FilePath := TPath.Combine(FBasePath, 'utf8_sample.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['basic', 'utf8', 'chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'utf8_sample.txt',
      FilePath,
      'UTF-8',
      '纯文本',
      'UTF-8中文样本，包含中英文混合内容',
      True, // 有BOM（由SaveToFile自动添加）
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // UTF-8 无BOM样本
    SampleText.Clear;
    SampleText.Add('UTF-8无BOM样本');
    SampleText.Add('这是一个不带BOM标记的UTF-8编码文本。');
    SampleText.Add('包含中英文混合内容和数字：123。');
    
    FilePath := TPath.Combine(FBasePath, 'utf8_no_bom_sample.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    try
      // 直接写入UTF-8编码的字节，不添加BOM
      var Bytes := TEncoding.UTF8.GetBytes(SampleText.Text);
      FileStream.WriteBuffer(Bytes, Length(Bytes));
    finally
      FileStream.Free;
    end;
    
    Tags := ['basic', 'utf8', 'no_bom', 'chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'utf8_no_bom_sample.txt',
      FilePath,
      'UTF-8无BOM',
      '纯文本',
      'UTF-8无BOM样本，测试无BOM情况下的UTF-8检测',
      False, // 无BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // UTF-16 LE文本样本
    SampleText.Clear;
    SampleText.Add('UTF-16 LE文本样本');
    SampleText.Add('这是一个UTF-16小端序编码的文本。');
    SampleText.Add('包含中英文混合内容和数字：123。');
    
    FilePath := TPath.Combine(FBasePath, 'utf16le_sample.txt');
    SampleText.SaveToFile(FilePath, TEncoding.Unicode);
    
    Tags := ['basic', 'utf16', 'utf16le', 'chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'utf16le_sample.txt',
      FilePath,
      'UTF-16LE',
      '纯文本',
      'UTF-16 LE样本，小端序编码',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // UTF-16 BE文本样本
    SampleText.Clear;
    SampleText.Add('UTF-16 BE文本样本');
    SampleText.Add('这是一个UTF-16大端序编码的文本。');
    SampleText.Add('同样包含中英文混合内容和数字：456。');
    
    FilePath := TPath.Combine(FBasePath, 'utf16be_sample.txt');
    SampleText.SaveToFile(FilePath, TEncoding.BigEndianUnicode);
    
    Tags := ['basic', 'utf16', 'utf16be', 'chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'utf16be_sample.txt',
      FilePath,
      'UTF-16BE',
      '纯文本',
      'UTF-16 BE样本，大端序编码',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // GBK中文样本
    SampleText.Clear;
    SampleText.Add('GBK中文文本样本');
    SampleText.Add('这是一个GBK编码的中文文本示例。');
    SampleText.Add('包含一些特殊字符和常用汉字。');
    
    FilePath := TPath.Combine(FBasePath, 'gbk_sample.txt');
    TFile.WriteAllText(FilePath, SampleText.Text, TEncoding.GetEncoding(936)); // 936=GBK
    
    Tags := ['basic', 'gbk', 'chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'gbk_sample.txt',
      FilePath,
      'GBK',
      '纯文本',
      'GBK中文样本，使用GB18030/GBK编码',
      False, // 无BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // Big5 繁体中文样本
    SampleText.Clear;
    SampleText.Add('Big5繁體中文文本樣本');
    SampleText.Add('這是一個Big5編碼的繁體中文文本示例。');
    SampleText.Add('包含一些特殊字符和常用漢字。');
    
    FilePath := TPath.Combine(FBasePath, 'big5_sample.txt');
    TFile.WriteAllText(FilePath, SampleText.Text, TEncoding.GetEncoding(950)); // 950=Big5
    
    Tags := ['basic', 'big5', 'chinese', 'traditional_chinese', 'pure_text'];
    Sample := TEncodingSample.Create(
      'big5_sample.txt',
      FilePath,
      'Big5',
      '纯文本',
      'Big5繁体中文样本，使用Big5编码',
      False, // 无BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
  finally
    SampleText.Free;
  end;
end;

procedure TSampleRegistry.GenerateSpecialCharsSamples;
var
  SampleText: TStringList;
  FilePath: string;
  Sample: TEncodingSample;
  Tags: TArray<string>;
begin
  SampleText := TStringList.Create;
  try
    // 特殊字符样本 - UTF-8
    SampleText.Clear;
    SampleText.Add('特殊字符样本 - UTF-8编码');
    SampleText.Add('=== 常用特殊符号 ===');
    SampleText.Add('● ○ ▲ ▼ ◆ ◇ ★ ☆ ◎ ◐ ◑ ☉ ☎ ☏ ⊙ ▣');
    SampleText.Add('♀ ♂ ♤ ♠ ♡ ♥ ♧ ♣ ⊿ ☼ ☺ ☻ ♨ ☚ ☛ ☜ ☝ ☞ ☟');
    SampleText.Add('=== 货币符号 ===');
    SampleText.Add('¥ $ € £ ¢ ₣ ₤ ₧ ₨ ₩ ₫ ₭ ₮ ₯ ₹ ₺ ₽ ₨ ﷼');
    SampleText.Add('=== 数学符号 ===');
    SampleText.Add('+ - × ÷ = ≠ ≈ ≤ ≥ ± ∓ ∞ π ∝ √ ∛ ∜ ∟ ∠ ∡ ∢');
    SampleText.Add('∑ ∏ ∩ ∪ ⊂ ⊃ ⊆ ⊇ ∈ ∋ ⊥ ∥ ∧ ∨ ¬ ∀ ∃ ∄ ∂ ∇');
    SampleText.Add('=== 各种标点和符号 ===');
    SampleText.Add('，。、；：？！…—·""''（）《》〈〉「」『』【】〔〕[]{}#&*@~');
    
    FilePath := TPath.Combine(FBasePath, 'special_chars_utf8.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['special', 'symbols', 'utf8'];
    Sample := TEncodingSample.Create(
      'special_chars_utf8.txt',
      FilePath,
      'UTF-8',
      '特殊字符',
      '特殊字符样本，包含各种特殊符号、emoji等',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // 控制字符样本 - UTF-8
    SampleText.Clear;
    SampleText.Add('控制字符样本');
    SampleText.Add('包含ASCII控制字符(C0)：');
    
    // 添加可见的控制字符表示
    SampleText.Add('NUL(^@): ' + #0);
    SampleText.Add('SOH(^A): ' + #1);
    SampleText.Add('STX(^B): ' + #2);
    SampleText.Add('ETX(^C): ' + #3);
    SampleText.Add('EOT(^D): ' + #4);
    SampleText.Add('ENQ(^E): ' + #5);
    SampleText.Add('ACK(^F): ' + #6);
    SampleText.Add('BEL(^G): ' + #7);
    SampleText.Add('BS(^H): ' + #8);
    SampleText.Add('HT(^I): ' + #9);
    SampleText.Add('LF(^J): ' + #10);
    SampleText.Add('VT(^K): ' + #11);
    SampleText.Add('FF(^L): ' + #12);
    SampleText.Add('CR(^M): ' + #13);
    SampleText.Add('SO(^N): ' + #14);
    SampleText.Add('SI(^O): ' + #15);
    SampleText.Add('DLE(^P): ' + #16);
    
    FilePath := TPath.Combine(FBasePath, 'control_chars.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['special', 'control', 'utf8'];
    Sample := TEncodingSample.Create(
      'control_chars.txt',
      FilePath,
      'UTF-8',
      '特殊字符',
      '控制字符样本，包含ASCII控制字符',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // Emoji样本 - UTF-8
    SampleText.Clear;
    SampleText.Add('Emoji表情符号样本 - UTF-8编码');
    SampleText.Add('=== 基本表情 ===');
    SampleText.Add('😀 😁 😂 😃 😄 😅 😆 😉 😊 😋 😎 😍 😘 😗 😙 😚 😐 😑 😶 😏');
    SampleText.Add('=== 人物和手势 ===');
    SampleText.Add('👦 👧 👨 👩 👴 👵 👶 👱 👮 👲 👳 👷 👸 👼 👯 👰 🙅 🙆 🙇 🙋');
    SampleText.Add('=== 动物 ===');
    SampleText.Add('🐒 🐶 🐕 🐩 🐺 🐱 🐈 🐯 🐅 🐆 🐴 🐎 🐮 🐂 🐃 🐄 🐷 🐖 🐗 🐽');
    SampleText.Add('=== 各种符号 ===');
    SampleText.Add('❤️ 💔 💌 💕 💞 💓 💗 💖 💘 💝 💟 💜 💙 💚 💛 💡 💢 💫 💥');
    
    FilePath := TPath.Combine(FBasePath, 'emoji_utf8.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['special', 'emoji', 'utf8'];
    Sample := TEncodingSample.Create(
      'emoji_utf8.txt',
      FilePath,
      'UTF-8',
      '特殊字符',
      'Emoji表情符号样本，包含各类表情符号',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
  finally
    SampleText.Free;
  end;
end;

procedure TSampleRegistry.GenerateMixedContentSamples;
var
  SampleText: TStringList;
  FilePath: string;
  Sample: TEncodingSample;
  Tags: TArray<string>;
begin
  SampleText := TStringList.Create;
  try
    // 中英文混合内容 - UTF-8
    SampleText.Clear;
    SampleText.Add('混合内容样本 - 中英文混合 - Mixed Content Sample');
    SampleText.Add('');
    SampleText.Add('1. 中英文混合段落 / English-Chinese Mixed Paragraph');
    SampleText.Add('这是一个包含中文和English混合内容的样本。This is a sample with mixed Chinese and English content.');
    SampleText.Add('软件界面经常会出现这样的混合文本，Software interfaces often contain such mixed text,');
    SampleText.Add('尤其是在国际化的应用程序中。especially in internationalized applications.');
    SampleText.Add('');
    SampleText.Add('2. 数字和符号 / Numbers and Symbols');
    SampleText.Add('数字 Numbers: 0123456789０１２３４５６７８９');
    SampleText.Add('符号 Symbols: !"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~');
    SampleText.Add('中文符号: 【】「」『』《》''""，。、；：？！…—·');
    SampleText.Add('');
    SampleText.Add('3. 代码片段 / Code Snippet');
    SampleText.Add('function convertEncoding(text, fromEncoding, toEncoding) {');
    SampleText.Add('  // 这是一个转换编码的函数 / This is a function to convert encoding');
    SampleText.Add('  const buffer = iconv.encode(text, fromEncoding);');
    SampleText.Add('  return iconv.decode(buffer, toEncoding);');
    SampleText.Add('}');
    
    FilePath := TPath.Combine(FBasePath, 'mixed_content_utf8.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['mixed', 'chinese', 'english', 'utf8'];
    Sample := TEncodingSample.Create(
      'mixed_content_utf8.txt',
      FilePath,
      'UTF-8',
      '混合内容',
      '中英文混合内容样本，包含中英文、数字、符号和代码',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
    
    // 多语言混合 - UTF-8
    SampleText.Clear;
    SampleText.Add('多语言混合样本 / Multilingual Sample');
    SampleText.Add('');
    SampleText.Add('1. 中文 (Chinese)');
    SampleText.Add('这是中文内容示例。这是简体中文。');
    SampleText.Add('');
    SampleText.Add('2. English (英文)');
    SampleText.Add('This is a sample of English text. The quick brown fox jumps over the lazy dog.');
    SampleText.Add('');
    SampleText.Add('3. 日本語 (Japanese)');
    SampleText.Add('これは日本語のサンプルです。私は日本語を勉強しています。');
    SampleText.Add('');
    SampleText.Add('4. Español (Spanish)');
    SampleText.Add('Esta es una muestra de texto en español. El rápido zorro marrón salta sobre el perro perezoso.');
    SampleText.Add('');
    SampleText.Add('5. Русский (Russian)');
    SampleText.Add('Это образец текста на русском языке. Быстрая коричневая лиса прыгает через ленивую собаку.');
    
    FilePath := TPath.Combine(FBasePath, 'multilingual_utf8.txt');
    SampleText.SaveToFile(FilePath, TEncoding.UTF8);
    
    Tags := ['mixed', 'multilingual', 'utf8'];
    Sample := TEncodingSample.Create(
      'multilingual_utf8.txt',
      FilePath,
      'UTF-8',
      '混合内容',
      '多语言混合样本，包含中文、英文、日文、西班牙文和俄文',
      True, // 有BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length,
      Tags
    );
    AddSample(Sample);
  finally
    SampleText.Free;
  end;
end;

procedure TSampleRegistry.GenerateEdgeCasesSamples;
var
  SampleText: TStringList;
  FilePath: string;
  Sample: TEncodingSample;
  FileStream: TFileStream;
  Bytes: TBytes;
  Tags: TArray<string>;
begin
  SampleText := TStringList.Create;
  try
    // 空文件样本
    FilePath := TPath.Combine(FBasePath, 'empty_file.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    FileStream.Free;
    
    Tags := ['edge', 'empty', 'special'];
    Sample := TEncodingSample.Create(
      'empty_file.txt',
      FilePath,
      '未知',
      '边界情况',
      '空文件测试样本，不包含任何内容',
      False, // 无BOM
      0,
      0,
      Tags
    );
    AddSample(Sample);
    
    // 只有BOM的文件 - UTF-8
    FilePath := TPath.Combine(FBasePath, 'utf8_only_bom.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    try
      Bytes := TEncoding.UTF8.GetPreamble;
      FileStream.WriteBuffer(Bytes, Length(Bytes));
    finally
      FileStream.Free;
    end;
    
    Tags := ['edge', 'bom_only', 'utf8'];
    Sample := TEncodingSample.Create(
      'utf8_only_bom.txt',
      FilePath,
      'UTF-8',
      '边界情况',
      '只包含UTF-8 BOM的文件，没有实际内容',
      True, // 有BOM
      TFile.GetSize(FilePath),
      0,
      Tags
    );
    AddSample(Sample);
    
    // 只有BOM的文件 - UTF-16LE
    FilePath := TPath.Combine(FBasePath, 'utf16le_only_bom.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    try
      Bytes := TEncoding.Unicode.GetPreamble;
      FileStream.WriteBuffer(Bytes, Length(Bytes));
    finally
      FileStream.Free;
    end;
    
    Tags := ['edge', 'bom_only', 'utf16le'];
    Sample := TEncodingSample.Create(
      'utf16le_only_bom.txt',
      FilePath,
      'UTF-16LE',
      '边界情况',
      '只包含UTF-16LE BOM的文件，没有实际内容',
      True, // 有BOM
      TFile.GetSize(FilePath),
      0,
      Tags
    );
    AddSample(Sample);
    
    // 非常大的文件 - 使用重复内容
    SampleText.Clear;
    SampleText.Add('这是一个非常大的文件样本，用于测试大文件的编码处理。');
    SampleText.Add('This is a very large file sample for testing encoding handling with large files.');
    
    // 重复内容100次以创建大文件
    var LargeContent := '';
    for var i := 1 to 100 do
      LargeContent := LargeContent + SampleText.Text + #13#10;
    
    FilePath := TPath.Combine(FBasePath, 'large_file.txt');
    TFile.WriteAllText(FilePath, LargeContent, TEncoding.UTF8);
    
    Tags := ['edge', 'large', 'performance'];
    Sample := TEncodingSample.Create(
      'large_file.txt',
      FilePath,
      'UTF-8',
      '边界情况',
      '大文件样本，用于测试大文件的编码处理性能',
      True, // 有BOM
      TFile.GetSize(FilePath),
      LargeContent.Length,
      Tags
    );
    AddSample(Sample);
    
    // 非法UTF-8序列的文件
    SampleText.Clear;
    SampleText.Add('包含非法UTF-8序列的文件');
    SampleText.Add('下面是一些合法内容');
    
    FilePath := TPath.Combine(FBasePath, 'invalid_utf8.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    try
      // 写入合法内容
      Bytes := TEncoding.UTF8.GetBytes(SampleText.Text);
      FileStream.WriteBuffer(Bytes, Length(Bytes));
      
      // 添加非法UTF-8序列 (0xC0 0xAF 是非法的UTF-8过长编码)
      var InvalidBytes: array[0..1] of Byte = ($C0, $AF);
      FileStream.WriteBuffer(InvalidBytes, 2);
      
      // 再写入一些合法内容
      Bytes := TEncoding.UTF8.GetBytes('这些是非法序列之后的合法内容');
      FileStream.WriteBuffer(Bytes, Length(Bytes));
    finally
      FileStream.Free;
    end;
    
    Tags := ['edge', 'invalid', 'utf8'];
    Sample := TEncodingSample.Create(
      'invalid_utf8.txt',
      FilePath,
      'UTF-8(含非法序列)',
      '边界情况',
      '包含非法UTF-8序列的文件，用于测试编码检测的健壮性',
      False, // 无BOM
      TFile.GetSize(FilePath),
      SampleText.Text.Length + 20, // 近似长度
      Tags
    );
    AddSample(Sample);
    
    // 混合行尾符号的文件
    SampleText.Clear;
    SampleText.Add('这是一个包含混合行尾符号的文件');
    SampleText.Add('This is a file with mixed line endings');
    
    FilePath := TPath.Combine(FBasePath, 'mixed_line_endings.txt');
    FileStream := TFileStream.Create(FilePath, fmCreate);
    try
      // 使用CR行尾
      Bytes := TEncoding.UTF8.GetBytes('第一行使用CR (\\r)');
      FileStream.WriteBuffer(Bytes, Length(Bytes));
      FileStream.WriteByte(13); // CR
      
      // 使用LF行尾
      Bytes := TEncoding.UTF8.GetBytes('第二行使用LF (\\n)');
      FileStream.WriteBuffer(Bytes, Length(Bytes));
      FileStream.WriteByte(10); // LF
      
      // 使用CRLF行尾
      Bytes := TEncoding.UTF8.GetBytes('第三行使用CRLF (\\r\\n)');
      FileStream.WriteBuffer(Bytes, Length(Bytes));
      FileStream.WriteByte(13); // CR
      FileStream.WriteByte(10); // LF
      
      // 无行尾的最后一行
      Bytes := TEncoding.UTF8.GetBytes('最后一行没有行尾符号');
      FileStream.WriteBuffer(Bytes, Length(Bytes));
    finally
      FileStream.Free;
    end;
    
    Tags := ['edge', 'line_endings', 'mixed'];
    Sample := TEncodingSample.Create(
      'mixed_line_endings.txt',
      FilePath,
      'UTF-8',
      '边界情况',
      '包含混合行尾符号(CR/LF/CRLF)的文件',
      False, // 无BOM
      TFile.GetSize(FilePath),
      100, // 近似长度
      Tags
    );
    AddSample(Sample);
  finally
    SampleText.Free;
  end;
end;

procedure TSampleRegistry.GenerateSampleReport(const AOutputPath: string);
var
  Report: TStringList;
  i: Integer;
  Sample: TEncodingSample;
begin
  Report := TStringList.Create;
  try
    Report.Add('编码测试样本报告');
    Report.Add('==================');
    Report.Add('');
    Report.Add(Format('总计样本数: %d', [FSamples.Count]));
    Report.Add(Format('报告生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add('');
    Report.Add('样本列表');
    Report.Add('==================');
    
    for i := 0 to FSamples.Count - 1 do
    begin
      Sample := FSamples[i];
      Report.Add(Format('[%d] %s', [i + 1, Sample.FileName]));
      Report.Add(Format('  路径: %s', [Sample.FilePath]));
      Report.Add(Format('  编码: %s', [Sample.Encoding]));
      Report.Add(Format('  类别: %s', [Sample.Category]));
      Report.Add(Format('  描述: %s', [Sample.Description]));
      Report.Add(Format('  大小: %d 字节, 约 %d 字符', [Sample.ByteSize, Sample.CharCount]));
      Report.Add(Format('  BOM: %s', [BoolToStr(Sample.HasBOM, True)]));
      
      if Length(Sample.Tags) > 0 then
        Report.Add(Format('  标签: %s', [string.Join(', ', Sample.Tags)]));
        
      Report.Add('');
    end;
    
    Report.SaveToFile(AOutputPath, TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;

procedure TSampleRegistry.ExportSampleIndex(const AOutputPath: string);
var
  Index: TStringList;
  i: Integer;
  Sample: TEncodingSample;
begin
  Index := TStringList.Create;
  try
    // 添加CSV表头
    Index.Add('文件名,编码,类别,描述,字节大小,字符数,有BOM,标签');
    
    for i := 0 to FSamples.Count - 1 do
    begin
      Sample := FSamples[i];
      
      // CSV格式的行
      Index.Add(Format('%s,%s,%s,%s,%d,%d,%s,%s',
        [
          Sample.FileName,
          Sample.Encoding,
          Sample.Category,
          StringReplace(Sample.Description, ',', ' ', [rfReplaceAll]), // 避免CSV歧义
          Sample.ByteSize,
          Sample.CharCount,
          BoolToStr(Sample.HasBOM, True),
          string.Join('|', Sample.Tags)
        ]));
    end;
    
    Index.SaveToFile(AOutputPath, TEncoding.UTF8);
  finally
    Index.Free;
  end;
end;

{ TEncodingSample }

constructor TEncodingSample.Create(const AFileName, AFilePath, AEncoding, ACategory, 
  ADescription: string; AHasBOM: Boolean; AByteSize: Int64; ACharCount: Integer;
  ATags: TArray<string>);
begin
  FileName := AFileName;
  FilePath := AFilePath;
  Encoding := AEncoding;
  Category := ACategory;
  Description := ADescription;
  HasBOM := AHasBOM;
  ByteSize := AByteSize;
  CharCount := ACharCount;
  CreatedAt := Now;
  Tags := ATags;
end;

end. 