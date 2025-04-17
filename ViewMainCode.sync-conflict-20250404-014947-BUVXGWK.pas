unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, System.IOUtils, System.UITypes, Vcl.FileCtrl, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Grids, System.Math, Vcl.CheckLst, System.Types, Vcl.Menus, System.Rtti,
  System.StrUtils, UtilsTypes, ModelEncoding, ModelConfig, HelperUI, HelperFiles, 
  ControllerEncoding, HelperLanguage, Winapi.ShlObj, ViewSynEdit;

type
  // 语言包装器类
  TLanguageWrapper = class
  public
    function GetLanguageStrings(Language: TAppLanguage): TLanguageStrings;
  end;

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
    ListBox1: TListBox;
    MemLog: TMemo;
    Splitter7: TSplitter;
    Splitter8: TSplitter;
    CheckListBox1: TCheckListBox;
    GridPopupMenu: TPopupMenu;
    MenuItemConvert: TMenuItem;
    MenuItemToggleSelect: TMenuItem;
    MenuItemConvertCurrent: TMenuItem;
    MenuItemConvertAllFiles: TMenuItem;
    N1: TMenuItem;
    Panel8: TPanel;
    btnConvert: TButton;
    btnSingleFile: TButton;
    btnRefresh: TButton;
    btnClose: TButton;
    btnToggleSelect: TButton;
    btnSelectUP: TButton;
    Label1: TLabel;
    ComboBox1: TComboBox;
    procedure btnCloseClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
    procedure btnSingleFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DirectoryListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure StringGrid1Click(Sender: TObject);
    procedure DriveComboBox1Change(Sender: TObject);
    procedure MenuItemConvertClick(Sender: TObject);
    procedure StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuItemToggleSelectClick(Sender: TObject);
    procedure btnToggleSelectClick(Sender: TObject);
    procedure MenuItemConvertCurrentClick(Sender: TObject);
    procedure MenuItemConvertAllFilesClick(Sender: TObject);
    procedure btnSelectUPClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FSelectedFolder: string;
    FSelectedRow: Integer;
    FFileExtensions: TStringList;
    FLanguageComboBox: TComboBox;
    FLanguageWrapper: TLanguageWrapper;
    
    // MVC架构组件
    FConfig: TAppConfig;
    FEncodingModel: TEncodingModel;
    FEncodingController: TEncodingController;
    FUIHelper: TUIHelper;
    FFileHelper: TFileHelper;
    
    procedure UpdateFileGrid(const FolderPath: string);
    procedure UpdateFileExtensions(const FolderPath: string);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    
    // 日志记录
    procedure Log(const Msg: string);
    
    // 表单刷新处理
    procedure InvalidateForm;
    procedure InvalidateControl(Control: TControl);
    
    // 语言设置
    {$WARNINGS OFF}
    procedure SetLanguage(Language: TAppLanguage);
    {$WARNINGS ON}
    procedure ApplyLanguageStrings;
    procedure CreateLanguageSelector;
    procedure SwitchToLanguageCode(const LangCode: string);
    procedure InitializeLanguageManager;
    function GetLanguageEnumName(Language: TAppLanguage): string;
    
    procedure UpdateSingleFileInGrid(const FilePath: string);
    
    FStringGridPopupMenu: TPopupMenu;
    procedure OnViewFileClick(Sender: TObject);
    procedure CreateStringGridPopupMenu;
    
    procedure btnShowContentClick(Sender: TObject);
    procedure btnSelectAllExtClick(Sender: TObject);
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // 语言相关公开方法
    procedure OnLanguageChange(const LangCode: string);
    function GetLanguageStrings(Language: TAppLanguage): TLanguageStrings;
    procedure SwitchToChinese;

    class procedure Execute;
    class procedure Initialize;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TLanguageWrapper }

function TLanguageWrapper.GetLanguageStrings(Language: TAppLanguage): TLanguageStrings;
begin
  if Assigned(Form1) then
    Result := Form1.GetLanguageStrings(Language)
  else
    FillChar(Result, SizeOf(Result), 0);
