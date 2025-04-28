unit ChineseEncodingFeatureDB.Update;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading,
  ChineseEncodingFeatureDB.Types, ChineseEncodingFeatureDB.Storage;

type
  // 更新操作类型
  TUpdateOperationType = (
    uotAdd,      // 添加操作
    uotUpdate,   // 更新操作
    uotDelete,   // 删除操作
    uotClear     // 清空操作
  );

  // 更新操作
  TUpdateOperation = record
    OperationType: TUpdateOperationType;
    ID: Integer;
    Data: TFeatureData;
  end;

  // 更新结果
  TUpdateResult = record
    Success: Boolean;
    ErrorMessage: string;
    AffectedIDs: TArray<Integer>;
  end;

  // 更新事件
  TUpdateEvent = procedure(Sender: TObject; const Operation: TUpdateOperation; const Result: TUpdateResult) of object;

  // 更新接口
  IFeatureDataUpdater = interface
    ['{C1D2E3F4-A5B6-7C8D-9E0F-1A2B3C4D5E6F}']
    // 添加特征数据
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    
    // 更新特征数据
    function UpdateFeatureData(AData: TFeatureData): TUpdateResult;
    
    // 删除特征数据
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    
    // 清空特征数据
    function ClearFeatureData: TUpdateResult;
    
    // 批量更新特征数据
    function BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
    
    // 获取更新历史
    function GetUpdateHistory: TArray<TUpdateOperation>;
    
    // 撤销最后一次更新
    function UndoLastUpdate: TUpdateResult;
    
    // 设置更新事件
    procedure SetOnUpdate(AEvent: TUpdateEvent);
  end;

  // 基本更新器
  TBaseFeatureDataUpdater = class(TInterfacedObject, IFeatureDataUpdater)
  private
    FStorage: IFeatureDataStorage;
    FUpdateHistory: TList<TUpdateOperation>;
    FOnUpdate: TUpdateEvent;
    
    // 触发更新事件
    procedure TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
  public
    constructor Create(AStorage: IFeatureDataStorage);
    destructor Destroy; override;
    
    // 实现IFeatureDataUpdater接口
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    function UpdateFeatureData(AData: TFeatureData): TUpdateResult;
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    function ClearFeatureData: TUpdateResult;
    function BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
    function GetUpdateHistory: TArray<TUpdateOperation>;
    function UndoLastUpdate: TUpdateResult;
    procedure SetOnUpdate(AEvent: TUpdateEvent);
  end;

  // 异步更新器
  TAsyncFeatureDataUpdater = class(TInterfacedObject, IFeatureDataUpdater)
  private
    FBaseUpdater: IFeatureDataUpdater;
    FUpdateQueue: TThreadedQueue<TUpdateOperation>;
    FUpdateThread: TThread;
    FOnUpdate: TUpdateEvent;
    
    // 更新线程方法
    procedure UpdateThreadProc;
    
    // 触发更新事件
    procedure TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
  public
    constructor Create(ABaseUpdater: IFeatureDataUpdater);
    destructor Destroy; override;
    
    // 实现IFeatureDataUpdater接口
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    function UpdateFeatureData(AData: TFeatureData): TUpdateResult;
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    function ClearFeatureData: TUpdateResult;
    function BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
    function GetUpdateHistory: TArray<TUpdateOperation>;
    function UndoLastUpdate: TUpdateResult;
    procedure SetOnUpdate(AEvent: TUpdateEvent);
  end;

  // 事务更新器
  TTransactionFeatureDataUpdater = class(TInterfacedObject, IFeatureDataUpdater)
  private
    FBaseUpdater: IFeatureDataUpdater;
    FTransactionOperations: TList<TUpdateOperation>;
    FInTransaction: Boolean;
    FOnUpdate: TUpdateEvent;
    
    // 触发更新事件
    procedure TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
  public
    constructor Create(ABaseUpdater: IFeatureDataUpdater);
    destructor Destroy; override;
    
    // 开始事务
    procedure BeginTransaction;
    
    // 提交事务
    function CommitTransaction: TArray<TUpdateResult>;
    
    // 回滚事务
    procedure RollbackTransaction;
    
    // 实现IFeatureDataUpdater接口
    function AddFeatureData(AData: TFeatureData): TUpdateResult;
    function UpdateFeatureData(AData: TFeatureData): TUpdateResult;
    function DeleteFeatureData(AID: Integer): TUpdateResult;
    function ClearFeatureData: TUpdateResult;
    function BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
    function GetUpdateHistory: TArray<TUpdateOperation>;
    function UndoLastUpdate: TUpdateResult;
    procedure SetOnUpdate(AEvent: TUpdateEvent);
  end;

  // 更新器工厂
  TFeatureDataUpdaterFactory = class
  public
    // 创建基本更新器
    class function CreateBaseUpdater(AStorage: IFeatureDataStorage): IFeatureDataUpdater;
    
    // 创建异步更新器
    class function CreateAsyncUpdater(ABaseUpdater: IFeatureDataUpdater): IFeatureDataUpdater;
    
    // 创建事务更新器
    class function CreateTransactionUpdater(ABaseUpdater: IFeatureDataUpdater): IFeatureDataUpdater;
  end;

