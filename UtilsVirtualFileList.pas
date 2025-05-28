unit UtilsVirtualFileList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls,
  Vcl.ComCtrls, Vcl.Graphics, System.Generics.Collections, System.Types,
  System.UITypes, Vcl.Forms, Vcl.ImgList, Vcl.Menus, UtilsVirtualListView;

type
  /// <summary>
  /// 文件项数据
  /// </summary>
  TFileItem = class
  private
    FFileName: string;
    FFilePath: string;
    FFileSize: Int64;
    FFileDate: TDateTime;
    FEncoding: string;
    FHasBOM: Boolean;
    FSelected: Boolean;
    FTag: NativeInt;
  public
    constructor Create;
    
    property FileName: string read FFileName write FFileName;
    property FilePath: string read FFilePath write FFilePath;
    property FileSize: Int64 read FFileSize write FFileSize;
    property FileDate: TDateTime read FFileDate write FFileDate;
    property Encoding: string read FEncoding write FEncoding;
    property HasBOM: Boolean read FHasBOM write FHasBOM;
    property Selected: Boolean read FSelected write FSelected;
    property Tag: NativeInt read FTag write FTag;
  end;

  /// <summary>
  /// 文件项获取事件
  /// </summary>
  TGetFileItemEvent = procedure(Sender: TObject; ItemIndex: Integer; var Item: TFileItem) of object;

  /// <summary>
  /// 文件项选择事件
  /// </summary>
  TFileItemSelectEvent = procedure(Sender: TObject; Item: TFileItem) of object;

  /// <summary>
  /// 文件项双击事件
  /// </summary>
  TFileItemDblClickEvent = procedure(Sender: TObject; Item: TFileItem) of object;

  /// <summary>
  /// 虚拟文件列表
  /// </summary>
  TVirtualFileList = class(TCustomControl)
  private
    FListView: TVirtualListView;
    FFiles: TObjectList<TFileItem>;
    FOnGetFileItem: TGetFileItemEvent;
    FOnFileItemSelect: TFileItemSelectEvent;
    FOnFileItemDblClick: TFileItemDblClickEvent;
    FVirtualMode: Boolean;
    FShowCheckboxes: Boolean;
    FShowIcons: Boolean;
    FImageList: TImageList;
    FDefaultFileIcon: Integer;
    FDefaultFolderIcon: Integer;
    FUpdateCount: Integer;
    
    procedure SetVirtualMode(const Value: Boolean);
    procedure SetShowCheckboxes(const Value: Boolean);
    procedure SetShowIcons(const Value: Boolean);
    function GetSelectedCount: Integer;
    function GetSelectedItems(Index: Integer): TFileItem;
    function GetItemCount: Integer;
    function GetItem(Index: Integer): TFileItem;
    procedure SetItem(Index: Integer; const Value: TFileItem);
    procedure ListViewGetVirtualItem(Sender: TObject; ItemIndex: Integer; var Item: TVirtualListItem);
    procedure ListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ListViewDblClick(Sender: TObject);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure UpdateListViewItem(Index: Integer);
    procedure InitializeListView;
    procedure InitializeImageList;
    procedure LoadSystemIcons;
  protected
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    /// <summary>
    /// 开始更新
    /// </summary>
    procedure BeginUpdate;
    
    /// <summary>
    /// 结束更新
    /// </summary>
    procedure EndUpdate;
    
    /// <summary>
    /// 清空所有项
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// 添加文件项
    /// </summary>
    function AddFile(const FileName, FilePath, Encoding: string; HasBOM: Boolean = False): TFileItem;
    
    /// <summary>
    /// 插入文件项
    /// </summary>
    function InsertFile(Index: Integer; const FileName, FilePath, Encoding: string; HasBOM: Boolean = False): TFileItem;
    
    /// <summary>
    /// 删除文件项
    /// </summary>
    procedure DeleteFile(Index: Integer);
    
    /// <summary>
    /// 获取选中的文件项索引
    /// </summary>
    function GetSelectedIndex: Integer;
    
    /// <summary>
    /// 设置选中的文件项索引
    /// </summary>
    procedure SetSelectedIndex(Index: Integer);
    
    /// <summary>
    /// 确保文件项可见
    /// </summary>
    procedure EnsureVisible(Index: Integer);
    
    /// <summary>
    /// 获取文件项索引
    /// </summary>
    function IndexOfFile(const FileName, FilePath: string): Integer;
    
    /// <summary>
    /// 更新文件项
    /// </summary>
    procedure UpdateFile(Index: Integer);
    
    /// <summary>
    /// 全选
    /// </summary>
    procedure SelectAll;
    
    /// <summary>
    /// 全不选
    /// </summary>
    procedure SelectNone;
    
    /// <summary>
    /// 反选
    /// </summary>
    procedure InvertSelection;
    
    /// <summary>
    /// 获取选中的文件项数量
    /// </summary>
    property SelectedCount: Integer read GetSelectedCount;
    
    /// <summary>
    /// 获取选中的文件项
    /// </summary>
    property SelectedItems[Index: Integer]: TFileItem read GetSelectedItems;
    
    /// <summary>
    /// 获取或设置文件项
    /// </summary>
    property Items[Index: Integer]: TFileItem read GetItem write SetItem;
    
    /// <summary>
    /// 获取文件项数量
    /// </summary>
    property ItemCount: Integer read GetItemCount;
    
    /// <summary>
    /// 列表视图
    /// </summary>
    property ListView: TVirtualListView read FListView;
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property BorderWidth;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    
    /// <summary>
    /// 虚拟模式
    /// </summary>
    property VirtualMode: Boolean read FVirtualMode write SetVirtualMode;
    
    /// <summary>
    /// 显示复选框
    /// </summary>
    property ShowCheckboxes: Boolean read FShowCheckboxes write SetShowCheckboxes;
    
    /// <summary>
    /// 显示图标
    /// </summary>
    property ShowIcons: Boolean read FShowIcons write SetShowIcons;
    
    /// <summary>
    /// 获取文件项事件
    /// </summary>
    property OnGetFileItem: TGetFileItemEvent read FOnGetFileItem write FOnGetFileItem;
    
    /// <summary>
    /// 文件项选择事件
    /// </summary>
    property OnFileItemSelect: TFileItemSelectEvent read FOnFileItemSelect write FOnFileItemSelect;
    
    /// <summary>
    /// 文件项双击事件
    /// </summary>
    property OnFileItemDblClick: TFileItemDblClickEvent read FOnFileItemDblClick write FOnFileItemDblClick;
    
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  Winapi.ShellAPI, Winapi.CommCtrl, System.IOUtils, System.Math;

