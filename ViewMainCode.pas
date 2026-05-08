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
  System.TypInfo, Vcl.Clipbrd, Vcl.ImgList, Vcl.Samples.Spin;

Type

  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
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
    Button2: TButton;
    CBoxDirHistory: TComboBox;
    chkIncludeSubdirs: TCheckBox;
    lblDepth: TLabel;
    SpinEditDepth: TSpinEdit;
    btnSelectAllExt: TButton;
    btnShowContent: TButton;
    ProgressBar1: TProgressBar;
    lblProgress: TLabel;
    btnRefresh: TButton;
    btnCancel: TButton;
    btnClose: TButton;
    MemLog: TMemo;
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
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure SelectUTF8BOMInTreeView;
    procedure ShowFileContent(const FileName: string; Encoding: TEncoding; const DetectedEncoding: string; HasBOM: Boolean);
    procedure AdjustGridColumnWidths;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chkIncludeSubdirsClick(Sender: TObject);
    procedure SpinEditDepthChange(Sender: TObject);
    procedure CBoxDirHistoryChange(Sender: TObject);
    procedure CBoxDirHistoryDropDown(Sender: TObject);
    // procedure btnCancelClick(Sender: TObject); // ��ʱ����
  private
    FSelectedFolder: string;
    FSelectedRow: Integer;
    FFileExtensions: TStringList;
    FIncludeSubdirs: Boolean;
    FMaxDepth: Integer;
    FLogBuffer: TStringList;
    FBufferingLogs: Boolean;

    // MVC�ܹ����
    FConfig: TAppConfig;
    FEncodingModel: TEncodingModel;
    FEncodingController: TEncodingController;
    FUIHelper: TUIHelper;
    FFileHelper: TFileHelper;

    FOriginalFontSize: Integer;

    // ���ʻ����
    FCurrentLanguage: string;

    // ͼ����Դ������TreeView��
    FIconList: TImageList;

    // �첽������أ���ʱ���ã�
    // FAsyncProcessor: TAsyncFileProcessor;
    // FProgressController: TProgressController;

    // ��ȡ��������Ϣ
    function GetLocalizedMessage(const MsgId: string): string;
    function GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
    procedure ShowLocalizedMessage(const MsgId: string);
    procedure ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);

    procedure UpdateFileGrid(const FolderPath: string);
    procedure UpdateFileExtensions(const FolderPath: string);
    procedure CheckListBox1ClickCheck(Sender: TObject);

    // ��־��¼
    procedure Log(const Msg: string);
    procedure StartLogBuffering;
    procedure EndLogBuffering;

    // ���ˢ�´���
    procedure InvalidateForm;

    // ����������ط���
    procedure InitializeLanguageManager;
    procedure CreateLanguageSelector;
    procedure ApplyLanguageStrings;
    procedure SwitchToLanguageCode(const LangCode: string);

    procedure UpdateSingleFileInGrid(const FilePath: string);

    // ��ʷĿ¼����
    procedure LoadDirHistory;
    procedure SaveDirHistory;
    procedure AddDirToHistory(const DirPath: string);
    procedure UpdateDirHistoryUI;

    // �첽������ط�������ʱ���ã�
    // procedure InitializeAsyncComponents;
    // procedure FinalizeAsyncComponents;
    // procedure UpdateFileGridAsync(const FolderPath: string);
    // procedure ConvertFilesAsync(const Files: TArray<string>; const TargetEncoding: string; WithBOM: Boolean);
    // procedure OnFileScanProgress(const Progress: TFileScanProgress);
    // procedure OnFileScanResult(const Result: TFileScanResult);
    // procedure OnConversionProgress(const Progress: TBatchConversionResult);
    // procedure ShowProgress;
    // procedure HideProgress;

    // ����������ˮƽ���������õ�����࣬ȷ���ܿ������ڵ�
    procedure ScrollEncodingTreeToLeft;

    // ��ʼ��TreeViewͼ��
    procedure InitTreeIcons;

    // UI ��ݲ��������ѡ���ļ��������/�Ƴ� UTF-8 BOM
    procedure ConvertSelectedFilesToUTF8(const WithBOM: Boolean);
    procedure MenuItemAddUTF8BOMClick(Sender: TObject);
    procedure MenuItemRemoveUTF8BOMClick(Sender: TObject);
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

  // ��ʼ����Ա
  FSelectedRow := -1;
  FFileExtensions := TStringList.Create;
  FLogBuffer := TStringList.Create;
  FBufferingLogs := False;

  // ��ʼ��MVC�ܹ����
  FConfig := TAppConfig.Create;
  FEncodingModel := TEncodingModel.Create;
  FUIHelper := TUIHelper.Create;

  // ���������������ʹ����ʽTProc<string>ǿ�����͵���������
  FEncodingController := TEncodingController.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );

  // �����ļ����֣�ʹ����ʽTProc<string>ǿ�����͵���������
  FFileHelper := TFileHelper.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );

  // ���ø�Ŀ¼��INIĿ¼
  RootDir := FFileHelper.GetRootDir;
  IniDir := RootDir + '\ini';
  Log('Root directory: ' + RootDir);
  Log('INI directory: ' + IniDir);

  // ��ʼ�����Թ�����
  InitializeLanguageManager;

  // ��������ѡ����
  CreateLanguageSelector;

  // ��ʼ���첽�������ʱ���ã�
  // InitializeAsyncComponents;

end;

destructor TForm1.Destroy;
begin
  // �ͷ��첽�������ʱ���ã�
  // FinalizeAsyncComponents;

  // �ͷ�MVC�ܹ����
  FEncodingController.Free;
  FFileHelper.Free;
  FUIHelper.Free;
  FEncodingModel.Free;
  FConfig.Free;

  // �ͷ�������Դ
  FLogBuffer.Free;
  FFileExtensions.Free;
  FIconList.Free;
  inherited;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
begin
  // Ӧ�õ�ǰ����
  ApplyLanguageStrings;

  // ǿ������Ӧ�ý������
  Application.ProcessMessages;

  // �����弰���һ���ʱ���������������
  Sleep(100);

  // ǿ�Ƹ�������UIԪ��
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;

  // ǿ���ػ���������
  InvalidateForm;

  // Log UI status
  Log('UI displayed');
  Log('Current language: ' + FCurrentLanguage);
  Log('Form title: ' + Caption);
  Log('Button status check:');
  Log(' - Convert button: ' + btnConvert.Caption);
  Log(' - Single file button: ' + btnSingleFile.Caption);
  Log(' - Refresh button: ' + btnRefresh.Caption);
  Log(' - Select all types button: ' + btnSelectAllExt.Caption);
  Log(' - Show content button: ' + btnShowContent.Caption);

  // Ӧ���п�����
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
    Log('Please select a valid folder');
    Exit;
  end;

  // Get selected encoding info
  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    ShowMessage('��ѡ��һ��Ŀ����롣');
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
  Log('Starting batch conversion of ' + IntToStr(Length(SelectedFiles)) + ' files to ' + TargetInfo.Name + '...');
  StartLogBuffering;

  // Execute conversion
  Screen.Cursor := crHourGlass;
  SuccessCount := 0;

  try
    // ʹ��ͬ����ʽִ��ת�����첽��ʱ���ã�
    FEncodingController.ConvertFiles(SelectedFiles, TargetInfo.ShortName, WithBOM);
    Log(System.SysUtils.Format('����ת����ɣ�ת���� %s', [TargetInfo.Name]));

    // ����ת����ɺ�ˢ���ļ������Ը��±�����Ϣ
    if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
    begin
      Log('Refreshing file list to update encoding info...');
      UpdateFileGrid(DirectoryListBox1.Directory);
      Log('File list refreshed');
    end;
  finally
    Screen.Cursor := crDefault;

    // End log buffering and update log at once
    EndLogBuffering;
  end;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
begin
  if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
  begin
    // ʹ��ͬ����ʽˢ���ļ��б���첽��ʱ���ã�
    UpdateFileGrid(DirectoryListBox1.Directory);
    Log('Refresh directory: ' + DirectoryListBox1.Directory);
  end;
end;

procedure TForm1.btnSingleFileClick(Sender: TObject);
begin
  // Just call the logic from the menu item handler
  MenuItemConvertCurrentClick(Sender);
end;

procedure TForm1.btnToggleSelectClick(Sender: TObject);
begin
  // ȫѡ/ȡ��ȫѡ
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin
  // ��CheckListBox1����Ŀ��ѡ�л�ȡ��ѡ��ʱ�����ļ��б�
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.cmbLanguageChange(Sender: TObject);
var
  Index, LangIndex: Integer;
  LangCode: string;
begin
  // ��ȡѡ�е�����
  Index := ComboBox1.ItemIndex;
  if Index < 0 then
  begin
    Log('Warning: Invalid language index');
    Exit;
  end;

  // ��ȡ��������
  LangIndex := Integer(ComboBox1.Items.Objects[Index]);

  // ��¼�û�ѡ�������
  Log('User selected language: ' + ComboBox1.Items[Index] + ' (Index: ' + IntToStr(LangIndex) + ')');

  // ��ȡ���Դ���
  if (LangIndex >= 0) and (LangIndex <= High(LANGUAGE_MAPPINGS)) then
  begin
    LangCode := LANGUAGE_MAPPINGS[LangIndex].LanguageCode;
    Log('Switch to language: ' + LangCode);

    // �л�����
    SwitchToLanguageCode(LangCode);
  end
  else
  begin
    Log('Warning: Invalid language index: ' + IntToStr(LangIndex));
  end;

  // ȷ�����漰ʱˢ��
  Application.ProcessMessages;
end;

procedure TForm1.DirectoryListBox1Change(Sender: TObject);
begin
  // ����ѡ�е��ļ���
  FSelectedFolder := DirectoryListBox1.Directory;

  // ���������е����ʹ��Ŀ¼
  FConfig.LastDirectory := FSelectedFolder;
  
  // ��ӵ���ʷ��¼
  AddDirToHistory(FSelectedFolder);

  // �����ļ��б���ļ���չ���б�
  Log('ѡ���Ŀ¼: ' + FSelectedFolder);
  UpdateFileExtensions(FSelectedFolder);
  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.DirectoryListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // �û����Ŀ¼�б��
  if Button = mbLeft then
      begin
    // ������������ѡ�е��ļ���
    FSelectedFolder := DirectoryListBox1.Directory;
  end;
end;

