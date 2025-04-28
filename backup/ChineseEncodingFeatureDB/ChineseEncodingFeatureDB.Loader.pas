unit ChineseEncodingFeatureDB.Loader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  ChineseEncodingFeatureDB.Types, ChineseEncodingFeatureDB.Storage,
  ChineseEncodingFeatureDB.Serialization, ChineseEncodingFeatureDB.Index;

type
  // 加载器状态
  TLoaderState = (
    lsIdle,       // 空闲状态
    lsLoading,    // 正在加载
    lsVerifying,  // 正在验证
    lsMerging,    // 正在合并
    lsCompleted,  // 完成
    lsError       // 错误
  );

  // 加载结果
  TLoadResult = record
    Success: Boolean;
    ErrorMessage: string;
    LoadedItems: Integer;
    SkippedItems: Integer;
    InvalidItems: Integer;
    Duration: Cardinal; // 加载耗时(毫秒)
  end;

  // 加载进度事件
  TLoadProgressEvent = procedure(Sender: TObject; Current, Total: Integer; State: TLoaderState) of object;
  
  // 加载完成事件
  TLoadCompletedEvent = procedure(Sender: TObject; const Result: TLoadResult) of object;

  // 特征数据加载接口
  IFeatureDataLoader = interface
    ['{E1F2D3C4-B5A6-7890-12AB-CDEF01234567}']
    // 加载内置特征数据
    function LoadBuiltInData: TLoadResult;
    
    // 从文件加载特征数据
    function LoadFromFile(const AFileName: string): TLoadResult;
    
    // 从目录加载特征数据
    function LoadFromDirectory(const ADirectory: string; ARecursive: Boolean = False): TLoadResult;
    
    // 从流加载特征数据
    function LoadFromStream(AStream: TStream): TLoadResult;
    
    // 从字符串加载特征数据
    function LoadFromString(const AData: string): TLoadResult;
    
    // 动态加载特征数据
    function LoadDynamicData(AData: TFeatureData): TLoadResult;
    
    // 获取加载器状态
    function GetState: TLoaderState;
    
    // 取消加载操作
    procedure Cancel;
    
    // 验证特征数据
    function ValidateData(AData: TFeatureData): Boolean;
    
    // 设置进度事件
    procedure SetOnProgress(AEvent: TLoadProgressEvent);
    
    // 设置完成事件
    procedure SetOnCompleted(AEvent: TLoadCompletedEvent);
  end;

  // 基本特征数据加载器
  TBaseFeatureDataLoader = class(TInterfacedObject, IFeatureDataLoader)
  private
    FStorage: IFeatureDataStorage;
    FSerializer: IFeatureDataSerializer;
    FState: TLoaderState;
    FCancelled: Boolean;
    FOnProgress: TLoadProgressEvent;
    FOnCompleted: TLoadCompletedEvent;
    
    // 触发进度事件
    procedure TriggerProgressEvent(Current, Total: Integer; State: TLoaderState);
    
    // 触发完成事件
    procedure TriggerCompletedEvent(const Result: TLoadResult);
    
    // 从JSON数组加载数据
    function LoadFromJsonArray(JsonArray: TJSONArray): TLoadResult;
  protected
    // 加载内置的GB18030/GBK/GB2312特征数据
    function LoadBuiltInGBData: TLoadResult;
    
    // 加载内置的Big5/Big5-HKSCS特征数据
    function LoadBuiltInBig5Data: TLoadResult;
  public
    constructor Create(AStorage: IFeatureDataStorage; ASerializer: IFeatureDataSerializer = nil);
    destructor Destroy; override;
    
    // 实现IFeatureDataLoader接口
    function LoadBuiltInData: TLoadResult;
    function LoadFromFile(const AFileName: string): TLoadResult;
    function LoadFromDirectory(const ADirectory: string; ARecursive: Boolean = False): TLoadResult;
    function LoadFromStream(AStream: TStream): TLoadResult;
    function LoadFromString(const AData: string): TLoadResult;
    function LoadDynamicData(AData: TFeatureData): TLoadResult;
    function GetState: TLoaderState;
    procedure Cancel;
    function ValidateData(AData: TFeatureData): Boolean;
    procedure SetOnProgress(AEvent: TLoadProgressEvent);
    procedure SetOnCompleted(AEvent: TLoadCompletedEvent);
  end;

  // 异步特征数据加载器
  TAsyncFeatureDataLoader = class(TInterfacedObject, IFeatureDataLoader)
  private
    FBaseLoader: IFeatureDataLoader;
    FOnProgress: TLoadProgressEvent;
    FOnCompleted: TLoadCompletedEvent;
    
    // 进度事件中转
    procedure HandleProgress(Sender: TObject; Current, Total: Integer; State: TLoaderState);
    
    // 完成事件中转
    procedure HandleCompleted(Sender: TObject; const Result: TLoadResult);
  public
    constructor Create(ABaseLoader: IFeatureDataLoader);
    destructor Destroy; override;
    
    // 实现IFeatureDataLoader接口
    function LoadBuiltInData: TLoadResult;
    function LoadFromFile(const AFileName: string): TLoadResult;
    function LoadFromDirectory(const ADirectory: string; ARecursive: Boolean = False): TLoadResult;
    function LoadFromStream(AStream: TStream): TLoadResult;
    function LoadFromString(const AData: string): TLoadResult;
    function LoadDynamicData(AData: TFeatureData): TLoadResult;
    function GetState: TLoaderState;
    procedure Cancel;
    function ValidateData(AData: TFeatureData): Boolean;
    procedure SetOnProgress(AEvent: TLoadProgressEvent);
    procedure SetOnCompleted(AEvent: TLoadCompletedEvent);
  end;

  // 加载器工厂
  TFeatureDataLoaderFactory = class
  public
    // 创建基本加载器
    class function CreateBaseLoader(AStorage: IFeatureDataStorage): IFeatureDataLoader;
    
    // 创建异步加载器
    class function CreateAsyncLoader(ABaseLoader: IFeatureDataLoader): IFeatureDataLoader;
  end;

