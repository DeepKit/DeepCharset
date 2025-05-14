unit TestEncodingTestSampleLoader;

{
  TestEncodingTestSampleLoader.pas
  测试编码测试样本批量加载功能
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingTestSampleLoader;

type
  TEncodingTestSampleLoaderTests = class
  private
    FSampleLoader: TEncodingTestSampleLoader;
    
    procedure LogMessage(const Msg: string);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure RunAllTests;
    
    // 测试方法
    procedure TestLoadFromDirectory;
    procedure TestLoadFromFiles;
    procedure TestFilterByEncoding;
    procedure TestFilterByTag;
    procedure TestFilterBySize;
    procedure TestSaveAndLoadMetadata;
    procedure TestMultipleCollections;
  end;

implementation

{ TEncodingTestSampleLoaderTests }

constructor TEncodingTestSampleLoaderTests.Create;
begin
  inherited Create;
  FSampleLoader := TEncodingTestSampleLoader.Create(LogMessage);
end;

destructor TEncodingTestSampleLoaderTests.Destroy;
begin
  FSampleLoader.Free;
  inherited;
end;

procedure TEncodingTestSampleLoaderTests.LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure TEncodingTestSampleLoaderTests.RunAllTests;
begin
  try
    Writeln('开始测试编码测试样本批量加载功能...');
    Writeln('----------------------------------------');
    
    TestLoadFromDirectory;
    TestLoadFromFiles;
    TestFilterByEncoding;
    TestFilterByTag;
    TestFilterBySize;
    TestSaveAndLoadMetadata;
    TestMultipleCollections;
    
    Writeln('----------------------------------------');
    Writeln('所有测试完成！');
  except
    on E: Exception do
      Writeln('测试过程中发生错误: ' + E.Message);
  end;
end;

procedure TEncodingTestSampleLoaderTests.TestFilterByEncoding;
var
  Collection: TEncodingSampleCollection;
  Samples: TArray<TEncodingSampleMetadata>;
begin
  Writeln('测试按编码筛选样本...');
  
  Collection := FSampleLoader.GetCollection;
  if Collection.Count = 0 then
  begin
    Writeln('  警告: 没有可用的样本，跳过测试');
    Exit;
  end;
  
  // 测试筛选UTF-8编码的样本
  Samples := Collection.FilterByEncoding('UTF-8');
  Writeln(Format('  找到 %d 个UTF-8编码的样本', [Length(Samples)]));
  
  // 测试筛选UTF-8 with BOM编码的样本
  Samples := Collection.FilterByEncoding('UTF-8 with BOM');
  Writeln(Format('  找到 %d 个UTF-8 with BOM编码的样本', [Length(Samples)]));
  
  // 测试筛选GBK编码的样本
  Samples := Collection.FilterByEncoding('GBK');
  Writeln(Format('  找到 %d 个GBK编码的样本', [Length(Samples)]));
  
  Writeln('按编码筛选样本测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestFilterBySize;
var
  Collection: TEncodingSampleCollection;
  Samples: TArray<TEncodingSampleMetadata>;
begin
  Writeln('测试按文件大小筛选样本...');
  
  Collection := FSampleLoader.GetCollection;
  if Collection.Count = 0 then
  begin
    Writeln('  警告: 没有可用的样本，跳过测试');
    Exit;
  end;
  
  // 测试筛选小文件（<1KB）
  Samples := Collection.FilterBySize(0, 1024);
  Writeln(Format('  找到 %d 个小文件（<1KB）', [Length(Samples)]));
  
  // 测试筛选中等文件（1KB-100KB）
  Samples := Collection.FilterBySize(1024, 102400);
  Writeln(Format('  找到 %d 个中等文件（1KB-100KB）', [Length(Samples)]));
  
  // 测试筛选大文件（>100KB）
  Samples := Collection.FilterBySize(102400, 0);
  Writeln(Format('  找到 %d 个大文件（>100KB）', [Length(Samples)]));
  
  Writeln('按文件大小筛选样本测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestFilterByTag;
var
  Collection: TEncodingSampleCollection;
  Samples: TArray<TEncodingSampleMetadata>;
  Tags: TArray<string>;
  Tag: string;
begin
  Writeln('测试按标签筛选样本...');
  
  Collection := FSampleLoader.GetCollection;
  if Collection.Count = 0 then
  begin
    Writeln('  警告: 没有可用的样本，跳过测试');
    Exit;
  end;
  
  // 获取所有可用标签
  Tags := Collection.GetAvailableTags;
  Writeln(Format('  找到 %d 个可用标签', [Length(Tags)]));
  
  // 测试筛选每个标签的样本
  for Tag in Tags do
  begin
    Samples := Collection.FilterByTag(Tag);
    Writeln(Format('  找到 %d 个标签为"%s"的样本', [Length(Samples), Tag]));
  end;
  
  Writeln('按标签筛选样本测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestLoadFromDirectory;
var
  TestDataDir: string;
  Collection: TEncodingSampleCollection;
begin
  Writeln('测试从目录加载样本...');
  
  // 尝试从几个可能的测试数据目录加载
  TestDataDir := 'TestData\EncodingSamples';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'tests\test_files';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'test_files';
  
  if not DirectoryExists(TestDataDir) then
  begin
    Writeln('  警告: 找不到测试数据目录，跳过测试');
    Exit;
  end;
  
  // 加载测试样本
  FSampleLoader.LoadFromDirectory(TestDataDir, False);
  
  // 验证加载结果
  Collection := FSampleLoader.GetCollection;
  Writeln(Format('  已加载 %d 个测试样本', [Collection.Count]));
  
  // 显示可用的编码类型
  var Encodings := Collection.GetAvailableEncodings;
  Writeln(Format('  找到 %d 种编码类型: %s', 
    [Length(Encodings), string.Join(', ', Encodings)]));
  
  Writeln('从目录加载样本测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestLoadFromFiles;
var
  TestDataDir: string;
  Files: TArray<string>;
begin
  Writeln('测试从文件列表加载样本...');
  
  // 尝试从几个可能的测试数据目录获取文件
  TestDataDir := 'TestData\EncodingSamples';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'tests\test_files';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'test_files';
  
  if not DirectoryExists(TestDataDir) then
  begin
    Writeln('  警告: 找不到测试数据目录，跳过测试');
    Exit;
  end;
  
  // 获取测试文件
  Files := TDirectory.GetFiles(TestDataDir, '*.txt');
  if Length(Files) = 0 then
  begin
    Writeln('  警告: 找不到测试文件，跳过测试');
    Exit;
  end;
  
  // 清空现有样本
  FSampleLoader.ClearAll;
  
  // 加载测试样本
  FSampleLoader.LoadFromFiles(Files);
  
  // 验证加载结果
  var Collection := FSampleLoader.GetCollection;
  Writeln(Format('  已加载 %d 个测试样本', [Collection.Count]));
  
  // 显示样本文件名
  var AllSamples := Collection.GetAllSamples;
  for var I := 0 to Min(5, Length(AllSamples) - 1) do
    Writeln(Format('  样本 %d: %s (%s)', [I + 1, AllSamples[I].FileName, AllSamples[I].KnownEncoding]));
  
  if Length(AllSamples) > 5 then
    Writeln('  ...(更多样本)');
  
  Writeln('从文件列表加载样本测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestMultipleCollections;
var
  Collection1, Collection2: TEncodingSampleCollection;
  TestDataDir: string;
  Files: TArray<string>;
  CollectionNames: TArray<string>;
begin
  Writeln('测试多个样本集合...');
  
  // 尝试从几个可能的测试数据目录获取文件
  TestDataDir := 'TestData\EncodingSamples';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'tests\test_files';
  if not DirectoryExists(TestDataDir) then
    TestDataDir := 'test_files';
  
  if not DirectoryExists(TestDataDir) then
  begin
    Writeln('  警告: 找不到测试数据目录，跳过测试');
    Exit;
  end;
  
  // 获取测试文件
  Files := TDirectory.GetFiles(TestDataDir, '*.txt');
  if Length(Files) = 0 then
  begin
    Writeln('  警告: 找不到测试文件，跳过测试');
    Exit;
  end;
  
  // 清空现有样本
  FSampleLoader.ClearAll;
  
  // 创建两个不同的集合
  Collection1 := FSampleLoader.CreateCollection('UTF8Samples');
  Collection2 := FSampleLoader.CreateCollection('GBKSamples');
  
  // 加载UTF-8样本
  for var FilePath in Files do
  begin
    if FilePath.Contains('UTF8') or FilePath.Contains('UTF-8') then
      Collection1.LoadFromFile(FilePath);
  end;
  
  // 加载GBK样本
  for var FilePath in Files do
  begin
    if FilePath.Contains('GBK') then
      Collection2.LoadFromFile(FilePath);
  end;
  
  // 验证集合
  Writeln(Format('  UTF8Samples集合: %d 个样本', [Collection1.Count]));
  Writeln(Format('  GBKSamples集合: %d 个样本', [Collection2.Count]));
  
  // 获取所有集合名称
  CollectionNames := FSampleLoader.GetCollectionNames;
  Writeln(Format('  找到 %d 个样本集合: %s', 
    [Length(CollectionNames), string.Join(', ', CollectionNames)]));
  
  Writeln('多个样本集合测试完成');
end;

procedure TEncodingTestSampleLoaderTests.TestSaveAndLoadMetadata;
var
  Collection: TEncodingSampleCollection;
  MetadataDir: string;
  MetadataFile: string;
begin
  Writeln('测试保存和加载元数据...');
  
  Collection := FSampleLoader.GetCollection;
  if Collection.Count = 0 then
  begin
    Writeln('  警告: 没有可用的样本，跳过测试');
    Exit;
  end;
  
  // 创建临时目录
  MetadataDir := TPath.Combine(TPath.GetTempPath, 'EncodingTestMetadata');
  if not DirectoryExists(MetadataDir) then
    ForceDirectories(MetadataDir);
  
  // 保存元数据
  FSampleLoader.SaveMetadataToDirectory(MetadataDir);
  
  // 清空现有样本
  FSampleLoader.ClearAll;
  
  // 加载元数据
  FSampleLoader.LoadMetadataFromDirectory(MetadataDir);
  
  // 验证加载结果
  Collection := FSampleLoader.GetCollection;
  Writeln(Format('  从元数据加载了 %d 个测试样本', [Collection.Count]));
  
  // 清理临时文件
  MetadataFile := TPath.Combine(MetadataDir, 'default.json');
  if FileExists(MetadataFile) then
    DeleteFile(MetadataFile);
  
  if DirectoryExists(MetadataDir) then
    RemoveDir(MetadataDir);
  
  Writeln('保存和加载元数据测试完成');
end;

end.
