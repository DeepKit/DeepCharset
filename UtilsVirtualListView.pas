unit UtilsVirtualListView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls,
  Vcl.ComCtrls, Vcl.Graphics, System.Generics.Collections, System.Types,
  System.UITypes, Vcl.Forms, Vcl.ImgList, Vcl.Menus;

type
  /// <summary>
  /// 虚拟列表项数据
  /// </summary>
  TVirtualListItem = class
  private
    FCaption: string;
    FSubItems: TStringList;
    FImageIndex: Integer;
    FStateIndex: Integer;
    FChecked: Boolean;
    FData: TObject;
    FTag: NativeInt;
  public
    constructor Create;
    destructor Destroy; override;
    
    property Caption: string read FCaption write FCaption;
    property SubItems: TStringList read FSubItems;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
    property StateIndex: Integer read FStateIndex write FStateIndex;
    property Checked: Boolean read FChecked write FChecked;
    property Data: TObject read FData write FData;
    property Tag: NativeInt read FTag write FTag;
  end;

  /// <summary>
  /// 虚拟列表项获取事件
  /// </summary>
  TGetVirtualItemEvent = procedure(Sender: TObject; ItemIndex: Integer; var Item: TVirtualListItem) of object;

  /// <summary>
  /// 虚拟列表视图
  /// </summary>
  TVirtualListView = class(TCustomListView)
  private
    FItems: TObjectList<TVirtualListItem>;
    FVirtualItemCount: Integer;
    FOnGetVirtualItem: TGetVirtualItemEvent;
    FVirtualMode: Boolean;
    FLastVisibleItem: Integer;
    FFirstVisibleItem: Integer;
    FVisibleItems: TDictionary<Integer, TVirtualListItem>;
    FDefaultItem: TVirtualListItem;
    FUpdateCount: Integer;
    FNeedRebuild: Boolean;
    
    procedure SetVirtualItemCount(const Value: Integer);
    procedure SetVirtualMode(const Value: Boolean);
    procedure UpdateVisibleItems;
    procedure RebuildVisibleItems;
    function GetVisibleItemCount: Integer;
    function GetVisibleItem(Index: Integer): TVirtualListItem;
    function GetItem(Index: Integer): TVirtualListItem;
    procedure SetItem(Index: Integer; const Value: TVirtualListItem);
    function GetItemCount: Integer;
    procedure CNNotify(var Message: TWMNotify); message CN_NOTIFY;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function OwnerDataFetch(Item: TListItem; Request: TItemRequest): Boolean; override;
    function OwnerDataFind(Find: TItemFind; const FindString: string; const FindPosition: TPoint; FindData: Pointer; StartIndex: Integer; Direction: TSearchDirection; Wrap: Boolean): Integer; override;
    function OwnerDataHint(StartIndex, EndIndex: Integer): Boolean; override;
    function CustomDrawItem(Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean): Boolean; override;
    function CustomDrawSubItem(Item: TListItem; SubItem: Integer; State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean): Boolean; override;
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
    /// 添加项
    /// </summary>
    function AddItem(const Caption: string; ImageIndex: Integer = -1): TVirtualListItem;
    
    /// <summary>
    /// 插入项
    /// </summary>
    function InsertItem(Index: Integer; const Caption: string; ImageIndex: Integer = -1): TVirtualListItem;
    
    /// <summary>
    /// 删除项
    /// </summary>
    procedure DeleteItem(Index: Integer);
    
    /// <summary>
    /// 获取选中的项索引
    /// </summary>
    function GetSelectedIndex: Integer;
    
    /// <summary>
    /// 设置选中的项索引
    /// </summary>
    procedure SetSelectedIndex(Index: Integer);
    
    /// <summary>
    /// 确保项可见
    /// </summary>
    procedure EnsureVisible(Index: Integer);
    
    /// <summary>
    /// 获取可见项数量
    /// </summary>
    property VisibleItemCount: Integer read GetVisibleItemCount;
    
    /// <summary>
    /// 获取可见项
    /// </summary>
    property VisibleItems[Index: Integer]: TVirtualListItem read GetVisibleItem;
    
    /// <summary>
    /// 获取或设置项
    /// </summary>
    property Items[Index: Integer]: TVirtualListItem read GetItem write SetItem;
    
    /// <summary>
    /// 获取项数量
    /// </summary>
    property ItemCount: Integer read GetItemCount;
    
    /// <summary>
    /// 虚拟项数量
    /// </summary>
    property VirtualItemCount: Integer read FVirtualItemCount write SetVirtualItemCount;
    
    /// <summary>
    /// 虚拟模式
    /// </summary>
    property VirtualMode: Boolean read FVirtualMode write SetVirtualMode;
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property BorderWidth;
    property Checkboxes;
    property Color;
    property Columns;
    property ColumnClick;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FlatScrollBars;
    property FullDrag;
    property GridLines;
    property HideSelection;
    property HotTrack;
    property HotTrackStyles;
    property HoverTime;
    property IconOptions;
    property Items;
    property LargeImages;
    property MultiSelect;
    property OwnerData;
    property OwnerDraw;
    property ReadOnly;
    property RowSelect;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowColumnHeaders;
    property ShowWorkAreas;
    property ShowHint;
    property SmallImages;
    property SortType;
    property StateImages;
    property TabOrder;
    property TabStop;
    property ViewStyle;
    property Visible;
    
    property OnAdvancedCustomDraw;
    property OnAdvancedCustomDrawItem;
    property OnAdvancedCustomDrawSubItem;
    property OnChange;
    property OnChanging;
    property OnClick;
    property OnColumnClick;
    property OnColumnDragged;
    property OnColumnRightClick;
    property OnCompare;
    property OnContextPopup;
    property OnCustomDraw;
    property OnCustomDrawItem;
    property OnCustomDrawSubItem;
    property OnData;
    property OnDataFind;
    property OnDataHint;
    property OnDataStateChange;
    property OnDblClick;
    property OnDeletion;
    property OnDrawItem;
    property OnEdited;
    property OnEditing;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetImageIndex;
    property OnGetSubItemImage;
    property OnDragDrop;
    property OnDragOver;
    property OnInfoTip;
    property OnInsert;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnSelectItem;
    property OnStartDock;
    property OnStartDrag;
    
    /// <summary>
    /// 获取虚拟项事件
    /// </summary>
    property OnGetVirtualItem: TGetVirtualItemEvent read FOnGetVirtualItem write FOnGetVirtualItem;
  end;

