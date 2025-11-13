unit HelperUI;

interface

uses
  System.SysUtils, System.Classes, Vcl.StdCtrls, Vcl.Controls, Vcl.Grids,
  Vcl.Forms, Vcl.Graphics, System.Types, Vcl.CheckLst, ModelEncoding,
  Winapi.Windows, Winapi.Messages, Vcl.ComCtrls, HelperLanguage, System.IniFiles, UtilsTypes,
  System.Rtti, System.TypInfo, System.DateUtils;

type
  // UI 辅助类
  TUIHelper = class
  private
    // 编码列表设置
    // procedure InitEncodingListBox(ListBox: TListBox; EncodingModel: TEncodingModel); // Removed

    // 获取翻译文本
    function GetTranslatedText(const Key: string; const DefaultValue: string): string;

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
    procedure AddFileToGridAt(Grid: TStringGrid; RowIndex: Integer; const FileName: string;
      const EncodingName: string; Selected: Boolean);

    // 清空表格
    procedure ClearGrid(Grid: TStringGrid);

    // 获取选中的文件
    function GetSelectedFiles(Grid: TStringGrid; const FolderPath: string): TArray<string>;

    // 切换所有选择
    procedure ToggleAllSelections(Grid: TStringGrid);

    // 更新日志
    procedure AppendLog(LogMemo: TMemo; const Text: string);
    procedure FlushLogBuffer;
    procedure FreeLogBuffer;

    // 内部静态方法
    class procedure FlushLogBufferInternal;

    // 提供统一的勾选标记（Unicode U+2713），避免源码中直接使用非 ASCII 字符
    class function GetCheckMark: string; static;
  end;



implementation

{$WARN IMPLICIT_STRING_CAST OFF}

// 统一的勾选标记实现（U+2713），避免源码直接写入靐ASCII字符导致的乱码
class function TUIHelper.GetCheckMark: string;
begin
  Result := string(WideChar($2713));
end;

{ TUIHelper }

constructor TUIHelper.Create;
begin
  inherited Create;
end;

destructor TUIHelper.Destroy;
begin
  inherited;
end;

// 上次更新日志的时间
var
  LastLogUpdateTime: TDateTime = 0;
  LogUpdateInterval: Integer = 500; // 毫秒
  LogBuffer: TStringList = nil;
  LogMemoRef: TMemo = nil;

procedure TUIHelper.AppendLog(LogMemo: TMemo; const Text: string);
var
  TimeStamp: string;
  LogText: string;
  CurrentTime: TDateTime;
  ElapsedMs: Integer;
  ContainsNonAscii: Boolean;
  i: Integer;
