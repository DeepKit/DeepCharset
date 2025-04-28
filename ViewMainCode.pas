Unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, System.IOUtils, System.UITypes, Vcl.FileCtrl, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Grids, System.Math, Vcl.CheckLst, System.Types, Vcl.Menus, System.Rtti,
  System.StrUtils, UtilsTypes, ModelEncoding, ModelConfig, HelperUI, HelperFiles,
  ControllerEncoding, Winapi.ShlObj, ViewMemo, Vcl.Themes, ViewSynEdit,
  System.UIConsts, System.IniFiles, ModelLanguage, ControllerLanguage,
  System.TypInfo, Vcl.Clipbrd;


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
    Label1: TLabel;
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
  private
    FSelectedFolder: string;
    FSelectedRow: Integer;
    FFileExtensions: TStringList;
    FIncludeSubdirs: Boolean;
    FLogBuffer: TStringList;
    FBufferingLogs: Boolean;

    // MVC架构组件
    FConfig: TAppConfig;
    FEncodingModel: TEncodingModel;
    FEncodingController: TEncodingController;
    FUIHelper: TUIHelper;
    FFileHelper: TFileHelper;

    FOriginalFontSize: Integer;

    // 国际化相关
    FCurrentLanguage: string;

    // 获取翻译后的消息
    function GetLocalizedMessage(const MsgId: string): string;
    function GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
    procedure ShowLocalizedMessage(const MsgId: string);
    procedure ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);

    procedure UpdateFileGrid(const FolderPath: string);
    procedure UpdateFileExtensions(const FolderPath: string);
    procedure CheckListBox1ClickCheck(Sender: TObject);

    // 日志记录
    procedure Log(const Msg: string);
    procedure StartLogBuffering;
    procedure EndLogBuffering;

    // 表单刷新处理
    procedure InvalidateForm;

    // 语言设置相关方法
    procedure InitializeLanguageManager;
    procedure CreateLanguageSelector;
    procedure ApplyLanguageStrings;
    procedure SwitchToLanguageCode(const LangCode: string);

    procedure UpdateSingleFileInGrid(const FilePath: string);

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

  // 初始化成员
  FSelectedRow := -1;
  FFileExtensions := TStringList.Create;
  FLogBuffer := TStringList.Create;
  FBufferingLogs := False;

  // 初始化MVC架构组件
  FConfig := TAppConfig.Create;
  FEncodingModel := TEncodingModel.Create;
  FUIHelper := TUIHelper.Create;

  // 创建编码控制器，使用匿名方法作为日志回调
  FEncodingController := TEncodingController.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );

  // 创建文件助手，使用匿名方法作为日志回调
  FFileHelper := TFileHelper.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );

  // 设置根目录和INI目录
  RootDir := FFileHelper.GetRootDir;
  IniDir := RootDir + '\ini';
  Log('设置根目录: ' + RootDir);
  Log('设置INI目录: ' + IniDir);

  // 初始化语言管理器
  InitializeLanguageManager;

  // 创建语言选择器
  CreateLanguageSelector;
end;

destructor TForm1.Destroy;
begin
  // 释放MVC架构组件
  FEncodingController.Free;
  FFileHelper.Free;
  FUIHelper.Free;
  FEncodingModel.Free;
  FConfig.Free;

  // 释放其他资源
  FLogBuffer.Free;
  FFileExtensions.Free;
  inherited;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
begin
  // 应用当前语言
  ApplyLanguageStrings;

  // 强制立即应用界面更新
  Application.ProcessMessages;

  // 给窗体及组件一点点时间来处理更新请求
  Sleep(100);

  // 强制更新所有UI元素
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;

  // 强制重绘整个窗体
  InvalidateForm;

  // 记录日志
  Log('程序界面已显示');
  Log('当前语言: ' + FCurrentLanguage);
  Log('主窗体标题: ' + Caption);
  Log('按钮状态检查:');
  Log(' - 转换按钮: ' + btnConvert.Caption);
  Log(' - 单文件按钮: ' + btnSingleFile.Caption);
  Log(' - 刷新按钮: ' + btnRefresh.Caption);
  Log(' - 全选类型按钮: ' + btnSelectAllExt.Caption);
  Log(' - 查看内容按钮: ' + btnShowContent.Caption);

  // 应用列宽设置
  AdjustGridColumnWidths;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.btnConvertClick(Sender: TObject);
var
  FolderPath: string;
  TargetInfo: TEncodingInfo;
  WithBOM: Boolean;
  SelectedFiles: TArray<string>;
  SuccessCount: Integer;
  SelectedIndex: Integer;
begin
  FolderPath := FSelectedFolder;

  // Ensure folder path is valid (Fix Deprecation Warning)
  if not System.SysUtils.DirectoryExists(FolderPath) then // Ensure qualified
  begin
    Log('请选择有效的文件夹');
    Exit;
  end;

  // Get selected encoding info
  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    ShowMessage('请选择一个目标编码。');
    Exit;
  end;
  SelectedIndex := Integer(TreeViewEncodings.Selected.Data);
  TargetInfo := FEncodingModel.Encodings[SelectedIndex];
  WithBOM := TargetInfo.HasBOM;

  // Get selected files
  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);

  if Length(SelectedFiles) = 0 then
  begin
    ShowLocalizedMessage('MsgSelectFiles');
    Exit;
  end;

  // Start log buffering
  Log('开始批量转换 ' + IntToStr(Length(SelectedFiles)) + ' 个文件到 ' + TargetInfo.Name + '...');
  StartLogBuffering;

  // Execute conversion
  Screen.Cursor := crHourGlass;
  SuccessCount := 0;

  try
    // Execute conversion
    for var j := 0 to High(SelectedFiles) do
    begin
      if FEncodingController.ConvertSingleFile(SelectedFiles[j], TargetInfo.ShortName, WithBOM) then
      begin
        UpdateSingleFileInGrid(SelectedFiles[j]);
        Inc(SuccessCount);
      end;
    end;

    // Record conversion result
    Log(System.SysUtils.Format('批量转换完成: 成功 %d/%d 个文件', [SuccessCount, Length(SelectedFiles)]));
    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('注意: %d 个文件未能成功转换 (可能是非文本文件或无法访问)',
          [Length(SelectedFiles) - SuccessCount]));

    // Refresh the grid
    UpdateFileGrid(FolderPath);
  finally
    Screen.Cursor := crDefault;

    // End log buffering and update log at once
    EndLogBuffering;

    // Show result
    if SuccessCount > 0 then
      ShowMessage(System.SysUtils.Format('转换完成: 成功 %d/%d 个文件', [SuccessCount, Length(SelectedFiles)]))
    else if Length(SelectedFiles) > 0 then
      ShowMessage('转换失败: 没有文件被成功转换，请检查日志了解详情');
  end;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