end;

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // 初始化成员
  FSelectedRow := -1;
  FFileExtensions := TStringList.Create;
  
  // 初始化MVC架构组件
  FConfig := TAppConfig.Create;
  FEncodingModel := TEncodingModel.Create;
  FUIHelper := TUIHelper.Create;
  
  // 初始化语言包装器
  FLanguageWrapper := TLanguageWrapper.Create;
  
  // 创建适配器函数来处理TProc<string>和procedure之间的转换
  FFileHelper := TFileHelper.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );
  
  FEncodingController := TEncodingController.Create(
    TProc<string>(
      procedure(const LogMsg: string)
  begin
        Log(LogMsg);
      end
    )
  );
  
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
  
  // 释放语言包装器
  FLanguageWrapper.Free;
  
  FFileExtensions.Free;
  inherited;
end;

procedure TForm1.InitializeLanguageManager;
begin
  // 初始化语言管理器
  if not Assigned(LanguageManager) then
    LanguageManager := TLanguageManager.Create;
    
  // 初始化语言管理器
  LanguageManager.Initialize;
  
  // 确保强制重新加载语言
  LanguageManager.LoadAvailableLanguages;
  
  // 设置语言回调
  LanguageManager.GetLanguageStringsCallback := FLanguageWrapper.GetLanguageStrings;
  
  // 设置语言变更事件
  LanguageManager.OnLanguageChange := OnLanguageChange;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
begin
  // 再次初始化语言管理器
  InitializeLanguageManager;
  
  // 创建语言选择器
  CreateLanguageSelector;
  
  // 注意：不再强制切换到中文，保持设计时状态
  // 应用当前语言，但不强制改变当前语言
  ApplyLanguageStrings;
  
  // 强制立即应用语言
  Application.ProcessMessages;
  
  // 给窗体及组件一点点时间来处理更新请求
  Sleep(100);
  
  // 再次强制更新所有UI元素
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;
      
  // 强制重绘整个窗体
  InvalidateForm;
  
  // 记录日志
  Log('程序界面已显示，当前语言：' + LanguageManager.GetLanguageNameByCode(LanguageManager.CurrentLanguage));
  Log('主窗体标题: ' + Caption);
  Log('按钮状态检查: ' + btnConvert.Caption);
end;

procedure TForm1.ApplyLanguageStrings;
var
  LangStrings: TLanguageStrings;
begin
  // 获取当前语言的字符串
  LangStrings := LanguageManager.GetLanguageStrings(LanguageManager.CurrentLanguage);
  
  // 记录语言切换
  Log('切换语言: ' + LanguageManager.GetLanguageNameByCode(LanguageManager.CurrentLanguage));
  
  // 应用到界面
  Self.Caption := LangStrings.WindowTitle;
  
  // 按钮文本
  btnConvert.Caption := LangStrings.BtnConvert;
  btnSingleFile.Caption := LangStrings.BtnSingleFile;
  btnRefresh.Caption := LangStrings.BtnRefresh;
  btnClose.Caption := LangStrings.BtnClose;
  btnToggleSelect.Caption := LangStrings.BtnToggleSelect;
  btnSelectUP.Caption := '↑'; // 保持箭头
  
  // 标签文本
  Label1.Caption := LangStrings.LanguageGroupCaption;
  
  // 表格标题
  StringGrid1.Cells[0, 0] := LangStrings.FileSelectColumn;
  StringGrid1.Cells[1, 0] := LangStrings.FileNameColumn;
  StringGrid1.Cells[2, 0] := LangStrings.EncodingColumn;
  
  // 菜单项
  MenuItemConvert.Caption := LangStrings.PopupMenuConvert;
  MenuItemToggleSelect.Caption := LangStrings.PopupMenuToggleSelect;
  MenuItemConvertCurrent.Caption := LangStrings.BtnSingleFile;
  MenuItemConvertAllFiles.Caption := LangStrings.BtnConvert;
  
  // 强制更新控件文本
  InvalidateControl(btnConvert);
  InvalidateControl(btnSingleFile);
  InvalidateControl(btnRefresh);
  InvalidateControl(btnClose);
  InvalidateControl(btnToggleSelect);
  
  // 刷新表格
  InvalidateControl(StringGrid1);
  
  // 刷新整个界面
  InvalidateForm;
  
  // 在日志中显示所有可见按钮的文本状态，帮助调试
  Log('按钮文本: 转换=' + btnConvert.Caption + 
      ', 单文件=' + btnSingleFile.Caption + 
      ', 刷新=' + btnRefresh.Caption + 
      ', 关闭=' + btnClose.Caption);
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.btnConvertClick(Sender: TObject);
var
  FolderPath: string;
  TargetEncoding: TEncoding;
  WithBOM: Boolean;
  FileExtensions: TArray<string>;
  Files: TArray<string>;
  i: Integer;
