unit UtilsBinaryDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Math;

type
  /// <summary>
  /// 二进制文件检测器
  /// </summary>
  TBinaryDetector = class
  private
    class var FBinaryExtensions: THashSet<string>;
    class var FTextExtensions: THashSet<string>;
    class var FBinarySignatures: TDictionary<string, TArray<Byte>>;
    class var FMaxSignatureLength: Integer;

    class procedure Initialize; static;
    class procedure Cleanup; static;

  public
    /// <summary>
    /// 根据文件扩展名判断是否是二进制文件
    /// </summary>
    class function IsBinaryFileByExtension(const FileName: string): Boolean;

    /// <summary>
    /// 根据文件扩展名判断是否是文本文件
    /// </summary>
    class function IsTextFileByExtension(const FileName: string): Boolean;

    /// <summary>
    /// 根据文件内容判断是否是二进制文件
    /// </summary>
    class function IsBinaryFileByContent(const FileName: string): Boolean; overload;
    class function IsBinaryFileByContent(const Buffer: TBytes; Size: Integer): Boolean; overload;

    /// <summary>
    /// 快速检测文件是否是二进制文件（综合扩展名和内容）
    /// </summary>
    class function IsBinaryFile(const FileName: string): Boolean; overload;
    class function IsBinaryFile(const Buffer: TBytes; Size: Integer; const FileName: string = ''): Boolean; overload;

    /// <summary>
    /// 添加二进制文件扩展名
    /// </summary>
    class procedure AddBinaryExtension(const Extension: string);

    /// <summary>
    /// 添加文本文件扩展名
    /// </summary>
    class procedure AddTextExtension(const Extension: string);

    /// <summary>
    /// 添加二进制文件签名
    /// </summary>
    class procedure AddBinarySignature(const Name: string; const Signature: TArray<Byte>);
  end;

implementation

{ TBinaryDetector }

class procedure TBinaryDetector.AddBinaryExtension(const Extension: string);
begin
  FBinaryExtensions.Add(LowerCase(Extension));
end;

class procedure TBinaryDetector.AddBinarySignature(const Name: string; const Signature: TArray<Byte>);
begin
  FBinarySignatures.Add(Name, Signature);
  if Length(Signature) > FMaxSignatureLength then
    FMaxSignatureLength := Length(Signature);
end;

class procedure TBinaryDetector.AddTextExtension(const Extension: string);
begin
  FTextExtensions.Add(LowerCase(Extension));
end;

class procedure TBinaryDetector.Cleanup;
begin
  FreeAndNil(FBinaryExtensions);
  FreeAndNil(FTextExtensions);
  FreeAndNil(FBinarySignatures);
end;

