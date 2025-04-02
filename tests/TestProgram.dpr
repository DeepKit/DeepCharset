program TestProgram;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash,
  ControllerEncoding in '..\ControllerEncoding.pas',
  ModelEncoding in '..\ModelEncoding.pas',
  UtilsIconv in '..\UtilsIconv.pas',
  UtilsUTF8 in '..\UtilsUTF8.pas';

const
  // 要测试的编码列表
  TEST_ENCODINGS: array[0..6] of record
    Name: string;        // 编码名称
    Encoding: TEncoding; // 编码对象
  end = (
    (Name: 'UTF-8';      Encoding: TEncoding.UTF8),
    (Name: 'GBK';        Encoding: nil),  // 使用代码页936
    (Name: 'Big5';       Encoding: nil),  // 使用代码页950
    (Name: 'Shift-JIS';  Encoding: nil),  // 使用代码页932
    (Name: 'EUC-KR';     Encoding: nil),  // 使用代码页51949
    (Name: 'ISO-8859-1'; Encoding: nil),  // 使用代码页28591
    (Name: 'KOI8-R';     Encoding: nil)   // 使用代码页20866
  );

var
  EncodingController: TEncodingController;
  
// 日志输出回调函数
procedure LogCallback(const Message: string);
begin
  Writeln(Message);
end;

// 创建测试文件
procedure CreateTestFiles;
var
  FilePath: string;
  TestFile: TFileStream;
  i, j: Integer;
  TestData: TStringList;
  UTF8String, EncodedString: TBytes;
  IconvHelper: TIconvHelper;
begin
  Writeln('创建测试文件...');
  TestData := TStringList.Create;
  IconvHelper := TIconvHelper.Create;
  try
    // 准备测试数据
    TestData.Add('这是一个测试文件，用于测试编码转换功能。');
    TestData.Add('これはエンコーディング変換機能をテストするためのテストファイルです。');
    TestData.Add('이것은 인코딩 변환 기능을 테스트하기 위한 테스트 파일입니다.');
    TestData.Add('Это тестовый файл для проверки функции преобразования кодировок.');
    TestData.Add('هذا ملف اختبار لاختبار وظيفة تحويل الترميز.');
    TestData.Add('Dies ist eine Testdatei zum Testen der Codierungskonvertierungsfunktion.');
    TestData.Add('C''est un fichier de test pour tester la fonction de conversion d''encodage.');
    TestData.Add('This is a test file for testing the encoding conversion function.');
    TestData.Add('1234567890!@#$%^&*()_+{}:"<>?~`-=[];\',./');
    
    // 为每种编码创建测试文件
    for i := 0 to High(TEST_ENCODINGS) do
    begin
      for j := 1 to 3 do
      begin
        FilePath := TPath.Combine('from', Format('%s_sample%d.txt', [TEST_ENCODINGS[i].Name, j]));
        
        // 将文本转换为UTF-8
        UTF8String := TEncoding.UTF8.GetBytes(TestData.Text);
        
        // 根据目标编码进行转换
        if TEST_ENCODINGS[i].Name = 'UTF-8' then
        begin
          EncodedString := UTF8String;
          
          // 为第一个UTF-8样本添加BOM
          if j = 1 then
          begin
            FilePath := TPath.Combine('from', 'UTF-8_BOM_sample1.txt');
            TestFile := TFileStream.Create(FilePath, fmCreate);
            try
              // 写入BOM
              TestFile.WriteBuffer(TEncoding.UTF8.GetPreamble[0], Length(TEncoding.UTF8.GetPreamble));
              // 写入内容
              TestFile.WriteBuffer(EncodedString[0], Length(EncodedString));
            finally
              TestFile.Free;
            end;
            Continue;
          end;
        end
        else
        begin
          // 使用IconvHelper进行编码转换
          if not IconvHelper.ConvertEncoding(
              UTF8String, 'UTF-8', TEST_ENCODINGS[i].Name, EncodedString) then
          begin
            Writeln('无法转换到 ', TEST_ENCODINGS[i].Name);
            continue;
          end;
        end;
        
        // 写入文件
        TestFile := TFileStream.Create(FilePath, fmCreate);
        try
          TestFile.WriteBuffer(EncodedString[0], Length(EncodedString));
        finally
          TestFile.Free;
        end;
        
        Writeln('创建测试文件: ', FilePath);
      end;
    end;
  finally
    TestData.Free;
    IconvHelper.Free;
  end;
end;

// 测试编码转换
procedure TestEncodingConversion;
var
  SourceFiles: TArray<string>;
  SourceFile, TargetFile, BackFile: string;
  i: Integer;
  Encoding: TEncoding;
  Results: TStringList;
  SourceHash, BackHash: string;
  MD5: THashMD5;
