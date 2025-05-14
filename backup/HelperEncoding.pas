unit HelperEncoding;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  ImprovedEncodingDetector, ImprovedEncodingConverter, UtilsEncodingTypes;

type
  TEncodingInfo = record
    Name: string;
    ShortName: string;
    HasBOM: Boolean;
  end;

  TEncodingModel = class
  private
    FEncodings: TList<TEncodingInfo>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReloadEncodings;

    property Encodings: TList<TEncodingInfo> read FEncodings;
  end;

  TEncodingController = class
  private
    FDetector: TImprovedEncodingDetector;
    FConverter: TImprovedEncodingConverter;
  public
    constructor Create;
    destructor Destroy; override;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;

    // 转换单个文件
    function ConvertSingleFileByName(const FileName, TargetEncoding: string; WithBOM: Boolean;
      OnSuccess: TProc<string> = nil): Boolean;

    // 批量转换文件
    procedure ConvertFilesByName(const FileNames: TArray<string>; const TargetEncoding: string;
      WithBOM: Boolean; OnSuccess: TProc<string> = nil);
  end;

  TFileHelper = class
  public
    // 获取文件夹中的所有文件扩展名
    function GetFileExtensions(const FolderPath: string): TArray<string>;

    // 获取文件夹中的所有文件
    function GetFilesInFolder(const FolderPath: string; const Extensions: TArray<string>;
      IncludeSubdirs: Boolean): TArray<string>;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;

    // 检查是否为正常文本文件
    function IsNormalTextFile(const FileName: string): Boolean;
  end;

implementation

{ TEncodingModel }

constructor TEncodingModel.Create;
begin
  inherited Create;
  FEncodings := TList<TEncodingInfo>.Create;
  ReloadEncodings;
end;

destructor TEncodingModel.Destroy;
begin
  FEncodings.Free;
  inherited;
end;

procedure TEncodingModel.ReloadEncodings;
var
  Info: TEncodingInfo;
begin
  FEncodings.Clear;

  // 添加常用编码
  Info.Name := 'UTF-8';
  Info.ShortName := 'UTF-8';
  Info.HasBOM := False;
  FEncodings.Add(Info);

  Info.Name := 'UTF-8 with BOM';
  Info.ShortName := 'UTF-8';
  Info.HasBOM := True;
  FEncodings.Add(Info);

  Info.Name := 'UTF-16 LE';
  Info.ShortName := 'UTF-16LE';
  Info.HasBOM := True;
  FEncodings.Add(Info);

  Info.Name := 'UTF-16 BE';
  Info.ShortName := 'UTF-16BE';
  Info.HasBOM := True;
  FEncodings.Add(Info);

  Info.Name := 'ANSI';
  Info.ShortName := 'ANSI';
  Info.HasBOM := False;
  FEncodings.Add(Info);

  Info.Name := 'GB18030';
  Info.ShortName := 'GB18030';
  Info.HasBOM := False;
  FEncodings.Add(Info);

  Info.Name := 'GBK';
  Info.ShortName := 'GBK';
  Info.HasBOM := False;
  FEncodings.Add(Info);

  Info.Name := 'Big5';
  Info.ShortName := 'Big5';
  Info.HasBOM := False;
  FEncodings.Add(Info);

  Info.Name := 'Shift-JIS';
  Info.ShortName := 'Shift-JIS';
  Info.HasBOM := False;
  FEncodings.Add(Info);
end;

{ TEncodingController }

constructor TEncodingController.Create;
begin
  inherited Create;
  FDetector := TImprovedEncodingDetector.Create;
  FConverter := TImprovedEncodingConverter.Create;
end;

destructor TEncodingController.Destroy;
begin
  FDetector.Free;
  FConverter.Free;
  inherited;
end;

function TEncodingController.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo := FDetector.DetectFileEncoding(FileName);
  HasBOM := EncodingInfo.HasBOM;
  Result := EncodingInfo.Encoding.GetName;
end;

function TEncodingController.ConvertSingleFileByName(const FileName, TargetEncoding: string;
  WithBOM: Boolean; OnSuccess: TProc<string> = nil): Boolean;
var
  TargetEncodingClass: TEncodingClass;
  SourceEncodingInfo: TEncodingInfo;
  SourceEncodingClass: TEncodingClass;
