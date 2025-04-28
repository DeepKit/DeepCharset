unit ChineseEncodingFeatureDB.Index;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  ChineseEncodingFeatureDB.Types;

type
  // 索引键类型
  TIndexKeyType = (
    iktID,              // ID索引
    iktEncoding,        // 编码类型索引
    iktDataType,        // 数据类型索引
    iktEncodingDataType, // 编码类型+数据类型索引
    iktLastUpdated,     // 最后更新时间索引
    iktCustom           // 自定义索引
  );

  // 索引项
  TIndexItem = record
    ID: Integer;
    Encoding: TChineseEncodingType;
    DataType: TFeatureDataType;
    LastUpdated: TDateTime;
    CustomKey: string;
  end;

  // 索引接口
  IFeatureDataIndex = interface
    ['{A1B2C3D4-E5F6-4A5B-8C9D-1E2F3A4B5C6D}']
    // 添加索引项
    procedure AddIndexItem(const AItem: TIndexItem);
    
    // 更新索引项
    procedure UpdateIndexItem(const AItem: TIndexItem);
    
    // 删除索引项
    procedure RemoveIndexItem(AID: Integer);
    
    // 清空索引
    procedure ClearIndex;
    
    // 根据ID查找索引项
    function FindByID(AID: Integer): TIndexItem;
    
    // 根据编码类型查找索引项
    function FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
    
    // 根据数据类型查找索引项
    function FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
    
    // 根据编码类型和数据类型查找索引项
    function FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
    
    // 根据最后更新时间查找索引项
    function FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
    
    // 根据自定义键查找索引项
    function FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
    
    // 获取所有索引项
    function GetAllItems: TArray<TIndexItem>;
    
    // 获取索引项数量
    function GetCount: Integer;
  end;

  // 内存索引
  TMemoryFeatureDataIndex = class(TInterfacedObject, IFeatureDataIndex)
  private
    FIDIndex: TDictionary<Integer, TIndexItem>;
    FEncodingIndex: TMultiMap<TChineseEncodingType, TIndexItem>;
    FDataTypeIndex: TMultiMap<TFeatureDataType, TIndexItem>;
    FEncodingDataTypeIndex: TMultiMap<string, TIndexItem>;
    FLastUpdatedIndex: TMultiMap<TDateTime, TIndexItem>;
    FCustomKeyIndex: TMultiMap<string, TIndexItem>;
    
    // 获取编码类型+数据类型的键
    function GetEncodingDataTypeKey(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): string;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 实现IFeatureDataIndex接口
    procedure AddIndexItem(const AItem: TIndexItem);
    procedure UpdateIndexItem(const AItem: TIndexItem);
    procedure RemoveIndexItem(AID: Integer);
    procedure ClearIndex;
    function FindByID(AID: Integer): TIndexItem;
    function FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
    function FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
    function FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
    function GetAllItems: TArray<TIndexItem>;
    function GetCount: Integer;
  end;

  // 文件索引
  TFileFeatureDataIndex = class(TInterfacedObject, IFeatureDataIndex)
  private
    FIndexFileName: string;
    FMemoryIndex: IFeatureDataIndex;
    
    // 加载索引
    procedure LoadIndex;
    
    // 保存索引
    procedure SaveIndex;
  public
    constructor Create(const AIndexFileName: string);
    destructor Destroy; override;
    
    // 实现IFeatureDataIndex接口
    procedure AddIndexItem(const AItem: TIndexItem);
    procedure UpdateIndexItem(const AItem: TIndexItem);
    procedure RemoveIndexItem(AID: Integer);
    procedure ClearIndex;
    function FindByID(AID: Integer): TIndexItem;
    function FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
    function FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
    function FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
    function GetAllItems: TArray<TIndexItem>;
    function GetCount: Integer;
  end;

  // 数据库索引
  TDatabaseFeatureDataIndex = class(TInterfacedObject, IFeatureDataIndex)
  private
    FConnectionString: string;
    
    // 创建索引表
    procedure CreateIndexTables;
  public
    constructor Create(const AConnectionString: string);
    destructor Destroy; override;
    
    // 实现IFeatureDataIndex接口
    procedure AddIndexItem(const AItem: TIndexItem);
    procedure UpdateIndexItem(const AItem: TIndexItem);
    procedure RemoveIndexItem(AID: Integer);
    procedure ClearIndex;
    function FindByID(AID: Integer): TIndexItem;
    function FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
    function FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
    function FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
    function FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
    function GetAllItems: TArray<TIndexItem>;
    function GetCount: Integer;
  end;

  // 索引工厂
  TFeatureDataIndexFactory = class
  public
    // 创建内存索引
    class function CreateMemoryIndex: IFeatureDataIndex;
    
    // 创建文件索引
    class function CreateFileIndex(const AIndexFileName: string): IFeatureDataIndex;
    
    // 创建数据库索引
    class function CreateDatabaseIndex(const AConnectionString: string): IFeatureDataIndex;
  end;