implementation

{ TVirtualListItem }

constructor TVirtualListItem.Create;
begin
  inherited Create;
  FSubItems := TStringList.Create;
  FImageIndex := -1;
  FStateIndex := -1;
  FChecked := False;
  FData := nil;
  FTag := 0;
end;

destructor TVirtualListItem.Destroy;
begin
  FSubItems.Free;
  inherited;
end;

{ TVirtualListView }

function TVirtualListView.AddItem(const Caption: string; ImageIndex: Integer): TVirtualListItem;
begin
  Result := TVirtualListItem.Create;
  Result.Caption := Caption;
  Result.ImageIndex := ImageIndex;
  FItems.Add(Result);
  
  if not FVirtualMode then
  begin
    Items.Add.Caption := Caption;
    Items[Items.Count - 1].ImageIndex := ImageIndex;
  end
  else
  begin
    Inc(FVirtualItemCount);
    Refresh;
  end;
end;

procedure TVirtualListView.BeginUpdate;
begin
  Inc(FUpdateCount);
  Items.BeginUpdate;
end;

procedure TVirtualListView.Clear;
begin
  FItems.Clear;
  FVisibleItems.Clear;
  FVirtualItemCount := 0;
  Items.Clear;
end;

procedure TVirtualListView.CNNotify(var Message: TWMNotify);
begin
  inherited;
  
  // 处理列表视图通知
  case Message.NMHdr^.code of
    LVN_GETDISPINFO:
      begin
        // 处理获取显示信息通知
        if FVirtualMode and Assigned(FOnGetVirtualItem) then
        begin
          with PLVDispInfo(Message.NMHdr)^ do
          begin
            // 获取项索引
            var ItemIndex := item.iItem;
            
            // 获取虚拟项
            var VirtualItem: TVirtualListItem := nil;
            FOnGetVirtualItem(Self, ItemIndex, VirtualItem);
            
            // 如果没有返回项，使用默认项
            if VirtualItem = nil then
              VirtualItem := FDefaultItem;
              
            // 设置项信息
            if (item.mask and LVIF_TEXT) <> 0 then
              StrCopy(item.pszText, PChar(VirtualItem.Caption));
              
            if (item.mask and LVIF_IMAGE) <> 0 then
              item.iImage := VirtualItem.ImageIndex;
              
            if (item.mask and LVIF_STATE) <> 0 then
            begin
              if VirtualItem.Checked then
                item.state := item.state or LVIS_CHECKED
              else
                item.state := item.state and not LVIS_CHECKED;
            end;
          end;
        end;
      end;
  end;
