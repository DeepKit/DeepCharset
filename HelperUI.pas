unit HelperUI;

interface

uses
  System.SysUtils, System.Classes, Vcl.StdCtrls, Vcl.Controls, Vcl.Grids,
  Vcl.Forms, Vcl.Graphics, System.Types, Vcl.CheckLst, ModelEncoding,
  Winapi.Windows, Winapi.Messages, Vcl.ComCtrls;

type
  // UI 辅助类
  TUIHelper = class
  private
    // 编码列表设置
    // procedure InitEncodingListBox(ListBox: TListBox; EncodingModel: TEncodingModel); // Removed

  public
    // 构造函数和析构函数
    constructor Create;
    destructor Destroy; override;

    // 初始化表格列
    procedure InitStringGrid(Grid: TStringGrid);

    // 设置编码列表
    procedure SetupEncodingList(TreeView: TTreeView; EncodingModel: TEncodingModel);

    // 刷新编码列表（用于语言切换后更新显示）
    procedure RefreshEncodingList;

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
  Grid.ColWidths[0] := 40;        // 选择框列
  Grid.ColWidths[1] := 500;       // 文件名列 (原来是200，增大到2.5倍)
  Grid.ColWidths[2] := 225;       // 编码列 (原来是150，增大到1.5倍)

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

procedure TUIHelper.SetupEncodingList(TreeView: TTreeView; EncodingModel: TEncodingModel);
var
  i: Integer;
  RootNode: TTreeNode;      // New Root Node
  GroupNode: TTreeNode;     // Node for each category
  EncodingNode: TTreeNode;  // Node for each encoding option
  EncodingInfo: TEncodingInfo;
begin
  TreeView.Items.BeginUpdate;
  try
    TreeView.Items.Clear;

    // Create the main root node with fixed text
    RootNode := TreeView.Items.AddObject(nil, '目标编码', nil); // Top level node
    GroupNode := nil; // Initialize GroupNode

    // Iterate through the categorized list from the model
    for i := 0 to EncodingModel.EncodingCount - 1 do
    begin
      EncodingInfo := EncodingModel.Encodings[i];

      if EncodingInfo.IsGroup then
      begin
        // Add a new category node under the main root node
        GroupNode := TreeView.Items.AddChildObject(RootNode, EncodingInfo.Name, Pointer(i)); // Store index, mark as group
        // GroupNode.Expand(False); // Optional: Start categories collapsed or expanded
      end
      else if Assigned(GroupNode) then // Ensure we have a category to add to
      begin
        // Add an encoding node under the current category node
        EncodingNode := TreeView.Items.AddChildObject(GroupNode, EncodingInfo.Name, Pointer(i)); // Store index in Data
      end
      else
      begin
         // Fallback: add directly under the root (shouldn't happen ideally)
         EncodingNode := TreeView.Items.AddChildObject(RootNode, EncodingInfo.Name, Pointer(i));
         // Log call was removed here in previous step
      end;
    end;

    // Expand the main root node by default
    if Assigned(RootNode) then
      RootNode.Expand(True);

  finally
    TreeView.Items.EndUpdate;
  end;
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

procedure TUIHelper.RefreshEncodingList;
begin
  // 这个方法需要在实现中添加必要的实例变量
  // 目前只是一个空实现，因为我们需要在ViewMainCode中调用它
  // 实际实现应该在ViewMainCode中完成
  // 这里只是为了解决编译错误

  // 在实际实现中，应该清空并重新填充编码列表
  // 例如：
  // if Assigned(FEncodingTreeView) and Assigned(FEncodingModel) then
  //   SetupEncodingList(FEncodingTreeView, FEncodingModel);
end;

end.