unit ChineseEncodingFeatureDB.Storage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.IOUtils, System.Math, ChineseEncodingFeatureDB.Types;

type
  // 特征数据存储接口
  IFeatureDataStorage = interface
    ['{F8A9D3E5-6B7C-4D2A-8E9F-1A2B3C4D5E6F}']
    // 保存特征数据
    function SaveFeatureData(AData: TFeatureData): Boolean;

    // 加载特征数据
    function LoadFeatureData(AID: Integer): TFeatureData;

    // 删除特征数据
    function DeleteFeatureData(AID: Integer): Boolean;

    // 查询特征数据
    function QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;

    // 清空特征数据
    procedure ClearFeatureData;

    // 获取特征数据数量
    function GetFeatureDataCount: Integer;

    // 获取特征数据ID列表
    function GetFeatureDataIDs: TArray<Integer>;

    // 检查特征数据是否存在
    function FeatureDataExists(AID: Integer): Boolean;
  end;

  // 内存特征数据存储
  TMemoryFeatureDataStorage = class(TInterfacedObject, IFeatureDataStorage)
  private
    FDataStore: TObjectDictionary<Integer, TFeatureData>;
    FNextID: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    // 实现IFeatureDataStorage接口
    function SaveFeatureData(AData: TFeatureData): Boolean;
    function LoadFeatureData(AID: Integer): TFeatureData;
    function DeleteFeatureData(AID: Integer): Boolean;
    function QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
    procedure ClearFeatureData;
    function GetFeatureDataCount: Integer;
    function GetFeatureDataIDs: TArray<Integer>;
    function FeatureDataExists(AID: Integer): Boolean;
  end;

  // 文件特征数据存储
  TFileFeatureDataStorage = class(TInterfacedObject, IFeatureDataStorage)
  private
    FStorageDirectory: string;
    FIndexFileName: string;
    FDataIndex: TDictionary<Integer, string>;
    FNextID: Integer;

    // 加载索引
    procedure LoadIndex;

    // 保存索引
    procedure SaveIndex;

    // 获取数据文件名
    function GetDataFileName(AID: Integer): string;

    // 序列化特征数据
    function SerializeFeatureData(AData: TFeatureData): string;

    // 反序列化特征数据
    function DeserializeFeatureData(const AJson: string): TFeatureData;
  public
    constructor Create(const AStorageDirectory: string);
    destructor Destroy; override;

    // 实现IFeatureDataStorage接口
    function SaveFeatureData(AData: TFeatureData): Boolean;
    function LoadFeatureData(AID: Integer): TFeatureData;
    function DeleteFeatureData(AID: Integer): Boolean;
    function QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
    procedure ClearFeatureData;
    function GetFeatureDataCount: Integer;
    function GetFeatureDataIDs: TArray<Integer>;
    function FeatureDataExists(AID: Integer): Boolean;
  end;

  // 数据库特征数据存储
  TDatabaseFeatureDataStorage = class(TInterfacedObject, IFeatureDataStorage)
  private
    FConnectionString: string;

    // 创建数据库表
    procedure CreateTables;

    // 序列化特征数据
    function SerializeFeatureData(AData: TFeatureData): string;

    // 反序列化特征数据
    function DeserializeFeatureData(const AJson: string; ADataType: TFeatureDataType; AEncoding: TChineseEncodingType): TFeatureData;
  public
    constructor Create(const AConnectionString: string);
    destructor Destroy; override;

    // 实现IFeatureDataStorage接口
    function SaveFeatureData(AData: TFeatureData): Boolean;
    function LoadFeatureData(AID: Integer): TFeatureData;
    function DeleteFeatureData(AID: Integer): Boolean;
    function QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
    procedure ClearFeatureData;
    function GetFeatureDataCount: Integer;
    function GetFeatureDataIDs: TArray<Integer>;
    function FeatureDataExists(AID: Integer): Boolean;
  end;

  // 特征数据存储工厂
  TFeatureDataStorageFactory = class
  public
    // 创建内存存储
    class function CreateMemoryStorage: IFeatureDataStorage;

    // 创建文件存储
    class function CreateFileStorage(const AStorageDirectory: string): IFeatureDataStorage;

    // 创建数据库存储
    class function CreateDatabaseStorage(const AConnectionString: string): IFeatureDataStorage;
  end;

implementation

{ TMemoryFeatureDataStorage }

