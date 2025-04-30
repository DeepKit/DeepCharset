unit TestStandardSamplesTest;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  TestFramework, TestStandardSamples;

type
  TStandardSamplesTest = class(TTestCase)
  private
    FSampleRegistry: TSampleRegistry;
    FTempPath: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSampleCreation;
    procedure TestSampleRetrieval;
    procedure TestCategorySamples;
    procedure TestEncodingSamples;
    procedure TestReportGeneration;
    procedure TestSampleIndex;
  end;

implementation

procedure TStandardSamplesTest.SetUp;
begin
  FTempPath := TPath.Combine(TPath.GetTempPath, 'EncodingTestSamples');
  if not TDirectory.Exists(FTempPath) then
    TDirectory.CreateDirectory(FTempPath);
    
  FSampleRegistry := TSampleRegistry.Create(FTempPath);
end;

procedure TStandardSamplesTest.TearDown;
begin
  FSampleRegistry.Free;
  
  if TDirectory.Exists(FTempPath) then
  begin
    // 删除临时目录下的所有文件
    TDirectory.Delete(FTempPath, True);
  end;
end;

procedure TStandardSamplesTest.TestSampleCreation;
begin
  // 生成标准测试集
  FSampleRegistry.GenerateStandardTestSet;
  
  // 验证至少有5个样本被创建
  CheckTrue(FSampleRegistry.GetSampleCount > 5, '应该至少生成5个样本');
  
  // 验证样本文件是否存在
  CheckTrue(TFile.Exists(TPath.Combine(FTempPath, 'ascii_sample.txt')), 'ASCII样本文件应该存在');
  CheckTrue(TFile.Exists(TPath.Combine(FTempPath, 'utf8_sample.txt')), 'UTF-8样本文件应该存在');
  CheckTrue(TFile.Exists(TPath.Combine(FTempPath, 'utf16le_sample.txt')), 'UTF-16LE样本文件应该存在');
  CheckTrue(TFile.Exists(TPath.Combine(FTempPath, 'utf16be_sample.txt')), 'UTF-16BE样本文件应该存在');
  CheckTrue(TFile.Exists(TPath.Combine(FTempPath, 'gbk_sample.txt')), 'GBK样本文件应该存在');
end;

procedure TStandardSamplesTest.TestSampleRetrieval;
var
  Sample: TEncodingSample;
begin
  FSampleRegistry.GenerateStandardTestSet;
  
  // 测试获取样本
  Sample := FSampleRegistry.GetSampleByIndex(0);
  CheckNotEquals('', Sample.FileName, '样本文件名不应为空');
  CheckNotEquals('', Sample.Encoding, '样本编码不应为空');
  
  // 测试获取指定样本
  // 查找UTF-8样本
  for var i := 0 to FSampleRegistry.GetSampleCount - 1 do
  begin
    Sample := FSampleRegistry.GetSampleByIndex(i);
    if Sample.FileName = 'utf8_sample.txt' then
    begin
      CheckEquals('UTF-8', Sample.Encoding, 'UTF-8样本编码应正确');
      CheckEquals('纯文本', Sample.Category, 'UTF-8样本类别应正确');
      Break;
    end;
  end;
end;

procedure TStandardSamplesTest.TestCategorySamples;
var
  CategorySamples: TArray<TEncodingSample>;
begin
  FSampleRegistry.GenerateStandardTestSet;
  
  // 测试按类别筛选
  CategorySamples := FSampleRegistry.GetSamplesByCategory('纯文本');
  CheckTrue(Length(CategorySamples) > 0, '应至少有一个纯文本类别样本');
  
  CategorySamples := FSampleRegistry.GetSamplesByCategory('特殊字符');
  CheckTrue(Length(CategorySamples) > 0, '应至少有一个特殊字符类别样本');
  
  CategorySamples := FSampleRegistry.GetSamplesByCategory('边界情况');
  CheckTrue(Length(CategorySamples) > 0, '应至少有一个边界情况类别样本');
end;

procedure TStandardSamplesTest.TestEncodingSamples;
var
  EncodingSamples: TArray<TEncodingSample>;
begin
  FSampleRegistry.GenerateStandardTestSet;
  
  // 测试按编码筛选
  EncodingSamples := FSampleRegistry.GetSamplesByEncoding('UTF-8');
  CheckTrue(Length(EncodingSamples) > 0, '应至少有一个UTF-8编码样本');
  
  EncodingSamples := FSampleRegistry.GetSamplesByEncoding('UTF-16LE');
  CheckTrue(Length(EncodingSamples) > 0, '应至少有一个UTF-16LE编码样本');
  
  EncodingSamples := FSampleRegistry.GetSamplesByEncoding('ASCII');
  CheckTrue(Length(EncodingSamples) > 0, '应至少有一个ASCII编码样本');
end;

procedure TStandardSamplesTest.TestReportGeneration;
var
  ReportPath: string;
begin
  FSampleRegistry.GenerateStandardTestSet;
  
  ReportPath := TPath.Combine(FTempPath, 'test_report.txt');
  FSampleRegistry.GenerateSampleReport(ReportPath);
  
  CheckTrue(TFile.Exists(ReportPath), '样本报告文件应该存在');
  CheckTrue(TFile.GetSize(ReportPath) > 0, '样本报告不应为空');
end;

procedure TStandardSamplesTest.TestSampleIndex;
var
  IndexPath: string;
begin
  FSampleRegistry.GenerateStandardTestSet;
  
  IndexPath := TPath.Combine(FTempPath, 'test_index.csv');
  FSampleRegistry.ExportSampleIndex(IndexPath);
  
  CheckTrue(TFile.Exists(IndexPath), '样本索引文件应该存在');
  CheckTrue(TFile.GetSize(IndexPath) > 0, '样本索引不应为空');
end;

initialization
  RegisterTest(TStandardSamplesTest.Suite);
end. 