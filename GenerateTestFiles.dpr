program GenerateTestFiles;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils;

// 创建GBK编码的测试文件
procedure CreateGBKTestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建GBK编码测试文件: ', FileName);
  
  // GBK编码的中文文本
  Bytes := TEncoding.GetEncoding(936).GetBytes(
    '这是GBK编码测试文件' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    '中文内容: 中国，北京' + #13#10 +
    '特殊符号: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 创建Shift-JIS编码的测试文件
procedure CreateShiftJISTestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建Shift-JIS编码测试文件: ', FileName);
  
  // Shift-JIS编码的日文文本
  Bytes := TEncoding.GetEncoding(932).GetBytes(
    'これはShift-JIS符号化テストファイルです' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    '日本語: こんにちは世界' + #13#10 +
    '特殊記号: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 创建EUC-KR编码的测试文件
procedure CreateEUCKRTestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建EUC-KR编码测试文件: ', FileName);
  
  // EUC-KR编码的韩文文本
  Bytes := TEncoding.GetEncoding(949).GetBytes(
    '이것은 EUC-KR 인코딩 테스트 파일입니다' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    '한국어: 안녕하세요 세계' + #13#10 +
    '특수 기호: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 创建Windows-1251编码的测试文件
procedure CreateWindows1251TestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建Windows-1251编码测试文件: ', FileName);
  
  // Windows-1251编码的俄文文本
  Bytes := TEncoding.GetEncoding(1251).GetBytes(
    'Это тестовый файл в кодировке Windows-1251' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    'Русский: Привет, мир' + #13#10 +
    'Специальные символы: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 创建Windows-1256编码的测试文件
procedure CreateWindows1256TestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建Windows-1256编码测试文件: ', FileName);
  
  // Windows-1256编码的阿拉伯文文本
  Bytes := TEncoding.GetEncoding(1256).GetBytes(
    'هذا ملف اختبار بترميز Windows-1256' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    'العربية: مرحبا بالعالم' + #13#10 +
    'رموز خاصة: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

// 创建Windows-1255编码的测试文件
procedure CreateWindows1255TestFile(const FileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  WriteLn('创建Windows-1255编码测试文件: ', FileName);
  
  // Windows-1255编码的希伯来文文本
  Bytes := TEncoding.GetEncoding(1255).GetBytes(
    'זהו קובץ בדיקה בקידוד Windows-1255' + #13#10 +
    'ASCII characters: Hello World!' + #13#10 +
    'עברית: שלום עולם' + #13#10 +
    'סמלים מיוחדים: ©®™℃№§¥£€$¢'
  );
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
end;

var
  TestDir: string;
begin
  try
    // 设置控制台编码为UTF-8，以便正确显示中文
    SetConsoleOutputCP(65001);
    
    WriteLn('编码测试文件生成程序');
    WriteLn('=================');
    WriteLn;
    
    // 创建测试目录
    TestDir := 'tests\from';
    if not DirectoryExists(TestDir) then
      ForceDirectories(TestDir);
    
    // 创建各种编码的测试文件
    CreateGBKTestFile(TestDir + '\GBK编码测试.txt');
    CreateShiftJISTestFile(TestDir + '\ShiftJIS编码测试.txt');
    CreateEUCKRTestFile(TestDir + '\EUCKR编码测试.txt');
    CreateWindows1251TestFile(TestDir + '\Windows1251编码测试.txt');
    CreateWindows1256TestFile(TestDir + '\Windows1256编码测试.txt');
    CreateWindows1255TestFile(TestDir + '\Windows1255编码测试.txt');
    
    WriteLn;
    WriteLn('所有测试文件已生成完毕!');
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('发生错误: ', E.Message);
      ReadLn;
    end;
  end;
end.