constructor TMemoryFeatureDataStorage.Create;
begin
  inherited Create;
  FDataStore := TObjectDictionary<Integer, TFeatureData>.Create([doOwnsValues]);
  FNextID := 1;
end;

destructor TMemoryFeatureDataStorage.Destroy;
begin
  FDataStore.Free;
  inherited;
end;

function TMemoryFeatureDataStorage.SaveFeatureData(AData: TFeatureData): Boolean;
begin
  if AData = nil then
    Exit(False);

  // 如果数据没有ID，分配一个新ID
  if AData.ID <= 0 then
  begin
    AData.ID := FNextID;
    Inc(FNextID);
  end;

  // 更新最后修改时间
  AData.LastUpdated := Now;

  // 保存数据
  FDataStore.AddOrSetValue(AData.ID, AData);

  Result := True;
end;

function TMemoryFeatureDataStorage.LoadFeatureData(AID: Integer): TFeatureData;
begin
  if not FDataStore.TryGetValue(AID, Result) then
    Result := nil;
end;

function TMemoryFeatureDataStorage.DeleteFeatureData(AID: Integer): Boolean;
begin
  Result := FDataStore.ContainsKey(AID);
  if Result then
    FDataStore.Remove(AID);
end;

function TMemoryFeatureDataStorage.QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
var
  Data: TFeatureData;
begin
  Result := TFeatureDataCollection.Create(AEncoding, ADataType);

  for Data in FDataStore.Values do
  begin
    if (Data.Encoding = AEncoding) and (Data.DataType = ADataType) then
      Result.Add(Data);
  end;
end;

procedure TMemoryFeatureDataStorage.ClearFeatureData;
begin
  FDataStore.Clear;
  FNextID := 1;
end;

function TMemoryFeatureDataStorage.GetFeatureDataCount: Integer;
begin
  Result := FDataStore.Count;
end;

function TMemoryFeatureDataStorage.GetFeatureDataIDs: TArray<Integer>;
begin
  Result := FDataStore.Keys.ToArray;
end;

function TMemoryFeatureDataStorage.FeatureDataExists(AID: Integer): Boolean;
begin
  Result := FDataStore.ContainsKey(AID);
end;

{ TFileFeatureDataStorage }

constructor TFileFeatureDataStorage.Create(const AStorageDirectory: string);
begin
  inherited Create;
  FStorageDirectory := AStorageDirectory;
  FIndexFileName := TPath.Combine(FStorageDirectory, 'index.json');
  FDataIndex := TDictionary<Integer, string>.Create;
  FNextID := 1;

  // 创建存储目录
  if not DirectoryExists(FStorageDirectory) then
    ForceDirectories(FStorageDirectory);

  // 加载索引
  LoadIndex;
end;

destructor TFileFeatureDataStorage.Destroy;
begin
  // 保存索引
  SaveIndex;

  FDataIndex.Free;
  inherited;
end;

procedure TFileFeatureDataStorage.LoadIndex;
var
  IndexFile: TStringList;
  JsonObj, DataObj: TJSONObject;
  JsonArray: TJSONArray;
  I: Integer;
begin
  if not FileExists(FIndexFileName) then
    Exit;

  IndexFile := TStringList.Create;
  try
    IndexFile.LoadFromFile(FIndexFileName);

    JsonObj := TJSONObject.ParseJSONValue(IndexFile.Text) as TJSONObject;
    if JsonObj <> nil then
    try
      // 加载下一个ID
      FNextID := JsonObj.GetValue<Integer>('next_id');

      // 加载数据索引
      JsonArray := JsonObj.GetValue<TJSONArray>('data_index');
      if JsonArray <> nil then
      begin
        for I := 0 to JsonArray.Count - 1 do
        begin
          DataObj := JsonArray.Items[I] as TJSONObject;
          if DataObj <> nil then
          begin
            FDataIndex.Add(
              DataObj.GetValue<Integer>('id'),
              DataObj.GetValue<string>('file_name')
            );
          end;
        end;
      end;
    finally
      JsonObj.Free;
    end;
  finally
    IndexFile.Free;
  end;
end;

procedure TFileFeatureDataStorage.SaveIndex;
var
  IndexFile: TStringList;
  JsonObj, DataObj: TJSONObject;
  JsonArray: TJSONArray;
  ID: Integer;
