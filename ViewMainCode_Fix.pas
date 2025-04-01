unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, System.IOUtils, System.UITypes, Vcl.FileCtrl, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Grids, System.Math, Vcl.CheckLst, System.Types, Vcl.Menus, System.Rtti,
  System.StrUtils, UtilsTypes, ModelEncoding, ModelConfig, HelperUI, HelperFiles, 
  ControllerEncoding, HelperLanguage, Winapi.ShlObj, ViewSynEdit, UtilsIconv;

// 以下是有问题的部分的修复示例
// 修复CreateLanguageSelector方法中的括号对齐问题
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

// 修复DirectoryListBox1Change方法的缩进问题
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

// 修复SwitchToChinese方法中的括号对齐问题
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

// 修复UpdateSingleFileInGrid方法中的括号对齐问题
procedure TForm1.UpdateSingleFileInGrid(const FilePath: string);
var
  i: Integer;
  FileName: string;
  EncodingName: string;
begin
  // 获取文件名
  FileName := ExtractFileName(FilePath);
  
  // 在表格中查找该文件
  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[1, i] = FileName then
    begin
      // 更新编码信息
      try
        if FEncodingController.DetectFileEncoding(FilePath, EncodingName) then
          StringGrid1.Cells[3, i] := EncodingName
        else
          StringGrid1.Cells[3, i] := '未知';
      except
        StringGrid1.Cells[3, i] := '检测失败';
      end;
      
      // 刷新表格
      InvalidateControl(StringGrid1);
      Break;
    end;
  end;
end; 