begin
  FolderPath := FSelectedFolder;
  
  // 确保文件夹路径有效
  if not System.SysUtils.DirectoryExists(FolderPath) then
  begin
    Log('请选择有效的文件夹');
    Exit;
  end;
  
  // 获取选中的编码
  WithBOM := False;
  TargetEncoding := FEncodingModel.GetEncodingByIndex(ListBox1.ItemIndex, WithBOM);
  
  // 获取文件扩展名过滤
  SetLength(FileExtensions, 0);
    for i := 0 to CheckListBox1.Items.Count - 1 do
    begin
      if CheckListBox1.Checked[i] then
      begin
      SetLength(FileExtensions, Length(FileExtensions) + 1);
      FileExtensions[High(FileExtensions)] := CheckListBox1.Items[i];
        end;
      end;
  
  // 获取要转换的文件列表
  Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions);
  
  if Length(Files) = 0 then
  begin
    Log('当前目录下没有符合条件的文件可转换');
    Exit;
  end;
  
  // 显示转换开始信息
  Log('开始转换文件夹: ' + FolderPath + '，共' + IntToStr(Length(Files)) + '个文件');
  
  // 执行转换
  Screen.Cursor := crHourGlass;
  try
    FEncodingController.ConvertFilesToEncoding(FolderPath, FileExtensions, nil, TargetEncoding, WithBOM);
    
    // 逐个更新已转换文件的编码信息
    for i := 0 to High(Files) do
      begin
      UpdateSingleFileInGrid(Files[i]);
      
      // 每10个文件更新一次界面，避免卡顿
      if (i mod 10 = 0) and (i > 0) then
        Application.ProcessMessages;
    end;
    
    // 显示转换结果
    Log('文件夹转换完成: 共处理' + IntToStr(Length(Files)) + '个文件');
    finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
  begin
    Screen.Cursor := crHourGlass;
    try
      UpdateFileGrid(FSelectedFolder);
    finally
      Screen.Cursor := crDefault;
  end;
end;

procedure TForm1.btnSelectUPClick(Sender: TObject);
var
  CurrentPath, ParentPath: string;
begin
  CurrentPath := DirectoryListBox1.Directory;
  ParentPath := ExtractFileDir(ExcludeTrailingPathDelimiter(CurrentPath));
  
  if ParentPath <> CurrentPath then
  begin
    DirectoryListBox1.Directory := ParentPath;
    UpdateFileGrid(ParentPath);
  end;
end;

procedure TForm1.btnSingleFileClick(Sender: TObject);
var
  SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding;
  WithBOM: Boolean;
  SelectedFileName: string;
  FullFilePath: string;
begin
  // 确保有文件被选中
  if FSelectedRow <= 0 then
  begin
    Log('请选择一个文件');
    Exit;
  end;

  // 确保选定行有有效的文件名
  SelectedFileName := StringGrid1.Cells[1, FSelectedRow];
  if (SelectedFileName = '') or (SelectedFileName = '(无文件)') or 
     (SelectedFileName = '(访问被拒绝)') then
  begin
    Log('无效的文件名或文件无法访问');
    Exit;
  end;

  // 获取选中的编码
  WithBOM := False;
  TargetEncoding := FEncodingModel.GetEncodingByIndex(ListBox1.ItemIndex, WithBOM);
  
  // 创建完整文件路径
  FullFilePath := IncludeTrailingPathDelimiter(FSelectedFolder) + SelectedFileName;
  SetLength(SelectedFiles, 1);
  SelectedFiles[0] := FullFilePath;
  
  // 确保文件存在且可访问
  if not FileExists(FullFilePath) then
  begin
    Log('文件不存在: ' + FullFilePath);
        Exit;
      end;
  
  try
    // 尝试打开文件以确保可访问
    with TFileStream.Create(FullFilePath, fmOpenRead or fmShareDenyNone) do
      Free;
        except
          on E: Exception do
          begin
      Log('无法访问文件: ' + SelectedFileName + ' - ' + E.Message);
      Exit;
    end;
  end;
  
  // 执行单文件转换
  Log('开始转换单个文件: ' + FullFilePath);
  FEncodingController.ConvertSelectedFilesToEncoding(SelectedFiles, TargetEncoding, WithBOM);
  
  // 只更新被转换文件的编码状态，而不是整个目录
  UpdateSingleFileInGrid(FullFilePath);
  
  // 记录完成信息
  Log('单文件转换完成: ' + SelectedFileName);