implementation

{ TMemoryFeatureDataIndex }

constructor TMemoryFeatureDataIndex.Create;
begin
  inherited Create;
  FIDIndex := TDictionary<Integer, TIndexItem>.Create;
  FEncodingIndex := TMultiMap<TChineseEncodingType, TIndexItem>.Create;
  FDataTypeIndex := TMultiMap<TFeatureDataType, TIndexItem>.Create;
  FEncodingDataTypeIndex := TMultiMap<string, TIndexItem>.Create;
  FLastUpdatedIndex := TMultiMap<TDateTime, TIndexItem>.Create;
  FCustomKeyIndex := TMultiMap<string, TIndexItem>.Create;
end;

destructor TMemoryFeatureDataIndex.Destroy;
begin
  FIDIndex.Free;
  FEncodingIndex.Free;
  FDataTypeIndex.Free;
  FEncodingDataTypeIndex.Free;
  FLastUpdatedIndex.Free;
  FCustomKeyIndex.Free;
  inherited;
end;

function TMemoryFeatureDataIndex.GetEncodingDataTypeKey(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): string;
begin
  Result := Format('%d_%d', [Ord(AEncoding), Ord(ADataType)]);
end;

procedure TMemoryFeatureDataIndex.AddIndexItem(const AItem: TIndexItem);
begin
  // 添加到ID索引
  FIDIndex.AddOrSetValue(AItem.ID, AItem);
  
  // 添加到编码类型索引
  FEncodingIndex.Add(AItem.Encoding, AItem);
  
  // 添加到数据类型索引
  FDataTypeIndex.Add(AItem.DataType, AItem);
  
  // 添加到编码类型+数据类型索引
  FEncodingDataTypeIndex.Add(GetEncodingDataTypeKey(AItem.Encoding, AItem.DataType), AItem);
  
  // 添加到最后更新时间索引
  FLastUpdatedIndex.Add(AItem.LastUpdated, AItem);
  
  // 添加到自定义键索引
  if not AItem.CustomKey.IsEmpty then
    FCustomKeyIndex.Add(AItem.CustomKey, AItem);
end;

procedure TMemoryFeatureDataIndex.UpdateIndexItem(const AItem: TIndexItem);
begin
  // 先删除旧索引项
  RemoveIndexItem(AItem.ID);
  
  // 添加新索引项
  AddIndexItem(AItem);
end;

procedure TMemoryFeatureDataIndex.RemoveIndexItem(AID: Integer);
var
  Item: TIndexItem;
begin
  // 检查ID是否存在
  if not FIDIndex.TryGetValue(AID, Item) then
    Exit;
  
  // 从ID索引中删除
  FIDIndex.Remove(AID);
  
  // 从编码类型索引中删除
  FEncodingIndex.RemovePair(Item.Encoding, Item);
  
  // 从数据类型索引中删除
  FDataTypeIndex.RemovePair(Item.DataType, Item);
  
  // 从编码类型+数据类型索引中删除
  FEncodingDataTypeIndex.RemovePair(GetEncodingDataTypeKey(Item.Encoding, Item.DataType), Item);
  
  // 从最后更新时间索引中删除
  FLastUpdatedIndex.RemovePair(Item.LastUpdated, Item);
  
  // 从自定义键索引中删除
  if not Item.CustomKey.IsEmpty then
    FCustomKeyIndex.RemovePair(Item.CustomKey, Item);
end;

procedure TMemoryFeatureDataIndex.ClearIndex;
begin
  FIDIndex.Clear;
  FEncodingIndex.Clear;
  FDataTypeIndex.Clear;
  FEncodingDataTypeIndex.Clear;
  FLastUpdatedIndex.Clear;
  FCustomKeyIndex.Clear;
end;

function TMemoryFeatureDataIndex.FindByID(AID: Integer): TIndexItem;
begin
  if not FIDIndex.TryGetValue(AID, Result) then
    FillChar(Result, SizeOf(Result), 0);
end;

function TMemoryFeatureDataIndex.FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
var
  Values: TArray<TIndexItem>;
begin
  Values := FEncodingIndex[AEncoding].ToArray;
  Result := Values;
end;

function TMemoryFeatureDataIndex.FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
var
  Values: TArray<TIndexItem>;
begin
  Values := FDataTypeIndex[ADataType].ToArray;
  Result := Values;
end;

function TMemoryFeatureDataIndex.FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
var
  Key: string;
  Values: TArray<TIndexItem>;