implementation

uses
  System.IOUtils, System.Threading;

{ TBaseFeatureDataLoader }

constructor TBaseFeatureDataLoader.Create(AStorage: IFeatureDataStorage; ASerializer: IFeatureDataSerializer);
begin
  inherited Create;
  FStorage := AStorage;
  
  if ASerializer = nil then
    FSerializer := TFeatureDataSerializerFactory.CreateJSONSerializer
  else
    FSerializer := ASerializer;
    
  FState := lsIdle;
  FCancelled := False;
end;

destructor TBaseFeatureDataLoader.Destroy;
begin
  inherited;
end;

procedure TBaseFeatureDataLoader.TriggerProgressEvent(Current, Total: Integer; State: TLoaderState);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, Current, Total, State);
end;

procedure TBaseFeatureDataLoader.TriggerCompletedEvent(const Result: TLoadResult);
begin
  if Assigned(FOnCompleted) then
    FOnCompleted(Self, Result);
end;

function TBaseFeatureDataLoader.LoadBuiltInData: TLoadResult;
var
  GBResult, Big5Result: TLoadResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 加载GB系列数据
    GBResult := LoadBuiltInGBData;
    if FCancelled then
    begin
      Result.ErrorMessage := 'Operation cancelled';
      Exit;
    end;
    
    TriggerProgressEvent(50, 100, FState);
    
    // 加载Big5系列数据
    Big5Result := LoadBuiltInBig5Data;
    if FCancelled then
    begin
      Result.ErrorMessage := 'Operation cancelled';
      Exit;
    end;
    
    TriggerProgressEvent(100, 100, FState);
    
    // 合并结果
    Result.Success := GBResult.Success or Big5Result.Success;
    if not GBResult.Success then
      Result.ErrorMessage := GBResult.ErrorMessage
    else if not Big5Result.Success then
      Result.ErrorMessage := Big5Result.ErrorMessage;
      
    Result.LoadedItems := GBResult.LoadedItems + Big5Result.LoadedItems;
    Result.SkippedItems := GBResult.SkippedItems + Big5Result.SkippedItems;
    Result.InvalidItems := GBResult.InvalidItems + Big5Result.InvalidItems;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.LoadBuiltInGBData: TLoadResult;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  
  // 这里实现GB18030/GBK/GB2312内置特征数据的加载
  // 通常是硬编码的数据，或者从资源中加载
  
  // 示例：加载GB18030字节频率数据
  var ByteFreqData := TByteFrequencyFeatureData.Create(cetGB18030);
  ByteFreqData.Description := 'GB18030字节频率数据';
  ByteFreqData.LastUpdated := Now;
  
  // 设置一些示例数据
  for var i := 0 to 255 do
    ByteFreqData.Data.ByteValues[i] := 0.0; // 实际应用中使用真实数据
    
  // 一些高频字节的例子
  ByteFreqData.Data.ByteValues[$B5] := 0.0234; // 仅示例
  ByteFreqData.Data.ByteValues[$C4] := 0.0189;
  ByteFreqData.Data.ByteValues[$D2] := 0.0176;
  
  // 保存到存储
  if FStorage.SaveFeatureData(ByteFreqData) then
    Inc(Result.LoadedItems)
  else
    Inc(Result.InvalidItems);
  
  // 其他内置GB系列数据...
  // 在实际实现中，应该添加更多的内置数据
  
  // 注意：示例代码中，我们只创建了一个示例数据项
  // 真实实现中，应该包含完整的内置数据