procedure TForm1.DriveComboBox1Change(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    // ��DirectoryListBox��Ŀ¼����Ϊ��ǰѡ���������
    DirectoryListBox1.Drive := DriveComboBox1.Drive;
    // ����ѡ�е��ļ���
    FSelectedFolder := DirectoryListBox1.Directory;
    Log('������: ' + DriveComboBox1.Drive + ', ѡ���Ŀ¼: ' + FSelectedFolder);
    // �����ļ��б�
    UpdateFileExtensions(FSelectedFolder);
    UpdateFileGrid(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
  end;
end;

class procedure TForm1.Execute;
begin
  // ��������ʾ������
  Application.CreateForm(TForm1, Form1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // �������������м����¼�
  KeyPreview := True;

  // ��ʼ�����Թ�����
  InitializeLanguageManager;

  // ����ͳһ�Ľ����ʼ������
  InitializeUI;

  // Ӧ�õ�ǰ�����ַ���
  ApplyLanguageStrings;
  
  // ������ʷĿ¼
  LoadDirHistory;

  // ����ʱΪ�����Ҽ��˵����� UTF-8 BOM �����
  try
    var Sep := TMenuItem.Create(GridPopupMenu);
    Sep.Caption := '-';
    GridPopupMenu.Items.Add(Sep);

    var ItemAdd := TMenuItem.Create(GridPopupMenu);
    ItemAdd.Caption := '���UTF-8 BOM';
    ItemAdd.OnClick := MenuItemAddUTF8BOMClick;
    GridPopupMenu.Items.Add(ItemAdd);

    var ItemRemove := TMenuItem.Create(GridPopupMenu);
    ItemRemove.Caption := '�Ƴ�UTF-8 BOM';
    ItemRemove.OnClick := MenuItemRemoveUTF8BOMClick;
    GridPopupMenu.Items.Add(ItemRemove);
  except
    // ���Բ˵������쳣������Ӱ��������
  end;
end;

procedure TForm1.TreeViewEncodingsClick(Sender: TObject);
begin
  // ���û����TreeViewEncodings�е���Ŀʱ����
  // ��������������⣨���ڵ㣩��ȡ��ѡ��
  if (TreeViewEncodings.Selected <> nil) and (TreeViewEncodings.Selected.Level = 0) then
    begin
    TreeViewEncodings.Selected := nil;
    end;
end;

procedure TForm1.Log(const Msg: string);
var
  SafeMsg: string;
  TimeStamp: string;
begin
  try
    // ���ʱ���
    TimeStamp := FormatDateTime('hh:nn:ss.zzz', Now);

    // ��ȫ������Ϣ��ֻ�Ƴ������ַ�
    SafeMsg := Msg;
    SafeMsg := StringReplace(SafeMsg, #0, '', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #13#10, ' ', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #13, ' ', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #10, ' ', [rfReplaceAll]);

    // ��ʽ����־��Ϣ
    SafeMsg := Format('[%s] %s', [TimeStamp, SafeMsg]);

    // ���MemLog�Ƿ��Ѵ���
    if not Assigned(MemLog) then
    begin
      // ���MemLog��δ������ֻ��������Դ���
      try
        OutputDebugString(PChar('��־: ' + SafeMsg));
      except
        on E: Exception do
        begin
          // �����������Դ���ʧ�ܣ�����ʹ�ø���ȫ�ķ�ʽ
          try
            OutputDebugString(PChar('��־: (�������)'));
          except
            // �������д���
          end;
        end;
      end;
      Exit;
    end;

    // ���FLogBuffer�Ƿ��ѳ�ʼ��
    if FBufferingLogs then
    begin
      // ����ģʽ������־��ӵ�������
      try
        if Assigned(FLogBuffer) then
          FLogBuffer.Add(SafeMsg)
        else
          OutputDebugString(PChar('����: ��־������δ��ʼ�����޷���¼��־: ' + SafeMsg));
      except
        on E: EEncodingError do
        begin
          try
            if Assigned(FLogBuffer) then
              FLogBuffer.Add('(����������־)');
            OutputDebugString(PChar('�������: �޷������־��������'));
          except
            // �������д���
          end;
        end;
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('����: �����־��������ʱ����: ' + E.Message));
          except
            // �������д���
          end;
        end;
      end;
    end
    else
    begin
      // ����ģʽ��ֱ����ӵ�MemLog
      try
        if Assigned(FUIHelper) then
          FUIHelper.AppendLog(MemLog, SafeMsg)
        else
        begin
          // ���FUIHelper��δ������ֱ����ӵ�MemLog
          try
            MemLog.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + SafeMsg);
          except
            on E: EEncodingError do
            begin
              // �ر���������
              try
                MemLog.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + '(����������־)');
                OutputDebugString(PChar('�������: �޷������־��MemLog'));
              except
                // �������д���
              end;
            end;
            on E: Exception do
            begin
              // ���������쳣
              try
                OutputDebugString(PChar('����: �����־��MemLogʱ����: ' + E.Message));
              except
                // �������д���
              end;
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          // ���������쳣
          try
            OutputDebugString(PChar('����: ��¼��־ʱ����: ' + E.Message));
          except
            // �������д���
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      // �������п��ܵ��쳣��ȷ����־��¼���ᵼ�³������
      try
        OutputDebugString(PChar('���ش���: ��־��¼�����г���δ������쳣: ' + E.Message));
      except
        // �������д���
      end;
    end;
  end;
end;

// ��ʼ��־����
procedure TForm1.StartLogBuffering;
begin
  try
    // ���û����־
    FBufferingLogs := True;

    // ��ȫ��飺ȷ��FLogBuffer�ѳ�ʼ��
    if not Assigned(FLogBuffer) then
    begin
      try
        OutputDebugString(PChar('����: ��־������δ��ʼ�����޷���ʼ����'));
        // �����µĻ�����
        FLogBuffer := TStringList.Create;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('������־������ʱ����: ' + E.Message));
          except
            // �������д���
          end;
          // ���û���ģʽ
          FBufferingLogs := False;
        end;
      end;
    end
    else
    begin
      // ��ջ�����
      try
        FLogBuffer.Clear;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('�����־������ʱ����: ' + E.Message));
          except
            // �������д���
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      try
        OutputDebugString(PChar('��ʼ��־����ʱ����: ' + E.Message));
      except
        // �������д���
      end;
      // ȷ������ģʽ������
      FBufferingLogs := False;
    end;
  end;
end;

// ������־���岢һ���Ը���MemLog
procedure TForm1.EndLogBuffering;
var
  i: Integer;
  StartIndex: Integer;
  LogCount: Integer;
begin
  try
    // �������ñ�־�������ڴ���������������־
    FBufferingLogs := False;

    // ��ȫ��飺ȷ��FLogBuffer�ѳ�ʼ��
    if not Assigned(FLogBuffer) then
    begin
      try
        OutputDebugString(PChar('����: ��־������δ��ʼ�����޷�ˢ����־'));
      except
        // �������д���
      end;
      Exit;
    end;

    // ��ȫ��飺ȷ��MemLog�ѳ�ʼ��
    if not Assigned(MemLog) then
    begin
      try
        OutputDebugString(PChar('����: MemLogδ��ʼ�����޷�ˢ����־'));
      except
        // �������д���
      end;
      Exit;
    end;

    // һ����������л������־
    LogCount := FLogBuffer.Count;
    if LogCount > 0 then
    begin
      try
        // ��������UI
        MemLog.Lines.BeginUpdate;
        try
          // �����־̫�ֻ࣬��ʾ���100��
          if LogCount > 100 then
          begin
            StartIndex := LogCount - 100;
            try
              MemLog.Lines.Add('���� ' + IntToStr(LogCount) + ' ����־��ֻ��ʾ���100��...');
            except
              on E: Exception do
              begin
                try
                  OutputDebugString(PChar('�����־ժҪ��Ϣʱ����: ' + E.Message));
                except
                  // �������д���
                end;
              end;
            end;
          end
          else
            StartIndex := 0;

          // ���������־����������ÿ����־���쳣
          for i := StartIndex to LogCount - 1 do
          begin
            try
              if (i >= 0) and (i < FLogBuffer.Count) then
                MemLog.Lines.Add(FLogBuffer[i]);
            except
              on E: EEncodingError do
              begin
                try
                  MemLog.Lines.Add('(����������־��)');
                  OutputDebugString(PChar('�������: �޷������־�� ' + IntToStr(i)));
                except
                  // �������д���
                end;
              end;
              on E: Exception do
              begin
                try
                  OutputDebugString(PChar('�����־��ʱ����: ' + E.Message));
                except
                  // �������д���
                end;
                // ����������һ����־
                Continue;
              end;
            end;
          end;
        finally
          try
            MemLog.Lines.EndUpdate;
          except
            on E: Exception do
            begin
              try
                OutputDebugString(PChar('������������ʱ����: ' + E.Message));
              except
                // �������д���
              end;
            end;
          end;
        end;

        // �������ײ�
        try
          MemLog.SelStart := Length(MemLog.Text);
          MemLog.SelLength := 0;
          MemLog.Perform(EM_SCROLLCARET, 0, 0);
        except
          on E: Exception do
          begin
            try
              OutputDebugString(PChar('�������ײ�ʱ����: ' + E.Message));
            except
              // �������д���
            end;
          end;
        end;

        // ��ջ�����
        try
          FLogBuffer.Clear;
        except
          on E: Exception do
          begin
            try
              OutputDebugString(PChar('�����־������ʱ����: ' + E.Message));
            except
              // �������д���
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('ˢ����־������ʱ����: ' + E.Message));
          except
            // �������д���
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      try
        OutputDebugString(PChar('���ش���: ������־��������г���δ������쳣: ' + E.Message));
      except
        // �������д���
      end;
    end;
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
    PChar(System.SysUtils.Format('ȷ��Ҫ�������ļ� (%d ��) ת��Ϊ��ǰѡ��ı���? ', [Length(AllFiles)])),
    '����ת��ȷ��',
    MB_YESNO + MB_ICONQUESTION) <> IDYES then
  begin
    Log('ȡ������ת��');
    Exit;
  end;

  // Start batch conversion
  Log('��ʼ����ת�������ļ�...');
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
        Log('- �ɹ�ת��: ' + AllFiles[i] + ' (�� ' + DetectedEncoding + ' �� ' +
          FEncodingModel.GetEncodingName(Encoding) + ')');
      end
      else
      begin
        Log('- ת��ʧ��: ' + AllFiles[i]);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('����ת�����: �ɹ� %d/%d ���ļ�', [SuccessCount, Length(AllFiles)]));
    if SuccessCount < Length(AllFiles) then
      Log(System.SysUtils.Format('ע��: %d ���ļ�δ�ܳɹ�ת�� (�����Ƿ��ı��ļ����޷�����)',
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
  FilePath: string;
  HasBOM: Boolean;
  DetectedEncoding: string;
  i: Integer;
begin
  // ��¼��ʼ����
  Log('��ʼ�����Ҽ��˵���ת��ѡ���ļ�������');

  if StringGrid1.RowCount <= 1 then
  begin
    Log('�����û���ļ�������ȡ��');
    Exit; // No files loaded
  end;

  // ��ȡѡ�еı�����Ϣ
  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    Log('δѡ��Ŀ����룬����ȡ��');
    ShowLocalizedMessage('MsgSelectTargetEncoding');
    Exit;
  end;
  SelectedIndex := Integer(TreeViewEncodings.Selected.Data);
  TargetInfo := FEncodingModel.Encodings[SelectedIndex];
  WithBOM := TargetInfo.HasBOM;
  Log('ѡ���Ŀ�����: ' + TargetInfo.Name + ', BOM: ' + BoolToStr(WithBOM, True));

  // ��ȡѡ�е��ļ�
  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);
  Log('�ҵ� ' + IntToStr(Length(SelectedFiles)) + ' ��ѡ�е��ļ�');

  if Length(SelectedFiles) = 0 then
  begin
    Log('û��ѡ���ļ�������ȡ��');
    ShowMessage('������ѡ��һ���ļ�����ת����');
    Exit;
  end;

  // ��ʼ����ת��
  Log('��ʼ����ת��ѡ�е��ļ�...');
  StartLogBuffering;
  SuccessCount := 0;

  try
    // ���õȴ����
    Screen.Cursor := crHourGlass;

    // ��������ѡ�е��ļ�����ת��
    for i := 0 to High(SelectedFiles) do
    begin
      FilePath := SelectedFiles[i];

      // ����ļ��Ƿ����
      if not FileExists(FilePath) then
      begin
        Log('�ļ������ڣ�����: ' + FilePath);
        Continue;
      end;

      // ��⵱ǰ����
      DetectedEncoding := FFileHelper.DetectFileEncoding(FilePath, HasBOM);
      Log('��⵽�ļ�����: ' + FilePath + ' - ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));

      // ����ת��
      if FEncodingController.ConvertSingleFile(FilePath, TargetInfo.ShortName, WithBOM) then
      begin
        Inc(SuccessCount);
        Log('- �ɹ�ת��: ' + FilePath + ' (�� ' + DetectedEncoding + ' �� ' + TargetInfo.Name + ')');

        // ���±���и��ļ���״̬
        UpdateSingleFileInGrid(FilePath);
      end
      else
      begin
        Log('- ת��ʧ��: ' + FilePath);
      end;
    end;

    // �������ת������ʾ���
    Log(System.SysUtils.Format('����ת�����: �ɹ� %d/%d ���ļ�', [SuccessCount, Length(SelectedFiles)]));

    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('ע��: %d ���ļ�δ�ܳɹ�ת�� (�����Ƿ��ı��ļ����޷�����)',
        [Length(SelectedFiles) - SuccessCount]));

    ShowMessage(System.SysUtils.Format('ת�����: �ɹ� %d/%d ���ļ�', [SuccessCount, Length(SelectedFiles)]));
  finally
    // �ָ����
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
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
  CurrentRowFile: string;
  FileName: string;
begin
  // ��¼��ʼ����
  Log('��ʼ�����Ҽ��˵�ת���ļ�����');

  // ���ȼ�鵱ǰѡ�е����Ƿ���Ч
  if (FSelectedRow > 0) and (FSelectedRow < StringGrid1.RowCount) and
     (StringGrid1.Cells[2, FSelectedRow] <> '') and
     (StringGrid1.Cells[2, FSelectedRow] <> '(���ļ�)') and
     (StringGrid1.Cells[2, FSelectedRow] <> '(Ŀ¼������)') and
     (StringGrid1.Cells[2, FSelectedRow] <> '(��ѡ������һ���ļ�����)') then
  begin
    // ��ȡ�ļ���
    FileName := StringGrid1.Cells[2, FSelectedRow];
    Log('��ǰѡ���е��ļ���: ' + FileName);

    // ��������·��
    CurrentRowFile := IncludeTrailingPathDelimiter(FSelectedFolder) + FileName;
    Log('����������·��: ' + CurrentRowFile);

    // ����ļ��Ƿ����
    if FileExists(CurrentRowFile) then
    begin
      SetLength(SelectedFiles, 1);
      SelectedFiles[0] := CurrentRowFile;
      Log('ʹ�õ�ǰ�е��ļ�: ' + CurrentRowFile);
    end
    else
    begin
      Log('�ļ�������: ' + CurrentRowFile);
      ShowMessage('�ļ�������: ' + CurrentRowFile);
      Exit;
    end;
  end
  else
  begin
    // �����ǰ����Ч�����Ի�ȡѡ�е��ļ�
    Log('��ǰ����Ч�����Ի�ȡѡ�е��ļ�');
    SelectedFiles := FFileHelper.GetSelectedFilesInFolder(FSelectedFolder, FFileExtensions,
      function(const FilePath: string): Boolean
      begin
        Result := False; // Assume no file selected first

        // Find this file in the grid
        for var j := 1 to StringGrid1.RowCount - 1 do
        begin
          if (StringGrid1.Cells[2, j] <> '') and
             (FilePath = IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[2, j]) and
             (StringGrid1.Cells[0, j] = TUIHelper.GetCheckMark) then
          begin
            Result := True;
            Break;
          end;
        end;
      end,
      FIncludeSubdirs
    );

    // �����Ȼû���ļ���ת����ֱ���˳�
    if Length(SelectedFiles) = 0 then
    begin
      Log('û��ѡ���ļ���Ҳû����Ч�ĵ�ǰ���ļ�������ȡ��');
      ShowMessage('��ѡ��Ҫת�����ļ�');
      Exit;
    end;
  end;

  // Get selected encoding (from TreeView)
  Encoding := FEncodingModel.GetSelectedEncoding;

  // Start batch conversion
  Log('��ʼת��ѡ�е��ļ�...');
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
        Log('- �ɹ�ת��: ' + FilePath + ' (�� ' + DetectedEncoding + ' �� ' +
          FEncodingModel.GetEncodingName(Encoding) + ')');

        // Update the status of this file in the grid
        UpdateSingleFileInGrid(FilePath);
      end
      else
      begin
        Log('- ת��ʧ��: ' + FilePath);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('����ת�����: �ɹ� %d/%d ���ļ�', [SuccessCount, Length(SelectedFiles)]));

    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('ע��: %d ���ļ�δ�ܳɹ�ת�� (�����Ƿ��ı��ļ����޷�����)',
        [Length(SelectedFiles) - SuccessCount]));

    ShowMessage(System.SysUtils.Format('ת�����: �ɹ� %d/%d ���ļ�', [SuccessCount, Length(SelectedFiles)]));
  finally
    // Restore cursor
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;

