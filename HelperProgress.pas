unit HelperProgress;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.UITypes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Dialogs, System.SyncObjs;

type
  /// <summary>
  /// 进度条辅助类，用于显示和更新进度条
  /// </summary>
  TProgressHelper = class
  private
    FProgressBar: TProgressBar;
    FStatusLabel: TLabel;
    FTotalCount: Integer;
    FCurrentCount: Integer;
    FLock: TCriticalSection;
    FLastUpdateTime: TDateTime;
    FUpdateInterval: Integer; // 毫秒

    procedure UpdateUI(const AStatusText: string = '');
  public
    constructor Create(AProgressBar: TProgressBar; AStatusLabel: TLabel);
    destructor Destroy; override;

    /// <summary>
    /// 初始化进度条
    /// </summary>
    /// <param name="ATotalCount">总任务数</param>
    procedure Initialize(ATotalCount: Integer);

    /// <summary>
    /// 更新进度
    /// </summary>
    /// <param name="ACurrentCount">当前完成的任务数</param>
    /// <param name="AStatusText">状态文本</param>
    procedure UpdateProgress(ACurrentCount: Integer; const AStatusText: string = '');

    /// <summary>
    /// 完成进度
    /// </summary>
    /// <param name="AStatusText">状态文本</param>
    procedure Complete(const AStatusText: string = '');

    /// <summary>
    /// 设置更新间隔（毫秒）
    /// </summary>
    property UpdateInterval: Integer read FUpdateInterval write FUpdateInterval;
  end;

  /// <summary>
  /// 配置管理器，用于保存和加载配置
  /// </summary>
  TConfigManager = class
  private
    FConfigFileName: string;
    FConfig: TStringList;

    function GetValue(const Section, Name: string): string;
    procedure SetValue(const Section, Name, Value: string);
  public
    constructor Create(const AConfigFileName: string = '');
    destructor Destroy; override;

    /// <summary>
    /// 加载配置
    /// </summary>
    procedure LoadConfig;

    /// <summary>
    /// 保存配置
    /// </summary>
    procedure SaveConfig;

    /// <summary>
    /// 获取字符串值
    /// </summary>
    function GetString(const Section, Name, Default: string): string;

    /// <summary>
    /// 设置字符串值
    /// </summary>
    procedure SetString(const Section, Name, Value: string);

    /// <summary>
    /// 获取整数值
    /// </summary>
    function GetInteger(const Section, Name: string; Default: Integer): Integer;

    /// <summary>
    /// 设置整数值
    /// </summary>
    procedure SetInteger(const Section, Name: string; Value: Integer);

    /// <summary>
    /// 获取布尔值
    /// </summary>
    function GetBoolean(const Section, Name: string; Default: Boolean): Boolean;

    /// <summary>
    /// 设置布尔值
    /// </summary>
    procedure SetBoolean(const Section, Name: string; Value: Boolean);
  end;

implementation

uses
  System.IniFiles, System.IOUtils, Vcl.Dialogs;

{ TProgressHelper }

constructor TProgressHelper.Create(AProgressBar: TProgressBar; AStatusLabel: TLabel);
begin
  inherited Create;
  FProgressBar := AProgressBar;
  FStatusLabel := AStatusLabel;
  FLock := TCriticalSection.Create;
  FUpdateInterval := 100; // 默认更新间隔为100毫秒
  FLastUpdateTime := 0;
end;

destructor TProgressHelper.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TProgressHelper.Initialize(ATotalCount: Integer);
begin
  FLock.Enter;
  try
    FTotalCount := ATotalCount;
    FCurrentCount := 0;

    TThread.Synchronize(nil, procedure
    begin
      if Assigned(FProgressBar) then
      begin
        FProgressBar.Min := 0;
        FProgressBar.Max := ATotalCount;
        FProgressBar.Position := 0;
        FProgressBar.Visible := True;
      end;

      if Assigned(FStatusLabel) then
      begin
        FStatusLabel.Caption := Format('准备处理 %d 个文件...', [ATotalCount]);
        FStatusLabel.Visible := True;
      end;
    end);
  finally
    FLock.Leave;
  end;
end;

