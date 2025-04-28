unit UtilsEncodingConverter2;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils,
  System.Generics.Collections;

type
  // 处理不可映射字符的动作
  TUnmappableCharAction = (
    ucaSkip,      // 跳过不可映射的字符
    ucaReplace,   // 替换为指定字符
    ucaThrow      // 抛出异常
  );

  // 行尾处理动作
  TLineEndingAction = (
    leaKeep,      // 保持原有行尾
    leaCRLF,      // 转换为CRLF
    leaLF,        // 转换为LF
    leaCR         // 转换为CR
  );

  // 不可映射字符信息
  TUnmappableCharInfo = record
    Position: Int64;        // 字符在文件中的位置
    SourceChar: WideChar;   // 源字符
    SourceEncoding: string; // 源编码
    TargetEncoding: string; // 目标编码
  end;

  // 转换结果
  TConversionResult = record
    Success: Boolean;                    // 转换是否成功
    BytesProcessed: Int64;              // 处理的字节数
    UnmappableChars: Integer;           // 不可映射字符数
    LineEndingsConverted: Integer;       // 转换的行尾数
    ErrorMessage: string;               // 错误信息
    UnmappableCharList: TList<TUnmappableCharInfo>; // 不可映射字符列表
  end;

  // 日志回调函数类型
  TLogCallback = reference to procedure(const Msg: string);

  // 编码转换器类
  TEncodingConverter2 = class
  private
    FLogCallback: TLogCallback;
    FReplaceChar: Char;
    FUnmappableAction: TUnmappableCharAction;
    FLineEndingAction: TLineEndingAction;
    
    procedure Log(const Msg: string);
    function HandleUnmappableChar(const CharInfo: TUnmappableCharInfo; 
      var Result: TConversionResult): Boolean;
    function NormalizeLineEndings(const Content: string; 
      var Result: TConversionResult): string;
    function GetEncodingByName(const EncodingName: string): TEncoding;
    function GetEncodingName(Encoding: TEncoding): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property LogCallback: TLogCallback read FLogCallback write FLogCallback;
    property ReplaceChar: Char read FReplaceChar write FReplaceChar;
    property UnmappableAction: TUnmappableCharAction 
      read FUnmappableAction write FUnmappableAction;
    property LineEndingAction: TLineEndingAction 
      read FLineEndingAction write FLineEndingAction;
    
    // 主要方法
    function ConvertFileEncoding(const SourceFile, TargetFile: string;
      const SourceEncodingName, TargetEncodingName: string;
      out Result: TConversionResult): Boolean;
  end;

implementation

uses
  System.Character;

{ TEncodingConverter2 }

constructor TEncodingConverter2.Create;
begin
  inherited;
  FReplaceChar := '?';
  FUnmappableAction := ucaReplace;
  FLineEndingAction := leaKeep;
end;

destructor TEncodingConverter2.Destroy;
begin
  inherited;
end;

procedure TEncodingConverter2.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingConverter2.GetEncodingByName(const EncodingName: string): TEncoding;
begin
  // 标准编码名称映射
  if SameText(EncodingName, 'UTF-8') then
    Result := TEncoding.UTF8
  else if SameText(EncodingName, 'UTF-16LE') then
    Result := TEncoding.Unicode
  else if SameText(EncodingName, 'UTF-16BE') then
    Result := TEncoding.BigEndianUnicode
  else if SameText(EncodingName, 'ASCII') then
    Result := TEncoding.ASCII
  else if SameText(EncodingName, 'windows-1252') then
    Result := TEncoding.ANSI
  else
    // 对于其他编码，使用TEncoding.GetEncoding
    Result := TEncoding.GetEncoding(EncodingName);
end;

function TEncodingConverter2.GetEncodingName(Encoding: TEncoding): string;
begin
  if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.ANSI then
    Result := 'windows-1252'
  else
    Result := Format('CP%d', [Encoding.CodePage]);
end;

function TEncodingConverter2.HandleUnmappableChar(
  const CharInfo: TUnmappableCharInfo;
  var Result: TConversionResult): Boolean;
begin
  Inc(Result.UnmappableChars);
  Result.UnmappableCharList.Add(CharInfo);
  
  case FUnmappableAction of
    ucaSkip: 
      begin
        Log(Format('跳过不可映射字符 [%s] 位置:%d', 
          [CharInfo.SourceChar, CharInfo.Position]));
        Result := True;
      end;
    ucaReplace:
      begin
        Log(Format('替换不可映射字符 [%s] -> [%s] 位置:%d',
          [CharInfo.SourceChar, FReplaceChar, CharInfo.Position]));
        Result := True;
      end;
    ucaThrow:
      begin
        Result.ErrorMessage := Format('发现不可映射字符 [%s] 位置:%d',
          [CharInfo.SourceChar, CharInfo.Position]);
        Result := False;
      end;
  end;
end;

function TEncodingConverter2.NormalizeLineEndings(
  const Content: string;
  var Result: TConversionResult): string;
var
  NewLineEnding: string;
begin
  case FLineEndingAction of
    leaKeep: Exit(Content);
    leaCRLF: NewLineEnding := #13#10;
    leaLF:   NewLineEnding := #10;
    leaCR:   NewLineEnding := #13;
  end;
  
  Result := StringReplace(Content, #13#10, NewLineEnding, [rfReplaceAll]);
  Result := StringReplace(Result, #13, NewLineEnding, [rfReplaceAll]);
  Result := StringReplace(Result, #10, NewLineEnding, [rfReplaceAll]);
  
  Inc(Result.LineEndingsConverted);
end;

function TEncodingConverter2.ConvertFileEncoding(
  const SourceFile, TargetFile: string;
  const SourceEncodingName, TargetEncodingName: string;
  out Result: TConversionResult): Boolean;
var
  SourceEncoding, TargetEncoding: TEncoding;
  FileContent: TBytes;
  ContentStr: string;
  OutputBytes: TBytes;
  CharInfo: TUnmappableCharInfo;
  I: Integer;
begin
  // 初始化结果
  Result.Success := False;
  Result.BytesProcessed := 0;
  Result.UnmappableChars := 0;
  Result.LineEndingsConverted := 0;
  Result.ErrorMessage := '';
  Result.UnmappableCharList := TList<TUnmappableCharInfo>.Create;
  
  try
    try
      // 获取编码对象
      SourceEncoding := GetEncodingByName(SourceEncodingName);
      TargetEncoding := GetEncodingByName(TargetEncodingName);
      
      // 读取源文件
      FileContent := TFile.ReadAllBytes(SourceFile);
      Result.BytesProcessed := Length(FileContent);
      
      // 转换为字符串
      ContentStr := SourceEncoding.GetString(FileContent);
      
      // 处理行尾
      if FLineEndingAction <> leaKeep then
        ContentStr := NormalizeLineEndings(ContentStr, Result);
      
      // 转换为目标编码
      OutputBytes := TargetEncoding.GetBytes(ContentStr);
      
      // 写入目标文件
      TFile.WriteAllBytes(TargetFile, OutputBytes);
      
      Result.Success := True;
      Log(Format('文件转换成功: %s -> %s', [SourceFile, TargetFile]));
      
    except
      on E: Exception do
      begin
        Result.Success := False;
        Result.ErrorMessage := E.Message;
        Log(Format('文件转换失败: %s', [E.Message]));
      end;
    end;
    
  finally
    if Assigned(Result.UnmappableCharList) then
      FreeAndNil(Result.UnmappableCharList);
  end;
end;

end. 