procedure TForm1.MenuItemToggleSelectClick(Sender: TObject);
begin
  // ȫѡ/ȡ��ȫѡ
  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.MenuItemViewContentClick(Sender: TObject);
begin
  // ֱ�ӵ��ð�ť�ĵ���¼�
  btnShowContentClick(Sender);
end;

procedure TForm1.MenuItemCopyFullPathClick(Sender: TObject);
var
  FullPath: string;
begin
  // ȷ��ѡ������Ч����
  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;

  // ��ȡѡ�е��ļ�ȫ·��
  FullPath := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[2, FSelectedRow];

  // ���Ƶ�������
  Clipboard.AsText := FullPath;

  // ��¼��־
  Log('�Ѹ����ļ�ȫ·����������: ' + FullPath);
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

  // ��ȡ��ǰ���λ�ö�Ӧ�ĵ�Ԫ��
  Grid.MouseToCell(P.X, P.Y, Col, Row);

  // ��������Ч�У����Ǳ�ͷ��
  if Row > 0 then
  begin
    // ѡ������
    Grid.Row := Row;
    FSelectedRow := Row;

    // ��������һ�У�Checkbox�У�
    if Col = 0 then
    begin
      // �л�Checkbox״̬
      if Grid.Cells[Col, Row] = TUIHelper.GetCheckMark then
        Grid.Cells[Col, Row] := ''
      else
        Grid.Cells[Col, Row] := TUIHelper.GetCheckMark;
    end;
  end;
end;

procedure TForm1.StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  GridCoord: TGridCoord;
begin
  GridCoord := StringGrid1.MouseCoord(MousePos.X, MousePos.Y);

  // ȷ�����������Ч��������
  if (GridCoord.Y > 0) and (GridCoord.Y < StringGrid1.RowCount) then
  begin
    StringGrid1.Row := GridCoord.Y;
    FSelectedRow := GridCoord.Y;
    // ��ʽ������˵�������������Ĭ����Ϊ
    GridPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end
  else
  begin
    // ���������Ĳ˵�
    MenuItemConvertCurrent.Enabled := False;
    MenuItemToggleSelect.Enabled := False;
    MenuItemViewContent.Enabled := False;
    Handled := True;
  end;
end;

procedure TForm1.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // ��¼ѡ�е���
  FSelectedRow := ARow;
end;

procedure TForm1.UpdateFileExtensions(const FolderPath: string);
var
  Extensions: TArray<string>;
  i: Integer;
  SafePath: string;
begin
  // ��ȫ��飺ȷ��UI����ѳ�ʼ��
  if not Assigned(CheckListBox1) then
  begin
    Log('����: CheckListBox1δ��ʼ��');
    Exit;
  end;

  // ��ȫ��飺ȷ��FFileExtensions�ѳ�ʼ��
  if not Assigned(FFileExtensions) then
  begin
    Log('����: FFileExtensionsδ��ʼ��');
    Exit;
  end;

  // ��ȫ��飺ȷ��FFileHelper�ѳ�ʼ��
  if not Assigned(FFileHelper) then
  begin
    Log('����: FFileHelperδ��ʼ��');
    Exit;
  end;

  // ���CheckListBox
  try
    CheckListBox1.Clear;
    FFileExtensions.Clear;
  except
    on E: Exception do
    begin
      Log('����б�ʱ����: ' + E.Message);
      // ����ִ�У�������������б�
    end;
  end;

  // ��ȫ��飺ȷ��Ŀ¼·����Ч
  if FolderPath = '' then
  begin
    Log('����: �ṩ��Ŀ¼·��Ϊ��');
    Exit;
  end;

  // �淶��·���������������
  try
    SafePath := ExcludeTrailingPathDelimiter(FolderPath);
    SafePath := IncludeTrailingPathDelimiter(SafePath);
  except
    on E: Exception do
    begin
      Log('·����ʽ������: ' + E.Message);
      SafePath := FolderPath; // ʹ��ԭʼ·��
    end;
  end;

  // ��ȫ��飺ȷ��Ŀ¼����
  if not System.SysUtils.DirectoryExists(SafePath) then
  begin
    Log('Ŀ¼������: ' + SafePath);
    Exit;
  end;

  try
    // ��ȡ�ļ����е�������չ��
    try
      Log('���ڻ�ȡĿ¼�е��ļ���չ��: ' + SafePath);
      Extensions := FFileHelper.GetFileExtensions(SafePath);
    except
      on E: Exception do
      begin
        Log('��ȡ�ļ���չ��ʱ����: ' + E.Message);
        SetLength(Extensions, 0); // ȷ��Extensions��һ��������
      end;
    end;

    // ��ȫ��飺ȷ�����ص�������Ч
    if Length(Extensions) = 0 then
    begin
      Log('δ�ҵ��κ��ļ���չ��');
      Exit;
    end;

    // ��ӵ�CheckListBox��FFileExtensions
    for i := 0 to High(Extensions) do
    begin
      try
        // ��ȫ��飺ȷ����չ����Ч
        if Extensions[i] = '' then
          Continue;

        // ��ӵ�UI���ڲ��б�
        CheckListBox1.Items.Add(Extensions[i]);
        FFileExtensions.Add(Extensions[i]);

        // Ĭ��ѡ�г���.exe��.dll�����������չ��
        if (Extensions[i] <> '.exe') and (Extensions[i] <> '.dll') then
          CheckListBox1.Checked[i] := True;
      except
        on E: Exception do
        begin
          Log('�����չ��ʱ����: ' + Extensions[i] + ' - ' + E.Message);
          // ����������һ����չ��
          Continue;
        end;
      end;
    end;

    // ��¼�ɹ���Ϣ
    if CheckListBox1.Items.Count > 0 then
      Log('�ɹ����� ' + IntToStr(CheckListBox1.Items.Count) + ' ���ļ���չ��')
    else
      Log('δ�ܼ����κ��ļ���չ��');
  except
    on E: EEncodingError do
    begin
      Log('�������: ' + E.Message);
      // �ر���������
      try
        // ����ʹ��Ĭ�ϱ���
        Log('����ʹ��Ĭ�ϱ��봦��·��');
        Extensions := FFileHelper.GetFileExtensions('C:\');

        // ����ɹ���ȡ����չ������ӵ��б�
        if Length(Extensions) > 0 then
        begin
          for i := 0 to High(Extensions) do
          begin
            try
              CheckListBox1.Items.Add(Extensions[i]);
              FFileExtensions.Add(Extensions[i]);

              // Ĭ��ѡ�г���.exe��.dll�����������չ��
              if (Extensions[i] <> '.exe') and (Extensions[i] <> '.dll') then
                CheckListBox1.Checked[i] := True;
            except
              Continue;
            end;
          end;
          Log('ʹ��Ĭ��Ŀ¼�ɹ����� ' + IntToStr(CheckListBox1.Items.Count) + ' ���ļ���չ��');
        end;
      except
        on E2: Exception do
          Log('ʹ��Ĭ�ϱ��봦��·��Ҳʧ��: ' + E2.Message);
      end;
    end;
    on E: Exception do
    begin
      Log('�����ļ���չ���б�ʱ����: ' + E.Message);
      // ͨ���쳣����
    end;
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
  SelectedFileNames: TStringList; // ���ڴ洢ˢ��ǰѡ�е��ļ���
  HasSelectedExtensions: Boolean;
  FileCount: Integer;
begin
  // ��ʼ��־���壬����UI����
  StartLogBuffering;

  // ���浱ǰѡ�е��ļ����Ա���ˢ�º�ָ�ѡ��״̬
  SelectedFileNames := TStringList.Create;
  try
    // ��ȡ��ǰѡ�е��ļ���
    for i := 1 to StringGrid1.RowCount - 1 do
    begin
      if (StringGrid1.Cells[0, i] = TUIHelper.GetCheckMark) and (StringGrid1.Cells[2, i] <> '') then
        SelectedFileNames.Add(StringGrid1.Cells[2, i]);

    end;

    // ��ձ��
    FUIHelper.ClearGrid(StringGrid1);

    // (Fix Deprecation Warning)
    if not System.SysUtils.DirectoryExists(FolderPath) then // Ensure qualified
    begin
      StringGrid1.Cells[2, 1] := '(Ŀ¼������)';
      // ȷ���п���ȷ
      AdjustGridColumnWidths;
      EndLogBuffering; // ������־����
      Exit;
    end;

    Screen.Cursor := crHourGlass;
    try
      // ��ȡѡ�е��ļ���չ��
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

      // ���û��ѡ���κ��ļ����ͣ���ʾ��ʾ���˳�
      if not HasSelectedExtensions then
      begin
        Log('δѡ���κ��ļ����ͣ�����ʾ�ļ�');
        StringGrid1.Cells[2, 1] := '(��ѡ������һ���ļ�����)';
        // ȷ���п���ȷ
        AdjustGridColumnWidths;
        EndLogBuffering; // ������־����
        Exit;
      end;

      // ��¼�������ã�ʹ��Ӣ�ģ�����Դ�ļ��������⣩
      Log('Start searching files: ' + FolderPath + ', include subdirectories: ' + BoolToStr(FIncludeSubdirs, True));

      // ���������Ŀ¼���ڽ�������ȷ��ʾ��ʹ�ñ��ػ���Ϣ��
      if FIncludeSubdirs then
        Log(GetLocalizedMessage('LogSubdirEnabled'))
      else
        Log(GetLocalizedMessage('LogSubdirDisabled'));

      // ��ʾ����������ʾ
      ProgressBar1.Visible := True;
      lblProgress.Visible := True;
      lblProgress.Caption := GetLocalizedMessage('ProgressSearchingFiles');
      ProgressBar1.Position := 0;
      Application.ProcessMessages;

      // ��ȡ�ļ��б� - ʹ��FIncludeSubdirs��FMaxDepth����
      Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions, FIncludeSubdirs, FMaxDepth);

      // ��¼�ҵ����ļ�����
      FileCount := Length(Files);
      Log(GetLocalizedMessageFmt('LogFilesFound', [FileCount]));

      // �ļ�����ȷ�ϻ��� �� �ڹؼ���ֵ�������û�ȷ��
      if FileCount >= 2000 then
      begin
        var ConfirmThresholds: array of Integer;
        var ThresholdCaptions: array of string;
        var ti: Integer;
        ConfirmThresholds := [2000, 5000, 20000, 100000, 500000];
        ThresholdCaptions := ['2,000', '5,000', '2��', '10��', '50��'];

        // �ҵ���ǰ�ļ�����Ӧ�������ֵ
        ti := High(ConfirmThresholds);
        while (ti >= 0) and (FileCount < ConfirmThresholds[ti]) do
          Dec(ti);

        if ti >= 0 then
        begin
          var Msg := Format('��ɨ�赽 %d ���ļ������� %s ��ֵ�����Ƿ������',
            [FileCount, ThresholdCaptions[ti]]);
          if Application.MessageBox(PChar(Msg), '�ļ�����ȷ��',
            MB_YESNO or MB_ICONQUESTION) = IDNO then
          begin
            Log('�û�ȡ���˴��ģ�ļ�ɨ��');
            ProgressBar1.Visible := False;
            lblProgress.Visible := False;
            EndLogBuffering;
            Exit;
          end;
        end;
      end;

      // ���ý�������Χ
      if FileCount > 0 then
      begin
        ProgressBar1.Max := FileCount;
        ProgressBar1.Position := 0;
        lblProgress.Caption := GetLocalizedMessageFmt('ProgressDetectingEncoding', [FileCount]);
        Application.ProcessMessages;
      end;

      // ����UI���£��������
      StringGrid1.BeginUpdate;
      try
        // Ԥ�����ñ�����������⶯̬����
        // ע�⣺��������Ϊ2����AddFileToGridAt�Զ���������
        StringGrid1.RowCount := 2;

        // ��ӵ����
        for i := 0 to High(Files) do
        begin
          FileName := ExtractFileName(Files[i]);

          // ����ļ�����
          EncodingName := FFileHelper.DetectFileEncoding(Files[i], HasBOM);

          // �����ļ��Ƿ�Ӧ�ñ�ѡ�� - ���֮ǰѡ�й������ѡ��
          ExtSelected := SelectedFileNames.IndexOf(FileName) >= 0;

          // ��ӵ����ʹ�ñ����ѡ��״̬����������1��ʼ��
          FUIHelper.AddFileToGridAt(StringGrid1, i + 1, FileName, EncodingName, ExtSelected);

          // �����ļ�������̬��������Ƶ�ʣ�����UI����
          var UpdateInterval := 50; // Ĭ��50���ļ�����һ��
          if FileCount < 100 then
            UpdateInterval := 10  // С��100���ļ�ʱ10������һ��
          else if FileCount > 1000 then
            UpdateInterval := 100; // ����1000���ļ�ÿ100������һ��

          if (i > 0) and ((i mod UpdateInterval = 0) or (i = High(Files))) then
          begin
            ProgressBar1.Position := i;
            lblProgress.Caption := GetLocalizedMessageFmt('ProgressDetecting', [i, FileCount, i / FileCount * 100]);
            Application.ProcessMessages; // ����UI��Ӧ
          end;
        end;

        // �����½���Ϊ100%
        if FileCount > 0 then
        begin
          ProgressBar1.Position := FileCount;
          lblProgress.Caption := GetLocalizedMessageFmt('ProgressCompleteFiles', [FileCount]);
          Application.ProcessMessages;
        end;
      finally
        StringGrid1.EndUpdate;
      end;

      // ���û���ļ��������ʾ
      if (FileCount = 0) or (StringGrid1.Cells[2, 1] = '') then
        StringGrid1.Cells[2, 1] := '(���ļ�)';

      // ȷ���п���ȷ
      AdjustGridColumnWidths;

      // ��¼�����Ϣ
      Log(GetLocalizedMessageFmt('LogDetectionComplete', [FileCount]));
      
      // ���ؽ�����
      Sleep(300); // ��΢�ӳ��Ա��û��������״̬
      ProgressBar1.Visible := False;
      lblProgress.Visible := False;
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    SelectedFileNames.Free;
    EndLogBuffering; // ������־���壬һ���Ը�����־
  end;
