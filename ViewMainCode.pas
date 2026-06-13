Unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, System.IOUtils, System.UITypes, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Grids, System.Math, Vcl.CheckLst, System.Types, Vcl.Menus, System.Rtti,
  VirtualTrees, VirtualExplorerTree, MPShellUtilities,
  System.StrUtils, UtilsTypes, ModelEncoding, ModelConfig, HelperUI, HelperFiles,
  ControllerEncoding, Winapi.ShlObj, ViewMemo, Vcl.Themes, ViewSynEdit,
  System.UIConsts, System.IniFiles, ModelLanguage, ControllerLanguage,
  System.TypInfo, Vcl.Clipbrd, Vcl.ImgList, Vcl.Samples.Spin,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

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
    vstDir: TVirtualExplorerTreeview;
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
    chkInstantScan: TCheckBox;
    btnScanDir: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
    procedure btnSingleFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure vstDirChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure TreeViewEncodingsClick(Sender: TObject);
    procedure StringGrid1Click(Sender: TObject);
    procedure MenuItemConvertClick(Sender: TObject);
    procedure StringGrid1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuItemToggleSelectClick(Sender: TObject);
    procedure btnToggleSelectClick(Sender: TObject);
    procedure MenuItemConvertCurrentClick(Sender: TObject);
    procedure MenuItemConvertAllFilesClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);

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
    procedure chkInstantScanClick(Sender: TObject);
    procedure btnScanDirClick(Sender: TObject);

  private
    FSelectedFolder: string;
    FSelectedRow: Integer;
    FFileExtensions: TStringList;
    FIncludeSubdirs: Boolean;
    FMaxDepth: Integer;
    FInstantScan: Boolean;
    FLogBuffer: TStringList;
    FBufferingLogs: Boolean;


    FConfig: TAppConfig;
    FEncodingModel: TEncodingModel;
    FEncodingController: TEncodingController;
    FUIHelper: TUIHelper;
    FFileHelper: TFileHelper;

    FOriginalFontSize: Integer;


    FCurrentLanguage: string;


    FIconList: TImageList;


    // FAsyncProcessor: TAsyncFileProcessor;
    // FProgressController: TProgressController;


    function GetLocalizedMessage(const MsgId: string): string;
    function GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
    procedure ShowLocalizedMessage(const MsgId: string);
    procedure ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);

    procedure UpdateFileGrid(const FolderPath: string);
    procedure UpdateFileExtensions(const FolderPath: string);
    procedure CheckListBox1ClickCheck(Sender: TObject);


    procedure Log(const Msg: string);
    procedure StartLogBuffering;
    procedure EndLogBuffering;


    procedure InvalidateForm;


    procedure InitializeLanguageManager;
    procedure CreateLanguageSelector;
    procedure ApplyLanguageStrings;
    procedure SwitchToLanguageCode(const LangCode: string);

    procedure UpdateSingleFileInGrid(const FilePath: string);


    procedure LoadDirHistory;
    procedure SaveDirHistory;
    procedure AddDirToHistory(const DirPath: string);
    procedure UpdateDirHistoryUI;

    procedure BrowseToDir(const APath: string);


    // procedure InitializeAsyncComponents;
    // procedure FinalizeAsyncComponents;
    // procedure UpdateFileGridAsync(const FolderPath: string);
    // procedure ConvertFilesAsync(const Files: TArray<string>; const TargetEncoding: string; WithBOM: Boolean);
    // procedure OnFileScanProgress(const Progress: TFileScanProgress);
    // procedure OnFileScanResult(const Result: TFileScanResult);
    // procedure OnConversionProgress(const Progress: TBatchConversionResult);
    // procedure ShowProgress;
    // procedure HideProgress;


    procedure ScrollEncodingTreeToLeft;


    procedure InitTreeIcons;


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


  FSelectedRow := -1;
  FFileExtensions := TStringList.Create;
  FLogBuffer := TStringList.Create;
  FBufferingLogs := False;


  FConfig := TAppConfig.Create;
  FEncodingModel := TEncodingModel.Create;
  FUIHelper := TUIHelper.Create;


  FEncodingController := TEncodingController.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );


  FFileHelper := TFileHelper.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );


  RootDir := FFileHelper.GetRootDir;
  IniDir := RootDir + '\ini';
  Log(GetLocalizedMessage('LogRootDirectory') + RootDir);
  Log(GetLocalizedMessage('LogIniDirectory') + IniDir);


  try
    InitializeLanguageManager;
  except
    on E: Exception do
      OutputDebugString(PChar('Constructor: InitializeLanguageManager failed: ' + E.Message));
  end;


  try
    CreateLanguageSelector;
  except
    on E: Exception do
      OutputDebugString(PChar('Constructor: CreateLanguageSelector failed: ' + E.Message));
  end;


  // InitializeAsyncComponents;

end;

destructor TForm1.Destroy;
begin

  // FinalizeAsyncComponents;


  FEncodingController.Free;
  FFileHelper.Free;
  FUIHelper.Free;
  FEncodingModel.Free;
  FConfig.Free;


  FLogBuffer.Free;
  FFileExtensions.Free;
  FIconList.Free;
  inherited;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
begin

  ApplyLanguageStrings;


  Application.ProcessMessages;

  Sleep(100);


  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;


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
    Log(GetLocalizedMessage('MsgSelectValidFolder'));
    Exit;
  end;

  // Get selected encoding info
  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    ShowLocalizedMessage('MsgSelectTargetEncoding');
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
  Log(GetLocalizedMessageFmt('LogBatchConversionStart', [Length(SelectedFiles), TargetInfo.Name]));
  StartLogBuffering;

  // Execute conversion
  Screen.Cursor := crHourGlass;
  SuccessCount := 0;

  try

    FEncodingController.ConvertFiles(SelectedFiles, TargetInfo.ShortName, WithBOM);
    Log(System.SysUtils.Format('%s', [TargetInfo.Name]));


    if System.SysUtils.DirectoryExists(FSelectedFolder) then
    begin
      Log(GetLocalizedMessage('LogRefreshingFileList'));
      UpdateFileGrid(FSelectedFolder);
      Log(GetLocalizedMessage('LogFileListRefreshed'));
    end;
    AddDirToHistory(FSelectedFolder);

  finally
    Screen.Cursor := crDefault;

    // End log buffering and update log at once
    EndLogBuffering;
  end;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
begin
  if System.SysUtils.DirectoryExists(FSelectedFolder) then
  begin

    UpdateFileGrid(FSelectedFolder);
    Log(GetLocalizedMessage('LogRefreshDirectory') + FSelectedFolder);
  end;
end;

procedure TForm1.btnSingleFileClick(Sender: TObject);
begin
  // Just call the logic from the menu item handler
  MenuItemConvertCurrentClick(Sender);
end;

procedure TForm1.btnToggleSelectClick(Sender: TObject);
begin

  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin

  UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.cmbLanguageChange(Sender: TObject);
var
  Index, LangIndex: Integer;
  LangCode: string;
begin

  Index := ComboBox1.ItemIndex;
  if Index < 0 then
  begin
    Log(GetLocalizedMessage('LogWarningInvalidLanguage'));
    Exit;
  end;


  LangIndex := Integer(ComboBox1.Items.Objects[Index]);


  Log(GetLocalizedMessage('LogUserSelectedLanguage') + ComboBox1.Items[Index] + ' (Index: ' + IntToStr(LangIndex) + ')');


  if (LangIndex >= 0) and (LangIndex <= High(LANGUAGE_MAPPINGS)) then
  begin
    LangCode := LANGUAGE_MAPPINGS[LangIndex].LanguageCode;
    Log(GetLocalizedMessage('LogSwitchToLanguage') + LangCode);


    SwitchToLanguageCode(LangCode);
  end
  else
  begin
    Log(GetLocalizedMessage('LogWarningInvalidLanguage') + ': ' + IntToStr(LangIndex));
  end;

  Application.ProcessMessages;
