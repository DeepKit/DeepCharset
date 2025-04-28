unit ImprovedEncodingDetector;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Character, System.StrUtils,
  System.Diagnostics, System.Generics.Collections, Winapi.Windows, UtilsEncodingTypes;

type
  // 编码检测结果
  TEncodingDetectionResult = record
    Encoding: TEncodingClass;
    Name: string;
    Confidence: Double;
    HasBOM: Boolean;
    BOMSize: Integer;
  end;

  // 编码统计信息
  TEncodingStats = record
    TotalBytes: Integer;
    ASCIIBytes: Integer;
    ValidBytes: Integer;
    InvalidBytes: Integer;
    ProcessingTime: Int64; // 修改为Int64，用于存储处理时间（毫秒）
    MaxFrequency: Integer;
    SequenceTypes: TDictionary<String, Integer>;
    ErrorTypes: TDictionary<String, Integer>;
    CodePointRanges: TDictionary<String, Integer>;
  end;

  // 编码检测器类
  TEncodingDetector = class
  private
    FLogger: TObject; // 实际使用时可以替换为适当的日志接口

    // 检测BOM
    function DetectBOM(const Buffer: TBytes; out Encoding: TEncodingClass; out BOMSize: Integer): Boolean;

    // 检测UTF-8编码
    function IsValidUTF8(const Buffer: TBytes; var Stats: TEncodingStats): Double;

    // 检测ASCII编码
    function IsASCII(const Buffer: TBytes): Double;

    // 检测中文编码（GBK/GB2312）
    function IsChineseEncoding(const Buffer: TBytes): Double;

    // 检测日文编码（Shift-JIS）
    function IsJapaneseEncoding(const Buffer: TBytes): Double;

    // 检测韩文编码（EUC-KR）
    function IsKoreanEncoding(const Buffer: TBytes): Double;

    // 检测Big5编码
    function IsBig5Encoding(const Buffer: TBytes): Double;

    // 检测EUC-JP编码
    function IsEUCJPEncoding(const Buffer: TBytes): Double;

    // 检测GB18030编码
    function IsGB18030Encoding(const Buffer: TBytes): Double;

    // 检测ISO-8859系列编码
    function IsISO8859Encoding(const Buffer: TBytes): Double;

    // 检测Windows-125x系列编码
    function IsWindows125xEncoding(const Buffer: TBytes): Double;

    // 检测KOI8系列编码
    function IsKOI8Encoding(const Buffer: TBytes): Double;

    // 获取编码名称
    function GetEncodingName(Encoding: TEncodingClass): string;
  public
    constructor Create;
    destructor Destroy; override;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;

    // 检测内存中的数据编码
    function DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;

    // 检测流中的数据编码
    function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
  end;

// 全局函数，方便直接调用
function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
function DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;

implementation

// 全局函数实现
function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  Detector: TEncodingDetector;
begin
  Detector := TEncodingDetector.Create;
  try
    Result := Detector.DetectFileEncoding(FileName);
  finally
    Detector.Free;
  end;
end;

function DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  Detector: TEncodingDetector;
begin
  Detector := TEncodingDetector.Create;
  try
    Result := Detector.DetectBufferEncoding(Buffer);
  finally
    Detector.Free;
  end;
end;

function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
var
  Detector: TEncodingDetector;
begin
  Detector := TEncodingDetector.Create;
  try
    Result := Detector.DetectStreamEncoding(Stream);
  finally
    Detector.Free;
  end;
end;

{ TEncodingDetector }

constructor TEncodingDetector.Create;
begin
  inherited Create;
  FLogger := nil; // 实际使用时可以初始化为适当的日志对象
end;

destructor TEncodingDetector.Destroy;
begin
  // 清理资源
  inherited;
end;

function TEncodingDetector.DetectBOM(const Buffer: TBytes; out Encoding: TEncodingClass; out BOMSize: Integer): Boolean;
var
  BOM: TBOM;
begin
  BOM := UtilsEncodingTypes.DetectBOM(Buffer);
  if BOM.Encoding <> nil then
  begin
    Encoding := BOM.Encoding;
    BOMSize := Length(BOM.Bytes);
    Result := True;
  end
  else
  begin
    Encoding := nil;
    BOMSize := 0;
    Result := False;
  end;
end;