begin
  if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
  begin
    UpdateFileGrid(DirectoryListBox1.Directory);
    Log('已刷新目录: ' + DirectoryListBox1.Directory);
  end;
end;

procedure TForm1.btnSingleFileClick(Sender: TObject);
begin
  // Just call the logic from the menu item handler
  MenuItemConvertCurrentClick(Sender);
end;


procedure TForm1.btnToggleSelectClick(Sender: TObject);
        begin
  // 全选/取消全选
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin
  // 当CheckListBox1的项目被选中或取消选中时更新文件列表
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.cmbLanguageChange(Sender: TObject);
var
  Index, LangIndex: Integer;
  LangCode: string;
begin
  // 获取选中的语言
  Index := ComboBox1.ItemIndex;
  if Index < 0 then
  begin
    Log('警告: 无效的语言索引');
    Exit;
  end;

  // 获取语言索引
  LangIndex := Integer(ComboBox1.Items.Objects[Index]);

  // 记录用户选择的语言
  Log('用户选择语言: ' + ComboBox1.Items[Index] + ' (Index: ' + IntToStr(LangIndex) + ')');

  // 获取语言代码
  if (LangIndex >= 0) and (LangIndex <= High(LANGUAGE_MAPPINGS)) then
  begin
    LangCode := LANGUAGE_MAPPINGS[LangIndex].LanguageCode;
    Log('切换到语言: ' + LangCode);

    // 切换语言
    SwitchToLanguageCode(LangCode);
  end
  else
  begin
    Log('警告: 无效的语言索引: ' + IntToStr(LangIndex));
  end;

  // 确保界面及时刷新
  Application.ProcessMessages;
end;

procedure TForm1.DirectoryListBox1Change(Sender: TObject);
  begin
  // 更新选中的文件夹
  FSelectedFolder := DirectoryListBox1.Directory;

  // 更新配置中的最后使用目录
  FConfig.LastDirectory := FSelectedFolder;

  // 更新文件列表和文件扩展名列表
  Log('选择的目录: ' + FSelectedFolder);
  UpdateFileExtensions(FSelectedFolder);
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.DirectoryListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // 用户点击目录列表框
  if Button = mbLeft then
      begin
    // 在鼠标点击后更新选中的文件夹
    FSelectedFolder := DirectoryListBox1.Directory;
  end;
end;

