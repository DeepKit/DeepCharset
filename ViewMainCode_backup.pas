Unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, System.IOUtils, System.UITypes, Vcl.FileCtrl, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Grids, System.Math, Vcl.CheckLst, System.Types, Vcl.Menus, System.Rtti,
  System.StrUtils, UtilsTypes, ModelEncoding, ModelConfig, HelperUI, HelperFiles,
  ControllerEncoding, Winapi.ShlObj, ViewMemo, Vcl.Themes, ViewSynEdit,
  System.UIConsts, System.IniFiles, ModelLanguage, ControllerLanguage, System.DateUtils,
  System.TypInfo, Vcl.Clipbrd, UtilsLogBuffer, UtilsAsyncFileScanner, UtilsDragDrop;


Type

  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    DriveComboBox1: TDriveComboBox;
    DirectoryListBox1: TDirectoryListBox;
    StringGrid1: TStringGrid;
    Panel7: TPanel;
    Splitter5: TSplitter;
    Splitter6: TSplitter;
    TreeViewEncodings: TTreeView;
    Splitter7: TSplitter;
    Splitter8: TSplitter;
    CheckListBox1: TCheckListBox;
    GridPopupMenu: TPopupMenu;
    MenuItemConvert: TMenuItem;
    MenuItemToggleSelect: TMenuItem;
    MenuItemConvertCurrent: TMenuItem;
    MenuItemConvertAllFiles: TMenuItem;
    N1: TMenuItem;
    MenuItemViewContent: TMenuItem;
    N2: TMenuItem;
    MenuItemCopyFullPath: TMenuItem;
    Panel8: TPanel;
    btnConvert: TButton;
    btnSingleFile: TButton;
    btnToggleSelect: TButton;
    ComboBox1: TComboBox;
    btnShowContent: TButton;
    Button2: TButton;
    btnSelectAllExt: TButton;
    chkIncludeSubdirs: TCheckBox;
    btnClose: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    MemLog: TMemo;
    btnRefresh: TButton;
    btnCancel: TButton;
    ProgressBar: TProgressBar;
    lblStatus: TLabel;
    btnToggleVirtualMode: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
    procedure btnSingleFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DirectoryListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure TreeViewEncodingsClick(Sender: TObject);
    procedure StringGrid1Click(Sender: TObject);
    procedure DriveComboBox1Change(Sender: TObject);
    procedure MenuItemConvertClick(Sender: TObject);
    procedure StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuItemToggleSelectClick(Sender: TObject);
    procedure btnToggleSelectClick(Sender: TObject);
    procedure MenuItemConvertCurrentClick(Sender: TObject);
    procedure MenuItemConvertAllFilesClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnShowContentClick(Sender: TObject);
    procedure btnSelectAllExtClick(Sender: TObject);
    procedure MenuItemViewContentClick(Sender: TObject);
    procedure MenuItemCopyFullPathClick(Sender: TObject);
    procedure UpdateFileCountLabel;
    procedure TreeViewEncodingsAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; Stage: TCustomDrawStage; var PaintImages,
      DefaultDraw: Boolean);
    procedure SelectUTF8BOMInTreeView;
    procedure ShowFileContent(const FileName: string; Encoding: TEncoding; const DetectedEncoding: string; HasBOM: Boolean);
    procedure AdjustGridColumnWidths;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chkIncludeSubdirsClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure FormDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure btnToggleVirtualModeClick(Sender: TObject);
  private
    FSelectedFolder: string;
    FSelectedRow: Integer;
    FFileExtensions: TStringList;
    FIncludeSubdirs: Boolean;
    FLogBuffer: TStringList;
    FBufferingLogs: Boolean;
    FLogBufferManager: TLogBuffer;
    FFileScanner: TAsyncFileScanner;
    FUseVirtualList: Boolean;

    // MVC架构组件
    FConfig: TAppConfig;
    FEncodingModel: TEncodingModel;
    FEncodingController: TEncodingController;
    FUIHelper: TUIHelper;
    FFileHelper: TFileHelper;

    FOriginalFontSize: Integer;

    // 获取本地化信息
    function GetLocalizedMessage(const MsgId: string): string;
    procedure ShowLocalizedMessage(const MsgId: string);

    procedure UpdateFileGrid(const FolderPath: string);
    procedure UpdateFileExtensions(const FolderPath: string);
    procedure CheckListBox1ClickCheck(Sender: TObject);

    // 日志记录
    procedure Log(const Msg: string);

    // 窗体刷新处理
    

    // 语言相关方法
    procedure InitializeLanguageManager;
    procedure CreateLanguageSelector;
    procedure ApplyLanguageStrings;
    procedure SwitchToLanguageCode(const LangCode: string);

    



  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    class procedure Execute;
    class procedure Initialize;
    procedure InitializeUI;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  try
    // 初始化成员变量
    FSelectedRow := -1;
    FFileExtensions := TStringList.Create;
    FLogBuffer := TStringList.Create;
    FBufferingLogs := False;
    FUseVirtualList := False;
    FOriginalFontSize := 0; // 初始化字体大小变量

    // 初始化日志目录
    var LogDir := ExtractFilePath(Application.ExeName) + 'logs';
    if not System.SysUtils.DirectoryExists(LogDir) then
    begin
      try
        System.SysUtils.ForceDirectories(LogDir);
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('创建日志目录失败: ' + E.Message));
          // 继续执行，不要中断初始化
        end;
      end;
    end;

    // 初始化日志管理器
    try
      var LogConfig := TLogBuffer.GetDefaultConfig;
      LogConfig.BufferType := lbtBoth;
      LogConfig.BufferMode := lbmBuffered;
      LogConfig.MaxBufferSize := 5000;
      LogConfig.FlushInterval := 500;
      LogConfig.EnableTimestamp := True;
      LogConfig.EnableLogLevel := True;
      LogConfig.LogFilePath := LogDir + '\TransSuccess.log';
      LogConfig.AppendToFile := True;
      LogConfig.RotationMode := lrmSize;
      LogConfig.MaxLogFileSize := 5 * 1024 * 1024; // 5MB
      LogConfig.MaxLogFiles := 10;

      FLogBufferManager := TLogBuffer.Create(LogConfig,
        TProc<string>(
          procedure(const LogMsg: string)
          begin
            if Assigned(MemLog) then
              MemLog.Lines.Add(LogMsg);
          end
        )
      );
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('初始化日志管理器失败: ' + E.Message));
        // 继续执行，不要中断初始化
      end;
    end;

    // 初始化MVC架构组件 - 按照依赖顺序初始化
    try
      // 1. 首先创建配置和模型
      FConfig := TAppConfig.Create;
      FEncodingModel := TEncodingModel.Create;

      // 2. 创建UI助手
      FUIHelper := TUIHelper.Create;

      // 3. 创建文件助手
      FFileHelper := TFileHelper.Create(
        TProc<string>(
          procedure(const LogMsg: string)
          begin
            if Assigned(Self) and Assigned(FLogBufferManager) then
              Log(LogMsg);
          end
        )
      );

      // 4. 创建编码控制器
      FEncodingController := TEncodingController.Create(
        TProc<string>(
          procedure(const LogMsg: string)
          begin
            if Assigned(Self) and Assigned(FLogBufferManager) then
              Log(LogMsg);
          end
        )
      );

      // 5. 最后创建文件扫描器
      FFileScanner := TAsyncFileScanner.Create(FFileHelper,
        TProc<string>(
          procedure(const LogMsg: string)
          begin
            if Assigned(Self) and Assigned(FLogBufferManager) then
              Log(LogMsg);
          end
        )
      );
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('初始化MVC组件失败: ' + E.Message));
        // 继续执行，不要中断初始化
      end;
    end;

    // 绑定UI控件 - 确保控件已创建
    try
      if Assigned(FFileScanner) and Assigned(ProgressBar) and Assigned(lblStatus) then
        FFileScanner.BindUI(ProgressBar, lblStatus);
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('绑定UI控件失败: ' + E.Message));
        // 继续执行，不要中断初始化
      end;
    end;

    // 设置根目录和INI目录
    try
      if Assigned(FFileHelper) then
      begin
        RootDir := FFileHelper.GetRootDir;
        IniDir := RootDir + '\ini';
        Log('设置根目录: ' + RootDir);
        Log('设置INI目录: ' + IniDir);
      end;
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('设置目录失败: ' + E.Message));
        // 继续执行，不要中断初始化
      end;
    end;

    // 初始化语言管理器
    try
      InitializeLanguageManager;
      CreateLanguageSelector;
    except
      on E: Exception do
      begin
        OutputDebugString(PChar('初始化语言管理器失败: ' + E.Message));
        // 继续执行，不要中断初始化
      end;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('初始化失败: ' + E.Message));

      // 清理已创建的资源
      try
        if Assigned(FFileScanner) then
          FreeAndNil(FFileScanner);
      except
      end;

      try
        if Assigned(FEncodingController) then
          FreeAndNil(FEncodingController);
      except
      end;

      try
        if Assigned(FFileHelper) then
          FreeAndNil(FFileHelper);
      except
      end;

      try
        if Assigned(FUIHelper) then
          FreeAndNil(FUIHelper);
      except
      end;

      try
        if Assigned(FEncodingModel) then
          FreeAndNil(FEncodingModel);
      except
      end;

      try
        if Assigned(FConfig) then
          FreeAndNil(FConfig);
      except
      end;

      try
        if Assigned(FLogBufferManager) then
          FreeAndNil(FLogBufferManager);
      except
      end;

      try
        if Assigned(FLogBuffer) then
          FreeAndNil(FLogBuffer);
      except
      end;

      try
        if Assigned(FFileExtensions) then
          FreeAndNil(FFileExtensions);
      except
      end;

      // 重新抛出异常
      raise;
    end;
  end;
