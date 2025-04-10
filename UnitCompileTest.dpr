program UnitCompileTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  JclStrings,
  JclUnicode,
  JclBOM,
  JclFileUtils,
  JclStreams,
  JclSysUtils,
  JclAnsiStrings, 
  JclStringConversions,
  JclEncodingUtils;

begin
  try
    WriteLn('JCL测试项目启动...');
    
    // 测试JclEncodingUtils
    WriteLn('测试检测文件编码...');
    var EncodingName := 'Unknown';
    
    // 检测当前执行文件的编码
    EncodingName := JclEncodingUtils.DetectFileEncoding(ParamStr(0));
    WriteLn('当前文件编码: ', EncodingName);
    
    WriteLn('JCL测试完成');
    
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
