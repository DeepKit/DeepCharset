unit TestStandardSamplesGenerator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, TestStandardSamples;

type
  /// <summary>
  /// 标准测试样本生成器
  /// </summary>
  TStandardSamplesGenerator = class
  private
    FSamplesManager: TStandardSamplesManager;
    FOutputDir: string;
    
    // 生成特定内容的文件
    function GenerateTextFile(const AFileName, AContent: string; const AEncoding: string; 
      AHasBOM: Boolean): string;
    
    // 将文本转换为特定编码
    function ConvertTextToEncoding(const AText: string; const AEncoding: string; 
      AWithBOM: Boolean): TBytes;
  public
    constructor Create(ASamplesManager: TStandardSamplesManager; 
      const AOutputDir: string = '');
    destructor Destroy; override;
    
    // 生成各种编码的中文纯文本样本
    procedure GenerateChineseTextSamples;
    
    // 生成各种编码的英文纯文本样本
    procedure GenerateEnglishTextSamples;
    
    // 生成混合中英文内容样本
    procedure GenerateMixedContentSamples;
    
    // 生成特殊字符样本
    procedure GenerateSpecialCharsSamples;
    
    // 生成边界情况样本
    procedure GenerateBoundaryCaseSamples;
    
    // 生成空文件样本
    procedure GenerateEmptyFileSamples;
    
    // 生成大文件样本
    procedure GenerateLargeFileSamples;
    
    // 生成所有样本
    procedure GenerateAllSamples;
    
    property OutputDir: string read FOutputDir write FOutputDir;
    property SamplesManager: TStandardSamplesManager read FSamplesManager;
  end;

implementation

uses
  System.NetEncoding, Winapi.Windows;

const
  // 中文样本文本
  CHINESE_SAMPLE_TEXT = 
    '中文编码测试样本' + sLineBreak +
    '这是一个用于测试编码检测和转换的中文文本样本。' + sLineBreak +
    '目的是测试程序能否正确处理中文字符和标点符号。' + sLineBreak +
    '支持的编码包括：UTF-8、GBK、GB18030、Big5等。' + sLineBreak +
    '特殊符号：【】「」『』《》''""￥·—…' + sLineBreak +
    '数字：１２３４５６７８９０' + sLineBreak +
    '字母：ＡＢＣＤＥＦＧａｂｃｄｅｆｇ' + sLineBreak +
    '简繁对照：简体字/繁體字 台湾/臺灣 国家/國家 产品/產品';
    
  // 英文样本文本
  ENGLISH_SAMPLE_TEXT = 
    'Encoding Test Sample - English' + sLineBreak +
    'This is a sample text for testing encoding detection and conversion.' + sLineBreak +
    'The purpose is to test if the program can correctly handle English characters and punctuation.' + sLineBreak +
    'Supported encodings include: UTF-8, ASCII, ISO-8859-1, etc.' + sLineBreak +
    'Special symbols: [@#$%^&*()_+{}|:"<>?~`]' + sLineBreak +
    'Numbers: 1234567890' + sLineBreak +
    'Letters: ABCDEFGabcdefg';
    
  // 特殊字符样本文本
  SPECIAL_CHARS_TEXT = 
    'Special Characters Encoding Test Sample' + sLineBreak +
    'ASCII Extended: ' + #128 + #129 + #130 + #131 + #132 + #133 + #134 + #135 + #136 + #137 + #138 + #139 + #140 + sLineBreak +
    'Currency Symbols: ¤ $ ¢ £ ¥ € ₹ ₽ ₩' + sLineBreak +
    'Mathematical Symbols: ∀ ∁ ∂ ∃ ∄ ∅ ∆ ∇ ∈ ∉ ∊ ∋ ∌ ∍ ∎ ∏ ∐ ∑ √ ∛ ∜ ∝ ∞' + sLineBreak +
    'Greek Letters: α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ ς σ τ υ φ χ ψ ω' + sLineBreak +
    'Arrows: ← ↑ → ↓ ↔ ↕ ↖ ↗ ↘ ↙' + sLineBreak +
    'Control Characters: ';
    
  // 混合内容样本文本
  MIXED_CONTENT_TEXT = 
    'Mixed Content Encoding Test Sample / 混合内容编码测试样本' + sLineBreak +
    'This is a sample text that contains both English and Chinese characters.' + sLineBreak +
    '这是一个包含中英文字符的样本文本。' + sLineBreak +
    'Numbers/数字: 1234567890１２３４５６７８９０' + sLineBreak +
    'Symbols/符号: !@#$%^&*()_+-=[]{}|;:",./<>?～！￥…（）【】「」《》，。；：''""';
    
  // 边界情况样本文本
  BOUNDARY_CASE_TEXT = 
    'Boundary Case Encoding Test Sample' + sLineBreak +
    'This file contains characters at the boundary of encoding ranges.' + sLineBreak +
    // BMP边界字符
    'BMP Boundary: ' + #$D7FF + #$E000 + sLineBreak +
    // 代理对范围
    'Surrogate Pair Range: ' + #$D800 + #$DC00 + sLineBreak +
    // UTF-8过长编码示例 (应该是无效的)
    'Overlong UTF-8 Example: ' + #$C0 + #$AF + sLineBreak +
    // CESU-8编码示例 
    'CESU-8 Example: ' + #$ED + #$A0 + #$80 + #$ED + #$B0 + #$80 + sLineBreak +
    // 各种边界情况的混合
    'Mixed Boundary Cases: ' + #$80 + #$FF + #$FE + #$FF + #$7F;

