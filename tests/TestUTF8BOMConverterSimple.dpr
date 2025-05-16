program TestUTF8BOMConverterSimple;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes,
  UTF8BOMConverter_Simple_Fixed in 'UTF8BOMConverter_Simple_Fixed.pas';

// 辅助函数
function BoolToYesNo(B: Boolean): string;
begin
  if B then
    Result := '有'
  else
    Result := '没有';
end;

function TestResultStr(B: Boolean): string;
begin
  if B then
    Result := '成功'
  else
    Result := '失败';
end;

// 手动复制文件函数
procedure CopyFile(const SourceFile, TargetFile: string);
var
  SourceStream, TargetStream: TFileStream;
begin
  SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
  try
    TargetStream := TFileStream.Create(TargetFile, fmCreate);
    try
      TargetStream.CopyFrom(SourceStream, 0);
    finally
      TargetStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

procedure TestAddBOMToUTF8File;
var
  FileName: string;
  Result: Boolean;
begin
  Writeln('=== 测试添加BOM到UTF-8文件 ===');
  
  // 使用无BOM的UTF-8文件
  FileName := 'TestData\EncodingSamples\UTF8-WithoutBOM.txt';
  
  if not FileExists(FileName) then
  begin
    Writeln('测试文件不存在: ' + FileName);
    Exit;
  end;
  
  // 创建临时副本用于测试
  var TempFileName := 'TestData\EncodingSamples\UTF8-WithoutBOM-Test.txt';
  CopyFile(FileName, TempFileName);
  
  try
    // 添加BOM
    Result := TUTF8BOMConverter.AddUTF8BOM(TempFileName);
    
    // 验证结果
    Writeln('添加BOM结果: ' + BoolToStr(Result, True));
    Writeln('文件现在' + BoolToYesNo(TUTF8BOMConverter.HasUTF8BOM(TempFileName)) + 'BOM');
    Writeln('测试' + TestResultStr(Result and TUTF8BOMConverter.HasUTF8BOM(TempFileName)));
  finally
    // 清理测试文件
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
  
  Writeln;
end;

procedure TestRemoveBOMFromUTF8File;
var
  FileName: string;
  Result: Boolean;
begin
  Writeln('=== 测试从UTF-8文件移除BOM ===');
  
  // 使用带BOM的UTF-8文件
  FileName := 'TestData\EncodingSamples\UTF8-WithBOM.txt';
  
  if not FileExists(FileName) then
  begin
    Writeln('测试文件不存在: ' + FileName);
    Exit;
  end;
  
  // 创建临时副本用于测试
  var TempFileName := 'TestData\EncodingSamples\UTF8-WithBOM-Test.txt';
  CopyFile(FileName, TempFileName);
  
  try
    // 移除BOM
    Result := TUTF8BOMConverter.RemoveUTF8BOM(TempFileName);
    
    // 验证结果
    Writeln('移除BOM结果: ' + BoolToStr(Result, True));
    Writeln('文件现在' + BoolToYesNo(TUTF8BOMConverter.HasUTF8BOM(TempFileName)) + 'BOM');
    Writeln('测试' + TestResultStr(Result and not TUTF8BOMConverter.HasUTF8BOM(TempFileName)));
  finally
    // 清理测试文件
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
  
  Writeln;
end;

procedure TestConvertToUTF8WithBOM;
var
  FileName: string;
  Result: Boolean;
begin
  Writeln('=== 测试转换文件到UTF-8+BOM ===');
  
  // 使用GBK编码文件
  FileName := 'TestData\EncodingSamples\GBK.txt';
  
  if not FileExists(FileName) then
  begin
    Writeln('测试文件不存在: ' + FileName);
    Exit;
  end;
  
  // 创建临时副本用于测试
  var TempFileName := 'TestData\EncodingSamples\GBK-Test.txt';
  CopyFile(FileName, TempFileName);
  
  try
    // 转换到UTF-8+BOM
    Result := TUTF8BOMConverter.ConvertToUTF8WithBOM(TempFileName);
    
    // 验证结果
    Writeln('转换结果: ' + BoolToStr(Result, True));
    Writeln('文件现在' + BoolToYesNo(TUTF8BOMConverter.HasUTF8BOM(TempFileName)) + 'BOM');
    Writeln('测试' + TestResultStr(Result and TUTF8BOMConverter.HasUTF8BOM(TempFileName)));
  finally
    // 清理测试文件
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
  
  Writeln;
end;

procedure TestConvertToUTF8WithoutBOM;
var
  FileName: string;
  Result: Boolean;
begin
  Writeln('=== 测试转换文件到UTF-8无BOM ===');
  
  // 使用GBK编码文件
  FileName := 'TestData\EncodingSamples\GBK.txt';
  
  if not FileExists(FileName) then
  begin
    Writeln('测试文件不存在: ' + FileName);
    Exit;
  end;
  
  // 创建临时副本用于测试
  var TempFileName := 'TestData\EncodingSamples\GBK-Test.txt';
  CopyFile(FileName, TempFileName);
  
  try
    // 转换到UTF-8无BOM
    Result := TUTF8BOMConverter.ConvertToUTF8WithoutBOM(TempFileName);
    
    // 验证结果
    Writeln('转换结果: ' + BoolToStr(Result, True));
    Writeln('文件现在' + BoolToYesNo(TUTF8BOMConverter.HasUTF8BOM(TempFileName)) + 'BOM');
    Writeln('测试' + TestResultStr(Result and not TUTF8BOMConverter.HasUTF8BOM(TempFileName)));
  finally
    // 清理测试文件
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
  
  Writeln;
end;

begin
  try
    Writeln('开始执行UTF8BOMConverter简化版测试...');
    Writeln;
    
    TestAddBOMToUTF8File;
    TestRemoveBOMFromUTF8File;
    TestConvertToUTF8WithBOM;
    TestConvertToUTF8WithoutBOM;
    
    Writeln;
    Writeln('测试完成，按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('出现错误: ' + E.Message);
      Readln;
    end;
  end;
end. 