end;

constructor TVirtualListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // 创建项列表
  FItems := TObjectList<TVirtualListItem>.Create(True);
  FVisibleItems := TDictionary<Integer, TVirtualListItem>.Create;
  FDefaultItem := TVirtualListItem.Create;
  
  // 初始化属性
  FVirtualMode := False;
  FVirtualItemCount := 0;
  FFirstVisibleItem := 0;
  FLastVisibleItem := 0;
  FUpdateCount := 0;
  FNeedRebuild := False;
  
  // 设置列表视图属性
  OwnerData := True;
  ViewStyle := vsReport;
  RowSelect := True;
  GridLines := True;
  ShowColumnHeaders := True;
end;

procedure TVirtualListView.CreateWnd;
begin
  inherited;
  
  if FVirtualMode then
  begin
    // 设置虚拟列表视图样式
    ListView_SetExtendedListViewStyle(Handle, 
      ListView_GetExtendedListViewStyle(Handle) or LVS_EX_DOUBLEBUFFER);
  end;
end;

function TVirtualListView.CustomDrawItem(Item: TListItem; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean): Boolean;
begin
  Result := inherited CustomDrawItem(Item, State, Stage, DefaultDraw);
end;

function TVirtualListView.CustomDrawSubItem(Item: TListItem; SubItem: Integer;
  State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: Boolean): Boolean;
begin
  Result := inherited CustomDrawSubItem(Item, SubItem, State, Stage, DefaultDraw);
end;

procedure TVirtualListView.DeleteItem(Index: Integer);
begin
  if (Index >= 0) and (Index < FItems.Count) then
  begin
    FItems.Delete(Index);
    
    if not FVirtualMode then
      Items.Delete(Index)
    else
    begin
      Dec(FVirtualItemCount);
      Refresh;
    end;
  end;
end;

destructor TVirtualListView.Destroy;
begin
  FVisibleItems.Free;
  FItems.Free;
  FDefaultItem.Free;
  inherited;
end;

procedure TVirtualListView.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
  begin
    Items.EndUpdate;
    if FNeedRebuild then
    begin
      RebuildVisibleItems;
      FNeedRebuild := False;
    end;
  end;
end;

procedure TVirtualListView.EnsureVisible(Index: Integer);
begin
  if (Index >= 0) and (Index < ItemCount) then
  begin
    if not FVirtualMode then
      Items[Index].MakeVisible(False)
    else
    begin
      // 在虚拟模式下确保项可见
      ListView_EnsureVisible(Handle, Index, False);
    end;
  end;
end;

function TVirtualListView.GetItem(Index: Integer): TVirtualListItem;
begin
  if (Index >= 0) and (Index < FItems.Count) then
    Result := FItems[Index]
  else
    Result := nil;
end;

function TVirtualListView.GetItemCount: Integer;
begin
  if FVirtualMode then
    Result := FVirtualItemCount
  else
    Result := FItems.Count;
end;

function TVirtualListView.GetSelectedIndex: Integer;
begin
  Result := -1;
  
  if Selected <> nil then
    Result := Selected.Index;
end;

function TVirtualListView.GetVisibleItem(Index: Integer): TVirtualListItem;
begin
  if FVisibleItems.TryGetValue(Index, Result) then
    // 已找到
  else
    Result := nil;
end;