{ TStandardSamplesGenerator }

constructor TStandardSamplesGenerator.Create(ASamplesManager: TStandardSamplesManager;
  const AOutputDir: string);
begin
  FSamplesManager := ASamplesManager;
  
  if AOutputDir = '' then
    FOutputDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SampleFiles')
  else
    FOutputDir := AOutputDir;
    
  ForceDirectories(FOutputDir);
end;

destructor TStandardSamplesGenerator.Destroy;
begin
  inherited;
end;

function TStandardSamplesGenerator.ConvertTextToEncoding(const AText: string;
  const AEncoding: string; AWithBOM: Boolean): TBytes;
var
  EncodingObj: TEncoding;
  BOM: TBytes;
  TextBytes: TBytes;
begin
  Result := nil;
  
  // 选择合适的编码对象
  if SameText(AEncoding, 'UTF-8') then
    EncodingObj := TEncoding.UTF8
  else if SameText(AEncoding, 'UTF-16LE') or SameText(AEncoding, 'Unicode') then
    EncodingObj := TEncoding.Unicode
  else if SameText(AEncoding, 'UTF-16BE') then
    EncodingObj := TEncoding.BigEndianUnicode
  else if SameText(AEncoding, 'ASCII') then
    EncodingObj := TEncoding.ASCII
  else if SameText(AEncoding, 'GB2312') or SameText(AEncoding, 'GBK') or
          SameText(AEncoding, 'GB18030') then
  begin
    // 使用代码页936（简体中文）
    EncodingObj := TEncoding.GetEncoding(936);
  end
  else if SameText(AEncoding, 'Big5') then
  begin
    // 使用代码页950（繁体中文）
    EncodingObj := TEncoding.GetEncoding(950);
  end
  else
    EncodingObj := TEncoding.UTF8; // 默认使用UTF-8
  
  try
    // 获取文本的字节表示
    TextBytes := EncodingObj.GetBytes(AText);
    
    // 如果需要添加BOM
    if AWithBOM then
    begin
      BOM := EncodingObj.GetPreamble;
      SetLength(Result, Length(BOM) + Length(TextBytes));
      if Length(BOM) > 0 then
        Move(BOM[0], Result[0], Length(BOM));
      Move(TextBytes[0], Result[Length(BOM)], Length(TextBytes));
    end
    else
    begin
      SetLength(Result, Length(TextBytes));
      Move(TextBytes[0], Result[0], Length(TextBytes));
    end;
  finally
    if (EncodingObj <> TEncoding.UTF8) and
       (EncodingObj <> TEncoding.Unicode) and
       (EncodingObj <> TEncoding.BigEndianUnicode) and
       (EncodingObj <> TEncoding.ASCII) then
      EncodingObj.Free;
  end;
end;