end;

// --- VirtualExplorerTree OnChange handler ---

procedure TForm1.vstDirChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  SelectedPath: string;
begin
  try
    SelectedPath := Trim(vstDir.SelectedPath);
    if SelectedPath = '' then
      Exit;
    if not System.SysUtils.DirectoryExists(SelectedPath) then
      Exit;

    FSelectedFolder := SelectedPath;
    FConfig.LastDirectory := FSelectedFolder;
    if FInstantScan then
    begin
      Log(FSelectedFolder);
      try
        Screen.Cursor := crHourGlass;
        UpdateFileExtensions(FSelectedFolder);
        UpdateFileGrid(FSelectedFolder);
        AddDirToHistory(FSelectedFolder);
      finally
        Screen.Cursor := crDefault;
      end;
    end
    else
      Log(GetLocalizedMessage('LogRefreshDirectory') + FSelectedFolder);
  except
    on E: Exception do
      OutputDebugString(PChar('vstDirChange: ' + E.Message));
  end;
end;

class procedure TForm1.Execute;
begin

  Application.CreateForm(TForm1, Form1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  KeyPreview := True;


  try
    InitializeLanguageManager;
  except
    on E: Exception do
      OutputDebugString(PChar('InitializeLanguageManager failed: ' + E.Message));
  end;


  try
    InitializeUI;
  except
    on E: Exception do
      OutputDebugString(PChar('InitializeUI failed: ' + E.Message));
  end;


  try
    ApplyLanguageStrings;
  except
    on E: Exception do
      OutputDebugString(PChar('ApplyLanguageStrings failed: ' + E.Message));
  end;


  try
    LoadDirHistory;
  except
    on E: Exception do
      OutputDebugString(PChar('LoadDirHistory failed: ' + E.Message));
  end;


  try
    var Sep := TMenuItem.Create(GridPopupMenu);
    Sep.Caption := '-';
    GridPopupMenu.Items.Add(Sep);

    var ItemAdd := TMenuItem.Create(GridPopupMenu);
    ItemAdd.Caption := '';
    ItemAdd.OnClick := MenuItemAddUTF8BOMClick;
    GridPopupMenu.Items.Add(ItemAdd);

    var ItemRemove := TMenuItem.Create(GridPopupMenu);
    ItemRemove.Caption := '';
    ItemRemove.OnClick := MenuItemRemoveUTF8BOMClick;
    GridPopupMenu.Items.Add(ItemRemove);
  except

  end;
end;

procedure TForm1.TreeViewEncodingsClick(Sender: TObject);
begin

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

    TimeStamp := FormatDateTime('hh:nn:ss.zzz', Now);


    SafeMsg := Msg;
    SafeMsg := StringReplace(SafeMsg, #0, '', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #13#10, ' ', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #13, ' ', [rfReplaceAll]);
    SafeMsg := StringReplace(SafeMsg, #10, ' ', [rfReplaceAll]);


    SafeMsg := Format('[%s] %s', [TimeStamp, SafeMsg]);


    if not Assigned(MemLog) then
    begin

      try
        OutputDebugString(PChar('' + SafeMsg));
      except
        on E: Exception do
        begin

          try
            OutputDebugString(PChar(''));
          except

          end;
        end;
      end;
      Exit;
    end;


    if FBufferingLogs then
    begin

      try
        if Assigned(FLogBuffer) then
          FLogBuffer.Add(SafeMsg)
        else
          OutputDebugString(PChar('' + SafeMsg));
      except
        on E: EEncodingError do
        begin
          try
            if Assigned(FLogBuffer) then
              FLogBuffer.Add('');
            OutputDebugString(PChar(''));
          except

          end;
        end;
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('' + E.Message));
          except

          end;
        end;
      end;
    end
    else
    begin

      try
        if Assigned(FUIHelper) then
          FUIHelper.AppendLog(MemLog, SafeMsg)
        else
        begin

          try
            MemLog.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + SafeMsg);
          except
            on E: EEncodingError do
            begin

              try
                MemLog.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + '');
                OutputDebugString(PChar(''));
              except

              end;
            end;
            on E: Exception do
            begin

              try
                OutputDebugString(PChar('' + E.Message));
              except

              end;
            end;
          end;
        end;
      except
        on E: Exception do
        begin

          try
            OutputDebugString(PChar('' + E.Message));
          except

          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin

      try
        OutputDebugString(PChar('' + E.Message));
      except

      end;
    end;
  end;
end;


procedure TForm1.StartLogBuffering;
begin
  try

    FBufferingLogs := True;

    if not Assigned(FLogBuffer) then
    begin
      try
        OutputDebugString(PChar(''));

        FLogBuffer := TStringList.Create;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('' + E.Message));
          except

          end;

          FBufferingLogs := False;
        end;
      end;
    end
    else
    begin

      try
        FLogBuffer.Clear;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('' + E.Message));
          except

          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      try
        OutputDebugString(PChar('' + E.Message));
      except

      end;

      FBufferingLogs := False;
    end;
  end;
end;

procedure TForm1.EndLogBuffering;
var
  i: Integer;
  StartIndex: Integer;
  LogCount: Integer;