{ TFileItem }

constructor TFileItem.Create;
begin
  inherited Create;
  FSelected := False;
  FTag := 0;
end;

{ TVirtualFileList }

function TVirtualFileList.AddFile(const FileName, FilePath, Encoding: string;
  HasBOM: Boolean): TFileItem;
begin
  Result := TFileItem.Create;
  Result.FileName := FileName;
  Result.FilePath := FilePath;
  Result.Encoding := Encoding;
  Result.HasBOM := HasBOM;
  
  // 获取文件信息
  if FileExists(FilePath + FileName) then
  begin
    var FileInfo: TSearchRec;
    if FindFirst(FilePath + FileName, faAnyFile, FileInfo) = 0 then
    begin
      try
        Result.FileSize := FileInfo.Size;
        Result.FileDate := FileInfo.TimeStamp;
      finally
        FindClose(FileInfo);
      end;
    end;
  end;
  
  // 添加到文件列表
  FFiles.Add(Result);
  
  // 更新列表视图
  if not FVirtualMode then
  begin
    var Item := FListView.AddItem(FileName);
    Item.SubItems.Add(Encoding);
    Item.SubItems.Add(FilePath);
    Item.SubItems.Add(FormatFloat('#,##0', Result.FileSize));
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.FileDate));
    Item.SubItems.Add(BoolToStr(HasBOM, True));
  end
  else
  begin
    FListView.VirtualItemCount := FFiles.Count;
    FListView.Refresh;
  end;
end;

procedure TVirtualFileList.BeginUpdate;
begin
  Inc(FUpdateCount);
  FListView.BeginUpdate;
end;

procedure TVirtualFileList.Clear;
begin
  FFiles.Clear;
  FListView.Clear;
end;

