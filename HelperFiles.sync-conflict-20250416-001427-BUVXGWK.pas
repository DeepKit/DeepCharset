unit HelperFiles;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Vcl.Dialogs, Vcl.Controls, UtilsUTF8,
  System.Math, System.StrUtils;

type
  // 文件辅助类
  TFileHelper = class
  private
    FLogCallback: TProc<string>;
    

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;
    
    // 获取文件扩展名列表
    function GetFileExtensions(const FolderPath: string): TArray<string>;
    
    // 获取指定文件夹中的文件
    function GetFilesInFolder(const FolderPath: string; const Extensions: TArray<string> = nil): TArray<string>;
    
    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
    
    // 转换文件编码
    function ConvertFile(const SourceFile, TargetFile: string; 
      TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;
      
    // 批量转换文件
    function BatchConvert(const Files: TArray<string>; 
      TargetEncoding: TEncoding; AddBOM: Boolean): Integer;
      
    // 文件路径处理
    function PathWithSeparator(const Path: string): string;
    
    // 检查路径是否存在，不存在则创建
    function EnsurePathExists(const Path: string): Boolean;
    
    // 获取用户文档路径
    function GetMyDocumentsPath: string;
  end;
  
implementation

uses
  Winapi.Windows, Winapi.ShlObj;

const
  CSIDL_PERSONAL = $0005; // My Documents

{ TFileHelper }

constructor TFileHelper.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

destructor TFileHelper.Destroy;
begin
  inherited;
end;

function TFileHelper.BatchConvert(const Files: TArray<string>; 
  TargetEncoding: TEncoding; AddBOM: Boolean): Integer;
var
  i: Integer;
begin
  Result := 0;
  
  if Length(Files) = 0 then
    Exit;
    
  for i := 0 to High(Files) do
  begin
    if ConvertFile(Files[i], Files[i], TargetEncoding, AddBOM) then
      Inc(Result);
  end;
end;

function TFileHelper.ConvertFile(const SourceFile, TargetFile: string; 
  TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;
var
  ConvResult: Boolean;
begin
  try
    // 根据目标编码选择不同的转换函数
    if TargetEncoding.CodePage = 936 then
    begin
      // 转换为GB2312/GBK
      ConvResult := ConvertFileToGB2312(SourceFile, TargetFile);
      Result := ConvResult;
      
      if ConvResult and Assigned(FLogCallback) then
        FLogCallback('成功转换到GB2312: ' + SourceFile);
    end
    else
    begin
      // 转换为UTF-8或其他编码
      ConvResult := ConvertFileToUTF8(SourceFile, TargetFile);
      Result := ConvResult;
      
      if ConvResult and Assigned(FLogCallback) then
        FLogCallback('成功转换到UTF-8: ' + SourceFile);
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换失败: ' + SourceFile + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFileHelper.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  Encoding: TEncoding;
  Stream: TFileStream;
  Buffer: TBytes;
  TextSample: string;
  GB2312Bytes: TBytes;
  ByteToRead: Integer;
  i, ValidChars, ChineseChars: Integer;
  IsUTF8: Boolean;
begin
  Result := '未知';
  HasBOM := False;
  
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取文件头部用于检测BOM和分析内容
      ByteToRead := Min(Stream.Size, 8192); // 读取更多字节用于分析
      SetLength(Buffer, ByteToRead);
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));
      
      // 先用标准方法检测BOM
      Encoding := nil;
      TEncoding.GetBufferEncoding(Buffer, Encoding);
      
      // 有BOM的情况
      HasBOM := Stream.Position > 0;
      
      if Encoding = TEncoding.UTF8 then
      begin
        if HasBOM then
          Result := 'UTF-8 BOM'
        else
          Result := 'UTF-8';
      end
      else if Encoding = TEncoding.Unicode then
        Result := 'UTF-16LE'
      else if Encoding = TEncoding.BigEndianUnicode then
        Result := 'UTF-16BE'
      else if Encoding = TEncoding.UTF7 then
        Result := 'UTF-7'
      else if Encoding = TEncoding.ASCII then
        Result := 'ASCII'
      else // 可能是ANSI、GB2312或UTF-8(无BOM)
      begin
        // 首先检查是否为UTF-8编码(无BOM)
        IsUTF8 := False;
        
        // 采用更可靠的UTF-8检测方法
        if ByteToRead > 0 then
        begin
          IsUTF8 := True; // 假设是UTF-8
          i := 0;
          while i < ByteToRead do
          begin
            // 检查单字节ASCII字符(0-127)
            if Buffer[i] < $80 then
            begin
              Inc(i);
              Continue;
            end;
            
            // 检查UTF-8多字节序列
            if (Buffer[i] and $E0) = $C0 then // 2字节序列: 110xxxxx 10xxxxxx
            begin
              if (i + 1 >= ByteToRead) or ((Buffer[i+1] and $C0) <> $80) then
              begin
                IsUTF8 := False;
                Break;
              end;
              Inc(i, 2);
            end
            else if (Buffer[i] and $F0) = $E0 then // 3字节序列: 1110xxxx 10xxxxxx 10xxxxxx
            begin
              if (i + 2 >= ByteToRead) or 
                 ((Buffer[i+1] and $C0) <> $80) or 
                 ((Buffer[i+2] and $C0) <> $80) then
              begin
                IsUTF8 := False;
                Break;
              end;
              Inc(i, 3);
            end
            else if (Buffer[i] and $F8) = $F0 then // 4字节序列: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
            begin
              if (i + 3 >= ByteToRead) or 
                 ((Buffer[i+1] and $C0) <> $80) or 
                 ((Buffer[i+2] and $C0) <> $80) or 
                 ((Buffer[i+3] and $C0) <> $80) then
              begin
                IsUTF8 := False;
                Break;
              end;
              Inc(i, 4);
            end
            else // 无效的UTF-8首字节
            begin
              IsUTF8 := False;
              Break;
            end;
          end;
          
          // 如果检测为有效的UTF-8，直接返回
          if IsUTF8 and (ByteToRead > 20) then // 确保有足够的样本量
          begin
            Result := 'UTF-8';
            Exit;
          end;
        end;
        
        // 检测GB2312/GBK中文编码 - 更加强力的检测方法
        // 首先分析文件是否符合GB2312特征
        ChineseChars := 0;
        ValidChars := 0;
        
        // 计算GB2312双字节字符的数量和规律
        i := 0;
        while i < ByteToRead - 1 do
        begin
          // 检查是否符合GB2312/GBK编码模式 - 更精确的范围
          // 第一个字节范围: 0x81-0xFE
          // 第二个字节范围: 0x40-0x7E, 0x80-0xFE
          if (i < ByteToRead - 1) and 
             (Buffer[i] >= $81) and (Buffer[i] <= $FE) and 
             (((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
              ((Buffer[i+1] >= $80) and (Buffer[i+1] <= $FE))) then
          begin
            ChineseChars := ChineseChars + 1;
            Inc(i, 2); // 跳过双字节字符
          end
          // 检查ASCII字符
          else if (Buffer[i] >= 32) and (Buffer[i] <= 126) then
          begin
            ValidChars := ValidChars + 1;
            Inc(i);
          end
          else
          begin
            Inc(i);
          end;
        end;
        
        // GB2312编码的判断逻辑 - 不同条件的组合判断
        if (ChineseChars > 5) or 
           ((ChineseChars > 0) and (ChineseChars * 5 >= ByteToRead / 40)) or
           // 文本文件中有明显的中文特征
           ((EndsText('.txt', FileName) or EndsText('.pas', FileName)) and (ChineseChars > 0))
        then
        begin
          Result := '简体中文 (GB2312)';
          Exit;
        end
        else if ValidChars > ByteToRead / 3 then
        begin
          Result := 'ANSI';
        end
        else
        begin
          Result := 'ANSI/二进制';
        end;
      end;

      // 处理特殊的二进制文件
      if EndsText('.bin', FileName) or EndsText('.exe', FileName) or
         EndsText('.dll', FileName) or EndsText('.obj', FileName) then
      begin
        Result := '二进制';
      end
      else if Result = '' then // 如果之前的检测没有结果
      begin
        Result := 'ANSI/未知';
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      // 记录文件访问错误但不抛出异常
      if Assigned(FLogCallback) then
        FLogCallback('检测编码失败: ' + FileName + ' - ' + E.Message);
      Result := '(访问被拒绝)';
      HasBOM := False;
    end;
  end;
end;

function TFileHelper.EnsurePathExists(const Path: string): Boolean;
begin
  Result := True;
  
  if not DirectoryExists(Path) then
  begin
    try
      Result := ForceDirectories(Path);
      
      if not Result and Assigned(FLogCallback) then
        FLogCallback('无法创建目录: ' + Path);
        
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('创建目录失败: ' + Path + ' - ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

function TFileHelper.GetFileExtensions(const FolderPath: string): TArray<string>;
var
  Files: TArray<string>;
  Extensions: TStringList;
  Ext: string;
  i: Integer;
begin
  Extensions := TStringList.Create;
  try
    Extensions.Sorted := True;
    Extensions.Duplicates := dupIgnore;
    
    Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);
    
    for i := 0 to High(Files) do
    begin
      Ext := ExtractFileExt(Files[i]);
      if Ext <> '' then
        Extensions.Add(Ext);
    end;
    
    SetLength(Result, Extensions.Count);
    for i := 0 to Extensions.Count - 1 do
      Result[i] := Extensions[i];
      
  finally
    Extensions.Free;
  end;
end;

function TFileHelper.GetFilesInFolder(const FolderPath: string; const Extensions: TArray<string>): TArray<string>;
var
  AllFiles: TArray<string>;
  FilteredFiles: TStringList;
  i, j: Integer;
  Ext: string;
  MatchFound: Boolean;
begin
  SetLength(Result, 0);
  
  if not DirectoryExists(FolderPath) then
    Exit;
    
  AllFiles := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);
  
  // 如果没有指定扩展名过滤器，返回所有文件
  if (Length(Extensions) = 0) or (Extensions = nil) then
  begin
    Result := AllFiles;
    Exit;
  end;
  
  // 根据扩展名过滤
  FilteredFiles := TStringList.Create;
  try
    for i := 0 to High(AllFiles) do
    begin
      Ext := ExtractFileExt(AllFiles[i]);
      MatchFound := False;
      
      for j := 0 to High(Extensions) do
      begin
        if SameText(Ext, Extensions[j]) then
        begin
          MatchFound := True;
          Break;
        end;
      end;
      
      if MatchFound then
        FilteredFiles.Add(AllFiles[i]);
    end;
    
    SetLength(Result, FilteredFiles.Count);
    for i := 0 to FilteredFiles.Count - 1 do
      Result[i] := FilteredFiles[i];
      
  finally
    FilteredFiles.Free;
  end;
end;

function TFileHelper.GetMyDocumentsPath: string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, Path) = S_OK then
    Result := Path
  else
    Result := '';
end;

function TFileHelper.PathWithSeparator(const Path: string): string;
begin
  Result := IncludeTrailingPathDelimiter(Path);
end;

end. 
