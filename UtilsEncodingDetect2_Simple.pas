unit UtilsEncodingDetect2;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  JclBOM, JclStrings, JclFileUtils, JclStreams, Winapi.Windows;

type
  // 编码检测结果记录
  TEncodingDetectResult = record
    EncodingName: string;    // 编码名称
    Confidence: Double;      // 置信度 (0.0-1.0)
    HasBOM: Boolean;         // 是否有BOM
    LanguageHint: string;    // 语言提示
  end;

  // 增强版编码检测结果记录
  TEncodingDetectionResult = record
    DetectedEncoding: TEncoding; // 检测到的编码
    EncodingName: string;        // 编码名称
    Confidence: Double;          // 置信度 (0.0-1.0)
    HasBOM: Boolean;             // 是否有BOM
    Description: string;         // 描述
  end;

  // 编码检测算法
  TEncodingDetectionAlgorithm = (
    edaBOM,           // BOM检测
    edaStatistical,   // 统计分析
    edaPattern,       // 模式匹配
    edaHeuristic,     // 启发式方法
    edaCombined       // 组合方法
  );

  // 编码检测选项
  TEncodingDetectionOptions = record
    MaxScanSize: Integer;             // 最大扫描大小
    MinConfidence: Double;            // 最小置信度
    PreferredEncoding: TEncoding;     // 首选编码
    DefaultEncoding: TEncoding;       // 默认编码
    AlgorithmPriority: set of TEncodingDetectionAlgorithm; // 算法优先级
  end;

  // 增强版编码检测器类
  TEncodingDetector2 = class
  private
    FOptions: TEncodingDetectionOptions;
    FLastError: string;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property Options: TEncodingDetectionOptions read FOptions write FOptions;
    property LastError: string read FLastError;
    
    // 编码检测方法
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
    function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
    function DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
    
    // 编码工具方法
    class function GetSupportedEncodings: TArray<TEncoding>;
    class function GetSupportedEncodingNames: TArray<string>;
    class function GetEncodingByName(const EncodingName: string): TEncoding;
    class function GetEncodingFriendlyName(Encoding: TEncoding): string;
  end;

implementation

{ TEncodingDetector2 }

constructor TEncodingDetector2.Create;
begin
  inherited Create;
  
  // 设置默认选项
  FOptions.MaxScanSize := 64 * 1024; // 默认扫描64KB
  FOptions.MinConfidence := 0.6;     // 最小置信度60%
  FOptions.PreferredEncoding := nil;
  FOptions.DefaultEncoding := TEncoding.ANSI;
  FOptions.AlgorithmPriority := [edaBOM, edaStatistical, edaPattern, edaCombined];
end;

destructor TEncodingDetector2.Destroy;
begin
  inherited;
end;

function TEncodingDetector2.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  Stream: TFileStream;
  Buffer: TBytes;
  PreambleSize: Integer;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  
  if not FileExists(FileName) then
  begin
    Result.Description := '文件不存在';
    Exit;
  end;
  
  try
    // 打开文件
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取文件头进行BOM检测
      SetLength(Buffer, Min(Stream.Size, 4));
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));
      
      // 使用TEncoding检测BOM
      if Length(Buffer) >= 2 then
      begin
        Result.DetectedEncoding := TEncoding.GetBufferEncoding(Buffer, TEncoding.Default, PreambleSize);
        
        if Result.DetectedEncoding = TEncoding.UTF8 then
        begin
          Result.EncodingName := 'UTF-8';
          Result.HasBOM := PreambleSize > 0;
          Result.Confidence := 1.0;
          Result.Description := 'UTF-8' + IfThen(Result.HasBOM, ' with BOM', ' without BOM');
        end
        else if Result.DetectedEncoding = TEncoding.Unicode then
        begin
          Result.EncodingName := 'UTF-16';
          Result.HasBOM := True;
          Result.Confidence := 1.0;
          Result.Description := 'UTF-16LE with BOM';
        end
        else if Result.DetectedEncoding = TEncoding.BigEndianUnicode then
        begin
          Result.EncodingName := 'UTF-16BE';
          Result.HasBOM := True;
          Result.Confidence := 1.0;
          Result.Description := 'UTF-16BE with BOM';
        end
        else
        begin
          // 如果没有检测到BOM，则尝试猜测编码
          if Buffer[0] = 0 then
          begin
            Result.DetectedEncoding := TEncoding.Unicode;
            Result.EncodingName := 'UTF-16';
            Result.HasBOM := False;
            Result.Confidence := 0.7;
            Result.Description := 'UTF-16 detected (probable)';
          end
          else
          begin
            // 默认为ANSI
            Result.DetectedEncoding := TEncoding.ANSI;
            Result.EncodingName := 'ANSI';
            Result.HasBOM := False;
            Result.Confidence := 0.5;
            Result.Description := 'ANSI detected (default)';
          end;
        end;
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result.DetectedEncoding := nil;
      Result.EncodingName := 'Error';
      Result.Confidence := 0;
      Result.HasBOM := False;
      Result.Description := 'Error: ' + E.Message;
    end;
  end;
end;

function TEncodingDetector2.DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
var
  SavedPosition: Int64;
  Buffer: TBytes;
  ReadSize: Integer;
begin
  // 保存当前流位置
  SavedPosition := Stream.Position;
  Stream.Position := 0;
  
  try
    // 读取数据进行检测
    SetLength(Buffer, Min(Stream.Size, FOptions.MaxScanSize));
    if Length(Buffer) > 0 then
      ReadSize := Stream.Read(Buffer[0], Length(Buffer))
    else
      ReadSize := 0;
      
    SetLength(Buffer, ReadSize);
    
    // 使用内部检测函数处理
    Result := DetectBytesEncoding(Buffer);
  finally
    // 恢复流位置
    Stream.Position := SavedPosition;
  end;