function TEncodingDetector.DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  Stats: TEncodingStats;
  ASCIIScore, UTF8Score, ChineseScore, JapaneseScore, KoreanScore, Big5Score: Double;
  EUCJP_Score, GB18030_Score, ISO8859_Score, Windows125x_Score, KOI8_Score: Double;
  MaxScore: Double;
  ScoreArray: array of Double;
  EncodingArray: array of TEncodingClass;
  NameArray: array of string;
  i, MaxIndex: Integer;
  ASCIIRatio: Double;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  // 检查是否为空
  if Length(Buffer) = 0 then
  begin
    Result.Encoding := TEncodingClass.GetEncoding(20127); // ASCII
    Result.Name := 'ASCII';
    Result.Confidence := 1.0;
    Exit;
  end;

  // 首先检测BOM
  if DetectBOM(Buffer, Result.Encoding, Result.BOMSize) then
  begin
    Result.HasBOM := True;
    Result.Name := GetEncodingName(Result.Encoding);
    Result.Confidence := 1.0;
    Exit;
  end;

  // 检测ASCII
  ASCIIScore := IsASCII(Buffer);
  ASCIIRatio := ASCIIScore; // 保存ASCII比例，用于后续分析

  if ASCIIScore > 0.99 then
  begin
    Result.Encoding := TEncodingClass.GetEncoding(20127); // ASCII
    Result.Name := 'ASCII';
    Result.Confidence := ASCIIScore;
    Exit;
  end;

  // 检测UTF-8（无BOM）
  UTF8Score := IsValidUTF8(Buffer, Stats);

  // 检测中文编码
  ChineseScore := IsChineseEncoding(Buffer);

  // 检测日文编码
  JapaneseScore := IsJapaneseEncoding(Buffer);

  // 检测韩文编码
  KoreanScore := IsKoreanEncoding(Buffer);

  // 检测Big5编码
  Big5Score := IsBig5Encoding(Buffer);

  // 检测其他编码
  EUCJP_Score := IsEUCJPEncoding(Buffer);
  GB18030_Score := IsGB18030Encoding(Buffer);
  ISO8859_Score := IsISO8859Encoding(Buffer);
  Windows125x_Score := IsWindows125xEncoding(Buffer);
  KOI8_Score := IsKOI8Encoding(Buffer);

  // 创建得分和编码数组
  SetLength(ScoreArray, 11);
  SetLength(EncodingArray, 11);
  SetLength(NameArray, 11);

  ScoreArray[0] := UTF8Score;
  EncodingArray[0] := TEncodingClass.GetEncoding(65001); // UTF-8
  NameArray[0] := 'UTF-8';

  ScoreArray[1] := GB18030_Score;
  EncodingArray[1] := TEncodingClass.GetEncoding(54936); // GB18030
  NameArray[1] := 'GB18030';

  ScoreArray[2] := ChineseScore;
  EncodingArray[2] := TEncodingClass.GetEncoding(936); // GBK
  NameArray[2] := 'GBK';

  ScoreArray[3] := JapaneseScore;
  EncodingArray[3] := TEncodingClass.GetEncoding(932); // Shift-JIS
  NameArray[3] := 'Shift-JIS';

  ScoreArray[4] := EUCJP_Score;
  EncodingArray[4] := TEncodingClass.GetEncoding(51932); // EUC-JP
  NameArray[4] := 'EUC-JP';

  ScoreArray[5] := KoreanScore;
  EncodingArray[5] := TEncodingClass.GetEncoding(949); // EUC-KR
  NameArray[5] := 'EUC-KR';

  ScoreArray[6] := Big5Score;
  EncodingArray[6] := TEncodingClass.GetEncoding(950); // Big5
  NameArray[6] := 'Big5';

  ScoreArray[7] := ISO8859_Score;
  EncodingArray[7] := TEncodingClass.GetEncoding(28591); // ISO-8859-1
  NameArray[7] := 'ISO-8859-1';

  ScoreArray[8] := Windows125x_Score;
  EncodingArray[8] := TEncodingClass.GetEncoding(1252); // Windows-1252
  NameArray[8] := 'Windows-1252';

  ScoreArray[9] := KOI8_Score;
  EncodingArray[9] := TEncodingClass.GetEncoding(20866); // KOI8-R
  NameArray[9] := 'KOI8-R';

  ScoreArray[10] := 0.5; // ANSI默认得分
  EncodingArray[10] := TEncodingClass.GetEncoding(0); // ANSI
  NameArray[10] := 'ANSI';

  // 找出得分最高的编码
  MaxScore := 0;
  MaxIndex := 10; // 默认为ANSI

  for i := 0 to High(ScoreArray) do
  begin
    if ScoreArray[i] > MaxScore then
    begin
      MaxScore := ScoreArray[i];
      MaxIndex := i;
    end;
  end;

  // 特殊处理：如果ASCII比例很高，但不是纯ASCII，优先考虑UTF-8
  if (ASCIIRatio > 0.9) and (ASCIIRatio < 0.99) and (UTF8Score > 0.7) then
  begin
    Result.Encoding := TEncodingClass.GetEncoding(65001); // UTF-8
    Result.Name := 'UTF-8';
    Result.Confidence := UTF8Score;
  end
  // 特殊处理：如果UTF-8得分接近但不是最高，且ASCII比例高，也优先考虑UTF-8
  else if (UTF8Score > 0.8) and (MaxScore - UTF8Score < 0.1) and (ASCIIRatio > 0.8) then
  begin
    Result.Encoding := TEncodingClass.GetEncoding(65001); // UTF-8
    Result.Name := 'UTF-8';
    Result.Confidence := UTF8Score;
  end
  // 特殊处理：如果最高得分不够高，且ASCII比例高，考虑使用ANSI
  else if (MaxScore < 0.7) and (ASCIIRatio > 0.9) then
  begin
    Result.Encoding := TEncodingClass.GetEncoding(0); // ANSI
    Result.Name := 'ANSI';
    Result.Confidence := 0.7;
  end
  // 一般情况：使用得分最高的编码
  else if MaxScore > 0.7 then
  begin
    Result.Encoding := EncodingArray[MaxIndex];
    Result.Name := NameArray[MaxIndex];
    Result.Confidence := MaxScore;
  end
  else
  begin
    // 如果所有得分都不够高，默认使用ANSI
    Result.Encoding := TEncodingClass.GetEncoding(0); // ANSI
    Result.Name := 'ANSI';
    Result.Confidence := 0.5;
  end;

  // 对于混合编码文件的特殊处理
  if (Result.Confidence < 0.8) and (UTF8Score > 0.6) and (ASCIIRatio > 0.7) then
  begin
    // 如果置信度不高，但UTF-8得分和ASCII比例都较高，可能是混合编码文件
    // 优先使用UTF-8，因为它对ASCII兼容
    Result.Encoding := TEncodingClass.GetEncoding(65001); // UTF-8
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.7);
  end;
end;