begin
  // 安全检查：确保LogMemo已创建且有效
  if not Assigned(LogMemo) then
  begin
    OutputDebugString(PChar('警告: 尝试向未创建的LogMemo添加日志: ' + Text));
    Exit;
  end;

  // 确保LogMemo已经完全创建并可用
  try
    // 简单测试LogMemo是否可用
    if not LogMemo.HandleAllocated then
    begin
      OutputDebugString(PChar('警告: LogMemo句柄尚未分配，跳过日志: ' + Text));
      Exit;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('错误: 检查LogMemo时发生异常: ' + E.Message));
      Exit;
    end;
  end;

  // 初始化日志缓冲区
  if not Assigned(LogBuffer) then
  begin
    LogBuffer := TStringList.Create;
    LogMemoRef := LogMemo;
  end;

  // 如果引用的Memo变了，清空缓冲区
  if (LogMemoRef <> LogMemo) and Assigned(LogMemoRef) then
  begin
    if Assigned(LogBuffer) and (LogBuffer.Count > 0) then
    begin
      // 将缓冲区内容写入旧的Memo
      TUIHelper.FlushLogBufferInternal;
    end;
    LogMemoRef := LogMemo;
  end;

  // 生成时间戳
  TimeStamp := FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now);

  // 处理日志文本
  try
    // 检查文本是否包含非ASCII字符
    ContainsNonAscii := False;
    for i := 1 to Length(Text) do
    begin
      if Ord(Text[i]) > 127 then
      begin
        ContainsNonAscii := True;
        Break;
      end;
    end;

    // 如果包含非ASCII字符，进行编码转换
    if ContainsNonAscii then
    begin
      // 使用更安全的方式处理非ASCII字符
      try
        // 直接使用UTF-8编码处理文本，避免中间转换步骤
        // 这样可以避免在多字节编码和Unicode之间转换时可能出现的问题
        LogText := TimeStamp + Text;
      except
        on E: EEncodingError do
        begin
          // 特别处理编码错误
          OutputDebugString(PChar('编码错误: ' + E.Message));
          LogText := TimeStamp + '(编码错误) ' + StringReplace(Text, #0, '', [rfReplaceAll]);
        end;
        on E: Exception do
        begin
          // 处理其他异常
          OutputDebugString(PChar('日志处理异常: ' + E.Message));
          LogText := TimeStamp + '(处理异常) ' + StringReplace(Text, #0, '', [rfReplaceAll]);
        end;
      end;
    end
    else
    begin
      // 如果只包含ASCII字符，直接使用
      LogText := TimeStamp + Text;
    end;
  except
    // 如果处理过程中出现异常，使用安全的方式添加日志
    LogText := TimeStamp + '(日志编码错误) ' + StringReplace(Text, #0, '', [rfReplaceAll]);
  end;

  // 添加到缓冲区
  LogBuffer.Add(LogText);

  // 检查是否需要更新UI
  CurrentTime := Now;
  ElapsedMs := MilliSecondsBetween(LastLogUpdateTime, CurrentTime);

  // 如果距离上次更新超过指定时间，或者缓冲区过大，则更新UI
  if (ElapsedMs > LogUpdateInterval) or (LogBuffer.Count > 100) then
    TUIHelper.FlushLogBufferInternal;
end;

// 将日志缓冲区内容写入Memo（内部静态方法）
class procedure TUIHelper.FlushLogBufferInternal;
begin
  // 安全检查：确保LogBuffer和LogMemoRef已创建且有效
  if not Assigned(LogBuffer) then
  begin
    OutputDebugString(PChar('警告: 尝试刷新未创建的LogBuffer'));
    Exit;
  end;

  if not Assigned(LogMemoRef) then
  begin
    OutputDebugString(PChar('警告: 尝试刷新到未创建的LogMemoRef'));
    Exit;
  end;

  // 确保LogMemoRef已经完全创建并可用
  try
    // 简单测试LogMemoRef是否可用
    if not LogMemoRef.HandleAllocated then
    begin
      OutputDebugString(PChar('警告: LogMemoRef句柄尚未分配，跳过刷新'));
      Exit;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('错误: 检查LogMemoRef时发生异常: ' + E.Message));
      Exit;
    end;
  end;

  if LogBuffer.Count = 0 then
    Exit;

  try
    // 批量更新UI
    LogMemoRef.Lines.BeginUpdate;
    try
      // 设置TMemo的编码为UTF-8
      LogMemoRef.Font.Charset := DEFAULT_CHARSET;

      // 安全地添加所有日志
      try
        // 逐行添加，避免整批添加可能导致的编码问题
        for var i := 0 to LogBuffer.Count - 1 do
        begin
          try
            LogMemoRef.Lines.Add(LogBuffer[i]);
          except
            on E: EEncodingError do
            begin
              // 特别处理编码错误
              OutputDebugString(PChar('添加日志行时编码错误: ' + E.Message));
              LogMemoRef.Lines.Add('(编码错误的日志行)');
            end;
            on E: Exception do
            begin
              // 处理其他异常
              OutputDebugString(PChar('添加日志行时异常: ' + E.Message));
              LogMemoRef.Lines.Add('(添加日志行时出错)');
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('批量添加日志时发生异常: ' + E.Message));
          // 尝试添加一条错误信息
          try
            LogMemoRef.Lines.Add('(日志处理出错，部分日志可能丢失)');
          except
            // 忽略
          end;
        end;
      end;
    finally
      LogMemoRef.Lines.EndUpdate;
    end;

    // 滚动到底部
    try
      LogMemoRef.SelStart := Length(LogMemoRef.Text);
      LogMemoRef.SelLength := 0;
      LogMemoRef.Perform(EM_SCROLLCARET, 0, 0);
    except
      // 忽略滚动错误
    end;

    // 清空缓冲区
    LogBuffer.Clear;

    // 更新时间戳
    LastLogUpdateTime := Now;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('错误: 刷新日志缓冲区时发生异常: ' + E.Message));
      // 忽略所有错误，确保程序可以继续运行
    end;
  end;