end;

procedure TForm1.btnToggleSelectClick(Sender: TObject);
begin
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin
  // 当CheckListBox1的项目被选中或取消选中时更新文件列表
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.cmbLanguageChange(Sender: TObject);
var
  LangInfos: TArray<TLanguageInfo>;
  Index: Integer;
  LangCode: string;
  IsChineseSelected: Boolean;
begin
  // 获取选中的语言
  Index := FLanguageComboBox.ItemIndex;
  if Index < 0 then
  begin
    Log('警告: 无效的语言索引');
    Exit;
  end;
  
  // 获取语言代码
  LangInfos := LanguageManager.GetLanguageList;
  if Index >= Length(LangInfos) then
  begin
    Log('警告: 语言索引超出范围');
    Exit;
  end;

  LangCode := LangInfos[Index].Code;
  
  // 检查是否选择的是中文
  IsChineseSelected := (LangCode = 'zh-CN');
  
  // 记录用户选择的语言
  Log('用户选择语言: ' + LangInfos[Index].NativeName + ' (' + LangCode + ')');
  
  // 如果用户选择的是简体中文，则直接调用SwitchToChinese
  if IsChineseSelected then
begin
    Log('直接调用SwitchToChinese方法');
    SwitchToChinese;
  end
  else
  begin
    // 否则使用常规的语言切换
    Log('切换到其他语言: ' + LangCode);
    SwitchToLanguageCode(LangCode);
  end;
  
  // 检查按钮文本是否已更新
  Log('语言切换后的按钮文本: 转换=' + btnConvert.Caption);
  
  // 确保界面及时刷新
  Application.ProcessMessages;
end;

procedure TForm1.CreateLanguageSelector;
var
  LangInfos: TArray<TLanguageInfo>;
  i: Integer;
begin
  // 初始化语言管理器
  if not Assigned(LanguageManager) then
    LanguageManager := TLanguageManager.Create;
    
  // 使用窗体上已有的ComboBox1控件
  FLanguageComboBox := ComboBox1;
  FLanguageComboBox.Style := csDropDownList;
  FLanguageComboBox.Tag := 1000; // 特殊标记，用于识别这是语言选择器
  
  // 清空已有项
  FLanguageComboBox.Items.Clear();
  
  // 添加事件处理
  FLanguageComboBox.OnChange := cmbLanguageChange;
  
  // 获取可用语言列表并填充下拉框
  LanguageManager.LoadAvailableLanguages;
  LangInfos := LanguageManager.GetLanguageList;
  
  Log('发现' + IntToStr(Length(LangInfos)) + '种语言');
  
  for i := 0 to High(LangInfos) do
  begin
    // 添加语言到下拉框，显示本地化名称
    FLanguageComboBox.Items.Add(LangInfos[i].NativeName);
    
    // 如果是当前语言，设置为选中
    if LangInfos[i].Code = LanguageManager.CurrentLanguage then
  begin
      FLanguageComboBox.ItemIndex := i;
      Log('当前语言: ' + LangInfos[i].NativeName + ' (' + LangInfos[i].Code + ')');
  end;