constructor TVirtualFileList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // 创建文件列表
  FFiles := TObjectList<TFileItem>.Create(True);
  
  // 创建列表视图
  FListView := TVirtualListView.Create(Self);
  FListView.Parent := Self;
  FListView.Align := alClient;
  FListView.ViewStyle := vsReport;
  FListView.RowSelect := True;
  FListView.GridLines := True;
  FListView.ShowColumnHeaders := True;
  FListView.OnGetVirtualItem := ListViewGetVirtualItem;
  FListView.OnSelectItem := ListViewSelectItem;
  FListView.OnDblClick := ListViewDblClick;
  FListView.OnKeyDown := ListViewKeyDown;
  FListView.OnColumnClick := ListViewColumnClick;
  
  // 初始化属性
  FVirtualMode := False;
  FShowCheckboxes := False;
  FShowIcons := True;
  FUpdateCount := 0;
  
  // 初始化列表视图
  InitializeListView;
  
  // 初始化图像列表
  InitializeImageList;
  
  // 加载系统图标
  LoadSystemIcons;
  
  // 设置控件大小
  Width := 400;
  Height := 300;
end;

procedure TVirtualFileList.CreateWnd;
begin
  inherited;
end;

procedure TVirtualFileList.DeleteFile(Index: Integer);
begin
  if (Index >= 0) and (Index < FFiles.Count) then
  begin
    FFiles.Delete(Index);
    
    if not FVirtualMode then
      FListView.DeleteItem(Index)
    else
    begin
      FListView.VirtualItemCount := FFiles.Count;
      FListView.Refresh;
    end;
  end;
end;

destructor TVirtualFileList.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TVirtualFileList.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
    FListView.EndUpdate;
end;

procedure TVirtualFileList.EnsureVisible(Index: Integer);
begin
  FListView.EnsureVisible(Index);
end;

function TVirtualFileList.GetItem(Index: Integer): TFileItem;
begin
  if (Index >= 0) and (Index < FFiles.Count) then
    Result := FFiles[Index]
  else
    Result := nil;
end;

function TVirtualFileList.GetItemCount: Integer;
begin
  Result := FFiles.Count;
end;

function TVirtualFileList.GetSelectedCount: Integer;
var
  i: Integer;
  Count: Integer;
begin
  Count := 0;
  
  for i := 0 to FFiles.Count - 1 do
    if FFiles[i].Selected then
      Inc(Count);
      
  Result := Count;
end;

function TVirtualFileList.GetSelectedIndex: Integer;
begin
  Result := FListView.GetSelectedIndex;
end;

function TVirtualFileList.GetSelectedItems(Index: Integer): TFileItem;
var
  i, Count: Integer;
begin
  Result := nil;
  Count := -1;
  
  for i := 0 to FFiles.Count - 1 do
  begin
    if FFiles[i].Selected then
    begin
      Inc(Count);
      if Count = Index then
      begin
        Result := FFiles[i];
        Break;
      end;
    end;
  end;
end;

function TVirtualFileList.IndexOfFile(const FileName, FilePath: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  
  for i := 0 to FFiles.Count - 1 do
  begin
    if (FFiles[i].FileName = FileName) and (FFiles[i].FilePath = FilePath) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TVirtualFileList.InitializeImageList;
begin
  // 创建图像列表
  FImageList := TImageList.Create(Self);
  FImageList.Width := 16;
  FImageList.Height := 16;
  FImageList.ColorDepth := cd32Bit;
  
  // 设置列表视图的图像列表
  FListView.SmallImages := FImageList;
end;

procedure TVirtualFileList.InitializeListView;
begin
  // 添加列
  with FListView.Columns.Add do
  begin
    Caption := '选择';
    Width := 50;
    Alignment := taCenter;
  end;
  
  with FListView.Columns.Add do
  begin
    Caption := '编码';
    Width := 100;
    Alignment := taLeftJustify;
  end;
  
  with FListView.Columns.Add do
  begin
    Caption := '文件名';
    Width := 200;
    Alignment := taLeftJustify;
  end;
  
  with FListView.Columns.Add do
  begin
    Caption := '大小';
    Width := 80;
    Alignment := taRightJustify;
  end;
  
  with FListView.Columns.Add do
  begin
    Caption := '修改日期';
    Width := 150;
    Alignment := taLeftJustify;
  end;
  
  with FListView.Columns.Add do
  begin
    Caption := 'BOM';
    Width := 50;
    Alignment := taCenter;
  end;
end;

procedure TVirtualFileList.InvertSelection;
var
  i: Integer;
begin
  BeginUpdate;
  try
    for i := 0 to FFiles.Count - 1 do
    begin
      FFiles[i].Selected := not FFiles[i].Selected;
      UpdateListViewItem(i);
    end;
  finally
    EndUpdate;
  end;
end;

function TVirtualFileList.InsertFile(Index: Integer; const FileName, FilePath,
  Encoding: string; HasBOM: Boolean): TFileItem;
begin
  // 确保索引有效
  if Index < 0 then
    Index := 0;
  if Index > FFiles.Count then
    Index := FFiles.Count;
    
  // 创建文件项
  Result := TFileItem.Create;
  Result.FileName := FileName;
  Result.FilePath := FilePath;
  Result.Encoding := Encoding;
  Result.HasBOM := HasBOM;
  
  // 获取文件信息
  if FileExists(FilePath + FileName) then
  begin
    var FileInfo: TSearchRec;
    if FindFirst(FilePath + FileName, faAnyFile, FileInfo) = 0 then
    begin
      try
        Result.FileSize := FileInfo.Size;
        Result.FileDate := FileInfo.TimeStamp;
      finally
        FindClose(FileInfo);
      end;
    end;
  end;
  
  // 插入到文件列表
  FFiles.Insert(Index, Result);
  
  // 更新列表视图
  if not FVirtualMode then
  begin
    var Item := FListView.InsertItem(Index, FileName);
    Item.SubItems.Add(Encoding);
    Item.SubItems.Add(FilePath);
    Item.SubItems.Add(FormatFloat('#,##0', Result.FileSize));
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.FileDate));
    Item.SubItems.Add(BoolToStr(HasBOM, True));
  end
  else
  begin
    FListView.VirtualItemCount := FFiles.Count;
    FListView.Refresh;
  end;