begin
  IndexFile := TStringList.Create;
  try
    JsonObj := TJSONObject.Create;
    try
      // 保存下一个ID
      JsonObj.AddPair('next_id', TJSONNumber.Create(FNextID));

      // 保存数据索引
      JsonArray := TJSONArray.Create;
      for ID in FDataIndex.Keys do
      begin
        DataObj := TJSONObject.Create;
        DataObj.AddPair('id', TJSONNumber.Create(ID));
        DataObj.AddPair('file_name', FDataIndex[ID]);
        JsonArray.AddElement(DataObj);
      end;

      JsonObj.AddPair('data_index', JsonArray);

      // 保存到文件
      IndexFile.Text := JsonObj.ToJSON;
      IndexFile.SaveToFile(FIndexFileName);
    finally
      JsonObj.Free;
    end;
  finally
    IndexFile.Free;
  end;
end;

function TFileFeatureDataStorage.GetDataFileName(AID: Integer): string;
begin
  Result := TPath.Combine(FStorageDirectory, Format('data_%d.json', [AID]));
end;

function TFileFeatureDataStorage.SerializeFeatureData(AData: TFeatureData): string;
var
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  try
    // 保存基本信息
    JsonObj.AddPair('id', TJSONNumber.Create(AData.ID));
    JsonObj.AddPair('data_type', TJSONNumber.Create(Ord(AData.DataType)));
    JsonObj.AddPair('encoding', TJSONNumber.Create(Ord(AData.Encoding)));
    JsonObj.AddPair('description', AData.Description);
    JsonObj.AddPair('last_updated', FormatDateTime('yyyy-mm-dd hh:nn:ss', AData.LastUpdated));

    // 保存特定类型的数据
    case AData.DataType of
      fdtByteFrequency:
        begin
          var ByteFreqData := AData as TByteFrequencyFeatureData;
          var ByteValues := TJSONArray.Create;

          for var I := 0 to 255 do
            ByteValues.AddElement(TJSONNumber.Create(ByteFreqData.Data.ByteValues[I]));

          JsonObj.AddPair('byte_values', ByteValues);
        end;

      fdtCharFrequency:
        begin
          var CharFreqData := AData as TCharFrequencyFeatureData;
          var CharData := TJSONObject.Create;

          CharData.AddPair('char_code', TJSONNumber.Create(CharFreqData.Data.CharCode));
          CharData.AddPair('first_byte', TJSONNumber.Create(CharFreqData.Data.FirstByte));
          CharData.AddPair('second_byte', TJSONNumber.Create(CharFreqData.Data.SecondByte));
          CharData.AddPair('third_byte', TJSONNumber.Create(CharFreqData.Data.ThirdByte));
          CharData.AddPair('fourth_byte', TJSONNumber.Create(CharFreqData.Data.FourthByte));
          CharData.AddPair('frequency', TJSONNumber.Create(CharFreqData.Data.Frequency));
          CharData.AddPair('character', CharFreqData.Data.Character);
          CharData.AddPair('char_type', TJSONNumber.Create(Ord(CharFreqData.Data.CharType)));
          CharData.AddPair('description', CharFreqData.Data.Description);

          JsonObj.AddPair('char_data', CharData);
        end;

      // 其他类型的数据序列化...
    end;

    Result := JsonObj.ToJSON;
  finally
    JsonObj.Free;
  end;
end;

function TFileFeatureDataStorage.DeserializeFeatureData(const AJson: string): TFeatureData;
var
  JsonObj: TJSONObject;
  DataType: TFeatureDataType;
  Encoding: TChineseEncodingType;
  I: Integer;
  TempValue: Double;
  TempUInt32: UInt32;
  TempByte: Byte;
  TempInt: Integer;
  TempString: string;