end;

procedure TForm1.InvalidateForm;
begin
  // ʹ�ü̳еķ����ػ洰��
  inherited Invalidate;
  // ǿ�ƴ���������Ϣ�����е��¼�
  Application.ProcessMessages;
end;

function TForm1.GetLocalizedMessage(const MsgId: string): string;
var
  LangStrings: TLanguageStrings;
  Context: TRttiContext;
  RttiType: TRttiType;
  RttiField: TRttiField;
begin
  // ��ȡ��ǰ���Ե��ַ���
  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

  // ʹ���ִ�RTTI��ȡ����ֵ
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
          Result := MsgId; // ����ֶ�ֵΪ�գ�������ϢID
      end
      else
        Result := MsgId; // ����ֶβ����ڣ�������ϢID
    end
    else
      Result := MsgId; // ���������Ϣ�����ڣ�������ϢID
  finally
    Context.Free;
  end;
end;

function TForm1.GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
begin
  Result := System.SysUtils.Format(GetLocalizedMessage(MsgId), Args);
end;

// ��ʾ���ػ�����Ϣ�Ի���
procedure TForm1.ShowLocalizedMessage(const MsgId: string);
var
  Title: string;
begin
  // ��ȡ��ǰ���ԵĴ��ڱ���
  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;

  // ��ʾ��Ϣ�Ի���
  Application.MessageBox(PChar(GetLocalizedMessage(MsgId)), PChar(Title), MB_OK + MB_ICONINFORMATION);
end;

// ��ʾ��ʽ���ı��ػ���Ϣ�Ի���
procedure TForm1.ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);
var
  Title: string;