end;

destructor TForm1.Destroy;
begin
  // 释放MVC架构组件
  if Assigned(FEncodingController) then
    FreeAndNil(FEncodingController);

  if Assigned(FFileHelper) then
    FreeAndNil(FFileHelper);

  if Assigned(FUIHelper) then
    FreeAndNil(FUIHelper);

  if Assigned(FEncodingModel) then
    FreeAndNil(FEncodingModel);

  if Assigned(FConfig) then
    FreeAndNil(FConfig);

  // 释放其他资源
  if Assigned(FFileScanner) then
  begin
    try
      FFileScanner.Cancel;
      FFileScanner.UnbindUI;
      FreeAndNil(FFileScanner);
    except
      // 忽略异常，确保正常释放其他资源
    end;
  end;

  if Assigned(FLogBufferManager) then
    FreeAndNil(FLogBufferManager);

  if Assigned(FLogBuffer) then
    FreeAndNil(FLogBuffer);

  if Assigned(FFileExtensions) then
    FreeAndNil(FFileExtensions);

  inherited;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    // 停止所有正在进行的操作
    if Assigned(FFileScanner) then
    begin
      try
        // 取消文件扫描
        FFileScanner.Cancel;

        // 等待扫描完成
        try
          if not FFileScanner.WaitForCompletion(1000) then
            Log('警告: 无法等待文件扫描完成，继续关闭');
        except
          on E: Exception do
            Log('等待扫描完成时出错: ' + E.Message);
        end;

        Log('已取消所有处理操作');
      except
        on E: Exception do
        begin
          Log('取消操作失败: ' + E.Message);
          // 继续关闭过程
        end;
      end;
    end;

    // 释放日志缓冲区
    try
      FUIHelper.FreeLogBuffer;
      Log('已释放日志缓冲区');
    except
      on E: Exception do
        Log('释放日志缓冲区失败: ' + E.Message);
    end;
  except
    on E: Exception do
    begin
      Log('关闭时释放SynEditForm失败: ' + E.Message);
      // 继续关闭过程确保程序可以正常关闭
    end;
  end;
