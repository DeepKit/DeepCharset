program TestReportGenerator;

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
    // 检测源文件编码
    SourceEncoding := DetectFileEncoding(SourceFile);
    
    // 读取源文件内容
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(UTF8Bytes, SourceStream.Size);
      try
        SourceStream.ReadBuffer(UTF8Bytes[0], SourceStream.Size);
      except
        on E: Exception do
        begin
          WriteLn('警告: 文件可能已损坏 - ', SourceFile, ' (', E.Message, ')');
          // 尝试恢复读取
          if SourceStream.Size > 0 then
          begin
            var BytesRead := SourceStream.Read(UTF8Bytes[0], SourceStream.Size);
            SetLength(UTF8Bytes, BytesRead);
          end
          else
            Exit;
        end;
      end;
      
      // 根据检测到的编码转换内容
      try
        case SourceEncoding of
          'UTF-8': Content := TEncoding.UTF8.GetString(UTF8Bytes);
          'UTF-16LE': Content := TEncoding.Unicode.GetString(UTF8Bytes);
          'UTF-16BE': Content := TEncoding.BigEndianUnicode.GetString(UTF8Bytes);
          'UTF-32LE': Content := TEncoding.GetEncoding(12000).GetString(UTF8Bytes);
          'UTF-32BE': Content := TEncoding.GetEncoding(12001).GetString(UTF8Bytes);
          'ASCII': Content := TEncoding.ASCII.GetString(UTF8Bytes);
          'GBK': Content := TEncoding.GetEncoding(936).GetString(UTF8Bytes);
          'EUC-JP': Content := TEncoding.GetEncoding(20932).GetString(UTF8Bytes);
          'EUC-KR': Content := TEncoding.GetEncoding(51949).GetString(UTF8Bytes);
          'BIG5': Content := TEncoding.GetEncoding(950).GetString(UTF8Bytes);
        else
          Content := TEncoding.Default.GetString(UTF8Bytes);
        end;
      except
        on E: EEncodingError do
        begin
          WriteLn('编码转换错误: ', SourceFile, ' (', E.Message, ')');
          // 尝试使用默认编码作为后备方案
          Content := TEncoding.Default.GetString(UTF8Bytes);
        end;
      end;
      
      // 创建目标文件
      TargetStream := TFileStream.Create(TargetFile, fmCreate);
      try
        // 写入UTF-8 BOM
        BOMBytes := TEncoding.UTF8.GetPreamble;
        if Length(BOMBytes) > 0 then
          TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
        
        // 写入UTF-8编码的内容
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
    begin
      WriteLn('转换文件时发生错误: ', E.Message);
      Result := False;
    end;
  end;
end;

