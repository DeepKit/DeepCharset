unit ChineseEncodingFeatureDB.Updater;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  ChineseEncodingFeatureDB.Types, ChineseEncodingFeatureDB.Storage,
  ChineseEncodingFeatureDB.Serialization, ChineseEncodingFeatureDB.Index;

type
  // 特征数据更新状态
  TUpdaterState = (
    usIdle,        // 空闲状态
    usUpdating,    // 正在更新
    usCompleted,   // 完成
    usError        // 错误
  );

  // 更新结果
  TUpdateResult = record
    Success: Boolean;
    ErrorMessage: string;
    UpdatedItems: Integer;
    SkippedItems: Integer;
    Duration: Cardinal; // 更新耗时(毫秒)
  end;

  // 更新进度事件
  TUpdateProgressEvent = procedure(Sender: TObject; Current, Total: Integer; State: TUpdaterState) of object;
  
  // 更新完成事件
  TUpdateCompletedEvent = procedure(Sender: TObject; const Result: TUpdateResult) of object;

  // 特征数据更新接口
  IFeatureDataUpdater = interface
    ['{D1C2B3A4-9876-5432-10FE-DCBA09876543}']
    // 添加特征数据
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    
    // 修改特征数据
    function ModifyFeatureData(AData: TFeatureData): TUpdateResult;
    
    // 删除特征数据
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    
    // 导出特征数据
    function ExportFeatureData(const AFileName: string; 
      AEncoding: TChineseEncodingType = cetUnknown; 
      ADataType: TFeatureDataType = fdtOther): TUpdateResult;
    
    // 导入特征数据
    function ImportFeatureData(const AFileName: string): TUpdateResult;
    
    // 批量更新特征数据
    function BatchUpdate(ADataList: TObjectList<TFeatureData>): TUpdateResult;
    
    // 获取更新器状态
    function GetState: TUpdaterState;
    
    // 设置进度事件
    procedure SetOnProgress(AEvent: TUpdateProgressEvent);
    
    // 设置完成事件
    procedure SetOnCompleted(AEvent: TUpdateCompletedEvent);
  end;

  // 基本特征数据更新器
  TBaseFeatureDataUpdater = class(TInterfacedObject, IFeatureDataUpdater)
  private
    FStorage: IFeatureDataStorage;
    FSerializer: IFeatureDataSerializer;
    FState: TUpdaterState;
    FOnProgress: TUpdateProgressEvent;
    FOnCompleted: TUpdateCompletedEvent;
    
    // 触发进度事件
    procedure TriggerProgressEvent(Current, Total: Integer; State: TUpdaterState);
    
    // 触发完成事件
    procedure TriggerCompletedEvent(const Result: TUpdateResult);
  public
    constructor Create(AStorage: IFeatureDataStorage; ASerializer: IFeatureDataSerializer = nil);
    destructor Destroy; override;
    
    // 实现IFeatureDataUpdater接口
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    function ModifyFeatureData(AData: TFeatureData): TUpdateResult;
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    function ExportFeatureData(const AFileName: string; AEncoding: TChineseEncodingType = cetUnknown; ADataType: TFeatureDataType = fdtOther): TUpdateResult;
    function ImportFeatureData(const AFileName: string): TUpdateResult;
    function BatchUpdate(ADataList: TObjectList<TFeatureData>): TUpdateResult;
    function GetState: TUpdaterState;
    procedure SetOnProgress(AEvent: TUpdateProgressEvent);
    procedure SetOnCompleted(AEvent: TUpdateCompletedEvent);
  end;

  // 特征数据更新器工厂
  TFeatureDataUpdaterFactory = class
  public
    // 创建基本更新器
    class function CreateUpdater(AStorage: IFeatureDataStorage): IFeatureDataUpdater;
  end;

implementation

uses
  System.IOUtils, System.Threading;

{ TBaseFeatureDataUpdater }

constructor TBaseFeatureDataUpdater.Create(AStorage: IFeatureDataStorage; ASerializer: IFeatureDataSerializer);
begin
  inherited Create;
  FStorage := AStorage;
  
  if ASerializer = nil then
    FSerializer := TFeatureDataSerializerFactory.CreateJSONSerializer
  else
    FSerializer := ASerializer;
    
  FState := usIdle;
end;

destructor TBaseFeatureDataUpdater.Destroy;
begin
  inherited;
end;

procedure TBaseFeatureDataUpdater.TriggerProgressEvent(Current, Total: Integer; State: TUpdaterState);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, Current, Total, State);
end;

procedure TBaseFeatureDataUpdater.TriggerCompletedEvent(const Result: TUpdateResult);
begin
  if Assigned(FOnCompleted) then
    FOnCompleted(Self, Result);
end;

