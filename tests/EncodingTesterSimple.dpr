program EncodingTesterSimple;

{$APPTYPE CONSOLE}
{$WARN SYMBOL_PLATFORM OFF}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Types,
  ModelEncoding in '..\ModelEncoding.pas',
  ControllerEncoding in '..\ControllerEncoding.pas',
  UtilsIconv in '..\UtilsIconv.pas',
  UtilsUTF8 in '..\UtilsUTF8.pas';

type
  TTestResult = record
    SourceFile: string;
    SourceEncoding: string;
    TargetEncoding: string;
    ForwardResult: string;
    ReverseResult: string;
    CompareResult: string;
    Remarks: string;
  end;

const
  FROM_DIR = 'from';
  TO_DIR = 'to';
  BACK_DIR = 'back';
  RESULTS_FILE = 'tests.md';
