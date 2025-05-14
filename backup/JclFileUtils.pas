unit JclFileUtils;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

// 检查文件是否存在
function FileExists(const FileName: string): Boolean;

// 查找文件列表
procedure BuildFileList(const Path: string; Attr: Integer; var Files: TStringList; SubDirectories: Boolean = True);

implementation

// 检查文件是否存在
function FileExists(const FileName: string): Boolean;
begin
  Result := System.SysUtils.FileExists(FileName);
end;

// 查找文件列表
procedure BuildFileList(const Path: string; Attr: Integer; var Files: TStringList; SubDirectories: Boolean = True);
var
  SearchOption: TSearchOption;
  Directory, FileMask: string;
  FoundFiles: TArray<string>;
  i: Integer;
begin
  if Files = nil then
    Exit;
    
  // 清空文件列表
  Files.Clear;
  
  // 分离目录和文件掩码
  Directory := ExtractFilePath(Path);
  FileMask := ExtractFileName(Path);
  
  // 如果目录为空，则使用当前目录
  if Directory = '' then
    Directory := './';
    
  // 设置是否搜索子目录
  if SubDirectories then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
    
  try
    // 使用TDirectory查找文件
    FoundFiles := TDirectory.GetFiles(Directory, FileMask, SearchOption);
    
    // 添加到结果列表
    for i := 0 to Length(FoundFiles) - 1 do
    begin
      Files.Add(FoundFiles[i]);
    end;
  except
    on E: Exception do
    begin
      // 处理可能的异常
      // 文件访问权限问题等
    end;
  end;
end;

end. 