program EncodingTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclEncodingUtils,
  UtilsTypes;

const
  TEST_DIR = 'encoding_tests';
  RESULTS_FILE = 'encoding_test_results.md';

type
  TEncodingTestItem = record
    EncodingName: string;
    CodePage: Integer;
    Description: string;
  end;

// 获取所有要测试的编码
function GetEncodingsToTest: TArray<TEncodingTestItem>;
begin
  SetLength(Result, 0);
  
  // 添加Unicode编码系列
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'UTF-8';
  Result[High(Result)].CodePage := 65001;
  Result[High(Result)].Description := 'UTF-8 (无BOM)';
  
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'UTF-8 with BOM';
  Result[High(Result)].CodePage := 65001;
  Result[High(Result)].Description := 'UTF-8 (有BOM)';
  
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'UTF-16LE';
  Result[High(Result)].CodePage := 1200;
  Result[High(Result)].Description := 'UTF-16 小端序';
  
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'UTF-16BE';
  Result[High(Result)].CodePage := 1201;
  Result[High(Result)].Description := 'UTF-16 大端序';
  
  // 添加中文编码
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'GBK';
  Result[High(Result)].CodePage := 936;
  Result[High(Result)].Description := '简体中文 (GBK)';
  
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'BIG5';
  Result[High(Result)].CodePage := 950;
  Result[High(Result)].Description := '繁体中文 (BIG5)';
  
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'GB18030';
  Result[High(Result)].CodePage := 54936;
  Result[High(Result)].Description := '中文扩展 (GB18030)';
  
  // 添加日文编码
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'Shift-JIS';
  Result[High(Result)].CodePage := 932;
  Result[High(Result)].Description := '日文 (Shift-JIS)';
  
  // 添加Windows编码系列
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'Windows-1252';
  Result[High(Result)].CodePage := 1252;
  Result[High(Result)].Description := '西欧 (Windows-1252)';
  
  // 添加ISO编码系列
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'ISO-8859-1';
  Result[High(Result)].CodePage := 28591;
  Result[High(Result)].Description := '拉丁文1 (ISO-8859-1)';
  
  // 添加ASCII编码
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := TEncodingTestItem.Create;
  Result[High(Result)].EncodingName := 'ASCII';
  Result[High(Result)].CodePage := 20127;
  Result[High(Result)].Description := 'ASCII (7位)';
end;

// 创建测试目录
procedure CreateTestDirectory;
begin
  if not TDirectory.Exists(TEST_DIR) then
    TDirectory.CreateDirectory(TEST_DIR);
end;

// 创建测试文件
procedure CreateTestFile(const FileName, Content: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    Bytes := TEncoding.UTF8.GetBytes(Content);
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 测试文件从UTF-8转换到目标编码
function TestConversion(const SourceFile, TargetEncodingName: string; AddBOM: Boolean): Boolean;
var
  TargetFile: string;
begin
  TargetFile := ChangeFileExt(SourceFile, '.' + TargetEncodingName.Replace(' ', '_') + '.txt');
  
  try
    Result := JclEncodingUtils.ConvertFileByName(
      SourceFile,
      TargetFile,
      'UTF-8',
      TargetEncodingName,
      AddBOM
    );
    
    // 验证文件是否创建成功
    if Result then
      Result := FileExists(TargetFile);
  except
    Result := False;
  end;
end;

// 检测文件编码
function DetectEncoding(const FileName: string): string;
begin
  if not FileExists(FileName) then
    Exit('文件不存在');
    
  try
    Result := JclEncodingUtils.DetectFileEncoding(FileName);
  except
    Result := '检测出错';
  end;
end;

// 主测试函数
procedure RunEncodingTests;
var
  Encodings: TArray<TEncodingTestItem>;
  TestFile, TestFileContent, ResultsContent: string;
  i: Integer;
  Success: Boolean;
  ResultsWriter: TStreamWriter;
begin
  Encodings := GetEncodingsToTest;
  
  // 创建测试目录
  CreateTestDirectory;
  
  // 创建测试文件
  TestFile := TPath.Combine(TEST_DIR, 'test_source.txt');
  
  // 测试文件包含中文、英文、日文等多种字符
  TestFileContent :=
    'English: The quick brown fox jumps over the lazy dog.' + sLineBreak +
    '中文：敏捷的棕色狐狸跳过懒狗。' + sLineBreak +
    '日本語：素早い茶色のキツネが怠け者の犬を飛び越えます。' + sLineBreak +
    '한국어: 빠른 갈색 여우가 게으른 개를 뛰어 넘습니다.' + sLineBreak +
    'Français: Le rapide renard brun saute par-dessus le chien paresseux.' + sLineBreak +
    'Русский: Быстрая коричневая лиса перепрыгивает через ленивую собаку.' + sLineBreak +
    'Español: El rápido zorro marrón salta sobre el perro perezoso.' + sLineBreak +
    'Deutsch: Der schnelle braune Fuchs springt über den faulen Hund.' + sLineBreak +
    'Special chars: €£¥©®™§±×÷≠≈≤≥µαβγδεζηθικλμνξοπρστυφχψω';
  
  CreateTestFile(TestFile, TestFileContent);
  
  // 初始化结果文件
  ResultsContent := '# 编码转换测试结果' + sLineBreak + sLineBreak;
  ResultsContent := ResultsContent + '测试日期: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak + sLineBreak;
  ResultsContent := ResultsContent + '| 编码 | 代码页 | 描述 | 转换状态 | 检测结果 |' + sLineBreak;
  ResultsContent := ResultsContent + '|------|--------|------|----------|----------|' + sLineBreak;
  
  // 运行测试
  for i := 0 to High(Encodings) do
  begin
    Writeln('测试编码: ', Encodings[i].EncodingName, ' (', Encodings[i].Description, ')');
    
    // 测试从UTF-8转换到目标编码
    Success := TestConversion(TestFile, Encodings[i].EncodingName, 
                             (Encodings[i].EncodingName = 'UTF-8 with BOM') or
                             (Encodings[i].EncodingName = 'UTF-16LE') or 
                             (Encodings[i].EncodingName = 'UTF-16BE'));
    
    // 检测转换后的文件编码
    var TargetFileName := ChangeFileExt(TestFile, '.' + Encodings[i].EncodingName.Replace(' ', '_') + '.txt');
    var DetectedEncoding := DetectEncoding(TargetFileName);
    
    // 添加到结果文件
    ResultsContent := ResultsContent + Format('| %s | %d | %s | %s | %s |' + sLineBreak,
      [Encodings[i].EncodingName, Encodings[i].CodePage, Encodings[i].Description,
       BoolToStr(Success, '成功', '失败'), DetectedEncoding]);
  end;
  
  // 保存结果文件
  ResultsWriter := TStreamWriter.Create(RESULTS_FILE, False, TEncoding.UTF8);
  try
    ResultsWriter.Write(ResultsContent);
  finally
    ResultsWriter.Free;
  end;
  
  Writeln('测试完成，结果保存在: ', RESULTS_FILE);
end;

begin
  try
    Writeln('开始编码转换测试...');
    RunEncodingTests;
    Writeln('按任意键继续...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 