implementation

{ TBaseFeatureDataUpdater }

constructor TBaseFeatureDataUpdater.Create(AStorage: IFeatureDataStorage);
begin
  inherited Create;
  FStorage := AStorage;
  FUpdateHistory := TList<TUpdateOperation>.Create;
end;

destructor TBaseFeatureDataUpdater.Destroy;
begin
  FUpdateHistory.Free;
  inherited;
end;

procedure TBaseFeatureDataUpdater.TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
begin
  if Assigned(FOnUpdate) then
    FOnUpdate(Self, Operation, Result);
end;

function TBaseFeatureDataUpdater.AddFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotAdd;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 执行操作
  try
    if FStorage.SaveFeatureData(AData) then
    begin
      Result.Success := True;
      SetLength(Result.AffectedIDs, 1);
      Result.AffectedIDs[0] := AData.ID;
      
      // 添加到更新历史
      FUpdateHistory.Add(Operation);
      
      // 触发更新事件
      TriggerUpdateEvent(Operation, Result);
    end
    else
    begin
      Result.ErrorMessage := 'Failed to save feature data';
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

function TBaseFeatureDataUpdater.UpdateFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 检查ID是否存在
  if not FStorage.FeatureDataExists(AData.ID) then
  begin
    Result.ErrorMessage := Format('Feature data with ID %d does not exist', [AData.ID]);
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotUpdate;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 执行操作
  try
    if FStorage.SaveFeatureData(AData) then
    begin
      Result.Success := True;
      SetLength(Result.AffectedIDs, 1);
      Result.AffectedIDs[0] := AData.ID;
      
      // 添加到更新历史
      FUpdateHistory.Add(Operation);
      
      // 触发更新事件
      TriggerUpdateEvent(Operation, Result);
    end
    else
    begin
      Result.ErrorMessage := 'Failed to update feature data';
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

function TBaseFeatureDataUpdater.DeleteFeatureData(AID: Integer): TUpdateResult;
var
  Operation: TUpdateOperation;
  OldData: TFeatureData;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查ID是否存在
  if not FStorage.FeatureDataExists(AID) then
  begin
    Result.ErrorMessage := Format('Feature data with ID %d does not exist', [AID]);
    Exit;
  end;
  
  // 获取旧数据（用于撤销）
  OldData := FStorage.LoadFeatureData(AID);
  
  // 创建操作
  Operation.OperationType := uotDelete;
  Operation.ID := AID;
  Operation.Data := OldData;
  
  // 执行操作
  try
    if FStorage.DeleteFeatureData(AID) then
    begin
      Result.Success := True;
      SetLength(Result.AffectedIDs, 1);
      Result.AffectedIDs[0] := AID;
      
      // 添加到更新历史
      FUpdateHistory.Add(Operation);
      
      // 触发更新事件
      TriggerUpdateEvent(Operation, Result);
    end
    else
    begin
      Result.ErrorMessage := 'Failed to delete feature data';
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

function TBaseFeatureDataUpdater.ClearFeatureData: TUpdateResult;
var
  Operation: TUpdateOperation;
  AllIDs: TArray<Integer>;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 获取所有ID（用于结果和撤销）
  AllIDs := FStorage.GetFeatureDataIDs;
  
  // 创建操作
  Operation.OperationType := uotClear;
  Operation.ID := -1;
  Operation.Data := nil;
  
  // 执行操作
  try
    FStorage.ClearFeatureData;
    
    Result.Success := True;
    Result.AffectedIDs := AllIDs;
    
    // 添加到更新历史
    FUpdateHistory.Add(Operation);
    
    // 触发更新事件
    TriggerUpdateEvent(Operation, Result);
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