end;

procedure TForm1.chkIncludeSubdirsClick(Sender: TObject);
begin
  // 更新子目录搜索状态
  FIncludeSubdirs := chkIncludeSubdirs.Checked;

  // 记录状态变化，以便将来提供更好的反馈
  if FIncludeSubdirs then
  begin
    Log('已启用子目录搜索 - 将搜索所有子文件夹中的文件');
    ShowLocalizedMessage('MsgSubdirEnabled');
  end
  else
    Log('已禁用子目录搜索 - 只搜索当前文件夹');

  // 更新文件列表以反映子目录搜索状态
  Screen.Cursor := crHourGlass;
  try
    UpdateFileGrid(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
  end;

  // 在日志中显示文件数量信息
  Log('文件列表已更新，当前显示 ' + IntToStr(StringGrid1.RowCount - 1) + ' 个文件');
end;

procedure TForm1.btnCancelClick(Sender: TObject);
begin
  // 取消当前正在进行的操作
  if Assigned(FFileScanner) and (FFileScanner.Status in [fssScanning, fssPaused]) then
  begin
    // 取消文件扫描
    Log('用户取消了文件扫描操作');
    FFileScanner.Cancel;

    // 更新UI状态
    if Assigned(lblStatus) then
      lblStatus.Caption := '操作已取消';

    if Assigned(ProgressBar) then
    begin
      ProgressBar.Position := 0;
      ProgressBar.Max := 100;
    end;

    // 显示消息
    ShowMessage('操作已取消');
  end
  else
  begin
    // 如果没有正在进行的操作，提示用户
    Log('没有正在进行的操作可以取消');
    ShowMessage('没有正在进行的操作可以取消');
  end;
end;

procedure TForm1.FormDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  // 接受文件拖放
  Accept := True;
end;

procedure TForm1.FormDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  DropFiles: TStringList;
  i: Integer;
  FileName, FolderPath: string;
  IsFolder: Boolean;
begin
  // 获取拖放的文件列表
  DropFiles := TStringList.Create;
  try
    // 获取拖放的文件
    if Assigned(Screen.ActiveForm) and (Screen.ActiveForm = Self) then
    begin
      // 获取拖放的文件
      if TDragDropFilesEx.GetDropFiles(DropFiles) then
      begin
        // 处理文件拖放
        if DropFiles.Count > 0 then
        begin
          Log(Format('接收到 %d 个拖放项目', [DropFiles.Count]));

          // 处理第一个拖放项目
          FileName := DropFiles[0];

          // 检查是否是文件夹
          IsFolder := System.SysUtils.DirectoryExists(FileName);

          if IsFolder then
          begin
            // 如果是文件夹，更新当前文件夹
            FolderPath := FileName;
            Log('拖放的是文件夹: ' + FolderPath);

            // 更新DirectoryListBox
            try
              DirectoryListBox1.Directory := FolderPath;
              FSelectedFolder := FolderPath;

              // 更新文件列表
              UpdateFileExtensions(FSelectedFolder);
              UpdateFileGrid(FSelectedFolder);
            except
              on E: Exception do
              begin
                Log('更新目录失败: ' + E.Message);
                ShowMessage('无法更新目录: ' + E.Message);
              end;
            end;
          end
          else
          begin
            // 如果是文件，更新当前文件夹为文件所在的文件夹
            FolderPath := ExtractFilePath(FileName);
            Log('拖放的是文件: ' + FileName);
            Log('文件所在文件夹: ' + FolderPath);

            // 更新DirectoryListBox
            try
              DirectoryListBox1.Directory := FolderPath;
              FSelectedFolder := FolderPath;

              // 更新文件列表
              UpdateFileExtensions(FSelectedFolder);
              UpdateFileGrid(FSelectedFolder);

              // 选中拖放的文件
              for i := 1 to StringGrid1.RowCount - 1 do
              begin
                if SameText(StringGrid1.Cells[2, i], ExtractFileName(FileName)) then
                begin
                  StringGrid1.Row := i;
                  StringGrid1.Cells[0, i] := '√';
                  Break;
                end;
              end;
            except
              on E: Exception do
              begin
                Log('更新目录失败: ' + E.Message);
                ShowMessage('无法更新目录: ' + E.Message);
              end;
            end;
          end;
        end;
      end
      else
      begin
        Log('无法获取拖放的文件');
      end;
    end;
  finally
    DropFiles.Free;
  end;
end;

procedure TForm1.btnToggleVirtualModeClick(Sender: TObject);
begin
  // 虚拟列表模式已移除
  ShowMessage('虚拟列表模式已移除');
end;

procedure TForm1.Log(const Msg: string);
begin
  if Assigned(FLogBufferManager) then
    FLogBufferManager.Log(Msg);
end;

procedure TForm1.StartLogBuffering;
begin
  FBufferingLogs := True;
  FLogBuffer.Clear;
end;

procedure TForm1.EndLogBuffering;
var
  i: Integer;
begin
  FBufferingLogs := False;

  // 将缓冲的日志写入日志管理器
  if Assigned(FLogBufferManager) and (FLogBuffer.Count > 0) then
  begin
    for i := 0 to FLogBuffer.Count - 1 do
      FLogBufferManager.Log(FLogBuffer[i]);

    FLogBuffer.Clear;
  end;
end;

procedure TForm1.InvalidateForm;
begin
  // 刷新窗体
  if Assigned(Self) and not (csDestroying in ComponentState) then
  begin
    Invalidate;
    Update;
  end;
end;

procedure TForm1.InitializeLanguageManager;
begin
  // 初始化语言管理器
  if Assigned(FUIHelper) then
    FUIHelper.InitializeLanguageManager;
end;

procedure TForm1.CreateLanguageSelector;
begin
  // 创建语言选择器
  if Assigned(FUIHelper) and Assigned(ComboBox1) then
    FUIHelper.CreateLanguageSelector(ComboBox1);
end;

procedure TForm1.ApplyLanguageStrings;
begin
  // 应用语言字符串
  if Assigned(FUIHelper) then
    FUIHelper.ApplyLanguageStrings(Self);
end;

procedure TForm1.SwitchToLanguageCode(const LangCode: string);
begin
  // 切换语言
  if Assigned(FUIHelper) then
    FUIHelper.SwitchToLanguageCode(LangCode);
end;

function TForm1.GetLocalizedMessage(const MsgId: string): string;
begin
  // 获取本地化消息
  if Assigned(FUIHelper) then
    Result := FUIHelper.GetLocalizedMessage(MsgId)
  else
    Result := MsgId;
end;



procedure TForm1.ShowLocalizedMessage(const MsgId: string);
begin
  // 显示本地化消息
  ShowMessage(GetLocalizedMessage(MsgId));
end;



procedure TForm1.UpdateFileGrid(const FolderPath: string);
var
  Files: TArray<string>;
  FileExtensions: TArray<string>;
  i, Processed: Integer;
  SelectedFileNames: TStringList;
begin
  // 检查取消请求
  if Assigned(FFileScanner) and FFileScanner.IsCancelled then
    Exit;

  // 保存选中的文件
  SelectedFileNames := TStringList.Create;
  try
    TThread.Synchronize(nil, procedure
    begin
      for i := 1 to StringGrid1.RowCount - 1 do
        if (StringGrid1.Cells[0, i] = '√') and (StringGrid1.Cells[1, i] <> '') then
          SelectedFileNames.Add(StringGrid1.Cells[1, i]);
          
      FUIHelper.ClearGrid(StringGrid1);
      StringGrid1.RowCount := 2;
      StringGrid1.Cells[1, 1] := '加载中...';
      AdjustGridColumnWidths;
    end);

    if not DirectoryExists(FolderPath) then
    begin
      TThread.Synchronize(nil, procedure
      begin
        StringGrid1.Cells[1, 1] := '(目录不存在)';
        AdjustGridColumnWidths;
      end);
      Exit;
    end;

    // 获取选中的扩展名
    SetLength(FileExtensions, 0);
    TThread.Synchronize(nil, procedure
    begin
      for i := 0 to CheckListBox1.Items.Count - 1 do
        if CheckListBox1.Checked[i] then
        begin
          SetLength(FileExtensions, Length(FileExtensions) + 1);
          FileExtensions[High(FileExtensions)] := CheckListBox1.Items[i];
        end;
    end);

    if Length(FileExtensions) = 0 then
    begin
      TThread.Synchronize(nil, procedure
      begin
        StringGrid1.Cells[1, 1] := '(请选择至少一种文件类型)';
        AdjustGridColumnWidths;
      end);
      Exit;
    end;

    // 分块加载文件(每100个文件更新一次UI)
    Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions, FIncludeSubdirs);
    Processed := 0;
    
    TThread.Synchronize(nil, procedure
    begin
      StringGrid1.RowCount := Max(2, Length(Files) + 1);
    end);

    for i := 0 to High(Files) do
    begin
      if Assigned(FFileScanner) and FFileScanner.IsCancelled then
        Break;

      // 每处理100个文件或最后一批时更新UI
      if (Processed mod 100 = 0) or (i = High(Files)) then
      begin
        TThread.Synchronize(nil, procedure
        begin
          lblStatus.Caption := string(Format('加载中...(%d/%d)', [i+1, Length(Files)]));
          ProgressBar.Position := (i+1) * 100 div Length(Files);
          Application.ProcessMessages;
        end);
      end;

      // 在后台线程处理文件
      var FileName := ExtractFileName(Files[i]);
      var EncodingName: string;
      var HasBOM: Boolean;
      
      if not DetectFileEncoding(Files[i], EncodingName, HasBOM) then
        EncodingName := '检测中...';

      var IsSelected := SelectedFileNames.IndexOf(FileName) >= 0;

      // 更新UI(主线程)
      TThread.Synchronize(nil, procedure
      begin
        if i+1 >= StringGrid1.RowCount then
          StringGrid1.RowCount := i+2;
          
        StringGrid1.Cells[0, i+1] := IfThen(IsSelected, '√', '');
        StringGrid1.Cells[1, i+1] := FileName;
        StringGrid1.Cells[2, i+1] := EncodingName;
      end);

      Inc(Processed);
    end;

    TThread.Synchronize(nil, procedure
    begin
      if StringGrid1.Cells[1, 1] = '加载中...' then
        StringGrid1.Cells[1, 1] := IfThen(Length(Files) = 0, '(无文件)', '');
        
      AdjustGridColumnWidths;
      lblStatus.Caption := string(Format('完成(%d个文件)', [Length(Files)]));
      ProgressBar.Position := 0;
    end);
  finally
    SelectedFileNames.Free;
  end;