procedure TForm1.DriveComboBox1Change(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    // 将DirectoryListBox的目录设置为当前选择的驱动器
    DirectoryListBox1.Drive := DriveComboBox1.Drive;
    // 更新选中的文件夹
    FSelectedFolder := DirectoryListBox1.Directory;
    Log('驱动器: ' + DriveComboBox1.Drive + ', 选择的目录: ' + FSelectedFolder);
    // 更新文件列表
    UpdateFileExtensions(FSelectedFolder);
    UpdateFileGrid(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
  end;
end;

class procedure TForm1.Execute;
begin
  // 创建并显示主窗体
  Application.CreateForm(TForm1, Form1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // 允许窗体接收所有键盘事件
  KeyPreview := True;

  // 初始化语言管理器
  InitializeLanguageManager;

  // 调用统一的界面初始化方法
  InitializeUI;

  // 应用当前语言字符串
  ApplyLanguageStrings;
end;

procedure TForm1.TreeViewEncodingsClick(Sender: TObject);
    begin
  // 当用户点击TreeViewEncodings中的项目时触发
  // 如果点击的是组标题（根节点），取消选择
  if (TreeViewEncodings.Selected <> nil) and (TreeViewEncodings.Selected.Level = 0) then
    begin
    TreeViewEncodings.Selected := nil;
    end;
end;

procedure TForm1.Log(const Msg: string);
begin
  if FBufferingLogs then
  begin
    // 缓冲模式：将日志添加到缓冲区
    FLogBuffer.Add(Msg);
  end
  else
  begin
    // 正常模式：直接添加到MemLog
    FUIHelper.AppendLog(MemLog, Msg);
  end;
end;

// 开始日志缓冲
procedure TForm1.StartLogBuffering;
begin
  FBufferingLogs := True;
  FLogBuffer.Clear;
end;

// 结束日志缓冲并一次性更新MemLog
procedure TForm1.EndLogBuffering;
var
  i: Integer;
begin
  FBufferingLogs := False;

  // 一次性添加所有缓冲的日志
  if FLogBuffer.Count > 0 then
  begin
    // 如果日志太多，只显示最后100条
    if FLogBuffer.Count > 100 then
    begin
      FUIHelper.AppendLog(MemLog, '共有 ' + IntToStr(FLogBuffer.Count) + ' 条日志，只显示最后100条...');
      for i := FLogBuffer.Count - 100 to FLogBuffer.Count - 1 do
        FUIHelper.AppendLog(MemLog, FLogBuffer[i]);
    end
    else
    begin
      for i := 0 to FLogBuffer.Count - 1 do
        FUIHelper.AppendLog(MemLog, FLogBuffer[i]);
    end;

    FLogBuffer.Clear;
  end;
end;

procedure TForm1.MenuItemConvertAllFilesClick(Sender: TObject);
var
  i, SuccessCount: Integer;
  AllFiles: TArray<string>;
  Encoding: TEncoding;
  HasBOM: Boolean;
  DetectedEncoding: string;
  EncodingName: string;
  FinishMsg: string;
begin
  // Get file list - use FIncludeSubdirs parameter
  AllFiles := FFileHelper.GetSelectedFilesInFolder(FSelectedFolder, FFileExtensions,
    function(const FilePath: string): Boolean
    begin
      Result := True; // Select all files
    end,
    FIncludeSubdirs
  );

  // If no files, show message and exit
  if Length(AllFiles) = 0 then
  begin
    ShowLocalizedMessage('MsgNoFilesForConversion');
    Exit;
  end;

  // Get selected encoding (from TreeView)
  Encoding := FEncodingModel.GetSelectedEncoding;

  // Confirmation dialog
  if Application.MessageBox(
    PChar(System.SysUtils.Format('确定要将所有文件 (%d 个) 转换为当前选择的编码? ', [Length(AllFiles)])),
    '批量转换确认',
    MB_YESNO + MB_ICONQUESTION) <> IDYES then
  begin
    Log('取消批量转换');
    Exit;
  end;

  // Start batch conversion
  Log('开始批量转换所有文件...');
  StartLogBuffering;
  SuccessCount := 0;

  try
    // Set cursor to wait state
    Screen.Cursor := crHourGlass;

    // Iterate through all files for conversion
    for i := 0 to High(AllFiles) do
    begin
      // Detect current encoding
      DetectedEncoding := FFileHelper.DetectFileEncoding(AllFiles[i], HasBOM);

      // Try conversion
      if FEncodingController.ConvertSingleFile(AllFiles[i], FEncodingModel.GetEncodingName(Encoding), True) then
      begin
        Inc(SuccessCount);
        Log('- 成功转换: ' + AllFiles[i] + ' (从 ' + DetectedEncoding + ' 到 ' +
          FEncodingModel.GetEncodingName(Encoding) + ')');
      end
      else
      begin
        Log('- 转换失败: ' + AllFiles[i]);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('批量转换完成: 成功 %d/%d 个文件', [SuccessCount, Length(AllFiles)]));
    if SuccessCount < Length(AllFiles) then
      Log(System.SysUtils.Format('注意: %d 个文件未能成功转换 (可能是非文本文件或无法访问)',
        [Length(AllFiles) - SuccessCount]));
  finally
    // Restore cursor
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;

procedure TForm1.MenuItemConvertClick(Sender: TObject);
var
  TargetInfo: TEncodingInfo;
  WithBOM: Boolean;
  SelectedFiles: TArray<string>;
  SelectedIndex: Integer;
  SuccessCount: Integer;
begin
  if StringGrid1.RowCount <= 1 then Exit; // No files loaded

  // 获取选中的编码信息
  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    ShowLocalizedMessage('MsgSelectTargetEncoding');
    Exit;
  end;
  SelectedIndex := Integer(TreeViewEncodings.Selected.Data);
  TargetInfo := FEncodingModel.Encodings[SelectedIndex];
  WithBOM := TargetInfo.HasBOM;

  // 获取选中的文件
  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);

  if Length(SelectedFiles) = 0 then
  begin
    ShowMessage('请至少选择一个文件进行转换。');
    Exit;
  end;

  SuccessCount := 0;

  // 执行转换
  for var j := 0 to High(SelectedFiles) do
  begin
    if FEncodingController.ConvertSingleFile(SelectedFiles[j], TargetInfo.ShortName, WithBOM) then
    begin
      UpdateSingleFileInGrid(SelectedFiles[j]);
      Inc(SuccessCount);
    end;
  end;
  Log(System.SysUtils.Format('批量转换完成: %d 个文件', [SuccessCount]));
end;

procedure TForm1.MenuItemConvertCurrentClick(Sender: TObject);
var
  FilePath: string;
  Encoding: TEncoding;
  SuccessCount: Integer;
  SelectedFiles: TArray<string>;
  HasBOM: Boolean;
  DetectedEncoding: string;
  i: Integer;
begin
  // Get selected files
  SelectedFiles := FFileHelper.GetSelectedFilesInFolder(FSelectedFolder, FFileExtensions,
    function(const FilePath: string): Boolean
    begin
      Result := False; // Assume no file selected first

      // Find this file in the grid
      for var j := 1 to StringGrid1.RowCount - 1 do
      begin
        if (StringGrid1.Cells[1, j] <> '') and
           (FilePath = IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[1, j]) and
           (StringGrid1.Cells[0, j] = '√') then
        begin
          Result := True;
          Break;
        end;
      end;
    end,
    FIncludeSubdirs
  );

  // If no files selected, show message
  if Length(SelectedFiles) = 0 then
  begin
    ShowLocalizedMessage('MsgNoFilesSelected');
    Exit;
  end;

  // Get selected encoding (from TreeView)
  Encoding := FEncodingModel.GetSelectedEncoding;

  // Start batch conversion
  Log('开始转换选中的文件...');
  StartLogBuffering;
  SuccessCount := 0;

  try
    // Set cursor to wait state
    Screen.Cursor := crHourGlass;

    // Iterate through all selected files for conversion
    for i := 0 to High(SelectedFiles) do
    begin
      FilePath := SelectedFiles[i];

      // Detect current encoding
      DetectedEncoding := FFileHelper.DetectFileEncoding(FilePath, HasBOM);

      // Try conversion
      if FEncodingController.ConvertSingleFile(FilePath, FEncodingModel.GetEncodingName(Encoding), True) then
      begin
        Inc(SuccessCount);
        Log('- 成功转换: ' + FilePath + ' (从 ' + DetectedEncoding + ' 到 ' +
          FEncodingModel.GetEncodingName(Encoding) + ')');

        // Update the status of this file in the grid
        UpdateSingleFileInGrid(FilePath);
      end
      else
      begin
        Log('- 转换失败: ' + FilePath);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('批量转换完成: 成功 %d/%d 个文件', [SuccessCount, Length(SelectedFiles)]));

    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('注意: %d 个文件未能成功转换 (可能是非文本文件或无法访问)',
        [Length(SelectedFiles) - SuccessCount]));

    ShowMessage(System.SysUtils.Format('转换完成: 成功 %d/%d 个文件', [SuccessCount, Length(SelectedFiles)]));
  finally
    // Restore cursor
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;

procedure TForm1.MenuItemToggleSelectClick(Sender: TObject);
        begin
  // 全选/取消全选
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.MenuItemViewContentClick(Sender: TObject);
begin
  // 直接调用按钮的点击事件
  btnShowContentClick(Sender);
end;

procedure TForm1.MenuItemCopyFullPathClick(Sender: TObject);
var
  FullPath: string;
begin
  // 确保选中了有效的行
  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;

  // 获取选中的文件全路径
  FullPath := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[1, FSelectedRow];

  // 复制到剪贴板
  Clipboard.AsText := FullPath;

  // 记录日志
  Log('已复制文件全路径到剪贴板: ' + FullPath);
end;

procedure TForm1.StringGrid1Click(Sender: TObject);
var
  Col, Row: Integer;
  Grid: TStringGrid;
  P: TPoint;
begin
  if Sender is TStringGrid then
    Grid := TStringGrid(Sender)
  else
    Exit;
  P := Grid.ScreenToClient(Mouse.CursorPos);

  // 获取当前鼠标位置对应的单元格
  Grid.MouseToCell(P.X, P.Y, Col, Row);

  // 如果点击有效行（不是表头）
  if Row > 0 then
  begin
    // 选中整行
    Grid.Row := Row;
    FSelectedRow := Row;

    // 如果点击第一列（Checkbox列）
    if Col = 0 then
    begin
      // 切换Checkbox状态
      if Grid.Cells[Col, Row] = '√' then
        Grid.Cells[Col, Row] := ''
      else
        Grid.Cells[Col, Row] := '√';
    end;
  end;
end;

procedure TForm1.StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  GridCoord: TGridCoord;
begin
  GridCoord := StringGrid1.MouseCoord(MousePos.X, MousePos.Y);

  // 确保点击的是有效的数据行
  if (GridCoord.Y > 0) and (GridCoord.Y < StringGrid1.RowCount) then
  begin
    StringGrid1.Row := GridCoord.Y;
    FSelectedRow := GridCoord.Y;
    // 显式激活弹出菜单，而不是依赖默认行为
    GridPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end
  else
  begin
    // 禁用上下文菜单
    MenuItemConvertCurrent.Enabled := False;
    MenuItemToggleSelect.Enabled := False;
    MenuItemViewContent.Enabled := False;
    Handled := True;
  end;