end;

procedure TVirtualFileList.ListViewColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  // 排序功能可以在这里实现
end;

procedure TVirtualFileList.ListViewDblClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := FListView.GetSelectedIndex;
  
  if (Index >= 0) and (Index < FFiles.Count) and Assigned(FOnFileItemDblClick) then
    FOnFileItemDblClick(Self, FFiles[Index]);
end;

procedure TVirtualFileList.ListViewGetVirtualItem(Sender: TObject;
  ItemIndex: Integer; var Item: TVirtualListItem);
var
  FileItem: TFileItem;
begin
  if (ItemIndex >= 0) and (ItemIndex < FFiles.Count) then
  begin
    // 使用缓存的文件项
    FileItem := FFiles[ItemIndex];
    
    // 如果在虚拟模式下有回调，调用回调
    if FVirtualMode and Assigned(FOnGetFileItem) then
    begin
      var TempItem: TFileItem := nil;
      FOnGetFileItem(Self, ItemIndex, TempItem);
      
      if TempItem <> nil then
        FileItem := TempItem;
    end;
    
    // 创建列表项
    if Item = nil then
      Item := TVirtualListItem.Create;
      
    // 设置列表项属性
    Item.Caption := FileItem.Selected ? '√' : '';
    Item.SubItems.Clear;
    Item.SubItems.Add(FileItem.Encoding);
    Item.SubItems.Add(FileItem.FileName);
    Item.SubItems.Add(FormatFloat('#,##0', FileItem.FileSize));
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', FileItem.FileDate));
    Item.SubItems.Add(BoolToStr(FileItem.HasBOM, True));
    
    // 设置图标
    if FShowIcons then
    begin
      if DirectoryExists(FileItem.FilePath + FileItem.FileName) then
        Item.ImageIndex := FDefaultFolderIcon
      else
        Item.ImageIndex := FDefaultFileIcon;
    end
    else
      Item.ImageIndex := -1;
  end;
end;

procedure TVirtualFileList.ListViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // 处理键盘事件
  case Key of
    VK_SPACE:
      begin
        // 空格键切换选中状态
        var Index := FListView.GetSelectedIndex;
        if (Index >= 0) and (Index < FFiles.Count) then
        begin
          FFiles[Index].Selected := not FFiles[Index].Selected;
          UpdateListViewItem(Index);
          
          if Assigned(FOnFileItemSelect) then
            FOnFileItemSelect(Self, FFiles[Index]);
        end;
      end;
  end;
end;

procedure TVirtualFileList.ListViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Index: Integer;
begin
  if Selected and (Item <> nil) then
  begin
    Index := Item.Index;
    
    if (Index >= 0) and (Index < FFiles.Count) and Assigned(FOnFileItemSelect) then
      FOnFileItemSelect(Self, FFiles[Index]);
  end;
end;