class procedure TBinaryDetector.Initialize;
begin
  if FBinaryExtensions = nil then
  begin
    // 创建二进制文件扩展名集合
    FBinaryExtensions := THashSet<string>.Create;

    // 添加常见的二进制文件扩展名
    FBinaryExtensions.Add('.exe');
    FBinaryExtensions.Add('.dll');
    FBinaryExtensions.Add('.obj');
    FBinaryExtensions.Add('.bin');
    FBinaryExtensions.Add('.dat');
    FBinaryExtensions.Add('.db');
    FBinaryExtensions.Add('.dbf');
    FBinaryExtensions.Add('.mdb');
    FBinaryExtensions.Add('.accdb');
    FBinaryExtensions.Add('.pdf');
    FBinaryExtensions.Add('.doc');
    FBinaryExtensions.Add('.docx');
    FBinaryExtensions.Add('.xls');
    FBinaryExtensions.Add('.xlsx');
    FBinaryExtensions.Add('.ppt');
    FBinaryExtensions.Add('.pptx');
    FBinaryExtensions.Add('.zip');
    FBinaryExtensions.Add('.rar');
    FBinaryExtensions.Add('.7z');
    FBinaryExtensions.Add('.gz');
    FBinaryExtensions.Add('.tar');
    FBinaryExtensions.Add('.jpg');
    FBinaryExtensions.Add('.jpeg');
    FBinaryExtensions.Add('.png');
    FBinaryExtensions.Add('.gif');
    FBinaryExtensions.Add('.bmp');
    FBinaryExtensions.Add('.ico');
    FBinaryExtensions.Add('.tif');
    FBinaryExtensions.Add('.tiff');
    FBinaryExtensions.Add('.mp3');
    FBinaryExtensions.Add('.mp4');
    FBinaryExtensions.Add('.avi');
    FBinaryExtensions.Add('.mov');
    FBinaryExtensions.Add('.wmv');
    FBinaryExtensions.Add('.flv');
    FBinaryExtensions.Add('.mkv');
    FBinaryExtensions.Add('.wav');
    FBinaryExtensions.Add('.ogg');
    FBinaryExtensions.Add('.wma');
    FBinaryExtensions.Add('.class');
    FBinaryExtensions.Add('.jar');
    FBinaryExtensions.Add('.so');
    FBinaryExtensions.Add('.o');
    FBinaryExtensions.Add('.a');
    FBinaryExtensions.Add('.lib');
    FBinaryExtensions.Add('.dcu');
    FBinaryExtensions.Add('.dcp');
    FBinaryExtensions.Add('.bpl');
    FBinaryExtensions.Add('.res');
    FBinaryExtensions.Add('.dcr');
    FBinaryExtensions.Add('.dcm');
    FBinaryExtensions.Add('.psd');
    FBinaryExtensions.Add('.ai');
    FBinaryExtensions.Add('.eps');
    FBinaryExtensions.Add('.pyc');
    FBinaryExtensions.Add('.pyo');
    FBinaryExtensions.Add('.pyd');
  end;

  if FTextExtensions = nil then
  begin
    // 创建文本文件扩展名集合
    FTextExtensions := THashSet<string>.Create;

    // 添加常见的文本文件扩展名
    FTextExtensions.Add('.txt');
    FTextExtensions.Add('.log');
    FTextExtensions.Add('.ini');
    FTextExtensions.Add('.cfg');
    FTextExtensions.Add('.conf');
    FTextExtensions.Add('.config');
    FTextExtensions.Add('.xml');
    FTextExtensions.Add('.html');
    FTextExtensions.Add('.htm');
    FTextExtensions.Add('.css');
    FTextExtensions.Add('.js');
    FTextExtensions.Add('.json');
    FTextExtensions.Add('.yaml');
    FTextExtensions.Add('.yml');
    FTextExtensions.Add('.md');
    FTextExtensions.Add('.markdown');
    FTextExtensions.Add('.rst');
    FTextExtensions.Add('.csv');
    FTextExtensions.Add('.tsv');
    FTextExtensions.Add('.sql');
    FTextExtensions.Add('.c');
    FTextExtensions.Add('.cpp');
    FTextExtensions.Add('.h');
    FTextExtensions.Add('.hpp');
    FTextExtensions.Add('.cs');
    FTextExtensions.Add('.java');
    FTextExtensions.Add('.py');
    FTextExtensions.Add('.rb');
    FTextExtensions.Add('.php');
    FTextExtensions.Add('.pl');
    FTextExtensions.Add('.sh');
    FTextExtensions.Add('.bat');
    FTextExtensions.Add('.cmd');
    FTextExtensions.Add('.ps1');
    FTextExtensions.Add('.pas');
    FTextExtensions.Add('.dpr');
    FTextExtensions.Add('.inc');
    FTextExtensions.Add('.dfm');
    FTextExtensions.Add('.go');
    FTextExtensions.Add('.rs');
    FTextExtensions.Add('.swift');
    FTextExtensions.Add('.kt');
    FTextExtensions.Add('.ts');
    FTextExtensions.Add('.jsx');
    FTextExtensions.Add('.tsx');
    FTextExtensions.Add('.vue');
    FTextExtensions.Add('.properties');
    FTextExtensions.Add('.gradle');
    FTextExtensions.Add('.sln');
    FTextExtensions.Add('.csproj');
    FTextExtensions.Add('.vbproj');
    FTextExtensions.Add('.vcxproj');
    FTextExtensions.Add('.gitignore');
    FTextExtensions.Add('.dockerignore');
    FTextExtensions.Add('.editorconfig');
  end;

  if FBinarySignatures = nil then
  begin
    // 创建二进制文件签名字典
    FBinarySignatures := TDictionary<string, TArray<Byte>>.Create;
    FMaxSignatureLength := 0;

    // 添加常见的二进制文件签名
    // ZIP, JAR, APK, DOCX, XLSX, PPTX
    AddBinarySignature('ZIP', [$50, $4B, $03, $04]);

    // PDF
    AddBinarySignature('PDF', [$25, $50, $44, $46]);

    // GIF
    AddBinarySignature('GIF87a', [$47, $49, $46, $38, $37, $61]);
    AddBinarySignature('GIF89a', [$47, $49, $46, $38, $39, $61]);

    // JPEG
    AddBinarySignature('JPEG', [$FF, $D8, $FF]);

    // PNG
    AddBinarySignature('PNG', [$89, $50, $4E, $47, $0D, $0A, $1A, $0A]);

    // BMP
    AddBinarySignature('BMP', [$42, $4D]);

    // EXE, DLL
    AddBinarySignature('PE', [$4D, $5A]);

    // RAR
    AddBinarySignature('RAR', [$52, $61, $72, $21, $1A, $07]);

    // 7Z
    AddBinarySignature('7Z', [$37, $7A, $BC, $AF, $27, $1C]);

    // GZIP
    AddBinarySignature('GZIP', [$1F, $8B]);

    // MIDI
    AddBinarySignature('MIDI', [$4D, $54, $68, $64]);

    // MP3
    AddBinarySignature('MP3', [$49, $44, $33]);

    // WAV
    AddBinarySignature('WAV', [$52, $49, $46, $46]);

    // AVI
    AddBinarySignature('AVI', [$52, $49, $46, $46]);

    // SWF
    AddBinarySignature('SWF', [$46, $57, $53]);
    AddBinarySignature('SWF_COMPRESSED', [$43, $57, $53]);

    // DCU (Delphi Compiled Unit)
    AddBinarySignature('DCU', [$50, $4B, $03, $04]);
  end;