function TBaseFeatureDataUpdater.BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
var
  I: Integer;
  Operation: TUpdateOperation;
  Result: TUpdateResult;
begin
  SetLength(Result, Length(Operations));
  
  for I := 0 to Length(Operations) - 1 do
  begin
    Operation := Operations[I];
    
    case Operation.OperationType of
      uotAdd:
        Result[I] := AddFeatureData(Operation.Data);
      
      uotUpdate:
        Result[I] := UpdateFeatureData(Operation.Data);
      
      uotDelete:
        Result[I] := DeleteFeatureData(Operation.ID);
      
      uotClear:
        Result[I] := ClearFeatureData;
    end;
  end;
end;

function TBaseFeatureDataUpdater.GetUpdateHistory: TArray<TUpdateOperation>;
begin
  Result := FUpdateHistory.ToArray;
end;

function TBaseFeatureDataUpdater.UndoLastUpdate: TUpdateResult;
var
  LastOperation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查是否有更新历史
  if FUpdateHistory.Count = 0 then
  begin
    Result.ErrorMessage := 'No update history';
    Exit;
  end;
  
  // 获取最后一次更新操作
  LastOperation := FUpdateHistory.Last;
  
  // 根据操作类型执行撤销操作
  case LastOperation.OperationType of
    uotAdd:
      begin
        // 撤销添加操作：删除数据
        Result := DeleteFeatureData(LastOperation.ID);
      end;
    
    uotUpdate:
      begin
        // 撤销更新操作：恢复旧数据
        if LastOperation.Data <> nil then
          Result := UpdateFeatureData(LastOperation.Data)
        else
          Result.ErrorMessage := 'No old data to restore';
      end;
    
    uotDelete:
      begin
        // 撤销删除操作：恢复数据
        if LastOperation.Data <> nil then
          Result := AddFeatureData(LastOperation.Data)
        else
          Result.ErrorMessage := 'No data to restore';
      end;
    
    uotClear:
      begin
        // 撤销清空操作：无法撤销
        Result.ErrorMessage := 'Cannot undo clear operation';
      end;
  end;
  
  // 如果撤销成功，从更新历史中删除最后一次操作
  if Result.Success then
    FUpdateHistory.Delete(FUpdateHistory.Count - 1);
end;

procedure TBaseFeatureDataUpdater.SetOnUpdate(AEvent: TUpdateEvent);
begin
  FOnUpdate := AEvent;
end;

{ TAsyncFeatureDataUpdater }

constructor TAsyncFeatureDataUpdater.Create(ABaseUpdater: IFeatureDataUpdater);
begin
  inherited Create;
  FBaseUpdater := ABaseUpdater;
  FUpdateQueue := TThreadedQueue<TUpdateOperation>.Create(100, INFINITE, 100);
  
  // 创建更新线程
  FUpdateThread := TThread.CreateAnonymousThread(UpdateThreadProc);
  FUpdateThread.FreeOnTerminate := False;
  FUpdateThread.Start;
end;

destructor TAsyncFeatureDataUpdater.Destroy;
begin
  // 停止更新线程
  FUpdateThread.Terminate;
  FUpdateQueue.DoShutDown;
  FUpdateThread.WaitFor;
  FUpdateThread.Free;
  
  FUpdateQueue.Free;
  
  inherited;
end;

procedure TAsyncFeatureDataUpdater.UpdateThreadProc;
var
  Operation: TUpdateOperation;
  Result: TUpdateResult;
begin
  while not TThread.CurrentThread.CheckTerminated do
  begin
    // 从队列中获取更新操作
    if FUpdateQueue.PopItem(Operation) = wrSignaled then
    begin
      // 执行更新操作
      case Operation.OperationType of
        uotAdd:
          Result := FBaseUpdater.AddFeatureData(Operation.Data);
        
        uotUpdate:
          Result := FBaseUpdater.UpdateFeatureData(Operation.Data);
        
        uotDelete:
          Result := FBaseUpdater.DeleteFeatureData(Operation.ID);
        
        uotClear:
          Result := FBaseUpdater.ClearFeatureData;
      end;
      
      // 触发更新事件
      TriggerUpdateEvent(Operation, Result);
    end;
  end;
