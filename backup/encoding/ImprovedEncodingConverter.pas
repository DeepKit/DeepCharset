unit ImprovedEncodingConverter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  UtilsEncodingTypes;

type
  TImprovedEncodingConverter = class
  private
    FPreserveBOM: Boolean;
    FErrorCount: Integer;
    FErrorDetails: string;

  public
    constructor Create;
    destructor Destroy; override;

    // 转换文件编码
    function ConvertFileEncoding(const SourceFile, TargetFile: string;
      SourceEncoding, TargetEncoding: TEncodingClass): Boolean;

    // 配置选项
    property PreserveBOM: Boolean read FPreserveBOM write FPreserveBOM;
  end;

implementation

constructor TImprovedEncodingConverter.Create;
begin
  inherited Create;
  FPreserveBOM := True;
  FErrorCount := 0;
  FErrorDetails := '';
end;

destructor TImprovedEncodingConverter.Destroy;
begin
  inherited;
end;

function TImprovedEncodingConverter.ConvertFileEncoding(const SourceFile, TargetFile: string;
  SourceEncoding, TargetEncoding: TEncodingClass): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  SourceBytes, TargetBytes: TBytes;
  SourceText: string;
  TargetEnc: TEncoding;
  BOMBytes: TBytes;
  BOMLength: Integer;
  WithBOM: Boolean;
begin
  Result := False;

  if not FileExists(SourceFile) then
    Exit;

  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.Read(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;

    // 检测是否需要添加BOM
    WithBOM := FPreserveBOM;

    // 获取目标编码对象
    if TargetEncoding = nil then
      TargetEnc := TEncoding.UTF8
    else
      TargetEnc := TargetEncoding.GetEncoding;

    // 转换编码
    if SourceEncoding = nil then
      SourceText := TEncoding.Default.GetString(SourceBytes)
    else
      SourceText := SourceEncoding.GetString(SourceBytes);

    // 获取目标编码的字节
    TargetBytes := TargetEnc.GetBytes(SourceText);

    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFile, fmCreate);
    try
      // 如果需要添加BOM，先写入BOM
      if WithBOM and (TargetEnc is TUnicodeEncoding) then
      begin
        BOMBytes := TargetEnc.GetPreamble;
        BOMLength := Length(BOMBytes);
        if BOMLength > 0 then
          TargetStream.Write(BOMBytes[0], BOMLength);
      end;

      // 写入文件内容
      if Length(TargetBytes) > 0 then
        TargetStream.Write(TargetBytes[0], Length(TargetBytes));
    finally
      TargetStream.Free;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      FErrorDetails := E.Message;
      Inc(FErrorCount);
    end;
  end;
end;

end.