begin
  Result := nil;

  JsonObj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if JsonObj = nil then
    Exit;

  try
    // 获取基本信息
    DataType := TFeatureDataType(JsonObj.GetValue<Integer>('data_type'));
    Encoding := TChineseEncodingType(JsonObj.GetValue<Integer>('encoding'));

    // 根据数据类型创建对应的对象
    case DataType of
      fdtByteFrequency:
        begin
          var ByteFreqData := TByteFrequencyFeatureData.Create(Encoding);

          ByteFreqData.ID := JsonObj.GetValue<Integer>('id');
          ByteFreqData.Description := JsonObj.GetValue<string>('description');

          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            ByteFreqData.LastUpdated := StrToDateTime(LastUpdatedStr);

          var ByteValues := JsonObj.GetValue<TJSONArray>('byte_values');
          if ByteValues <> nil then
          begin
            for I := 0 to Min(255, ByteValues.Count - 1) do
            begin
              TempValue := ByteValues.Items[I].GetValue<Double>;
              var TempData := ByteFreqData.Data;
              TempData.ByteValues[I] := TempValue;
              ByteFreqData.Data := TempData;
            end;
          end;

          Result := ByteFreqData;
        end;

      fdtCharFrequency:
        begin
          var CharFreqData := TCharFrequencyFeatureData.Create(Encoding);

          CharFreqData.ID := JsonObj.GetValue<Integer>('id');
          CharFreqData.Description := JsonObj.GetValue<string>('description');

          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            CharFreqData.LastUpdated := StrToDateTime(LastUpdatedStr);

          var CharData := JsonObj.GetValue<TJSONObject>('char_data');
          if CharData <> nil then
          begin
            var TempData := CharFreqData.Data;

            TempUInt32 := CharData.GetValue<UInt32>('char_code');
            TempData.CharCode := TempUInt32;

            TempByte := CharData.GetValue<Byte>('first_byte');
            TempData.FirstByte := TempByte;

            TempByte := CharData.GetValue<Byte>('second_byte');
            TempData.SecondByte := TempByte;

            TempByte := CharData.GetValue<Byte>('third_byte');
            TempData.ThirdByte := TempByte;

            TempByte := CharData.GetValue<Byte>('fourth_byte');
            TempData.FourthByte := TempByte;

            TempValue := CharData.GetValue<Double>('frequency');
            TempData.Frequency := TempValue;

            TempString := CharData.GetValue<string>('character');
            TempData.Character := TempString;

            TempInt := CharData.GetValue<Integer>('char_type');
            TempData.CharType := TCharType(TempInt);

            TempString := CharData.GetValue<string>('description');
            TempData.Description := TempString;

            CharFreqData.Data := TempData;
          end;

          Result := CharFreqData;
        end;

      // 其他类型的数据反序列化...
    end;
  finally
    JsonObj.Free;
  end;
end;

function TFileFeatureDataStorage.SaveFeatureData(AData: TFeatureData): Boolean;
var
  FileName: string;
  DataFile: TStringList;
begin
  if AData = nil then
    Exit(False);

  // 如果数据没有ID，分配一个新ID
  if AData.ID <= 0 then
  begin
    AData.ID := FNextID;
    Inc(FNextID);
  end;

  // 更新最后修改时间
  AData.LastUpdated := Now;

  // 获取数据文件名
  FileName := GetDataFileName(AData.ID);

  // 序列化数据
  DataFile := TStringList.Create;
  try
    DataFile.Text := SerializeFeatureData(AData);
    DataFile.SaveToFile(FileName);

    // 更新索引
    FDataIndex.AddOrSetValue(AData.ID, ExtractFileName(FileName));

    // 保存索引
    SaveIndex;

    Result := True;
  finally
    DataFile.Free;
  end;
end;

function TFileFeatureDataStorage.LoadFeatureData(AID: Integer): TFeatureData;
var
  FileName: string;
  DataFile: TStringList;
begin
  Result := nil;

  // 检查ID是否存在
  if not FDataIndex.TryGetValue(AID, FileName) then
    Exit;

  // 获取完整文件名
  FileName := TPath.Combine(FStorageDirectory, FileName);

  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit;

  // 加载数据
  DataFile := TStringList.Create;
  try
    DataFile.LoadFromFile(FileName);
    Result := DeserializeFeatureData(DataFile.Text);
  finally
    DataFile.Free;
  end;
end;

function TFileFeatureDataStorage.DeleteFeatureData(AID: Integer): Boolean;
var
  FileName: string;
begin
  // 检查ID是否存在
  if not FDataIndex.TryGetValue(AID, FileName) then
    Exit(False);

  // 获取完整文件名
  FileName := TPath.Combine(FStorageDirectory, FileName);

  // 删除文件
  if FileExists(FileName) then
    DeleteFile(FileName);

  // 更新索引
  FDataIndex.Remove(AID);

  // 保存索引
  SaveIndex;

  Result := True;
end;

function TFileFeatureDataStorage.QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
var
  ID: Integer;
  Data: TFeatureData;
begin
  Result := TFeatureDataCollection.Create(AEncoding, ADataType);

  for ID in FDataIndex.Keys do
  begin
    Data := LoadFeatureData(ID);
    if (Data <> nil) and (Data.Encoding = AEncoding) and (Data.DataType = ADataType) then
      Result.Add(Data);
  end;
end;

