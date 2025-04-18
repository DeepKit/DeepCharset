unit UtilsJCLEncoding;

interface

uses
  System.SysUtils, System.Classes, JclBOM, JclStrings, JclEncodingUtils,
  JclFileUtils, JclStreams;

// 兼容性函数：将TArray<Byte>安全转换为PByte
function ByteArrayToPointer(const Arr: TArray<Byte>): PByte;

// 兼容性函数：检测文件编码名称
function DetectFileEncoding(const FileName: string): string;

// 兼容性函数：将文件转换为UTF-8 BOM
function ConvertFileToUTF8BOM(const SourceFile, TargetFile: string): Boolean;

// 兼容性函数：通过编码名称执行文件转换
function ConvertFileByName(const SourceFile, TargetFile, SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;

implementation

function ByteArrayToPointer(const Arr: TArray<Byte>): PByte;
begin
  if Length(Arr) = 0 then
    Result := nil
  else
    Result := @Arr[0];
end;

function DetectFileEncoding(const FileName: string): string;
begin
  Result := JclEncodingUtils.DetectFileEncoding(FileName);
end;

function ConvertFileToUTF8BOM(const SourceFile, TargetFile: string): Boolean;
begin
  Result := JclEncodingUtils.ConvertFileToUTF8BOM(SourceFile, TargetFile);
end;

function ConvertFileByName(const SourceFile, TargetFile, SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
begin
  Result := JclEncodingUtils.ConvertFileByName(SourceFile, TargetFile, SourceEncoding, TargetEncoding, AddBOM);
end;

end. 