begin
  try

    FBufferingLogs := False;

    if not Assigned(FLogBuffer) then
    begin
      try
        OutputDebugString(PChar(''));
      except

      end;
      Exit;
    end;

    if not Assigned(MemLog) then
    begin
      try
        OutputDebugString(PChar(''));
      except

      end;
      Exit;
    end;


    LogCount := FLogBuffer.Count;
    if LogCount > 0 then
    begin
      try

        MemLog.Lines.BeginUpdate;
        try

          if LogCount > 100 then
          begin
            StartIndex := LogCount - 100;
            try
              MemLog.Lines.Add('' + IntToStr(LogCount) + '');
            except
              on E: Exception do
              begin
                try
                  OutputDebugString(PChar('' + E.Message));
                except

                end;
              end;
            end;
          end
          else
            StartIndex := 0;


          for i := StartIndex to LogCount - 1 do
          begin
            try
              if (i >= 0) and (i < FLogBuffer.Count) then
                MemLog.Lines.Add(FLogBuffer[i]);
            except
              on E: EEncodingError do
              begin
                try
                  MemLog.Lines.Add('');
                  OutputDebugString(PChar('' + IntToStr(i)));
                except

                end;
              end;
              on E: Exception do
              begin
                try
                  OutputDebugString(PChar('' + E.Message));
                except

                end;

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
                OutputDebugString(PChar('' + E.Message));
              except

              end;
            end;
          end;
        end;


        try
          MemLog.SelStart := Length(MemLog.Text);
          MemLog.SelLength := 0;
          MemLog.Perform(EM_SCROLLCARET, 0, 0);
        except
          on E: Exception do
          begin
            try
              OutputDebugString(PChar('' + E.Message));
            except

            end;
          end;
        end;


        try
          FLogBuffer.Clear;
        except
          on E: Exception do
          begin
            try
              OutputDebugString(PChar('' + E.Message));
            except

            end;
          end;
        end;
      except
        on E: Exception do
        begin
          try
            OutputDebugString(PChar('' + E.Message));
          except

          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      try
        OutputDebugString(PChar('' + E.Message));
      except

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
    PChar(System.SysUtils.Format('%s', [Length(AllFiles)])),
    '',
    MB_YESNO + MB_ICONQUESTION) <> IDYES then
  begin
    Log('User cancelled batch conversion.');
    Exit;
  end;

  Log('Starting batch conversion...');
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
        Log('' + AllFiles[i] + '' + DetectedEncoding + '' +
          FEncodingModel.GetEncodingName(Encoding) + ')');
      end
      else
      begin
        Log('' + AllFiles[i]);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('%s', [SuccessCount, Length(AllFiles)]));
    if SuccessCount < Length(AllFiles) then
      Log(System.SysUtils.Format('%s',
        [Length(AllFiles) - SuccessCount]));
  
    AddDirToHistory(FSelectedFolder);
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

  Log('');

  if StringGrid1.RowCount <= 1 then
  begin
    Log('');
    Exit; // No files loaded
  end;


  if (TreeViewEncodings.Selected = nil) or (TreeViewEncodings.Selected.Level = 0) then
  begin
    Log('');
    ShowLocalizedMessage('MsgSelectTargetEncoding');
    Exit;
  end;
  SelectedIndex := Integer(TreeViewEncodings.Selected.Data);
  TargetInfo := FEncodingModel.Encodings[SelectedIndex];
  WithBOM := TargetInfo.HasBOM;
  Log('' + TargetInfo.Name + ', BOM: ' + BoolToStr(WithBOM, True));


  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);
  Log('' + IntToStr(Length(SelectedFiles)) + '');

  if Length(SelectedFiles) = 0 then
  begin
    Log('');
    ShowLocalizedMessage('MsgSelectFiles');
    Exit;
  end;


  Log('');
  StartLogBuffering;
  SuccessCount := 0;

  try

    Screen.Cursor := crHourGlass;


    for i := 0 to High(SelectedFiles) do
    begin
      FilePath := SelectedFiles[i];


      if not FileExists(FilePath) then
      begin
        Log('' + FilePath);
        Continue;
      end;


      DetectedEncoding := FFileHelper.DetectFileEncoding(FilePath, HasBOM);
      Log('' + FilePath + ' - ' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));


      if FEncodingController.ConvertSingleFile(FilePath, TargetInfo.ShortName, WithBOM) then
      begin
        Inc(SuccessCount);
        Log('' + FilePath + '' + DetectedEncoding + '' + TargetInfo.Name + ')');


        UpdateSingleFileInGrid(FilePath);
      end
      else
      begin
        Log('' + FilePath);
      end;
    end;


    Log(System.SysUtils.Format('%s', [SuccessCount, Length(SelectedFiles)]));

    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('%s',
        [Length(SelectedFiles) - SuccessCount]));

    ShowMessage(System.SysUtils.Format('Conversion result: %d/%d files successful', [SuccessCount, Length(SelectedFiles)]));
  
    AddDirToHistory(FSelectedFolder);
  finally

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

  Log('');

  if (FSelectedRow > 0) and (FSelectedRow < StringGrid1.RowCount) and
     (StringGrid1.Cells[2, FSelectedRow] <> '') and
     (StringGrid1.Cells[2, FSelectedRow] <> '') and
     (StringGrid1.Cells[2, FSelectedRow] <> '') and
     (StringGrid1.Cells[2, FSelectedRow] <> '') then
  begin

    FileName := StringGrid1.Cells[2, FSelectedRow];
    Log('' + FileName);


    CurrentRowFile := IncludeTrailingPathDelimiter(FSelectedFolder) + FileName;
    Log('' + CurrentRowFile);


    if FileExists(CurrentRowFile) then
    begin
      SetLength(SelectedFiles, 1);
      SelectedFiles[0] := CurrentRowFile;
      Log('' + CurrentRowFile);
    end
    else
    begin
      Log('' + CurrentRowFile);
      ShowMessage('File not found: ' + CurrentRowFile);
      Exit;
    end;
  end
  else
  begin

    Log('');
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


    if Length(SelectedFiles) = 0 then
    begin
      Log('');
      ShowLocalizedMessage('MsgSelectFiles');
      Exit;
    end;
  end;

  // Get selected encoding (from TreeView)
  Encoding := FEncodingModel.GetSelectedEncoding;

  // Start batch conversion
  Log('');
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
        Log('' + FilePath + '' + DetectedEncoding + '' +
          FEncodingModel.GetEncodingName(Encoding) + ')');

        // Update the status of this file in the grid
        UpdateSingleFileInGrid(FilePath);
      end
      else
      begin
        Log('' + FilePath);
      end;
    end;

    // Complete batch conversion, show result
    Log(System.SysUtils.Format('%s', [SuccessCount, Length(SelectedFiles)]));

    if SuccessCount < Length(SelectedFiles) then
      Log(System.SysUtils.Format('%s',
        [Length(SelectedFiles) - SuccessCount]));

    ShowMessage(System.SysUtils.Format('Conversion result: %d/%d files successful', [SuccessCount, Length(SelectedFiles)]));
  finally
    // Restore cursor
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;

procedure TForm1.MenuItemToggleSelectClick(Sender: TObject);
begin

  FUIHelper.ToggleAllSelections(StringGrid1);
end;

procedure TForm1.MenuItemViewContentClick(Sender: TObject);
begin

  btnShowContentClick(Sender);
end;

procedure TForm1.MenuItemCopyFullPathClick(Sender: TObject);
var
  FullPath: string;
begin

  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;


  FullPath := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[2, FSelectedRow];


  Clipboard.AsText := FullPath;


  Log('' + FullPath);
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


  Grid.MouseToCell(P.X, P.Y, Col, Row);


  if Row > 0 then
  begin

    Grid.Row := Row;
    FSelectedRow := Row;


    if Col = 0 then
    begin

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


  if (GridCoord.Y > 0) and (GridCoord.Y < StringGrid1.RowCount) then
  begin
    StringGrid1.Row := GridCoord.Y;
    FSelectedRow := GridCoord.Y;

    GridPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end
  else
  begin

    MenuItemConvertCurrent.Enabled := False;
    MenuItemToggleSelect.Enabled := False;
    MenuItemViewContent.Enabled := False;
    Handled := True;
  end;
end;

procedure TForm1.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin

  FSelectedRow := ARow;
end;

procedure TForm1.UpdateFileExtensions(const FolderPath: string);
var
  Extensions: TArray<string>;
  i: Integer;
  SafePath: string;