begin
  // ��ȡ��ǰ���ԵĴ��ڱ���
  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;

  // ��ʾ��ʽ������Ϣ�Ի���
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
  // ��ȡ�ļ���
  FileName := ExtractFileName(FilePath);

  // ����ļ�����
  EncodingName := FFileHelper.DetectFileEncoding(FilePath, HasBOM);

  // �ڱ���в��Ҹ��ļ�
  Found := False;
  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[2, i] = FileName then
    begin
      // ���±�����Ϣ
      StringGrid1.Cells[1, i] := EncodingName;
      Found := True;
      Break;
    end;
  end;

  // ��������û�и��ļ���������Ҫ���������
  if not Found and (FileName <> '') then
  begin
    Log('�ļ� ' + FileName + ' ת����ɣ�����: ' + EncodingName);
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
  // ȷ��ѡ������Ч����
  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;

  // ��ȡѡ�е��ļ�·��
  SelectedFile := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[2, FSelectedRow];
  if not FileExists(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgFileNotExists', [SelectedFile]);
    Exit;
  end;

  // ����Ƿ�Ϊ�ı��ļ�
  if not FFileHelper.IsNormalTextFile(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(SelectedFile)]);
    Exit;
  end;

  try
    // ����ļ�����
    Log('���ڼ���ļ�����: ' + SelectedFile);
    HasBOM := False;
    DetectedEncoding := FFileHelper.DetectFileEncoding(SelectedFile, HasBOM);
    Encoding := nil; // ���ǽ�ʹ�����ƶ����Ǳ������

    Log('��⵽�ļ�����: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));

    // ��ȫ�ش�����ǰ��ʵ��
    if Assigned(SynEditForm) then
    begin
      // ���ʵ���Ѵ��ڣ��������ض����ͷ�
      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('������ǰ��SynEditFormʵ��');
        end;
      except
        on E: Exception do
        begin
          Log('����SynEditFormʧ��: ' + E.Message);
          // �������ʧ�ܣ������ͷ�
          try
            FreeAndNil(SynEditForm);
            Log('�ͷ���ǰ��SynEditFormʵ��');
          except
            on E2: Exception do
            begin
              Log('�ͷ�SynEditFormʧ��: ' + E2.Message);
              // �����ͷŴ��󣬼���������ʵ��
            end;
          end;
        end;
      end;
    end;

    // ȷ��ʵ��Ϊ��
    if Assigned(SynEditForm) then
    begin
      // ���ʵ����Ȼ���ڣ�����������
      Log('��������SynEditFormʵ��');
    end
    else
    begin
      // �����µ�SynEditFormʵ��
      Log('���ڴ����µ�SynEditFormʵ��...');
      try
        SynEditForm := TSynEditForm.Create(Self, FFileHelper);
        if not Assigned(SynEditForm) then
        begin
          ShowLocalizedMessage('MsgCannotCreateViewer');
          Log('����SynEditFormʧ��: ʵ��Ϊ��');
          Exit;
        end;
        Log('�ɹ������µ�SynEditFormʵ��');
      except
        on E: Exception do
        begin
          ShowLocalizedMessageFmt('MsgCannotCreateViewer', [E.Message]);
          Log('����SynEditFormʧ��: ' + E.Message);
          Exit;
        end;
      end;
    end;

    // ʹ��ʵ�������ļ�
    Log('���ڴ��ļ�: ' + SelectedFile);
    try
      // ʹ�ü�⵽�ı�������ļ�
      Log('ʹ�ü�⵽�ı�������ļ�: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));

      // ���ݼ�⵽�ı��봴����Ӧ��TEncoding����
      var FileEncoding: TEncoding := nil;
      try
        if SameText(DetectedEncoding, 'UTF-8') or SameText(DetectedEncoding, 'UTF-8 with BOM') then
          FileEncoding := TEncoding.UTF8
        else if SameText(DetectedEncoding, 'UTF-16LE') then
          FileEncoding := TEncoding.Unicode
        else if SameText(DetectedEncoding, 'UTF-16BE') then
          FileEncoding := TEncoding.BigEndianUnicode
        else if SameText(DetectedEncoding, 'GBK') or SameText(DetectedEncoding, 'GB2312') then
          FileEncoding := TEncoding.GetEncoding(936) // GBK����ҳ
        else if SameText(DetectedEncoding, 'BIG5') then
          FileEncoding := TEncoding.GetEncoding(950) // BIG5����ҳ
        else
          FileEncoding := TEncoding.Default;

        // ʹ��ָ����������ļ�
        SynEditForm.SetFileInfo(SelectedFile);
        SynEditForm.LoadFileWithEncoding(SelectedFile, FileEncoding, DetectedEncoding, HasBOM);
        Log('�ɹ������ļ���SynEditForm������: ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));
      finally
        // �ͷŷǱ�׼�������
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
        Log('LoadFileWithEncodingʧ��: ' + E.Message);

        // �������ʧ�ܣ�����ʹ��Ĭ�ϱ���
        try
          Log('����ʹ��Ĭ�ϱ�������ļ�...');
          SynEditForm.LoadFile(SelectedFile);
          Log('ʹ��Ĭ�ϱ���ɹ������ļ�');
        except
          on E2: Exception do
          begin
            Log('ʹ��Ĭ�ϱ�������ļ�Ҳʧ��: ' + E2.Message);
            // ���ͷ�ʵ����ֻ���˳�
            Exit;
          end;
        end;
      end;
    end;

    // ��λ�������������Ҳ�(�����Ļ�ռ��㹻)
    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50; // ��΢ƫ��

      // �����С�������ʱ���ã���������ʱ����

      // ��ʾʵ������ģ̬��
      SynEditForm.Show;
      SynEditForm.BringToFront; // ȷ�����ڿɼ�
      Log('�ɹ���ʾ�ļ�: ' + SelectedFile);
    except
      on E: Exception do
      begin
        ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
        Log('��ʾSynEditFormʧ��: ' + E.Message);
        // ���ͷ�ʵ����ֻ�Ǽ�¼����
      end;
    end;
  except
    on E: Exception do
    begin
      ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
      Log('�鿴�ļ�ʧ��: ' + E.Message);
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
    // ��ȡ��ǰ�����ַ���
    LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

    // ��¼������ʼ
    Log('ѡ��/ȡ��ѡ�������ļ����Ͳ�����ʼ');

    // ����Ƿ�������Ŀ���Ѿ�ѡ��
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

    // ��ʾ״̬��Ϣ
    Log('��ǰ״̬: ȫ��ѡ��=' + BoolToStr(AllChecked, True) +
        ', ����ѡ��=' + BoolToStr(AnyChecked, True) +
        ', ѡ������=' + IntToStr(SelectedCount));

    // ������ж�ѡ�л򲿷�ѡ�У���ȫ��ȡ��ѡ��
    // �����ûѡ�У���ȫ��ѡ��
    if AllChecked or AnyChecked then
    begin
      // ȫ��ȡ��ѡ��
      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := False;
      end;

      btnSelectAllExt.Caption := LangStrings.BtnSelectAllFileTypes;
      Log(LangStrings.LogDeselectAllFileTypes);
    end
    else
    begin
      // ȫ��ѡ��
      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := True;
      end;

      btnSelectAllExt.Caption := LangStrings.BtnDeselectAllFileTypes;
      Log(LangStrings.LogSelectAllFileTypes);
    end;

    // ֱ�ӵ���UpdateFileCountLabel������״̬��ʾ
    UpdateFileCountLabel;

    // ȷ��Ŀ¼��Ч
    if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
    begin
      // ��ղ����¼����ļ��б�
      Log(LangStrings.LogForceUpdateFileList);
      StringGrid1.RowCount := 2; // ���ñ��ֻ���������
      StringGrid1.Rows[1].Clear(); // ��յ�һ��������

      // ֱ�Ӹ����ļ��б�
      UpdateFileGrid(DirectoryListBox1.Directory);

      // ��¼��ǰѡ�е��ļ���������
      SelectedCount := 0;
      for i := 0 to CheckListBox1.Items.Count - 1 do
        if CheckListBox1.Checked[i] then
          Inc(SelectedCount);

      Log('�ļ��б��Ѹ��£���ǰѡ��' + IntToStr(SelectedCount) + '���ļ�����');

      // ǿ�Ƹ���UI
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log('ȫѡ���Ͱ�ť��������: ' + E.Message);
  end;
end;

procedure TForm1.UpdateFileCountLabel;
var
  i, SelectedCount: Integer;
  TotalFiles: Integer;
begin
  // ����ѡ�е��ļ���������
  SelectedCount := 0;
  for i := 0 to CheckListBox1.Items.Count - 1 do
    if CheckListBox1.Checked[i] then
      Inc(SelectedCount);

  // ��ȡ���ļ�����
  TotalFiles := 0;
  for i := 1 to StringGrid1.RowCount - 1 do
    if (StringGrid1.Cells[2, i] <> '') and
       (StringGrid1.Cells[2, i] <> '(���ļ�)') and
       (StringGrid1.Cells[2, i] <> '(Ŀ¼������)') and
       (StringGrid1.Cells[2, i] <> '(��ѡ������һ���ļ�����)') then
      Inc(TotalFiles);

  // �������־
  Log('�ļ�����ͳ��: ��ѡ�� ' + IntToStr(SelectedCount) + '/' +
      IntToStr(CheckListBox1.Items.Count) + ' �����ͣ��� ' +
      IntToStr(TotalFiles) + ' ���ļ�');
end;

procedure TForm1.TreeViewEncodingsAdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages,
  DefaultDraw: Boolean);
var
  Tree: TTreeView;
  NodeText: string;
  BracketPos: Integer;
  EncodingPart, DescPart: string;
  TextRect: TRect;
  TextWidth: Integer;
  IsSelected: Boolean;
begin
  Tree := Sender as TTreeView;

  if Stage = cdPrePaint then
  begin
    IsSelected := cdsSelected in State;

    case Node.Level of
      0: // ���ڵ�
      begin
        Tree.Canvas.Font.Style := [fsBold];
        Tree.Canvas.Font.Size := FOriginalFontSize + 2;
        if not IsSelected then
          Tree.Canvas.Font.Color := clNavy
        else
          Tree.Canvas.Font.Color := clHighlightText;
      end;

      1: // ����ڵ�
      begin
        Tree.Canvas.Font.Style := [fsBold];
        Tree.Canvas.Font.Size := FOriginalFontSize + 1;
        if not IsSelected then
          Tree.Canvas.Font.Color := clBlue
        else
          Tree.Canvas.Font.Color := clHighlightText;
      end;

      else // ����ڵ㣨��˵����
      begin
        NodeText := Node.Text;
        BracketPos := Pos('(', NodeText);

        if BracketPos > 0 then
        begin
          DefaultDraw := False; // �����Ի��ı�

          EncodingPart := Trim(Copy(NodeText, 1, BracketPos - 1));
          DescPart := Copy(NodeText, BracketPos, MaxInt);

          TextRect := Node.DisplayRect(True);

          if IsSelected then
          begin
            // ѡ��״̬����
            Tree.Canvas.Brush.Color := clHighlight;
            Tree.Canvas.FillRect(TextRect);

            // ���ƣ���ɫ�Ӵ֣�
            Tree.Canvas.Font.Style := [fsBold];
            Tree.Canvas.Font.Color := clHighlightText;
            Tree.Canvas.TextOut(TextRect.Left, TextRect.Top, EncodingPart);

            // ��������ɫ��ͨ��
            TextWidth := Tree.Canvas.TextWidth(EncodingPart);
            Tree.Canvas.Font.Style := [];
            Tree.Canvas.Font.Color := clHighlightText;
            Tree.Canvas.TextOut(TextRect.Left + TextWidth, TextRect.Top, ' ' + DescPart);
          end
          else
          begin
            // δѡ�У����ƺ�ɫ�Ӵ֣�������ɫ
            Tree.Canvas.Font.Style := [fsBold];
            Tree.Canvas.Font.Size := FOriginalFontSize;
            Tree.Canvas.Font.Color := clWindowText;
            Tree.Canvas.TextOut(TextRect.Left, TextRect.Top, EncodingPart);

            TextWidth := Tree.Canvas.TextWidth(EncodingPart);
            Tree.Canvas.Font.Style := [];
            Tree.Canvas.Font.Color := clGray;
            Tree.Canvas.TextOut(TextRect.Left + TextWidth, TextRect.Top, ' ' + DescPart);
          end;

          Exit;
        end
        else
        begin
          // ��˵�������Ӵ�����
          Tree.Canvas.Font.Style := [fsBold];
          Tree.Canvas.Font.Size := FOriginalFontSize;
          if not IsSelected then
            Tree.Canvas.Font.Color := clWindowText
          else
            Tree.Canvas.Font.Color := clHighlightText;
        end;
      end;
    end;
  end;
end;

procedure TForm1.InitTreeIcons;
var
  bmp: Vcl.Graphics.TBitmap;
  procedure AddIcon(const DrawProc: TProc<Vcl.Graphics.TCanvas>);
  begin
    bmp.SetSize(16, 16);
    bmp.PixelFormat := pf32bit;
    bmp.Canvas.Brush.Style := bsSolid;
    // ��Ϳ����Ϊ͸��ɫ����
    bmp.Canvas.Brush.Color := clWhite;
    bmp.Canvas.Pen.Color := clWhite;
    bmp.Canvas.Rectangle(0, 0, 16, 16);
    SetBkMode(bmp.Canvas.Handle, TRANSPARENT);
    bmp.Transparent := True;
    bmp.TransparentColor := clWhite;
    // ��������
    DrawProc(bmp.Canvas);
    if not Assigned(FIconList) then
    begin
      FIconList := TImageList.Create(Self);
      FIconList.Width := 16;
      FIconList.Height := 16;
      FIconList.ColorDepth := cd32Bit;
      FIconList.Masked := True;
      FIconList.BkColor := clWhite;
    end
    else
      FIconList.Clear;
    FIconList.AddMasked(bmp, clWhite);
  end;

  procedure AddIconNoClear(const DrawProc: TProc<Vcl.Graphics.TCanvas>);
  begin
    // ��ͬһ��imagelist��׷��
    bmp.SetSize(16, 16);
    bmp.PixelFormat := pf32bit;
    bmp.Canvas.Brush.Color := clWhite;
    bmp.Canvas.Pen.Color := clWhite;
    bmp.Canvas.Rectangle(0, 0, 16, 16);
    SetBkMode(bmp.Canvas.Handle, TRANSPARENT);
    bmp.Transparent := True;
    bmp.TransparentColor := clWhite;
    DrawProc(bmp.Canvas);
    FIconList.AddMasked(bmp, clWhite);
  end;
begin
  // ����ѳ�ʼ�����������㣬ֱ�ӷ���
  if Assigned(FIconList) and (FIconList.Count >= 10) then
    Exit;

  bmp := Vcl.Graphics.TBitmap.Create;
  try
    // ����/���ImageList����������Ӹ���ͼ��
    // 0: Root (App)
    AddIcon(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(0,122,204);
        C.Pen.Color := RGB(0,90,160);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        C.Pen.Color := clWhite;
        C.MoveTo(R.Left+2, R.Top+3); C.LineTo(R.Right-2, R.Top+3);
        C.MoveTo(R.Left+2, R.Top+5); C.LineTo(R.Right-2, R.Top+5);
        C.MoveTo(R.Left+2, R.Top+7); C.LineTo(R.Left+7, R.Top+7);
      end);

    // 1: Unicode (U)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(120, 80, 200);
        C.Pen.Color := RGB(90, 60, 160);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'U';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 2: Asian (��)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(0, 160, 80);
        C.Pen.Color := RGB(0,120,60);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := '��';
        C.Font.Color := clWhite; C.Font.Size := 7; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 3: Western (W)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(0, 150, 220);
        C.Pen.Color := RGB(0,110,180);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'W';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 4: Eastern (E)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(230, 120, 20);
        C.Pen.Color := RGB(190,90,10);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'E';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 5: MiddleEast (ME)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(200, 80, 80);
        C.Pen.Color := RGB(160,60,60);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'ME';
        C.Font.Color := clWhite; C.Font.Size := 7; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 6: Nordic (N)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(60, 160, 220);
        C.Pen.Color := RGB(40,120,180);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'N';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 7: Southern (S)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(120, 180, 60);
        C.Pen.Color := RGB(90,140,40);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'S';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 8: Other (O)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(160, 160, 160);
        C.Pen.Color := RGB(120,120,120);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := 'O';
        C.Font.Color := clWhite; C.Font.Size := 8; C.Font.Style := [fsBold];
        TW := C.TextWidth(S); TH := C.TextHeight(S);
        C.TextOut(R.Left + (R.Right-R.Left-TW) div 2, R.Top + (R.Bottom-R.Top-TH) div 2, S);
      end);

    // 9: Encoding (document)
    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect;
      begin
        // ���������ĵ�ͼ�꣺���۽Ǻ���������
        R := Rect(3,2,13,14);
        // �ĵ�����
        C.Brush.Color := clWhite;
        C.Pen.Color := RGB(150,150,150);
        C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
        // �����۽�
        C.Pen.Color := RGB(180,180,180);
        C.MoveTo(R.Right-5, R.Top);
        C.LineTo(R.Right-1, R.Top+4);
        C.LineTo(R.Right-1, R.Bottom-1);
        C.LineTo(R.Left, R.Bottom-1);
        // �ĵ�����
        C.Pen.Color := RGB(110,110,110);
        C.MoveTo(R.Left+2, R.Top+4); C.LineTo(R.Right-2, R.Top+4);
        C.MoveTo(R.Left+2, R.Top+6); C.LineTo(R.Right-2, R.Top+6);
        C.MoveTo(R.Left+2, R.Top+8); C.LineTo(R.Right-4, R.Top+8);
      end);
  finally
    bmp.Free;
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
    // ����TreeView�е����нڵ�
    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];
      NodeLevel := Node.Level;

      // ������б���ڵ㣨�Ǹ��ڵ�ͷǷ������ڵ㣩
      // ע�⣺����HelperUI.SetupEncodingList��ʵ�֣�����ڵ������Level=1��Level=2
      if (NodeLevel > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);

        // ����Ƿ�ΪUTF-8 BOM�ڵ�
        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin
          // �������Ƿ�ΪUTF-8����BOM
          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (FEncodingModel.Encodings[NodeData].HasBOM) then
          begin
            // ѡ�иýڵ�
            TreeViewEncodings.Selected := Node;

            // ȷ���ýڵ�ɼ���չ�����ڵ㣩
            Node.MakeVisible;

            // ��¼��־
            Log('Ĭ��ѡ�б���: ' + Node.Text);

            // �ҵ����˳�ѭ��
            Exit;
          end;
        end;
      end;
    end;

    // ���û���ҵ�UTF-8 BOM�����Բ�����ͨUTF-8����BOM��
    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];

      if (Node.Level > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);

        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin
          // ������ͨUTF-8
          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (not FEncodingModel.Encodings[NodeData].HasBOM) then
          begin
            TreeViewEncodings.Selected := Node;
            Node.MakeVisible;
            Log('û���ҵ�UTF-8 BOM��ѡ����ͨUTF-8: ' + Node.Text);
            Exit;
          end;
        end;
      end;
    end;

    Log('δ�ҵ�UTF-8����ڵ㣬δ����Ĭ�ϱ���');
  except
    on E: Exception do
      Log('����Ĭ�ϱ���ʧ��: ' + E.Message);
  end;
