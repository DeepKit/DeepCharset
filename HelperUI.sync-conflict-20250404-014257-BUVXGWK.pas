unit HelperUI;

interface

uses
  System.SysUtils, System.Classes, Vcl.StdCtrls, Vcl.Controls, Vcl.Grids,
  Vcl.Forms, Vcl.Graphics, System.Types, Vcl.CheckLst, ModelEncoding, 
  Winapi.Windows, Winapi.Messages;

type
  // UI 辅助类
  TUIHelper = class
  private
    // 编码列表设置
    procedure InitEncodingListBox(ListBox: TListBox; EncodingModel: TEncodingModel);
    
  public
    // 构造函数和析构函数
    constructor Create;
    destructor Destroy; override;
    
    // 初始化表格列
    procedure InitStringGrid(Grid: TStringGrid);
    
    // 设置编码列表
    procedure SetupEncodingList(ListBox: TListBox; EncodingModel: TEncodingModel);
    
    // 自定义绘制编码列表
    procedure DrawEncodingListItem(Control: TWinControl; Index: Integer; Rect: TRect; 
      State: TOwnerDrawState; EncodingList: TEncodingInfoArray);
      
    // 在表格中添加文件
    procedure AddFileToGrid(Grid: TStringGrid; const FileName: string; 
      const EncodingName: string; Selected: Boolean);
      
    // 清空表格
    procedure ClearGrid(Grid: TStringGrid);
    
    // 获取选中的文件
    function GetSelectedFiles(Grid: TStringGrid; const FolderPath: string): TArray<string>;
    
    // 切换所有选择
    procedure ToggleAllSelections(Grid: TStringGrid);
    
    // 更新日志
    procedure AppendLog(LogMemo: TMemo; const Text: string);
  end;
  
implementation

{ TUIHelper }

constructor TUIHelper.Create;
begin
  inherited Create;
end;

destructor TUIHelper.Destroy;
begin
  inherited;
end;

procedure TUIHelper.AppendLog(LogMemo: TMemo; const Text: string);
begin
  LogMemo.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Text);
  
  // 滚动到底部
  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TUIHelper.ClearGrid(Grid: TStringGrid);
var
  i: Integer;
begin
  // 保留表头
  for i := Grid.RowCount - 1 downto 1 do
    Grid.Rows[i].Clear;
  
  Grid.RowCount := 2;
  Grid.Rows[1].Clear; // 清空第一个数据行
end;

procedure TUIHelper.DrawEncodingListItem(Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState; EncodingList: TEncodingInfoArray);
var
  LB: TListBox;
  IsGroup, IsEmpty: Boolean;
  TextColor, BgColor: TColor;
  TextLeft: Integer;
  TextRect: TRect;
  ItemText: string;
  EncodingInfo: TEncodingInfo;
  ListIndex: Integer;
begin
  LB := TListBox(Control);
  
  // 获取显示文本
  ItemText := LB.Items[Index];
  
  // 确定是否为空行
  IsEmpty := (ItemText = '');
  
  if IsEmpty then
  begin
    // 空行只绘制背景
    LB.Canvas.Brush.Color := clWindow;
    LB.Canvas.FillRect(Rect);
    Exit;
  end;
  
  // 获取实际编码索引
  ListIndex := Integer(LB.Items.Objects[Index]);
  
  // 确保索引有效
  if (ListIndex < 0) or (ListIndex >= Length(EncodingList)) then
  begin
    // 无效索引，绘制为普通项
    LB.Canvas.Brush.Color := clWindow;
    LB.Canvas.FillRect(Rect);
    Exit;
  end;
  
  // 获取编码信息
  EncodingInfo := EncodingList[ListIndex];
  IsGroup := EncodingInfo.IsGroup;
  
  // 设置背景和文本颜色
  if (State * [odSelected, odFocused]) <> [] then
  begin
    TextColor := clWhite;
    BgColor := clHighlight;
  end
  else if IsGroup then
  begin
    TextColor := clWindowText;
    BgColor := clBtnFace;
  end
  else
  begin
    TextColor := clWindowText;
    BgColor := clWindow;
  end;
  
  // 绘制背景
  LB.Canvas.Brush.Color := BgColor;
  LB.Canvas.FillRect(Rect);
  
  // 设置文本属性
  LB.Canvas.Font.Color := TextColor;
  if IsGroup then
    LB.Canvas.Font.Style := [fsBold]
  else
    LB.Canvas.Font.Style := [];
  
  // 绘制文本，确保垂直居中
  TextLeft := Rect.Left + 6; // 增加左边距
  TextRect := Rect;
  TextRect.Left := TextLeft;
  
  // 使用Canvas.TextOut来绘制文本
  LB.Canvas.TextOut(TextRect.Left, 
                    (TextRect.Top + TextRect.Bottom - LB.Canvas.TextHeight(ItemText)) div 2, 
                    ItemText);
  
  // 为组项绘制底线
  if IsGroup then
  begin
    LB.Canvas.Pen.Color := clGray;
    LB.Canvas.MoveTo(Rect.Left, Rect.Bottom - 1);
    LB.Canvas.LineTo(Rect.Right, Rect.Bottom - 1);
  end;