end;
var
  Files: TStringList;
  i: Integer;
  FileName: string;
  FileInfo: TSearchRec;
  Extensions: TStringList;
begin
  // 更新文件列表
  if not System.SysUtils.DirectoryExists(FolderPath) then
    Exit;

  // 获取选中的文件扩展名
  Extensions := TStringList.Create;
  try
    for i := 0 to CheckListBox1.Items.Count - 1 do
    begin
      if CheckListBox1.Checked[i] then
        Extensions.Add(FFileExtensions[i]);
    end;

    // 扫描文件
    Files := TStringList.Create;
    try
      // 使用异步文件扫描器扫描文件
      if Assigned(FFileScanner) then
      begin
        FFileScanner.ScanFiles(FolderPath, Extensions, FIncludeSubdirs, Files);

        // 更新文件列表
        StringGrid1.RowCount := Files.Count + 1;
        for i := 0 to Files.Count - 1 do
        begin
          FileName := Files[i];
          StringGrid1.Cells[0, i + 1] := '';
          StringGrid1.Cells[1, i + 1] := ExtractFilePath(FileName);
          StringGrid1.Cells[2, i + 1] := ExtractFileName(FileName);
        end;
      end;
    finally
      Files.Free;
    end;
  finally
    Extensions.Free;
  end;

  // 更新文件计数标签
  UpdateFileCountLabel;