end;

function TBaseFeatureDataLoader.LoadBuiltInBig5Data: TLoadResult;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  
  // 这里实现Big5/Big5-HKSCS内置特征数据的加载
  // 通常是硬编码的数据，或者从资源中加载
  
  // 示例：加载Big5字节频率数据
  var ByteFreqData := TByteFrequencyFeatureData.Create(cetBig5);
  ByteFreqData.Description := 'Big5字节频率数据';
  ByteFreqData.LastUpdated := Now;
  
  // 设置一些示例数据
  for var i := 0 to 255 do
    ByteFreqData.Data.ByteValues[i] := 0.0; // 实际应用中使用真实数据
    
  // 一些高频字节的例子
  ByteFreqData.Data.ByteValues[$A4] := 0.0215; // 仅示例
  ByteFreqData.Data.ByteValues[$B0] := 0.0178;
  ByteFreqData.Data.ByteValues[$C5] := 0.0156;
  
  // 保存到存储
  if FStorage.SaveFeatureData(ByteFreqData) then
    Inc(Result.LoadedItems)
  else
    Inc(Result.InvalidItems);
  
  // 其他内置Big5系列数据...
  // 在实际实现中，应该添加更多的内置数据
  
  // 注意：示例代码中，我们只创建了一个示例数据项
  // 真实实现中，应该包含完整的内置数据
end;

