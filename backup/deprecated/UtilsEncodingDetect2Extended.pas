unit UtilsEncodingDetect2Extended;

interface

uses
  System.SysUtils, System.Classes, System.Math, UtilsEncodingTypes, UtilsEncodingDetect2;

// 返回扩展的支持编码列表（包含HZ-GB-2312）
function GetSupportedEncodingsExtended: TArray<string>;

// 扩展的编码检测函数，增加了对HZ-GB-2312的支持
function DetectBufferEncodingExtended(const Buffer: TBytes): TEncodingDetectionInfo;

implementation

const
  ENCODING_HZ_GB_2312 = 'HZ-GB-2312';

function GetSupportedEncodingsExtended: TArray<string>;
var
  BaseEncodings: TArray<string>;
  I: Integer;
begin
  // 获取基本编码列表
  BaseEncodings := TEncodingDetector2.GetSupportedEncodings;
  
  // 创建包含一个额外空间的新数组
  SetLength(Result, Length(BaseEncodings) + 1);
  
  // 复制基本编码
  for I := 0 to Length(BaseEncodings) - 1 do
    Result[I] := BaseEncodings[I];
    
  // 添加HZ-GB-2312编码
  Result[Length(Result) - 1] := ENCODING_HZ_GB_2312;
end;

// 这个函数是UtilsEncodingDetect2.pas中的DetectBufferEncoding函数的扩展版本
// 它添加了对HZ-GB-2312编码的检测
function DetectBufferEncodingExtended(const Buffer: TBytes): TEncodingDetectionInfo;
var
  DetectionInfo: TEncodingDetectionInfo;
  Confidence: Double;
  Detector: TEncodingDetector2;
begin
  Result := TEncodingDetectionInfo.Create(ENCODING_UNKNOWN);
  Detector := TEncodingDetector2.Create;
  try
    // 首先检查BOM
    if Detector.DetectBOM(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查是否是ASCII
    if Detector.IsASCII(Buffer, Confidence) then
    begin
      Result.EncodingName := ENCODING_ASCII;
      Result.Confidence := Confidence;
      Result.CodePage := 20127;
      Result.Description := 'ASCII (7-bit)';
      Exit;
    end;

    // 检查是否是UTF-8
    if Detector.IsValidUTF8(Buffer, Confidence) then
    begin
      Result.EncodingName := ENCODING_UTF8;
      Result.Confidence := Confidence;
      Result.CodePage := 65001;
      Result.Description := 'UTF-8 without BOM';
      Exit;
    end;

    // 检查中文编码
    if Detector.IsChineseEncoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查日语编码
    if Detector.IsJapaneseEncoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查韩语编码
    if Detector.IsKoreanEncoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查Big5编码
    if Detector.IsBig5Encoding(Buffer, Confidence) then
    begin
      Result.EncodingName := ENCODING_BIG5;
      Result.Confidence := Confidence;
      Result.CodePage := 950;
      Result.Description := 'Big5 (繁体中文)';
      Exit;
    end;

    // 检查Windows代码页编码
    if Detector.IsWindows125xEncoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查ISO-8859编码
    if Detector.IsISO8859Encoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查KOI8编码
    if Detector.IsKOI8Encoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查UTF-32编码
    if Detector.IsUTF32Encoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 检查HZ-GB-2312编码
    if Detector.IsHZGB2312Encoding(Buffer, DetectionInfo) then
    begin
      Result := DetectionInfo;
      Exit;
    end;

    // 如果所有检测都失败，返回默认编码（ASCII）但置信度很低
    Result.EncodingName := ENCODING_ASCII;
    Result.Confidence := 0.1;
    Result.CodePage := 20127;
    Result.Description := '未能确定编码，默认使用ASCII';
    
    Detector.Log(Format('编码检测结果: %s (置信度: %.2f)', [Result.Description, Result.Confidence]));
  finally
    Detector.Free;
  end;
end;

end. 