procedure TVirtualFileList.Loaded;
begin
  inherited;
end;

procedure TVirtualFileList.LoadSystemIcons;
var
  SysImageList: THandle;
  SFI: TSHFileInfo;
  Icon: TIcon;
begin
  // 获取系统图标列表
  SysImageList := SHGetFileInfo('', 0, SFI, SizeOf(SFI), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  
  if SysImageList <> 0 then
  begin
    // 获取默认文件图标
    SHGetFileInfo('.txt', 0, SFI, SizeOf(SFI), SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
    Icon := TIcon.Create;
    try
      Icon.Handle := ImageList_GetIcon(SysImageList, SFI.iIcon, ILD_NORMAL);
      FDefaultFileIcon := FImageList.AddIcon(Icon);
    finally
      Icon.Free;
    end;
    
    // 获取默认文件夹图标
    SHGetFileInfo('', FILE_ATTRIBUTE_DIRECTORY, SFI, SizeOf(SFI), SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
    Icon := TIcon.Create;
    try
      Icon.Handle := ImageList_GetIcon(SysImageList, SFI.iIcon, ILD_NORMAL);
      FDefaultFolderIcon := FImageList.AddIcon(Icon);
    finally
      Icon.Free;
    end;
  end;
end;

procedure TVirtualFileList.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
end;

procedure TVirtualFileList.Resize;
begin
  inherited;
end;

procedure TVirtualFileList.SelectAll;
var
  i: Integer;
begin
  BeginUpdate;
  try
    for i := 0 to FFiles.Count - 1 do
    begin
      FFiles[i].Selected := True;
      UpdateListViewItem(i);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TVirtualFileList.SelectNone;
var
  i: Integer;
begin
  BeginUpdate;
  try
    for i := 0 to FFiles.Count - 1 do
    begin
      FFiles[i].Selected := False;
      UpdateListViewItem(i);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TVirtualFileList.SetItem(Index: Integer; const Value: TFileItem);
begin
  if (Index >= 0) and (Index < FFiles.Count) then
  begin
    FFiles[Index] := Value;
    UpdateListViewItem(Index);
  end;
end;

procedure TVirtualFileList.SetSelectedIndex(Index: Integer);
begin
  FListView.SetSelectedIndex(Index);
end;

procedure TVirtualFileList.SetShowCheckboxes(const Value: Boolean);
begin
  if FShowCheckboxes <> Value then
  begin
    FShowCheckboxes := Value;
    FListView.Checkboxes := Value;
  end;
end;

procedure TVirtualFileList.SetShowIcons(const Value: Boolean);
begin
  if FShowIcons <> Value then
  begin
    FShowIcons := Value;
    FListView.Refresh;
  end;
end;

procedure TVirtualFileList.SetVirtualMode(const Value: Boolean);
begin
  if FVirtualMode <> Value then
  begin
    FVirtualMode := Value;
    FListView.VirtualMode := Value;
    
    if FVirtualMode then
      FListView.VirtualItemCount := FFiles.Count;
  end;
end;

procedure TVirtualFileList.UpdateFile(Index: Integer);
begin
  if (Index >= 0) and (Index < FFiles.Count) then
    UpdateListViewItem(Index);
end;

procedure TVirtualFileList.UpdateListViewItem(Index: Integer);
begin
  if (Index >= 0) and (Index < FFiles.Count) then
  begin
    if not FVirtualMode then
    begin
      // 更新标准列表视图项
      if (Index < FListView.Items.Count) then
      begin
        FListView.Items[Index].Caption := FFiles[Index].Selected ? '√' : '';
        
        // 确保子项数量足够
        while FListView.Items[Index].SubItems.Count < 5 do
          FListView.Items[Index].SubItems.Add('');
          
        FListView.Items[Index].SubItems[0] := FFiles[Index].Encoding;
        FListView.Items[Index].SubItems[1] := FFiles[Index].FileName;
        FListView.Items[Index].SubItems[2] := FormatFloat('#,##0', FFiles[Index].FileSize);
        FListView.Items[Index].SubItems[3] := FormatDateTime('yyyy-mm-dd hh:nn:ss', FFiles[Index].FileDate);
        FListView.Items[Index].SubItems[4] := BoolToStr(FFiles[Index].HasBOM, True);
      end;
    end
    else
    begin
      // 在虚拟模式下刷新显示
      FListView.Refresh;
    end;
  end;
end;

end.
