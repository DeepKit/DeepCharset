unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.FileCtrl, Vcl.Grids, System.UITypes, System.Types, System.StrUtils,
  System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  System.DateUtils, System.Math, System.Threading, System.SyncObjs,

  // 自定义单元
  ModelLanguage, ModelEncoding, ModelConfig,
  HelperUI, HelperFiles, HelperLanguage,
  ControllerEncoding, ControllerLanguage,
  UtilsTypes, UtilsLogBuffer, UtilsAsyncFileScanner, UtilsDragDrop,
  ViewMemo, ViewSynEdit;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    Panel28: TPanel;
    Panel29: TPanel;
    Panel30: TPanel;
    btnClose: TButton;
    btnConvert: TButton;
    btnRefresh: TButton;
    btnSelectAllExt: TButton;
    btnUnselectAllExt: TButton;
    btnShowContent: TButton;
    btnSingleFile: TButton;
    btnCancel: TButton;
    btnToggleVirtualMode: TButton;
    DirectoryListBox1: TDirectoryListBox;
    DriveComboBox1: TDriveComboBox;
    CheckListBox1: TCheckListBox;
    StringGrid1: TStringGrid;
    TreeViewEncodings: TTreeView;
    MemLog: TMemo;
    StatusBar1: TStatusBar;
    ProgressBar: TProgressBar;
    lblStatus: TLabel;
    lblFileCount: TLabel;
    lblSelectedFolder: TLabel;
    lblVersion: TLabel;
    lblLanguage: TLabel;
    ComboBoxLanguage: TComboBox;
    chkIncludeSubdirs: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnSelectAllExtClick(Sender: TObject);
    procedure btnUnselectAllExtClick(Sender: TObject);
    procedure btnShowContentClick(Sender: TObject);
    procedure btnSingleFileClick(Sender: TObject);
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure DriveComboBox1Change(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure TreeViewEncodingsChange(Sender: TObject; Node: TTreeNode);
    procedure ComboBoxLanguageChange(Sender: TObject);
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

    // 本地化缓存
    FCurrentLanguage: string;

    // 获取本地化信息
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

    // 窗体刷新处理
    procedure InvalidateForm;

    // 语言相关方法
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

end.
