unit ConversionReportGenerator;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.DateUtils, System.IOUtils, System.SyncObjs,
  ModelEncoding;

type
  { 转换结果状态 }
  TConversionStatus = (csSuccess, csWarning, csError, csSkipped, csCancelled);
  
  { 转换结果项记录 }
  TConversionResultItem = record
    FilePath: string;
    OriginalEncoding: string;
    NewEncoding: string;
    FileSize: Int64;
    ProcessingTime: TDateTime;
    Status: TConversionStatus;
    ErrorMessage: string;
    
    constructor Create(const AFilePath: string; const AOriginalEncoding, ANewEncoding: string;
      AFileSize: Int64; AProcessingTime: TDateTime; AStatus: TConversionStatus;
      const AErrorMessage: string = '');
    function ToJSON: TJSONObject;
    function ToCsv: string;
    function ToText: string;
  end;
  
  { 转换结果摘要记录 }
  TConversionSummary = record
    TotalFiles: Integer;
    SuccessfulFiles: Integer;
    WarningFiles: Integer;
    ErrorFiles: Integer;
    SkippedFiles: Integer;
    CancelledFiles: Integer;
    TotalSize: Int64;
    StartTime: TDateTime;
    EndTime: TDateTime;
    
    constructor Create;
    function ElapsedTimeInSeconds: Double;
    function AverageSpeed: Double; // 字节/秒
    function ToJSON: TJSONObject;
    function ToCsv: string;
    function ToText: string;
  end;
  
  { 报告类型 }
  TReportFormat = (rfText, rfHTML, rfCSV, rfJSON, rfXML);
  
  { 报告生成器接口 }
  IReportGenerator = interface
    ['{D5A7F23C-B8E3-4E6D-B512-12E63A4C87F9}']
    procedure AddResult(const ResultItem: TConversionResultItem);
    procedure SetSummary(const Summary: TConversionSummary);
    procedure GenerateReport(const FilePath: string; Format: TReportFormat);
    function GetReportContent(Format: TReportFormat): string;
    procedure ClearResults;
    function GetResults: TArray<TConversionResultItem>;
    function GetSummary: TConversionSummary;
    property Results: TArray<TConversionResultItem> read GetResults;
    property Summary: TConversionSummary read GetSummary;
  end;
  
  { 报告生成器具体实现 }
  TReportGenerator = class(TInterfacedObject, IReportGenerator)
  private
    FResults: TList<TConversionResultItem>;
    FSummary: TConversionSummary;
    FLock: TCriticalSection;
    
    function GenerateTextReport: string;
    function GenerateHtmlReport: string;
    function GenerateCsvReport: string;
    function GenerateJsonReport: string;
    function GenerateXmlReport: string;
  public
    constructor Create;
    destructor Destroy; override;
    
    { IReportGenerator实现 }
    procedure AddResult(const ResultItem: TConversionResultItem);
    procedure SetSummary(const Summary: TConversionSummary);
    procedure GenerateReport(const FilePath: string; Format: TReportFormat);
    function GetReportContent(Format: TReportFormat): string;
    procedure ClearResults;
    function GetResults: TArray<TConversionResultItem>;
    function GetSummary: TConversionSummary;
  end;

implementation

{ TConversionResultItem }

constructor TConversionResultItem.Create(const AFilePath: string; 
  const AOriginalEncoding, ANewEncoding: string; AFileSize: Int64; 
  AProcessingTime: TDateTime; AStatus: TConversionStatus; const AErrorMessage: string);
begin
  FilePath := AFilePath;
  OriginalEncoding := AOriginalEncoding;
  NewEncoding := ANewEncoding;
  FileSize := AFileSize;
  ProcessingTime := AProcessingTime;
  Status := AStatus;
  ErrorMessage := AErrorMessage;
end;

function TConversionResultItem.ToJSON: TJSONObject;
const
  StatusNames: array[TConversionStatus] of string = (
    '成功', '警告', '错误', '跳过', '已取消'
  );