end;

procedure TForm1.ScrollEncodingTreeToLeft;
begin
  try
    if Assigned(TreeViewEncodings) and TreeViewEncodings.HandleAllocated then
    begin
      // ��ˮƽ�������ƶ��������
      TreeViewEncodings.Perform(WM_HSCROLL, SB_LEFT, 0);
      // �ٴ�ȷ���ɼ����������ʼ
      TreeViewEncodings.Perform(WM_HSCROLL, SB_LEFT, 0);
    end;
  except
    // �����κι����쳣
  end;
end;

procedure TForm1.AdjustGridColumnWidths;
begin
  // �����п�
  StringGrid1.ColWidths[0] := 40;        // ѡ�����
  StringGrid1.ColWidths[1] := 112;       // ������ (���ٵ�ԭ����һ��)
  StringGrid1.ColWidths[2] := 613;       // �ļ����� (���ӱ����м��ٵĲ���)

  // ǿ���ػ�
  StringGrid1.Invalidate;
end;

procedure TForm1.InitializeUI;
begin
  // ��ʼ������
  FUIHelper.InitStringGrid(StringGrid1);
  FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);

  // ��ʼ����ͼ��
  InitTreeIcons;
  TreeViewEncodings.Images := FIconList;

  // �󶨱������ĸ߼��Զ�������¼���ʵ�ַ���ڵ���ɫ������Ӵ�
  TreeViewEncodings.OnAdvancedCustomDrawItem := TreeViewEncodingsAdvancedCustomDrawItem;

  // �ֶ������п� (��ʹInitStringGrid�Ѿ����ù���������һ��ȷ����Ч)
  AdjustGridColumnWidths;

  // Ĭ��ѡ��UTF-8 BOM����
  SelectUTF8BOMInTreeView;

  // ��ˮƽ��������������࣬ȷ����ʾ���ڵ�
  ScrollEncodingTreeToLeft;

  // ���¼�
  CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;
  StringGrid1.PopupMenu := GridPopupMenu;
  btnShowContent.OnClick := btnShowContentClick;
  btnSelectAllExt.OnClick := btnSelectAllExtClick;

  // ��ʼ����ť��ʾ��Ϣ
  btnShowContent.Hint := '�鿴ѡ���ļ�������';
  btnShowContent.ShowHint := True;

  btnSelectAllExt.Hint := 'ѡ���ȡ��ѡ�������ļ�����';
  btnSelectAllExt.ShowHint := True;

  // Ӧ�������ַ���
  ApplyLanguageStrings;

  // ��ʼ��"������Ŀ¼"��ѡ��
  chkIncludeSubdirs.Checked := False;
  FIncludeSubdirs := False;
  chkIncludeSubdirs.OnClick := chkIncludeSubdirsClick;

  // ��ʼ��ɨ����ȿ���
  FMaxDepth := 2;
  SpinEditDepth.Value := FMaxDepth;
  SpinEditDepth.OnChange := SpinEditDepthChange;
  SpinEditDepth.Visible := False;
  lblDepth.Visible := False;

  // ʹ�ø���ȫ��Ĭ��Ŀ¼
  try
    // ���ȳ���ʹ���ϴμ�¼��Ŀ¼�����������Ч��
    if (FConfig.LastDirectory <> '') and System.SysUtils.DirectoryExists(FConfig.LastDirectory) then
    begin
      Log('ʹ���ϴμ�¼��Ŀ¼: ' + FConfig.LastDirectory);
      FSelectedFolder := FConfig.LastDirectory;
    end
    else
    begin
      // ����ʹ���û��ĵ�Ŀ¼
      try
        FSelectedFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Documents';
        Log('ʹ���û��ĵ�Ŀ¼: ' + FSelectedFolder);
      except
        // �����ȡ��������ʧ�ܣ�ʹ�ó�������Ŀ¼
        FSelectedFolder := ExtractFilePath(ParamStr(0));
        Log('ʹ�ó�������Ŀ¼: ' + FSelectedFolder);
      end;
    end;

    // �����Ŀ¼�Ƿ���ڣ���������ʹ��C��
    if not System.SysUtils.DirectoryExists(FSelectedFolder) then
    begin
      FSelectedFolder := 'C:\';
      Log('��ѡĿ¼�����ڣ�ʹ��C��: ' + FSelectedFolder);
    end;

    // ����DirectoryListBox��Ŀ¼ - ����try..except��
    try
      DirectoryListBox1.Directory := FSelectedFolder;
    except
      on E: Exception do
      begin
        Log('����Ŀ¼ʧ��: ' + E.Message);
        // �������Ŀ¼ʧ�ܣ�����ʹ��C�̸�Ŀ¼
        try
          FSelectedFolder := 'C:\';
          DirectoryListBox1.Directory := FSelectedFolder;
        except
          Log('�޷������κ�Ŀ¼����������޷���������');
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('��ʼ��Ŀ¼����: ' + E.Message);
      // ������������ʹ��C��
      FSelectedFolder := 'C:\';
      try
        DirectoryListBox1.Directory := FSelectedFolder;
      except
        Log('�޷�����Ŀ¼�����Դ˴��󲢼���');
      end;
    end;
  end;

  // �ӳٸ����ļ��б�������ڳ�ʼ���׶β�������I/O
  try
    // ��ȫ��飺ȷ��FSelectedFolder��Ч
    if (FSelectedFolder = '') or (not System.SysUtils.DirectoryExists(FSelectedFolder)) then
    begin
      Log('ѡ���Ŀ¼��Ч��ʹ��C����ΪĬ��Ŀ¼');
      FSelectedFolder := 'C:\';
    end;

    // ��ȫ��飺ȷ��FFileHelper�ѳ�ʼ��
    if not Assigned(FFileHelper) then
    begin
      Log('�ļ�����δ��ʼ���������ļ���չ������');
    end
    else
    begin
      try
        // ����ֻ�����ļ���չ���б���������ļ�
        Log('���ڸ����ļ���չ���б��Ŀ¼: ' + FSelectedFolder);
        UpdateFileExtensions(FSelectedFolder);
        Log('�ļ���չ���б�������');
      except
        on E: Exception do
        begin
          Log('�����ļ���չ���б�ʱ����: ' + E.Message);
          // ����ִ�У���Ҫ�жϳ�ʼ������
        end;
      end;
    end;

    // �ڱ������ʾ��ʾ��Ϣ
    try
      StringGrid1.Cells[2, 1] := '�����ˢ�¡���ť�����ļ�...';
      AdjustGridColumnWidths;
    except
      on E: Exception do
      begin
        Log('���ñ����ʾ��Ϣʱ����: ' + E.Message);
        // ����ִ�У���Ҫ�жϳ�ʼ������
      end;
    end;

    // ����һ����ʱ�����ڳ��������X���ټ����ļ�
    // (����ֱ�Ӻ��ԣ����û��ֶ����ˢ�°�ť)

    // ��¼��־�������Զ�����
    Log('�����ʼ����ɣ�����ˢ�°�ť�����ļ��б�');
  except
    on E: Exception do
    begin
      Log('��ʼ���ļ��б����: ' + E.Message);
      try
        StringGrid1.Cells[2, 1] := '���ش����볢�Ե��ˢ�°�ť';
        AdjustGridColumnWidths;
      except
        // �����κ�UI���´���
        Log('���ô�����ʾ��Ϣʱ����');
      end;
    end;
  end;

  // ��������ѡ����������ǿ���л�����
  CreateLanguageSelector;

  // ��¼�����־
  Log('�������������ǰ���ԣ�' + FCurrentLanguage);

  FOriginalFontSize := TreeViewEncodings.Font.Size;
end;

class procedure TForm1.Initialize;
begin
  // ��ʼ�����Թ�����
  ControllerLanguage.InitializeLanguageManager;
end;

procedure TForm1.InitializeLanguageManager;
begin
  // ��ʼ�����Թ�����
  ControllerLanguage.InitializeLanguageManager;

  // ��¼��־
  Log('���Թ������ѳ�ʼ��');
end;

procedure TForm1.CreateLanguageSelector;
var
  i: Integer;
  LangFile: string;
  FoundLanguages: Integer;
  SystemLangCode: string;
  MatchedLangCode: string;
