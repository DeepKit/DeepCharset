program FullTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Diagnostics,
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.Types,
  Winapi.Windows,
  ControllerEncoding,
  ModelEncoding;

const
  TEST_DIR = 'tests\from';
  // TO_DIR, BACK_DIR, TEST_ENCODINGS, SAMPLE_SIZE are no longer needed for this test
  TEST_FILES: array[0..0] of string = ('*.TXT');

var
  Controller: TEncodingController;
  TotalFilesChecked, MatchCount, MismatchCount: Integer;
  TestStartTime, TestEndTime: TDateTime;
  LogFileName, ControllerLogFileName: string;
  LogWriter: TStreamWriter;
  // AllCombinations, SelectedCombinations no longer needed

// 设置控制台输出编码
procedure SetConsoleOutputEncoding;
begin
  SetConsoleOutputCP(CP_UTF8);
end;

// 修改LogResult以写入测试日志文件
procedure LogResult(const FileName, ExpectedEncoding, DetectedEncoding, Status: string);
begin
  if Assigned(LogWriter) then
    LogWriter.WriteLine(Format('%s|%s|%s|%s', [FileName, ExpectedEncoding, DetectedEncoding, Status]))
  else
    WriteLn(Format('Log Error: LogWriter not assigned. %s|%s|%s|%s', [FileName, ExpectedEncoding, DetectedEncoding, Status]));
end;

// NEW: Procedure to verify encoding detection
procedure VerifyEncodingDetection;
var
  FilePaths: TStringDynArray;
  FilePath: string;
  FileNameOnly: string;
  BaseName: string;
  DotPos: Integer;
  ExpectedEncoding, DetectedEncoding: string;
  Match: Boolean;
begin
  WriteLn('Starting Encoding Detection Verification...');
  TotalFilesChecked := 0;
  MatchCount := 0;
  MismatchCount := 0;

  // Ensure Controller is assigned
  if not Assigned(Controller) then
  begin
     WriteLn('Error: Controller object is not assigned.');
     Exit;
  end;

  FilePaths := TDirectory.GetFiles(TEST_DIR, TEST_FILES[0], TSearchOption.soTopDirectoryOnly);

  if Length(FilePaths) = 0 then
  begin
    WriteLn('Warning: No test files found in ' + TEST_DIR);
    Exit;
  end;

  WriteLn(Format('Found %d files to check in %s', [Length(FilePaths), TEST_DIR]));

  for FilePath in FilePaths do
  begin
    Inc(TotalFilesChecked);
    FileNameOnly := ExtractFileName(FilePath);
    BaseName := ChangeFileExt(FileNameOnly, '');

    // Extract expected encoding from the first part of the basename
    DotPos := Pos('.', BaseName);
    if DotPos > 0 then
      ExpectedEncoding := Copy(BaseName, 1, DotPos - 1)
    else
      ExpectedEncoding := BaseName; // Assume whole name if no dot

    // Normalize common names
    if SameText(ExpectedEncoding, 'UTF8') then
      ExpectedEncoding := 'UTF-8';
    // Add other normalizations if needed (e.g., GB2312 -> GBK)
    if SameText(ExpectedEncoding, 'GB2312') then
      ExpectedEncoding := 'GBK'; // Example normalization

    WriteLn('Checking file: ' + FileNameOnly + ' (Expected: ' + ExpectedEncoding + ')');

    // Detect encoding
    DetectedEncoding := '';
    if Controller.DetectFileEncoding(FilePath, DetectedEncoding) then
    begin
      // Compare
      Match := SameText(ExpectedEncoding, DetectedEncoding);
      if Match then
      begin
        Inc(MatchCount);
        LogResult(FileNameOnly, ExpectedEncoding, DetectedEncoding, 'Match');
      end
      else
      begin
        Inc(MismatchCount);
        LogResult(FileNameOnly, ExpectedEncoding, DetectedEncoding, 'Mismatch');
      end;
    end
    else
    begin
      Inc(MismatchCount); // Count detection failure as mismatch
      LogResult(FileNameOnly, ExpectedEncoding, 'Detection Failed', 'Mismatch');
    end;
  end;

  WriteLn('Verification Finished.');
end;

// 主程序
begin
  SetConsoleOutputEncoding;
  TestStartTime := Now;
  WriteLn('Starting Encoding Verification Test...');

  // Initialize Log File
  LogFileName := ChangeFileExt(ParamStr(0), '_Verification_Results.log');
  ControllerLogFileName := 'controller_log.txt'; // Keep controller log

  // Clear previous log file
  if TFile.Exists(LogFileName) then
    TFile.Delete(LogFileName);
  // Do NOT clear controller log here, let controller manage it

  LogWriter := TStreamWriter.Create(LogFileName, True, TEncoding.UTF8);
  try
    // Write log header
    LogWriter.WriteLine('FileName|ExpectedEncoding|DetectedEncoding|Status');

    // Initialize Controller
    Controller := TEncodingController.Create;
    try
      // Run the verification
      VerifyEncodingDetection;

    finally
      Controller.Free;
    end;

  finally
    LogWriter.Free;
    LogWriter := nil; // Ensure it's nil after freeing
  end;

  TestEndTime := Now;
  WriteLn('----');
  WriteLn('Verification Test Summary:');
  WriteLn(Format('Total Files Checked: %d', [TotalFilesChecked]));
  WriteLn(Format('Matches: %d', [MatchCount]));
  WriteLn(Format('Mismatches: %d', [MismatchCount]));
  WriteLn(Format('Duration: %s', [FormatDateTime('hh:nn:ss.zzz', TestEndTime - TestStartTime)]));
  WriteLn('Detailed results logged to: ' + LogFileName);
  WriteLn('Controller logs (if any issues) are in: ' + ControllerLogFileName);

end. 