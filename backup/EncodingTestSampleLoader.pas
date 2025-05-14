unit EncodingTestSampleLoader;

{
  EncodingTestSampleLoader.pas
  实现编码测试样本批量加载功能
  
  作为improve.md中任务2.1.1的实现
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Types;

type
  /// <summary>
  /// 测试样本的元数据信息
  /// </summary>
  TEncodingSampleMetadata = record
    FileName: string;           // 文件名
    FilePath: string;           // 文件完整路径
    KnownEncoding: string;      // 已知的编码（如果有）
    FileSize: Int64;            // 文件大小（字节）
    Description: string;        // 描述信息
    Tags: TArray<string>;       // 标签（如"中文"、"混合"等）
    CreationDate: TDateTime;    // 创建日期
    
    constructor Create(const AFilePath: string);
  end;

  /// <summary>
  /// 测试样本集合
  /// </summary>
  TEncodingSampleCollection = class
  private
    FSamples: TList<TEncodingSampleMetadata>;
    FMetadataCache: TDictionary<string, TEncodingSampleMetadata>;
    FTagIndex: TDictionary<string, TList<Integer>>;
    FEncodingIndex: TDictionary<string, TList<Integer>>;
    
    procedure BuildIndices;
    procedure ClearIndices;
    function ExtractEncodingFromFileName(const FileName: string): string;
    function ExtractTagsFromFileName(const FileName: string): TArray<string>;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 加载指定目录中的所有测试样本
    /// </summary>
    procedure LoadFromDirectory(const Directory: string; Recursive: Boolean = False);
    
    /// <summary>
    /// 加载指定文件列表中的测试样本
    /// </summary>
    procedure LoadFromFiles(const Files: TArray<string>);
    
    /// <summary>
    /// 加载指定文件中的测试样本
    /// </summary>
    procedure LoadFromFile(const FilePath: string);
    
    /// <summary>
    /// 根据编码筛选样本
    /// </summary>
    function FilterByEncoding(const Encoding: string): TArray<TEncodingSampleMetadata>;
    
    /// <summary>
    /// 根据标签筛选样本
    /// </summary>
    function FilterByTag(const Tag: string): TArray<TEncodingSampleMetadata>;
    
    /// <summary>
    /// 根据文件大小范围筛选样本
    /// </summary>
    function FilterBySize(MinSize, MaxSize: Int64): TArray<TEncodingSampleMetadata>;
    
    /// <summary>
    /// 获取所有样本
    /// </summary>
    function GetAllSamples: TArray<TEncodingSampleMetadata>;
    
    /// <summary>
    /// 获取所有可用的编码类型
    /// </summary>
    function GetAvailableEncodings: TArray<string>;
    
    /// <summary>
    /// 获取所有可用的标签
    /// </summary>
    function GetAvailableTags: TArray<string>;
    
    /// <summary>
    /// 获取样本数量
    /// </summary>
    function GetCount: Integer;
    
    /// <summary>
    /// 清空样本集合
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// 保存样本元数据到文件
    /// </summary>
    procedure SaveMetadataToFile(const FilePath: string);
    
    /// <summary>
    /// 从文件加载样本元数据
    /// </summary>
    procedure LoadMetadataFromFile(const FilePath: string);
    
    property Count: Integer read GetCount;
  end;

  /// <summary>
  /// 测试样本加载器
  /// </summary>
  TEncodingTestSampleLoader = class
  private
    FSampleCollections: TDictionary<string, TEncodingSampleCollection>;
    FDefaultCollection: TEncodingSampleCollection;
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 加载指定目录中的所有测试样本
    /// </summary>
    procedure LoadFromDirectory(const Directory: string; Recursive: Boolean = False; const CollectionName: string = '');
    
    /// <summary>
    /// 加载指定文件列表中的测试样本
    /// </summary>
    procedure LoadFromFiles(const Files: TArray<string>; const CollectionName: string = '');
    
    /// <summary>
    /// 获取指定名称的样本集合
    /// </summary>
    function GetCollection(const Name: string = ''): TEncodingSampleCollection;
    
    /// <summary>
    /// 获取所有样本集合名称
    /// </summary>
    function GetCollectionNames: TArray<string>;
    
    /// <summary>
    /// 创建新的样本集合
    /// </summary>
    function CreateCollection(const Name: string): TEncodingSampleCollection;
    
    /// <summary>
    /// 删除指定名称的样本集合
    /// </summary>
    procedure RemoveCollection(const Name: string);
    
    /// <summary>
    /// 清空所有样本集合
    /// </summary>
    procedure ClearAll;
    
    /// <summary>
    /// 保存所有样本集合元数据到目录
    /// </summary>
    procedure SaveMetadataToDirectory(const Directory: string);
    
    /// <summary>
    /// 从目录加载所有样本集合元数据
    /// </summary>
    procedure LoadMetadataFromDirectory(const Directory: string);
    
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

{ TEncodingSampleMetadata }

constructor TEncodingSampleMetadata.Create(const AFilePath: string);
var
  FileInfo: TFileInfo;
begin
  FilePath := AFilePath;
  FileName := ExtractFileName(AFilePath);
  
  if FileExists(AFilePath) then
  begin
    FileInfo := TFile.GetFileInfo(AFilePath);
    FileSize := FileInfo.Size;
    CreationDate := FileInfo.CreationTime;
  end
  else
  begin
    FileSize := 0;
    CreationDate := 0;
  end;
  
  KnownEncoding := '';
  Description := '';
  Tags := [];
end;

{ TEncodingSampleCollection }

constructor TEncodingSampleCollection.Create;
begin
  inherited Create;
  FSamples := TList<TEncodingSampleMetadata>.Create;
  FMetadataCache := TDictionary<string, TEncodingSampleMetadata>.Create;
  FTagIndex := TDictionary<string, TList<Integer>>.Create;
  FEncodingIndex := TDictionary<string, TList<Integer>>.Create;
end;

destructor TEncodingSampleCollection.Destroy;
begin
  Clear;
  ClearIndices;
  FMetadataCache.Free;
  FSamples.Free;
  FTagIndex.Free;
  FEncodingIndex.Free;
  inherited;
end;

procedure TEncodingSampleCollection.BuildIndices;
var
  I: Integer;
  Sample: TEncodingSampleMetadata;
  Tag: string;
  TagList: TList<Integer>;
  EncodingList: TList<Integer>;
begin
  ClearIndices;
  
  for I := 0 to FSamples.Count - 1 do
  begin
    Sample := FSamples[I];
    
    // 构建编码索引
    if Sample.KnownEncoding <> '' then
    begin
      if not FEncodingIndex.TryGetValue(Sample.KnownEncoding, EncodingList) then
      begin
        EncodingList := TList<Integer>.Create;
        FEncodingIndex.Add(Sample.KnownEncoding, EncodingList);
      end;
      EncodingList.Add(I);
    end;
    
    // 构建标签索引
    for Tag in Sample.Tags do
    begin
      if not FTagIndex.TryGetValue(Tag, TagList) then
      begin
        TagList := TList<Integer>.Create;
        FTagIndex.Add(Tag, TagList);
      end;
      TagList.Add(I);
    end;
  end;
end;

procedure TEncodingSampleCollection.Clear;
begin
  FSamples.Clear;
  FMetadataCache.Clear;
  ClearIndices;
end;

procedure TEncodingSampleCollection.ClearIndices;
var
  TagList: TList<Integer>;
  EncodingList: TList<Integer>;
begin
  // 清理标签索引
  for TagList in FTagIndex.Values do
    TagList.Free;
  FTagIndex.Clear;
  
  // 清理编码索引
  for EncodingList in FEncodingIndex.Values do
    EncodingList.Free;
  FEncodingIndex.Clear;
end;

function TEncodingSampleCollection.ExtractEncodingFromFileName(const FileName: string): string;
begin
  Result := '';
  
  // 从文件名中提取编码信息
  // 例如：UTF8-WithBOM.txt -> UTF-8 with BOM
  if FileName.Contains('UTF8') or FileName.Contains('UTF-8') then
  begin
    if FileName.Contains('BOM') or FileName.Contains('bom') then
    begin
      if FileName.Contains('Without') or FileName.Contains('NoBOM') or FileName.Contains('No-BOM') then
        Result := 'UTF-8'
      else
        Result := 'UTF-8 with BOM';
    end
    else
      Result := 'UTF-8';
  end
  else if FileName.Contains('UTF16LE') or FileName.Contains('UTF-16LE') then
    Result := 'UTF-16LE'
  else if FileName.Contains('UTF16BE') or FileName.Contains('UTF-16BE') then
    Result := 'UTF-16BE'
  else if FileName.Contains('UTF32LE') or FileName.Contains('UTF-32LE') then
    Result := 'UTF-32LE'
  else if FileName.Contains('UTF32BE') or FileName.Contains('UTF-32BE') then
    Result := 'UTF-32BE'
  else if FileName.Contains('GBK') then
    Result := 'GBK'
  else if FileName.Contains('GB18030') then
    Result := 'GB18030'
  else if FileName.Contains('GB2312') then
    Result := 'GB2312'
  else if FileName.Contains('Big5') or FileName.Contains('BIG5') then
    Result := 'Big5'
  else if FileName.Contains('ASCII') then
    Result := 'ASCII'
  else if FileName.Contains('ANSI') then
    Result := 'ANSI';
end;

function TEncodingSampleCollection.ExtractTagsFromFileName(const FileName: string): TArray<string>;
var
  Tags: TList<string>;
begin
  Tags := TList<string>.Create;
  try
    // 从文件名中提取标签信息
    if FileName.Contains('Chinese') or FileName.Contains('中文') then
      Tags.Add('Chinese');
    
    if FileName.Contains('English') or FileName.Contains('英文') then
      Tags.Add('English');
    
    if FileName.Contains('Mixed') or FileName.Contains('混合') then
      Tags.Add('Mixed');
    
    if FileName.Contains('Special') or FileName.Contains('特殊') then
      Tags.Add('Special');
    
    if FileName.Contains('Large') or FileName.Contains('大文件') then
      Tags.Add('Large');
    
    if FileName.Contains('Small') or FileName.Contains('小文件') then
      Tags.Add('Small');
    
    if FileName.Contains('Invalid') or FileName.Contains('无效') then
      Tags.Add('Invalid');
    
    if FileName.Contains('Damaged') or FileName.Contains('损坏') then
      Tags.Add('Damaged');
    
    Result := Tags.ToArray;
  finally
    Tags.Free;
  end;
end;

function TEncodingSampleCollection.FilterByEncoding(const Encoding: string): TArray<TEncodingSampleMetadata>;
var
  EncodingList: TList<Integer>;
  ResultList: TList<TEncodingSampleMetadata>;
  I: Integer;
begin
  ResultList := TList<TEncodingSampleMetadata>.Create;
  try
    if FEncodingIndex.TryGetValue(Encoding, EncodingList) then
    begin
      for I in EncodingList do
        ResultList.Add(FSamples[I]);
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TEncodingSampleCollection.FilterBySize(MinSize, MaxSize: Int64): TArray<TEncodingSampleMetadata>;
var
  ResultList: TList<TEncodingSampleMetadata>;
  Sample: TEncodingSampleMetadata;
begin
  ResultList := TList<TEncodingSampleMetadata>.Create;
  try
    for Sample in FSamples do
    begin
      if (Sample.FileSize >= MinSize) and ((MaxSize <= 0) or (Sample.FileSize <= MaxSize)) then
        ResultList.Add(Sample);
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TEncodingSampleCollection.FilterByTag(const Tag: string): TArray<TEncodingSampleMetadata>;
var
  TagList: TList<Integer>;
  ResultList: TList<TEncodingSampleMetadata>;
  I: Integer;
begin
  ResultList := TList<TEncodingSampleMetadata>.Create;
  try
    if FTagIndex.TryGetValue(Tag, TagList) then
    begin
      for I in TagList do
        ResultList.Add(FSamples[I]);
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TEncodingSampleCollection.GetAllSamples: TArray<TEncodingSampleMetadata>;
begin
  Result := FSamples.ToArray;
end;

function TEncodingSampleCollection.GetAvailableEncodings: TArray<string>;
begin
  Result := FEncodingIndex.Keys.ToArray;
end;

function TEncodingSampleCollection.GetAvailableTags: TArray<string>;
begin
  Result := FTagIndex.Keys.ToArray;
end;

function TEncodingSampleCollection.GetCount: Integer;
begin
  Result := FSamples.Count;
end;

procedure TEncodingSampleCollection.LoadFromDirectory(const Directory: string; Recursive: Boolean);
var
  Files: TArray<string>;
  SearchOption: TSearchOption;
begin
  if not DirectoryExists(Directory) then
    Exit;
  
  if Recursive then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
  
  Files := TDirectory.GetFiles(Directory, '*.*', SearchOption);
  LoadFromFiles(Files);
end;

procedure TEncodingSampleCollection.LoadFromFile(const FilePath: string);
var
  Sample: TEncodingSampleMetadata;
begin
  if not FileExists(FilePath) then
    Exit;
  
  // 检查是否已经加载过该文件
  if FMetadataCache.TryGetValue(FilePath, Sample) then
  begin
    FSamples.Add(Sample);
    Exit;
  end;
  
  // 创建新的样本元数据
  Sample := TEncodingSampleMetadata.Create(FilePath);
  
  // 尝试从文件名中提取编码信息
  Sample.KnownEncoding := ExtractEncodingFromFileName(Sample.FileName);
  
  // 尝试从文件名中提取标签信息
  Sample.Tags := ExtractTagsFromFileName(Sample.FileName);
  
  // 添加到样本列表和缓存
  FSamples.Add(Sample);
  FMetadataCache.Add(FilePath, Sample);
end;

procedure TEncodingSampleCollection.LoadFromFiles(const Files: TArray<string>);
var
  FilePath: string;
begin
  for FilePath in Files do
    LoadFromFile(FilePath);
  
  // 重建索引
  BuildIndices;
end;

procedure TEncodingSampleCollection.LoadMetadataFromFile(const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  JsonValue: TJSONValue;
  Sample: TEncodingSampleMetadata;
  TagsArray: TJSONArray;
  I, J: Integer;
begin
  if not FileExists(FilePath) then
    Exit;
  
  Clear;
  
  try
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(FilePath)) as TJSONObject;
    try
      if Json = nil then
        Exit;
      
      JsonArray := Json.GetValue('samples') as TJSONArray;
      if JsonArray = nil then
        Exit;
      
      for I := 0 to JsonArray.Count - 1 do
      begin
        JsonValue := JsonArray.Items[I];
        if JsonValue is TJSONObject then
        begin
          Sample.FilePath := (JsonValue as TJSONObject).GetValue('filePath').Value;
          Sample.FileName := (JsonValue as TJSONObject).GetValue('fileName').Value;
          Sample.KnownEncoding := (JsonValue as TJSONObject).GetValue('knownEncoding').Value;
          Sample.FileSize := StrToInt64Def((JsonValue as TJSONObject).GetValue('fileSize').Value, 0);
          Sample.Description := (JsonValue as TJSONObject).GetValue('description').Value;
          Sample.CreationDate := ISO8601ToDate((JsonValue as TJSONObject).GetValue('creationDate').Value);
          
          TagsArray := (JsonValue as TJSONObject).GetValue('tags') as TJSONArray;
          SetLength(Sample.Tags, TagsArray.Count);
          for J := 0 to TagsArray.Count - 1 do
            Sample.Tags[J] := TagsArray.Items[J].Value;
          
          FSamples.Add(Sample);
          FMetadataCache.Add(Sample.FilePath, Sample);
        end;
      end;
      
      // 重建索引
      BuildIndices;
    finally
      Json.Free;
    end;
  except
    // 忽略解析错误
  end;
end;

procedure TEncodingSampleCollection.SaveMetadataToFile(const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  SampleJson: TJSONObject;
  TagsArray: TJSONArray;
  Sample: TEncodingSampleMetadata;
  Tag: string;
begin
  Json := TJSONObject.Create;
  try
    JsonArray := TJSONArray.Create;
    Json.AddPair('samples', JsonArray);
    
    for Sample in FSamples do
    begin
      SampleJson := TJSONObject.Create;
      SampleJson.AddPair('filePath', Sample.FilePath);
      SampleJson.AddPair('fileName', Sample.FileName);
      SampleJson.AddPair('knownEncoding', Sample.KnownEncoding);
      SampleJson.AddPair('fileSize', TJSONNumber.Create(Sample.FileSize));
      SampleJson.AddPair('description', Sample.Description);
      SampleJson.AddPair('creationDate', DateToISO8601(Sample.CreationDate));
      
      TagsArray := TJSONArray.Create;
      for Tag in Sample.Tags do
        TagsArray.Add(Tag);
      
      SampleJson.AddPair('tags', TagsArray);
      JsonArray.Add(SampleJson);
    end;
    
    TFile.WriteAllText(FilePath, Json.ToString);
  finally
    Json.Free;
  end;
end;

{ TEncodingTestSampleLoader }

constructor TEncodingTestSampleLoader.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FSampleCollections := TDictionary<string, TEncodingSampleCollection>.Create;
  FDefaultCollection := TEncodingSampleCollection.Create;
  FLogCallback := ALogCallback;
end;

destructor TEncodingTestSampleLoader.Destroy;
begin
  ClearAll;
  FDefaultCollection.Free;
  FSampleCollections.Free;
  inherited;
end;

procedure TEncodingTestSampleLoader.ClearAll;
var
  Collection: TEncodingSampleCollection;
begin
  for Collection in FSampleCollections.Values do
    Collection.Free;
  
  FSampleCollections.Clear;
  FDefaultCollection.Clear;
end;

function TEncodingTestSampleLoader.CreateCollection(const Name: string): TEncodingSampleCollection;
var
  Collection: TEncodingSampleCollection;
begin
  // 如果集合已存在，返回现有集合
  if Name = '' then
    Result := FDefaultCollection
  else if FSampleCollections.TryGetValue(Name, Collection) then
    Result := Collection
  else
  begin
    // 创建新集合
    Collection := TEncodingSampleCollection.Create;
    FSampleCollections.Add(Name, Collection);
    Result := Collection;
  end;
end;

function TEncodingTestSampleLoader.GetCollection(const Name: string): TEncodingSampleCollection;
begin
  if Name = '' then
    Result := FDefaultCollection
  else if not FSampleCollections.TryGetValue(Name, Result) then
    Result := nil;
end;

function TEncodingTestSampleLoader.GetCollectionNames: TArray<string>;
begin
  Result := FSampleCollections.Keys.ToArray;
end;

procedure TEncodingTestSampleLoader.LoadFromDirectory(const Directory: string; Recursive: Boolean; const CollectionName: string);
var
  Collection: TEncodingSampleCollection;
begin
  Log(Format('正在从目录加载测试样本: %s (递归: %s)', [Directory, BoolToStr(Recursive, True)]));
  
  Collection := CreateCollection(CollectionName);
  Collection.LoadFromDirectory(Directory, Recursive);
  
  Log(Format('已加载 %d 个测试样本到集合: %s', [Collection.Count, IfThen(CollectionName = '', '默认集合', CollectionName)]));
end;

procedure TEncodingTestSampleLoader.LoadFromFiles(const Files: TArray<string>; const CollectionName: string);
var
  Collection: TEncodingSampleCollection;
begin
  Log(Format('正在加载 %d 个测试样本文件', [Length(Files)]));
  
  Collection := CreateCollection(CollectionName);
  Collection.LoadFromFiles(Files);
  
  Log(Format('已加载 %d 个测试样本到集合: %s', [Collection.Count, IfThen(CollectionName = '', '默认集合', CollectionName)]));
end;

procedure TEncodingTestSampleLoader.LoadMetadataFromDirectory(const Directory: string);
var
  Files: TArray<string>;
  FilePath: string;
  CollectionName: string;
  Collection: TEncodingSampleCollection;
begin
  if not DirectoryExists(Directory) then
    Exit;
  
  Log(Format('正在从目录加载元数据: %s', [Directory]));
  
  Files := TDirectory.GetFiles(Directory, '*.json');
  for FilePath in Files do
  begin
    CollectionName := ChangeFileExt(ExtractFileName(FilePath), '');
    Collection := CreateCollection(CollectionName);
    Collection.LoadMetadataFromFile(FilePath);
    
    Log(Format('已加载元数据: %s (%d 个样本)', [CollectionName, Collection.Count]));
  end;
end;

procedure TEncodingTestSampleLoader.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingTestSampleLoader.RemoveCollection(const Name: string);
var
  Collection: TEncodingSampleCollection;
begin
  if Name = '' then
    FDefaultCollection.Clear
  else if FSampleCollections.TryGetValue(Name, Collection) then
  begin
    Collection.Free;
    FSampleCollections.Remove(Name);
  end;
end;

procedure TEncodingTestSampleLoader.SaveMetadataToDirectory(const Directory: string);
var
  CollectionName: string;
  Collection: TEncodingSampleCollection;
  FilePath: string;
begin
  if not DirectoryExists(Directory) then
    ForceDirectories(Directory);
  
  Log(Format('正在保存元数据到目录: %s', [Directory]));
  
  // 保存默认集合
  if FDefaultCollection.Count > 0 then
  begin
    FilePath := TPath.Combine(Directory, 'default.json');
    FDefaultCollection.SaveMetadataToFile(FilePath);
    Log(Format('已保存默认集合元数据: %s (%d 个样本)', [FilePath, FDefaultCollection.Count]));
  end;
  
  // 保存其他集合
  for CollectionName in FSampleCollections.Keys do
  begin
    Collection := FSampleCollections[CollectionName];
    if Collection.Count > 0 then
    begin
      FilePath := TPath.Combine(Directory, CollectionName + '.json');
      Collection.SaveMetadataToFile(FilePath);
      Log(Format('已保存集合元数据: %s (%d 个样本)', [FilePath, Collection.Count]));
    end;
  end;
end;

end.