begin
  Key := GetEncodingDataTypeKey(AEncoding, ADataType);
  Values := FEncodingDataTypeIndex[Key].ToArray;
  Result := Values;
end;

function TMemoryFeatureDataIndex.FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
var
  Items: TList<TIndexItem>;
  Pair: TPair<TDateTime, TIndexItem>;
begin
  Items := TList<TIndexItem>.Create;
  try
    for Pair in FLastUpdatedIndex do
    begin
      if (Pair.Key >= AStartTime) and (Pair.Key <= AEndTime) then
        Items.Add(Pair.Value);
    end;
    
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function TMemoryFeatureDataIndex.FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
var
  Values: TArray<TIndexItem>;
begin
  Values := FCustomKeyIndex[ACustomKey].ToArray;
  Result := Values;
end;

function TMemoryFeatureDataIndex.GetAllItems: TArray<TIndexItem>;
var
  Items: TList<TIndexItem>;
  Pair: TPair<Integer, TIndexItem>;
begin
  Items := TList<TIndexItem>.Create;
  try
    for Pair in FIDIndex do
      Items.Add(Pair.Value);
    
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function TMemoryFeatureDataIndex.GetCount: Integer;
begin
  Result := FIDIndex.Count;
end;

{ TFileFeatureDataIndex }

constructor TFileFeatureDataIndex.Create(const AIndexFileName: string);
begin
  inherited Create;
  FIndexFileName := AIndexFileName;
  FMemoryIndex := TMemoryFeatureDataIndex.Create;
  
  // 加载索引
  LoadIndex;
end;

destructor TFileFeatureDataIndex.Destroy;
begin
  // 保存索引
  SaveIndex;
  
  inherited;
end;

procedure TFileFeatureDataIndex.LoadIndex;
var
  IndexFile: TStringList;
  JsonArray, ItemObj: TJSONArray;
  I: Integer;
  Item: TIndexItem;
begin
  if not FileExists(FIndexFileName) then
    Exit;
  
  IndexFile := TStringList.Create;
  try
    IndexFile.LoadFromFile(FIndexFileName);
    
    JsonArray := TJSONObject.ParseJSONValue(IndexFile.Text) as TJSONArray;
    if JsonArray <> nil then
    try
      for I := 0 to JsonArray.Count - 1 do
      begin
        ItemObj := JsonArray.Items[I] as TJSONObject;
        if ItemObj <> nil then
        begin
          Item.ID := ItemObj.GetValue<Integer>('id');
          Item.Encoding := TChineseEncodingType(ItemObj.GetValue<Integer>('encoding'));
          Item.DataType := TFeatureDataType(ItemObj.GetValue<Integer>('data_type'));
          Item.LastUpdated := ISO8601ToDate(ItemObj.GetValue<string>('last_updated'));
          Item.CustomKey := ItemObj.GetValue<string>('custom_key');
          
          FMemoryIndex.AddIndexItem(Item);
        end;
      end;
    finally
      JsonArray.Free;
    end;
  finally
    IndexFile.Free;
  end;
end;

procedure TFileFeatureDataIndex.SaveIndex;
var
  IndexFile: TStringList;
  JsonArray, ItemObj: TJSONArray;
  Items: TArray<TIndexItem>;
  I: Integer;
begin
  IndexFile := TStringList.Create;
  try
    JsonArray := TJSONArray.Create;
    try
      Items := FMemoryIndex.GetAllItems;
      
      for I := 0 to Length(Items) - 1 do
      begin
        ItemObj := TJSONObject.Create;
        ItemObj.AddPair('id', TJSONNumber.Create(Items[I].ID));
        ItemObj.AddPair('encoding', TJSONNumber.Create(Ord(Items[I].Encoding)));
        ItemObj.AddPair('data_type', TJSONNumber.Create(Ord(Items[I].DataType)));
        ItemObj.AddPair('last_updated', DateToISO8601(Items[I].LastUpdated));
        ItemObj.AddPair('custom_key', Items[I].CustomKey);
        
        JsonArray.AddElement(ItemObj);
      end;
      
      IndexFile.Text := JsonArray.ToJSON;
      IndexFile.SaveToFile(FIndexFileName);
    finally
      JsonArray.Free;
    end;
  finally
    IndexFile.Free;
  end;
end;

procedure TFileFeatureDataIndex.AddIndexItem(const AItem: TIndexItem);
begin
  FMemoryIndex.AddIndexItem(AItem);
  SaveIndex;
end;

procedure TFileFeatureDataIndex.UpdateIndexItem(const AItem: TIndexItem);
begin
  FMemoryIndex.UpdateIndexItem(AItem);
  SaveIndex;
