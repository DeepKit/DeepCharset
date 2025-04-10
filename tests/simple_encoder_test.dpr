program simple_encoder_test;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  JclBOM,
  JclStreams;

// 简单测试编码检测
procedure TestEncodingDetection;
var
  FileName: string;
  BOMType: TJclBOMType;
  Stream: TFileStream;
begin
  WriteLn('===== 简单编码检测测试 =====');
  
  // 尝试检测样本目录下的文件
  if DirectoryExists('sample_files') then
  begin
    var Files := TDirectory.GetFiles('sample_files', '*.txt');
    for FileName in Files do
    begin
      try
        Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        try
          BOMType := DetectBOM(Stream);
          Write('文件 "', ExtractFileName(FileName), '" BOM类型: ');
          
          case BOMType of
            bomAnsi: WriteLn('无BOM (ANSI)');
            bomUTF8: WriteLn('UTF-8 BOM');
            bomUTF16LE: WriteLn('UTF-16 LE BOM');
            bomUTF16BE: WriteLn('UTF-16 BE BOM');
            bomUTF32LE: WriteLn('UTF-32 LE BOM');
            bomUTF32BE: WriteLn('UTF-32 BE BOM');
          else
            WriteLn('未知');
          end;
        finally
          Stream.Free;
        end;
      except
        on E: Exception do
          WriteLn('处理文件 "', ExtractFileName(FileName), '" 时出错: ', E.Message);
      end;
    end;
  end
  else
    WriteLn('未找到样本文件目录。');
  
  WriteLn('测试完成。');
end;

// 主函数
begin
  try
    TestEncodingDetection;
    
    // 暂停等待用户按键
    WriteLn;
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 