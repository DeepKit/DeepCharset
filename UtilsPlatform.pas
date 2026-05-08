unit UtilsPlatform;

interface

uses
  System.SysUtils, System.IOUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ENDIF}
  ;

{$IFDEF MSWINDOWS}
type
  TUPFileAttributes = TFileAttributes;
{$ELSE}
type
  TUPFileAttributes = Cardinal;
{$ENDIF}

// 读取文件属性（只在 Windows 下有效，其他平台返回 0/空集）
function UP_GetAttributes(const FileName: string; out Attrs: TUPFileAttributes): Boolean;
// 设置文件属性（Windows 有效）
function UP_SetAttributes(const FileName: string; const Attrs: TUPFileAttributes): Boolean;
// 判断是否为只读
function UP_IsReadOnly(const Attrs: TUPFileAttributes): Boolean;
// 清除只读标志（Windows 有效）
function UP_ClearReadOnly(const FileName: string): Boolean;

implementation

{$IFDEF MSWINDOWS}
function UP_GetAttributes(const FileName: string; out Attrs: TUPFileAttributes): Boolean;
begin
  try
    Attrs := TFile.GetAttributes(FileName);
    Result := True;
  except
    Result := False;
  end;
end;

function UP_SetAttributes(const FileName: string; const Attrs: TUPFileAttributes): Boolean;
begin
  try
    TFile.SetAttributes(FileName, Attrs);
    Result := True;
  except
    Result := False;
  end;
end;

function UP_IsReadOnly(const Attrs: TUPFileAttributes): Boolean;
begin
  Result := TFileAttribute.faReadOnly in Attrs;
end;

function UP_ClearReadOnly(const FileName: string): Boolean;
var
  A: TUPFileAttributes;
begin
  Result := False;
  if not UP_GetAttributes(FileName, A) then Exit;
  if not UP_IsReadOnly(A) then
  begin
    Result := True;
    Exit;
  end;
  Result := UP_SetAttributes(FileName, A - [TFileAttribute.faReadOnly]);
end;
{$ELSE}
function UP_GetAttributes(const FileName: string; out Attrs: TUPFileAttributes): Boolean;
begin
  Attrs := 0;
  Result := False;
end;

function UP_SetAttributes(const FileName: string; const Attrs: TUPFileAttributes): Boolean;
begin
  Result := False;
end;

function UP_IsReadOnly(const Attrs: TUPFileAttributes): Boolean;
begin
  Result := False;
end;

function UP_ClearReadOnly(const FileName: string): Boolean;
begin
  Result := True; // 非 Windows 平台直接视为成功
end;
{$ENDIF}

end.