end;

class function TBinaryDetector.IsBinaryFile(const FileName: string): Boolean;
var
  FileExt: string;
begin
  // 首先根据扩展名判断
  FileExt := LowerCase(ExtractFileExt(FileName));

  // 如果扩展名在二进制文件列表中，直接返回True
  if FBinaryExtensions.Contains(FileExt) then
    Exit(True);

  // 如果扩展名在文本文件列表中，直接返回False
  if FTextExtensions.Contains(FileExt) then
    Exit(False);

  // 如果扩展名不在列表中，根据内容判断
  Result := IsBinaryFileByContent(FileName);
end;

class function TBinaryDetector.IsBinaryFile(const Buffer: TBytes; Size: Integer; const FileName: string): Boolean;
var
  FileExt: string;
begin
  // 如果提供了文件名，首先根据扩展名判断
  if FileName <> '' then
  begin
    FileExt := LowerCase(ExtractFileExt(FileName));

    // 如果扩展名在二进制文件列表中，直接返回True
    if FBinaryExtensions.Contains(FileExt) then
      Exit(True);

    // 如果扩展名在文本文件列表中，直接返回False
    if FTextExtensions.Contains(FileExt) then
      Exit(False);
  end;

  // 根据内容判断
  Result := IsBinaryFileByContent(Buffer, Size);
end;

class function TBinaryDetector.IsBinaryFileByContent(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 只读取文件的前4KB用于判断
      SetLength(Buffer, 4096);
      BytesRead := FileStream.Read(Buffer[0], 4096);
      if BytesRead > 0 then
        Result := IsBinaryFileByContent(Buffer, BytesRead);
    finally
      FileStream.Free;
    end;
  except
    // 忽略异常，返回False
  end;
end;

class function TBinaryDetector.IsBinaryFileByContent(const Buffer: TBytes; Size: Integer): Boolean;
var
  i, j: Integer;
  Signature: TArray<Byte>;
  Match: Boolean;
  ZeroCount, NullCount: Integer;
  TextRatio: Double;
begin
  // 首先检查文件签名
  for Signature in FBinarySignatures.Values do
  begin
    if Length(Signature) > Size then
      Continue;

    Match := True;
    for i := 0 to Length(Signature) - 1 do
    begin
      if Buffer[i] <> Signature[i] then
      begin
        Match := False;
        Break;
      end;
    end;

    if Match then
      Exit(True);
  end;

  // 检查文件内容中的二进制特征
  ZeroCount := 0;
  NullCount := 0;

  for i := 0 to Min(Size - 1, 4095) do
  begin
    // 检查NULL字符
    if Buffer[i] = 0 then
      Inc(NullCount);

    // 检查不可打印字符（ASCII 0-8, 14-31）
    if (Buffer[i] < 9) or ((Buffer[i] > 13) and (Buffer[i] < 32)) then
      Inc(ZeroCount);
  end;

  // 计算二进制特征比例
  TextRatio := 1.0 - (ZeroCount / Min(Size, 4096));

  // 如果NULL字符过多，或者不可打印字符过多，判断为二进制文件
  if (NullCount > 1) or (TextRatio < 0.9) then
    Result := True
  else
    Result := False;
end;

class function TBinaryDetector.IsBinaryFileByExtension(const FileName: string): Boolean;
var
  FileExt: string;
begin
  FileExt := LowerCase(ExtractFileExt(FileName));
  Result := FBinaryExtensions.Contains(FileExt);
end;

class function TBinaryDetector.IsTextFileByExtension(const FileName: string): Boolean;
var
  FileExt: string;
begin
  FileExt := LowerCase(ExtractFileExt(FileName));
  Result := FTextExtensions.Contains(FileExt);
end;

initialization
  TBinaryDetector.Initialize;

finalization
  TBinaryDetector.Cleanup;

end.