function TBaseFeatureDataLoader.LoadFromFile(const AFileName: string): TLoadResult;
var
  FileStream: TFileStream;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  if not FileExists(AFileName) then
  begin
    Result.ErrorMessage := Format('File %s does not exist', [AFileName]);
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 打开文件
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      // 从文件加载特征数据
      Result := LoadFromStream(FileStream);
    finally
      FileStream.Free;
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.LoadFromDirectory(const ADirectory: string; ARecursive: Boolean = False): TLoadResult;
var
  Files: TArray<string>;
  FileResult: TLoadResult;
  SearchOption: TSearchOption;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  if not DirectoryExists(ADirectory) then
  begin
    Result.ErrorMessage := Format('Directory %s does not exist', [ADirectory]);
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 获取目录中的所有特征数据文件
    if ARecursive then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;
      
    Files := TDirectory.GetFiles(ADirectory, '*.json', SearchOption);
    
    // 加载每个文件
    for var i := 0 to Length(Files) - 1 do
    begin
      if FCancelled then
      begin
        Result.ErrorMessage := 'Operation cancelled';
        Break;
      end;
      
      TriggerProgressEvent(i, Length(Files), FState);
      
      // 加载文件
      FileResult := LoadFromFile(Files[i]);
      
      // 累加结果
      Result.LoadedItems := Result.LoadedItems + FileResult.LoadedItems;
      Result.SkippedItems := Result.SkippedItems + FileResult.SkippedItems;
      Result.InvalidItems := Result.InvalidItems + FileResult.InvalidItems;
    end;
    
    // 设置成功标志
    Result.Success := (Result.LoadedItems > 0);
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.LoadFromStream(AStream: TStream): TLoadResult;
var
  DataString: string;
  StringStream: TStringStream;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  if AStream = nil then
  begin
    Result.ErrorMessage := 'Stream is nil';
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 将流内容读取为字符串
    StringStream := TStringStream.Create('', TEncoding.UTF8);
    try
      AStream.Position := 0;
      StringStream.CopyFrom(AStream, AStream.Size);
      DataString := StringStream.DataString;
    finally
      StringStream.Free;
    end;
    
    // 从字符串加载特征数据
    Result := LoadFromString(DataString);
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.LoadFromString(const AData: string): TLoadResult;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  JsonArray: TJSONArray;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  if AData.IsEmpty then
  begin
    Result.ErrorMessage := 'Data is empty';
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 解析JSON
    JsonValue := TJSONObject.ParseJSONValue(AData);
    if JsonValue = nil then
    begin
      Result.ErrorMessage := 'Invalid JSON data';
      Exit;
    end;
    
    try
      // 检查是单个对象还是数组
      if JsonValue is TJSONObject then
      begin
        JsonObject := JsonValue as TJSONObject;
        
        // 反序列化特征数据
        var FeatureData := FSerializer.Deserialize(JsonObject.ToJSON);
        if FeatureData <> nil then
        begin
          try
            // 验证数据
            FState := lsVerifying;
            TriggerProgressEvent(0, 1, FState);
            
            if ValidateData(FeatureData) then
            begin
              // 保存到存储
              if FStorage.SaveFeatureData(FeatureData) then
                Inc(Result.LoadedItems)
              else
                Inc(Result.SkippedItems);
            end
            else
              Inc(Result.InvalidItems);
          finally
            FeatureData.Free;
          end;
        end
        else
          Inc(Result.InvalidItems);
      end
      else if JsonValue is TJSONArray then
      begin
        JsonArray := JsonValue as TJSONArray;
        Result := LoadFromJsonArray(JsonArray);
      end
      else
      begin
        Result.ErrorMessage := 'Unsupported JSON format';
      end;
    finally
      JsonValue.Free;
    end;
    
    // 设置成功标志
    Result.Success := (Result.LoadedItems > 0);
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.LoadFromJsonArray(JsonArray: TJSONArray): TLoadResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  
  if JsonArray = nil then
    Exit;
    
  // 处理JSON数组中的每个项
  for var i := 0 to JsonArray.Count - 1 do
  begin
    if FCancelled then
      Break;
      
    TriggerProgressEvent(i, JsonArray.Count, FState);
    
    var JsonItem := JsonArray.Items[i];
    if not (JsonItem is TJSONObject) then
    begin
      Inc(Result.InvalidItems);
      Continue;
    end;
    
    // 反序列化特征数据
    var FeatureData := FSerializer.Deserialize(JsonItem.ToJSON);
    if FeatureData <> nil then
    begin
      try
        // 验证数据
        FState := lsVerifying;
        TriggerProgressEvent(i, JsonArray.Count, FState);
        
        if ValidateData(FeatureData) then
        begin
          // 保存到存储
          if FStorage.SaveFeatureData(FeatureData) then
            Inc(Result.LoadedItems)
          else
            Inc(Result.SkippedItems);
        end
        else
          Inc(Result.InvalidItems);
      finally
        FeatureData.Free;
      end;
    end
    else
      Inc(Result.InvalidItems);
      
    FState := lsLoading;
  end;
  
  // 设置成功标志
  Result.Success := (Result.LoadedItems > 0);