end;

function TEncodingDetector2.DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
var
  PreambleSize: Integer;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  
  if Length(Bytes) = 0 then
    Exit;
  
  // 使用TEncoding检测BOM
  Result.DetectedEncoding := TEncoding.GetBufferEncoding(Bytes, TEncoding.Default, PreambleSize);
  
  if Result.DetectedEncoding = TEncoding.UTF8 then
  begin
    Result.EncodingName := 'UTF-8';
    Result.HasBOM := PreambleSize > 0;
    Result.Confidence := 1.0;
    Result.Description := 'UTF-8' + IfThen(Result.HasBOM, ' with BOM', ' without BOM');
  end
  else if Result.DetectedEncoding = TEncoding.Unicode then
  begin
    Result.EncodingName := 'UTF-16';
    Result.HasBOM := True;
    Result.Confidence := 1.0;
    Result.Description := 'UTF-16LE with BOM';
  end
  else if Result.DetectedEncoding = TEncoding.BigEndianUnicode then
  begin
    Result.EncodingName := 'UTF-16BE';
    Result.HasBOM := True;
    Result.Confidence := 1.0;
    Result.Description := 'UTF-16BE with BOM';
  end
  else
  begin
    // 如果没有检测到BOM，则尝试根据内容猜测编码
    var HasHighBit := False;
    var HasNulls := False;
    var NullPosition := 0;
    
    for var i := 0 to Min(Length(Bytes) - 1, 1000) do
    begin
      if Bytes[i] = 0 then
      begin
        HasNulls := True;
        NullPosition := i;
        Break;
      end
      else if Bytes[i] >= $80 then
      begin
        HasHighBit := True;
      end;
    end;
    
    if HasNulls and (NullPosition mod 2 = 0) then
    begin
      // 可能是UTF-16LE
      Result.DetectedEncoding := TEncoding.Unicode;
      Result.EncodingName := 'UTF-16';
      Result.HasBOM := False;
      Result.Confidence := 0.7;
      Result.Description := 'UTF-16 detected (probable)';
    end
    else if HasHighBit then
    begin
      // 可能是UTF-8或其他多字节编码
      Result.DetectedEncoding := TEncoding.UTF8;
      Result.EncodingName := 'UTF-8';
      Result.HasBOM := False;
      Result.Confidence := 0.6;
      Result.Description := 'UTF-8 detected (probable)';
    end
    else
    begin
      // 纯ASCII
      Result.DetectedEncoding := TEncoding.ASCII;
      Result.EncodingName := 'ASCII';
      Result.HasBOM := False;
      Result.Confidence := 0.9;
      Result.Description := 'ASCII detected';
    end;
  end;
end;

class function TEncodingDetector2.GetSupportedEncodings: TArray<TEncoding>;
begin
  SetLength(Result, 5);
  Result[0] := TEncoding.ANSI;
  Result[1] := TEncoding.ASCII;
  Result[2] := TEncoding.UTF8;
  Result[3] := TEncoding.Unicode;      // UTF-16LE
  Result[4] := TEncoding.BigEndianUnicode; // UTF-16BE
end;

class function TEncodingDetector2.GetSupportedEncodingNames: TArray<string>;
begin
  SetLength(Result, 8);
  Result[0] := 'ANSI';
  Result[1] := 'ASCII';
  Result[2] := 'UTF-8';
  Result[3] := 'UTF-16';
  Result[4] := 'UTF-16BE';
  Result[5] := 'GBK';
  Result[6] := 'GB18030';
  Result[7] := 'Big5';
end;

class function TEncodingDetector2.GetEncodingByName(const EncodingName: string): TEncoding;
var
  NormalizedName: string;
begin
  NormalizedName := LowerCase(EncodingName);
  
  if (NormalizedName = 'ansi') then
    Result := TEncoding.ANSI
  else if (NormalizedName = 'ascii') then
    Result := TEncoding.ASCII
  else if (NormalizedName = 'utf-8') or (NormalizedName = 'utf8') then
    Result := TEncoding.UTF8
  else if (NormalizedName = 'utf-16') or (NormalizedName = 'utf16') or 
          (NormalizedName = 'utf-16le') or (NormalizedName = 'utf16le') then
    Result := TEncoding.Unicode
  else if (NormalizedName = 'utf-16be') or (NormalizedName = 'utf16be') then
    Result := TEncoding.BigEndianUnicode
  else if (NormalizedName = 'gbk') or (NormalizedName = 'gb2312') then
  begin
    try
      Result := TEncoding.GetEncoding(936);
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'gb18030') then
  begin
    try
      Result := TEncoding.GetEncoding(54936);
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'big5') then
  begin
    try
      Result := TEncoding.GetEncoding(950);
    except
      Result := TEncoding.ANSI;
    end;
  end
  else
    Result := TEncoding.ANSI; // 默认返回ANSI
end;

class function TEncodingDetector2.GetEncodingFriendlyName(Encoding: TEncoding): string;
begin
  if Encoding = nil then
    Result := 'Unknown'
  else if Encoding = TEncoding.ANSI then
    Result := 'ANSI'
  else if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding.CodePage = 936 then
    Result := 'GBK'
  else if Encoding.CodePage = 54936 then
    Result := 'GB18030'
  else if Encoding.CodePage = 950 then
    Result := 'Big5'
  else
    Result := Format('CodePage %d', [Encoding.CodePage]);
end;

end. 