function TEncodingDetector.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  FileStream: TFileStream;
  Buffer, SmallBuffer, LargeBuffer: TBytes;
  SampleSize, FileSize: Integer;
  SmallResult, LargeResult: TEncodingDetectionResult;
  FileExt: string;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      FileSize := FileStream.Size;

      // 对于非常小的文件，读取整个文件
      if FileSize <= 4096 then
      begin
        SampleSize := FileSize;
        SetLength(Buffer, SampleSize);
        if SampleSize > 0 then
          FileStream.ReadBuffer(Buffer[0], SampleSize);

        // 使用缓冲区检测编码
        Result := DetectBufferEncoding(Buffer);

        // 对于小文件，考虑文件扩展名作为额外的提示
        FileExt := LowerCase(ExtractFileExt(FileName));
        if (FileExt = '.txt') and (Result.Confidence < 0.8) then
        begin
          // 文本文件更可能是ANSI或UTF-8
          if Result.Encoding = TEncodingClass.GetEncoding(0) then // ANSI
            Result.Confidence := Max(Result.Confidence, 0.7)
          else if Result.Encoding = TEncodingClass.GetEncoding(65001) then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.7);
        end
        else if (FileExt = '.xml') or (FileExt = '.html') or (FileExt = '.htm') then
        begin
          // XML和HTML文件更可能是UTF-8
          if Result.Encoding = TEncodingClass.GetEncoding(65001) then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.8);
        end;
      end
      else
      begin
        // 对于大文件，使用两种采样策略

        // 1. 读取文件开头的4KB
        SetLength(SmallBuffer, Min(FileSize, 4096));
        if Length(SmallBuffer) > 0 then
        begin
          FileStream.Position := 0;
          FileStream.ReadBuffer(SmallBuffer[0], Length(SmallBuffer));
        end;

        // 2. 读取文件的多个部分，总计最多128KB
        SampleSize := Min(FileSize, 131072); // 128KB
        SetLength(LargeBuffer, SampleSize);

        if SampleSize > 0 then
        begin
          // 读取文件开头、中间和结尾的部分
          if FileSize <= SampleSize then
          begin
            // 如果文件小于采样大小，直接读取整个文件
            FileStream.Position := 0;
            FileStream.ReadBuffer(LargeBuffer[0], FileSize);
          end
          else
          begin
            // 读取文件开头的1/3采样
            FileStream.Position := 0;
            FileStream.ReadBuffer(LargeBuffer[0], SampleSize div 3);

            // 读取文件中间的1/3采样
            FileStream.Position := (FileSize - SampleSize div 3) div 2;
            FileStream.ReadBuffer(LargeBuffer[SampleSize div 3], SampleSize div 3);

            // 读取文件结尾的1/3采样
            FileStream.Position := FileSize - SampleSize div 3;
            FileStream.ReadBuffer(LargeBuffer[2 * (SampleSize div 3)], SampleSize div 3);
          end;
        end;

        // 分别检测两个样本
        SmallResult := DetectBufferEncoding(SmallBuffer);
        LargeResult := DetectBufferEncoding(LargeBuffer);

        // 如果两个结果一致，使用大样本的结果
        if (SmallResult.Encoding = LargeResult.Encoding) then
        begin
          Result := LargeResult;
          // 提高置信度
          Result.Confidence := Min(1.0, Result.Confidence + 0.1);
        end
        else
        begin
          // 如果结果不一致，可能是混合编码文件
          // 优先使用大样本的结果，但降低置信度
          Result := LargeResult;
          Result.Confidence := Max(0.5, Result.Confidence - 0.2);

          // 如果小样本检测到BOM，优先使用小样本结果
          if SmallResult.HasBOM then
          begin
            Result := SmallResult;
            Result.Confidence := 1.0; // BOM是确定的标志
          end
          // 如果小样本是UTF-8且置信度高，也优先使用小样本
          else if (SmallResult.Encoding = TEncodingClass.GetEncoding(65001)) and (SmallResult.Confidence > 0.9) then
          begin
            Result := SmallResult;
          end;
        end;
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 出错时使用默认编码
      Result.Encoding := TEncodingClass.GetEncoding(0); // ANSI
      Result.Name := 'ANSI';
      Result.Confidence := 0;
    end;
  end;
end;

function TEncodingDetector.DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
var
  Buffer: TBytes;
  SampleSize: Integer;
  OriginalPosition: Int64;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  try
    // 保存原始位置
    OriginalPosition := Stream.Position;

    // 读取流样本
    SampleSize := Min(Stream.Size - Stream.Position, 65536); // 最多读取64KB
    SetLength(Buffer, SampleSize);
    Stream.ReadBuffer(Buffer[0], SampleSize);

    // 使用缓冲区检测编码
    Result := DetectBufferEncoding(Buffer);

    // 恢复原始位置
    Stream.Position := OriginalPosition;
  except
    on E: Exception do
    begin
      // 出错时使用默认编码
      Result.Encoding := TEncodingClass.GetEncoding(0); // ANSI
      Result.Name := 'ANSI';
      Result.Confidence := 0;
    end;
  end;
end;

function TEncodingDetector.GetEncodingName(Encoding: TEncodingClass): string;
begin
  if Encoding = nil then
    Result := 'Unknown'
  else if Encoding = TEncodingClass.GetEncoding(65001) then
    Result := 'UTF-8'
  else if Encoding = TEncodingClass.GetEncoding(1200) then
    Result := 'UTF-16LE'
  else if Encoding = TEncodingClass.GetEncoding(1201) then
    Result := 'UTF-16BE'
  else if Encoding = TEncodingClass.GetEncoding(12000) then
    Result := 'UTF-32LE'
  else if Encoding = TEncodingClass.GetEncoding(12001) then
    Result := 'UTF-32BE'
  else if Encoding = TEncodingClass.GetEncoding(20127) then
    Result := 'ASCII'
  else if Encoding = TEncodingClass.GetEncoding(0) then
    Result := 'ANSI'
  else if Encoding = TEncodingClass.GetEncoding(936) then
    Result := 'GBK'
  else if Encoding = TEncodingClass.GetEncoding(54936) then
    Result := 'GB18030'
  else if Encoding = TEncodingClass.GetEncoding(950) then
    Result := 'Big5'
  else if Encoding = TEncodingClass.GetEncoding(932) then
    Result := 'Shift-JIS'
  else if Encoding = TEncodingClass.GetEncoding(51932) then
    Result := 'EUC-JP'
  else if Encoding = TEncodingClass.GetEncoding(949) then
    Result := 'EUC-KR'
  else if Encoding = TEncodingClass.GetEncoding(28591) then
    Result := 'ISO-8859-1'
  else if Encoding = TEncodingClass.GetEncoding(1252) then
    Result := 'Windows-1252'
  else if Encoding = TEncodingClass.GetEncoding(20866) then
    Result := 'KOI8-R'
  else
    Result := 'Unknown';
end;

// 以下是各种编码检测方法的实现
// 这些方法将在后续步骤中实现

function TEncodingDetector.IsASCII(const Buffer: TBytes): Double;
var
  I, Count, ASCIICount: Integer;