end;

procedure TForm1.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // 记录选中的行
  FSelectedRow := ARow;
end;

procedure TForm1.UpdateFileExtensions(const FolderPath: string);
var
  Extensions: TArray<string>;
  i: Integer;
begin
  // 清空CheckListBox
  CheckListBox1.Clear;
  FFileExtensions.Clear;

  // 获取文件夹中的所有扩展名
  Extensions := FFileHelper.GetFileExtensions(FolderPath);

  // 添加到CheckListBox和FFileExtensions
  for i := 0 to High(Extensions) do
        begin
    CheckListBox1.Items.Add(Extensions[i]);
    FFileExtensions.Add(Extensions[i]);

    // 默认选中除了.exe和.dll以外的所有扩展名
    if (Extensions[i] <> '.exe') and (Extensions[i] <> '.dll') then
      CheckListBox1.Checked[i] := True;
  end;
end;

procedure TForm1.UpdateFileGrid(const FolderPath: string);
var
  Files: TArray<string>;
  FileExtensions: TArray<string>;
  i: Integer;
  FileName: string;
  EncodingName: string;
  ExtSelected: Boolean;
  HasBOM: Boolean;
  SelectedFileNames: TStringList; // 用于存储刷新前选中的文件名
  HasSelectedExtensions: Boolean;
begin
  // 保存当前选中的文件，以便在刷新后恢复选择状态
  SelectedFileNames := TStringList.Create;
  try
    // 获取当前选中的文件名
    for i := 1 to StringGrid1.RowCount - 1 do
    begin
      if (StringGrid1.Cells[0, i] = '√') and (StringGrid1.Cells[1, i] <> '') then
        SelectedFileNames.Add(StringGrid1.Cells[1, i]);
    end;

    // 清空表格
    FUIHelper.ClearGrid(StringGrid1);

    // (Fix Deprecation Warning)
    if not System.SysUtils.DirectoryExists(FolderPath) then // Ensure qualified
    begin
      StringGrid1.Cells[1, 1] := '(目录不存在)';
      // 确保列宽正确
      AdjustGridColumnWidths;
      Exit;
    end;

    Screen.Cursor := crHourGlass;
    try
      // 获取选中的文件扩展名
      SetLength(FileExtensions, 0);
      HasSelectedExtensions := False;

      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        if CheckListBox1.Checked[i] then
        begin
          HasSelectedExtensions := True;
          SetLength(FileExtensions, Length(FileExtensions) + 1);
          FileExtensions[High(FileExtensions)] := CheckListBox1.Items[i];
        end;
      end;

      // 如果没有选中任何文件类型，显示提示并退出
      if not HasSelectedExtensions then
      begin
        Log('未选择任何文件类型，不显示文件');
        StringGrid1.Cells[1, 1] := '(请选择至少一种文件类型)';
        // 确保列宽正确
        AdjustGridColumnWidths;
        Exit;
      end;

      // 记录搜索设置
      Log('开始搜索文件: ' + FolderPath + ', 包含子目录: ' + BoolToStr(FIncludeSubdirs, True));

      // 如果包含子目录，在界面上明确提示
      if FIncludeSubdirs then
        Log('【注意】子目录搜索已启用，将包含所有子文件夹中的匹配文件')
      else
        Log('【注意】子目录搜索已禁用，只搜索当前文件夹');

      // 获取文件列表 - 使用FIncludeSubdirs参数
      Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions, FIncludeSubdirs);

      // 添加到表格
      for i := 0 to High(Files) do
      begin
        FileName := ExtractFileName(Files[i]);

        // 检测文件编码
        EncodingName := FFileHelper.DetectFileEncoding(Files[i], HasBOM);

        // 检查该文件是否应该被选中 - 如果之前选中过则继续选中
        ExtSelected := SelectedFileNames.IndexOf(FileName) >= 0;

        // 添加到表格，使用保存的选择状态
        FUIHelper.AddFileToGrid(StringGrid1, FileName, EncodingName, ExtSelected);
      end;

      // 如果没有文件，添加提示
      if StringGrid1.Cells[1, 1] = '' then
        StringGrid1.Cells[1, 1] := '(无文件)';

      // 确保列宽正确
      AdjustGridColumnWidths;
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    SelectedFileNames.Free;
  end;
end;

procedure TForm1.InvalidateForm;
  begin
  // 使用继承的方法重绘窗体
  inherited Invalidate;
  // 强制处理所有消息队列中的事件
  Application.ProcessMessages;
end;

function TForm1.GetLocalizedMessage(const MsgId: string): string;
var
  LangStrings: TLanguageStrings;
  Context: TRttiContext;
  RttiType: TRttiType;
  RttiField: TRttiField;
begin
  // 获取当前语言的字符串
  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

  // 使用现代RTTI获取属性值
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(TypeInfo(TLanguageStrings));
    if Assigned(RttiType) then
    begin
      RttiField := RttiType.GetField(MsgId);
      if Assigned(RttiField) then
      begin
        Result := RttiField.GetValue(@LangStrings).AsString;
        if Result = '' then
          Result := MsgId; // 如果字段值为空，返回消息ID
      end
      else
        Result := MsgId; // 如果字段不存在，返回消息ID
    end
    else
      Result := MsgId; // 如果类型信息不存在，返回消息ID
  finally
    Context.Free;
  end;
end;

function TForm1.GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
begin
  Result := System.SysUtils.Format(GetLocalizedMessage(MsgId), Args);
end;

// 显示本地化的消息对话框
procedure TForm1.ShowLocalizedMessage(const MsgId: string);
var
  Title: string;
begin
  // 获取当前语言的窗口标题
  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;

  // 显示消息对话框
  Application.MessageBox(PChar(GetLocalizedMessage(MsgId)), PChar(Title), MB_OK + MB_ICONINFORMATION);
end;

// 显示格式化的本地化消息对话框
procedure TForm1.ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);
var
  Title: string;
begin
  // 获取当前语言的窗口标题
  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;

  // 显示格式化的消息对话框
  Application.MessageBox(PChar(GetLocalizedMessageFmt(MsgId, Args)), PChar(Title), MB_OK + MB_ICONINFORMATION);
end;

procedure TForm1.UpdateSingleFileInGrid(const FilePath: string);
var
  FileName: string;
  EncodingName: string;
  HasBOM: Boolean;
  i: Integer;
  Found: Boolean;
begin
  // 提取文件名
  FileName := ExtractFileName(FilePath);

  // 检测文件编码
  EncodingName := FFileHelper.DetectFileEncoding(FilePath, HasBOM);

  // 在表格中查找该文件
  Found := False;
  for i := 1 to StringGrid1.RowCount - 1 do