begin
  if not Assigned(CheckListBox1) then
  begin
    Log('');
    Exit;
  end;

  if not Assigned(FFileExtensions) then
  begin
    Log('');
    Exit;
  end;

  if not Assigned(FFileHelper) then
  begin
    Log('');
    Exit;
  end;


  try
    CheckListBox1.Clear;
    FFileExtensions.Clear;
  except
    on E: Exception do
    begin
      Log('' + E.Message);

    end;
  end;

  if FolderPath = '' then
  begin
    Log('');
    Exit;
  end;

  try
    SafePath := ExcludeTrailingPathDelimiter(FolderPath);
    SafePath := IncludeTrailingPathDelimiter(SafePath);
  except
    on E: Exception do
    begin
      Log('' + E.Message);
      SafePath := FolderPath;
    end;
  end;

  if not System.SysUtils.DirectoryExists(SafePath) then
  begin
    Log('' + SafePath);
    Exit;
  end;

  try

    try
      Log('' + SafePath);
      Extensions := FFileHelper.GetFileExtensions(SafePath);
    except
      on E: Exception do
      begin
        Log('' + E.Message);
        SetLength(Extensions, 0);
      end;
    end;

    if Length(Extensions) = 0 then
    begin
      Log('');
      Exit;
    end;


    for i := 0 to High(Extensions) do
    begin
      try
        if Extensions[i] = '' then
          Continue;


        CheckListBox1.Items.Add(Extensions[i]);
        FFileExtensions.Add(Extensions[i]);


        if (Extensions[i] <> '.exe') and (Extensions[i] <> '.dll') then
          CheckListBox1.Checked[i] := True;
      except
        on E: Exception do
        begin
          Log('' + Extensions[i] + ' - ' + E.Message);

          Continue;
        end;
      end;
    end;


    if CheckListBox1.Items.Count > 0 then
      Log('' + IntToStr(CheckListBox1.Items.Count) + '')
    else
      Log('');
  except
    on E: EEncodingError do
    begin
      Log('' + E.Message);

      try

        Log('');
        Extensions := FFileHelper.GetFileExtensions('C:\');


        if Length(Extensions) > 0 then
        begin
          for i := 0 to High(Extensions) do
          begin
            try
              CheckListBox1.Items.Add(Extensions[i]);
              FFileExtensions.Add(Extensions[i]);


              if (Extensions[i] <> '.exe') and (Extensions[i] <> '.dll') then
                CheckListBox1.Checked[i] := True;
            except
              Continue;
            end;
          end;
          Log('' + IntToStr(CheckListBox1.Items.Count) + '');
        end;
      except
        on E2: Exception do
          Log('' + E2.Message);
      end;
    end;
    on E: Exception do
    begin
      Log('' + E.Message);

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
  SelectedFileNames: TStringList;
  HasSelectedExtensions: Boolean;
  FileCount: Integer;
begin
  StartLogBuffering;

  SelectedFileNames := TStringList.Create;
  try

    for i := 1 to StringGrid1.RowCount - 1 do
    begin
      if (StringGrid1.Cells[0, i] = TUIHelper.GetCheckMark) and (StringGrid1.Cells[2, i] <> '') then
        SelectedFileNames.Add(StringGrid1.Cells[2, i]);

    end;


    FUIHelper.ClearGrid(StringGrid1);

    // (Fix Deprecation Warning)
    if not System.SysUtils.DirectoryExists(FolderPath) then // Ensure qualified
    begin
      StringGrid1.Cells[2, 1] := '';

      AdjustGridColumnWidths;
      EndLogBuffering;
      Exit;
    end;

    Screen.Cursor := crHourGlass;
    try

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


      if not HasSelectedExtensions then
      begin
        Log('');
        StringGrid1.Cells[2, 1] := '';

        AdjustGridColumnWidths;
        EndLogBuffering;
        Exit;
      end;


      Log(GetLocalizedMessageFmt('LogStartSearching', [FolderPath, BoolToStr(FIncludeSubdirs, True)]));


      if FIncludeSubdirs then
        Log(GetLocalizedMessage('LogSubdirEnabled'))
      else
        Log(GetLocalizedMessage('LogSubdirDisabled'));


      ProgressBar1.Visible := True;
      lblProgress.Visible := True;
      lblProgress.Caption := GetLocalizedMessage('ProgressSearchingFiles');
      ProgressBar1.Position := 0;
      Application.ProcessMessages;


      Files := FFileHelper.GetFilesInFolder(FolderPath, FileExtensions, FIncludeSubdirs, FMaxDepth);


      FileCount := Length(Files);
      Log(GetLocalizedMessageFmt('LogFilesFound', [FileCount]));


      if FileCount >= 2000 then
      begin
        var ConfirmThresholds: array of Integer;
        var ThresholdCaptions: array of string;
        var ti: Integer;
        ConfirmThresholds := [2000, 5000, 20000, 100000, 500000];
        ThresholdCaptions := ['2,000', '5,000', '', '', ''];


        ti := High(ConfirmThresholds);
        while (ti >= 0) and (FileCount < ConfirmThresholds[ti]) do
          Dec(ti);

        if ti >= 0 then
        begin
          var Msg := Format('%s',
            [FileCount, ThresholdCaptions[ti]]);
          if Application.MessageBox(PChar(Msg), '',
            MB_YESNO or MB_ICONQUESTION) = IDNO then
          begin
            Log('');
            ProgressBar1.Visible := False;
            lblProgress.Visible := False;
            EndLogBuffering;
            Exit;
          end;
        end;
      end;


      if FileCount > 0 then
      begin
        ProgressBar1.Max := FileCount;
        ProgressBar1.Position := 0;
        lblProgress.Caption := GetLocalizedMessageFmt('ProgressDetectingEncoding', [FileCount]);
        Application.ProcessMessages;
      end;


      StringGrid1.BeginUpdate;
      try


        StringGrid1.RowCount := 2;


        for i := 0 to High(Files) do
        begin
          FileName := ExtractFileName(Files[i]);


          EncodingName := FFileHelper.DetectFileEncoding(Files[i], HasBOM);


          ExtSelected := SelectedFileNames.IndexOf(FileName) >= 0;


          FUIHelper.AddFileToGridAt(StringGrid1, i + 1, FileName, EncodingName, ExtSelected);


          var UpdateInterval := 50;
          if FileCount < 100 then
            UpdateInterval := 10
          else if FileCount > 1000 then
            UpdateInterval := 100;

          if (i > 0) and ((i mod UpdateInterval = 0) or (i = High(Files))) then
          begin
            ProgressBar1.Position := i;
            lblProgress.Caption := GetLocalizedMessageFmt('ProgressDetecting', [i, FileCount, i / FileCount * 100]);
            Application.ProcessMessages;
          end;
        end;


        if FileCount > 0 then
        begin
          ProgressBar1.Position := FileCount;
          lblProgress.Caption := GetLocalizedMessageFmt('ProgressCompleteFiles', [FileCount]);
          Application.ProcessMessages;
        end;
      finally
        StringGrid1.EndUpdate;
      end;


      if (FileCount = 0) or (StringGrid1.Cells[2, 1] = '') then
        StringGrid1.Cells[2, 1] := '';


      AdjustGridColumnWidths;


      Log(GetLocalizedMessageFmt('LogDetectionComplete', [FileCount]));
      

      Sleep(300);
      ProgressBar1.Visible := False;
      lblProgress.Visible := False;
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    SelectedFileNames.Free;
    EndLogBuffering;
  end;
end;

procedure TForm1.InvalidateForm;
begin
  inherited Invalidate;

  Application.ProcessMessages;
end;

function TForm1.GetLocalizedMessage(const MsgId: string): string;
var
  LangStrings: TLanguageStrings;
  Context: TRttiContext;
  RttiType: TRttiType;
  RttiField: TRttiField;
begin

  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);


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
          Result := MsgId;
      end
      else
        Result := MsgId;
    end
    else
      Result := MsgId;
  finally
    Context.Free;
  end;
end;

function TForm1.GetLocalizedMessageFmt(const MsgId: string; const Args: array of const): string;
begin
  Result := System.SysUtils.Format(GetLocalizedMessage(MsgId), Args);
end;


procedure TForm1.ShowLocalizedMessage(const MsgId: string);
var
  Title: string;
begin

  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;


  Application.MessageBox(PChar(GetLocalizedMessage(MsgId)), PChar(Title), MB_OK + MB_ICONINFORMATION);
end;


procedure TForm1.ShowLocalizedMessageFmt(const MsgId: string; const Args: array of const);
var
  Title: string;