begin
  // 获取源文件编码
  SourceEncodingInfo := FDetector.DetectFileEncoding(FileName);
  SourceEncodingClass := SourceEncodingInfo.Encoding;

  // 获取目标编码类
  if TargetEncoding = 'UTF-8' then
    TargetEncodingClass := TEncodingClass.GetEncoding(65001)
  else if TargetEncoding = 'UTF-16LE' then
    TargetEncodingClass := TEncodingClass.GetEncoding(1200)
  else if TargetEncoding = 'UTF-16BE' then
    TargetEncodingClass := TEncodingClass.GetEncoding(1201)
  else if TargetEncoding = 'ANSI' then
    TargetEncodingClass := TEncodingClass.GetEncoding(0)
  else if TargetEncoding = 'GB18030' then
    TargetEncodingClass := TEncodingClass.GetEncoding(54936)
  else if TargetEncoding = 'GBK' then
    TargetEncodingClass := TEncodingClass.GetEncoding(936)
  else if TargetEncoding = 'Big5' then
    TargetEncodingClass := TEncodingClass.GetEncoding(950)
  else if TargetEncoding = 'Shift-JIS' then
    TargetEncodingClass := TEncodingClass.GetEncoding(932)
  else
    TargetEncodingClass := TEncodingClass.GetEncoding(65001); // 默认为 UTF-8

  // 设置是否保留BOM
  FConverter.PreserveBOM := WithBOM;

  // 转换文件
  Result := FConverter.ConvertFileEncoding(FileName, FileName, SourceEncodingClass, TargetEncodingClass);

  // 如果转换成功，调用回调函数
  if Result and Assigned(OnSuccess) then
    OnSuccess(FileName);
end;

procedure TEncodingController.ConvertFilesByName(const FileNames: TArray<string>;
  const TargetEncoding: string; WithBOM: Boolean; OnSuccess: TProc<string> = nil);
var
  i: Integer;
begin
  for i := 0 to High(FileNames) do
  begin
    if ConvertSingleFileByName(FileNames[i], TargetEncoding, WithBOM, OnSuccess) then
      // 转换成功，已在 ConvertSingleFileByName 中调用回调函数
    else
      // 转换失败，不调用回调函数
  end;
end;

{ TFileHelper }

function TFileHelper.GetFileExtensions(const FolderPath: string): TArray<string>;
var
  Files: TArray<string>;
  Extensions: TDictionary<string, Boolean>;
  i: Integer;
  Ext: string;
begin
  Extensions := TDictionary<string, Boolean>.Create;
  try
    // 获取文件夹中的所有文件
    Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);

    // 提取扩展名
    for i := 0 to High(Files) do
    begin
      Ext := ExtractFileExt(Files[i]);
      if not Extensions.ContainsKey(Ext) then
        Extensions.Add(Ext, True);
    end;

    // 转换为数组
    SetLength(Result, Extensions.Count);
    i := 0;
    for Ext in Extensions.Keys do
    begin
      Result[i] := Ext;
      Inc(i);
    end;
  finally
    Extensions.Free;
  end;
end;

function TFileHelper.GetFilesInFolder(const FolderPath: string; const Extensions: TArray<string>;
  IncludeSubdirs: Boolean): TArray<string>;
var
  Files: TArray<string>;
  FilteredFiles: TList<string>;
  i, j: Integer;
  Ext: string;
  SearchOption: TSearchOption;
begin
  FilteredFiles := TList<string>.Create;
  try
    // 设置搜索选项
    if IncludeSubdirs then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;

    // 获取文件夹中的所有文件
    Files := TDirectory.GetFiles(FolderPath, '*.*', SearchOption);

    // 过滤扩展名
    for i := 0 to High(Files) do
    begin
      Ext := ExtractFileExt(Files[i]);
      for j := 0 to High(Extensions) do
      begin
        if SameText(Ext, Extensions[j]) then
        begin
          FilteredFiles.Add(Files[i]);
          Break;
        end;
      end;
    end;

    // 转换为数组
    Result := FilteredFiles.ToArray;
  finally
    FilteredFiles.Free;
  end;
end;

function TFileHelper.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  Detector: TImprovedEncodingDetector;
  EncodingInfo: TEncodingInfo;
begin
  Detector := TImprovedEncodingDetector.Create;
  try
    EncodingInfo := Detector.DetectFileEncoding(FileName);
    HasBOM := EncodingInfo.HasBOM;
    Result := EncodingInfo.Encoding.GetName;
  finally
    Detector.Free;
  end;
end;

function TFileHelper.IsNormalTextFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  i: Integer;
  BinaryCount: Integer;
begin
  Result := True;

  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit(False);

  // 检查文件大小
  if TFile.GetSize(FileName) > 10 * 1024 * 1024 then // 10MB
    Exit(False);

  // 检查文件内容
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    // 读取前 4KB 的内容
    SetLength(Buffer, Min(Stream.Size, 4 * 1024));
    Stream.ReadBuffer(Buffer[0], Length(Buffer));

    // 检查是否包含二进制字符
    BinaryCount := 0;
    for i := 0 to High(Buffer) do
    begin
      if (Buffer[i] < 9) or (Buffer[i] > 126) and (Buffer[i] < 160) then
        Inc(BinaryCount);
    end;

    // 如果二进制字符超过 10%，认为是二进制文件
    Result := (BinaryCount / Length(Buffer)) < 0.1;
  finally
    Stream.Free;
  end;
end;

end.