begin
    if StringGrid1.Cells[1, i] = FileName then
begin
      // 更新编码信息
      StringGrid1.Cells[2, i] := EncodingName;
      Found := True;
      Break;
  end;
end;

  // 如果表格中没有该文件，可能需要考虑添加它
  if not Found and (FileName <> '') then
begin
    Log('文件 ' + FileName + ' 转换完成，编码: ' + EncodingName);
  end;
end;

procedure TForm1.btnShowContentClick(Sender: TObject);
var
  SelectedFile: string;
  EncodingInfo: TEncodingInfo;
  DetectedEncoding: string;
  HasBOM: Boolean;
  Encoding: TEncoding;
begin
  // 确保选中了有效的行
  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;

  // 获取选中的文件路径
  SelectedFile := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[1, FSelectedRow];
  if not FileExists(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgFileNotExists', [SelectedFile]);
    Exit;
  end;

  // 检查是否为文本文件
  if not FFileHelper.IsNormalTextFile(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(SelectedFile)]);
    Exit;
  end;

  try
    // 检测文件编码
    Log('正在检测文件编码: ' + SelectedFile);
    HasBOM := False;
    DetectedEncoding := FFileHelper.DetectFileEncoding(SelectedFile, HasBOM);
    Encoding := nil; // 我们将使用名称而不是编码对象

    Log('检测到文件编码: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));

    // 安全地处理先前的实例
    if Assigned(SynEditForm) then
    begin
      // 如果实例已存在，尝试隐藏而非释放
      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('隐藏先前的SynEditForm实例');
        end;
      except
        on E: Exception do
        begin
          Log('隐藏SynEditForm失败: ' + E.Message);
          // 如果隐藏失败，尝试释放
          try
            FreeAndNil(SynEditForm);
            Log('释放先前的SynEditForm实例');
          except
            on E2: Exception do
            begin
              Log('释放SynEditForm失败: ' + E2.Message);
              // 忽略释放错误，继续创建新实例
            end;
          end;
        end;
      end;
    end;

    // 确保实例为空
    if Assigned(SynEditForm) then
    begin
      // 如果实例仍然存在，尝试重用它
      Log('重用现有SynEditForm实例');
    end
    else
    begin
      // 创建新的SynEditForm实例
      Log('正在创建新的SynEditForm实例...');
      try
        Application.CreateForm(TSynEditForm, SynEditForm);
        if not Assigned(SynEditForm) then
        begin
          ShowLocalizedMessage('MsgCannotCreateViewer');
          Log('创建SynEditForm失败: 实例为空');
          Exit;
        end;
        Log('成功创建新的SynEditForm实例');
      except
        on E: Exception do
        begin
          ShowLocalizedMessageFmt('MsgCannotCreateViewer', [E.Message]);
          Log('创建SynEditForm失败: ' + E.Message);
          Exit;
        end;
      end;
    end;

    // 使用实例加载文件
    Log('正在打开文件: ' + SelectedFile);
    try
      // 使用检测到的编码加载文件
      Log('使用检测到的编码加载文件: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));

      // 根据检测到的编码创建相应的TEncoding对象
      var FileEncoding: TEncoding := nil;
      try
        if SameText(DetectedEncoding, 'UTF-8') or SameText(DetectedEncoding, 'UTF-8 with BOM') then
          FileEncoding := TEncoding.UTF8
        else if SameText(DetectedEncoding, 'UTF-16LE') then
          FileEncoding := TEncoding.Unicode
        else if SameText(DetectedEncoding, 'UTF-16BE') then
          FileEncoding := TEncoding.BigEndianUnicode
        else if SameText(DetectedEncoding, 'GBK') or SameText(DetectedEncoding, 'GB2312') then
          FileEncoding := TEncoding.GetEncoding(936) // GBK代码页
        else if SameText(DetectedEncoding, 'BIG5') then
          FileEncoding := TEncoding.GetEncoding(950) // BIG5代码页
        else
          FileEncoding := TEncoding.Default;

        // 使用指定编码加载文件
        SynEditForm.SetFileInfo(SelectedFile, DetectedEncoding, HasBOM);
        SynEditForm.LoadFileWithEncoding(SelectedFile, FileEncoding, DetectedEncoding, HasBOM);
        Log('成功加载文件到SynEditForm，编码: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));
      finally
        // 释放非标准编码对象
        if Assigned(FileEncoding) and
           (FileEncoding <> TEncoding.UTF8) and
           (FileEncoding <> TEncoding.Unicode) and
           (FileEncoding <> TEncoding.BigEndianUnicode) and
           (FileEncoding <> TEncoding.Default) then
          FileEncoding.Free;
      end;
    except
      on E: Exception do
      begin
        ShowLocalizedMessageFmt('MsgCannotLoadFile', [E.Message]);
        Log('LoadFileWithEncoding失败: ' + E.Message);

        // 如果加载失败，尝试使用默认编码
        try
          Log('尝试使用默认编码加载文件...');
          SynEditForm.LoadFile(SelectedFile);
          Log('使用默认编码成功加载文件');
        except
          on E2: Exception do
          begin
            Log('使用默认编码加载文件也失败: ' + E2.Message);
            // 不释放实例，只是退出
            Exit;
          end;
        end;
      end;
    end;

    // 定位窗体在主窗体右侧(如果屏幕空间足够)
    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50; // 略微偏下

      // 调整窗体大小为合理值
      SynEditForm.Width := 800;
      SynEditForm.Height := 600;

      // 显示实例（非模态）
      SynEditForm.Show;
      SynEditForm.BringToFront; // 确保窗口可见
      Log('成功显示文件: ' + SelectedFile);
    except
      on E: Exception do
      begin
        ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
        Log('显示SynEditForm失败: ' + E.Message);
        // 不释放实例，只是记录错误
      end;
    end;
  except
    on E: Exception do
    begin
      ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
      Log('查看文件失败: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnSelectAllExtClick(Sender: TObject);
var
  i: Integer;
  AllChecked, AnyChecked: Boolean;
  SelectedCount: Integer;
  LangStrings: TLanguageStrings;
begin
  try
    // 获取当前语言字符串
    LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

    // 记录操作开始
    Log('选择/取消选择所有文件类型操作开始');

    // 检查是否所有项目都已经选中
    AllChecked := True;
    AnyChecked := False;
    SelectedCount := 0;

    for i := 0 to CheckListBox1.Items.Count - 1 do
    begin
      if CheckListBox1.Checked[i] then
      begin
        AnyChecked := True;
        Inc(SelectedCount);
      end
      else
        AllChecked := False;

      if AnyChecked and not AllChecked then
        Break;
    end;

    // 显示状态信息
    Log('当前状态: 全部选中=' + BoolToStr(AllChecked, True) +
        ', 部分选中=' + BoolToStr(AnyChecked, True) +
        ', 选中数量=' + IntToStr(SelectedCount));

    // 如果所有都选中或部分选中，则全部取消选择
    // 如果都没选中，则全部选择
    if AllChecked or AnyChecked then
    begin
      // 全部取消选择
      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := False;
      end;

      btnSelectAllExt.Caption := '选择所有文件类型';
      Log('已取消选择所有文件类型');
    end
    else
    begin
      // 全部选择
      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := True;
      end;

      btnSelectAllExt.Caption := '取消选择所有文件类型';
      Log('已选择所有文件类型');
    end;

    // 直接调用UpdateFileCountLabel来更新状态显示
    UpdateFileCountLabel;

    // 确保目录有效
    if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
    begin
      // 清空并重新加载文件列表
      Log('强制更新文件列表');
      StringGrid1.RowCount := 2; // 重置表格，只保留标题行
      StringGrid1.Rows[1].Clear(); // 清空第一个数据行

      // 直接更新文件列表
      UpdateFileGrid(DirectoryListBox1.Directory);

      // 记录当前选中的文件类型数量
      SelectedCount := 0;
      for i := 0 to CheckListBox1.Items.Count - 1 do
        if CheckListBox1.Checked[i] then
          Inc(SelectedCount);

      Log('文件列表已更新，当前选中' + IntToStr(SelectedCount) + '种文件类型');

      // 强制更新UI
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log('全选类型按钮操作出错: ' + E.Message);
  end;
end;

procedure TForm1.UpdateFileCountLabel;
var
  i, SelectedCount: Integer;
  TotalFiles: Integer;
begin
  // 计算选中的文件类型数量
  SelectedCount := 0;
  for i := 0 to CheckListBox1.Items.Count - 1 do
    if CheckListBox1.Checked[i] then
      Inc(SelectedCount);

  // 获取总文件数量
  TotalFiles := 0;
  for i := 1 to StringGrid1.RowCount - 1 do
    if (StringGrid1.Cells[1, i] <> '') and
       (StringGrid1.Cells[1, i] <> '(无文件)') and
       (StringGrid1.Cells[1, i] <> '(目录不存在)') and
       (StringGrid1.Cells[1, i] <> '(请选择至少一种文件类型)') then
      Inc(TotalFiles);

  // 输出到日志
  Log('文件类型统计: 已选择 ' + IntToStr(SelectedCount) + '/' +
      IntToStr(CheckListBox1.Items.Count) + ' 种类型，共 ' +
      IntToStr(TotalFiles) + ' 个文件');
end;

procedure TForm1.TreeViewEncodingsAdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; Stage: TCustomDrawStage; var PaintImages,
  DefaultDraw: Boolean);
var
  Tree: TTreeView;
  NewStyle: TFontStyles;
  NewSize: Integer;
begin
  Tree := Sender as TTreeView;

  if Stage = cdPrePaint then
  begin
    NewStyle := [];
    NewSize := FOriginalFontSize; // Start with default

    case Node.Level of
      0: // Root Node ("目标编码")
      begin
        NewStyle := [fsBold];
        NewSize := FOriginalFontSize + 2;
      end;
      1: // Category Node
      begin
        NewStyle := [fsBold];
        NewSize := FOriginalFontSize + 1;
      end;
      2: // Encoding Node
        ;// Keep default style and size
    end;

    // Apply changes only if different from current canvas font
    if (Tree.Canvas.Font.Style <> NewStyle) or (Tree.Canvas.Font.Size <> NewSize) then
    begin
       Tree.Canvas.Font.Style := NewStyle;
       Tree.Canvas.Font.Size := NewSize;
    end;
  end
  else if Stage = cdPostPaint then
  begin
    // Restore default font settings after painting the item
    // Check if it was changed before restoring
    if (Tree.Canvas.Font.Style <> []) or (Tree.Canvas.Font.Size <> FOriginalFontSize) then
    begin
        Tree.Canvas.Font.Style := [];
        Tree.Canvas.Font.Size := FOriginalFontSize;
    end;
  end;
end;

procedure TForm1.SelectUTF8BOMInTreeView;
var
  i: Integer;
  Node: TTreeNode;
  NodeData: Integer;
  NodeLevel: Integer;
begin
  try
    // 遍历TreeView中的所有节点
    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];
      NodeLevel := Node.Level;

      // 检查所有编码节点（非根节点和非分组标题节点）
      // 注意：由于HelperUI.SetupEncodingList的实现，编码节点可能在Level=1或Level=2
      if (NodeLevel > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);

        // 检查是否为UTF-8 BOM节点
        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin
          // 检查编码是否为UTF-8且有BOM
          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (FEncodingModel.Encodings[NodeData].HasBOM) then
          begin
            // 选中该节点
            TreeViewEncodings.Selected := Node;

            // 确保该节点可见（展开父节点）
            Node.MakeVisible;

            // 记录日志
            Log('默认选中编码: ' + Node.Text);

            // 找到后退出循环
            Exit;
          end;
        end;
      end;
    end;

    // 如果没有找到UTF-8 BOM，尝试查找普通UTF-8（无BOM）
    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];

      if (Node.Level > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);

        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin
          // 查找普通UTF-8
          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (not FEncodingModel.Encodings[NodeData].HasBOM) then
          begin
            TreeViewEncodings.Selected := Node;
            Node.MakeVisible;
            Log('没有找到UTF-8 BOM，选中普通UTF-8: ' + Node.Text);
            Exit;
          end;
        end;
      end;
    end;

    Log('未找到UTF-8编码节点，未设置默认编码');
  except
    on E: Exception do
      Log('设置默认编码失败: ' + E.Message);
  end;
end;

procedure TForm1.AdjustGridColumnWidths;
begin
  // 设置列宽
  StringGrid1.ColWidths[0] := 40;        // 选择框列
  StringGrid1.ColWidths[1] := 500;       // 文件名列 (增大到2.5倍)
  StringGrid1.ColWidths[2] := 225;       // 编码列 (增大到1.5倍)

  // 强制重绘
  StringGrid1.Invalidate;
end;

procedure TForm1.InitializeUI;
begin
  // 初始化界面
  FUIHelper.InitStringGrid(StringGrid1);
  FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);

  // 手动调整列宽 (即使InitStringGrid已经设置过，再设置一次确保生效)
  AdjustGridColumnWidths;

  // 默认选中UTF-8 BOM编码
  SelectUTF8BOMInTreeView;

  // 绑定事件
  CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;
  StringGrid1.PopupMenu := GridPopupMenu;
  btnShowContent.OnClick := btnShowContentClick;
  btnSelectAllExt.OnClick := btnSelectAllExtClick;

  // 初始化按钮提示信息
  btnShowContent.Hint := '查看选中文件的内容';
  btnShowContent.ShowHint := True;

  btnSelectAllExt.Hint := '选择或取消选择所有文件类型';
  btnSelectAllExt.ShowHint := True;

  // 应用语言字符串
  ApplyLanguageStrings;

  // 初始化"包含子目录"复选框
  chkIncludeSubdirs.Checked := False;
  FIncludeSubdirs := False;
  chkIncludeSubdirs.OnClick := chkIncludeSubdirsClick;

  // 使用更安全的默认目录
  try
    // 首先尝试使用上次记录的目录（如果有且有效）
    if (FConfig.LastDirectory <> '') and System.SysUtils.DirectoryExists(FConfig.LastDirectory) then
    begin
      Log('使用上次记录的目录: ' + FConfig.LastDirectory);
      FSelectedFolder := FConfig.LastDirectory;
    end
    else
    begin
      // 尝试使用用户文档目录
      try
        FSelectedFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Documents';
        Log('使用用户文档目录: ' + FSelectedFolder);
      except
        // 如果获取环境变量失败，使用程序所在目录
        FSelectedFolder := ExtractFilePath(ParamStr(0));
        Log('使用程序所在目录: ' + FSelectedFolder);
      end;
    end;

    // 最后检查目录是否存在，不存在则使用C盘
    if not System.SysUtils.DirectoryExists(FSelectedFolder) then
    begin
      FSelectedFolder := 'C:\';
      Log('所选目录不存在，使用C盘: ' + FSelectedFolder);
    end;

    // 设置DirectoryListBox的目录 - 放在try..except中
    try
      DirectoryListBox1.Directory := FSelectedFolder;
    except
      on E: Exception do
      begin
        Log('设置目录失败: ' + E.Message);
        // 如果设置目录失败，尝试使用C盘根目录
        try
          FSelectedFolder := 'C:\';
          DirectoryListBox1.Directory := FSelectedFolder;
        except
          Log('无法设置任何目录，程序可能无法正常工作');
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('初始化目录出错: ' + E.Message);
      // 紧急情况，尝试使用C盘
      FSelectedFolder := 'C:\';
      try
        DirectoryListBox1.Directory := FSelectedFolder;
      except
        Log('无法设置目录，忽略此错误并继续');
      end;
    end;
  end;

  // 延迟更新文件列表，避免在初始化阶段产生过多I/O
  try
    // 首先只更新文件扩展名列表，不加载文件
    UpdateFileExtensions(FSelectedFolder);

    // 在表格中显示提示消息
    StringGrid1.Cells[1, 1] := '点击【刷新】按钮加载文件...';
    AdjustGridColumnWidths;

    // 设置一个定时器，在程序启动后X秒再加载文件
    // (这里直接忽略，让用户手动点击刷新按钮)

    // 记录日志，不再自动加载
    Log('界面初始化完成，请点击刷新按钮加载文件列表');
  except
    on E: Exception do
    begin
      Log('初始化文件列表出错: ' + E.Message);
      StringGrid1.Cells[1, 1] := '加载错误，请尝试点击刷新按钮';
      AdjustGridColumnWidths;
    end;
  end;

  // 创建语言选择器，但不强制切换语言
  CreateLanguageSelector;

  // 记录启动日志
  Log('程序已启动，当前语言：' + FCurrentLanguage);

  FOriginalFontSize := TreeViewEncodings.Font.Size;