end;

procedure TFileFeatureDataIndex.RemoveIndexItem(AID: Integer);
begin
  FMemoryIndex.RemoveIndexItem(AID);
  SaveIndex;
end;

procedure TFileFeatureDataIndex.ClearIndex;
begin
  FMemoryIndex.ClearIndex;
  SaveIndex;
end;

function TFileFeatureDataIndex.FindByID(AID: Integer): TIndexItem;
begin
  Result := FMemoryIndex.FindByID(AID);
end;

function TFileFeatureDataIndex.FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
begin
  Result := FMemoryIndex.FindByEncoding(AEncoding);
end;

function TFileFeatureDataIndex.FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
begin
  Result := FMemoryIndex.FindByDataType(ADataType);
end;

function TFileFeatureDataIndex.FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
begin
  Result := FMemoryIndex.FindByEncodingAndDataType(AEncoding, ADataType);
end;

function TFileFeatureDataIndex.FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
begin
  Result := FMemoryIndex.FindByLastUpdated(AStartTime, AEndTime);
end;

function TFileFeatureDataIndex.FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
begin
  Result := FMemoryIndex.FindByCustomKey(ACustomKey);
end;

function TFileFeatureDataIndex.GetAllItems: TArray<TIndexItem>;
begin
  Result := FMemoryIndex.GetAllItems;
end;

function TFileFeatureDataIndex.GetCount: Integer;
begin
  Result := FMemoryIndex.GetCount;
end;

{ TDatabaseFeatureDataIndex }

constructor TDatabaseFeatureDataIndex.Create(const AConnectionString: string);
begin
  inherited Create;
  FConnectionString := AConnectionString;
  
  // 创建索引表
  CreateIndexTables;
end;

destructor TDatabaseFeatureDataIndex.Destroy;
begin
  inherited;
end;

procedure TDatabaseFeatureDataIndex.CreateIndexTables;
begin
  // 在实际实现中，这里应该创建数据库索引表
  // 例如：
  // CREATE TABLE feature_index (
  //   id INTEGER PRIMARY KEY,
  //   encoding INTEGER,
  //   data_type INTEGER,
  //   last_updated DATETIME,
  //   custom_key TEXT
  // );
  // CREATE INDEX idx_encoding ON feature_index (encoding);
  // CREATE INDEX idx_data_type ON feature_index (data_type);
  // CREATE INDEX idx_encoding_data_type ON feature_index (encoding, data_type);
  // CREATE INDEX idx_last_updated ON feature_index (last_updated);
  // CREATE INDEX idx_custom_key ON feature_index (custom_key);
end;

procedure TDatabaseFeatureDataIndex.AddIndexItem(const AItem: TIndexItem);
begin
  // 在实际实现中，这里应该添加索引项到数据库
end;

procedure TDatabaseFeatureDataIndex.UpdateIndexItem(const AItem: TIndexItem);
begin
  // 在实际实现中，这里应该更新数据库中的索引项
end;

procedure TDatabaseFeatureDataIndex.RemoveIndexItem(AID: Integer);
begin
  // 在实际实现中，这里应该从数据库中删除索引项
end;

procedure TDatabaseFeatureDataIndex.ClearIndex;
begin
  // 在实际实现中，这里应该清空数据库中的索引
end;

function TDatabaseFeatureDataIndex.FindByID(AID: Integer): TIndexItem;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  FillChar(Result, SizeOf(Result), 0);
end;

function TDatabaseFeatureDataIndex.FindByEncoding(AEncoding: TChineseEncodingType): TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.FindByDataType(ADataType: TFeatureDataType): TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.FindByEncodingAndDataType(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.FindByLastUpdated(AStartTime, AEndTime: TDateTime): TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.FindByCustomKey(const ACustomKey: string): TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中查找索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.GetAllItems: TArray<TIndexItem>;
begin
  // 在实际实现中，这里应该从数据库中获取所有索引项
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataIndex.GetCount: Integer;
begin
  // 在实际实现中，这里应该返回数据库中的索引项数量
  Result := 0;
end;

{ TFeatureDataIndexFactory }

class function TFeatureDataIndexFactory.CreateMemoryIndex: IFeatureDataIndex;
begin
  Result := TMemoryFeatureDataIndex.Create;
end;

class function TFeatureDataIndexFactory.CreateFileIndex(const AIndexFileName: string): IFeatureDataIndex;
begin
  Result := TFileFeatureDataIndex.Create(AIndexFileName);
end;

class function TFeatureDataIndexFactory.CreateDatabaseIndex(const AConnectionString: string): IFeatureDataIndex;
begin
  Result := TDatabaseFeatureDataIndex.Create(AConnectionString);
end;

end.