function DetectFileEncoding(const FileName: string): string;
var
  BOM: TJclBOM;
  Stream: TFileStream;
  Buffer: TBytes;
  ByteCounts: array[0..255] of Integer;
  i: Integer;
  IsLikelyUTF8: Boolean;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    BOM := DetectBOM(Stream);
    case BOM of
      bomUtf8: Result := 'UTF-8';
      bomUtf16LE: Result := 'UTF-16LE';
      bomUtf16BE: Result := 'UTF-16BE';
      bomUtf32LE: Result := 'UTF-32LE';
      bomUtf32BE: Result := 'UTF-32BE';
    else
      // 优化无BOM文件的检测算法
      SetLength(Buffer, Min(4096, Stream.Size));
      Stream.ReadBuffer(Buffer[0], Length(Buffer));
      
      // 统计字节频率并计算熵值
      FillChar(ByteCounts, SizeOf(ByteCounts), 0);
      for i := 0 to High(Buffer) do
        Inc(ByteCounts[Buffer[i]]);
      
      // 改进的UTF-8检测 - 增加序列有效性验证
      IsLikelyUTF8 := True;
      i := 0;
      var ValidUTF8Sequences := 0;
      var TotalUTF8Sequences := 0;
      
      while i < Length(Buffer) do
      begin
        if (Buffer[i] and $80) <> 0 then // 检查高位是否为1
        begin
          Inc(TotalUTF8Sequences);
          // 检查UTF-8多字节序列
          if (Buffer[i] and $E0) = $C0 then // 2字节序列
          begin
            if (i + 1 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) then
            begin
              Inc(ValidUTF8Sequences);
              Inc(i);
            end
            else
              IsLikelyUTF8 := False;
          end
          else if (Buffer[i] and $F0) = $E0 then // 3字节序列
          begin
            if (i + 2 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) and ((Buffer[i+2] and $C0) = $80) then
            begin
              Inc(ValidUTF8Sequences);
              Inc(i, 2);
            end
            else
              IsLikelyUTF8 := False;
          end
          else if (Buffer[i] and $F8) = $F0 then // 4字节序列
          begin
            if (i + 3 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) and ((Buffer[i+2] and $C0) = $80) and ((Buffer[i+3] and $C0) = $80) then
            begin
              Inc(ValidUTF8Sequences);
              Inc(i, 3);
            end
            else
              IsLikelyUTF8 := False;
          end
          else
            IsLikelyUTF8 := False;
        end;
        Inc(i);
      end;
      
      // 基于序列有效性判断UTF-8
      if (TotalUTF8Sequences > 0) and (ValidUTF8Sequences/TotalUTF8Sequences > 0.9) then
        Result := 'UTF-8'
      else if IsASCIIText(Stream) then
        Result := 'ASCII'
      else if IsGBKText(Stream) then
        Result := 'GBK'
      else if IsBig5Text(Stream) then
        Result := 'BIG5'
      else if IsEUCJPText(Stream) then
        Result := 'EUC-JP'
      else if IsEUCKRText(Stream) then
        Result := 'EUC-KR'
      else if IsTIS620Text(Stream) then
        Result := 'TIS-620'
      else if IsVISCII(Stream) then
        Result := 'VISCII'
      else if IsWindows1256Text(Stream) then
        Result := 'Windows-1256'
      else if IsWindows1255Text(Stream) then
        Result := 'Windows-1255'
      else if IsWindows1257Text(Stream) then
        Result := 'Windows-1257'
      else if (ByteCounts[0] > Length(Buffer) div 4) then // 大量NULL字节可能是UTF-16
        Result := 'UTF-16LE'
      else if IsShiftJISText(Stream) then
        Result := 'Shift-JIS'
      else if IsEUCJISText(Stream) then
        Result := 'EUC-JIS'
      else if IsISO2022JPText(Stream) then
        Result := 'ISO-2022-JP'
      else if IsKSC5601Text(Stream) then
        Result := 'KSC5601'
      else
        Result := 'GBK';
    end;
  finally
    Stream.Free;
  end;
end;

function FindFirstDiffPos(const Str1, Str2: string): Integer;
var
  i: Integer;
  Len1, Len2: Integer;
begin
  Len1 := Length(Str1);
  Len2 := Length(Str2);
  
  for i := 1 to Min(Len1, Len2) do
  begin
    if Str1[i] <> Str2[i] then
    begin
      Result := i;
      Exit;
    end;
  end;
  
  if Len1 <> Len2 then
    Result := Min(Len1, Len2) + 1
  else
    Result := 0;
end;

const
  FROM_DIR = 'tests\\from\\';
  TO_DIR = 'tests\\to\\';
  REPORT_FILE = 'tests\\conversion_report.txt';

procedure GenerateTestFiles;
var
  i: Integer;
  FileName: string;
  Content: string;
  Encoding: TEncoding;
  LargeContent: string;
  CorruptContent: TBytes;
