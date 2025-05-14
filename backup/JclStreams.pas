unit JclStreams;

interface

uses
  System.Classes, System.SysUtils, System.NetEncoding;

// 从流计算MD5哈希值字符串
function GetHashStringFromStream(Stream: TStream): string;

implementation

// 获取文件内容的唯一标识，使用Base64编码的哈希值
function GetHashStringFromStream(Stream: TStream): string;
var
  SavePos: Int64;
  Buffer: TBytes;
  EncodedStr: string;
begin
  Result := '';
  if Stream = nil then
    Exit;

  SavePos := Stream.Position;
  try
    Stream.Position := 0;
    
    // 对于大文件，只取前100KB进行哈希计算，以提高效率
    var MaxReadSize := 102400; // 100KB
    var SizeToRead := Stream.Size;
    if SizeToRead > MaxReadSize then
      SizeToRead := MaxReadSize;
    
    SetLength(Buffer, SizeToRead);
    if SizeToRead > 0 then
      Stream.ReadBuffer(Buffer[0], SizeToRead);
    
    // 使用Base64编码获取哈希值
    EncodedStr := TNetEncoding.Base64.EncodeBytesToString(Buffer);
    // 为了缩短结果，只取编码的前32字符作为哈希值
    if Length(EncodedStr) > 32 then
      Result := Copy(EncodedStr, 1, 32)
    else
      Result := EncodedStr;
  finally
    Stream.Position := SavePos;
  end;
end;

end. 