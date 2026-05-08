unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IOUtils,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.Menus, System.UITypes, Vcl.Clipbrd,
  System.Math, HelperFiles;

type
  TSynEditForm = class(TForm)
    PanelTop: TPanel;
    LabelFileName: TLabel;
    LabelEncoding: TLabel;
    LabelFileSize: TLabel;
    PanelButtons: TPanel;
    btnClose: TButton;
    btnCopy: TButton;
    btnWordWrap: TButton;
    StatusBar: TStatusBar;
    PopupMenu: TPopupMenu;
    MenuItemCopy: TMenuItem;
    MenuItemSelectAll: TMenuItem;
    N1: TMenuItem;
    MenuItemWordWrap: TMenuItem;
    RichEdit1: TRichEdit;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnWordWrapClick(Sender: TObject);
    procedure MenuItemCopyClick(Sender: TObject);
    procedure MenuItemSelectAllClick(Sender: TObject);
    procedure MenuItemWordWrapClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RichEdit1Change(Sender: TObject);
    procedure RichEdit1Click(Sender: TObject);
    procedure RichEdit1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FFileName: string;
    FLineCount: Integer;
    FCharCount: Integer;
    FDetectedEncoding: string;
    FHasBOM: Boolean;
    FFileHelper: TFileHelper; // 添加文件助手引用

    procedure UpdateStatusBar;
    procedure SetupSyntaxHighlighter(const FileName: string);
    function IsBinaryFile(const FileName: string): Boolean;
    function LoadFileWithProperEncoding(const FileName: string): string;
    function GetCharsetFromEncoding(const EncodingName: string): TFontCharset;
  public
    constructor Create(AOwner: TComponent; AFileHelper: TFileHelper); reintroduce;
    destructor Destroy; override;
    procedure LoadFile(const FileName: string);
    procedure LoadFileWithEncoding(const FileName: string; Encoding: TEncoding;
      const DetectedEncoding: string; HasBOM: Boolean);
    procedure SetFileInfo(const FileName: string);
  end;

var
  SynEditForm: TSynEditForm;

implementation

{$R *.dfm}

constructor TSynEditForm.Create(AOwner: TComponent; AFileHelper: TFileHelper);
begin
  inherited Create(AOwner);
  FFileHelper := AFileHelper;
end;

destructor TSynEditForm.Destroy;
begin
  // FFileHelper 由外部管理，不需要释放
  inherited Destroy;
end;