begin
  Writeln('测试编码转换...');
  
  // 获取所有源文件
  SourceFiles := TDirectory.GetFiles('from');
  Results := TStringList.Create;
  try
    // 添加表头
    Results.Add('# 编码转换测试结果');
    Results.Add('');
    Results.Add('| 原始文件 | 中间文件(Unicode) | 还原文件 | 结果 | 备注 |');
    Results.Add('| ------- | ----------------- | ------- | ---- | ---- |');
    
    // 为每个编码转换一个文件
    for i := 0 to High(TEST_ENCODINGS) do
    begin
      // 查找符合此编码的第一个文件
      SourceFile := '';
      for var file in SourceFiles do
      begin
        if file.Contains(TEST_ENCODINGS[i].Name) then
        begin
          SourceFile := file;
          break;
        end;
      end;
      
      if SourceFile = '' then
      begin
        Writeln('找不到 ', TEST_ENCODINGS[i].Name, ' 编码的文件');
        continue;
      end;
      
      // 获取目标编码
      if TEST_ENCODINGS[i].Encoding <> nil then
        Encoding := TEST_ENCODINGS[i].Encoding
      else begin
        case TEST_ENCODINGS[i].Name of
          'GBK':        Encoding := TEncoding.GetEncoding(936);
          'Big5':       Encoding := TEncoding.GetEncoding(950);
          'Shift-JIS':  Encoding := TEncoding.GetEncoding(932);
          'EUC-KR':     Encoding := TEncoding.GetEncoding(51949);
          'ISO-8859-1': Encoding := TEncoding.GetEncoding(28591);
          'KOI8-R':     Encoding := TEncoding.GetEncoding(20866);
        else
          Encoding := TEncoding.UTF8;
        end;
      end;
      
      SourceFile := ExtractFileName(SourceFile);
      TargetFile := StringReplace(SourceFile, '.txt', '_to_unicode.txt', [rfReplaceAll]);
      BackFile := StringReplace(SourceFile, '.txt', '_back.txt', [rfReplaceAll]);
      
      // 步骤1: 转换到Unicode
      Writeln('转换 ', SourceFile, ' 到Unicode...');
      if EncodingController.ConvertFileEncoding(
          TPath.Combine('from', SourceFile),
          TPath.Combine('to', TargetFile),
          TEncoding.Unicode, True) = crSuccess then
      begin
        // 步骤2: 转换回原始编码
        Writeln('转换 ', TargetFile, ' 回 ', TEST_ENCODINGS[i].Name, '...');
        if EncodingController.ConvertFileEncoding(
            TPath.Combine('to', TargetFile),
            TPath.Combine('back', BackFile),
            Encoding, False) = crSuccess then
        begin
          // 比较原始文件和转换后的文件
          Writeln('比较 ', SourceFile, ' 和 ', BackFile, '...');
          try
            // 使用MD5哈希比较文件内容
            SourceHash := THashMD5.GetHashStringFromFile(TPath.Combine('from', SourceFile));
            BackHash := THashMD5.GetHashStringFromFile(TPath.Combine('back', BackFile));
            
            if SourceHash = BackHash then
              Results.Add(Format('| %s | %s | %s | ✅ | 文件内容相同 |', 
                [SourceFile, TargetFile, BackFile]))
            else
              Results.Add(Format('| %s | %s | %s | ❌ | 文件内容不同 |', 
                [SourceFile, TargetFile, BackFile]));
          except
            on E: Exception do
              Results.Add(Format('| %s | %s | %s | ❌ | 比较失败: %s |', 
                [SourceFile, TargetFile, BackFile, E.Message]));
          end;
        end else
          Results.Add(Format('| %s | %s | - | ❌ | 转换回原始编码失败 |', 
            [SourceFile, TargetFile]));
      end else
        Results.Add(Format('| %s | - | - | ❌ | 转换到Unicode失败 |', [SourceFile]));
    end;
    
    // 添加汇总
    Results.Add('');
    Results.Add('## 测试汇总');
    Results.Add('');
    Results.Add(Format('- 测试时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Results.Add(Format('- 测试文件数: %d', [Length(SourceFiles)]));
    
    // 记录结果
    Results.SaveToFile('tests.md');
    Writeln('测试结果已保存到tests.md');
  finally
    Results.Free;
  end;
end;

begin
  try
    Writeln('编码转换测试程序启动...');
    
    // 创建编码控制器
    EncodingController := TEncodingController.Create(LogCallback);
    try
      // 创建测试目录
      if not DirectoryExists('from') then
        CreateDir('from');
      if not DirectoryExists('to') then
        CreateDir('to');
      if not DirectoryExists('back') then
        CreateDir('back');
      
      // 创建测试文件
      CreateTestFiles;
      
      // 运行测试
      TestEncodingConversion;
      
      Writeln('测试完成');
      Writeln('按任意键退出...');
      Readln;
    finally
      EncodingController.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end. 