procedure TFileFeatureDataStorage.ClearFeatureData;
var
  ID: Integer;
  FileName: string;
begin
  // 删除所有数据文件
  for ID in FDataIndex.Keys do
  begin
    if FDataIndex.TryGetValue(ID, FileName) then
    begin
      FileName := TPath.Combine(FStorageDirectory, FileName);
      if FileExists(FileName) then
        DeleteFile(FileName);
    end;
  end;

  // 清空索引
  FDataIndex.Clear;
  FNextID := 1;

  // 保存索引
  SaveIndex;
end;

function TFileFeatureDataStorage.GetFeatureDataCount: Integer;
begin
  Result := FDataIndex.Count;
end;

function TFileFeatureDataStorage.GetFeatureDataIDs: TArray<Integer>;
begin
  Result := FDataIndex.Keys.ToArray;
end;

function TFileFeatureDataStorage.FeatureDataExists(AID: Integer): Boolean;
begin
  Result := FDataIndex.ContainsKey(AID);
end;

{ TDatabaseFeatureDataStorage }

constructor TDatabaseFeatureDataStorage.Create(const AConnectionString: string);
begin
  inherited Create;
  FConnectionString := AConnectionString;

  // 创建数据库表
  CreateTables;
end;

destructor TDatabaseFeatureDataStorage.Destroy;
begin
  inherited;
end;

procedure TDatabaseFeatureDataStorage.CreateTables;
begin
  // 在实际实现中，这里应该创建数据库表
  // 例如：
  // CREATE TABLE feature_data (
  //   id INTEGER PRIMARY KEY,
  //   data_type INTEGER,
  //   encoding INTEGER,
  //   description TEXT,
  //   last_updated DATETIME,
  //   data_json TEXT
  // );
end;

function TDatabaseFeatureDataStorage.SerializeFeatureData(AData: TFeatureData): string;
begin
  // 在实际实现中，这里应该序列化特征数据为JSON
  Result := '';
end;

function TDatabaseFeatureDataStorage.DeserializeFeatureData(const AJson: string; ADataType: TFeatureDataType; AEncoding: TChineseEncodingType): TFeatureData;
begin
  // 在实际实现中，这里应该反序列化JSON为特征数据
  Result := nil;
end;

function TDatabaseFeatureDataStorage.SaveFeatureData(AData: TFeatureData): Boolean;
begin
  // 在实际实现中，这里应该保存特征数据到数据库
  Result := False;
end;

function TDatabaseFeatureDataStorage.LoadFeatureData(AID: Integer): TFeatureData;
begin
  // 在实际实现中，这里应该从数据库加载特征数据
  Result := nil;
end;

function TDatabaseFeatureDataStorage.DeleteFeatureData(AID: Integer): Boolean;
begin
  // 在实际实现中，这里应该从数据库删除特征数据
  Result := False;
end;

function TDatabaseFeatureDataStorage.QueryFeatureData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
begin
  // 在实际实现中，这里应该从数据库查询特征数据
  Result := TFeatureDataCollection.Create(AEncoding, ADataType);
end;

procedure TDatabaseFeatureDataStorage.ClearFeatureData;
begin
  // 在实际实现中，这里应该清空数据库中的特征数据
end;

function TDatabaseFeatureDataStorage.GetFeatureDataCount: Integer;
begin
  // 在实际实现中，这里应该返回数据库中的特征数据数量
  Result := 0;
end;

function TDatabaseFeatureDataStorage.GetFeatureDataIDs: TArray<Integer>;
begin
  // 在实际实现中，这里应该返回数据库中的特征数据ID列表
  SetLength(Result, 0);
end;

function TDatabaseFeatureDataStorage.FeatureDataExists(AID: Integer): Boolean;
begin
  // 在实际实现中，这里应该检查数据库中是否存在指定ID的特征数据
  Result := False;
end;

{ TFeatureDataStorageFactory }

class function TFeatureDataStorageFactory.CreateMemoryStorage: IFeatureDataStorage;
begin
  Result := TMemoryFeatureDataStorage.Create;
end;

class function TFeatureDataStorageFactory.CreateFileStorage(const AStorageDirectory: string): IFeatureDataStorage;
begin
  Result := TFileFeatureDataStorage.Create(AStorageDirectory);
end;

class function TFeatureDataStorageFactory.CreateDatabaseStorage(const AConnectionString: string): IFeatureDataStorage;
begin
  Result := TDatabaseFeatureDataStorage.Create(AConnectionString);
end;

end.