begin
  // 生成25个不同编码的测试文件，包括复杂场景
  for i := 1 to 25 do
  begin
    FileName := FROM_DIR + '测试文件_' + IntToStr(i) + '.txt';
    Content := '这是测试文件 ' + IntToStr(i) + ' 的内容。包含多语言混合文本: 中文, 日本語, 한국어, ไทย, Tiếng Việt 和特殊符号: ©®™😊' + #13#10;
    
    // 生成大文件内容
    LargeContent := Content;
    while Length(LargeContent) < 1024 * 1024 do // 1MB
      LargeContent := LargeContent + Content;
    
    // 生成损坏文件内容
    SetLength(CorruptContent, 100);
    FillChar(CorruptContent[0], 100, Random(256));
    
    case i mod 25 of
      0: Encoding := TEncoding.UTF8; // 普通UTF-8
      1: Encoding := TEncoding.Unicode; // UTF-16LE
      2: Encoding := TEncoding.BigEndianUnicode; // UTF-16BE
      3: Encoding := TEncoding.ASCII;
      4: Encoding := TEncoding.GetEncoding(936); // GBK
      5: Encoding := TEncoding.GetEncoding(20932); // EUC-JP
      6: Encoding := TEncoding.GetEncoding(50220); // ISO-2022-JP
      7: Encoding := TEncoding.GetEncoding(51949); // EUC-KR
      8: Encoding := TEncoding.GetEncoding(950); // BIG5
      9: Encoding := TEncoding.GetEncoding(12000); // UTF-32LE
      10: Encoding := TEncoding.GetEncoding(874); // TIS-620 (泰文)
      11: Encoding := TEncoding.GetEncoding(1258); // VISCII (越南文)
      12: Encoding := TEncoding.GetEncoding(1065); // Myanmar (缅甸文)
      13: begin // 超大文件
          FileName := FROM_DIR + '超大文件_' + IntToStr(i) + '.txt';
          try
            TFile.WriteAllText(FileName, LargeContent, TEncoding.UTF8);
            Continue;
          except
            on E: Exception do
              WriteLn('生成超大文件失败: ', FileName, ' - ', E.Message);
          end;
        end;
      14: begin // 损坏文件
          FileName := FROM_DIR + '损坏文件_' + IntToStr(i) + '.txt';
          try
            TFile.WriteAllBytes(FileName, CorruptContent);
            Continue;
          except
            on E: Exception do
              WriteLn('生成损坏文件失败: ', FileName, ' - ', E.Message);
          end;
        end;
      15: Encoding := TEncoding.GetEncoding(1250); // 中欧
      16: Encoding := TEncoding.GetEncoding(1251); // 西里尔
      17: Encoding := TEncoding.GetEncoding(1252); // 西欧
      18: Encoding := TEncoding.GetEncoding(1253); // 希腊
      19: Encoding := TEncoding.GetEncoding(1254); // 土耳其
      20: Encoding := TEncoding.GetEncoding(1255); // 希伯来文
      21: Encoding := TEncoding.GetEncoding(1256); // 阿拉伯文
      22: Encoding := TEncoding.GetEncoding(1257); // 波罗的海
      23: begin // 混合编码文件
          FileName := FROM_DIR + '混合编码_' + IntToStr(i) + '.txt';
          try
            // 写入UTF-8 BOM和内容
            TFile.WriteAllText(FileName, 'UTF-8部分: ' + Content, TEncoding.UTF8);
            // 追加GBK编码内容
            TFile.AppendAllText(FileName, 'GBK部分: ' + Content, TEncoding.GetEncoding(936));
            Continue;
          except
            on E: Exception do
              WriteLn('生成混合编码文件失败: ', FileName, ' - ', E.Message);
          end;
        end;
      24: begin // 无BOM的UTF-8文件
          FileName := FROM_DIR + '无BOM_UTF8_' + IntToStr(i) + '.txt';
          try
            // 写入无BOM的UTF-8内容
            UTF8Bytes := TEncoding.UTF8.GetBytes(Content);
            TFile.WriteAllBytes(FileName, UTF8Bytes);
            Continue;
          except
            on E: Exception do
              WriteLn('生成无BOM UTF-8文件失败: ', FileName, ' - ', E.Message);
          end;
        end
    end;
    
    try
      TFile.WriteAllText(FileName, Content, Encoding);
    except
      on E: Exception do
        WriteLn('生成测试文件失败: ', FileName, ' - ', E.Message);
    end;
  end;
end;

procedure ConvertAllFiles;
var
  Files: TStringDynArray;
  i: Integer;
  SourceFile, TargetFile: string;
  Success: Boolean;
  StartTime, EndTime: TDateTime;
  ElapsedMs: Int64;