end;

  // 如果没有设置选中项，默认选择第一个
  if (FLanguageComboBox.ItemIndex < 0) and (FLanguageComboBox.Items.Count > 0) then
    FLanguageComboBox.ItemIndex := 0;
    
  // 确保语言选择框可见
  FLanguageComboBox.Visible := True;
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
  // 初始化界面
  FUIHelper.InitStringGrid(StringGrid1);
  FUIHelper.SetupEncodingList(ListBox1, FEncodingModel);
  
  // 绑定事件
  CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;
  
  // 读取上次使用的目录
  if FConfig.LastDirectory <> '' then
  begin
    try
      DirectoryListBox1.Directory := FConfig.LastDirectory;
      FSelectedFolder := FConfig.LastDirectory;
    except
      // 如果上次目录不可用，使用文档目录
      FSelectedFolder := FFileHelper.GetMyDocumentsPath;
      DirectoryListBox1.Directory := FSelectedFolder;
    end;
      end
      else
      begin
    // 使用文档目录作为默认
    FSelectedFolder := FFileHelper.GetMyDocumentsPath;
    DirectoryListBox1.Directory := FSelectedFolder;
  end;
  
  // 更新文件列表
  UpdateFileExtensions(FSelectedFolder);
  UpdateFileGrid(FSelectedFolder);
  
  // 创建语言选择器，但不强制切换语言
  CreateLanguageSelector;
  
  // 创建StringGrid的右键菜单
  CreateStringGridPopupMenu;
  
  // 设置按钮事件
  btnShowContent.OnClick := btnShowContentClick;
  btnSelectAllExt.OnClick := btnSelectAllExtClick;
  
  // 记录启动日志
  Log('程序已启动，当前语言：' + LanguageManager.GetLanguageNameByCode(LanguageManager.CurrentLanguage));
end;

class procedure TForm1.Initialize;
    begin
  // 初始化语言管理器
  if not Assigned(LanguageManager) then
    LanguageManager := TLanguageManager.Create;
    
  // 初始化语言管理器
  LanguageManager.Initialize;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
    begin
  // 当用户点击ListBox1中的项目时触发
  // 如果点击的是组标题，取消选择
  if (ListBox1.ItemIndex >= 0) and (ListBox1.ItemIndex < FEncodingModel.EncodingCount) then
    begin
    if FEncodingModel.Encodings[ListBox1.ItemIndex].IsGroup then
      ListBox1.ItemIndex := -1;
      end;
    end;

procedure TForm1.ListBox1DrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    begin
  // 使用UIHelper绘制编码列表项
  FUIHelper.DrawEncodingListItem(Control, Index, Rect, State, FEncodingModel.EncodingList);
end;

procedure TForm1.Log(const Msg: string);
        begin
  // 使用UIHelper添加日志
  FUIHelper.AppendLog(MemLog, Msg);
end;

procedure TForm1.MenuItemConvertAllFilesClick(Sender: TObject);
          begin
  // 转换所有文件
  btnConvertClick(Sender);
end;

procedure TForm1.MenuItemConvertClick(Sender: TObject);
var
  SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding;
  WithBOM: Boolean;
  i: Integer;
        begin
  // 获取选中的文件
  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);
  
  // 确保有文件被选中
  if Length(SelectedFiles) = 0 then
    begin
    Log('请选择至少一个文件');
    Exit;
  end;
  
  // 获取选中的编码
  WithBOM := False;
  TargetEncoding := FEncodingModel.GetEncodingByIndex(ListBox1.ItemIndex, WithBOM);
  
  // 转换选中的文件
  Log('开始转换选中的' + IntToStr(Length(SelectedFiles)) + '个文件');
  FEncodingController.ConvertSelectedFilesToEncoding(SelectedFiles, TargetEncoding, WithBOM);
  
  // 只更新被转换文件的编码状态
  for i := 0 to High(SelectedFiles) do
    begin
    UpdateSingleFileInGrid(SelectedFiles[i]);
  end;
  
  // 记录完成信息
  Log('选中文件转换完成，共' + IntToStr(Length(SelectedFiles)) + '个文件');
end;

procedure TForm1.MenuItemConvertCurrentClick(Sender: TObject);
begin
  // 转换单个文件
  btnSingleFileClick(Sender);
end;

procedure TForm1.MenuItemToggleSelectClick(Sender: TObject);
        begin
  // 全选/取消全选
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.OnLanguageChange(const LangCode: string);
var
  LangInfos: TArray<TLanguageInfo>;
  i: Integer;
begin
  // 记录被调用
  Log('OnLanguageChange被调用: ' + LangCode);

  // 立即应用界面文本更新
  ApplyLanguageStrings;
  
  // 更新语言选择框的选中项
  LangInfos := LanguageManager.GetLanguageList;
  for i := 0 to High(LangInfos) do
