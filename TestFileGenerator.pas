unit TestFileGenerator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TTestFileGenerator = class
  public
    class procedure GenerateTestFiles(const BaseDir: string);
    class procedure GenerateUTF8WithBOMFile(const FilePath: string; const Content: string);
    class procedure GenerateUTF8WithoutBOMFile(const FilePath: string; const Content: string);
    class procedure GenerateANSIFile(const FilePath: string; const Content: string);
    class procedure GenerateUTF16LEFile(const FilePath: string; const Content: string);
    class procedure GenerateUTF16BEFile(const FilePath: string; const Content: string);
    class procedure GenerateGB2312File(const FilePath: string; const Content: string);
  end;

implementation

{ TTestFileGenerator }

class procedure TTestFileGenerator.GenerateTestFiles(const BaseDir: string);
var
  TestFilesDir: string;
begin
  TestFilesDir := TPath.Combine(BaseDir, 'TestFiles');
  
  // 确保目录存在
  if not DirectoryExists(TestFilesDir) then
    ForceDirectories(TestFilesDir);
  
  // 生成各种编码的测试文件
  GenerateUTF8WithBOMFile(TPath.Combine(TestFilesDir, 'utf8_with_bom.txt'), 
    '这是一个UTF-8带BOM的测试文件' + sLineBreak + 
    'This is a UTF-8 with BOM test file' + sLineBreak + 
    '1234567890');
    
  GenerateUTF8WithoutBOMFile(TPath.Combine(TestFilesDir, 'utf8_without_bom.txt'), 
    '这是一个UTF-8不带BOM的测试文件' + sLineBreak + 
    'This is a UTF-8 without BOM test file' + sLineBreak + 
    '1234567890');
    
  GenerateANSIFile(TPath.Combine(TestFilesDir, 'ansi.txt'), 
    'This is an ANSI test file' + sLineBreak + 
    'ANSI only supports ASCII and local code page' + sLineBreak + 
    '1234567890');
    
  GenerateUTF16LEFile(TPath.Combine(TestFilesDir, 'utf16_le.txt'), 
    '这是一个UTF-16 LE的测试文件' + sLineBreak + 
    'This is a UTF-16 LE test file' + sLineBreak + 
    '1234567890');
    
  GenerateUTF16BEFile(TPath.Combine(TestFilesDir, 'utf16_be.txt'), 
    '这是一个UTF-16 BE的测试文件' + sLineBreak + 
    'This is a UTF-16 BE test file' + sLineBreak + 
    '1234567890');
    
  GenerateGB2312File(TPath.Combine(TestFilesDir, 'gb2312.txt'), 
    '这是一个GB2312编码的测试文件' + sLineBreak + 
    'This is a GB2312 encoded test file' + sLineBreak + 
    '1234567890');
end;

class procedure TTestFileGenerator.GenerateUTF8WithBOMFile(const FilePath: string; const Content: string);
begin
  // TEncoding.UTF8默认带BOM
  TFile.WriteAllText(FilePath, Content, TEncoding.UTF8);
end;

class procedure TTestFileGenerator.GenerateUTF8WithoutBOMFile(const FilePath: string; const Content: string);
var
  UTF8NoBOM: TEncoding;
  Bytes: TBytes;
begin
  // 使用UTF-8编码但不添加BOM
  UTF8NoBOM := TEncoding.GetEncoding(65001); // UTF-8 codepage
  try
    Bytes := UTF8NoBOM.GetBytes(Content);
    TFile.WriteAllBytes(FilePath, Bytes);
  finally
    UTF8NoBOM.Free;
  end;
end;

class procedure TTestFileGenerator.GenerateANSIFile(const FilePath: string; const Content: string);
var
  ANSIEncoding: TEncoding;
begin
  // 使用默认ANSI编码
  ANSIEncoding := TEncoding.GetEncoding(0); // Default ANSI codepage
  try
    TFile.WriteAllText(FilePath, Content, ANSIEncoding);
  finally
    ANSIEncoding.Free;
  end;
end;

class procedure TTestFileGenerator.GenerateUTF16LEFile(const FilePath: string; const Content: string);
begin
  // UTF-16 LE (Little Endian)
  TFile.WriteAllText(FilePath, Content, TEncoding.Unicode);
end;

class procedure TTestFileGenerator.GenerateUTF16BEFile(const FilePath: string; const Content: string);
begin
  // UTF-16 BE (Big Endian)
  TFile.WriteAllText(FilePath, Content, TEncoding.BigEndianUnicode);
end;

class procedure TTestFileGenerator.GenerateGB2312File(const FilePath: string; const Content: string);
var
  GB2312Encoding: TEncoding;
begin
  // GB2312编码
  GB2312Encoding := TEncoding.GetEncoding(936); // GB2312 codepage
  try
    TFile.WriteAllText(FilePath, Content, GB2312Encoding);
  finally
    GB2312Encoding.Free;
  end;
end;

end.