function TVirtualListView.GetVisibleItemCount: Integer;
begin
  Result := FLastVisibleItem - FFirstVisibleItem + 1;
  if Result < 0 then
    Result := 0;
end;

procedure TVirtualListView.InsertItem(Index: Integer; const Caption: string;
  ImageIndex: Integer);
var
  Item: TVirtualListItem;
begin
  // 确保索引有效
  if Index < 0 then
    Index := 0;
  if Index > FItems.Count then
    Index := FItems.Count;
    
  // 创建新项
  Item := TVirtualListItem.Create;
  Item.Caption := Caption;
  Item.ImageIndex := ImageIndex;
  
  // 插入到列表
  FItems.Insert(Index, Item);
  
  if not FVirtualMode then
  begin
    // 插入到标准列表视图
    var ListItem := Items.Insert(Index);
    ListItem.Caption := Caption;
    ListItem.ImageIndex := ImageIndex;
  end
  else
  begin
    // 更新虚拟项数量
    Inc(FVirtualItemCount);
    Refresh;
  end;
end;

procedure TVirtualListView.Loaded;
begin
  inherited;
  
  if FVirtualMode then
    UpdateVisibleItems;
end;

procedure TVirtualListView.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
end;

function TVirtualListView.OwnerDataFetch(Item: TListItem;
  Request: TItemRequest): Boolean;
var
  VirtualItem: TVirtualListItem;
  i: Integer;
begin
  Result := True;
  
  if FVirtualMode and Assigned(FOnGetVirtualItem) then
  begin
    // 获取虚拟项
    VirtualItem := nil;
    FOnGetVirtualItem(Self, Item.Index, VirtualItem);
    
    // 如果没有返回项，使用默认项
    if VirtualItem = nil then
      VirtualItem := FDefaultItem;
      
    // 设置项信息
    Item.Caption := VirtualItem.Caption;
    Item.ImageIndex := VirtualItem.ImageIndex;
    Item.StateIndex := VirtualItem.StateIndex;
    Item.Checked := VirtualItem.Checked;
    Item.Data := VirtualItem.Data;
    
    // 设置子项
    for i := 0 to Min(Item.SubItems.Count, VirtualItem.SubItems.Count) - 1 do
      Item.SubItems[i] := VirtualItem.SubItems[i];
      
    // 添加缺少的子项
    for i := Item.SubItems.Count to VirtualItem.SubItems.Count - 1 do
      Item.SubItems.Add(VirtualItem.SubItems[i]);
      
    // 缓存可见项
    FVisibleItems.AddOrSetValue(Item.Index, VirtualItem);
  end;
end;

function TVirtualListView.OwnerDataFind(Find: TItemFind;
  const FindString: string; const FindPosition: TPoint; FindData: Pointer;
  StartIndex: Integer; Direction: TSearchDirection; Wrap: Boolean): Integer;
begin
  Result := -1;
end;

function TVirtualListView.OwnerDataHint(StartIndex, EndIndex: Integer): Boolean;
begin
  Result := True;
  
  // 更新可见项范围
  FFirstVisibleItem := StartIndex;
  FLastVisibleItem := EndIndex;
  
  // 更新可见项
  UpdateVisibleItems;
end;

procedure TVirtualListView.RebuildVisibleItems;
begin
  if FUpdateCount > 0 then
  begin
    FNeedRebuild := True;
    Exit;
  end;
  
  // 清空可见项缓存
  FVisibleItems.Clear;
  
  // 重新加载可见项
  if FVirtualMode and Assigned(FOnGetVirtualItem) then
  begin
    for var i := FFirstVisibleItem to FLastVisibleItem do
    begin
      if (i >= 0) and (i < FVirtualItemCount) then
      begin
        var VirtualItem: TVirtualListItem := nil;
        FOnGetVirtualItem(Self, i, VirtualItem);
        
        if VirtualItem <> nil then
          FVisibleItems.AddOrSetValue(i, VirtualItem);
      end;
    end;
  end;
  
  // 刷新显示
  Refresh;
end;