end;

procedure TForm1.UpdateFileExtensions(const FolderPath: string);
var
  Files: TStringList;
  i: Integer;
  Ext: string;
  Extensions: TStringList;
begin
  // 更新文件扩展名列表
  if not System.SysUtils.DirectoryExists(FolderPath) then
    Exit;

  // 清空扩展名列表
  FFileExtensions.Clear;
  CheckListBox1.Items.Clear;

  // 扫描文件扩展名
  Files := TStringList.Create;
  try
    // 使用异步文件扫描器扫描文件扩展名
    if Assigned(FFileScanner) then
    begin
      FFileScanner.ScanFileExtensions(FolderPath, FIncludeSubdirs, Files);

      // 更新扩展名列表
      Extensions := TStringList.Create;
      try
        for i := 0 to Files.Count - 1 do
        begin
          Ext := ExtractFileExt(Files[i]);
          if (Ext <> '') and (Extensions.IndexOf(Ext) < 0) then
            Extensions.Add(Ext);
        end;

        // 排序扩展名
        Extensions.Sort;

        // 更新CheckListBox
        for i := 0 to Extensions.Count - 1 do
        begin
          FFileExtensions.Add(Extensions[i]);
          CheckListBox1.Items.Add(Extensions[i]);
          CheckListBox1.Checked[i] := True;
        end;
      finally
        Extensions.Free;
      end;
    end;
  finally
    Files.Free;
  end;

  // 更新文件计数标签
  UpdateFileCountLabel;