end;

class procedure TForm1.Initialize;
begin
  // 初始化语言管理器
  ControllerLanguage.InitializeLanguageManager;
end;

procedure TForm1.InitializeLanguageManager;
begin
  // 初始化语言管理器
  ControllerLanguage.InitializeLanguageManager;

  // 记录日志
  Log('语言管理器已初始化');
end;

procedure TForm1.CreateLanguageSelector;
var
  i: Integer;
  LangFile: string;
  FoundLanguages: Integer;
begin
  // 清空语言选择框
  ComboBox1.Items.Clear;
  ComboBox1.Items.AddObject('English', TObject(1)); // 默认添加英语
  FoundLanguages := 1;

  // 记录日志
  Log('开始搜索语言文件，目录: ' + IniDir);

  // 根据LANGUAGE_MAPPINGS去查找相应的ini文件
  for i := 0 to High(LANGUAGE_MAPPINGS) do
  begin
    LangFile := IniDir + '\' + LANGUAGE_MAPPINGS[i].LanguageCode + '.ini';

    // 记录日志
    Log('检查语言文件: ' + LangFile);

    if FileExists(LangFile) then
    begin
      // 找到语言文件，添加到语言选择框
      ComboBox1.Items.AddObject(LANGUAGE_MAPPINGS[i].DisplayName, TObject(i));
      Inc(FoundLanguages);

      // 记录日志
      Log('找到语言文件: ' + LANGUAGE_MAPPINGS[i].LanguageCode + ' - ' + LANGUAGE_MAPPINGS[i].DisplayName);
    end
    else
    begin
      // 记录日志
      Log('未找到语言文件: ' + LANGUAGE_MAPPINGS[i].LanguageCode);
    end;
  end;

  // 选中中文项（如果存在）
  if ComboBox1.Items.Count > 0 then
  begin
    // 默认选中第一项
    ComboBox1.ItemIndex := 0;

    // 尝试找到中文项并选中
    for i := 0 to ComboBox1.Items.Count - 1 do
    begin
      if Integer(ComboBox1.Items.Objects[i]) < High(LANGUAGE_MAPPINGS) then
      begin
        if LANGUAGE_MAPPINGS[Integer(ComboBox1.Items.Objects[i])].LanguageCode = 'zh-CN' then
        begin
          ComboBox1.ItemIndex := i;
          // 切换到中文
          SwitchToLanguageCode('zh-CN');
          Log('自动切换到中文');
          Break;
        end;
      end;
    end;
  end;

  // 记录日志
  Log('语言选择器已创建，找到 ' + IntToStr(FoundLanguages) + ' 种语言');
  Log('当前选中语言: ' + ComboBox1.Text);