begin
  Result := TJSONObject.Create;
  Result.AddPair('filePath', FilePath);
  Result.AddPair('originalEncoding', OriginalEncoding);
  Result.AddPair('newEncoding', NewEncoding);
  Result.AddPair('fileSize', TJSONNumber.Create(FileSize));
  Result.AddPair('processingTime', FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ProcessingTime));
  Result.AddPair('status', StatusNames[Status]);
  
  if ErrorMessage <> '' then
    Result.AddPair('errorMessage', ErrorMessage);
end;

function TConversionResultItem.ToCsv: string;
const
  StatusNames: array[TConversionStatus] of string = (
    '成功', '警告', '错误', '跳过', '已取消'
  );
begin
  Result := Format('"%s","%s","%s",%d,"%s","%s","%s"',
    [
      FilePath.Replace('"', '""'),
      OriginalEncoding.Replace('"', '""'),
      NewEncoding.Replace('"', '""'),
      FileSize,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ProcessingTime),
      StatusNames[Status],
      ErrorMessage.Replace('"', '""')
    ]);
end;

function TConversionResultItem.ToText: string;
const
  StatusNames: array[TConversionStatus] of string = (
    '成功', '警告', '错误', '跳过', '已取消'
  );
begin
  Result := Format('文件: %s'#13#10 +
                  '原编码: %s'#13#10 +
                  '新编码: %s'#13#10 +
                  '文件大小: %d 字节'#13#10 +
                  '处理时间: %s'#13#10 +
                  '状态: %s',
    [
      FilePath,
      OriginalEncoding,
      NewEncoding,
      FileSize,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ProcessingTime),
      StatusNames[Status]
    ]);
    
  if ErrorMessage <> '' then
    Result := Result + #13#10 + '错误信息: ' + ErrorMessage;
end;

{ TConversionSummary }

constructor TConversionSummary.Create;
begin
  TotalFiles := 0;
  SuccessfulFiles := 0;
  WarningFiles := 0;
  ErrorFiles := 0;
  SkippedFiles := 0;
  CancelledFiles := 0;
  TotalSize := 0;
  StartTime := 0;
  EndTime := 0;
end;

function TConversionSummary.ElapsedTimeInSeconds: Double;
begin
  if EndTime > StartTime then
    Result := SecondsBetween(StartTime, EndTime) + MilliSecondsBetween(StartTime, EndTime) / 1000
  else
    Result := 0;
end;

function TConversionSummary.AverageSpeed: Double;
var
  ElapsedSecs: Double;
begin
  ElapsedSecs := ElapsedTimeInSeconds;
  if (ElapsedSecs > 0) and (TotalSize > 0) then
    Result := TotalSize / ElapsedSecs
  else
    Result := 0;
end;

function TConversionSummary.ToJSON: TJSONObject;
var
  AverageSpeedValue: Double;
  ElapsedTime: Double;