begin
  Count := Length(Buffer);
  if Count = 0 then
  begin
    Result := 0;
    Exit;
  end;

  ASCIICount := 0;
  for I := 0 to Count - 1 do
    if Buffer[I] < $80 then
      Inc(ASCIICount);

  Result := ASCIICount / Count;
end;

function TEncodingDetector.IsBig5Encoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, InvalidBytes: Integer;
  FirstByte, SecondByte: Byte;
  IsValidBig5: Boolean;
  ChineseCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  InvalidBytes := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成双字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的Big5编码
    // Big5: 首字节 $A1-$F9，次字节 $40-$7E 或 $A1-$FE
    IsValidBig5 := (FirstByte >= $A1) and (FirstByte <= $F9) and
                  (((SecondByte >= $40) and (SecondByte <= $7E)) or
                   ((SecondByte >= $A1) and (SecondByte <= $FE)));

    if IsValidBig5 then
    begin
      Inc(ValidPairs);
      Inc(ChineseCharCount);
      Inc(I, 2);
    end
    else
    begin
      Inc(InvalidBytes);
      Inc(I);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的中文字符，增加置信度
  if ChineseCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果中文字符比例合适，增加置信度
  if (Count > 20) and (ChineseCharCount > 0) then
  begin
    var ChineseRatio := ChineseCharCount / ((Count - ASCIICount) / 2);
    if ChineseRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsChineseEncoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, InvalidBytes: Integer;
  FirstByte, SecondByte: Byte;
  IsValidGBK: Boolean;
  ChineseCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  InvalidBytes := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成双字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的GBK编码
    // GBK: 首字节 $81-$FE，次字节 $40-$FE (不包括 $7F)
    IsValidGBK := (FirstByte >= $81) and (FirstByte <= $FE) and
                  (SecondByte >= $40) and (SecondByte <= $FE) and
                  (SecondByte <> $7F);

    if IsValidGBK then
    begin
      Inc(ValidPairs);
      Inc(ChineseCharCount);
      Inc(I, 2);
    end
    else
    begin
      Inc(InvalidBytes);
      Inc(I);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的中文字符，增加置信度
  if ChineseCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果中文字符比例合适，增加置信度
  if (Count > 20) and (ChineseCharCount > 0) then
  begin
    var ChineseRatio := ChineseCharCount / ((Count - ASCIICount) / 2);
    if ChineseRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsEUCJPEncoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, InvalidBytes: Integer;
  FirstByte, SecondByte, ThirdByte: Byte;
  IsValidEUCJP: Boolean;
  JapaneseCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  InvalidBytes := 0;
  JapaneseCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成多字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的EUC-JP编码
    // EUC-JP: 基本集 首字节 $A1-$FE，次字节 $A1-$FE
    if (FirstByte >= $A1) and (FirstByte <= $FE) and
       (SecondByte >= $A1) and (SecondByte <= $FE) then
    begin
      IsValidEUCJP := True;
      Inc(ValidPairs);
      Inc(JapaneseCharCount);
      Inc(I, 2);
      Continue;
    end;

    // 检查半角片假名 (SS2 + 1字节)
    if (FirstByte = $8E) and (I + 1 < Count) then
    begin
      if (SecondByte >= $A1) and (SecondByte <= $DF) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(I, 2);
        Continue;
      end;
    end;

    // 检查JIS X 0212-1990 (SS3 + 2字节)
    if (FirstByte = $8F) and (I + 2 < Count) then
    begin
      ThirdByte := Buffer[I + 2];
      if (SecondByte >= $A1) and (SecondByte <= $FE) and
         (ThirdByte >= $A1) and (ThirdByte <= $FE) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(I, 3);
        Continue;
      end;
    end;

    // 如果不是有效的EUC-JP序列
    Inc(InvalidBytes);
    Inc(I);
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的日文字符，增加置信度
  if JapaneseCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果日文字符比例合适，增加置信度
  if (Count > 20) and (JapaneseCharCount > 0) then
  begin
    var JapaneseRatio := JapaneseCharCount / ((Count - ASCIICount) / 2);
    if JapaneseRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsGB18030Encoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, ValidQuads, InvalidBytes: Integer;
  FirstByte, SecondByte, ThirdByte, FourthByte: Byte;
  ChineseCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  ValidQuads := 0;
  InvalidBytes := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成多字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的GB18030双字节序列
    // GB18030: 双字节 首字节 $81-$FE，次字节 $40-$FE (不包括 $7F)
    if (FirstByte >= $81) and (FirstByte <= $FE) and
       (SecondByte >= $40) and (SecondByte <= $FE) and (SecondByte <> $7F) then
    begin
      Inc(ValidPairs);
      Inc(ChineseCharCount);
      Inc(I, 2);
      Continue;
    end;

    // 检查是否是有效的GB18030四字节序列
    // GB18030: 四字节 首字节 $81-$FE，次字节 $30-$39，第三字节 $81-$FE，第四字节 $30-$39
    if (I + 3 < Count) and
       (FirstByte >= $81) and (FirstByte <= $FE) and
       (SecondByte >= $30) and (SecondByte <= $39) then
    begin
      ThirdByte := Buffer[I + 2];
      FourthByte := Buffer[I + 3];

      if (ThirdByte >= $81) and (ThirdByte <= $FE) and
         (FourthByte >= $30) and (FourthByte <= $39) then
      begin
        Inc(ValidQuads);
        Inc(ChineseCharCount);
        Inc(I, 4);
        Continue;
      end;
    end;

    // 如果不是有效的GB18030序列
    Inc(InvalidBytes);
    Inc(I);
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + ValidQuads * 4 + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的中文字符，增加置信度
  if ChineseCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果中文字符比例合适，增加置信度
  if (Count > 20) and (ChineseCharCount > 0) then
  begin
    var ChineseRatio := ChineseCharCount / ((Count - ASCIICount) / 2.5);
    if ChineseRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 4. 如果有四字节序列，增加置信度（这是GB18030的特点）
  if ValidQuads > 0 then
    Confidence := Confidence * 1.3;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsISO8859Encoding(const Buffer: TBytes): Double;
var
  I, Count, ExtendedASCIICount, ASCIICount, InvalidBytes: Integer;
  Byte1: Byte;
  Confidence: Double;
  LatinCharCount: Integer;
  ControlCharCount: Integer;
