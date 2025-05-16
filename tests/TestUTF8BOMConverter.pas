unit TestUTF8BOMConverter;

interface

procedure RunTestUTF8BOMConverter;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  UTF8BOMConverter_Advanced;

procedure PrintResult(const Result: TConversionResult; const Operation: string);
begin
  WriteLn('-----------------------------------------------------');
  WriteLn('操作: ', Operation);
  WriteLn('成功: ', IfThen(Result.Success, '是', '否'));
  WriteLn('源编码: ', Result.SourceEncoding);
  WriteLn('目标编码: ', Result.TargetEncoding);
  WriteLn('往返验证: ', IfThen(Result.RoundTripSuccess, '通过', '失败'));
  WriteLn('特殊字符验证: ', IfThen(Result.SpecialCharsValid, '通过', '失败'));
  
  if not Result.Success then
    WriteLn('错误信息: ', Result.ErrorMessage);
    
  WriteLn('详细信息:');
  WriteLn(Result.DetailedMessage);
  WriteLn('-----------------------------------------------------');
  WriteLn;
end;

function IfThen(Condition: Boolean; const TrueStr, FalseStr: string): string;
begin
  if Condition then
    Result := TrueStr
  else
    Result := FalseStr;
end;

procedure RunTestUTF8BOMConverter;
var
  TestFolder: string;
  UTF8FileWithBOM, UTF8FileWithoutBOM, ANSIFile: string;
  Result: TConversionResult;
  BatchResults: TArray<TConversionResult>;
  Files: TArray<string>;
  I: Integer;

begin
  try
    // 启用UTF-8控制台输出
    SetConsoleOutputCP(65001);
    
    WriteLn('UTF-8 BOM转换器高级版测试程序');
    WriteLn('======================================');
    WriteLn;
    
    // 创建测试目录
    TestFolder := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestData');
    if not TDirectory.Exists(TestFolder) then
      TDirectory.CreateDirectory(TestFolder);
      
    // 创建测试文件路径
    UTF8FileWithBOM := TPath.Combine(TestFolder, 'UTF8-WithBOM.txt');
    UTF8FileWithoutBOM := TPath.Combine(TestFolder, 'UTF8-WithoutBOM.txt');
    ANSIFile := TPath.Combine(TestFolder, 'ANSI.txt');
    
    // 确保测试文件存在
    if not TFile.Exists(UTF8FileWithBOM) then
    begin
      WriteLn('创建UTF-8带BOM测试文件...');
      var Stream := TFileStream.Create(UTF8FileWithBOM, fmCreate);
      try
        var BOM: TBytes := [$EF, $BB, $BF];
        var Content: TBytes := TEncoding.UTF8.GetBytes('这是一个UTF-8编码的文本文件（带BOM）' + sLineBreak + 
                                                    '包含中文字符：你好，世界！' + sLineBreak + 
                                                    '特殊字符测试：♥★☆♂♀§¶' + sLineBreak + 
                                                    '数字和标点符号：123456789,.!?');
        Stream.WriteBuffer(BOM[0], Length(BOM));
        Stream.WriteBuffer(Content[0], Length(Content));
      finally
        Stream.Free;
      end;
    end;
    
    if not TFile.Exists(UTF8FileWithoutBOM) then
    begin
      WriteLn('创建UTF-8不带BOM测试文件...');
      var Content: TBytes := TEncoding.UTF8.GetBytes('这是一个UTF-8编码的文本文件（无BOM）' + sLineBreak + 
                                                  '包含中文字符：你好，世界！' + sLineBreak + 
                                                  '特殊字符测试：♥★☆♂♀§¶' + sLineBreak + 
                                                  '数字和标点符号：123456789,.!?');
      TFile.WriteAllBytes(UTF8FileWithoutBOM, Content);
    end;
    
    if not TFile.Exists(ANSIFile) then
    begin
      WriteLn('创建ANSI测试文件...');
      var Content: TBytes := TEncoding.Default.GetBytes('这是一个ANSI编码的文本文件' + sLineBreak + 
                                                     '包含中文字符：你好，世界！' + sLineBreak + 
                                                     '特殊字符测试：♥★☆♂♀§¶' + sLineBreak + 
                                                     '数字和标点符号：123456789,.!?');
      TFile.WriteAllBytes(ANSIFile, Content);
    end;
    
    // 测试1: 添加BOM到不带BOM的UTF-8文件
    WriteLn('测试1: 添加BOM到不带BOM的UTF-8文件');
    var TestFile := TPath.Combine(TestFolder, 'Test1.txt');
    TFile.Copy(UTF8FileWithoutBOM, TestFile, True);
    Result := TUTF8BOMConverter_Advanced.AddUTF8BOM(TestFile);
    PrintResult(Result, '添加BOM到不带BOM的UTF-8文件');
    
    // 测试2: 去除BOM
    WriteLn('测试2: 去除BOM');
    TestFile := TPath.Combine(TestFolder, 'Test2.txt');
    TFile.Copy(UTF8FileWithBOM, TestFile, True);
    Result := TUTF8BOMConverter_Advanced.RemoveUTF8BOM(TestFile);
    PrintResult(Result, '去除BOM');
    
    // 测试3: 将ANSI转换为UTF-8+BOM
    WriteLn('测试3: 将ANSI转换为UTF-8+BOM');
    TestFile := TPath.Combine(TestFolder, 'Test3.txt');
    TFile.Copy(ANSIFile, TestFile, True);
    Result := TUTF8BOMConverter_Advanced.ConvertToUTF8WithBOM(TestFile);
    PrintResult(Result, '将ANSI转换为UTF-8+BOM');
    
    // 测试4: 将ANSI转换为UTF-8无BOM
    WriteLn('测试4: 将ANSI转换为UTF-8无BOM');
    TestFile := TPath.Combine(TestFolder, 'Test4.txt');
    TFile.Copy(ANSIFile, TestFile, True);
    Result := TUTF8BOMConverter_Advanced.ConvertToUTF8WithoutBOM(TestFile);
    PrintResult(Result, '将ANSI转换为UTF-8无BOM');
    
    // 测试5: 批处理测试
    WriteLn('测试5: 批处理测试');
    SetLength(Files, 3);
    for I := 0 to 2 do
    begin
      TestFile := TPath.Combine(TestFolder, Format('BatchTest%d.txt', [I+1]));
      case I of
        0: TFile.Copy(UTF8FileWithBOM, TestFile, True);
        1: TFile.Copy(UTF8FileWithoutBOM, TestFile, True);
        2: TFile.Copy(ANSIFile, TestFile, True);
      end;
      Files[I] := TestFile;
    end;
    
    BatchResults := TUTF8BOMConverter_Advanced.BatchProcess(Files, 'utf-8-bom');
    WriteLn('批处理结果:');
    for I := 0 to Length(BatchResults) - 1 do
    begin
      WriteLn(Format('文件 %d: %s - 转换%s', 
        [I+1, Files[I], IfThen(BatchResults[I].Success, '成功', '失败')]));
    end;
    
    WriteLn;
    WriteLn('所有测试完成！');
    WriteLn('测试文件保存在: ', TestFolder);
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('出现异常：', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end;

end. 