procedure TProgressHelper.UpdateProgress(ACurrentCount: Integer; const AStatusText: string);
begin
  FLock.Enter;
  try
    FCurrentCount := ACurrentCount;

    // 检查是否需要更新UI
    if MilliSecondsBetween(Now, FLastUpdateTime) >= FUpdateInterval then
    begin
      UpdateUI(AStatusText);
      FLastUpdateTime := Now;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TProgressHelper.UpdateUI(const AStatusText: string);
var
  StatusText: string;
  Percentage: Integer;
begin
  if FTotalCount > 0 then
    Percentage := Round(FCurrentCount / FTotalCount * 100)
  else
    Percentage := 0;

  StatusText := Format('处理中... %d/%d (%d%%)', [FCurrentCount, FTotalCount, Percentage]);

  TThread.Queue(TThread.CurrentThread,
    procedure
    begin
      if Assigned(FProgressBar) then
        FProgressBar.Position := FCurrentCount;

      if Assigned(FStatusLabel) then
      begin
        if AStatusText <> '' then
          FStatusLabel.Caption := AStatusText
        else
          FStatusLabel.Caption := StatusText;
      end;

      // 让UI有机会更新
      Application.ProcessMessages;
    end
  );
end;

procedure TProgressHelper.Complete(const AStatusText: string);
begin
  FLock.Enter;
  try
    FCurrentCount := FTotalCount;

    TThread.Synchronize(TThread.CurrentThread,
      procedure
      begin
        if Assigned(FProgressBar) then
        begin
          FProgressBar.Position := FProgressBar.Max;
        end;

        if Assigned(FStatusLabel) then
        begin
          if AStatusText <> '' then
            FStatusLabel.Caption := AStatusText
          else
            FStatusLabel.Caption := Format('完成! 共处理 %d 个文件', [FTotalCount]);
        end;
      end
    );
  finally
    FLock.Leave;
  end;
end;

{ TConfigManager }

constructor TConfigManager.Create(const AConfigFileName: string);
begin
  inherited Create;
  FConfig := TStringList.Create;

  if AConfigFileName = '' then
    FConfigFileName := ChangeFileExt(ParamStr(0), '.ini')
  else
    FConfigFileName := AConfigFileName;

  LoadConfig;
end;

destructor TConfigManager.Destroy;
begin
  SaveConfig;
  FConfig.Free;
  inherited;
end;

function TConfigManager.GetValue(const Section, Name: string): string;
var
  IniFile: TIniFile;
begin
  Result := '';

  if FileExists(FConfigFileName) then
  begin
    IniFile := TIniFile.Create(FConfigFileName);
    try
      Result := IniFile.ReadString(Section, Name, '');
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TConfigManager.SetValue(const Section, Name, Value: string);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    IniFile.WriteString(Section, Name, Value);
  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.LoadConfig;
begin
  if FileExists(FConfigFileName) then
  begin
    try
      FConfig.LoadFromFile(FConfigFileName);
    except
      on E: Exception do
      begin
        MessageDlg('加载配置文件时出错: ' + E.Message, mtError, [mbOK], 0);
      end;
    end;
  end;
end;

procedure TConfigManager.SaveConfig;
begin
  try
    FConfig.SaveToFile(FConfigFileName);
  except
    on E: Exception do
    begin
      MessageDlg('保存配置文件时出错: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

function TConfigManager.GetString(const Section, Name, Default: string): string;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    Result := IniFile.ReadString(Section, Name, Default);
  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.SetString(const Section, Name, Value: string);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    IniFile.WriteString(Section, Name, Value);
  finally
    IniFile.Free;
  end;
end;

function TConfigManager.GetInteger(const Section, Name: string; Default: Integer): Integer;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    Result := IniFile.ReadInteger(Section, Name, Default);
  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.SetInteger(const Section, Name: string; Value: Integer);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    IniFile.WriteInteger(Section, Name, Value);
  finally
    IniFile.Free;
  end;
end;

function TConfigManager.GetBoolean(const Section, Name: string; Default: Boolean): Boolean;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    Result := IniFile.ReadBool(Section, Name, Default);
  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.SetBoolean(const Section, Name: string; Value: Boolean);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(FConfigFileName);
  try
    IniFile.WriteBool(Section, Name, Value);
  finally
    IniFile.Free;
  end;
end;

end.