function TStandardSamplesGenerator.GenerateTextFile(const AFileName, AContent: string;
  const AEncoding: string; AHasBOM: Boolean): string;
var
  FileContent: TBytes;
  FilePath: string;
  FileStream: TFileStream;
  Sample: TStandardSample;
  Category: TSampleCategory;
  Language: TSampleLanguage;
  Description: string;
begin
  // 确定文件路径
  FilePath := TPath.Combine(FOutputDir, AFileName);
  
  // 转换文本到指定编码
  FileContent := ConvertTextToEncoding(AContent, AEncoding, AHasBOM);
  
  // 创建必要的目录
  ForceDirectories(ExtractFilePath(FilePath));
  
  // 写入文件
  FileStream := TFileStream.Create(FilePath, fmCreate);
  try
    if Length(FileContent) > 0 then
      FileStream.WriteBuffer(FileContent[0], Length(FileContent));
  finally
    FileStream.Free;
  end;
  
  // 根据文件名确定类别和语言
  Category := scPureText;
  Language := slOther;
  Description := '';
  
  if AFileName.Contains('Chinese') then
    Language := slChinese
  else if AFileName.Contains('English') then
    Language := slEnglish
  else if AFileName.Contains('Mixed') then
  begin
    Language := slMixed;
    Category := scMixedContent;
  end;
  
  if AFileName.Contains('Special') then
  begin
    Category := scSpecialChars;
    Description := '特殊字符测试样本，包含各种特殊符号';
  end
  else if AFileName.Contains('Boundary') then
  begin
    Category := scBoundary;
    Description := '边界情况测试样本，包含编码边界字符';
  end
  else if Language = slChinese then
    Description := '中文编码测试样本'
  else if Language = slEnglish then
    Description := '英文编码测试样本'
  else if Category = scMixedContent then
    Description := '混合中英文内容测试样本';
    
  // 创建样本对象并添加到管理器
  Sample := TStandardSample.CreateFromFile(FilePath, Category, Language, 
    AEncoding, AHasBOM, Description);
  FSamplesManager.AddSample(Sample);
  
  Result := FilePath;
end;

procedure TStandardSamplesGenerator.GenerateChineseTextSamples;
begin
  // 生成UTF-8编码的中文样本
  GenerateTextFile('Chinese_UTF8.txt', CHINESE_SAMPLE_TEXT, 'UTF-8', False);
  GenerateTextFile('Chinese_UTF8_BOM.txt', CHINESE_SAMPLE_TEXT, 'UTF-8', True);
  
  // 生成UTF-16LE/BE编码的中文样本
  GenerateTextFile('Chinese_UTF16LE.txt', CHINESE_SAMPLE_TEXT, 'UTF-16LE', False);
  GenerateTextFile('Chinese_UTF16LE_BOM.txt', CHINESE_SAMPLE_TEXT, 'UTF-16LE', True);
  GenerateTextFile('Chinese_UTF16BE.txt', CHINESE_SAMPLE_TEXT, 'UTF-16BE', False);
  GenerateTextFile('Chinese_UTF16BE_BOM.txt', CHINESE_SAMPLE_TEXT, 'UTF-16BE', True);
  
  // 生成GBK/GB18030编码的中文样本
  GenerateTextFile('Chinese_GBK.txt', CHINESE_SAMPLE_TEXT, 'GBK', False);
  GenerateTextFile('Chinese_GB18030.txt', CHINESE_SAMPLE_TEXT, 'GB18030', False);
  
  // 生成Big5编码的中文样本
  GenerateTextFile('Chinese_Big5.txt', CHINESE_SAMPLE_TEXT, 'Big5', False);
end;