begin
  Count := Length(Buffer);
  if Count = 0 then
  begin
    Result := 0;
    Exit;
  end;

  ExtendedASCIICount := 0;
  ASCIICount := 0;
  InvalidBytes := 0;
  LatinCharCount := 0;
  ControlCharCount := 0;

  for I := 0 to Count - 1 do
  begin
    Byte1 := Buffer[I];

    // ASCII字符
    if Byte1 < $80 then
    begin
      Inc(ASCIICount);

      // 控制字符 (除了常见的制表符、换行符和回车符)
      if (Byte1 < $20) and (Byte1 <> 9) and (Byte1 <> 10) and (Byte1 <> 13) then
        Inc(ControlCharCount);

      Continue;
    end;

    // ISO-8859系列的扩展ASCII部分 ($80-$FF)
    if (Byte1 >= $A0) and (Byte1 <= $FF) then
    begin
      Inc(ExtendedASCIICount);
      Inc(LatinCharCount);
    end
    // 控制字符区域 ($80-$9F) - 在ISO-8859中不应该出现
    else if (Byte1 >= $80) and (Byte1 <= $9F) then
    begin
      Inc(InvalidBytes);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ASCIICount + ExtendedASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度

  // 1. 如果有大量的扩展ASCII字符，增加置信度
  if ExtendedASCIICount > 10 then
    Confidence := Confidence * 1.1;

  // 2. 如果扩展ASCII字符比例合适，增加置信度
  if (Count > 20) and (ExtendedASCIICount > 0) then
  begin
    var ExtendedRatio := ExtendedASCIICount / (Count - ASCIICount);
    if ExtendedRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.5) and (ASCIIRatio < 0.98) then
      Confidence := Confidence * 1.1;
  end;

  // 4. 如果没有无效字节，增加置信度
  if InvalidBytes = 0 then
    Confidence := Confidence * 1.1;

  // 5. 如果控制字符很少，增加置信度
  if (ControlCharCount = 0) or ((Count > 20) and (ControlCharCount / Count < 0.01)) then
    Confidence := Confidence * 1.1;

  // 6. 如果是纯ASCII，降低置信度（因为这可能是任何编码）
  if (ASCIICount = Count) and (Count > 10) then
    Confidence := Confidence * 0.8;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsJapaneseEncoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, InvalidBytes: Integer;
  FirstByte, SecondByte: Byte;
  IsValidShiftJIS: Boolean;
  JapaneseCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  InvalidBytes := 0;
  JapaneseCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成双字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的Shift-JIS编码
    // Shift-JIS: 首字节 $81-$9F 或 $E0-$FC，次字节 $40-$FC (不包括 $7F)
    IsValidShiftJIS := ((FirstByte >= $81) and (FirstByte <= $9F) or
                        (FirstByte >= $E0) and (FirstByte <= $FC)) and
                        (SecondByte >= $40) and (SecondByte <= $FC) and
                        (SecondByte <> $7F);

    // 检查半角片假名区域 (Shift-JIS: $A1-$DF)
    if (FirstByte >= $A1) and (FirstByte <= $DF) then
    begin
      Inc(JapaneseCharCount);
      Inc(I);
      Continue;
    end;

    if IsValidShiftJIS then
    begin
      Inc(ValidPairs);
      Inc(JapaneseCharCount);
      Inc(I, 2);
    end
    else
    begin
      Inc(InvalidBytes);
      Inc(I);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + JapaneseCharCount + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的日文字符，增加置信度
  if JapaneseCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果日文字符比例合适，增加置信度
  if (Count > 20) and (JapaneseCharCount > 0) then
  begin
    var JapaneseRatio := JapaneseCharCount / ((Count - ASCIICount) / 1.5);
    if JapaneseRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsKOI8Encoding(const Buffer: TBytes): Double;
var
  I, Count, ExtendedASCIICount, ASCIICount: Integer;
  Byte1: Byte;
  Confidence: Double;
  CyrillicCharCount, ControlCharCount: Integer;
  // KOI8-R 中常见的字符
  KOI8RChars: array of Byte;
begin
  Count := Length(Buffer);
  if Count = 0 then
  begin
    Result := 0;
    Exit;
  end;

  // 初始化 KOI8-R 中常见的字符
  KOI8RChars := [$B3, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF,
                 $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF,
                 $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF];

  ExtendedASCIICount := 0;
  ASCIICount := 0;
  CyrillicCharCount := 0;
  ControlCharCount := 0;

  for I := 0 to Count - 1 do
  begin
    Byte1 := Buffer[I];

    // ASCII字符
    if Byte1 < $80 then
    begin
      Inc(ASCIICount);

      // 控制字符 (除了常见的制表符、换行符和回车符)
      if (Byte1 < $20) and (Byte1 <> 9) and (Byte1 <> 10) and (Byte1 <> 13) then
        Inc(ControlCharCount);

      Continue;
    end;

    // KOI8系列的扩展ASCII部分 ($80-$FF)
    if (Byte1 >= $80) and (Byte1 <= $FF) then
    begin
      Inc(ExtendedASCIICount);

      // 检查是否是KOI8-R中常见的西里尔字符
      for var J := 0 to High(KOI8RChars) do
        if Byte1 = KOI8RChars[J] then
        begin
          Inc(CyrillicCharCount);
          Break;
        end;
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ASCIICount + ExtendedASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度

  // 1. 如果有大量的西里尔字符，增加置信度
  if CyrillicCharCount > 10 then
    Confidence := Confidence * 1.3;

  // 2. 如果西里尔字符比例合适，增加置信度
  if (Count > 20) and (ExtendedASCIICount > 0) then
  begin
    var CyrillicRatio := CyrillicCharCount / ExtendedASCIICount;
    if CyrillicRatio > 0.5 then
      Confidence := Confidence * 1.2;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.5) and (ASCIIRatio < 0.98) then
      Confidence := Confidence * 1.1;
  end;

  // 4. 如果控制字符很少，增加置信度
  if (ControlCharCount = 0) or ((Count > 20) and (ControlCharCount / Count < 0.01)) then
    Confidence := Confidence * 1.1;

  // 5. 如果是纯ASCII，降低置信度（因为这可能是任何编码）
  if (ASCIICount = Count) and (Count > 10) then
    Confidence := Confidence * 0.8;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsKoreanEncoding(const Buffer: TBytes): Double;