begin

  Title := ControllerLanguage.GetLanguageStrings(FCurrentLanguage).WindowTitle;


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

  FileName := ExtractFileName(FilePath);


  EncodingName := FFileHelper.DetectFileEncoding(FilePath, HasBOM);


  Found := False;
  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[2, i] = FileName then
    begin

      StringGrid1.Cells[1, i] := EncodingName;
      Found := True;
      Break;
    end;
  end;


  if not Found and (FileName <> '') then
  begin
    Log('' + FileName + '' + EncodingName);
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

  if (FSelectedRow <= 0) or (FSelectedRow >= StringGrid1.RowCount) then
  begin
    ShowLocalizedMessage('MsgSelectFile');
    Exit;
  end;


  SelectedFile := IncludeTrailingPathDelimiter(FSelectedFolder) + StringGrid1.Cells[2, FSelectedRow];
  if not FileExists(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgFileNotExists', [SelectedFile]);
    Exit;
  end;


  if not FFileHelper.IsNormalTextFile(SelectedFile) then
  begin
    ShowLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(SelectedFile)]);
    Exit;
  end;

  try

    Log('' + SelectedFile);
    HasBOM := False;
    DetectedEncoding := FFileHelper.DetectFileEncoding(SelectedFile, HasBOM);
    Encoding := nil;

    Log('' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));


    if Assigned(SynEditForm) then
    begin

      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('');
        end;
      except
        on E: Exception do
        begin
          Log('' + E.Message);

          try
            FreeAndNil(SynEditForm);
            Log('');
          except
            on E2: Exception do
            begin
              Log('' + E2.Message);

            end;
          end;
        end;
      end;
    end;


    if Assigned(SynEditForm) then
    begin

      Log('');
    end
    else
    begin

      Log('');
      try
        SynEditForm := TSynEditForm.Create(Self, FFileHelper);
        if not Assigned(SynEditForm) then
        begin
          ShowLocalizedMessage('MsgCannotCreateViewer');
          Log('');
          Exit;
        end;
        Log('');
      except
        on E: Exception do
        begin
          ShowLocalizedMessageFmt('MsgCannotCreateViewer', [E.Message]);
          Log('' + E.Message);
          Exit;
        end;
      end;
    end;


    Log('' + SelectedFile);
    try

      Log('' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));


      var FileEncoding: TEncoding := nil;
      try
        if SameText(DetectedEncoding, 'UTF-8') or SameText(DetectedEncoding, 'UTF-8 with BOM') then
          FileEncoding := TEncoding.UTF8
        else if SameText(DetectedEncoding, 'UTF-16LE') then
          FileEncoding := TEncoding.Unicode
        else if SameText(DetectedEncoding, 'UTF-16BE') then
          FileEncoding := TEncoding.BigEndianUnicode
        else if SameText(DetectedEncoding, 'GBK') or SameText(DetectedEncoding, 'GB2312') then
          FileEncoding := TEncoding.GetEncoding(936)
        else if SameText(DetectedEncoding, 'BIG5') then
          FileEncoding := TEncoding.GetEncoding(950)
        else
          FileEncoding := TEncoding.Default;


        SynEditForm.SetFileInfo(SelectedFile);
        SynEditForm.LoadFileWithEncoding(SelectedFile, FileEncoding, DetectedEncoding, HasBOM);
        Log('' + DetectedEncoding + ', BOM: ' + BoolToStr(HasBOM, True));
      finally

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
        Log('' + E.Message);


        try
          Log('');
          SynEditForm.LoadFile(SelectedFile);
          Log('');
        except
          on E2: Exception do
          begin
            Log('' + E2.Message);

            Exit;
          end;
        end;
      end;
    end;

    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50;


      SynEditForm.Show;
      SynEditForm.BringToFront;
      Log('' + SelectedFile);
    except
      on E: Exception do
      begin
        ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
        Log('' + E.Message);

      end;
    end;
  except
    on E: Exception do
    begin
      ShowLocalizedMessageFmt('MsgViewerError', [E.Message]);
      Log('' + E.Message);
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

    LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);


    Log('');


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


    Log('' + BoolToStr(AllChecked, True) +
        '' + BoolToStr(AnyChecked, True) +
        '' + IntToStr(SelectedCount));


    if AllChecked or AnyChecked then
    begin

      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := False;
      end;

      btnSelectAllExt.Caption := LangStrings.BtnSelectAllFileTypes;
      Log(LangStrings.LogDeselectAllFileTypes);
    end
    else
    begin

      for i := 0 to CheckListBox1.Items.Count - 1 do
      begin
        CheckListBox1.Checked[i] := True;
      end;

      btnSelectAllExt.Caption := LangStrings.BtnDeselectAllFileTypes;
      Log(LangStrings.LogSelectAllFileTypes);
    end;


    UpdateFileCountLabel;


    if System.SysUtils.DirectoryExists(FSelectedFolder) then
    begin

      Log(LangStrings.LogForceUpdateFileList);
      StringGrid1.RowCount := 2;
      StringGrid1.Rows[1].Clear();


      UpdateFileGrid(FSelectedFolder);


      SelectedCount := 0;
      for i := 0 to CheckListBox1.Items.Count - 1 do
        if CheckListBox1.Checked[i] then
          Inc(SelectedCount);

      Log('' + IntToStr(SelectedCount) + '');


      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log('' + E.Message);
  end;
end;

procedure TForm1.UpdateFileCountLabel;
var
  i, SelectedCount: Integer;
  TotalFiles: Integer;
begin

  SelectedCount := 0;
  for i := 0 to CheckListBox1.Items.Count - 1 do
    if CheckListBox1.Checked[i] then
      Inc(SelectedCount);


  TotalFiles := 0;
  for i := 1 to StringGrid1.RowCount - 1 do
    if (StringGrid1.Cells[2, i] <> '') and
       (StringGrid1.Cells[2, i] <> '') and
       (StringGrid1.Cells[2, i] <> '') and
       (StringGrid1.Cells[2, i] <> '') then
      Inc(TotalFiles);


  Log('' + IntToStr(SelectedCount) + '/' +
      IntToStr(CheckListBox1.Items.Count) + '' +
      IntToStr(TotalFiles) + '');
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
      0:
      begin
        Tree.Canvas.Font.Style := [fsBold];
        Tree.Canvas.Font.Size := FOriginalFontSize + 2;
        if not IsSelected then
          Tree.Canvas.Font.Color := clNavy
        else
          Tree.Canvas.Font.Color := clHighlightText;
      end;

      1:
      begin
        Tree.Canvas.Font.Style := [fsBold];
        Tree.Canvas.Font.Size := FOriginalFontSize + 1;
        if not IsSelected then
          Tree.Canvas.Font.Color := clBlue
        else
          Tree.Canvas.Font.Color := clHighlightText;
      end;

      else
      begin
        NodeText := Node.Text;
        BracketPos := Pos('(', NodeText);

        if BracketPos > 0 then
        begin
          DefaultDraw := False;

          EncodingPart := Trim(Copy(NodeText, 1, BracketPos - 1));
          DescPart := Copy(NodeText, BracketPos, MaxInt);

          TextRect := Node.DisplayRect(True);

          if IsSelected then
          begin

            Tree.Canvas.Brush.Color := clHighlight;
            Tree.Canvas.FillRect(TextRect);


            Tree.Canvas.Font.Style := [fsBold];
            Tree.Canvas.Font.Color := clHighlightText;
            Tree.Canvas.TextOut(TextRect.Left, TextRect.Top, EncodingPart);


            TextWidth := Tree.Canvas.TextWidth(EncodingPart);
            Tree.Canvas.Font.Style := [];
            Tree.Canvas.Font.Color := clHighlightText;
            Tree.Canvas.TextOut(TextRect.Left + TextWidth, TextRect.Top, ' ' + DescPart);
          end
          else
          begin

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

    bmp.Canvas.Brush.Color := clWhite;
    bmp.Canvas.Pen.Color := clWhite;
    bmp.Canvas.Rectangle(0, 0, 16, 16);
    SetBkMode(bmp.Canvas.Handle, TRANSPARENT);
    bmp.Transparent := True;
    bmp.TransparentColor := clWhite;

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
  if Assigned(FIconList) and (FIconList.Count >= 10) then
    Exit;

  bmp := Vcl.Graphics.TBitmap.Create;
  try

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


    AddIconNoClear(
      procedure(C: Vcl.Graphics.TCanvas)
      var R: TRect; TW, TH: Integer; S: string;
      begin
        R := Rect(2,2,14,14);
        C.Brush.Color := RGB(0, 160, 80);
        C.Pen.Color := RGB(0,120,60);
        C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 3, 3);
        S := '';
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

        R := Rect(3,2,13,14);

        C.Brush.Color := clWhite;
        C.Pen.Color := RGB(150,150,150);
        C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

        C.Pen.Color := RGB(180,180,180);
        C.MoveTo(R.Right-5, R.Top);
        C.LineTo(R.Right-1, R.Top+4);
        C.LineTo(R.Right-1, R.Bottom-1);
        C.LineTo(R.Left, R.Bottom-1);

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

    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];
      NodeLevel := Node.Level;


      if (NodeLevel > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);


        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin

          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (FEncodingModel.Encodings[NodeData].HasBOM) then
          begin

            TreeViewEncodings.Selected := Node;

            Node.MakeVisible;


            Log('' + Node.Text);


            Exit;
          end;
        end;
      end;
    end;


    for i := 0 to TreeViewEncodings.Items.Count - 1 do
    begin
      Node := TreeViewEncodings.Items[i];

      if (Node.Level > 0) and (Integer(Node.Data) >= 0) then
      begin
        NodeData := Integer(Node.Data);

        if (NodeData >= 0) and (NodeData < FEncodingModel.EncodingCount) then
        begin

          if (FEncodingModel.Encodings[NodeData].CodePage = 65001) and
             (not FEncodingModel.Encodings[NodeData].HasBOM) then
          begin
            TreeViewEncodings.Selected := Node;
            Node.MakeVisible;
            Log('' + Node.Text);
            Exit;
          end;
        end;
      end;
    end;

    Log('');
  except
    on E: Exception do
      Log('' + E.Message);
  end;