end;

procedure TForm1.UpdateFileCountLabel;
begin
  // 更新文件计数标签
  if Assigned(lblStatus) then
    lblStatus.Caption := Format('文件数: %d', [StringGrid1.RowCount - 1]);
end;

procedure TForm1.UpdateSingleFileInGrid(const FilePath: string);
var
  i: Integer;
  FileName: string;
begin
  // 更新单个文件在网格中的显示
  FileName := ExtractFileName(FilePath);

  if Assigned(StringGrid1) then
  begin
    for i := 1 to StringGrid1.RowCount - 1 do
    begin
      if SameText(AnsiString(StringGrid1.Cells[2, i]), AnsiString(FileName)) then
    begin
      // 更新文件信息
      StringGrid1.Cells[1, i] := string(ExtractFilePath(FilePath));
      Break;
    end;
  end;
end;


procedure TForm1.btnShowContentClick(Sender: TObject);
var
  FileName: string;
  Encoding: TEncoding;
  DetectedEncoding: string;
  HasBOM: Boolean;
begin
  // 显示文件内容
  if (StringGrid1.Row > 0) and (StringGrid1.Row < StringGrid1.RowCount) then
  begin
    FileName := StringGrid1.Cells[1, StringGrid1.Row] + StringGrid1.Cells[2, StringGrid1.Row];

    // 检测文件编码
    if Assigned(FEncodingController) then
    begin
      Encoding := FEncodingController.DetectFileEncoding(FileName, DetectedEncoding, HasBOM);

      // 显示文件内容
      // 显示文件内容功能已移除
      ShowMessage('文件内容: ' + FileName + ' (编码: ' + DetectedEncoding + ')');
    end;
  end;
