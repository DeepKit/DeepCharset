unit ViewMemo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.Math;

const
  // Windows API 常量
  EC_LEFTMARGIN = 1;
  EC_RIGHTMARGIN = 2;
  WS_EX_RTLREADING = $00002000;

type
  TMemoForm = class(TForm)
    Panel1: TPanel;
    btnClose: TButton;
    lblFileInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure SaveFile(const FileName: string; Encoding: TEncoding);
  private
    { Private declarations }
    FEditor: TMemo;
    
    procedure CreateMemoEditor;
    procedure SetUTF8TextToMemo(const Text: string);
  public
    { Public declarations }
    procedure LoadFile(const FileName: string; Encoding: TEncoding);
    procedure SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
  end;

var
  MemoForm: TMemoForm;

implementation

{$R *.dfm}

procedure TMemoForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TMemoForm.FormCreate(Sender: TObject);
begin
  try
    CreateMemoEditor;
    Position := poScreenCenter;
  except
    on E: Exception do
    begin
      ShowMessage('初始化编辑器失败: ' + E.Message);
    end;
  end;
end;

procedure TMemoForm.CreateMemoEditor;
begin
  try
    // 创建标准Memo编辑器
    FEditor := TMemo.Create(Self);
    FEditor.Parent := Self;
    FEditor.Align := alClient;
    FEditor.Font.Name := 'Consolas';
    FEditor.Font.Size := 10;
    FEditor.ScrollBars := ssBoth;
    FEditor.WordWrap := False;
    FEditor.ReadOnly := True; // 设置为只读
    
    // 设置Memo的编码相关属性
    FEditor.WantReturns := True;
    FEditor.WantTabs := True;
    
    // 设置Memo支持Unicode字符集
    SendMessage(FEditor.Handle, EM_SETMARGINS, EC_LEFTMARGIN or EC_RIGHTMARGIN, MakeLong(3, 3));
    SendMessage(FEditor.Handle, WM_SETFONT, FEditor.Font.Handle, 1);
    
    // 尝试设置Unicode支持
    SetWindowLong(FEditor.Handle, GWL_EXSTYLE, GetWindowLong(FEditor.Handle, GWL_EXSTYLE) or WS_EX_RTLREADING);
    
    Panel1.Align := alBottom;
  except
    on E: Exception do
      ShowMessage('创建编辑器失败: ' + E.Message);
  end;
end;

procedure TMemoForm.LoadFile(const FileName: string; Encoding: TEncoding);
var
  Content: string;
  FileStream: TFileStream;
  EncodingToUse: TEncoding;
  BufferSize: Integer;
  Buffer: TBytes;
  Preamble: TBytes;
  PreambleLength: Integer;
begin
  try
    // 打开文件
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      // 读取文件内容到缓冲区
      BufferSize := FileStream.Size;
      SetLength(Buffer, BufferSize);
      FileStream.ReadBuffer(Buffer[0], BufferSize);
      
      // 如果没有指定编码，尝试自动检测
      if Encoding = nil then
      begin
        // 尝试检测BOM
        EncodingToUse := nil;
        TEncoding.GetBufferEncoding(Buffer, EncodingToUse);
        
        // 如果未检测到BOM，默认使用UTF-8
        if EncodingToUse = nil then
          EncodingToUse := TEncoding.UTF8
        else
          EncodingToUse := Encoding;
      end
      else
        EncodingToUse := Encoding;
      
      // 检查BOM并跳过
      Preamble := EncodingToUse.GetPreamble;
      PreambleLength := Length(Preamble);
      
      if (PreambleLength > 0) and (BufferSize >= PreambleLength) then
      begin
        // 检查文件是否带有BOM
        if CompareMem(@Buffer[0], @Preamble[0], PreambleLength) then
        begin
          // 跳过BOM
          Content := EncodingToUse.GetString(Buffer, PreambleLength, BufferSize - PreambleLength);
        end
        else
          Content := EncodingToUse.GetString(Buffer);
      end
      else
        Content := EncodingToUse.GetString(Buffer);
      
      // 将编码设置为memo的字符集
      SetUTF8TextToMemo(Content);
      
      // 设置字体以便更好地显示Unicode字符
      FEditor.Font.Name := 'Courier New';
      FEditor.Font.Size := 10;
      
      // 更新标题
      Caption := ExtractFileName(FileName);
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('加载文件失败: ' + E.Message);
      FEditor.Text := '无法加载文件。错误: ' + E.Message;
    end;
  end;
end;

procedure TMemoForm.SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
var
  BOMStr: string;
begin
  if HasBOM then
    BOMStr := '带BOM'
  else
    BOMStr := '无BOM';
    
  // 更新文件信息标签
  lblFileInfo.Caption := Format('文件: %s | 编码: %s (%s)',
    [ExtractFileName(FileName), EncodingName, BOMStr]);
end;

procedure TMemoForm.SaveFile(const FileName: string; Encoding: TEncoding);
var
  FileStream: TFileStream;
  Buffer: TBytes;
  EncodingToUse: TEncoding;
begin
  try
    // 如果未指定编码，默认使用UTF-8加BOM
    if Encoding = nil then
      EncodingToUse := TEncoding.UTF8
    else
      EncodingToUse := Encoding;
    
    // 获取文本内容的字节表示
    Buffer := EncodingToUse.GetBytes(FEditor.Text);
    
    // 创建文件流
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      // 首先写入BOM标记
      if EncodingToUse = TEncoding.UTF8 then
      begin
        // 添加UTF-8 BOM (EF BB BF)
        FileStream.Write(TEncoding.UTF8.GetPreamble[0], Length(TEncoding.UTF8.GetPreamble));
      end
      else
      begin
        // 其他编码使用自己的BOM
        FileStream.Write(EncodingToUse.GetPreamble[0], Length(EncodingToUse.GetPreamble));
      end;
      
      // 然后写入文件内容
      FileStream.Write(Buffer[0], Length(Buffer));
    finally
      FileStream.Free;
    end;
    
    // 更新标题
    Caption := ExtractFileName(FileName);
  except
    on E: Exception do
      ShowMessage('保存文件失败: ' + E.Message);
  end;
end;

// 辅助方法：正确设置UTF-8文本到Memo控件
procedure TMemoForm.SetUTF8TextToMemo(const Text: string);
begin
  try
    // 直接设置文本，因为 Text 参数已经是 Unicode 字符串
    FEditor.Text := Text;
    
    // 设置字体以更好地显示 Unicode 字符
    FEditor.Font.Name := 'Consolas';
    FEditor.Font.Size := 10;
    FEditor.Font.Charset := DEFAULT_CHARSET;
  except
    on E: Exception do
    begin
      ShowMessage('设置文本失败: ' + E.Message);
      FEditor.Text := '无法显示文本: ' + E.Message;
    end;
  end;
end;

end. 