begin
    if LangInfos[i].Code = LangCode then
  begin
      if FLanguageComboBox.ItemIndex <> i then
      begin
        Log('更新语言下拉框选中项: ' + LangInfos[i].NativeName);
        FLanguageComboBox.ItemIndex := i;
      end;
      Break;
  end;
end;

  // 强制更新所有控件文本
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;
      
  // 更新客户区
  InvalidateForm;
  
  // 检查按钮文本
  Log('OnLanguageChange后的按钮文本: 转换=' + btnConvert.Caption);
end;

procedure TForm1.SetLanguage(Language: TAppLanguage);
var
  LangCode: string;
begin
  // 获取语言代码
  LangCode := GetLanguageCodeByEnum(Language);
  
  // 设置语言
  LanguageManager.SetLanguage(LangCode);
  
  // 立即应用语言更新
  ApplyLanguageStrings;
end;

procedure TForm1.StringGrid1Click(Sender: TObject);
var
  Col, Row: Integer;
  Grid: TStringGrid;
  P: TPoint;
begin
  Grid := TStringGrid(Sender);
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
  Grid: TStringGrid;
  Col, Row: Integer;
        begin
  Grid := TStringGrid(Sender);
  Grid.MouseToCell(MousePos.X, MousePos.Y, Col, Row);
  
  // 如果右键点击有效行
  if Row > 0 then
    begin
    Grid.Row := Row;
    FSelectedRow := Row;
    GridPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
    Handled := True;
  end;
end;

procedure TForm1.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // 记录选中的行
  FSelectedRow := ARow;
end;

procedure TForm1.SwitchToLanguageCode(const LangCode: string);
var
  LangEnum: TAppLanguage;
begin
  // 输出详细日志帮助调试
  Log('尝试切换到语言: ' + LangCode + ' (' + LanguageManager.GetLanguageNameByCode(LangCode) + ')');
  
  // 获取语言枚举
  LangEnum := GetLanguageEnumByCode(LangCode);
  Log('语言枚举值: ' + GetLanguageEnumName(LangEnum));
  
  // 确保我们有正确的语言字符串
  if LangEnum = alChinese then
    begin
    // 设置语言
    LanguageManager.SetLanguage(LangCode);
    
    // 强制中文设置 - 一种情况是直接显式设置字符串
    Log('强制应用中文界面文本');
    Self.Caption := 'UTF-8 BOM 编码转换器';
    btnConvert.Caption := '转换所有';
    btnSingleFile.Caption := '单个文件';
    btnRefresh.Caption := '刷新';
    btnClose.Caption := '关闭';
    btnToggleSelect.Caption := '全选/取消全选';
    Label1.Caption := '语言';
    StringGrid1.Cells[0, 0] := '选择';
    StringGrid1.Cells[1, 0] := '文件名';
    StringGrid1.Cells[2, 0] := '当前编码';
    
    MenuItemConvert.Caption := '转换选中文件';
    MenuItemToggleSelect.Caption := '全选/取消全选';
    MenuItemConvertCurrent.Caption := '单个文件';
    MenuItemConvertAllFiles.Caption := '转换所有';
      end
      else
      begin
    // 设置语言
    LanguageManager.SetLanguage(LangCode);
    
    // 应用语言
    ApplyLanguageStrings;
  end;
  
  // 确保界面及时刷新
  Application.ProcessMessages;
  
  // 记录日志
  Log('已切换到语言: ' + LanguageManager.GetLanguageNameByCode(LangCode));
  Log('按钮文本状态: 转换=' + btnConvert.Caption);
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
    
    if not System.SysUtils.DirectoryExists(FolderPath) then
      Exit;
      
    Screen.Cursor := crHourGlass;
    try
  // 获取选中的文件扩展名
      SetLength(FileExtensions, 0);
  for i := 0 to CheckListBox1.Items.Count - 1 do
  begin
    if CheckListBox1.Checked[i] then
    begin
          SetLength(FileExtensions, Length(FileExtensions) + 1);
          FileExtensions[High(FileExtensions)] := CheckListBox1.Items[i];
    end;
  end;
  
      // 获取文件列表
      Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions);
      
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
        
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    SelectedFileNames.Free;
  end;