end;

procedure TForm1.btnSelectAllExtClick(Sender: TObject);
var
  i: Integer;
begin
  // 选择所有扩展名
  for i := 0 to CheckListBox1.Items.Count - 1 do
    CheckListBox1.Checked[i] := True;

  // 更新文件列表
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.TreeViewEncodingsAdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
begin
  // 自定义绘制TreeView项
  if Assigned(FUIHelper) then
    FUIHelper.CustomDrawTreeViewItem(Sender, Node, Stage, PaintImages, DefaultDraw);
end;

procedure TForm1.SelectUTF8BOMInTreeView;
begin
  // 选择UTF-8 BOM编码
  if Assigned(FUIHelper) then
    FUIHelper.SelectUTF8BOMInTreeView(TreeViewEncodings);
end;

procedure TForm1.ShowFileContent(const FileName: string; Encoding: TEncoding; const DetectedEncoding: string; HasBOM: Boolean);
begin
  // 显示文件内容
  if Assigned(FUIHelper) then
    FUIHelper.ShowFileContent(FileName, Encoding, DetectedEncoding, HasBOM);
end;

procedure TForm1.AdjustGridColumnWidths;
begin
  // 调整网格列宽
  if Assigned(StringGrid1) then
  begin
    StringGrid1.ColWidths[0] := 30;
    StringGrid1.ColWidths[1] := 200;
    StringGrid1.ColWidths[2] := 150;
  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // 处理键盘事件
  if (Key = VK_ESCAPE) then
  begin
    // 取消当前操作
    btnCancelClick(Sender);
    Key := 0;
  end;
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin
  // 更新文件列表
  UpdateFileGrid(FSelectedFolder);
end;

class procedure TForm1.Execute;
begin
  // 创建并显示窗体
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end;

class procedure TForm1.Initialize;
begin
  // 初始化类
end;

procedure TForm1.InitializeUI;
begin
  // 初始化UI
  if Assigned(StringGrid1) then
  begin
    StringGrid1.ColCount := 3;
    StringGrid1.RowCount := 1;
    StringGrid1.Cells[0, 0] := '';
    StringGrid1.Cells[1, 0] := '路径';
    StringGrid1.Cells[2, 0] := '文件名';

    AdjustGridColumnWidths;
  end;

  // 初始化CheckListBox
  if Assigned(CheckListBox1) then
    CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;

  // 初始化TreeView
  if Assigned(TreeViewEncodings) then
    SelectUTF8BOMInTreeView;

  // 应用语言字符串
  ApplyLanguageStrings;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  try
    // 初始化UI
    InitializeUI;

    // 设置拖放功能
    TDragDropFilesEx.EnableDragDrop(Self);

    // 显示调试信息
    ShowMessage('窗体创建成功');
  except
    on E: Exception do
    begin
      ShowMessage('窗体创建时发生异常: ' + E.Message);
    end;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  try
    // 窗体显示时的初始化
    if Assigned(DirectoryListBox1) then
    begin
      FSelectedFolder := DirectoryListBox1.Directory;
      UpdateFileExtensions(FSelectedFolder);
      UpdateFileGrid(FSelectedFolder);
    end;

    // 显示调试信息
    ShowMessage('窗体显示成功');
  except
    on E: Exception do
    begin
      ShowMessage('窗体显示时发生异常: ' + E.Message);
    end;
  end;