end;

function TBaseFeatureDataLoader.LoadDynamicData(AData: TFeatureData): TLoadResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  if FCancelled then
  begin
    Result.ErrorMessage := 'Operation cancelled';
    Exit;
  end;
  
  if AData = nil then
  begin
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  FState := lsLoading;
  TriggerProgressEvent(0, 3, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 验证数据
    FState := lsVerifying;
    TriggerProgressEvent(1, 3, FState);
    
    var IsValid := ValidateData(AData);
    
    // 保存数据
    FState := lsMerging;
    TriggerProgressEvent(2, 3, FState);
    
    if IsValid then
    begin
      // 保存到存储
      if FStorage.SaveFeatureData(AData) then
      begin
        Inc(Result.LoadedItems);
        Result.Success := True;
      end
      else
        Inc(Result.SkippedItems);
    end
    else
    begin
      Inc(Result.InvalidItems);
      Result.ErrorMessage := 'Invalid feature data';
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := lsCompleted;
    TriggerProgressEvent(3, 3, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := lsError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataLoader.GetState: TLoaderState;
begin
  Result := FState;
end;

procedure TBaseFeatureDataLoader.Cancel;
begin
  FCancelled := True;
end;

function TBaseFeatureDataLoader.ValidateData(AData: TFeatureData): Boolean;
begin
  // 基本验证
  Result := (AData <> nil);
  
  if not Result then
    Exit;
    
  // 检查编码类型是否有效
  if AData.Encoding = cetUnknown then
    Exit(False);
    
  // 根据数据类型进行特定验证
  case AData.DataType of
    fdtByteFrequency:
      begin
        // 验证字节频率数据
        if not (AData is TByteFrequencyFeatureData) then
          Exit(False);
          
        // 可以添加更多字节频率数据的验证逻辑
      end;
      
    fdtCharFrequency:
      begin
        // 验证字符频率数据
        if not (AData is TCharFrequencyFeatureData) then
          Exit(False);
          
        var CharFreqData := AData as TCharFrequencyFeatureData;
        // 检查字符是否有效
        if CharFreqData.Data.Character.IsEmpty then
          Exit(False);
          
        // 可以添加更多字符频率数据的验证逻辑
      end;
      
    fdtBytePair:
      begin
        // 验证字节对数据
        if not (AData is TBytePairFreatureData) then
          Exit(False);
          
        // 可以添加更多字节对数据的验证逻辑
      end;
      
    fdtRegion:
      begin
        // 验证区域数据
        if not (AData is TRegionFeatureData) then
          Exit(False);
          
        var RegionData := AData as TRegionFeatureData;
        // 检查区域范围是否有效
        if RegionData.Data.StartRange > RegionData.Data.EndRange then
          Exit(False);
          
        // 可以添加更多区域数据的验证逻辑
      end;
      
    fdtSpecialChar:
      begin
        // 验证特殊字符数据
        if not (AData is TSpecialCharFeatureData) then
          Exit(False);
          
        var SpecialCharData := AData as TSpecialCharFeatureData;
        // 检查字符是否有效
        if SpecialCharData.Data.Character.IsEmpty then
          Exit(False);
          
        // 可以添加更多特殊字符数据的验证逻辑
      end;
      
    fdtLanguageFeature:
      begin
        // 验证语言特征数据
        if not (AData is TLanguageFeatureFeatureData) then
          Exit(False);
          
        var LangFeatureData := AData as TLanguageFeatureFeatureData;
        // 检查内容是否有效
        if LangFeatureData.Data.Content.IsEmpty then
          Exit(False);
          
        // 可以添加更多语言特征数据的验证逻辑
      end;
      
    else
      begin
        // 未知的数据类型
        Exit(False);
      end;
  end;
end;

procedure TBaseFeatureDataLoader.SetOnProgress(AEvent: TLoadProgressEvent);
begin
  FOnProgress := AEvent;
end;

procedure TBaseFeatureDataLoader.SetOnCompleted(AEvent: TLoadCompletedEvent);
begin
  FOnCompleted := AEvent;
end;

{ TAsyncFeatureDataLoader }

constructor TAsyncFeatureDataLoader.Create(ABaseLoader: IFeatureDataLoader);
begin
  inherited Create;
  FBaseLoader := ABaseLoader;
  
  // 设置事件处理
  FBaseLoader.SetOnProgress(HandleProgress);
  FBaseLoader.SetOnCompleted(HandleCompleted);
end;

destructor TAsyncFeatureDataLoader.Destroy;
begin
  inherited;
end;

procedure TAsyncFeatureDataLoader.HandleProgress(Sender: TObject; Current, Total: Integer; State: TLoaderState);
begin
  if Assigned(FOnProgress) then
    TThread.Queue(nil, procedure
      begin
        FOnProgress(Self, Current, Total, State);
      end);
end;

procedure TAsyncFeatureDataLoader.HandleCompleted(Sender: TObject; const Result: TLoadResult);
begin
  if Assigned(FOnCompleted) then
    TThread.Queue(nil, procedure
      begin
        FOnCompleted(Self, Result);
      end);
end;

function TAsyncFeatureDataLoader.LoadBuiltInData: TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadBuiltInData;
    end);
end;

function TAsyncFeatureDataLoader.LoadFromFile(const AFileName: string): TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadFromFile(AFileName);
    end);