end;

function TForm1.GetLanguageStrings(Language: TAppLanguage): TLanguageStrings;
  begin
  // 记录语言字符串请求
  if FConfig <> nil then
    Log('请求语言字符串: ' + GetLanguageEnumName(Language));
  
  // 根据不同语言返回不同的界面字符串
  case Language of
    alChinese:
      begin
        Result.WindowTitle := 'UTF-8 BOM 编码转换器';
        Result.BtnConvert := '转换所有';
        Result.BtnSingleFile := '单个文件';
        Result.BtnRefresh := '刷新';
        Result.BtnClose := '关闭';
        Result.BtnToggleSelect := '全选/取消全选';
        Result.LanguageGroupCaption := '语言';
        Result.DirectoryListBoxLabel := '目录';
        Result.FileListLabel := '文件列表';
        Result.CurrentEncodingLabel := '当前编码';
        Result.FileSelectColumn := '选择';
        Result.FileNameColumn := '文件名';
        Result.EncodingColumn := '当前编码';
        Result.PopupMenuConvert := '转换选中文件';
        Result.PopupMenuToggleSelect := '全选/取消全选';
        Result.NoFilesText := '(无文件)';
        Result.ReadErrorText := '(读取错误)';
        Result.LogSelectedDirectory := '选择的目录: ';
      end;
    alEnglish:
begin
        Result.WindowTitle := 'UTF-8 BOM Encoding Converter';
        Result.BtnConvert := 'Convert All';
        Result.BtnSingleFile := 'Single File';
        Result.BtnRefresh := 'Refresh';
        Result.BtnClose := 'Close';
        Result.BtnToggleSelect := 'Select/Deselect All';
        Result.LanguageGroupCaption := 'Language';
        Result.DirectoryListBoxLabel := 'Directory';
        Result.FileListLabel := 'File List';
        Result.CurrentEncodingLabel := 'Current Encoding';
        Result.FileSelectColumn := 'Select';
        Result.FileNameColumn := 'Filename';
        Result.EncodingColumn := 'Current Encoding';
        Result.PopupMenuConvert := 'Convert Selected Files';
        Result.PopupMenuToggleSelect := 'Select/Deselect All';
        Result.NoFilesText := '(No Files)';
        Result.ReadErrorText := '(Read Error)';
        Result.LogSelectedDirectory := 'Selected Directory: ';
      end;
    else
      // 输出未知语言的警告
      if FConfig <> nil then
        Log('警告: 未知语言类型，默认使用英语');
        
      // 默认使用英语
      Result := GetLanguageStrings(alEnglish);
  end;
end;

procedure TForm1.SwitchToChinese;
var
  i: Integer;
  LangInfos: TArray<TLanguageInfo>;
begin
  // 设置语言为中文
  SetLanguage(alChinese);
  
  // 直接设置按钮文本
  btnConvert.Caption := '转换所有';
  btnSingleFile.Caption := '单个文件';
  btnRefresh.Caption := '刷新';
  btnClose.Caption := '关闭';
  btnToggleSelect.Caption := '全选/取消全选';
  Label1.Caption := '语言';
  
  // 表格标题
  StringGrid1.Cells[0, 0] := '选择';
  StringGrid1.Cells[1, 0] := '文件名';
  StringGrid1.Cells[2, 0] := '当前编码';
  
  // 如果FLanguageComboBox已创建，选择中文选项
  if Assigned(FLanguageComboBox) then
begin
    LangInfos := LanguageManager.GetLanguageList;
    for i := 0 to High(LangInfos) do
begin
      if LangInfos[i].Code = 'zh-CN' then
      begin
        FLanguageComboBox.ItemIndex := i;
        Break;
      end;
    end;
  end;
  
  // 确保界面文本更新
  ApplyLanguageStrings;
  
  // 强制处理所有消息队列中的事件
  Application.ProcessMessages;
  
  // 强制重绘所有控件
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;
  
  // 强制重绘窗体
  InvalidateForm;
  
  // 记录日志
  Log('已切换到中文界面');
  Log('按钮文本: 转换=' + btnConvert.Caption + 
      ', 单文件=' + btnSingleFile.Caption + 
      ', 刷新=' + btnRefresh.Caption + 
      ', 关闭=' + btnClose.Caption);