end;

procedure TForm1.DirectoryListBox1Change(Sender: TObject);
begin
  // 目录更改时的处理
  FSelectedFolder := DirectoryListBox1.Directory;
  UpdateFileExtensions(FSelectedFolder);
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.DriveComboBox1Change(Sender: TObject);
begin
  // 驱动器更改时的处理
  DirectoryListBox1.Drive := DriveComboBox1.Drive;
  FSelectedFolder := DirectoryListBox1.Directory;
  UpdateFileExtensions(FSelectedFolder);
  UpdateFileGrid(FSelectedFolder);
end;



procedure TForm1.btnCloseClick(Sender: TObject);
begin
  // 关闭窗体
  Close;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
begin
  // 刷新文件列表
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.btnConvertClick(Sender: TObject);
begin
  // 转换所有选中的文件
  ShowMessage('转换功能尚未实现');
end;

procedure TForm1.btnSingleFileClick(Sender: TObject);
begin
  // 转换单个文件
  ShowMessage('单文件转换功能尚未实现');
end;

procedure TForm1.DirectoryListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // 目录列表鼠标按下事件
  // 可以在这里添加右键菜单等功能
end;

procedure TForm1.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // 选择表格单元格
  FSelectedRow := ARow;
end;

procedure TForm1.TreeViewEncodingsClick(Sender: TObject);
begin
  // 编码树视图点击事件
  // 可以在这里添加编码选择功能
end;

procedure TForm1.StringGrid1Click(Sender: TObject);
begin
  // 表格点击事件
  // 可以在这里添加文件选择功能
end;

procedure TForm1.MenuItemConvertClick(Sender: TObject);
begin
  // 转换菜单项点击事件
  ShowMessage('转换功能尚未实现');
end;

procedure TForm1.StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  // 表格右键菜单事件
  // 可以在这里显示上下文菜单
end;

procedure TForm1.MenuItemToggleSelectClick(Sender: TObject);
begin
  // 切换选择菜单项点击事件
  if Assigned(FUIHelper) then
    FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.btnToggleSelectClick(Sender: TObject);
begin
  // 切换选择按钮点击事件
  if Assigned(FUIHelper) then
    FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.MenuItemConvertCurrentClick(Sender: TObject);
begin
  // 转换当前文件菜单项点击事件
  ShowMessage('转换当前文件功能尚未实现');
end;

procedure TForm1.MenuItemConvertAllFilesClick(Sender: TObject);
begin
  // 转换所有文件菜单项点击事件
  ShowMessage('转换所有文件功能尚未实现');
end;

procedure TForm1.cmbLanguageChange(Sender: TObject);
begin
  // 语言选择框变更事件
  if Assigned(ComboBox1) and (ComboBox1.ItemIndex >= 0) then
  begin
    // 获取选中的语言代码
    var LangCode := '';
    var LangInfos := ControllerLanguage.GetLanguageList;
    if (ComboBox1.ItemIndex >= 0) and (ComboBox1.ItemIndex < Length(LangInfos)) then
      LangCode := LangInfos[ComboBox1.ItemIndex].Code;

    // 切换语言
    if LangCode <> '' then
      SwitchToLanguageCode(LangCode);
  end;
end;

procedure TForm1.MenuItemViewContentClick(Sender: TObject);
begin
  // 查看内容菜单项点击事件
  btnShowContentClick(Sender);
end;

procedure TForm1.MenuItemCopyFullPathClick(Sender: TObject);
begin
  // 复制完整路径菜单项点击事件
  if (StringGrid1.Row > 0) and (StringGrid1.Row < StringGrid1.RowCount) then
  begin
    var FullPath := StringGrid1.Cells[1, StringGrid1.Row] + StringGrid1.Cells[2, StringGrid1.Row];
    Clipboard.AsText := FullPath;
    ShowMessage('已复制路径: ' + FullPath);
  end;
end;

end.