function TSynEditForm.IsBinaryFile(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: array[0..1023] of Byte;
  BytesRead: Integer;
  I: Integer;
  BinaryCount: Integer;
  FileExt: string;
begin
  Result := False;
  if not FileExists(FileName) then
    Exit;

  // 根据文件扩展名进行初步判断
  FileExt := LowerCase(ExtractFileExt(FileName));

  // 明确的文本文件扩展名，直接返回False
  if (FileExt = '.txt') or (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dpk') or
     (FileExt = '.inc') or (FileExt = '.dfm') or (FileExt = '.fmx') or (FileExt = '.ini') or
     (FileExt = '.cfg') or (FileExt = '.conf') or (FileExt = '.log') or (FileExt = '.xml') or
     (FileExt = '.html') or (FileExt = '.htm') or (FileExt = '.css') or (FileExt = '.js') or
     (FileExt = '.json') or (FileExt = '.sql') or (FileExt = '.csv') or (FileExt = '.md') or
     (FileExt = '.readme') or (FileExt = '.bat') or (FileExt = '.cmd') or (FileExt = '.ps1') or
     (FileExt = '.c') or (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
     (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.py') or (FileExt = '.php') or
     (FileExt = '.rb') or (FileExt = '.pl') or (FileExt = '.sh') or (FileExt = '.vbs') or
     (FileExt = '.asm') or (FileExt = '.s') then
  begin
    Result := False;
    Exit;
  end;

  // 明确的二进制文件扩展名，直接返回True
  if (FileExt = '.exe') or (FileExt = '.dll') or (FileExt = '.sys') or (FileExt = '.bin') or
     (FileExt = '.dat') or (FileExt = '.db') or (FileExt = '.mdb') or (FileExt = '.accdb') or
     (FileExt = '.jpg') or (FileExt = '.jpeg') or (FileExt = '.png') or (FileExt = '.gif') or
     (FileExt = '.bmp') or (FileExt = '.ico') or (FileExt = '.tiff') or (FileExt = '.webp') or
     (FileExt = '.mp3') or (FileExt = '.wav') or (FileExt = '.mp4') or (FileExt = '.avi') or
     (FileExt = '.mkv') or (FileExt = '.mov') or (FileExt = '.wmv') or (FileExt = '.flv') or
     (FileExt = '.zip') or (FileExt = '.rar') or (FileExt = '.7z') or (FileExt = '.tar') or
     (FileExt = '.gz') or (FileExt = '.bz2') or (FileExt = '.xz') or (FileExt = '.pdf') or
     (FileExt = '.doc') or (FileExt = '.docx') or (FileExt = '.xls') or (FileExt = '.xlsx') or
     (FileExt = '.ppt') or (FileExt = '.pptx') then
  begin
    Result := True;
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      BytesRead := FileStream.Read(Buffer, SizeOf(Buffer));

      if BytesRead = 0 then
        Exit(False); // 空文件视为文本文件

      BinaryCount := 0;

      // 检查前1024字节中的二进制字符
      for I := 0 to BytesRead - 1 do
      begin
        // 如果包含控制字符（除了常见的文本控制字符）
        if (Buffer[I] < 32) and not (Buffer[I] in [0, 9, 10, 13, 26]) then
        begin
          Inc(BinaryCount);
        end
        // 检查高位字节（可能是二进制数据）
        else if Buffer[I] > 127 then
        begin
          // 对于高位字节，我们更宽容一些，因为可能是UTF-8或其他编码
          // 只有当连续出现很多高位字节时才认为是二进制
        end;
      end;

      // 如果二进制字符超过5%，认为是二进制文件
      Result := (BinaryCount * 100 div BytesRead) > 5;

    finally
      FileStream.Free;
    end;
  except
    Result := False; // 如果读取失败，假设是文本文件（更安全的默认值）
  end;
end;



function TSynEditForm.LoadFileWithProperEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  Encoding: TEncoding;
  EncodingName: string;
  HasBOM: Boolean;
  BOMSize: Integer;
begin
  Result := '';

  // 使用与Grid相同的编码检测逻辑
  if not Assigned(FFileHelper) then
  begin
    Result := '文件助手未初始化';
    Exit;
  end;

  EncodingName := FFileHelper.DetectFileEncoding(FileName, HasBOM);
  FDetectedEncoding := EncodingName;
  FHasBOM := HasBOM;

  // 调试信息：显示检测到的编码
  Caption := Format('文件查看器 - %s (检测编码: %s)', [ExtractFileName(FileName), EncodingName]);

  // 根据检测到的编码名称获取对应的TEncoding对象
  // 对于UTF-8编码，支持多种变体名称
  if (EncodingName = 'UTF-8') or (EncodingName = 'UTF-8 BOM') or
     (Pos('UTF-8', EncodingName) > 0) then
    Encoding := TEncoding.UTF8
  else if (EncodingName = 'UTF-16LE') or (Pos('UTF-16LE', EncodingName) > 0) then
    Encoding := TEncoding.Unicode
  else if (EncodingName = 'UTF-16BE') or (Pos('UTF-16BE', EncodingName) > 0) then
    Encoding := TEncoding.BigEndianUnicode
  else if (EncodingName = 'UTF-32LE') or (EncodingName = 'UTF-32BE') or
          (Pos('UTF-32', EncodingName) > 0) then
    Encoding := TEncoding.UTF8  // 对于UTF-32，回退到UTF-8
  else if EncodingName = 'ASCII' then
    Encoding := TEncoding.ASCII
  else if EncodingName = 'UTF-7' then
    Encoding := TEncoding.UTF7
  // 中文编码
  else if (EncodingName = 'GBK') or (EncodingName = 'GB2312') or (EncodingName = 'GB18030') then
    Encoding := TEncoding.GetEncoding(936)  // 中文GBK编码
  else if EncodingName = 'BIG5' then
    Encoding := TEncoding.GetEncoding(950)  // 繁体中文BIG5编码
  else if EncodingName = 'HZ-GB-2312' then
    Encoding := TEncoding.GetEncoding(52936)  // HZ-GB-2312编码
  // 日文编码
  else if (EncodingName = 'Shift-JIS') or (EncodingName = 'SHIFT_JIS') then
    Encoding := TEncoding.GetEncoding(932)  // 日文Shift-JIS编码
  else if (EncodingName = 'EUC-JP') or (EncodingName = 'EUCJP') then
    Encoding := TEncoding.GetEncoding(20932)  // 日文EUC-JP编码
  else if EncodingName = 'ISO-2022-JP' then
    Encoding := TEncoding.GetEncoding(50220)  // 日文ISO-2022-JP编码
  // 韩文编码
  else if (EncodingName = 'EUC-KR') or (EncodingName = 'EUCKR') then
    Encoding := TEncoding.GetEncoding(949)  // 韩文EUC-KR编码
  else if EncodingName = 'UHC' then
    Encoding := TEncoding.GetEncoding(949)  // 韩文UHC编码（与EUC-KR相同）
  // 欧洲编码
  else if (EncodingName = 'ISO-8859-1') or (EncodingName = 'Latin-1') then
    Encoding := TEncoding.GetEncoding(28591)  // 西欧Latin-1编码
  else if (EncodingName = 'ISO-8859-2') or (EncodingName = 'Latin-2') then
    Encoding := TEncoding.GetEncoding(28592)  // 中欧Latin-2编码
  else if (EncodingName = 'ISO-8859-15') or (EncodingName = 'Latin-9') then
    Encoding := TEncoding.GetEncoding(28605)  // 西欧Latin-9编码
  else if EncodingName = 'Windows-1252' then
    Encoding := TEncoding.GetEncoding(1252)  // 西欧Windows编码
  else if EncodingName = 'Windows-1251' then
    Encoding := TEncoding.GetEncoding(1251)  // 西里尔字母编码
  // 俄文编码
  else if (EncodingName = 'KOI8-R') or (EncodingName = 'KOI8R') then
    Encoding := TEncoding.GetEncoding(20866)  // 俄文KOI8-R编码
  else if (EncodingName = 'KOI8-U') or (EncodingName = 'KOI8U') then
    Encoding := TEncoding.GetEncoding(21866)  // 乌克兰文KOI8-U编码
  // 其他常见编码
  else if (EncodingName = 'ANSI') or (EncodingName = 'Default') then
    Encoding := TEncoding.Default  // 系统默认编码
  else
  begin
    // 尝试通过代码页名称获取编码
    try
      // 如果编码名称是数字，尝试作为代码页
      var CodePage: Integer;
      if TryStrToInt(EncodingName, CodePage) then
        Encoding := TEncoding.GetEncoding(CodePage)
      else
        Encoding := TEncoding.Default;
    except
      Encoding := TEncoding.Default; // 最终回退到默认编码
    end;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      if FileStream.Size = 0 then
        Exit;

      // 计算BOM大小
      BOMSize := 0;
      if HasBOM then
      begin
        if (Pos('UTF-8', EncodingName) > 0) then
          BOMSize := 3
        else if (Pos('UTF-16', EncodingName) > 0) then
          BOMSize := 2
        else if (Pos('UTF-32', EncodingName) > 0) then
          BOMSize := 4;
      end;

      // 跳过BOM
      FileStream.Position := BOMSize;

      // 读取文件内容
      SetLength(Buffer, FileStream.Size - BOMSize);
      if Length(Buffer) > 0 then
        FileStream.Read(Buffer[0], Length(Buffer));

      // 使用检测到的编码解码
      try
        Result := Encoding.GetString(Buffer);

        // 检查解码结果是否包含明显的乱码字符
        if (Pos('?', Result) > 0) and (Length(Result) > 10) then
        begin
          // 如果包含很多问号，可能是编码错误，尝试其他编码
          var QuestionMarkCount := 0;
          for var i := 1 to Length(Result) do
            if Result[i] = '?' then Inc(QuestionMarkCount);

          // 如果问号超过5%，认为编码可能有问题
          if (QuestionMarkCount * 100 div Length(Result)) > 5 then
            raise Exception.Create('编码可能不正确，包含过多问号字符');
        end;
      except
        // 如果当前编码失败，抛出异常进入回退逻辑
        raise;
      end;

    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 如果解码失败，尝试多种编码
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
        try
          SetLength(Buffer, FileStream.Size);
          if FileStream.Size > 0 then
            FileStream.Read(Buffer[0], FileStream.Size);

          // 按优先级尝试多种编码
          var EncodingTried: Boolean := False;
          var BestResult: string := '';
          var BestEncoding: string := '';
          var BestScore: Integer := -1;

          // 定义一个函数来评估解码质量
          var EvaluateDecoding := function(const Text: string): Integer
          begin
            Result := 0;
            if Length(Text) = 0 then Exit(-1000);

            var QuestionMarks := 0;
            var ChineseChars := 0;
            var ValidChars := 0;

            for var i := 1 to Length(Text) do
            begin
              var Ch := Text[i];
              if Ch = '?' then
                Inc(QuestionMarks)
              else if (Ord(Ch) >= $4E00) and (Ord(Ch) <= $9FFF) then // 中文字符范围
                Inc(ChineseChars)
              else if (Ord(Ch) >= 32) and (Ord(Ch) <= 126) then // ASCII可打印字符
                Inc(ValidChars);
            end;

            // 计算分数：中文字符+10分，有效字符+1分，问号-5分
            Result := ChineseChars * 10 + ValidChars - QuestionMarks * 5;

            // 如果问号太多，严重扣分
            if (QuestionMarks * 100 div Length(Text)) > 10 then
              Result := Result - 1000;
          end;

          // 检测并跳过BOM
          var BufferToUse: TBytes;
          var BOMSkipped: Integer := 0;

          // 检测UTF-8 BOM (EF BB BF)
          if (Length(Buffer) >= 3) and
             (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
          begin
            BOMSkipped := 3;
            SetLength(BufferToUse, Length(Buffer) - 3);
            if Length(BufferToUse) > 0 then
              Move(Buffer[3], BufferToUse[0], Length(BufferToUse));
          end
          // 检测UTF-16LE BOM (FF FE)
          else if (Length(Buffer) >= 2) and
                  (Buffer[0] = $FF) and (Buffer[1] = $FE) then
          begin
            BOMSkipped := 2;
            SetLength(BufferToUse, Length(Buffer) - 2);
            if Length(BufferToUse) > 0 then
              Move(Buffer[2], BufferToUse[0], Length(BufferToUse));
          end
          // 检测UTF-16BE BOM (FE FF)
          else if (Length(Buffer) >= 2) and
                  (Buffer[0] = $FE) and (Buffer[1] = $FF) then
          begin
            BOMSkipped := 2;
            SetLength(BufferToUse, Length(Buffer) - 2);
            if Length(BufferToUse) > 0 then
              Move(Buffer[2], BufferToUse[0], Length(BufferToUse));
          end
          else
          begin
            // 没有BOM，使用原始缓冲区
            BufferToUse := Buffer;
          end;

          // 1. 首先尝试UTF-8编码（现代文件最常用）
          try
            var TestResult := TEncoding.UTF8.GetString(BufferToUse);
            var Score := EvaluateDecoding(TestResult);
            if Score > BestScore then
            begin
              BestResult := TestResult;
              if BOMSkipped = 3 then
                BestEncoding := 'UTF-8 with BOM (回退)'
              else
                BestEncoding := 'UTF-8 (回退)';
              BestScore := Score;
            end;
          except
            // UTF-8失败，继续尝试其他编码
          end;

          // 2. 尝试GBK编码（中文文件常用）
          try
            var TestResult := TEncoding.GetEncoding(936).GetString(BufferToUse);
            var Score := EvaluateDecoding(TestResult);
            if Score > BestScore then
            begin
              BestResult := TestResult;
              BestEncoding := 'GBK (回退)';
              BestScore := Score;
            end;
          except
            // GBK失败，继续尝试其他编码
          end;

          // 3. 尝试Big5编码（繁体中文）
          try
            var TestResult := TEncoding.GetEncoding(950).GetString(BufferToUse);
            var Score := EvaluateDecoding(TestResult);
            if Score > BestScore then
            begin
              BestResult := TestResult;
              BestEncoding := 'Big5 (回退)';
              BestScore := Score;
            end;
          except
            // Big5失败，继续尝试其他编码
          end;

          // 4. 尝试Windows-1252编码（西欧）
          try
            var TestResult := TEncoding.GetEncoding(1252).GetString(BufferToUse);
            var Score := EvaluateDecoding(TestResult);
            if Score > BestScore then
            begin
              BestResult := TestResult;
              BestEncoding := 'Windows-1252 (回退)';
              BestScore := Score;
            end;
          except
            // Windows-1252失败，继续尝试其他编码
          end;

          // 5. 尝试默认编码
          try
            var TestResult := TEncoding.Default.GetString(BufferToUse);
            var Score := EvaluateDecoding(TestResult);
            if Score > BestScore then
            begin
              BestResult := TestResult;
              BestEncoding := 'Default (回退)';
              BestScore := Score;
            end;
          except
            // Default失败，继续
          end;

          // 使用最佳结果
          if BestScore > -1000 then
          begin
            Result := BestResult;
            FDetectedEncoding := BestEncoding;
            EncodingTried := True;
          end;

          // 如果所有编码都失败
          if not EncodingTried then
          begin
            Result := '无法解码文件内容 - 可能是二进制文件或损坏的文本文件';
            FDetectedEncoding := '解码失败';
          end;
        finally
          FileStream.Free;
        end;
      except
        Result := '无法读取文件内容';
        FDetectedEncoding := '未知';
      end;
    end;
  end;
end;

function TSynEditForm.GetCharsetFromEncoding(const EncodingName: string): TFontCharset;
begin
  // 根据编码名称返回对应的字符集
  // 对于Unicode编码，使用DEFAULT_CHARSET以获得最好的支持
  if (EncodingName = 'UTF-8') or (EncodingName = 'UTF-16LE') or (EncodingName = 'UTF-16BE') or
     (EncodingName = 'UTF-32LE') or (EncodingName = 'UTF-32BE') then
    Result := DEFAULT_CHARSET  // Unicode编码使用默认字符集
  // 对于中文编码，优先使用DEFAULT_CHARSET，因为现代Windows对Unicode支持更好
  else if (EncodingName = 'GBK') or (EncodingName = 'GB2312') or (EncodingName = 'GB18030') then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET以获得更好的中文支持
  else if EncodingName = 'BIG5' then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET以获得更好的繁体中文支持
  // 对于其他编码也优先使用DEFAULT_CHARSET
  else if (EncodingName = 'Shift-JIS') or (EncodingName = 'SHIFT_JIS') or
          (EncodingName = 'EUC-JP') or (EncodingName = 'EUCJP') or
          (EncodingName = 'ISO-2022-JP') then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET
  else if (EncodingName = 'EUC-KR') or (EncodingName = 'EUCKR') or (EncodingName = 'UHC') then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET
  else if (EncodingName = 'Windows-1251') or (EncodingName = 'KOI8-R') or (EncodingName = 'KOI8-U') then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET
  else if (EncodingName = 'Windows-1252') or (EncodingName = 'ISO-8859-1') or
          (EncodingName = 'ISO-8859-2') or (EncodingName = 'ISO-8859-15') or
          (EncodingName = 'Latin-1') or (EncodingName = 'Latin-2') or (EncodingName = 'Latin-9') then
    Result := DEFAULT_CHARSET  // 改为DEFAULT_CHARSET
  else if (EncodingName = 'ASCII') or (EncodingName = 'ANSI') or (EncodingName = 'Default') then
    Result := DEFAULT_CHARSET  // 使用DEFAULT_CHARSET
  else
    Result := DEFAULT_CHARSET;  // 所有情况都使用DEFAULT_CHARSET
end;

procedure TSynEditForm.SetupSyntaxHighlighter(const FileName: string);
var
  AppropriateCharset: TFontCharset;
begin
  // 根据检测到的编码设置合适的字符集
  AppropriateCharset := GetCharsetFromEncoding(FDetectedEncoding);

  // 设置基本的编辑器属性
  RichEdit1.Font.Name := 'Consolas';
  RichEdit1.Font.Size := 10;
  RichEdit1.Font.Charset := AppropriateCharset;  // 根据检测到的编码设置字符集
  RichEdit1.ReadOnly := True;
  RichEdit1.WordWrap := False;
  RichEdit1.ScrollBars := ssBoth;

  // RichEdit不支持语法高亮，但提供更好的Unicode支持
  // 如果需要语法高亮，需要安装完整的SynEdit组件

  // 调试信息：显示使用的字符集
  Caption := Format('文件查看器 - %s (编码: %s, 字符集: %d)',
    [ExtractFileName(FileName), FDetectedEncoding, Integer(AppropriateCharset)]);
end;

procedure TSynEditForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ESC关闭窗口
  if Key = VK_ESCAPE then
    Close;

  // Ctrl+A 全选
  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    RichEdit1.SelectAll;
    Key := 0;
  end;

  // Ctrl+C 复制
  if (Key = Ord('C')) and (ssCtrl in Shift) then
  begin
    if RichEdit1.SelLength > 0 then
      Clipboard.AsText := RichEdit1.SelText;
    Key := 0;
  end;
end;

procedure TSynEditForm.FormResize(Sender: TObject);
begin
  // 窗体大小调整时的处理（设计时控件会自动调整）
end;

procedure TSynEditForm.LoadFile(const FileName: string);
var
  FileContent: string;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('文件不存在: %s', [FileName]);

  // 检查是否为二进制文件
  if IsBinaryFile(FileName) then
  begin
    MessageDlg('此文件是二进制文件，无法显示文本内容。', mtWarning, [mbOK], 0);
    Exit;
  end;

  try
    FFileName := FileName;

    // 使用改进的编码检测和加载
    FileContent := LoadFileWithProperEncoding(FileName);

    // 设置到RichEdit
    RichEdit1.Text := FileContent;

    // 设置编辑器属性
    SetupSyntaxHighlighter(FileName);

    // 更新文件信息
    SetFileInfo(FileName);

    // 更新行数和字符数
    FLineCount := RichEdit1.Lines.Count;
    FCharCount := Length(RichEdit1.Text);
    UpdateStatusBar;
  except
    on E: Exception do
      raise Exception.CreateFmt('无法加载文件 %s: %s', [FileName, E.Message]);
  end;
end;

procedure TSynEditForm.LoadFileWithEncoding(const FileName: string; Encoding: TEncoding;
  const DetectedEncoding: string; HasBOM: Boolean);
begin
  // 简化实现，直接调用LoadFile，让SynEdit处理编码
  LoadFile(FileName);
end;

procedure TSynEditForm.MenuItemCopyClick(Sender: TObject);
begin
  btnCopyClick(Sender);
end;

procedure TSynEditForm.MenuItemSelectAllClick(Sender: TObject);
begin
  RichEdit1.SelectAll;
end;

procedure TSynEditForm.MenuItemWordWrapClick(Sender: TObject);
begin
  btnWordWrapClick(Sender);
  MenuItemWordWrap.Checked := RichEdit1.WordWrap;
end;

procedure TSynEditForm.SetFileInfo(const FileName: string);
var
  FileSize: Int64;
  EncodingText: string;
begin
  try
    FileSize := TFile.GetSize(FileName);

    // 更新窗体标题
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);

    // 更新文件信息标签
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := Format('文件大小: %.2f KB (%d 字节)', [FileSize / 1024, FileSize]);

    // 更新编码信息
    EncodingText := FDetectedEncoding;
    if FHasBOM then
      EncodingText := EncodingText + ' (带BOM)';
    LabelEncoding.Caption := Format('编码: %s', [EncodingText]);
  except
    // 忽略错误
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := '文件大小: 未知';
    LabelEncoding.Caption := '编码: 未知';
  end;
end;

procedure TSynEditForm.UpdateStatusBar;
begin
  // 更新状态栏信息
  StatusBar.Panels[0].Text := Format('行数: %d', [FLineCount]);
  StatusBar.Panels[1].Text := Format('字符数: %d', [FCharCount]);

  // 更新光标位置（使用RichEdit的SelStart属性）
  if RichEdit1.SelStart >= 0 then
  begin
    var Line, Col: Integer;
    Line := SendMessage(RichEdit1.Handle, EM_LINEFROMCHAR, RichEdit1.SelStart, 0) + 1;
    Col := RichEdit1.SelStart - SendMessage(RichEdit1.Handle, EM_LINEINDEX, Line - 1, 0) + 1;
    StatusBar.Panels[2].Text := Format('行: %d, 列: %d', [Line, Col]);
  end
  else
    StatusBar.Panels[2].Text := '';
end;

procedure TSynEditForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TSynEditForm.btnCopyClick(Sender: TObject);
begin
  if RichEdit1.SelLength > 0 then
    Clipboard.AsText := RichEdit1.SelText
  else
    Clipboard.AsText := RichEdit1.Text;
end;

procedure TSynEditForm.btnWordWrapClick(Sender: TObject);
begin
  RichEdit1.WordWrap := not RichEdit1.WordWrap;

  if RichEdit1.WordWrap then
  begin
    RichEdit1.ScrollBars := ssVertical;
    btnWordWrap.Caption := '关闭换行';
  end
  else
  begin
    RichEdit1.ScrollBars := ssBoth;
    btnWordWrap.Caption := '自动换行';
  end;

  // 更新菜单项状态
  if Assigned(MenuItemWordWrap) then
    MenuItemWordWrap.Checked := RichEdit1.WordWrap;
end;

procedure TSynEditForm.RichEdit1Change(Sender: TObject);
begin
  // 文本改变时更新行数和字符数
  FLineCount := RichEdit1.Lines.Count;
  FCharCount := Length(RichEdit1.Text);
  UpdateStatusBar;
end;

procedure TSynEditForm.RichEdit1Click(Sender: TObject);
begin
  // 鼠标点击时更新光标位置
  UpdateStatusBar;
end;

procedure TSynEditForm.RichEdit1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // 键盘操作后更新光标位置
  UpdateStatusBar;
end;

end.
