program EncodingDetectCompare;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Controls,
  Vcl.Grids,
  Vcl.ExtCtrls,
  ControllerEncoding,
  JclEncodingUtils;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    btnSelectFolder: TButton;
    btnDetect: TButton;
    btnSaveResults: TButton;
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnSelectFolderClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
    procedure btnSaveResultsClick(Sender: TObject);
  private
    FSelectedFolder: string;
    FFiles: TStringList;
    FEncodingController: TEncodingController;
    procedure InitializeGrid;
    procedure DetectFileEncoding(const FileName: string; RowIndex: Integer);
    procedure LogMessage(const Msg: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

{$R *.dfm}

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFiles := TStringList.Create;
  FEncodingController := TEncodingController.Create;
  FEncodingController.OnLog := LogMessage;
end;

destructor TForm1.Destroy;
begin
  FFiles.Free;
  FEncodingController.Free;
  inherited;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitializeGrid;
end;

procedure TForm1.InitializeGrid;
begin
  StringGrid1.ColCount := 4;
  StringGrid1.RowCount := 1;
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 0;
  StringGrid1.Cells[0, 0] := '文件名';
  StringGrid1.Cells[1, 0] := '我们的检测结果';
  StringGrid1.Cells[2, 0] := 'emEditor检测结果';
  StringGrid1.Cells[3, 0] := '是否一致';
  
  StringGrid1.ColWidths[0] := 300;
  StringGrid1.ColWidths[1] := 150;
  StringGrid1.ColWidths[2] := 150;
  StringGrid1.ColWidths[3] := 80;
end;

procedure TForm1.btnSelectFolderClick(Sender: TObject);
var
  SelectDir: string;
begin
  if SelectDirectory('选择要检测的文件夹', '', SelectDir) then
  begin
    FSelectedFolder := SelectDir;
    Caption := '编码检测比较 - ' + FSelectedFolder;
    
    // 清空文件列表
    FFiles.Clear;
    StringGrid1.RowCount := 1;
    
    // 获取所有文件
    TDirectory.GetFiles(FSelectedFolder, '*.*', TSearchOption.soAllDirectories, 
      procedure(const Path: string; const SearchRec: TSearchRec)
      begin
        // 只处理文本文件
        if (LowerCase(ExtractFileExt(Path)) = '.txt') or
           (LowerCase(ExtractFileExt(Path)) = '.csv') or
           (LowerCase(ExtractFileExt(Path)) = '.ini') or
           (LowerCase(ExtractFileExt(Path)) = '.log') or
           (LowerCase(ExtractFileExt(Path)) = '.xml') or
           (LowerCase(ExtractFileExt(Path)) = '.json') or
           (LowerCase(ExtractFileExt(Path)) = '.htm') or
           (LowerCase(ExtractFileExt(Path)) = '.html') or
           (LowerCase(ExtractFileExt(Path)) = '.css') or
           (LowerCase(ExtractFileExt(Path)) = '.js') or
           (LowerCase(ExtractFileExt(Path)) = '.md') then
        begin
          FFiles.Add(Path);
        end;
      end);
    
    // 更新网格行数
    StringGrid1.RowCount := FFiles.Count + 1;
    
    // 填充文件名列
    for var i := 0 to FFiles.Count - 1 do
    begin
      StringGrid1.Cells[0, i + 1] := ExtractFileName(FFiles[i]);
    end;
  end;
end;

procedure TForm1.btnDetectClick(Sender: TObject);
begin
  if FFiles.Count = 0 then
  begin
    ShowMessage('请先选择文件夹');
    Exit;
  end;
  
  // 检测每个文件的编码
  for var i := 0 to FFiles.Count - 1 do
  begin
    DetectFileEncoding(FFiles[i], i + 1);
  end;
end;

procedure TForm1.DetectFileEncoding(const FileName: string; RowIndex: Integer);
var
  EncodingName: string;
begin
  // 使用我们的编码检测算法
  if FEncodingController.DetectFileEncoding(FileName, EncodingName) then
  begin
    StringGrid1.Cells[1, RowIndex] := EncodingName;
  end
  else
  begin
    StringGrid1.Cells[1, RowIndex] := '检测失败';
  end;
  
  // emEditor的结果需要手动填写
  StringGrid1.Cells[2, RowIndex] := '';
  
  // 更新UI
  Application.ProcessMessages;
end;

procedure TForm1.btnSaveResultsClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  OutputFile: TStringList;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := '文本文件 (*.txt)|*.txt';
    SaveDialog.DefaultExt := 'txt';
    SaveDialog.Title := '保存检测结果';
    
    if SaveDialog.Execute then
    begin
      OutputFile := TStringList.Create;
      try
        // 添加标题行
        OutputFile.Add('文件名' + #9 + '我们的检测结果' + #9 + 'emEditor检测结果' + #9 + '是否一致');
        
        // 添加数据行
        for var i := 1 to StringGrid1.RowCount - 1 do
        begin
          var OurResult := StringGrid1.Cells[1, i];
          var EmResult := StringGrid1.Cells[2, i];
          var IsMatch := (OurResult = EmResult) and (OurResult <> '') and (EmResult <> '');
          
          OutputFile.Add(
            StringGrid1.Cells[0, i] + #9 + 
            OurResult + #9 + 
            EmResult + #9 + 
            BoolToStr(IsMatch, True)
          );
        end;
        
        // 保存文件
        OutputFile.SaveToFile(SaveDialog.FileName);
        ShowMessage('结果已保存到: ' + SaveDialog.FileName);
      finally
        OutputFile.Free;
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TForm1.LogMessage(const Msg: string);
begin
  // 可以添加日志记录
end;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