end;

procedure TAsyncFeatureDataUpdater.TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
begin
  if Assigned(FOnUpdate) then
    TThread.Queue(nil,
      procedure
      begin
        FOnUpdate(Self, Operation, Result);
      end);
end;

function TAsyncFeatureDataUpdater.AddFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotAdd;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 添加到更新队列
  if FUpdateQueue.PushItem(Operation) <> wrSignaled then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Failed to push operation to queue';
  end;
end;

function TAsyncFeatureDataUpdater.UpdateFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotUpdate;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 添加到更新队列
  if FUpdateQueue.PushItem(Operation) <> wrSignaled then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Failed to push operation to queue';
  end;
end;

function TAsyncFeatureDataUpdater.DeleteFeatureData(AID: Integer): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 创建操作
  Operation.OperationType := uotDelete;
  Operation.ID := AID;
  Operation.Data := nil;
  
  // 添加到更新队列
  if FUpdateQueue.PushItem(Operation) <> wrSignaled then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Failed to push operation to queue';
  end;
end;

function TAsyncFeatureDataUpdater.ClearFeatureData: TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 创建操作
  Operation.OperationType := uotClear;
  Operation.ID := -1;
  Operation.Data := nil;
  
  // 添加到更新队列
  if FUpdateQueue.PushItem(Operation) <> wrSignaled then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Failed to push operation to queue';
  end;
end;

function TAsyncFeatureDataUpdater.BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
var
  I: Integer;
begin
  SetLength(Result, Length(Operations));
  
  for I := 0 to Length(Operations) - 1 do
  begin
    case Operations[I].OperationType of
      uotAdd:
        Result[I] := AddFeatureData(Operations[I].Data);
      
      uotUpdate:
        Result[I] := UpdateFeatureData(Operations[I].Data);
      
      uotDelete:
        Result[I] := DeleteFeatureData(Operations[I].ID);
      
      uotClear:
        Result[I] := ClearFeatureData;
    end;
  end;
end;

function TAsyncFeatureDataUpdater.GetUpdateHistory: TArray<TUpdateOperation>;
begin
  Result := FBaseUpdater.GetUpdateHistory;
end;

function TAsyncFeatureDataUpdater.UndoLastUpdate: TUpdateResult;
begin
  Result := FBaseUpdater.UndoLastUpdate;
end;

procedure TAsyncFeatureDataUpdater.SetOnUpdate(AEvent: TUpdateEvent);
begin
  FOnUpdate := AEvent;
end;

{ TTransactionFeatureDataUpdater }

constructor TTransactionFeatureDataUpdater.Create(ABaseUpdater: IFeatureDataUpdater);
begin
  inherited Create;
  FBaseUpdater := ABaseUpdater;
  FTransactionOperations := TList<TUpdateOperation>.Create;
  FInTransaction := False;
end;

destructor TTransactionFeatureDataUpdater.Destroy;
begin
  FTransactionOperations.Free;
  inherited;
end;

procedure TTransactionFeatureDataUpdater.TriggerUpdateEvent(const Operation: TUpdateOperation; const Result: TUpdateResult);
begin
  if Assigned(FOnUpdate) then
    FOnUpdate(Self, Operation, Result);
end;

procedure TTransactionFeatureDataUpdater.BeginTransaction;
begin
  FInTransaction := True;
  FTransactionOperations.Clear;
end;

function TTransactionFeatureDataUpdater.CommitTransaction: TArray<TUpdateResult>;
var
  Operations: TArray<TUpdateOperation>;
begin
  if not FInTransaction then
    Exit(nil);
  
  // 获取事务中的所有操作
  Operations := FTransactionOperations.ToArray;
  
  // 执行批量更新
  Result := FBaseUpdater.BatchUpdate(Operations);
  
  // 清空事务
  FTransactionOperations.Clear;
  FInTransaction := False;
end;

procedure TTransactionFeatureDataUpdater.RollbackTransaction;
begin
  if not FInTransaction then
    Exit;
  
  // 清空事务
  FTransactionOperations.Clear;
  FInTransaction := False;
