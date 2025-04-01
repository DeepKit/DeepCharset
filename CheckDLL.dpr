program CheckDLL;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Winapi.Windows;

const
  // ARM架构常量定义
  IMAGE_FILE_MACHINE_ARM   = $01C0;
  IMAGE_FILE_MACHINE_ARMNT = $01C4;
  IMAGE_FILE_MACHINE_ARM64 = $AA64;

function GetDLLArchitecture(const DLLPath: string): string;
var
  ImageDosHeader: TImageDosHeader;
  ImageNtHeaders: TImageNtHeaders;
  F: THandle;
  BytesRead: DWORD;
begin
  Result := '未知';
  
  if not FileExists(DLLPath) then
  begin
    Result := '文件不存在';
    Exit;
  end;
  
  F := CreateFile(PChar(DLLPath), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if F = INVALID_HANDLE_VALUE then
  begin
    Result := Format('无法打开文件，错误码：%d', [GetLastError]);
    Exit;
  end;
  
  try
    // 读取DOS头
    if not ReadFile(F, ImageDosHeader, SizeOf(ImageDosHeader), BytesRead, nil) or
       (BytesRead <> SizeOf(ImageDosHeader)) then
    begin
      Result := '读取DOS头失败';
      Exit;
    end;
    
    // 检查MZ签名
    if ImageDosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    begin
      Result := '不是有效的PE文件';
      Exit;
    end;
    
    // 移动到PE头
    if SetFilePointer(F, ImageDosHeader._lfanew, nil, FILE_BEGIN) = $FFFFFFFF then
    begin
      Result := '定位PE头失败';
      Exit;
    end;
    
    // 读取NT头
    if not ReadFile(F, ImageNtHeaders, SizeOf(ImageNtHeaders), BytesRead, nil) or
       (BytesRead <> SizeOf(ImageNtHeaders)) then
    begin
      Result := '读取PE头失败';
      Exit;
    end;
    
    // 检查PE签名
    if ImageNtHeaders.Signature <> IMAGE_NT_SIGNATURE then
    begin
      Result := '无效的PE签名';
      Exit;
    end;
    
    // 检查Machine字段以确定架构
    case ImageNtHeaders.FileHeader.Machine of
      IMAGE_FILE_MACHINE_I386:
        Result := '32位 (x86)';
      IMAGE_FILE_MACHINE_AMD64:
        Result := '64位 (x64)';
      IMAGE_FILE_MACHINE_IA64:
        Result := '64位 (Itanium)';
      IMAGE_FILE_MACHINE_ARM:
        Result := 'ARM';
      IMAGE_FILE_MACHINE_ARMNT:
        Result := 'ARM Thumb-2';
      IMAGE_FILE_MACHINE_ARM64:
        Result := 'ARM64';
      else
        Result := Format('未知架构，Machine值：%d', [ImageNtHeaders.FileHeader.Machine]);
    end;
  finally
    CloseHandle(F);
  end;
end;

var
  DLLPath: string;

begin
  try
    WriteLn('DLL文件架构检查工具');
    WriteLn('-------------------');
    
    if ParamCount > 0 then
      DLLPath := ParamStr(1)
    else
      DLLPath := 'libiconv-2.dll';
    
    WriteLn('检查DLL文件: ', DLLPath);
    WriteLn('架构信息: ', GetDLLArchitecture(DLLPath));
    
    WriteLn;
    WriteLn('应用程序架构: ', 
      {$IFDEF WIN64}
      '64位 (x64)'
      {$ELSE}
      '32位 (x86)'
      {$ENDIF}
    );
    
    WriteLn;
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ReadLn;
    end;
  end;
end. 