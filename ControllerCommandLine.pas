unit ControllerCommandLine;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  UtilsTypes,
  UtilsEncodingTypes,
  EncodingConverter_Improved;

type

  TCommandLineOptions = record
    SourceEncoding: string;
    TargetEncoding: string;
    InputFile: string;
    OutputFile: string;
    Recursive: Boolean;
    CreateBackup: Boolean;
    Verbose: Boolean;
    Quiet: Boolean;
    AddBOM: Boolean;
    RemoveBOM: Boolean;
    ShowHelp: Boolean;
    ShowVersion: Boolean;
  end;


  TCommandLineController = class
  private
    FOptions: TCommandLineOptions;
    FConverter: TEncodingConverter_Improved;
    FSuccessCount: Integer;
    FFailureCount: Integer;
    
    procedure ParseCommandLine;
    procedure ShowHelp;
    procedure ShowVersion;
    procedure WriteOutput(const Msg: string; IsError: Boolean = False);
    procedure ProcessSingleFile(const FileName: string);
    procedure ProcessDirectory(const DirPath: string);
    function CreateBackupFile(const FileName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    function Execute: Integer;
    
    property Options: TCommandLineOptions read FOptions;
  end;

implementation

{$WARN IMPLICIT_STRING_CAST OFF}

uses
  System.IOUtils,
  System.StrUtils,
  EncodingExceptions;

const
  APP_VERSION = '2.0.1';
  APP_NAME = 'DeepCharset';

{ TCommandLineController }

constructor TCommandLineController.Create;
begin
  inherited Create;
  FConverter := TEncodingConverter_Improved.Create;
  FSuccessCount := 0;
  FFailureCount := 0;
  

  FOptions.SourceEncoding := 'auto';
  FOptions.TargetEncoding := 'UTF-8';
  FOptions.Recursive := False;
  FOptions.CreateBackup := True;  // v2.0.1 P2.1: CLI 默认启用备份，防止首次误覆盖
  FOptions.Verbose := False;
  FOptions.Quiet := False;
  FOptions.AddBOM := False;
  FOptions.RemoveBOM := False;
  FOptions.ShowHelp := False;
  FOptions.ShowVersion := False;
end;

destructor TCommandLineController.Destroy;
begin
  FConverter.Free;
  inherited;
end;

procedure TCommandLineController.ParseCommandLine;
var
  I: Integer;
  Param, NextParam: string;
begin
  I := 1;
  while I <= ParamCount do
  begin
    Param := ParamStr(I);
    

    if I < ParamCount then
      NextParam := ParamStr(I + 1)
    else
      NextParam := '';
    

    if (Param = '-h') or (Param = '--help') or (Param = '/?') then
    begin
      FOptions.ShowHelp := True;
      Inc(I);
    end
    else if (Param = '-v') or (Param = '--version') then
    begin
      FOptions.ShowVersion := True;
      Inc(I);
    end
    else if (Param = '-s') or (Param = '--source') then
    begin
      FOptions.SourceEncoding := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-t') or (Param = '--target') then
    begin
      FOptions.TargetEncoding := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-o') or (Param = '--output') then
    begin
      FOptions.OutputFile := NextParam;
      Inc(I, 2);
    end
    else if (Param = '-r') or (Param = '--recursive') then
    begin
      FOptions.Recursive := True;
      Inc(I);
    end
    else if (Param = '-b') or (Param = '--backup') then
    begin
      FOptions.CreateBackup := True;
      Inc(I);
    end
    else if (Param = '--no-backup') then
    begin
      FOptions.CreateBackup := False;
      Inc(I);
    end
    else if (Param = '--verbose') then
    begin
      FOptions.Verbose := True;
      Inc(I);
    end
    else if (Param = '-q') or (Param = '--quiet') then
    begin
      FOptions.Quiet := True;
      Inc(I);
    end
    else if (Param = '--add-bom') then
    begin
      FOptions.AddBOM := True;
      Inc(I);
    end
    else if (Param = '--remove-bom') then
    begin
      FOptions.RemoveBOM := True;
      Inc(I);
    end
    else if not StartsText('-', Param) then
    begin

      if FOptions.InputFile = '' then
        FOptions.InputFile := Param;
      Inc(I);
    end
    else
    begin
      WriteOutput('' + Param, True);
      Inc(I);
    end;
  end;
end;

procedure TCommandLineController.ShowHelp;
begin
  WriteLn('' + APP_NAME + '');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('  Unicode:   UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('');
  WriteLn('  ' + APP_NAME + '.exe -s GBK -t UTF-8 input.txt');
  WriteLn('');
  WriteLn('');
  WriteLn('  ' + APP_NAME + '.exe -s auto -t UTF-8 input.txt -o output.txt');
  WriteLn('');
  WriteLn('');
  WriteLn('  ' + APP_NAME + '.exe -s GBK -t UTF-8 -r -b C:\MyFiles\');
  WriteLn('');
  WriteLn('');
  WriteLn('  ' + APP_NAME + '.exe -s Big5 -t UTF-8 --add-bom input.txt');
  WriteLn('');
  WriteLn('');
  WriteLn('  ' + APP_NAME + '.exe -s 936 -t 65001 input.txt');
end;

procedure TCommandLineController.ShowVersion;
begin
  WriteLn(APP_NAME + ' v' + APP_VERSION);
  WriteLn('');
  WriteLn('Copyright (c) 2025 DeepCharset Team');
end;

procedure TCommandLineController.WriteOutput(const Msg: string; IsError: Boolean);
begin
  if FOptions.Quiet then
    Exit;
    
  if IsError then
    WriteLn(ErrOutput, '' + Msg)
  else
    WriteLn(Msg);
end;

function TCommandLineController.CreateBackupFile(const FileName: string): Boolean;
var
  BackupFileName: string;
begin
  Result := False;
  BackupFileName := FileName + '.bak';
  
  try
    TFile.Copy(FileName, BackupFileName, True);
    if FOptions.Verbose then
      WriteOutput('' + BackupFileName);
    Result := True;
  except
    on E: Exception do
      WriteOutput('' + E.Message, True);
  end;
end;

procedure TCommandLineController.ProcessSingleFile(const FileName: string);
var
  ConvResult: TEncodingConversionResult;
  ConvOptions: TEncodingConversionOptions;
  OutputFileName: string;
begin
  if not FileExists(FileName) then
  begin
    WriteOutput('' + FileName, True);
    Inc(FFailureCount);
    Exit;
  end;
  
  if FOptions.Verbose then
    WriteOutput('' + FileName);
  

  if FOptions.CreateBackup then
    CreateBackupFile(FileName);
  

  ConvOptions := TEncodingConverter_Improved.CreateDefaultOptions;
  ConvOptions.AddBOM := FOptions.AddBOM;

  ConvOptions.ErrorHandling := eehsSkip;
  

  if FOptions.OutputFile <> '' then
    OutputFileName := FOptions.OutputFile
  else
    OutputFileName := FileName;
  
  try

    ConvResult := FConverter.ConvertFile(
      FileName,
      OutputFileName,
      FOptions.SourceEncoding,
      FOptions.TargetEncoding,
      ConvOptions
    );
    
    if ConvResult.Success then
    begin
      Inc(FSuccessCount);
      if FOptions.Verbose then
      begin
        {$WARN IMPLICIT_STRING_CAST OFF}
        WriteOutput(Format('', 
          [ConvResult.SourceEncoding, ConvResult.TargetEncoding, ConvResult.BytesProcessed]));
        {$WARN IMPLICIT_STRING_CAST ON}
      end;
    end
    else
    begin
      Inc(FFailureCount);

      if ConvResult.ErrorCount > 0 then
      begin
        {$WARN IMPLICIT_STRING_CAST OFF}
        WriteOutput(Format('', [FileName, ConvResult.Errors[0].ErrorMessage]), True);
        {$WARN IMPLICIT_STRING_CAST ON}
      end
      else
      begin
        {$WARN IMPLICIT_STRING_CAST OFF}
        WriteOutput(Format('', [FileName]), True);
        {$WARN IMPLICIT_STRING_CAST ON}
      end;
    end;
  except
    on E: EEncodingException do
    begin
      Inc(FFailureCount);
      {$WARN IMPLICIT_STRING_CAST OFF}
      WriteOutput(Format('', [FileName, E.Message]), True);
      {$WARN IMPLICIT_STRING_CAST ON}
    end;
    on E: Exception do
    begin
      Inc(FFailureCount);
      {$WARN IMPLICIT_STRING_CAST OFF}
      WriteOutput(Format('', [FileName, E.Message]), True);
      {$WARN IMPLICIT_STRING_CAST ON}
    end;
  end;
end;

procedure TCommandLineController.ProcessDirectory(const DirPath: string);
var
  Files: TArray<string>;
  FileName: string;
  SearchOption: TSearchOption;
begin
  if not DirectoryExists(DirPath) then
  begin
    WriteOutput('' + DirPath, True);
    Exit;
  end;
  
  if FOptions.Verbose then
    WriteOutput('' + DirPath);
  

  if FOptions.Recursive then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
  

  try
    Files := TDirectory.GetFiles(DirPath, '*.*', SearchOption);
    
    if Length(Files) = 0 then
    begin
      {$WARN IMPLICIT_STRING_CAST OFF}
      WriteOutput('');
      {$WARN IMPLICIT_STRING_CAST ON}
      Exit;
    end;
    
    {$WARN IMPLICIT_STRING_CAST OFF}
    WriteOutput(Format('', [Length(Files)]));
    {$WARN IMPLICIT_STRING_CAST ON}
    

    for FileName in Files do
    begin

      if EndsText('.bak', FileName) then
        Continue;
        
      ProcessSingleFile(FileName);
    end;
  except
    on E: Exception do
      WriteOutput('' + E.Message, True);
  end;
end;

function TCommandLineController.Execute: Integer;
begin
  Result := 0;
  

  ParseCommandLine;
  

  if FOptions.ShowHelp then
  begin
    ShowHelp;
    Exit;
  end;
  
  if FOptions.ShowVersion then
  begin
    ShowVersion;
    Exit;
  end;
  

  if FOptions.InputFile = '' then
  begin
    WriteOutput('', True);
    WriteOutput('', True);
    Result := 1;
    Exit;
  end;
  

  if DirectoryExists(FOptions.InputFile) then
  begin

    ProcessDirectory(FOptions.InputFile);
  end
  else if FileExists(FOptions.InputFile) then
  begin

    ProcessSingleFile(FOptions.InputFile);
  end
  else
  begin
    WriteOutput('' + FOptions.InputFile, True);
    Result := 1;
    Exit;
  end;
  

  if not FOptions.Quiet then
  begin
    WriteLn('');
    WriteLn('');
    WriteLn(Format('', [FSuccessCount]));
    WriteLn(Format('', [FFailureCount]));
  end;
  

  if FFailureCount > 0 then
    Result := 1;
end;

end.