end;

function TTransactionFeatureDataUpdater.AddFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotAdd;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 如果在事务中，添加到事务操作列表
  if FInTransaction then
  begin
    FTransactionOperations.Add(Operation);
  end
  else
  begin
    // 否则，直接执行操作
    Result := FBaseUpdater.AddFeatureData(AData);
  end;
end;

function TTransactionFeatureDataUpdater.UpdateFeatureData(AData: TFeatureData): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 检查参数
  if AData = nil then
  begin
    Result.Success := False;
    Result.ErrorMessage := 'Data is nil';
    Exit;
  end;
  
  // 创建操作
  Operation.OperationType := uotUpdate;
  Operation.ID := AData.ID;
  Operation.Data := AData;
  
  // 如果在事务中，添加到事务操作列表
  if FInTransaction then
  begin
    FTransactionOperations.Add(Operation);
  end
  else
  begin
    // 否则，直接执行操作
    Result := FBaseUpdater.UpdateFeatureData(AData);
  end;
end;

function TTransactionFeatureDataUpdater.DeleteFeatureData(AID: Integer): TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 创建操作
  Operation.OperationType := uotDelete;
  Operation.ID := AID;
  Operation.Data := nil;
  
  // 如果在事务中，添加到事务操作列表
  if FInTransaction then
  begin
    FTransactionOperations.Add(Operation);
  end
  else
  begin
    // 否则，直接执行操作
    Result := FBaseUpdater.DeleteFeatureData(AID);
  end;
end;

function TTransactionFeatureDataUpdater.ClearFeatureData: TUpdateResult;
var
  Operation: TUpdateOperation;
begin
  // 初始化结果
  Result.Success := True;
  Result.ErrorMessage := '';
  SetLength(Result.AffectedIDs, 0);
  
  // 创建操作
  Operation.OperationType := uotClear;
  Operation.ID := -1;
  Operation.Data := nil;
  
  // 如果在事务中，添加到事务操作列表
  if FInTransaction then
  begin
    FTransactionOperations.Add(Operation);
  end
  else
  begin
    // 否则，直接执行操作
    Result := FBaseUpdater.ClearFeatureData;
  end;
end;

function TTransactionFeatureDataUpdater.BatchUpdate(const Operations: TArray<TUpdateOperation>): TArray<TUpdateResult>;
var
  I: Integer;
begin
  // 如果在事务中，添加到事务操作列表
  if FInTransaction then
  begin
    for I := 0 to Length(Operations) - 1 do
      FTransactionOperations.Add(Operations[I]);
    
    // 返回空结果
    SetLength(Result, Length(Operations));
    for I := 0 to Length(Result) - 1 do
    begin
      Result[I].Success := True;
      Result[I].ErrorMessage := '';
      SetLength(Result[I].AffectedIDs, 0);
    end;
  end
  else
  begin
    // 否则，直接执行操作
    Result := FBaseUpdater.BatchUpdate(Operations);
  end;
end;

function TTransactionFeatureDataUpdater.GetUpdateHistory: TArray<TUpdateOperation>;
begin
  Result := FBaseUpdater.GetUpdateHistory;
end;

function TTransactionFeatureDataUpdater.UndoLastUpdate: TUpdateResult;
begin
  Result := FBaseUpdater.UndoLastUpdate;
end;

procedure TTransactionFeatureDataUpdater.SetOnUpdate(AEvent: TUpdateEvent);
begin
  FOnUpdate := AEvent;
end;

{ TFeatureDataUpdaterFactory }

class function TFeatureDataUpdaterFactory.CreateBaseUpdater(AStorage: IFeatureDataStorage): IFeatureDataUpdater;
begin
  Result := TBaseFeatureDataUpdater.Create(AStorage);
end;

class function TFeatureDataUpdaterFactory.CreateAsyncUpdater(ABaseUpdater: IFeatureDataUpdater): IFeatureDataUpdater;
begin
  Result := TAsyncFeatureDataUpdater.Create(ABaseUpdater);
end;

class function TFeatureDataUpdaterFactory.CreateTransactionUpdater(ABaseUpdater: IFeatureDataUpdater): IFeatureDataUpdater;
begin
  Result := TTransactionFeatureDataUpdater.Create(ABaseUpdater);
end;

end.