procedure TVirtualListView.SetItem(Index: Integer; const Value: TVirtualListItem);
begin
  if (Index >= 0) and (Index < FItems.Count) then
  begin
    // 替换项
    FItems[Index] := Value;
    
    if not FVirtualMode then
    begin
      // 更新标准列表视图
      Items[Index].Caption := Value.Caption;
      Items[Index].ImageIndex := Value.ImageIndex;
      Items[Index].StateIndex := Value.StateIndex;
      Items[Index].Checked := Value.Checked;
      Items[Index].Data := Value.Data;
      
      // 更新子项
      Items[Index].SubItems.Clear;
      for var i := 0 to Value.SubItems.Count - 1 do
        Items[Index].SubItems.Add(Value.SubItems[i]);
    end
    else
    begin
      // 在虚拟模式下刷新显示
      Refresh;
    end;
  end;
end;

procedure TVirtualListView.SetSelectedIndex(Index: Integer);
begin
  if (Index >= 0) and (Index < ItemCount) then
  begin
    if not FVirtualMode then
    begin
      // 在标准模式下选择项
      Items[Index].Selected := True;
      Items[Index].Focused := True;
    end
    else
    begin
      // 在虚拟模式下选择项
      ListView_SetItemState(Handle, Index, 
        LVIS_SELECTED or LVIS_FOCUSED, LVIS_SELECTED or LVIS_FOCUSED);
    end;
    
    // 确保项可见
    EnsureVisible(Index);
  end;
end;

procedure TVirtualListView.SetVirtualItemCount(const Value: Integer);
begin
  if FVirtualItemCount <> Value then
  begin
    FVirtualItemCount := Value;
    
    if FVirtualMode then
    begin
      // 更新列表视图项数量
      if HandleAllocated then
        ListView_SetItemCount(Handle, FVirtualItemCount);
        
      // 更新可见项
      UpdateVisibleItems;
    end;
  end;
end;

procedure TVirtualListView.SetVirtualMode(const Value: Boolean);
begin
  if FVirtualMode <> Value then
  begin
    FVirtualMode := Value;
    
    if FVirtualMode then
    begin
      // 启用虚拟模式
      OwnerData := True;
      
      // 设置项数量
      if HandleAllocated then
        ListView_SetItemCount(Handle, FVirtualItemCount);
    end
    else
    begin
      // 禁用虚拟模式
      OwnerData := False;
      
      // 清空并重新加载项
      Items.Clear;
      for var i := 0 to FItems.Count - 1 do
      begin
        var Item := Items.Add;
        Item.Caption := FItems[i].Caption;
        Item.ImageIndex := FItems[i].ImageIndex;
        Item.StateIndex := FItems[i].StateIndex;
        Item.Checked := FItems[i].Checked;
        Item.Data := FItems[i].Data;
        
        // 添加子项
        for var j := 0 to FItems[i].SubItems.Count - 1 do
          Item.SubItems.Add(FItems[i].SubItems[j]);
      end;
    end;
  end;
end;

procedure TVirtualListView.UpdateVisibleItems;
begin
  if FVirtualMode and Assigned(FOnGetVirtualItem) then
  begin
    // 获取可见项范围
    var TopIndex := ListView_GetTopIndex(Handle);
    var VisibleCount := ListView_GetCountPerPage(Handle);
    
    // 更新可见项范围
    FFirstVisibleItem := TopIndex;
    FLastVisibleItem := TopIndex + VisibleCount;
    
    // 限制范围
    if FFirstVisibleItem < 0 then
      FFirstVisibleItem := 0;
    if FLastVisibleItem >= FVirtualItemCount then
      FLastVisibleItem := FVirtualItemCount - 1;
      
    // 重建可见项
    RebuildVisibleItems;
  end;
end;

procedure TVirtualListView.WMHScroll(var Message: TWMHScroll);
begin
  inherited;
  
  // 水平滚动时更新可见项
  UpdateVisibleItems;
end;

procedure TVirtualListView.WMSize(var Message: TWMSize);
begin
  inherited;
  
  // 大小改变时更新可见项
  UpdateVisibleItems;
end;

procedure TVirtualListView.WMVScroll(var Message: TWMVScroll);
begin
  inherited;
  
  // 垂直滚动时更新可见项
  UpdateVisibleItems;
end;

end.