end;

procedure TForm1.InvalidateForm;
  begin
  // 使用继承的方法重绘窗体
  inherited Invalidate;
  // 强制处理所有消息队列中的事件
  Application.ProcessMessages;
end;

procedure TForm1.InvalidateControl(Control: TControl);
begin
  // 空方法，只是保留调用结构
  // 在某些版本的Delphi中，控件会自动刷新
end;

function TForm1.GetLanguageEnumName(Language: TAppLanguage): string;
  begin
  case Language of
    alChinese: Result := 'alChinese';
    alEnglish: Result := 'alEnglish';
    else Result := '未知语言类型(' + IntToStr(Ord(Language)) + ')';
    end;
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

procedure TForm1.OnViewFileClick(Sender: TObject);
var
  RowIndex: Integer;
  FileName, FullPath: string;
begin
  // 获取当前选择的行
  RowIndex := StringGrid1.Row;
  
  // 检查是否有有效的选择
  if (RowIndex <= 0) or (RowIndex >= StringGrid1.RowCount) then
    Exit;
    
  // 获取文件名
  FileName := StringGrid1.Cells[1, RowIndex];
  
  // 如果是无文件或错误信息，退出
  if (FileName = '') or 
     (FileName = FLanguageStrings.NoFilesText) or 
     (FileName = FLanguageStrings.ReadErrorText) then
    Exit;
    
  // 构建完整路径
  FullPath := IncludeTrailingPathDelimiter(FSelectedFolder) + FileName;
  
  // 如果文件不存在，显示错误
  if not FileExists(FullPath) then
  begin
    ShowMessage('文件不存在: ' + FullPath);
    Exit;
  end;
  
  // 创建并显示SynEdit窗体
  if not Assigned(FormSynEdit) then
    FormSynEdit := TFormSynEdit.Create(Application);
    
  // 设置文件名并显示窗体
  FormSynEdit.FileName := FullPath;
  FormSynEdit.Show;
end;

procedure TForm1.CreateStringGridPopupMenu;
var
  MenuItem: TMenuItem;
begin
  // 创建弹出菜单
  FStringGridPopupMenu := TPopupMenu.Create(Self);
  
  // 添加"使用SynEdit查看"菜单项
  MenuItem := TMenuItem.Create(FStringGridPopupMenu);
  MenuItem.Caption := '使用SynEdit查看文件';
  MenuItem.OnClick := OnViewFileClick;
  FStringGridPopupMenu.Items.Add(MenuItem);
  
  // 设置StringGrid1的PopupMenu属性
  StringGrid1.PopupMenu := FStringGridPopupMenu;
end;

procedure TForm1.btnShowContentClick(Sender: TObject);
var
  SelectedRow: Integer;
  FullPath: string;
begin
  SelectedRow := StringGrid1.Row;
  
  // 检查是否选择了有效的行
  if (SelectedRow < 1) or (SelectedRow >= StringGrid1.RowCount) then
  begin
    ShowMessage('请先选择一个文件');
    Exit;
  end;
  
  // 获取完整文件路径
  FullPath := StringGrid1.Cells[4, SelectedRow];
  
  // 检查文件是否存在
  if not FileExists(FullPath) then
  begin
    ShowMessage('文件不存在: ' + FullPath);
    Exit;
  end;
  
  // 打开SynEdit查看窗口
  with TFormSynEdit.Create(Self) do
  try
    FileName := FullPath;
    ShowModal;
  finally
    Free;
  end;
end;

procedure TForm1.btnSelectAllExtClick(Sender: TObject);
var
  I: Integer;
  AllChecked: Boolean;
begin
  // 检查是否所有项都已选中
  AllChecked := True;
  for I := 0 to CheckListBox1.Items.Count - 1 do
  begin
    if not CheckListBox1.Checked[I] then
    begin
      AllChecked := False;
      Break;
    end;
  end;
  
  // 根据当前状态切换选中状态
  for I := 0 to CheckListBox1.Items.Count - 1 do
    CheckListBox1.Checked[I] := not AllChecked;
  
  // 刷新文件列表
  btnRefreshClick(nil);
end;

end.