end;

procedure TForm1.ApplyLanguageStrings;
var
  LangStrings: TLanguageStrings;
begin
  // 获取当前语言的字符串
  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

  // 应用到界面
  Self.Caption := LangStrings.WindowTitle;
  btnConvert.Caption := LangStrings.BtnConvert;
  btnSingleFile.Caption := LangStrings.BtnSingleFile;
  btnRefresh.Caption := LangStrings.BtnRefresh;
  btnClose.Caption := LangStrings.BtnClose;
  btnToggleSelect.Caption := LangStrings.BtnToggleSelect;
  Label1.Caption := LangStrings.LanguageGroupCaption;
  StringGrid1.Cells[0, 0] := LangStrings.FileSelectColumn;
  StringGrid1.Cells[1, 0] := LangStrings.FileNameColumn;
  StringGrid1.Cells[2, 0] := LangStrings.EncodingColumn;

  // 菜单项
  MenuItemConvert.Caption := LangStrings.PopupMenuConvert;
  MenuItemToggleSelect.Caption := LangStrings.PopupMenuToggleSelect;
  MenuItemConvertCurrent.Caption := LangStrings.BtnSingleFile;
  MenuItemConvertAllFiles.Caption := LangStrings.BtnConvert;
  MenuItemViewContent.Caption := LangStrings.BtnPreview;

  // 复选框
  chkIncludeSubdirs.Caption := LangStrings.ChkIncludeSubdirs;

  // 其他按钮
  btnSelectAllExt.Caption := LangStrings.BtnAllFileTypes;
  btnShowContent.Caption := LangStrings.BtnCheckContent;

  // 重建编码树视图以更新语言显示
  TreeViewEncodings.Items.BeginUpdate;
  try
    // 记住选中的编码
    var SelectedEncoding: Integer := -1;
    if TreeViewEncodings.Selected <> nil then
      SelectedEncoding := Integer(TreeViewEncodings.Selected.Data);

    // 清空并重新构建编码列表
    FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);

    // 如果之前有选中的编码，尝试恢复选择
    if SelectedEncoding >= 0 then
    begin
      // 尝试查找并选中之前选中的节点
      for var i := 0 to TreeViewEncodings.Items.Count - 1 do
      begin
        var Node := TreeViewEncodings.Items[i];
        if (Node.Level > 0) and (Integer(Node.Data) >= 0) and
           (Integer(Node.Data) = SelectedEncoding) then
        begin
          TreeViewEncodings.Selected := Node;
          Node.MakeVisible;
          Log('已恢复选中的编码节点');
          Break;
        end;
      end;
    end
    else
    begin
      // 如果之前没有选中节点，默认选中UTF-8 BOM
      SelectUTF8BOMInTreeView;
    end;
  finally
    TreeViewEncodings.Items.EndUpdate;
  end;

  // 记录日志
  Log('已应用语言字符串: ' + FCurrentLanguage);
