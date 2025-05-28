unit UtilsDragDrop;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Forms,
  Vcl.Controls, Vcl.Dialogs, System.StrUtils, System.IOUtils, Winapi.ShellAPI;

type
  /// <summary>
  /// 拖放文件扩展类
  /// </summary>
  TDragDropFilesEx = class
  private
    class var FDropFiles: TStringList;
    class var FLastDropTime: Cardinal;
    class var FDropTimeout: Cardinal;

    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>
    /// 获取拖放的文件列表
    /// </summary>
    class function GetDropFiles(Files: TStringList): Boolean; static;

    /// <summary>
    /// 处理拖放消息
    /// </summary>
    class procedure HandleDropFiles(var Msg: TWMDropFiles); static;

    /// <summary>
    /// 启用窗体的拖放功能
    /// </summary>
    class procedure EnableDragDrop(Form: TForm); static;

    /// <summary>
    /// 禁用窗体的拖放功能
    /// </summary>
    class procedure DisableDragDrop(Form: TForm); static;

    /// <summary>
    /// 拖放超时时间（毫秒）
    /// </summary>
    class property DropTimeout: Cardinal read FDropTimeout write FDropTimeout;
  end;

implementation

{ TDragDropFilesEx }

class constructor TDragDropFilesEx.Create;
begin
  FDropFiles := TStringList.Create;
  FLastDropTime := 0;
  FDropTimeout := 5000; // 5秒超时
end;

class destructor TDragDropFilesEx.Destroy;
begin
  FreeAndNil(FDropFiles);
end;

class procedure TDragDropFilesEx.DisableDragDrop(Form: TForm);
begin
  if Assigned(Form) then
    DragAcceptFiles(Form.Handle, False);
end;

class procedure TDragDropFilesEx.EnableDragDrop(Form: TForm);
begin
  if Assigned(Form) then
  begin
    // 启用拖放
    DragAcceptFiles(Form.Handle, True);

    // 使用窗体的消息处理
    // 注册窗体的WM_DROPFILES消息处理
    // 这里不再设置窗体的消息处理，而是依赖于Application.OnMessage
  end;
end;

class function TDragDropFilesEx.GetDropFiles(Files: TStringList): Boolean;
begin
  Result := False;

  if not Assigned(Files) then
    Exit;

  // 检查是否超时
  if GetTickCount - FLastDropTime > FDropTimeout then
  begin
    FDropFiles.Clear;
    Exit;
  end;

  // 复制文件列表
  Files.Assign(FDropFiles);
  Result := Files.Count > 0;
end;

class procedure TDragDropFilesEx.HandleDropFiles(var Msg: TWMDropFiles);
var
  DropHandle: HDROP;
  FileCount: Integer;
  FileName: string;
  Buffer: array[0..MAX_PATH] of Char;
  i: Integer;
begin
  // 清空文件列表
  FDropFiles.Clear;

  // 获取拖放句柄
  DropHandle := Msg.Drop;

  try
    // 获取文件数量
    FileCount := DragQueryFile(DropHandle, $FFFFFFFF, nil, 0);

    // 获取文件名
    for i := 0 to FileCount - 1 do
    begin
      DragQueryFile(DropHandle, i, Buffer, MAX_PATH);
      FileName := Buffer;
      FDropFiles.Add(FileName);
    end;

    // 更新最后拖放时间
    FLastDropTime := GetTickCount;
  finally
    // 释放拖放句柄
    DragFinish(DropHandle);
  end;

  // 设置消息已处理
  Msg.Result := 0;
end;

initialization
  // 注册拖放文件消息处理
  // 在窗体创建时使用EnableDragDrop方法

end.