end;

function TUIHelper.GetSelectedFiles(Grid: TStringGrid; const FolderPath: string): TArray<string>;
var
  i, Count: Integer;
  Files: TArray<string>;
begin
  SetLength(Files, 0);
  Count := 0;
  
  for i := 1 to Grid.RowCount - 1 do
  begin
    if (Grid.Cells[0, i] = '√') and (Grid.Cells[1, i] <> '') then
    begin
      Inc(Count);
      SetLength(Files, Count);
      Files[Count - 1] := IncludeTrailingPathDelimiter(FolderPath) + Grid.Cells[1, i];
    end;
  end;
  
  Result := Files;
end;

procedure TUIHelper.InitStringGrid(Grid: TStringGrid);
begin
  // 设置表格属性
  Grid.RowCount := 2;
  Grid.ColCount := 3;
  Grid.FixedRows := 1;
  Grid.FixedCols := 0;
  Grid.Options := Grid.Options + [goRowSelect, goThumbTracking] - [goEditing];
  Grid.ScrollBars := ssVertical;
  
  // 设置列宽
  Grid.ColWidths[0] := 40;  // 选择框列
  Grid.ColWidths[1] := 200; // 文件名列
  Grid.ColWidths[2] := 150; // 编码列
  
  // 设置表头
  Grid.Cells[0, 0] := '选择';
  Grid.Cells[1, 0] := '文件名';
  Grid.Cells[2, 0] := '当前编码';
  
  // 清空数据行
  Grid.Rows[1].Clear;
end;

procedure TUIHelper.AddFileToGrid(Grid: TStringGrid; const FileName: string; 
  const EncodingName: string; Selected: Boolean);
var
  RowIndex: Integer;
begin
  // 添加新行
  RowIndex := Grid.RowCount - 1;
  
  // 如果最后一行已有数据，添加新行
  if Grid.Cells[1, RowIndex] <> '' then
  begin
    Grid.RowCount := Grid.RowCount + 1;
    RowIndex := Grid.RowCount - 1;
  end;
  
  // 设置单元格内容
  if Selected then
    Grid.Cells[0, RowIndex] := '√'
  else
    Grid.Cells[0, RowIndex] := '';
    
  Grid.Cells[1, RowIndex] := FileName;
  Grid.Cells[2, RowIndex] := EncodingName;
end;

procedure TUIHelper.InitEncodingListBox(ListBox: TListBox; EncodingModel: TEncodingModel);
var
  i: Integer;
  DisplayName: string;
  EncodingInfo: TEncodingInfo;
  EncodingListWithSpace: TEncodingInfoArray; // 修改为TEncodingInfoArray类型
  GroupIndexes: TArray<Integer>; // 记录组标题的索引
  SpaceCount: Integer;