var
  I, Count, ValidPairs, InvalidBytes: Integer;
  FirstByte, SecondByte: Byte;
  IsValidEUCKR: Boolean;
  KoreanCharCount, ASCIICount: Integer;
  Confidence: Double;
begin
  Count := Length(Buffer);
  if Count < 2 then
  begin
    Result := 0;
    Exit;
  end;

  ValidPairs := 0;
  InvalidBytes := 0;
  KoreanCharCount := 0;
  ASCIICount := 0;

  I := 0;
  while I < Count do
  begin
    FirstByte := Buffer[I];

    // ASCII字符
    if FirstByte < $80 then
    begin
      Inc(ASCIICount);
      Inc(I);
      Continue;
    end;

    // 检查是否有足够的字节来完成双字节序列
    if I + 1 >= Count then
    begin
      Inc(InvalidBytes);
      Inc(I);
      Continue;
    end;

    // 获取第二个字节
    SecondByte := Buffer[I + 1];

    // 检查是否是有效的EUC-KR编码
    // EUC-KR: 首字节 $A1-$FE，次字节 $A1-$FE
    IsValidEUCKR := (FirstByte >= $A1) and (FirstByte <= $FE) and
                    (SecondByte >= $A1) and (SecondByte <= $FE);

    // 检查KS X 1001扩展区域
    if (FirstByte >= $81) and (FirstByte <= $C8) and
       (SecondByte >= $41) and (SecondByte <= $FE) and (SecondByte <> $7F) then
    begin
      Inc(ValidPairs);
      Inc(KoreanCharCount);
      Inc(I, 2);
      Continue;
    end;

    if IsValidEUCKR then
    begin
      Inc(ValidPairs);
      Inc(KoreanCharCount);
      Inc(I, 2);
    end
    else
    begin
      Inc(InvalidBytes);
      Inc(I);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ValidPairs * 2 + ASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度
  // 1. 如果有大量的韩文字符，增加置信度
  if KoreanCharCount > 10 then
    Confidence := Confidence * 1.2;

  // 2. 如果韩文字符比例合适，增加置信度
  if (Count > 20) and (KoreanCharCount > 0) then
  begin
    var KoreanRatio := KoreanCharCount / ((Count - ASCIICount) / 2);
    if KoreanRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.1) and (ASCIIRatio < 0.9) then
      Confidence := Confidence * 1.1;
  end;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

function TEncodingDetector.IsValidUTF8(const Buffer: TBytes; var Stats: TEncodingStats): Double;
var
  I, Count: Integer;
  Len, BytesInSequence: Integer;
  ValidBytes, InvalidBytes: Integer;
  ValidSequences, InvalidSequences: Integer;
  SequenceStart: Integer;
  ASCIICount, NonASCIICount: Integer;
  UTF8ContinuationCount: Integer;
  ControlChars, ExtendedLatinChars, NonLatinChars: Integer;
  ExpectedContinuationBytes: Integer;
  ContinuationBytesFound: Integer;
  IsValidSequence: Boolean;
  LocalConfidence: Double;
  MaxConfidence: Double;
  CodePoint: Cardinal;
  StopWatch: TStopwatch;
  LastValidSequence, ContinuousSequences: Integer;
  ByteSequenceTypes: TDictionary<Integer, Integer>;
  TotalCodePoints: Integer;