end;

procedure TForm1.SwitchToLanguageCode(const LangCode: string);
var
  LangInfo: TLanguageInfo;
  i: Integer;
begin
  // 输出详细日志帮助调试
  Log('尝试切换到语言: ' + LangCode);

  // 设置语言
  ControllerLanguage.SetLanguage(LangCode);
  FCurrentLanguage := LangCode;

  // 应用语言字符串（此方法中已包含重建编码列表的逻辑）
  ApplyLanguageStrings;

  // 更新语言选择器选中项
  LangInfo := ControllerLanguage.GetLanguageInfo(LangCode);
  for i := 0 to ComboBox1.Items.Count - 1 do
  begin
    if ComboBox1.Items[i] = LangInfo.NativeName then
    begin
      ComboBox1.ItemIndex := i;
      Break;
    end;
  end;
end;

procedure TForm1.ShowFileContent(const FileName: string; Encoding: TEncoding; const DetectedEncoding: string; HasBOM: Boolean);
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgFileNotExists', [FileName]));
    Exit;
  end;

  // 检查是否为文本文件
  if not FFileHelper.IsNormalTextFile(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(FileName)]));
    Exit;
  end;

  try
    // 创建SynEditForm实例（如果尚未创建）
    if not Assigned(SynEditForm) then
    begin
      try
        Application.CreateForm(TSynEditForm, SynEditForm);
      except
        on E: Exception do
        begin
          ShowMessage('无法创建文件查看器: ' + E.Message);
          Log('创建SynEditForm失败: ' + E.Message);
          Exit;
        end;
      end;
    end;

    // 直接加载文件内容，SynEdit会自动处理编码
    try
      SynEditForm.LoadFile(FileName);
    except
      on E: Exception do
      begin
        ShowMessage('无法加载文件: ' + E.Message);
        Log('SynEditForm.LoadFile失败: ' + E.Message);
        Exit;
      end;
    end;

    // 定位窗体在主窗体右侧(如果屏幕空间足够)
    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50; // 略微偏下

      // 调整窗体大小为合理值
      SynEditForm.Width := 800;
      SynEditForm.Height := 600;

      // 显示窗体(非模态)
      SynEditForm.Show;

      // 记录日志
      Log('已打开文件: ' + FileName);
    except
      on E: Exception do
      begin
        ShowMessage('显示窗体时发生错误: ' + E.Message);
        Log('显示SynEditForm失败: ' + E.Message);
      end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('无法打开文件: ' + E.Message);
      Log('打开文件失败: ' + E.Message);
    end;
  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // 如果按下Shift+Ctrl+W组合键，则调整表格列宽
  if (Key = Ord('W')) and (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    AdjustGridColumnWidths;
    Log('表格列宽已调整');
    Key := 0; // 防止按键继续处理
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 安全释放全局的SynEditForm实例
  try
    if Assigned(SynEditForm) then
    begin
      // 首先尝试隐藏窗体
      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('已隐藏SynEditForm窗体');
          Application.ProcessMessages; // 给系统一些时间处理隐藏操作
          Sleep(100); // 等待一下，确保窗体已隐藏
        end;
      except
        on E: Exception do
        begin
          Log('隐藏SynEditForm失败: ' + E.Message);
          // 即使隐藏失败也继续尝试释放
        end;
      end;

      // 然后尝试释放实例
      try
        // 使用Release而非Free，让VCL在下一个消息循环中释放实例
        SynEditForm.Release;
        SynEditForm := nil;
        Log('已释放SynEditForm实例');
      except
        on E: Exception do
        begin
          Log('释放SynEditForm失败: ' + E.Message);
          // 如果Release失败，尝试使用FreeAndNil
          try
            FreeAndNil(SynEditForm);
            Log('使用FreeAndNil释放SynEditForm实例');
          except
            on E2: Exception do
              Log('使用FreeAndNil释放SynEditForm也失败: ' + E2.Message);
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('关闭时处理SynEditForm失败: ' + E.Message);
      // 忽略最终错误，确保主窗体可以关闭
    end;
  end;
end;

procedure TForm1.chkIncludeSubdirsClick(Sender: TObject);
begin
  // 更新子目录包含状态
  FIncludeSubdirs := chkIncludeSubdirs.Checked;

  // 记录状态变化并在界面上提供清晰的反馈
  if FIncludeSubdirs then
  begin
    Log('已启用子目录搜索 - 将包含所有子文件夹中的文件');
    ShowLocalizedMessage('MsgSubdirEnabled');
  end
  else
    Log('已禁用子目录搜索 - 只搜索当前文件夹');

  // 更新文件列表以反映子目录包含状态
  Screen.Cursor := crHourGlass;
  try
    UpdateFileGrid(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
  end;

  // 在日志中显示文件数量信息
  Log('文件列表已更新，当前共显示 ' + IntToStr(StringGrid1.RowCount - 1) + ' 个文件');
end;


end.