procedure TStandardSamplesGenerator.GenerateEnglishTextSamples;
begin
  // 生成ASCII编码的英文样本
  GenerateTextFile('English_ASCII.txt', ENGLISH_SAMPLE_TEXT, 'ASCII', False);
  
  // 生成UTF-8编码的英文样本
  GenerateTextFile('English_UTF8.txt', ENGLISH_SAMPLE_TEXT, 'UTF-8', False);
  GenerateTextFile('English_UTF8_BOM.txt', ENGLISH_SAMPLE_TEXT, 'UTF-8', True);
  
  // 生成UTF-16LE/BE编码的英文样本
  GenerateTextFile('English_UTF16LE.txt', ENGLISH_SAMPLE_TEXT, 'UTF-16LE', False);
  GenerateTextFile('English_UTF16LE_BOM.txt', ENGLISH_SAMPLE_TEXT, 'UTF-16LE', True);
  GenerateTextFile('English_UTF16BE.txt', ENGLISH_SAMPLE_TEXT, 'UTF-16BE', False);
  GenerateTextFile('English_UTF16BE_BOM.txt', ENGLISH_SAMPLE_TEXT, 'UTF-16BE', True);
end;

procedure TStandardSamplesGenerator.GenerateMixedContentSamples;
begin
  // 生成UTF-8编码的混合内容样本
  GenerateTextFile('Mixed_UTF8.txt', MIXED_CONTENT_TEXT, 'UTF-8', False);
  GenerateTextFile('Mixed_UTF8_BOM.txt', MIXED_CONTENT_TEXT, 'UTF-8', True);
  
  // 生成UTF-16LE/BE编码的混合内容样本
  GenerateTextFile('Mixed_UTF16LE.txt', MIXED_CONTENT_TEXT, 'UTF-16LE', False);
  GenerateTextFile('Mixed_UTF16LE_BOM.txt', MIXED_CONTENT_TEXT, 'UTF-16LE', True);
  GenerateTextFile('Mixed_UTF16BE.txt', MIXED_CONTENT_TEXT, 'UTF-16BE', False);
  GenerateTextFile('Mixed_UTF16BE_BOM.txt', MIXED_CONTENT_TEXT, 'UTF-16BE', True);
  
  // 生成GBK/GB18030编码的混合内容样本
  GenerateTextFile('Mixed_GBK.txt', MIXED_CONTENT_TEXT, 'GBK', False);
  GenerateTextFile('Mixed_GB18030.txt', MIXED_CONTENT_TEXT, 'GB18030', False);
  
  // 生成Big5编码的混合内容样本
  GenerateTextFile('Mixed_Big5.txt', MIXED_CONTENT_TEXT, 'Big5', False);
end;

procedure TStandardSamplesGenerator.GenerateSpecialCharsSamples;
begin
  // 生成UTF-8编码的特殊字符样本
  GenerateTextFile('Special_UTF8.txt', SPECIAL_CHARS_TEXT, 'UTF-8', False);
  GenerateTextFile('Special_UTF8_BOM.txt', SPECIAL_CHARS_TEXT, 'UTF-8', True);
  
  // 生成UTF-16LE/BE编码的特殊字符样本
  GenerateTextFile('Special_UTF16LE.txt', SPECIAL_CHARS_TEXT, 'UTF-16LE', False);
  GenerateTextFile('Special_UTF16LE_BOM.txt', SPECIAL_CHARS_TEXT, 'UTF-16LE', True);
  GenerateTextFile('Special_UTF16BE.txt', SPECIAL_CHARS_TEXT, 'UTF-16BE', False);
  GenerateTextFile('Special_UTF16BE_BOM.txt', SPECIAL_CHARS_TEXT, 'UTF-16BE', True);
  
  // 生成控制字符的特殊样本
  var ControlCharsText := 'Control Characters:';
  for var I := 0 to 31 do
    ControlCharsText := ControlCharsText + ' ' + Chr(I);
  ControlCharsText := ControlCharsText + sLineBreak + 'DEL: ' + Chr(127);
  
  GenerateTextFile('Special_Control_Chars_UTF8.txt', ControlCharsText, 'UTF-8', False);
end;