end;

// 将日志缓冲区内容写入Memo（公共方法）
procedure TUIHelper.FlushLogBuffer;
begin
  TUIHelper.FlushLogBufferInternal;
end;

// 在程序结束时释放资源
procedure TUIHelper.FreeLogBuffer;
begin
  try
    if Assigned(LogBuffer) then
    begin
      // 确保所有日志都被写入
      try
        TUIHelper.FlushLogBufferInternal;
      except
        on E: Exception do
          OutputDebugString(PChar('警告: 释放日志缓冲区时刷新失败: ' + E.Message));
      end;

      // 释放缓冲区
      try
        LogBuffer.Free;
        LogBuffer := nil;
      except
        on E: Exception do
          OutputDebugString(PChar('警告: 释放日志缓冲区失败: ' + E.Message));
      end;
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('错误: FreeLogBuffer过程中发生异常: ' + E.Message));
  end;
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
  FileName: string;
  FullPath: string;
begin
  SetLength(Files, 0);
  Count := 0;

  // 记录开始处理
  OutputDebugString(PChar('开始获取选中文件，文件夹路径: ' + FolderPath));

  for i := 1 to Grid.RowCount - 1 do
  begin
    // 检查是否选中且文件名不为空
    if ((Grid.Cells[0, i] = TUIHelper.GetCheckMark) or (Grid.Cells[0, i] = '√')) and (Grid.Cells[2, i] <> '') then
    begin
      // 获取文件名（从第3列，索引为2）
      FileName := Grid.Cells[2, i];

      // 构建完整路径
      FullPath := IncludeTrailingPathDelimiter(FolderPath) + FileName;

      // 检查文件是否存在
      if FileExists(FullPath) then
      begin
        Inc(Count);
        SetLength(Files, Count);
        Files[Count - 1] := FullPath;

        // 记录添加的文件
        OutputDebugString(PChar('添加选中文件: ' + FullPath));
      end
      else
      begin
        // 记录文件不存在
        OutputDebugString(PChar('文件不存在，跳过: ' + FullPath));
      end;
    end;
  end;

  // 记录处理结果
  OutputDebugString(PChar('共找到 ' + IntToStr(Count) + ' 个选中文件'));

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
  Grid.ColWidths[1] := 112;       // 编码列 (减少到原来的一半)
  Grid.ColWidths[2] := 613;       // 文件名列 (增加编码列减少的部分)

  // 设置表头
  Grid.Cells[0, 0] := '选择';
  Grid.Cells[1, 0] := '当前编码';
  Grid.Cells[2, 0] := '文件名';

  // 采用系统通用字体与默认字符集，确保 Unicode 符号（如勾选标记）正确显示
  Grid.Font.Name := 'Segoe UI';
  Grid.Font.Charset := DEFAULT_CHARSET;

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
    Grid.Cells[0, RowIndex] := TUIHelper.GetCheckMark
  else
    Grid.Cells[0, RowIndex] := '';

  Grid.Cells[1, RowIndex] := EncodingName;
  Grid.Cells[2, RowIndex] := FileName;
end;

procedure TUIHelper.AddFileToGridAt(Grid: TStringGrid; RowIndex: Integer; const FileName: string;
  const EncodingName: string; Selected: Boolean);
begin
  // 确保行索引有效
  if (RowIndex < 1) then
    Exit;

  // 如果行索引超出当前行数，增加行数
  if (RowIndex >= Grid.RowCount) then
    Grid.RowCount := RowIndex + 1;

  // 设置单元格内容
  if Selected then
    Grid.Cells[0, RowIndex] := TUIHelper.GetCheckMark
  else
    Grid.Cells[0, RowIndex] := '';

  Grid.Cells[1, RowIndex] := EncodingName;
  Grid.Cells[2, RowIndex] := FileName;