begin
  // 清空现有项
  ListBox.Items.Clear;
  SpaceCount := 0;
  
  // 设置属性
  ListBox.Style := lbOwnerDrawFixed;
  ListBox.ItemHeight := 25; // 增加项目高度以增大间距
  
  // 复制并扩展编码列表，在每个组前添加空行（除第一个组）
  SetLength(EncodingListWithSpace, Length(EncodingModel.EncodingList) + 3); // 预留3个空行位置
  SetLength(GroupIndexes, 0);
  
  // 第一阶段：添加所有编码并标记组位置
  for i := 0 to EncodingModel.EncodingCount - 1 do
  begin
    // 记录组标题位置
    if EncodingModel.Encodings[i].IsGroup then
    begin
      SetLength(GroupIndexes, Length(GroupIndexes) + 1);
      GroupIndexes[High(GroupIndexes)] := i + SpaceCount;
      
      // 如果不是第一个组，添加空行
      if i > 0 then
      begin
        EncodingListWithSpace[i + SpaceCount] := EncodingModel.Encodings[0]; // 使用第一个条目(组标题)作为占位符
        EncodingListWithSpace[i + SpaceCount].Name := ''; // 空名称表示空行
        SpaceCount := SpaceCount + 1;
      end
    end;
    
    // 复制当前编码信息
    EncodingListWithSpace[i + SpaceCount] := EncodingModel.Encodings[i];
  end;
  
  // 调整数组大小到实际使用的长度
  SetLength(EncodingListWithSpace, Length(EncodingModel.EncodingList) + SpaceCount);
  
  // 第二阶段：添加到ListBox
  for i := 0 to High(EncodingListWithSpace) do
  begin
    EncodingInfo := EncodingListWithSpace[i];
    
    // 空行
    if EncodingInfo.Name = '' then
    begin
      DisplayName := '';
    end
    // 组标题
    else if EncodingInfo.IsGroup then
    begin
      DisplayName := EncodingInfo.Name;
    end
    // 普通编码项
    else
    begin
      DisplayName := '  ' + EncodingInfo.Name;
    end;
    
    ListBox.Items.AddObject(DisplayName, TObject(i)); // 存储索引到Object属性
  end;
  
  // 选择默认编码 (UTF-8 BOM)
  for i := 0 to ListBox.Items.Count - 1 do
  begin
    // 获取实际的编码索引
    if ListBox.Items.Objects[i] <> nil then
    begin
      EncodingInfo := EncodingListWithSpace[Integer(ListBox.Items.Objects[i])];
      if (not EncodingInfo.IsGroup) and (EncodingInfo.CodePage = 65001) and (EncodingInfo.HasBOM) then
      begin
        ListBox.ItemIndex := i;
        Break;
      end;
    end;
  end;
  
  // 如果没有找到默认编码，则选择第一个非组项
  if ListBox.ItemIndex < 0 then
  begin
    for i := 0 to ListBox.Items.Count - 1 do
    begin
      // 获取实际的编码索引
      if ListBox.Items.Objects[i] <> nil then
      begin
        EncodingInfo := EncodingListWithSpace[Integer(ListBox.Items.Objects[i])];
        if (not EncodingInfo.IsGroup) and (EncodingInfo.Name <> '') then
        begin
          ListBox.ItemIndex := i;
          Break;
        end;
      end;
    end;
  end;
  
  // 保存扩展后的编码列表，用于绘制
  // 使用EncodingModel的ReplaceEncodingList方法替换原始列表
  EncodingModel.ReplaceEncodingList(EncodingListWithSpace);
end;

procedure TUIHelper.SetupEncodingList(ListBox: TListBox; EncodingModel: TEncodingModel);
begin
  // 初始化编码列表
  InitEncodingListBox(ListBox, EncodingModel);
end;

procedure TUIHelper.ToggleAllSelections(Grid: TStringGrid);
var
  i: Integer;
  HasChecked: Boolean;
begin
  // 检查是否有已选中的项目
  HasChecked := False;
  for i := 1 to Grid.RowCount - 1 do
  begin
    if (Grid.Cells[1, i] <> '') and (Grid.Cells[0, i] = '√') then
    begin
      HasChecked := True;
      Break;
    end;
  end;
  
  // 根据当前状态切换选择
  for i := 1 to Grid.RowCount - 1 do
  begin
    if Grid.Cells[1, i] <> '' then
    begin
      if HasChecked then
        Grid.Cells[0, i] := ''
      else
        Grid.Cells[0, i] := '√';
    end;
  end;
end;

end. 