end;

procedure TForm1.ScrollEncodingTreeToLeft;
begin
  try
    if Assigned(TreeViewEncodings) and TreeViewEncodings.HandleAllocated then
    begin

      TreeViewEncodings.Perform(WM_HSCROLL, SB_LEFT, 0);

      TreeViewEncodings.Perform(WM_HSCROLL, SB_LEFT, 0);
    end;
  except

  end;
end;

procedure TForm1.AdjustGridColumnWidths;
begin

  StringGrid1.ColWidths[0] := 40;
  StringGrid1.ColWidths[1] := 112;
  StringGrid1.ColWidths[2] := 613;


  StringGrid1.Invalidate;
end;

procedure TForm1.InitializeUI;
begin

  FUIHelper.InitStringGrid(StringGrid1);
  FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);


  InitTreeIcons;
  TreeViewEncodings.Images := FIconList;


  TreeViewEncodings.OnAdvancedCustomDrawItem := TreeViewEncodingsAdvancedCustomDrawItem;


  AdjustGridColumnWidths;


  SelectUTF8BOMInTreeView;


  ScrollEncodingTreeToLeft;


  CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;
  StringGrid1.PopupMenu := GridPopupMenu;
  btnShowContent.OnClick := btnShowContentClick;
  btnSelectAllExt.OnClick := btnSelectAllExtClick;


  btnShowContent.Hint := '';
  btnShowContent.ShowHint := True;

  btnSelectAllExt.Hint := '';
  btnSelectAllExt.ShowHint := True;


  ApplyLanguageStrings;


  chkIncludeSubdirs.Checked := False;
  FIncludeSubdirs := False;
  chkIncludeSubdirs.OnClick := chkIncludeSubdirsClick;

  // Init instant scan toggle
  FInstantScan := FConfig.InstantScan;
  chkInstantScan.Checked := FInstantScan;
  chkInstantScan.OnClick := chkInstantScanClick;
  btnScanDir.Visible := not FInstantScan;
  btnScanDir.OnClick := btnScanDirClick;


  FMaxDepth := 2;
  SpinEditDepth.Value := FMaxDepth;
  SpinEditDepth.OnChange := SpinEditDepthChange;
  SpinEditDepth.Visible := False;
  lblDepth.Visible := False;

  // Setup Shell-aware directory tree (TVirtualExplorerTreeview)
  // Pattern from DeepLaunch: set Active:=False, configure, HandleNeeded, then Active:=True
  begin
    vstDir.Active := False;
    vstDir.RootFolder := rfDesktop;
    vstDir.FileObjects := [foFolders, foHidden];
    vstDir.TreeOptions.VETFolderOptions :=
      vstDir.TreeOptions.VETFolderOptions + [toFoldersExpandable] - [toHideRootFolder];
    vstDir.OnChange := vstDirChange;

    // Force handle creation before Shell COM calls
    vstDir.HandleNeeded;
    vstDir.Active := True;

    // Resolve startup directory
    if (FConfig.LastDirectory <> '') and System.SysUtils.DirectoryExists(FConfig.LastDirectory) then
    begin
      Log('' + FConfig.LastDirectory);
      FSelectedFolder := FConfig.LastDirectory;
    end
    else
    begin
      try
        FSelectedFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Documents';
        Log('' + FSelectedFolder);
      except
        FSelectedFolder := ExtractFilePath(ParamStr(0));
        Log('' + FSelectedFolder);
      end;
    end;

    if not System.SysUtils.DirectoryExists(FSelectedFolder) then
    begin
      FSelectedFolder := 'C:\';
      Log('' + FSelectedFolder);
    end;

    BrowseToDir(FSelectedFolder);
  end;


  try
    if (FSelectedFolder = '') or (not System.SysUtils.DirectoryExists(FSelectedFolder)) then
    begin
      Log('');
      FSelectedFolder := 'C:\';
    end;

    if not Assigned(FFileHelper) then
    begin
      Log('');
    end
    else
    begin
      try

        Log('' + FSelectedFolder);
        UpdateFileExtensions(FSelectedFolder);
        Log('');
      except
        on E: Exception do
        begin
          Log('' + E.Message);

        end;
      end;
    end;


    try
      StringGrid1.Cells[2, 1] := '';
      AdjustGridColumnWidths;
    except
      on E: Exception do
      begin
        Log('' + E.Message);

      end;
    end;


    Log('');
  except
    on E: Exception do
    begin
      Log('' + E.Message);
      try
        StringGrid1.Cells[2, 1] := '';
        AdjustGridColumnWidths;
      except

        Log('');
      end;
    end;
  end;


  CreateLanguageSelector;


  Log('' + FCurrentLanguage);

  FOriginalFontSize := TreeViewEncodings.Font.Size;
end;

class procedure TForm1.Initialize;
begin

  ControllerLanguage.InitializeLanguageManager;
end;

procedure TForm1.InitializeLanguageManager;
begin

  ControllerLanguage.InitializeLanguageManager;


  Log('');
end;

procedure TForm1.CreateLanguageSelector;
var
  i: Integer;
  LangFile: string;
  FoundLanguages: Integer;
  SystemLangCode: string;
  MatchedLangCode: string;
begin

  ComboBox1.Items.Clear;
  ComboBox1.Items.AddObject('English', TObject(1));
  FoundLanguages := 1;


  Log('' + IniDir);


  for i := 0 to High(LANGUAGE_MAPPINGS) do
  begin
    LangFile := IniDir + '\' + LANGUAGE_MAPPINGS[i].LanguageCode + '.ini';


    Log('' + LangFile);

    if FileExists(LangFile) then
    begin

      ComboBox1.Items.AddObject(LANGUAGE_MAPPINGS[i].DisplayName, TObject(i));
      Inc(FoundLanguages);


      Log('' + LANGUAGE_MAPPINGS[i].LanguageCode + ' - ' + LANGUAGE_MAPPINGS[i].DisplayName);
    end
    else
    begin

      Log('' + LANGUAGE_MAPPINGS[i].LanguageCode);
    end;
  end;


  SystemLangCode := ControllerLanguage.GetCurrentLanguage;
  Log('' + SystemLangCode);


  MatchedLangCode := '';
  ComboBox1.ItemIndex := 0;

  if SystemLangCode <> '' then
  begin
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

    if MatchedLangCode <> '' then
    begin
      SwitchToLanguageCode(MatchedLangCode);
      Log('' + MatchedLangCode);
    end
    else
    begin
      SwitchToLanguageCode('en-US');
      Log('');
    end;
  end;


  Log('' + IntToStr(FoundLanguages) + '');
  Log('' + ComboBox1.Text);
end;

procedure TForm1.ApplyLanguageStrings;
var
  LangStrings: TLanguageStrings;