procedure TStandardSamplesGenerator.GenerateBoundaryCaseSamples;
begin
  // 生成UTF-8编码的边界情况样本
  GenerateTextFile('Boundary_UTF8.txt', BOUNDARY_CASE_TEXT, 'UTF-8', False);
  GenerateTextFile('Boundary_UTF8_BOM.txt', BOUNDARY_CASE_TEXT, 'UTF-8', True);
  
  // 生成UTF-16LE/BE编码的边界情况样本
  GenerateTextFile('Boundary_UTF16LE.txt', BOUNDARY_CASE_TEXT, 'UTF-16LE', False);
  GenerateTextFile('Boundary_UTF16LE_BOM.txt', BOUNDARY_CASE_TEXT, 'UTF-16LE', True);
  GenerateTextFile('Boundary_UTF16BE.txt', BOUNDARY_CASE_TEXT, 'UTF-16BE', False);
  GenerateTextFile('Boundary_UTF16BE_BOM.txt', BOUNDARY_CASE_TEXT, 'UTF-16BE', True);
  
  // 创建仅包含BOM的文件
  GenerateTextFile('BOM_Only_UTF8.txt', '', 'UTF-8', True);
  GenerateTextFile('BOM_Only_UTF16LE.txt', '', 'UTF-16LE', True);
  GenerateTextFile('BOM_Only_UTF16BE.txt', '', 'UTF-16BE', True);
  
  // 创建部分BOM的文件（非标准/错误的BOM）
  var FileStream: TFileStream;
  var FilePath: string;
  var Sample: TStandardSample;
  
  // 部分UTF-8 BOM (0xEF 0xBB，缺少第三个字节)
  FilePath := TPath.Combine(FOutputDir, 'Partial_BOM_UTF8.txt');
  FileStream := TFileStream.Create(FilePath, fmCreate);
  try
    var PartialBOM: array[0..1] of Byte = ($EF, $BB);
    FileStream.WriteBuffer(PartialBOM, 2);
  finally
    FileStream.Free;
  end;
  
  // 添加到样本集
  Sample := TStandardSample.CreateFromFile(FilePath, scBoundary, slOther, 
    'UTF-8', False, '部分UTF-8 BOM (0xEF 0xBB，缺少第三个字节)');
  FSamplesManager.AddSample(Sample);
  
  // 部分UTF-16LE BOM (只有0xFF，缺少第二个字节)
  FilePath := TPath.Combine(FOutputDir, 'Partial_BOM_UTF16LE.txt');
  FileStream := TFileStream.Create(FilePath, fmCreate);
  try
    var PartialBOM: Byte = $FF;
    FileStream.WriteBuffer(PartialBOM, 1);
  finally
    FileStream.Free;
  end;
  
  // 添加到样本集
  Sample := TStandardSample.CreateFromFile(FilePath, scBoundary, slOther, 
    'UTF-16LE', False, '部分UTF-16LE BOM (只有0xFF，缺少第二个字节)');
  FSamplesManager.AddSample(Sample);
end;

procedure TStandardSamplesGenerator.GenerateEmptyFileSamples;
begin
  // 创建空文件
  GenerateTextFile('Empty.txt', '', 'UTF-8', False);
  
  // 创建只包含空格和换行符的文件
  GenerateTextFile('Whitespace_Only.txt', '   ' + sLineBreak + '  ' + sLineBreak, 'UTF-8', False);
  
  // 创建只包含Unicode空格字符的文件
  GenerateTextFile('Unicode_Whitespace.txt', #$2000 + #$2001 + #$2002 + #$2003, 'UTF-8', False);
end;

procedure TStandardSamplesGenerator.GenerateLargeFileSamples;
var
  Content: string;
  I: Integer;
begin
  // 生成重复内容的大文件
  Content := '';
  for I := 1 to 1000 do
    Content := Content + MIXED_CONTENT_TEXT + sLineBreak;
  
  GenerateTextFile('Large_UTF8.txt', Content, 'UTF-8', False);
  GenerateTextFile('Large_UTF8_BOM.txt', Content, 'UTF-8', True);
  GenerateTextFile('Large_GBK.txt', Content, 'GBK', False);
end;

procedure TStandardSamplesGenerator.GenerateAllSamples;
begin
  GenerateChineseTextSamples;
  GenerateEnglishTextSamples;
  GenerateMixedContentSamples;
  GenerateSpecialCharsSamples;
  GenerateBoundaryCaseSamples;
  GenerateEmptyFileSamples;
  GenerateLargeFileSamples;
  
  // 创建样本索引
  FSamplesManager.CreateSampleIndex(TPath.Combine(FOutputDir, 'SampleIndex.json'));
end;

end. 