begin
  Result := TJSONObject.Create;
  
  Result.AddPair('totalFiles', TJSONNumber.Create(TotalFiles));
  Result.AddPair('successfulFiles', TJSONNumber.Create(SuccessfulFiles));
  Result.AddPair('warningFiles', TJSONNumber.Create(WarningFiles));
  Result.AddPair('errorFiles', TJSONNumber.Create(ErrorFiles));
  Result.AddPair('skippedFiles', TJSONNumber.Create(SkippedFiles));
  Result.AddPair('cancelledFiles', TJSONNumber.Create(CancelledFiles));
  Result.AddPair('totalSize', TJSONNumber.Create(TotalSize));
  
  if StartTime > 0 then
    Result.AddPair('startTime', FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', StartTime));
    
  if EndTime > 0 then
    Result.AddPair('endTime', FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', EndTime));
    
  ElapsedTime := ElapsedTimeInSeconds;
  if ElapsedTime > 0 then
  begin
    Result.AddPair('elapsedTimeSeconds', TJSONNumber.Create(ElapsedTime));
    
    AverageSpeedValue := AverageSpeed;
    if AverageSpeedValue > 0 then
      Result.AddPair('averageSpeed', TJSONNumber.Create(AverageSpeedValue));
  end;
end;

function TConversionSummary.ToCsv: string;
begin
  Result := Format('%d,%d,%d,%d,%d,%d,%d,"%s","%s",%.3f,%.3f',
    [
      TotalFiles,
      SuccessfulFiles,
      WarningFiles,
      ErrorFiles,
      SkippedFiles,
      CancelledFiles,
      TotalSize,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', StartTime),
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', EndTime),
      ElapsedTimeInSeconds,
      AverageSpeed
    ]);
end;

function TConversionSummary.ToText: string;
begin
  Result := Format(
    '总文件数: %d'#13#10 +
    '成功转换: %d'#13#10 +
    '警告文件: %d'#13#10 +
    '错误文件: %d'#13#10 +
    '跳过文件: %d'#13#10 +
    '已取消: %d'#13#10 +
    '总大小: %d 字节'#13#10 +
    '开始时间: %s'#13#10 +
    '结束时间: %s'#13#10 +
    '总耗时: %.3f 秒',
    [
      TotalFiles,
      SuccessfulFiles,
      WarningFiles,
      ErrorFiles,
      SkippedFiles,
      CancelledFiles,
      TotalSize,
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', StartTime),
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', EndTime),
      ElapsedTimeInSeconds
    ]);
    
  if AverageSpeed > 0 then
    Result := Result + Format(#13#10 + '平均速度: %.2f 字节/秒', [AverageSpeed]);
end;

{ TReportGenerator }

constructor TReportGenerator.Create;
begin
  inherited Create;
  FResults := TList<TConversionResultItem>.Create;
  FLock := TCriticalSection.Create;
  FSummary.Create;
end;

destructor TReportGenerator.Destroy;
begin
  FResults.Free;
  FLock.Free;
  inherited;
end;

procedure TReportGenerator.AddResult(const ResultItem: TConversionResultItem);
begin
  FLock.Enter;
  try
    FResults.Add(ResultItem);
  finally
    FLock.Leave;
  end;
end;

procedure TReportGenerator.SetSummary(const Summary: TConversionSummary);
begin
  FLock.Enter;
  try
    FSummary := Summary;
  finally
    FLock.Leave;
  end;
end;

procedure TReportGenerator.ClearResults;
begin
  FLock.Enter;
  try
    FResults.Clear;
    FSummary.Create; // 重置摘要
  finally
    FLock.Leave;
  end;
end;

function TReportGenerator.GetResults: TArray<TConversionResultItem>;
begin
  FLock.Enter;
  try
    SetLength(Result, FResults.Count);
    for var i := 0 to FResults.Count - 1 do
      Result[i] := FResults[i];
  finally
    FLock.Leave;
  end;
end;

function TReportGenerator.GetSummary: TConversionSummary;
begin
  FLock.Enter;
  try
    Result := FSummary;
  finally
    FLock.Leave;
  end;
end;

procedure TReportGenerator.GenerateReport(const FilePath: string; Format: TReportFormat);
var
  Content: string;
  FileStream: TFileStream;
  Encoding: TEncoding;
  Preamble: TBytes;
begin
  Content := GetReportContent(Format);
  
  // 根据格式选择编码
  Encoding := TEncoding.UTF8;
  
  try
    if TFile.Exists(FilePath) then
      FileStream := TFileStream.Create(FilePath, fmCreate)
    else
      FileStream := TFileStream.Create(FilePath, fmCreate);
  
    try
      // 写入BOM
      Preamble := Encoding.GetPreamble;
      if Length(Preamble) > 0 then
        FileStream.WriteBuffer(Preamble[0], Length(Preamble));
        
      // 写入内容
      if Content <> '' then
      begin
        var Bytes := Encoding.GetBytes(Content);
        FileStream.WriteBuffer(Bytes[0], Length(Bytes));
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      raise Exception.CreateFmt('无法生成报告到文件 "%s": %s', [FilePath, E.Message]);
  end;
end;

function TReportGenerator.GetReportContent(Format: TReportFormat): string;
begin
  case Format of
    rfText: Result := GenerateTextReport;
    rfHTML: Result := GenerateHtmlReport;
    rfCSV: Result := GenerateCsvReport;
    rfJSON: Result := GenerateJsonReport;
    rfXML: Result := GenerateXmlReport;
  else
    Result := GenerateTextReport;
  end;
end;

function TReportGenerator.GenerateTextReport: string;
var
  StringList: TStringList;
  Item: TConversionResultItem;
begin
  StringList := TStringList.Create;
  try
    // 添加摘要信息
    StringList.Add('=== 转换结果摘要 ===');
    StringList.Add(FSummary.ToText);
    StringList.Add('');
    StringList.Add('=== 转换详细记录 ===');
    
    // 添加每个文件的转换结果
    for Item in FResults do
    begin
      StringList.Add('----------------------------------------');
      StringList.Add(Item.ToText);
      StringList.Add('');
    end;
    
    Result := StringList.Text;
  finally
    StringList.Free;
  end;
end;

function TReportGenerator.GenerateHtmlReport: string;
var
  Html: TStringList;
  Item: TConversionResultItem;
  StatusClass: string;
const
  StatusClasses: array[TConversionStatus] of string = (
    'success', 'warning', 'error', 'skipped', 'cancelled'
  );
  StatusNames: array[TConversionStatus] of string = (
    '成功', '警告', '错误', '跳过', '已取消'
  );
begin
  Html := TStringList.Create;
  try
    // HTML头
    Html.Add('<!DOCTYPE html>');
    Html.Add('<html lang="zh">');
    Html.Add('<head>');
    Html.Add('  <meta charset="UTF-8">');
    Html.Add('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    Html.Add('  <title>编码转换报告</title>');
    Html.Add('  <style>');
    Html.Add('    body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }');
    Html.Add('    h1, h2 { color: #333; }');
    Html.Add('    .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }');
    Html.Add('    .summary div { margin: 5px 0; }');
    Html.Add('    table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    Html.Add('    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }');
    Html.Add('    th { background-color: #f2f2f2; }');
    Html.Add('    tr:hover { background-color: #f5f5f5; }');
    Html.Add('    tr.success td { border-left: 4px solid #4CAF50; }');
    Html.Add('    tr.warning td { border-left: 4px solid #FFC107; }');
    Html.Add('    tr.error td { border-left: 4px solid #F44336; }');
    Html.Add('    tr.skipped td { border-left: 4px solid #9E9E9E; }');
    Html.Add('    tr.cancelled td { border-left: 4px solid #607D8B; }');
    Html.Add('    .status-success { color: #4CAF50; }');
    Html.Add('    .status-warning { color: #FFC107; }');
    Html.Add('    .status-error { color: #F44336; }');
    Html.Add('    .status-skipped { color: #9E9E9E; }');
    Html.Add('    .status-cancelled { color: #607D8B; }');
    Html.Add('  </style>');
    Html.Add('</head>');
    Html.Add('<body>');
    
    // 标题
    Html.Add('  <h1>编码转换报告</h1>');
    
    // 摘要部分
    Html.Add('  <h2>摘要</h2>');
    Html.Add('  <div class="summary">');
    Html.Add(Format('    <div>总文件数: <strong>%d</strong></div>', [FSummary.TotalFiles]));
    Html.Add(Format('    <div>成功转换: <strong class="status-success">%d</strong></div>', [FSummary.SuccessfulFiles]));
    Html.Add(Format('    <div>警告文件: <strong class="status-warning">%d</strong></div>', [FSummary.WarningFiles]));
    Html.Add(Format('    <div>错误文件: <strong class="status-error">%d</strong></div>', [FSummary.ErrorFiles]));
    Html.Add(Format('    <div>跳过文件: <strong class="status-skipped">%d</strong></div>', [FSummary.SkippedFiles]));
    Html.Add(Format('    <div>已取消: <strong class="status-cancelled">%d</strong></div>', [FSummary.CancelledFiles]));
    Html.Add(Format('    <div>总大小: <strong>%d 字节</strong></div>', [FSummary.TotalSize]));
    Html.Add(Format('    <div>开始时间: <strong>%s</strong></div>', [FormatDateTime('yyyy-mm-dd hh:nn:ss', FSummary.StartTime)]));
    Html.Add(Format('    <div>结束时间: <strong>%s</strong></div>', [FormatDateTime('yyyy-mm-dd hh:nn:ss', FSummary.EndTime)]));
    Html.Add(Format('    <div>总耗时: <strong>%.3f 秒</strong></div>', [FSummary.ElapsedTimeInSeconds]));
    
    if FSummary.AverageSpeed > 0 then
      Html.Add(Format('    <div>平均速度: <strong>%.2f 字节/秒</strong></div>', [FSummary.AverageSpeed]));
      
    Html.Add('  </div>');
    
    // 详细记录表格
    Html.Add('  <h2>详细记录</h2>');
    Html.Add('  <table>');
    Html.Add('    <thead>');
    Html.Add('      <tr>');
    Html.Add('        <th>文件</th>');
    Html.Add('        <th>原编码</th>');
    Html.Add('        <th>新编码</th>');
    Html.Add('        <th>大小 (字节)</th>');
    Html.Add('        <th>处理时间</th>');
    Html.Add('        <th>状态</th>');
    Html.Add('        <th>错误信息</th>');
    Html.Add('      </tr>');
    Html.Add('    </thead>');
    Html.Add('    <tbody>');
    
    // 添加每个文件的转换结果
    for Item in FResults do
    begin
      StatusClass := StatusClasses[Item.Status];
      
      Html.Add(Format('      <tr class="%s">', [StatusClass]));
      Html.Add(Format('        <td>%s</td>', [Item.FilePath]));
      Html.Add(Format('        <td>%s</td>', [Item.OriginalEncoding]));
      Html.Add(Format('        <td>%s</td>', [Item.NewEncoding]));
      Html.Add(Format('        <td>%d</td>', [Item.FileSize]));
      Html.Add(Format('        <td>%s</td>', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Item.ProcessingTime)]));
      Html.Add(Format('        <td class="status-%s">%s</td>', [StatusClass, StatusNames[Item.Status]]));
      Html.Add(Format('        <td>%s</td>', [Item.ErrorMessage]));
      Html.Add('      </tr>');
    end;
    
    Html.Add('    </tbody>');
    Html.Add('  </table>');
    
    // HTML尾部
    Html.Add('</body>');
    Html.Add('</html>');
    
    Result := Html.Text;
  finally
    Html.Free;
  end;
end;

function TReportGenerator.GenerateCsvReport: string;
var
  Csv: TStringList;
  Item: TConversionResultItem;
begin
  Csv := TStringList.Create;
  try
    // 添加摘要头
    Csv.Add('总文件数,成功转换,警告文件,错误文件,跳过文件,已取消,总大小,开始时间,结束时间,总耗时,平均速度');
    
    // 添加摘要数据
    Csv.Add(FSummary.ToCsv);
    
    // 添加空行
    Csv.Add('');
    
    // 添加详细记录头
    Csv.Add('文件路径,原编码,新编码,文件大小,处理时间,状态,错误信息');
    
    // 添加每个文件的转换结果
    for Item in FResults do
      Csv.Add(Item.ToCsv);
    
    Result := Csv.Text;
  finally
    Csv.Free;
  end;
end;

function TReportGenerator.GenerateJsonReport: string;
var
  RootObj, SummaryObj: TJSONObject;
  ResultsArray: TJSONArray;
  Item: TConversionResultItem;
begin
  RootObj := TJSONObject.Create;
  try
    // 添加摘要信息
    SummaryObj := FSummary.ToJSON;
    RootObj.AddPair('summary', SummaryObj);
    
    // 添加详细记录
    ResultsArray := TJSONArray.Create;
    
    for Item in FResults do
      ResultsArray.AddElement(Item.ToJSON);
      
    RootObj.AddPair('details', ResultsArray);
    
    Result := RootObj.ToJSON;
  finally
    RootObj.Free;
  end;
end;

function TReportGenerator.GenerateXmlReport: string;
var
  Xml: TStringList;
  Item: TConversionResultItem;
const
  StatusNames: array[TConversionStatus] of string = (
    '成功', '警告', '错误', '跳过', '已取消'
  );
begin
  Xml := TStringList.Create;
  try
    // XML头
    Xml.Add('<?xml version="1.0" encoding="UTF-8"?>');
    Xml.Add('<ConversionReport>');
    
    // 添加摘要信息
    Xml.Add('  <Summary>');
    Xml.Add(Format('    <TotalFiles>%d</TotalFiles>', [FSummary.TotalFiles]));
    Xml.Add(Format('    <SuccessfulFiles>%d</SuccessfulFiles>', [FSummary.SuccessfulFiles]));
    Xml.Add(Format('    <WarningFiles>%d</WarningFiles>', [FSummary.WarningFiles]));
    Xml.Add(Format('    <ErrorFiles>%d</ErrorFiles>', [FSummary.ErrorFiles]));
    Xml.Add(Format('    <SkippedFiles>%d</SkippedFiles>', [FSummary.SkippedFiles]));
    Xml.Add(Format('    <CancelledFiles>%d</CancelledFiles>', [FSummary.CancelledFiles]));
    Xml.Add(Format('    <TotalSize>%d</TotalSize>', [FSummary.TotalSize]));
    Xml.Add(Format('    <StartTime>%s</StartTime>', [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', FSummary.StartTime)]));
    Xml.Add(Format('    <EndTime>%s</EndTime>', [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', FSummary.EndTime)]));
    Xml.Add(Format('    <ElapsedTimeSeconds>%.3f</ElapsedTimeSeconds>', [FSummary.ElapsedTimeInSeconds]));
    
    if FSummary.AverageSpeed > 0 then
      Xml.Add(Format('    <AverageSpeed>%.2f</AverageSpeed>', [FSummary.AverageSpeed]));
      
    Xml.Add('  </Summary>');
    
    // 添加详细记录
    Xml.Add('  <Details>');
    
    for Item in FResults do
    begin
      Xml.Add('    <ConversionResult>');
      Xml.Add(Format('      <FilePath>%s</FilePath>', [XMLEscape(Item.FilePath)]));
      Xml.Add(Format('      <OriginalEncoding>%s</OriginalEncoding>', [XMLEscape(Item.OriginalEncoding)]));
      Xml.Add(Format('      <NewEncoding>%s</NewEncoding>', [XMLEscape(Item.NewEncoding)]));
      Xml.Add(Format('      <FileSize>%d</FileSize>', [Item.FileSize]));
      Xml.Add(Format('      <ProcessingTime>%s</ProcessingTime>', [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Item.ProcessingTime)]));
      Xml.Add(Format('      <Status>%s</Status>', [StatusNames[Item.Status]]));
      
      if Item.ErrorMessage <> '' then
        Xml.Add(Format('      <ErrorMessage>%s</ErrorMessage>', [XMLEscape(Item.ErrorMessage)]));
        
      Xml.Add('    </ConversionResult>');
    end;
    
    Xml.Add('  </Details>');
    Xml.Add('</ConversionReport>');
    
    Result := Xml.Text;
  finally
    Xml.Free;
  end;
end;

// 辅助函数：XML特殊字符转义
function XMLEscape(const Str: string): string;
begin
  Result := Str;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

end. 