begin

  LangStrings := ControllerLanguage.GetLanguageStrings(FCurrentLanguage);


  Self.Caption := LangStrings.WindowTitle;
  btnConvert.Caption := LangStrings.BtnConvert;
  btnSingleFile.Caption := LangStrings.BtnSingleFile + LangStrings.SingleFileConvertSuffix;
  btnRefresh.Caption := LangStrings.BtnRefresh;
  btnClose.Caption := LangStrings.BtnClose;
  btnToggleSelect.Caption := LangStrings.BtnToggleSelect;

  StringGrid1.Cells[0, 0] := LangStrings.FileSelectColumn;
  StringGrid1.Cells[1, 0] := LangStrings.EncodingColumn;
  StringGrid1.Cells[2, 0] := LangStrings.FileNameColumn;


  MenuItemConvert.Caption := LangStrings.PopupMenuConvert;
  MenuItemToggleSelect.Caption := LangStrings.PopupMenuToggleSelect;
  MenuItemConvertCurrent.Caption := LangStrings.BtnSingleFile + LangStrings.SingleFileConvertSuffix;
  MenuItemConvertAllFiles.Caption := LangStrings.BtnConvert;
  MenuItemViewContent.Caption := LangStrings.BtnPreview;


  chkIncludeSubdirs.Caption := LangStrings.ChkIncludeSubdirs;
  chkInstantScan.Caption := LangStrings.ChkInstantScan;
  btnScanDir.Caption := LangStrings.BtnScanDir;
  lblDepth.Caption := LangStrings.LblDepth;


  btnSelectAllExt.Caption := LangStrings.BtnAllFileTypes;
  btnShowContent.Caption := LangStrings.BtnCheckContent;


  TreeViewEncodings.Items.BeginUpdate;
  try

    var SelectedEncoding: Integer := -1;
    if TreeViewEncodings.Selected <> nil then
      SelectedEncoding := Integer(TreeViewEncodings.Selected.Data);


    FUIHelper.SetupEncodingList(TreeViewEncodings, FEncodingModel);


    if SelectedEncoding >= 0 then
    begin

      for var i := 0 to TreeViewEncodings.Items.Count - 1 do
      begin
        var Node := TreeViewEncodings.Items[i];
        if (Node.Level > 0) and (Integer(Node.Data) >= 0) and
           (Integer(Node.Data) = SelectedEncoding) then
        begin
          TreeViewEncodings.Selected := Node;
          Node.MakeVisible;
          Log('');
          Break;
        end;
      end;
    end
    else
    begin
      SelectUTF8BOMInTreeView;
    end;
  finally
    TreeViewEncodings.Items.EndUpdate;
  end;


  ScrollEncodingTreeToLeft;


  Log('' + FCurrentLanguage);
end;

procedure TForm1.SwitchToLanguageCode(const LangCode: string);
var
  LangInfo: TLanguageInfo;
  i: Integer;