begin
  try
    Files := TDirectory.GetFiles(FROM_DIR);
    
    for i := 0 to High(Files) do
    begin
      SourceFile := Files[i];
      TargetFile := TO_DIR + ExtractFileName(SourceFile);
      
      try
        StartTime := Now;
        Success := ConvertFileToUTF8BOM(SourceFile, TargetFile);
        EndTime := Now;
        ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
        
        if not Success then
          WriteLn('转换失败: ', SourceFile, ' -> ', TargetFile)
        else
          WriteLn('转换成功: ', SourceFile, ' (耗时: ', ElapsedMs, 'ms)');
      except
        on E: Exception do
          WriteLn('转换文件时发生错误: ', SourceFile, ' - ', E.Message);
      end;
    end;
  except
    on E: Exception do
      WriteLn('获取文件列表时发生错误: ', E.Message);
  end;
end;

procedure GenerateReport;
var
  Report: TStringList;
  Files: TStringDynArray;
  i: Integer;
  SourceFile, TargetFile: string;
  SourceContent, TargetContent: string;
  SourceEncoding, TargetEncoding: string;
  Match: Boolean;
  SourceEnc, TargetEnc: TEncoding;
begin
  Report := TStringList.Create;
  try
    Report.Add('转码测试报告');
    Report.Add('生成时间: ' + DateTimeToStr(Now));
    Report.Add('='.PadRight(80, '='));
    
    try
      Files := TDirectory.GetFiles(FROM_DIR);
      
      for i := 0 to High(Files) do
      begin
        SourceFile := Files[i];
        TargetFile := TO_DIR + ExtractFileName(SourceFile);
        
        if not FileExists(TargetFile) then
        begin
          Report.Add(Format('错误: 目标文件不存在: %s', [TargetFile]));
          Continue;
        end;
        
        SourceEncoding := DetectFileEncoding(SourceFile);
        TargetEncoding := DetectFileEncoding(TargetFile);
        
        try
          if SourceEncoding = 'GBK' then
            SourceEnc := TEncoding.GetEncoding(936)
          else
            SourceEnc := TEncoding.GetEncoding(SourceEncoding);
            
          TargetEnc := TEncoding.UTF8;
          
          try
            SourceContent := TFile.ReadAllText(SourceFile, SourceEnc);
            TargetContent := TFile.ReadAllText(TargetFile, TargetEnc);
            
            Match := SourceContent = TargetContent;
            
            Report.Add(Format('源文件: %s (%s)', [ExtractFileName(SourceFile), SourceEncoding]));
            Report.Add(Format('目标文件: %s (%s)', [ExtractFileName(TargetFile), TargetEncoding]));
            Report.Add(Format('内容匹配: %s', [BoolToStr(Match, True)]));
            
            if not Match then
              Report.Add(Format('第一个差异位置: %d', [FindFirstDiffPos(SourceContent, TargetContent)]));
            
            Report.Add('-'.PadRight(80, '-'));
          finally
            if Assigned(SourceEnc) and (SourceEnc <> TEncoding.UTF8) and (SourceEnc <> TEncoding.Unicode) and
               (SourceEnc <> TEncoding.BigEndianUnicode) and (SourceEnc <> TEncoding.ASCII) then
              SourceEnc.Free;
          end;
        except
          on E: Exception do
            Report.Add(Format('错误处理文件 %s: %s', [SourceFile, E.Message]));
        end;
      end;
      
      TFile.WriteAllText(REPORT_FILE, Report.Text, TEncoding.UTF8);
      WriteLn('报告已生成: ', REPORT_FILE);
    except
      on E: Exception do
        WriteLn('生成报告时发生错误: ', E.Message);
    end;
  finally
    Report.Free;
  end;
end;

var
  E: Exception;
begin
  try
    // 设置控制台编码为UTF-8
    SetConsoleOutputCP(65001);
    
    WriteLn('开始生成测试文件...');
    GenerateTestFiles;
    
    WriteLn('开始转换文件...');
    ConvertAllFiles;
    
    WriteLn('开始生成测试报告...');
    GenerateReport;
    
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