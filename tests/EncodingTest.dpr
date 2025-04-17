program EncodingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  ModelEncoding in '..\ModelEncoding.pas',
  ControllerEncoding in '..\ControllerEncoding.pas',
  UtilsIconv in '..\UtilsIconv.pas',
  UtilsUTF8 in '..\UtilsUTF8.pas';


var
  Controller: TEncodingController;
  SourceDir, TargetDir, BackDir: string;
  SourceFiles: TStringDynArray;
  SourceEncoding: string;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;