begin

  Log('' + LangCode);


  ControllerLanguage.SetLanguage(LangCode);
  FCurrentLanguage := LangCode;


  ApplyLanguageStrings;


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

  if not FileExists(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgFileNotExists', [FileName]));
    Exit;
  end;


  if not FFileHelper.IsNormalTextFile(FileName) then
  begin
    ShowMessage(GetLocalizedMessageFmt('MsgNotTextFile', [ExtractFileName(FileName)]));
    Exit;
  end;

  try

    if not Assigned(SynEditForm) then
    begin
      try
        Application.CreateForm(TSynEditForm, SynEditForm);
      except
        on E: Exception do
        begin
          ShowMessage('Error: ' + E.Message);
          Log('' + E.Message);
          Exit;
        end;
      end;
    end;


    try
      SynEditForm.LoadFile(FileName);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Log('' + E.Message);
        Exit;
      end;
    end;

    try
      if Self.Left + Self.Width + 20 + 600 < Screen.Width then
        SynEditForm.Left := Self.Left + Self.Width + 20
      else
        SynEditForm.Left := (Screen.Width - SynEditForm.Width) div 2;

      SynEditForm.Top := Self.Top + 50;


      SynEditForm.Show;


      Log('' + FileName);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Log('' + E.Message);
      end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + E.Message);
      Log('' + E.Message);
    end;
  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  if (Key = Ord('W')) and (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    AdjustGridColumnWidths;
    Log('');
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Deactivate Shell tree to prevent late COM callbacks during shutdown
  try
    vstDir.OnChange := nil;
    vstDir.Active := False;
  except
  end;


  try
    if Assigned(SynEditForm) then
    begin

      try
        if SynEditForm.Visible then
        begin
          SynEditForm.Hide;
          Log('');
          Application.ProcessMessages;
          Sleep(100);
        end;
      except
        on E: Exception do
        begin
          Log('' + E.Message);
        end;
      end;


      try
        SynEditForm.Release;
        SynEditForm := nil;
        Log('');
      except
        on E: Exception do
        begin
          Log('' + E.Message);
          try
            FreeAndNil(SynEditForm);
            Log('');
          except
            on E2: Exception do
            begin
              Log('' + E2.Message);
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('' + E.Message);
    end;
  end;


  try
    FUIHelper.FreeLogBuffer;
    Log('');
  except
    on E: Exception do
    begin
      Log('' + E.Message);
    end;
  end;
end;

procedure TForm1.chkIncludeSubdirsClick(Sender: TObject);
begin

  FIncludeSubdirs := chkIncludeSubdirs.Checked;


  SpinEditDepth.Visible := FIncludeSubdirs;
  lblDepth.Visible := FIncludeSubdirs;

  if FIncludeSubdirs then
  begin
    Log('' + IntToStr(FMaxDepth));
    ShowLocalizedMessage('MsgSubdirEnabled');
  end
  else
    Log('');


  UpdateFileGrid(FSelectedFolder);


  Log('' + IntToStr(StringGrid1.RowCount - 1) + '');
end;

procedure TForm1.SpinEditDepthChange(Sender: TObject);
begin
  FMaxDepth := SpinEditDepth.Value;
  Log('' + IntToStr(FMaxDepth));
  if FIncludeSubdirs then
    UpdateFileGrid(FSelectedFolder);
end;

procedure TForm1.chkInstantScanClick(Sender: TObject);
begin
  FInstantScan := chkInstantScan.Checked;
  FConfig.InstantScan := FInstantScan;
  btnScanDir.Visible := not FInstantScan;
  if btnScanDir.Visible then
    Log(GetLocalizedMessage('LogInstantScanOff'))
  else
    Log(GetLocalizedMessage('LogInstantScanOn'));
end;

procedure TForm1.btnScanDirClick(Sender: TObject);
begin
  if (FSelectedFolder = '') or (not System.SysUtils.DirectoryExists(FSelectedFolder)) then
  begin
    ShowLocalizedMessage('MsgSelectValidFolder');
    Exit;
  end;
  Log(FSelectedFolder);
  try
    Screen.Cursor := crHourGlass;
    UpdateFileExtensions(FSelectedFolder);
    UpdateFileGrid(FSelectedFolder);
    AddDirToHistory(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
  end;
end;

{
procedure TForm1.btnCancelClick(Sender: TObject);
begin
  if Assigned(FAsyncProcessor) then
  begin
    Log('');
    FAsyncProcessor.Cancel;
    HideProgress;
  end;
end;
}

{
procedure TForm1.InitializeAsyncComponents;
begin

  FAsyncProcessor := TAsyncFileProcessor.Create(
    TProc<string>(
      procedure(const LogMsg: string)
      begin
        Log(LogMsg);
      end
    )
  );


  FProgressController := TProgressController.Create(ProgressBar1, lblProgress, btnCancel);
  FProgressController.OnCancel := btnCancelClick;

  Log('');
end;
}

{
procedure TForm1.FinalizeAsyncComponents;
begin
  try

    if Assigned(FAsyncProcessor) then
    begin
      FAsyncProcessor.Cancel;
      FAsyncProcessor.WaitForCompletion(3000);
    end;


    FreeAndNil(FAsyncProcessor);
    FreeAndNil(FProgressController);

    Log('');
  except
    on E: Exception do
      Log('' + E.Message);
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

  if Assigned(FProgressController) then
    FProgressController.UpdateProgress(Progress);


  if Progress.TotalFiles > 0 then
  begin
    var ProgressPercent := (Progress.ProcessedFiles * 100) div Progress.TotalFiles;
    Caption := Format(FLanguageStrings.WindowTitleScanProgress,
      [ProgressPercent, Progress.ProcessedFiles, Progress.TotalFiles]);


    if Progress.ProcessedFiles >= Progress.TotalFiles then
    begin

      HideProgress;
      Caption := FLanguageStrings.WindowTitleDefault;

      var Results := FAsyncProcessor.GetResults;
      Log(Format(FLanguageStrings.LogAsyncScanComplete, [Length(Results)]));


      if Length(Results) = 0 then
        StringGrid1.Cells[2, 1] := '';


      AdjustGridColumnWidths;
    end;
  end;
end;
}

{
procedure TForm1.OnFileScanResult(const Result: TFileScanResult);
begin

  var RowIndex := StringGrid1.RowCount;
  StringGrid1.RowCount := RowIndex + 1;

  StringGrid1.Cells[0, RowIndex] := '';
  StringGrid1.Cells[1, RowIndex] := Result.Encoding;
  StringGrid1.Cells[2, RowIndex] := Result.FileName;


  if (RowIndex mod 50 = 0) then
    Application.ProcessMessages;
end;

procedure TForm1.OnConversionProgress(const Progress: TBatchConversionResult);
begin

  if Assigned(FProgressController) then
    FProgressController.UpdateConversionProgress(Progress);


  if Progress.TotalFiles > 0 then
  begin
    var ProcessedFiles := Progress.SuccessCount + Progress.FailCount + Progress.SkippedCount;
    var ProgressPercent := (ProcessedFiles * 100) div Progress.TotalFiles;
    Caption := Format(FLanguageStrings.WindowTitleConvertProgress,
      [ProgressPercent, Progress.SuccessCount, Progress.FailCount]);


    if ProcessedFiles >= Progress.TotalFiles then
    begin

      HideProgress;
      Caption := FLanguageStrings.WindowTitleDefault;


      UpdateFileGrid(FSelectedFolder);

      Log('');
      ShowMessage(Format('Batch conversion result: %d success, %d failed', [Progress.SuccessCount, Progress.FailCount]));
    end;
  end;
end;

procedure TForm1.UpdateFileGridAsync(const FolderPath: string);
var
  FileExtensions: TArray<string>;
  i: Integer;
  HasSelectedExtensions: Boolean;
begin

  if not System.SysUtils.DirectoryExists(FolderPath) then
  begin
    StringGrid1.Cells[2, 1] := '';
    AdjustGridColumnWidths;
    Exit;
  end;


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


  if not HasSelectedExtensions then
  begin
    Log('');
    StringGrid1.Cells[2, 1] := '';
    AdjustGridColumnWidths;
    Exit;
  end;


  FUIHelper.ClearGrid(StringGrid1);


  ShowProgress;


  Log('' + FolderPath + '' + BoolToStr(FIncludeSubdirs, True));


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
    ShowLocalizedMessage('MsgSelectFiles');
    Exit;
  end;


  ShowProgress;


  Log(Format('%s',
    [Length(Files), TargetEncoding, BoolToStr(WithBOM, True)]));


  FAsyncProcessor.ConvertFilesAsync(
    Files,
    TargetEncoding,
    WithBOM,
    OnConversionProgress
  );
end;
}

{ Directory History }

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
    
    Log(Format('%s', [CBoxDirHistory.Items.Count]));
  except
    on E: Exception do
      Log('' + E.Message);
  end;
end;

procedure TForm1.SaveDirHistory;
var
  i: Integer;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  try

    FConfig.IniFile.EraseSection('DirHistory');
    

    FConfig.IniFile.WriteInteger('DirHistory', 'Count', CBoxDirHistory.Items.Count);
    

    for i := 0 to CBoxDirHistory.Items.Count - 1 do
      FConfig.IniFile.WriteString('DirHistory', 'Dir' + IntToStr(i), CBoxDirHistory.Items[i]);
      

    FConfig.IniFile.UpdateFile;
      
    Log(Format('%s', [CBoxDirHistory.Items.Count]));
  except
    on E: Exception do
      Log('' + E.Message);
  end;
end;

procedure TForm1.AddDirToHistory(const DirPath: string);
var
  Index: Integer;
const
  MAX_HIDeepStory = 20;
begin
  if not Assigned(CBoxDirHistory) then
    Exit;
    
  if (DirPath = '') or not System.SysUtils.DirectoryExists(DirPath) then
    Exit;
    

  Index := CBoxDirHistory.Items.IndexOf(DirPath);
  
  if Index >= 0 then
  begin

    CBoxDirHistory.Items.Move(Index, 0);
  end
  else
  begin

    CBoxDirHistory.Items.Insert(0, DirPath);
    

    while CBoxDirHistory.Items.Count > MAX_HIDeepStory do
      CBoxDirHistory.Items.Delete(CBoxDirHistory.Items.Count - 1);
  end;
  

  UpdateDirHistoryUI;
  
  SaveDirHistory;
  
  Log('' + DirPath);
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
    CBoxDirHistory.Text := '';
  end;
end;

procedure TForm1.BrowseToDir(const APath: string);
begin
  if Trim(APath) = '' then
    Exit;
  if not System.SysUtils.DirectoryExists(APath) then
    Exit;

  try
    if not vstDir.Active then
      vstDir.Active := True;
    vstDir.BrowseTo(APath, True);
  except
    on E: Exception do
      OutputDebugString(PChar('BrowseToDir failed: ' + E.Message));
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

    FSelectedFolder := SelectedDir;
    BrowseToDir(FSelectedFolder);
    Log('' + SelectedDir);
  end
  else
  begin
    ShowMessage('Directory not found: ' + SelectedDir);

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
    

  i := CBoxDirHistory.Items.Count - 1;
  while i >= 0 do
  begin
    if not System.SysUtils.DirectoryExists(CBoxDirHistory.Items[i]) then
    begin
      Log('' + CBoxDirHistory.Items[i]);
      CBoxDirHistory.Items.Delete(i);
    end;
    Dec(i);
  end;
  
  if CBoxDirHistory.Items.Count = 0 then
    CBoxDirHistory.Text := '';
end;


procedure TForm1.ConvertSelectedFilesToUTF8(const WithBOM: Boolean);
var
  SelectedFiles: TArray<string>;
  SuccessCount, i: Integer;
  FilePath: string;
begin

  SelectedFiles := FUIHelper.GetSelectedFiles(StringGrid1, FSelectedFolder);
  if Length(SelectedFiles) = 0 then
  begin
    ShowLocalizedMessage('MsgSelectFiles');
    Exit;
  end;

  Log(Format('%s', [IfThen(WithBOM, '', ''), Length(SelectedFiles)]));
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
        Log('' + FilePath);
    end;

    Log(Format('%s',
      [SuccessCount, Length(SelectedFiles), IfThen(WithBOM, 'UTF-8 with BOM', 'UTF-8 (no BOM)')]));


    if System.SysUtils.DirectoryExists(FSelectedFolder) then
      UpdateFileGrid(FSelectedFolder);
      AddDirToHistory(FSelectedFolder);
  finally
    Screen.Cursor := crDefault;
    EndLogBuffering;
  end;
end;


procedure TForm1.MenuItemAddUTF8BOMClick(Sender: TObject);
begin
  ConvertSelectedFilesToUTF8(True);
end;


procedure TForm1.MenuItemRemoveUTF8BOMClick(Sender: TObject);
begin
  ConvertSelectedFilesToUTF8(False);
end;

initialization
  RegisterClasses([TVirtualExplorerTreeview]);

end.