begin
  // �������ѡ���
  ComboBox1.Items.Clear;
  ComboBox1.Items.AddObject('English', TObject(1)); // Ĭ�����Ӣ��
  FoundLanguages := 1;

  // ��¼��־
  Log('��ʼ���������ļ���Ŀ¼: ' + IniDir);

  // ����LANGUAGE_MAPPINGSȥ������Ӧ��ini�ļ�
  for i := 0 to High(LANGUAGE_MAPPINGS) do
  begin
    LangFile := IniDir + '\' + LANGUAGE_MAPPINGS[i].LanguageCode + '.ini';

    // ��¼��־
    Log('��������ļ�: ' + LangFile);

    if FileExists(LangFile) then
    begin
      // �ҵ������ļ�����ӵ�����ѡ���
      ComboBox1.Items.AddObject(LANGUAGE_MAPPINGS[i].DisplayName, TObject(i));
      Inc(FoundLanguages);

      // ��¼��־
      Log('�ҵ������ļ�: ' + LANGUAGE_MAPPINGS[i].LanguageCode + ' - ' + LANGUAGE_MAPPINGS[i].DisplayName);
    end
    else
    begin
      // ��¼��־
      Log('δ�ҵ������ļ�: ' + LANGUAGE_MAPPINGS[i].LanguageCode);
    end;
  end;

  // ��ȡϵͳ���ԣ��� LanguageManager.Initialize ͨ�� Windows API ��⣩
  SystemLangCode := ControllerLanguage.GetCurrentLanguage;
  Log('Windows ϵͳ����: ' + SystemLangCode);

  // ����ϵͳ�����Զ�ѡ��ƥ����
  MatchedLangCode := '';
  ComboBox1.ItemIndex := 0; // Ĭ��ѡ�е�һ�English��

  if SystemLangCode <> '' then
  begin
    // �Ⱦ�ȷƥ�䣨�� zh-CN��
    for i := 0 to ComboBox1.Items.Count - 1 do
    begin
      if Integer(ComboBox1.Items.Objects[i]) <= High(LANGUAGE_MAPPINGS) then
      begin
        if LANGUAGE_MAPPINGS[Integer(ComboBox1.Items.Objects[i])].LanguageCode = SystemLangCode then
        begin
          MatchedLangCode := SystemLangCode;
          ComboBox1.ItemIndex := i;
          Break;
        end;
      end;
    end;

    // ��ȷƥ��ʧ��ʱ����������ǰ׺ƥ�䣨�� zh-CN �� zh-TW��
    if MatchedLangCode = '' then
    begin
      var LangPrefix := Copy(SystemLangCode, 1, 2);
      for i := 0 to ComboBox1.Items.Count - 1 do
      begin
        if Integer(ComboBox1.Items.Objects[i]) <= High(LANGUAGE_MAPPINGS) then
        begin
          if Copy(LANGUAGE_MAPPINGS[Integer(ComboBox1.Items.Objects[i])].LanguageCode, 1, 2) = LangPrefix then
          begin
            MatchedLangCode := LANGUAGE_MAPPINGS[Integer(ComboBox1.Items.Objects[i])].LanguageCode;
            ComboBox1.ItemIndex := i;
            Break;
          end;
        end;
      end;
    end;

    // Ӧ��ƥ�䵽������
    if MatchedLangCode <> '' then
    begin
      SwitchToLanguageCode(MatchedLangCode);
      Log('�Զ����� Windows ����: ' + MatchedLangCode);
    end
    else
    begin
      SwitchToLanguageCode('en-US');
      Log('ϵͳ������ƥ���ʹ��Ӣ��');
    end;
  end;

  // ��¼��־
  Log('����ѡ�����Ѵ������ҵ� ' + IntToStr(FoundLanguages) + ' ������');
  Log('��ǰѡ������: ' + ComboBox1.Text);
end;

procedure TForm1.ApplyLanguageStrings;
var
  LangStrings: TLanguageStrings;
begin
  // ��ȡ��ǰ���Ե��ַ���
  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);

  // Ӧ�õ�����
  Self.Caption := LangStrings.WindowTitle;
  btnConvert.Caption := LangStrings.BtnConvert;
  btnSingleFile.Caption := LangStrings.BtnSingleFile + LangStrings.SingleFileConvertSuffix;
  btnRefresh.Caption := LangStrings.BtnRefresh;
  btnClose.Caption := LangStrings.BtnClose;
  btnToggleSelect.Caption := LangStrings.BtnToggleSelect;

  StringGrid1.Cells[0, 0] := LangStrings.FileSelectColumn;
  StringGrid1.Cells[1, 0] := LangStrings.EncodingColumn;
  StringGrid1.Cells[2, 0] := LangStrings.FileNameColumn;

  // �˵���
  MenuItemConvert.Caption := LangStrings.PopupMenuConvert;
  MenuItemToggleSelect.Caption := LangStrings.PopupMenuToggleSelect;
  MenuItemConvertCurrent.Caption := LangStrings.BtnSingleFile + LangStrings.SingleFileConvertSuffix;
  MenuItemConvertAllFiles.Caption := LangStrings.BtnConvert;
  MenuItemViewContent.Caption := LangStrings.BtnPreview;

  // ��ѡ��
  chkIncludeSubdirs.Caption := LangStrings.ChkIncludeSubdirs;
  lblDepth.Caption := LangStrings.LblDepth;

  // ������ť
  btnSelectAllExt.Caption := LangStrings.BtnAllFileTypes;
  btnShowContent.Caption := LangStrings.BtnCheckContent;

  // �ؽ���������ͼ�Ը���������ʾ
  TreeViewEncodings.Items.BeginUpdate;
  try
    // ��סѡ�еı���
    var SelectedEncoding: Integer := -1;
    if TreeViewEncodings.Selected <> nil then
      SelectedEncoding := Integer(TreeViewEncodings.Selected.Data);

    // ��ղ����¹��������б�
    FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);

    // ���֮ǰ��ѡ�еı��룬���Իָ�ѡ��
    if SelectedEncoding >= 0 then
    begin
      // ���Բ��Ҳ�ѡ��֮ǰѡ�еĽڵ�
      for var i := 0 to TreeViewEncodings.Items.Count - 1 do
      begin
        var Node := TreeViewEncodings.Items[i];
        if (Node.Level > 0) and (Integer(Node.Data) >= 0) and
           (Integer(Node.Data) = SelectedEncoding) then
        begin
          TreeViewEncodings.Selected := Node;
          Node.MakeVisible;
          Log('�ѻָ�ѡ�еı���ڵ�');
          Break;
        end;
      end;
    end
    else
    begin
      // ���֮ǰû��ѡ�нڵ㣬Ĭ��ѡ��UTF-8 BOM
      SelectUTF8BOMInTreeView;
    end;
  finally
    TreeViewEncodings.Items.EndUpdate;
  end;

  // ����TreeView������࣬����ˮƽ������ͣ���м�
  ScrollEncodingTreeToLeft;

  // ��¼��־
  Log('��Ӧ�������ַ���: ' + FCurrentLanguage);
end;

procedure TForm1.SwitchToLanguageCode(const LangCode: string);
var
  LangInfo: TLanguageInfo;
  i: Integer;
begin
  // �����ϸ��־��������
  Log('�����л�������: ' + LangCode);

  // ��������
  ControllerLanguage.SetLanguage(LangCode);
  FCurrentLanguage := LangCode;

  // Ӧ�������ַ������˷������Ѱ����ؽ������б���߼���
  ApplyLanguageStrings;

  // ��������ѡ����ѡ����
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
  // ����ļ��Ƿ����
  if not FileExists(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgFileNotExists', [FileName]));
    Exit;
  end;

  // ����Ƿ�Ϊ�ı��ļ�
  if not FFileHelper.IsNormalTextFile(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(FileName)]));
    Exit;
  end;

  try
    // ����SynEditFormʵ���������δ������
    if not Assigned(SynEditForm) then
    begin
      try
        Application.CreateForm(TSynEditForm, SynEditForm);
      except
        on E: Exception do
        begin
          ShowMessage('�޷������ļ��鿴��: ' + E.Message);
          Log('����SynEditFormʧ��: ' + E.Message);
          Exit;
        end;
      end;
    end;

    // ֱ�Ӽ����ļ����ݣ�SynEdit���Զ��������
    try
      SynEditForm.LoadFile(FileName);
    except
      on E: Exception do
      begin
        ShowMessage('�޷������ļ�: ' + E.Message);
        Log('SynEditForm.LoadFileʧ��: ' + E.Message);
        Exit;
      end;
    end;

    // ��λ�������������Ҳ�(�����Ļ�ռ��㹻)
    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50; // ��΢ƫ��

      // �����С�������ʱ���ã���������ʱ����

      // ��ʾ����(��ģ̬)
      SynEditForm.Show;

      // ��¼��־
      Log('�Ѵ��ļ�: ' + FileName);
    except
      on E: Exception do
      begin
        ShowMessage('��ʾ����ʱ��������: ' + E.Message);
        Log('��ʾSynEditFormʧ��: ' + E.Message);
      end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('�޷����ļ�: ' + E.Message);
      Log('���ļ�ʧ��: ' + E.Message);
    end;
  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // �������Shift+Ctrl+W��ϼ������������п�
  if (Key = Ord('W')) and (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    AdjustGridColumnWidths;
    Log('�ѵ�������п�');
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // ��ȫ�ͷ�ȫ�ֵ�SynEditFormʵ��
  try
    if Assigned(SynEditForm) then
    begin
      // ���ȳ������ش���
      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('������SynEditForm����');
          Application.ProcessMessages;
          Sleep(100);
        end;
      except
        on E: Exception do
        begin
          Log('����SynEditFormʧ��: ' + E.Message);
        end;
      end;

      // Ȼ�����ͷ�ʵ��
      try
        SynEditForm.Release;
        SynEditForm := nil;
        Log('���ͷ�SynEditFormʵ��');
      except
        on E: Exception do
        begin
          Log('�ͷ�SynEditFormʧ��: ' + E.Message);
          try
            FreeAndNil(SynEditForm);
            Log('ʹ��FreeAndNil�ͷ�SynEditFormʵ��');
          except
            on E2: Exception do
            begin
              Log('ʹ��FreeAndNil�ͷ�SynEditFormҲʧ��: ' + E2.Message);
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('�ر�ʱ����SynEditFormʧ��: ' + E.Message);
    end;
  end;

  // �ͷ���־������
  try
    FUIHelper.FreeLogBuffer;
    Log('���ͷ���־������');
  except
    on E: Exception do
    begin
      Log('�ͷ���־������ʧ��: ' + E.Message);
    end;
  end;
end;

procedure TForm1.chkIncludeSubdirsClick(Sender: TObject);
begin
  // ������Ŀ¼����״̬
  FIncludeSubdirs := chkIncludeSubdirs.Checked;

  // ��ȿ��ƽ�������Ŀ¼ʱ��ʾ
  SpinEditDepth.Visible := FIncludeSubdirs;
  lblDepth.Visible := FIncludeSubdirs;

  // ��¼״̬�仯���ڽ������ṩ�����ķ���
  if FIncludeSubdirs then
  begin
    Log('��������Ŀ¼���� - ���: ' + IntToStr(FMaxDepth));
    ShowLocalizedMessage('MsgSubdirEnabled');
  end
  else
    Log('�ѽ�����Ŀ¼���� - ֻ������ǰ�ļ���');

  // �����ļ��б��Է�ӳ��Ŀ¼����״̬
  UpdateFileGrid(FSelectedFolder);

  // ����־����ʾ�ļ�������Ϣ
  Log('�ļ��б��Ѹ��£���ǰ����ʾ ' + IntToStr(StringGrid1.RowCount - 1) + ' ���ļ�');
end;

procedure TForm1.SpinEditDepthChange(Sender: TObject);
begin
  FMaxDepth := SpinEditDepth.Value;
  Log('ɨ������ѵ���Ϊ: ' + IntToStr(FMaxDepth));
  if FIncludeSubdirs then
    UpdateFileGrid(FSelectedFolder);
end;

{
procedure TForm1.btnCancelClick(Sender: TObject);
begin
  if Assigned(FAsyncProcessor) then
  begin
    Log('�û�����ȡ����ǰ����');
    FAsyncProcessor.Cancel;
    HideProgress;
  end;
end;
}

{
procedure TForm1.InitializeAsyncComponents;
begin
  // �����첽������
  FAsyncProcessor := TAsyncFileProcessor.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );

  // �������ȿ�����
  FProgressController := TProgressController.Create(ProgressBar1, lblProgress, btnCancel);
  FProgressController.OnCancel := btnCancelClick;

  Log('�첽�����ʼ�����');
end;
}

{
procedure TForm1.FinalizeAsyncComponents;
begin
  try
    // ȡ���������е�����
    if Assigned(FAsyncProcessor) then
    begin
      FAsyncProcessor.Cancel;
      FAsyncProcessor.WaitForCompletion(3000); // �ȴ����3��
    end;

    // �ͷ����
    FreeAndNil(FAsyncProcessor);
    FreeAndNil(FProgressController);

    Log('�첽������ͷ�');
  except
    on E: Exception do
      Log('�ͷ��첽���ʱ����: ' + E.Message);
  end;
end;
}

{
procedure TForm1.ShowProgress;
begin
  if Assigned(FProgressController) then
    FProgressController.Show;
end;

procedure TForm1.HideProgress;
begin
  if Assigned(FProgressController) then
    FProgressController.Hide;
end;
}

