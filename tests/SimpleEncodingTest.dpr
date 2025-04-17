program SimpleEncodingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclBOM,
  JclEncodingUtils;

function ConvertFileToUTF8BOM(const SourceFile, TargetFile: string): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  SourceEncoding: string;
  Content: string;
  UTF8Bytes: TBytes;
  BOMBytes: TBytes;
begin
  Result := False;
  try
    SourceEncoding := DetectFileEncoding(SourceFile);
    
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(UTF8Bytes, SourceStream.Size);
      SourceStream.ReadBuffer(UTF8Bytes[0], SourceStream.Size);
      
      case SourceEncoding of
        'UTF-8': Content := TEncoding.UTF8.GetString(UTF8Bytes);
        'UTF-16LE': Content := TEncoding.Unicode.GetString(UTF8Bytes);
        'UTF-16BE': Content := TEncoding.BigEndianUnicode.GetString(UTF8Bytes);
        'ASCII': Content := TEncoding.ASCII.GetString(UTF8Bytes);
        'GBK': Content := TEncoding.GetEncoding(936).GetString(UTF8Bytes);
      else
        Content := TEncoding.Default.GetString(UTF8Bytes);
      end;
      
      TargetStream := TFileStream.Create(TargetFile, fmCreate);
      try
        BOMBytes := TEncoding.UTF8.GetPreamble;
        if Length(BOMBytes) > 0 then
          TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
        
        UTF8Bytes := TEncoding.UTF8.GetBytes(Content);
        if Length(UTF8Bytes) > 0 then
          TargetStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
        
        Result := True;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
      WriteLn('转换文件时发生错误: ', E.Message);
  end;
end;

function DetectFileEncoding(const FileName: string): string;
var
  BOM: TJclBOM;
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    BOM := DetectBOM(Stream);
    case BOM of
      bomUtf8: Result := 'UTF-8';
      bomUtf16LE: Result := 'UTF-16LE';
      bomUtf16BE: Result := 'UTF-16BE';
    else
      if IsUTF8Text(Stream) then
        Result := 'UTF-8'
      else if IsASCIIText(Stream) then
        Result := 'ASCII'
      else
        Result := 'GBK';
    end;
  finally
    Stream.Free;
  end;
end;

procedure TestSingleFile(const SourceFile, TargetFile: string);
begin
  WriteLn('测试文件: ', SourceFile);
  if ConvertFileToUTF8BOM(SourceFile, TargetFile) then
    WriteLn('转换成功: ', TargetFile)
  else
    WriteLn('转换失败');
end;

begin
  try
    SetConsoleOutputCP(65001);
    
    if ParamCount >= 2 then
      TestSingleFile(ParamStr(1), ParamStr(2))
    else
      WriteLn('用法: SimpleEncodingTest.exe 源文件 目标文件');
    
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