begin
  // 初始化计时器
  StopWatch := TStopwatch.StartNew;

  // 初始化统计数据
  Count := Length(Buffer);
  ValidBytes := 0;
  InvalidBytes := 0;
  ValidSequences := 0;
  InvalidSequences := 0;
  ASCIICount := 0;
  NonASCIICount := 0;
  UTF8ContinuationCount := 0;
  ControlChars := 0;
  ExtendedLatinChars := 0;
  NonLatinChars := 0;
  LocalConfidence := 0;
  MaxConfidence := 0;
  LastValidSequence := -1;
  ContinuousSequences := 0;
  TotalCodePoints := 0;

  // 创建字节序列类型字典，用于统计各种长度的UTF-8序列数量
  ByteSequenceTypes := TDictionary<Integer, Integer>.Create;
  ByteSequenceTypes.Add(1, 0); // 1字节序列 (ASCII)
  ByteSequenceTypes.Add(2, 0); // 2字节序列
  ByteSequenceTypes.Add(3, 0); // 3字节序列
  ByteSequenceTypes.Add(4, 0); // 4字节序列

  I := 0;
  while I < Count do
  begin
    SequenceStart := I;
    IsValidSequence := False;
    BytesInSequence := 0;
    CodePoint := 0;

    // 处理ASCII字符 (0xxxxxxx)
    if (Buffer[I] and $80) = 0 then
    begin
      // 这是一个ASCII字符
      Inc(ASCIICount);
      CodePoint := Buffer[I];
      BytesInSequence := 1;
      IsValidSequence := True;

      // 控制字符检查
      if (CodePoint < $20) and (CodePoint <> 9) and (CodePoint <> 10) and (CodePoint <> 13) then
        Inc(ControlChars);

      // 增加此类型序列的计数
      ByteSequenceTypes[1] := ByteSequenceTypes[1] + 1;
    end
    else
    begin
      // 这是一个非ASCII字符
      Inc(NonASCIICount);

      // 检查首字节，确定这个UTF-8序列应该有多少字节
      if ((Buffer[I] and $E0) = $C0) then         // 110xxxxx - 2字节序列
      begin
        ExpectedContinuationBytes := 1;
        CodePoint := Buffer[I] and $1F;
      end
      else if ((Buffer[I] and $F0) = $E0) then    // 1110xxxx - 3字节序列
      begin
        ExpectedContinuationBytes := 2;
        CodePoint := Buffer[I] and $0F;
      end
      else if ((Buffer[I] and $F8) = $F0) then    // 11110xxx - 4字节序列
      begin
        ExpectedContinuationBytes := 3;
        CodePoint := Buffer[I] and $07;
      end
      else
      begin
        // 无效的首字节
        ExpectedContinuationBytes := 0;
        IsValidSequence := False;
      end;

      // 如果这是一个有效的首字节，则检查后续字节
      if ExpectedContinuationBytes > 0 then
      begin
        // 检查是否有足够的字节来完成这个序列
        if I + ExpectedContinuationBytes < Count then
        begin
          ContinuationBytesFound := 0;
          IsValidSequence := True;

          // 验证每个后续字节
          for Len := 1 to ExpectedContinuationBytes do
          begin
            if ((Buffer[I + Len] and $C0) = $80) then  // 10xxxxxx - 后续字节
            begin
              Inc(ContinuationBytesFound);
              Inc(UTF8ContinuationCount);

              // 累积代码点值
              CodePoint := (CodePoint shl 6) or (Buffer[I + Len] and $3F);
            end
            else
            begin
              // 发现无效的后续字节
              IsValidSequence := False;
              Break;
            end;
          end;

          // 确认找到了正确数量的后续字节
          IsValidSequence := IsValidSequence and (ContinuationBytesFound = ExpectedContinuationBytes);

          // 检查代码点的有效性
          if IsValidSequence then
          begin
            BytesInSequence := 1 + ExpectedContinuationBytes;

            // UTF-8编码过长检测
            // 检查序列的最小字节数要求
            var MinBytesRequired := 1;
            if CodePoint >= $80 then MinBytesRequired := 2;
            if CodePoint >= $800 then MinBytesRequired := 3;
            if CodePoint >= $10000 then MinBytesRequired := 4;

            // 如果使用了比必要更多的字节，标记为无效
            if BytesInSequence > MinBytesRequired then
              IsValidSequence := False;

            // 检查是否是代理对范围 (U+D800-U+DFFF) - 这在UTF-8中是不允许的
            if (CodePoint >= $D800) and (CodePoint <= $DFFF) then
              IsValidSequence := False;

            // 检查超出Unicode范围的值 (> U+10FFFF)
            if CodePoint > $10FFFF then
              IsValidSequence := False;

            // 如果是2字节序列，字符应该大于127
            if (BytesInSequence = 2) and (CodePoint <= $7F) then
              IsValidSequence := False;

            // 如果是3字节序列，字符应该大于2047
            if (BytesInSequence = 3) and (CodePoint <= $7FF) then
              IsValidSequence := False;

            // 分析字符类型
            if (CodePoint <= $007F) then
              // ASCII范围 - 已经计数过了
              CodePoint := CodePoint  // 空操作，保持编译器满意
            else if (CodePoint <= $00FF) then
              Inc(ExtendedLatinChars)
            else
              Inc(NonLatinChars);

            // 检测序列的连续性
            if LastValidSequence >= 0 then
              if SequenceStart = LastValidSequence + BytesInSequence then
                Inc(ContinuousSequences);

            // 增加此类型序列的计数
            if ByteSequenceTypes.ContainsKey(BytesInSequence) then
              ByteSequenceTypes[BytesInSequence] := ByteSequenceTypes[BytesInSequence] + 1;
          end;
        end
        else
        begin
          // 缓冲区结束，无法完成序列
          IsValidSequence := False;
        end;
      end;
    end;

    // 根据序列验证结果更新统计数据
    if IsValidSequence then
    begin
      Inc(ValidSequences);
      Inc(ValidBytes, BytesInSequence);
      Inc(TotalCodePoints);
      I := I + BytesInSequence;
      LastValidSequence := SequenceStart;
    end
    else
    begin
      Inc(InvalidSequences);
      Inc(InvalidBytes);
      Inc(I);
    end;
  end;

  // 计算基础置信度分数
  if Count > 0 then
    Result := ValidBytes / Count
  else
    Result := 0;

  // ======== 增强型置信度评分 ========

  // 1. ASCII比例分析 - UTF-8文本通常有一定比例的ASCII
  var ASCIIBonus := 0.0;
  if Count > 10 then
  begin
    var ASCIIRatio := ASCIICount / Count;

    // 典型的UTF-8文本有一定比例的ASCII
    if (ASCIIRatio >= 0.15) and (ASCIIRatio <= 0.95) then
      ASCIIBonus := 0.1
    else if (ASCIIRatio > 0) and (ASCIIRatio < 0.15) then
      ASCIIBonus := 0.05;

    // 过高比例的ASCII也可能是英文ASCII文本
    if ASCIIRatio > 0.98 then
      ASCIIBonus := -0.1;
  end;

  // 2. 后续字节比例分析 - 检测后续字节与非ASCII字节的比例是否合理
  var ContinuationBonus := 0.0;
  if NonASCIICount > 0 then
  begin
    var ExpectedRatio := UTF8ContinuationCount / NonASCIICount;

    // 对于合法的UTF-8，后续字节应该占非ASCII字节的大约2/3
    // (考虑到混合了2、3、4字节序列)
    if (ExpectedRatio >= 0.6) and (ExpectedRatio <= 0.9) then
      ContinuationBonus := 0.15;
  end;

  // 3. 序列长度分布分析
  var DistributionBonus := 0.0;
  if TotalCodePoints > 0 then
  begin
    // 检查序列类型的分布
    var HasReasonableDistribution :=
      (ByteSequenceTypes[1] > 0) and  // 有一些ASCII
      (
        (ByteSequenceTypes[2] > 0) or  // 有一些2字节序列
        (ByteSequenceTypes[3] > 0)     // 或有一些3字节序列
      );

    // 如果分布合理，增加置信度
    if HasReasonableDistribution then
      DistributionBonus := 0.1;

    // 检查是否主要是中文或其他CJK文本 (3字节序列为主)
    var ThreeByteRatio := 0.0;
    if TotalCodePoints > 0 then
      ThreeByteRatio := ByteSequenceTypes[3] / TotalCodePoints;

    if (ThreeByteRatio > 0.5) and (ByteSequenceTypes[1] > 0) then
      DistributionBonus := DistributionBonus + 0.05;
  end;

  // 4. 字符类型分析 - 检查文本是否包含多种类型的字符
  var CharTypeBonus := 0.0;
  if TotalCodePoints > 0 then
  begin
    // 计算扩展拉丁字符和非拉丁字符的比例
    var ExtendedLatinRatio := ExtendedLatinChars / TotalCodePoints;
    var NonLatinRatio := NonLatinChars / TotalCodePoints;

    // 奖励多语言文本 (混合了ASCII、扩展拉丁和非拉丁字符)
    if (ASCIICount > 0) and (ExtendedLatinRatio > 0) and (NonLatinRatio > 0) then
      CharTypeBonus := 0.1
    // 或者主要是非拉丁文本但包含一些ASCII
    else if (NonLatinRatio > 0.6) and (ASCIICount > 0) then
      CharTypeBonus := 0.1;
  end;

  // 5. 连续性分析 - UTF-8序列通常是连续的
  var ContinuityBonus := 0.0;
  if ValidSequences > 5 then
  begin
    var ContinuityRatio := ContinuousSequences / (ValidSequences - 1);
    if ContinuityRatio > 0.8 then
      ContinuityBonus := 0.1
    else if ContinuityRatio > 0.5 then
      ContinuityBonus := 0.05;
  end;

  // 6. 控制字符分析 - 文本通常不包含太多控制字符
  var ControlCharPenalty := 0.0;
  if TotalCodePoints > 10 then
  begin
    var ControlRatio := ControlChars / TotalCodePoints;
    if ControlRatio > 0.1 then
      ControlCharPenalty := Min(0.2, ControlRatio);
  end;

  // 7. 无效序列惩罚
  var InvalidPenalty := 0.0;
  if Count > 0 then
  begin
    var InvalidRatio := InvalidBytes / Count;
    if InvalidRatio > 0.2 then
      InvalidPenalty := Min(0.4, InvalidRatio)
    else if InvalidRatio > 0.05 then
      InvalidPenalty := 0.1;
  end;

  // 应用所有加分和惩罚到基础置信度
  Result := Result * (1.0 + ASCIIBonus + ContinuationBonus + DistributionBonus +
                           CharTypeBonus + ContinuityBonus -
                           ControlCharPenalty - InvalidPenalty);

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Result));

  // 填充统计信息
  Stats.TotalBytes := Count;
  Stats.ASCIIBytes := ASCIICount;
  Stats.ValidBytes := ValidBytes;
  Stats.InvalidBytes := InvalidBytes;

  // 记录序列类型分布
  Stats.SequenceTypes := TDictionary<String, Integer>.Create;
  for var Pair in ByteSequenceTypes do
    Stats.SequenceTypes.Add(Pair.Key.ToString + '-byte', Pair.Value);

  // 记录处理时间
  StopWatch.Stop;
  Stats.ProcessingTime := StopWatch.ElapsedMilliseconds;

  // 清理
  ByteSequenceTypes.Free;