{
procedure TForm1.OnFileScanProgress(const Progress: TFileScanProgress);
begin
  // �����߳��и��½���
  if Assigned(FProgressController) then
    FProgressController.UpdateProgress(Progress);

  // ����״̬��������UIԪ��
  if Progress.TotalFiles > 0 then
  begin
    var ProgressPercent := (Progress.ProcessedFiles * 100) div Progress.TotalFiles;
    Caption := Format(FLanguageStrings.WindowTitleScanProgress,
      [ProgressPercent, Progress.ProcessedFiles, Progress.TotalFiles]);

    // ����Ƿ����
    if Progress.ProcessedFiles >= Progress.TotalFiles then
    begin
      // ֱ�������߳��д�������¼�
      HideProgress;
      Caption := FLanguageStrings.WindowTitleDefault;

      var Results := FAsyncProcessor.GetResults;
      Log(Format(FLanguageStrings.LogAsyncScanComplete, [Length(Results)]));

      // ���û���ļ�����ʾ��ʾ
      if Length(Results) = 0 then
        StringGrid1.Cells[2, 1] := '(���ļ�)';

      // �����п�
      AdjustGridColumnWidths;
    end;
  end;
end;
}

{
procedure TForm1.OnFileScanResult(const Result: TFileScanResult);
begin
  // �����߳�������ļ������
  var RowIndex := StringGrid1.RowCount;
  StringGrid1.RowCount := RowIndex + 1;

  StringGrid1.Cells[0, RowIndex] := ''; // ѡ����
  StringGrid1.Cells[1, RowIndex] := Result.Encoding; // ������
  StringGrid1.Cells[2, RowIndex] := Result.FileName; // �ļ�����

  // ÿ���50���ļ�ˢ��һ�ν���
  if (RowIndex mod 50 = 0) then
    Application.ProcessMessages;
end;

procedure TForm1.OnConversionProgress(const Progress: TBatchConversionResult);
begin
  // �����߳��и���ת������
  if Assigned(FProgressController) then
    FProgressController.UpdateConversionProgress(Progress);

  // ���´������
  if Progress.TotalFiles > 0 then
  begin
    var ProcessedFiles := Progress.SuccessCount + Progress.FailCount + Progress.SkippedCount;
    var ProgressPercent := (ProcessedFiles * 100) div Progress.TotalFiles;
    Caption := Format(FLanguageStrings.WindowTitleConvertProgress,
      [ProgressPercent, Progress.SuccessCount, Progress.FailCount]);

    // ����Ƿ����
    if ProcessedFiles >= Progress.TotalFiles then
    begin
      // ֱ�������߳��д�������¼�
      HideProgress;
      Caption := FLanguageStrings.WindowTitleDefault;

      // ˢ���ļ��б�����ʾ���º�ı���
      UpdateFileGrid(FSelectedFolder);

      Log('�첽����ת�����');
      ShowMessage(Format('����ת�����: �ɹ� %d, ʧ�� %d', [Progress.SuccessCount, Progress.FailCount]));
    end;
  end;
end;

procedure TForm1.UpdateFileGridAsync(const FolderPath: string);
var
  FileExtensions: TArray<string>;
  i: Integer;
  HasSelectedExtensions: Boolean;
begin
  // ���Ŀ¼�Ƿ����
  if not System.SysUtils.DirectoryExists(FolderPath) then
  begin
    StringGrid1.Cells[2, 1] := '(Ŀ¼������)';
    AdjustGridColumnWidths;
    Exit;
  end;

  // ��ȡѡ�е��ļ���չ��
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

  // ���û��ѡ���κ��ļ����ͣ���ʾ��ʾ���˳�
  if not HasSelectedExtensions then
  begin
    Log('δѡ���κ��ļ����ͣ�����ʾ�ļ�');
    StringGrid1.Cells[2, 1] := '(��ѡ������һ���ļ�����)';
    AdjustGridColumnWidths;
    Exit;
  end;

  // ��ձ��
  FUIHelper.ClearGrid(StringGrid1);

  // ��ʾ����
  ShowProgress;

  // ��¼��ʼɨ��
  Log('��ʼ�첽ɨ���ļ�: ' + FolderPath + ', ������Ŀ¼: ' + BoolToStr(FIncludeSubdirs, True));

  // ����첽ɨ��
  FAsyncProcessor.ScanFolderAsync(
    FolderPath,
    FileExtensions,
    FIncludeSubdirs,
    OnFileScanProgress,
    OnFileScanResult
  );
end;

procedure TForm1.ConvertFilesAsync(const Files: TArray<string>; const TargetEncoding: string; WithBOM: Boolean);
begin
  if Length(Files) = 0 then
  begin
    ShowMessage('û��ѡ��Ҫת�����ļ�');
    Exit;
  end;

  // ��ʾ����
  ShowProgress;

  // ��¼��ʼת��
  Log(Format('��ʼ�첽����ת�� %d ���ļ��� %s (BOM: %s)',
    [Length(Files), TargetEncoding, BoolToStr(WithBOM, True)]));

  // ����첽ת��
  FAsyncProcessor.ConvertFilesAsync(
    Files,
    TargetEncoding,
    WithBOM,
    OnConversionProgress
  );
end;
}

{ ��ʷĿ¼���� }

procedure TForm1.LoadDirHistory;
var
  HistoryCount, i: Integer;
  DirPath: string;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  CBoxDirHistory.Items.Clear;
  
  try
    HistoryCount := FConfig.IniFile.ReadInteger('DirHistory', 'Count', 0);
    
    for i := 0 to HistoryCount - 1 do
    begin
      DirPath := FConfig.IniFile.ReadString('DirHistory', 'Dir' + IntToStr(i), '');
      if (DirPath <> '') and System.SysUtils.DirectoryExists(DirPath) then
        CBoxDirHistory.Items.Add(DirPath);
    end;
    
    Log(Format('������ %d ����ʷĿ¼', [CBoxDirHistory.Items.Count]));
  except
    on E: Exception do
      Log('������ʷĿ¼ʧ��: ' + E.Message);
  end;
end;

procedure TForm1.SaveDirHistory;
var
  i: Integer;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  try
    // ���������
    FConfig.IniFile.EraseSection('DirHistory');
    
    // ��������
    FConfig.IniFile.WriteInteger('DirHistory', 'Count', CBoxDirHistory.Items.Count);
    
    // ����ÿ��Ŀ¼
    for i := 0 to CBoxDirHistory.Items.Count - 1 do
      FConfig.IniFile.WriteString('DirHistory', 'Dir' + IntToStr(i), CBoxDirHistory.Items[i]);
      
    // ˢ�� INI �ļ�
    FConfig.IniFile.UpdateFile;
      
    Log(Format('������ %d ����ʷĿ¼', [CBoxDirHistory.Items.Count]));
  except
    on E: Exception do
      Log('������ʷĿ¼ʧ��: ' + E.Message);
  end;
end;

procedure TForm1.AddDirToHistory(const DirPath: string);
var
  Index: Integer;
const
  MAX_HIDeepStory = 20; // ��ౣ�� 20 ����ʷĿ¼
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  if (DirPath = '') or not System.SysUtils.DirectoryExists(DirPath) then
    Exit;
    
  // ����Ƿ��Ѵ���
  Index := CBoxDirHistory.Items.IndexOf(DirPath);
  
  if Index >= 0 then
  begin
    // �Ѵ��ڣ��ƶ�������
    CBoxDirHistory.Items.Move(Index, 0);
  end
  else
  begin
    // �����ڣ���ӵ�����
    CBoxDirHistory.Items.Insert(0, DirPath);
    
    // ��������
    while CBoxDirHistory.Items.Count > MAX_HIDeepStory do
      CBoxDirHistory.Items.Delete(CBoxDirHistory.Items.Count - 1);
  end;
  
  // ����UI
  UpdateDirHistoryUI;
  
  // ���浽����
  SaveDirHistory;
  
  Log('���Ŀ¼����ʷ: ' + DirPath);
end;

procedure TForm1.UpdateDirHistoryUI;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  if CBoxDirHistory.Items.Count > 0 then
  begin
    CBoxDirHistory.ItemIndex := 0;
    CBoxDirHistory.Text := CBoxDirHistory.Items[0];
  end
  else
  begin
    CBoxDirHistory.ItemIndex := -1;
    CBoxDirHistory.Text := '����ʷ��¼';
  end;
end;

procedure TForm1.CBoxDirHistoryChange(Sender: TObject);
var
  SelectedDir: string;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  if CBoxDirHistory.ItemIndex < 0 then
    Exit;
    
  SelectedDir := CBoxDirHistory.Items[CBoxDirHistory.ItemIndex];
  
  if System.SysUtils.DirectoryExists(SelectedDir) then
  begin
    // ����Ŀ¼�б��
    DirectoryListBox1.Directory := SelectedDir;
    
    // ���´���ѡ��
    if Length(SelectedDir) >= 2 then
      DriveComboBox1.Drive := UpCase(SelectedDir[1]);
      
    Log('����ʷѡ��Ŀ¼: ' + SelectedDir);
  end
  else
  begin
    ShowMessage('Ŀ¼������: ' + SelectedDir);
    // ����ʷ���Ƴ�
    CBoxDirHistory.Items.Delete(CBoxDirHistory.ItemIndex);
    SaveDirHistory;
    UpdateDirHistoryUI;
  end;
end;

procedure TForm1.CBoxDirHistoryDropDown(Sender: TObject);
var
  i: Integer;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  // ����ʱˢ���б���Ƴ������ڵ�Ŀ¼
  i := CBoxDirHistory.Items.Count - 1;
  while i >= 0 do
  begin
    if not System.SysUtils.DirectoryExists(CBoxDirHistory.Items[i]) then
    begin
      Log('�Ƴ���ЧĿ¼: ' + CBoxDirHistory.Items[i]);
      CBoxDirHistory.Items.Delete(i);
    end;
    Dec(i);
  end;
  
  if CBoxDirHistory.Items.Count = 0 then
    CBoxDirHistory.Text := '����ʷ��¼';
end;

// ������ѡ���ļ�ת��Ϊ UTF-8����ѡ�Ƿ�� BOM��
procedure TForm1.ConvertSelectedFilesToUTF8(const WithBOM: Boolean);
var
  SelectedFiles: TArray<string>;
  SuccessCount, i: Integer;
  FilePath: string;
begin
  // ��ȡѡ�е��ļ�
  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);
  if Length(SelectedFiles) = 0 then
  begin
    ShowLocalizedMessage('MsgSelectFiles');
    Exit;
  end;

  Log(Format('��ʼ����%s UTF-8 BOM���� %d ���ļ�...', [IfThen(WithBOM, '���', '�Ƴ�'), Length(SelectedFiles)]));
  StartLogBuffering;
  Screen.Cursor := crHourGlass;
  SuccessCount := 0;
  try
    for i := 0 to High(SelectedFiles) do
    begin
      FilePath := SelectedFiles[i];
      if FEncodingController.ConvertSingleFile(FilePath, 'UTF-8', WithBOM) then
      begin
        Inc(SuccessCount);
        UpdateSingleFileInGrid(FilePath);
      end
      else
        Log('- ת��ʧ��: ' + FilePath);
    end;

    Log(Format('��ɣ��ɹ� %d/%d ���ļ���Ŀ�꣺%s��',
      [SuccessCount, Length(SelectedFiles), IfThen(WithBOM, 'UTF-8 with BOM', 'UTF-8 (no BOM)')]));

    // ˢ���ļ�����
    if System.SysUtils.DirectoryExists(DirectoryListBox1.Directory) then
      UpdateFileGrid(DirectoryListBox1.Directory);
  finally
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;

// �Ҽ��˵������ UTF-8 BOM
procedure TForm1.MenuItemAddUTF8BOMClick(Sender: TObject);
begin
  ConvertSelectedFilesToUTF8(True);
end;

// �Ҽ��˵����Ƴ� UTF-8 BOM
procedure TForm1.MenuItemRemoveUTF8BOMClick(Sender: TObject);
begin
  ConvertSelectedFilesToUTF8(False);
end;

end.