end;

function TAsyncFeatureDataLoader.LoadFromDirectory(const ADirectory: string; ARecursive: Boolean): TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadFromDirectory(ADirectory, ARecursive);
    end);
end;

function TAsyncFeatureDataLoader.LoadFromStream(AStream: TStream): TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadFromStream(AStream);
    end);
end;

function TAsyncFeatureDataLoader.LoadFromString(const AData: string): TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadFromString(AData);
    end);
end;

function TAsyncFeatureDataLoader.LoadDynamicData(AData: TFeatureData): TLoadResult;
begin
  // 初始化异步任务
  Result.Success := False;
  Result.ErrorMessage := 'Async operation started';
  Result.LoadedItems := 0;
  Result.SkippedItems := 0;
  Result.InvalidItems := 0;
  Result.Duration := 0;
  
  // 在后台线程中执行加载
  TTask.Run(procedure
    begin
      FBaseLoader.LoadDynamicData(AData);
    end);
end;

function TAsyncFeatureDataLoader.GetState: TLoaderState;
begin
  Result := FBaseLoader.GetState;
end;

procedure TAsyncFeatureDataLoader.Cancel;
begin
  FBaseLoader.Cancel;
end;

function TAsyncFeatureDataLoader.ValidateData(AData: TFeatureData): Boolean;
begin
  Result := FBaseLoader.ValidateData(AData);
end;

procedure TAsyncFeatureDataLoader.SetOnProgress(AEvent: TLoadProgressEvent);
begin
  FOnProgress := AEvent;
end;

procedure TAsyncFeatureDataLoader.SetOnCompleted(AEvent: TLoadCompletedEvent);
begin
  FOnCompleted := AEvent;
end;

{ TFeatureDataLoaderFactory }

class function TFeatureDataLoaderFactory.CreateBaseLoader(AStorage: IFeatureDataStorage): IFeatureDataLoader;
begin
  Result := TBaseFeatureDataLoader.Create(AStorage);
end;

class function TFeatureDataLoaderFactory.CreateAsyncLoader(ABaseLoader: IFeatureDataLoader): IFeatureDataLoader;
begin
  Result := TAsyncFeatureDataLoader.Create(ABaseLoader);
end;

end. 