end;

procedure TUIHelper.SetupEncodingList(TreeView: TTreeView; EncodingModel: TEncodingModel);
var
  i: Integer;
  RootNode: TTreeNode;
  GroupNode: TTreeNode;
  EncodingNode: TTreeNode;
  EncodingInfo: ModelEncoding.TEncodingInfo;
  DisplayText: string;
  RootText: string;
  ShortDesc: string;
  IsCommonEncoding: Boolean;
begin
  TreeView.Items.BeginUpdate;
  try
    TreeView.Items.Clear;
    
    // 设置 TreeView 外观
    TreeView.Font.Size := 10;
    TreeView.Font.Name := 'Segoe UI';
    // 启用树状连接线和展开按钮，显示根节点
    TreeView.ShowLines := True;
    TreeView.ShowButtons := True;
    TreeView.ShowRoot := True;
    // 统一缩进，使用视觉连接线
    TreeView.Indent := 22;

    // 获取根节点文本（不使用表情或特殊符号，避免乱码）
    RootText := GetTranslatedText('TreeViewRootNode', '选择目标编码');
    RootNode := TreeView.Items.AddObject(nil, RootText, nil);
    if Assigned(RootNode) then
    begin
      RootNode.ImageIndex := 0;
      RootNode.SelectedIndex := 0;
    end;
    GroupNode := nil;

    for i := 0 to EncodingModel.EncodingCount - 1 do
    begin
      EncodingInfo := EncodingModel.Encodings[i];

      if EncodingInfo.IsGroup then
      begin
        // 分组标题：加粗显示（不使用表情或特殊符号）
        DisplayText := GetTranslatedText('EncodingGroup_' + EncodingInfo.ShortName, EncodingInfo.Name);
        if DisplayText = '' then
          DisplayText := EncodingInfo.Name;
        
        GroupNode := TreeView.Items.AddChildObject(RootNode, DisplayText, Pointer(i));
        if Assigned(GroupNode) then
        begin
          // 根据分组短名为不同语系分配不同的图标索引
          // 约定的索引：
          // 0=root，1=Unicode，2=Asian，3=Western，4=Eastern，5=MiddleEast，6=Nordic，7=Southern，8=Other，9=Encoding
          var idx: Integer := 8; // 默认Other
          var key := LowerCase(EncodingInfo.ShortName);
          if key = 'unicode' then idx := 1
          else if key = 'asian' then idx := 2
          else if key = 'western' then idx := 3
          else if key = 'eastern' then idx := 4
          else if key = 'middleeast' then idx := 5
          else if key = 'nordic' then idx := 6
          else if key = 'southern' then idx := 7
          else idx := 8;

          GroupNode.ImageIndex := idx;
          GroupNode.SelectedIndex := idx;
        end;
      end
      else if Assigned(GroupNode) then
      begin
        // 判断是否为常用编码
        IsCommonEncoding := (EncodingInfo.ShortName = 'UTF8') or 
                           (EncodingInfo.ShortName = 'UTF8BOM') or
                           (EncodingInfo.ShortName = 'GBK') or 
                           (EncodingInfo.ShortName = 'Big5') or
                           (EncodingInfo.ShortName = 'GB2312');
        
        // 获取编码名称（主要信息，不使用表情或特殊符号）
        DisplayText := EncodingInfo.Name;
        
        // 获取编码描述
        ShortDesc := GetTranslatedText('EncodingDesc_' + EncodingInfo.ShortName, EncodingInfo.Description);
        
        // 如果有描述，使用括号包裹，与编码名称区分
        if ShortDesc <> '' then
          DisplayText := DisplayText + '  (' + ShortDesc + ')';
        
        // 取消手工空格缩进，交给TreeView的层级缩进处理，避免文本不对齐
        
        EncodingNode := TreeView.Items.AddChildObject(GroupNode, DisplayText, Pointer(i));
        if Assigned(EncodingNode) then
        begin
          // 统一使用编码图标索引9
          EncodingNode.ImageIndex := 9;
          EncodingNode.SelectedIndex := 9;
        end;
      end
      else
      begin
        DisplayText := EncodingInfo.Name;
        EncodingNode := TreeView.Items.AddChildObject(RootNode, DisplayText, Pointer(i));
        if Assigned(EncodingNode) then
        begin
          EncodingNode.ImageIndex := 9;
          EncodingNode.SelectedIndex := 9;
        end;
      end;
    end;

    // 展开根节点和常用编码组
    if Assigned(RootNode) then
    begin
      RootNode.Expand(True);
      
      // 展开 Unicode 组
      if (RootNode.Count > 0) and (RootNode.Item[0] <> nil) then
        RootNode.Item[0].Expand(True);
      
      // 展开亚洲编码组
      if (RootNode.Count > 1) and (RootNode.Item[1] <> nil) then
        RootNode.Item[1].Expand(True);
    end;

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
    if (Grid.Cells[2, i] <> '') and (Grid.Cells[0, i] = TUIHelper.GetCheckMark) then
    begin
      HasChecked := True;
      Break;
    end;
  end;

  // 根据当前状态切换选择
  for i := 1 to Grid.RowCount - 1 do
  begin
    if Grid.Cells[2, i] <> '' then
    begin
      if HasChecked then
        Grid.Cells[0, i] := ''
      else
        Grid.Cells[0, i] := TUIHelper.GetCheckMark;
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