end;

function TEncodingDetector.IsWindows125xEncoding(const Buffer: TBytes): Double;
var
  I, Count, ExtendedASCIICount, ASCIICount: Integer;
  Byte1: Byte;
  Confidence: Double;
  LatinCharCount, ControlCharCount: Integer;
begin
  Count := Length(Buffer);
  if Count = 0 then
  begin
    Result := 0;
    Exit;
  end;

  ExtendedASCIICount := 0;
  ASCIICount := 0;
  LatinCharCount := 0;
  ControlCharCount := 0;

  for I := 0 to Count - 1 do
  begin
    Byte1 := Buffer[I];

    // ASCII字符
    if Byte1 < $80 then
    begin
      Inc(ASCIICount);

      // 控制字符 (除了常见的制表符、换行符和回车符)
      if (Byte1 < $20) and (Byte1 <> 9) and (Byte1 <> 10) and (Byte1 <> 13) then
        Inc(ControlCharCount);

      Continue;
    end;

    // Windows-125x系列的扩展ASCII部分 ($80-$FF)
    // 注意：Windows-125x系列使用了$80-$9F区域，这是与ISO-8859系列的主要区别
    if (Byte1 >= $80) and (Byte1 <= $FF) then
    begin
      Inc(ExtendedASCIICount);

      // 特别关注Windows-125x系列常用的字符区域
      if (Byte1 >= $C0) and (Byte1 <= $FF) then
        Inc(LatinCharCount);
    end;
  end;

  // 计算基础置信度
  if Count > 0 then
    Confidence := (ASCIICount + ExtendedASCIICount) / Count
  else
    Confidence := 0;

  // 调整置信度

  // 1. 如果有大量的扩展ASCII字符，增加置信度
  if ExtendedASCIICount > 10 then
    Confidence := Confidence * 1.1;

  // 2. 如果扩展ASCII字符比例合适，增加置信度
  if (Count > 20) and (ExtendedASCIICount > 0) then
  begin
    var ExtendedRatio := ExtendedASCIICount / (Count - ASCIICount);
    if ExtendedRatio > 0.7 then
      Confidence := Confidence * 1.1;
  end;

  // 3. 如果ASCII字符比例合适，增加置信度
  if Count > 20 then
  begin
    var ASCIIRatio := ASCIICount / Count;
    if (ASCIIRatio > 0.5) and (ASCIIRatio < 0.98) then
      Confidence := Confidence * 1.1;
  end;

  // 4. 如果控制字符很少，增加置信度
  if (ControlCharCount = 0) or ((Count > 20) and (ControlCharCount / Count < 0.01)) then
    Confidence := Confidence * 1.1;

  // 5. 如果是纯ASCII，降低置信度（因为这可能是任何编码）
  if (ASCIICount = Count) and (Count > 10) then
    Confidence := Confidence * 0.8;

  // 6. 如果有$80-$9F区域的字符，增加Windows-125x的置信度
  var ControlAreaCount := 0;
  for I := 0 to Count - 1 do
    if (Buffer[I] >= $80) and (Buffer[I] <= $9F) then
      Inc(ControlAreaCount);

  if ControlAreaCount > 0 then
    Confidence := Confidence * 1.2;

  // 确保结果在0-1之间
  Result := Max(0.0, Min(1.0, Confidence));
end;

end.
