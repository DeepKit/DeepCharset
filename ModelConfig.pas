unit ModelConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows, Winapi.Messages;

type
  // 应用程序配置模型
  TAppConfig = class
  private
    FLastDirectory: string;
    FDefaultEncoding: Integer;
    FAddBOM: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 保存最后使用的目录
    procedure SetLastDirectory(const Directory: string);
    
    // 配置属性
    property LastDirectory: string read FLastDirectory write SetLastDirectory;
    property DefaultEncoding: Integer read FDefaultEncoding write FDefaultEncoding;
    property AddBOM: Boolean read FAddBOM write FAddBOM;
  end;
  
implementation

{ TAppConfig }

constructor TAppConfig.Create;
begin
  inherited Create;
  // 设置默认值，不再读取ini文件
  FLastDirectory := '';
  FDefaultEncoding := 65001; // UTF-8
  FAddBOM := True; // 总是添加BOM
end;

destructor TAppConfig.Destroy;
begin
  // 不再保存配置到ini文件
  inherited;
end;

procedure TAppConfig.SetLastDirectory(const Directory: string);
begin
  // 简单赋值，不再保存到ini文件
  FLastDirectory := Directory;
end;

end. 