function TBaseFeatureDataUpdater.AddFeatureData(AData: TFeatureData): TUpdateResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if AData = nil then
  begin
    Result.ErrorMessage := '数据为空';
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, 1, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 设置更新时间
    AData.LastUpdated := Now;
    
    // 保存到存储
    if FStorage.SaveFeatureData(AData) then
    begin
      Inc(Result.UpdatedItems);
      Result.Success := True;
    end
    else
    begin
      Inc(Result.SkippedItems);
      Result.ErrorMessage := '保存数据失败';
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
    TriggerProgressEvent(1, 1, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.ModifyFeatureData(AData: TFeatureData): TUpdateResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if AData = nil then
  begin
    Result.ErrorMessage := '数据为空';
    Exit;
  end;
  
  if AData.ID <= 0 then
  begin
    Result.ErrorMessage := '无效的数据ID';
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, 1, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 检查数据是否存在
    if not FStorage.FeatureDataExists(AData.ID) then
    begin
      Inc(Result.SkippedItems);
      Result.ErrorMessage := Format('ID为%d的数据不存在', [AData.ID]);
      Exit;
    end;
    
    // 设置更新时间
    AData.LastUpdated := Now;
    
    // 保存到存储
    if FStorage.SaveFeatureData(AData) then
    begin
      Inc(Result.UpdatedItems);
      Result.Success := True;
    end
    else
    begin
      Inc(Result.SkippedItems);
      Result.ErrorMessage := '保存数据失败';
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
    TriggerProgressEvent(1, 1, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.DeleteFeatureData(AID: Integer): TUpdateResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if AID <= 0 then
  begin
    Result.ErrorMessage := '无效的数据ID';
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, 1, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 检查数据是否存在
    if not FStorage.FeatureDataExists(AID) then
    begin
      Inc(Result.SkippedItems);
      Result.ErrorMessage := Format('ID为%d的数据不存在', [AID]);
      Exit;
    end;
    
    // 从存储中删除
    if FStorage.DeleteFeatureData(AID) then
    begin
      Inc(Result.UpdatedItems);
      Result.Success := True;
    end
    else
    begin
      Inc(Result.SkippedItems);
      Result.ErrorMessage := '删除数据失败';
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
    TriggerProgressEvent(1, 1, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.ExportFeatureData(const AFileName: string; AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TUpdateResult;
var
  DataCollection: TFeatureDataCollection;
  JsonArray: TJSONArray;
  JsonStr: string;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if AFileName = '' then
  begin
    Result.ErrorMessage := '文件名为空';
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 查询要导出的数据
    if (AEncoding <> cetUnknown) and (ADataType <> fdtOther) then
      DataCollection := FStorage.QueryFeatureData(AEncoding, ADataType)
    else if AEncoding <> cetUnknown then
    begin
      // 导出指定编码的所有数据类型
      DataCollection := TFeatureDataCollection.Create(AEncoding, fdtOther);
      try
        for var DataType := Low(TFeatureDataType) to High(TFeatureDataType) do
        begin
          var Collection := FStorage.QueryFeatureData(AEncoding, DataType);
          try
            if Collection <> nil then
            begin
              for var i := 0 to Collection.Count - 1 do
                DataCollection.Add(Collection.GetItem(i));
            end;
          finally
            Collection.Free;
          end;
        end;
      except
        DataCollection.Free;
        raise;
      end;
    end
    else if ADataType <> fdtOther then
    begin
      // 导出指定数据类型的所有编码
      DataCollection := TFeatureDataCollection.Create(cetUnknown, ADataType);
      try
        for var EncodingType := Low(TChineseEncodingType) to High(TChineseEncodingType) do
        begin
          var Collection := FStorage.QueryFeatureData(EncodingType, ADataType);
          try
            if Collection <> nil then
            begin
              for var i := 0 to Collection.Count - 1 do
                DataCollection.Add(Collection.GetItem(i));
            end;
          finally
            Collection.Free;
          end;
        end;
      except
        DataCollection.Free;
        raise;
      end;
    end
    else
    begin
      // 导出所有数据
      DataCollection := TFeatureDataCollection.Create(cetUnknown, fdtOther);
      try
        var IDs := FStorage.GetFeatureDataIDs;
        for var i := 0 to Length(IDs) - 1 do
        begin
          var Data := FStorage.LoadFeatureData(IDs[i]);
          if Data <> nil then
            DataCollection.Add(Data);
            
          TriggerProgressEvent(i, Length(IDs), FState);
        end;
      except
        DataCollection.Free;
        raise;
      end;
    end;
    
    try
      // 序列化为JSON数组
      JsonArray := TJSONArray.Create;
      try
        for var i := 0 to DataCollection.Count - 1 do
        begin
          var Data := DataCollection.GetItem(i);
          var JsonStr := FSerializer.Serialize(Data);
          
          if JsonStr <> '' then
          begin
            var JsonValue := TJSONObject.ParseJSONValue(JsonStr);
            if JsonValue <> nil then
            begin
              JsonArray.AddElement(JsonValue);
              Inc(Result.UpdatedItems);
            end
            else
              Inc(Result.SkippedItems);
          end
          else
            Inc(Result.SkippedItems);
            
          TriggerProgressEvent(i, DataCollection.Count, FState);
        end;
        
        // 写入文件
        JsonStr := JsonArray.ToJSON;
        TFile.WriteAllText(AFileName, JsonStr, TEncoding.UTF8);
        
        Result.Success := True;
      finally
        JsonArray.Free;
      end;
    finally
      DataCollection.Free;
    end;
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
    TriggerProgressEvent(100, 100, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.ImportFeatureData(const AFileName: string): TUpdateResult;
var
  JsonStr: string;
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if not FileExists(AFileName) then
  begin
    Result.ErrorMessage := Format('文件"%s"不存在', [AFileName]);
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, 100, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 读取文件内容
    JsonStr := TFile.ReadAllText(AFileName, TEncoding.UTF8);
    
    if JsonStr = '' then
    begin
      Result.ErrorMessage := '文件为空';
      Exit;
    end;
    
    // 解析JSON
    JsonValue := TJSONObject.ParseJSONValue(JsonStr);
    if JsonValue = nil then
    begin
      Result.ErrorMessage := '无效的JSON格式';
      Exit;
    end;
    
    try
      // 检查JSON格式
      if JsonValue is TJSONArray then
      begin
        // 数组格式，包含多个数据项
        JsonArray := JsonValue as TJSONArray;
        
        for var i := 0 to JsonArray.Count - 1 do
        begin
          if JsonArray.Items[i] is TJSONObject then
          begin
            JsonObject := JsonArray.Items[i] as TJSONObject;
            
            // 反序列化数据
            var Data := FSerializer.Deserialize(JsonObject.ToJSON);
            if Data <> nil then
            begin
              try
                // 保存到存储
                if FStorage.SaveFeatureData(Data) then
                  Inc(Result.UpdatedItems)
                else
                  Inc(Result.SkippedItems);
              finally
                Data.Free;
              end;
            end
            else
              Inc(Result.SkippedItems);
          end
          else
            Inc(Result.SkippedItems);
            
          TriggerProgressEvent(i, JsonArray.Count, FState);
        end;
      end
      else if JsonValue is TJSONObject then
      begin
        // 单个对象格式
        JsonObject := JsonValue as TJSONObject;
        
        // 反序列化数据
        var Data := FSerializer.Deserialize(JsonObject.ToJSON);
        if Data <> nil then
        begin
          try
            // 保存到存储
            if FStorage.SaveFeatureData(Data) then
              Inc(Result.UpdatedItems)
            else
              Inc(Result.SkippedItems);
          finally
            Data.Free;
          end;
        end
        else
          Inc(Result.SkippedItems);
          
        TriggerProgressEvent(1, 1, FState);
      end
      else
      begin
        Result.ErrorMessage := '不支持的JSON格式';
        Exit;
      end;
    finally
      JsonValue.Free;
    end;
    
    Result.Success := (Result.UpdatedItems > 0);
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
    TriggerProgressEvent(100, 100, FState);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.BatchUpdate(ADataList: TObjectList<TFeatureData>): TUpdateResult;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.UpdatedItems := 0;
  Result.SkippedItems := 0;
  Result.Duration := 0;
  
  if (ADataList = nil) or (ADataList.Count = 0) then
  begin
    Result.ErrorMessage := '数据列表为空';
    Exit;
  end;
  
  FState := usUpdating;
  TriggerProgressEvent(0, ADataList.Count, FState);
  
  try
    // 记录开始时间
    var StartTime := TStopwatch.GetTimeStamp;
    
    // 批量更新
    for var i := 0 to ADataList.Count - 1 do
    begin
      var Data := ADataList[i];
      
      if Data <> nil then
      begin
        // 设置更新时间
        Data.LastUpdated := Now;
        
        // 保存到存储
        if FStorage.SaveFeatureData(Data) then
          Inc(Result.UpdatedItems)
        else
          Inc(Result.SkippedItems);
      end
      else
        Inc(Result.SkippedItems);
        
      TriggerProgressEvent(i + 1, ADataList.Count, FState);
    end;
    
    Result.Success := (Result.UpdatedItems > 0);
    
    // 计算耗时
    var EndTime := TStopwatch.GetTimeStamp;
    Result.Duration := TStopwatch.MSecsSpan(StartTime, EndTime);
    
    FState := usCompleted;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      FState := usError;
    end;
  end;
  
  TriggerCompletedEvent(Result);
end;

function TBaseFeatureDataUpdater.GetState: TUpdaterState;
begin
  Result := FState;
end;

procedure TBaseFeatureDataUpdater.SetOnProgress(AEvent: TUpdateProgressEvent);
begin
  FOnProgress := AEvent;
end;

procedure TBaseFeatureDataUpdater.SetOnCompleted(AEvent: TUpdateCompletedEvent);
begin
  FOnCompleted := AEvent;
end;

{ TFeatureDataUpdaterFactory }

class function TFeatureDataUpdaterFactory.CreateUpdater(AStorage: IFeatureDataStorage): IFeatureDataUpdater;
begin
  Result := TBaseFeatureDataUpdater.Create(AStorage);
end;

end. 