// 实现GetTranslatedText方法
function TUIHelper.GetTranslatedText(const Key: string; const DefaultValue: string): string;
var
  LangCode: string;
  LangIniFile: TMemIniFile;
  FullPath: string;
  Section: string;
  TransKey: string;
begin
  // 初始化变量
  TransKey := '';

  // 检查LanguageManager是否可用
  if Assigned(LanguageManager) and (LanguageManager.CurrentLanguage <> '') then
  begin
    LangCode := LanguageManager.CurrentLanguage;

    try
      // 确定INI文件的路径
      if IniDir <> '' then
        FullPath := System.SysUtils.IncludeTrailingPathDelimiter(IniDir) + LangCode + '.ini'
      else
        FullPath := ExtractFilePath(Application.ExeName) + 'ini\' + LangCode + '.ini';

      // 检查INI文件是否存在
      if FileExists(FullPath) then
      begin
        LangIniFile := TMemIniFile.Create(FullPath, TEncoding.UTF8);
        try
          // 根据键名前缀确定查找的节
          if Key.StartsWith('TreeViewRootNode') then
          begin
            Section := 'Strings';
            TransKey := 'TreeViewRootNode';
          end
          else if Key.StartsWith('EncodingGroup_') then
          begin
            Section := 'Encodings';
            TransKey := Copy(Key, Length('EncodingGroup_') + 1, Length(Key));
          end
          else if Key.StartsWith('Encoding_') then
          begin
            Section := 'Encodings';
            TransKey := Copy(Key, Length('Encoding_') + 1, Length(Key));
          end
          else if Key.StartsWith('EncodingDesc_') then
          begin
            // 从INI文件中获取编码描述
            Section := 'EncodingDescriptions';
            TransKey := Copy(Key, Length('EncodingDesc_') + 1, Length(Key));

            // 如果在EncodingDescriptions节中找不到，尝试在Encodings节中查找
            Result := LangIniFile.ReadString(Section, TransKey, '');
            if Result = '' then
            begin
              Section := 'Encodings';
              Result := LangIniFile.ReadString(Section, TransKey, DefaultValue);
            end;

            // 如果仍然为空，使用默认值
            if Result = '' then
              Result := DefaultValue;

            Exit;
          end
          else
          begin
            Section := 'Strings';
            TransKey := Key;
          end;

          // 从INI文件读取翻译
          Result := LangIniFile.ReadString(Section, TransKey, DefaultValue);

          // 如果读取到空字符串，使用默认值
          if Result = '' then
            Result := DefaultValue;
        finally
          LangIniFile.Free;
        end;
      end
      else
        Result := DefaultValue;
    except
      // 异常处理，使用默认值
      Result := DefaultValue;
    end;
  end
  else
  begin
    // 如果LanguageManager不可用，使用默认值
    Result := DefaultValue;
  end;
end;

end.