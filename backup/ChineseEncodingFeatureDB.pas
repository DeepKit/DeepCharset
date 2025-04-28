unit ChineseEncodingFeatureDB;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  ChineseEncodingFeatureDB.Types,
  ChineseEncodingFeatureDB.Storage,
  ChineseEncodingFeatureDB.Index,
  ChineseEncodingFeatureDB.Serialization,
  ChineseEncodingFeatureDB.Loader,
  ChineseEncodingFeatureDB.Matcher,
  ChineseEncodingFeatureDB.Updater;

type
  // 特征数据库接口
  IChineseEncodingFeatureDB = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    // 获取存储接口
    function GetStorage: IFeatureDataStorage;
    
    // 获取索引接口
    function GetIndex: IFeatureDataIndex;
    
    // 获取加载器接口
    function GetLoader: IFeatureDataLoader;
    
    // 获取匹配器接口
    function GetMatcher: IFeatureMatcher;
    
    // 获取更新器接口
    function GetUpdater: IFeatureDataUpdater;
    
    // 初始化数据库
    procedure Initialize;
    
    // 加载内置数据
    procedure LoadBuiltInData;
    
    // 获取支持的编码类型列表
    function GetSupportedEncodings: TArray<TChineseEncodingType>;
    
    // 获取支持的特征类型列表
    function GetSupportedFeatureTypes: TArray<TFeatureDataType>;
    
    // 查询特征数据
    function QueryData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
    
    // 加载特定特征数据
    function LoadData(AID: Integer): TFeatureData;
    
    // 保存特征数据
    function SaveData(AData: TFeatureData): Boolean;
    
    // 删除特征数据
    function DeleteData(AID: Integer): Boolean;
    
    // 属性访问
    property Storage: IFeatureDataStorage read GetStorage;
    property Index: IFeatureDataIndex read GetIndex;
    property Loader: IFeatureDataLoader read GetLoader;
    property Matcher: IFeatureMatcher read GetMatcher;
    property Updater: IFeatureDataUpdater read GetUpdater;
  end;

  // 特征数据库实现
  TChineseEncodingFeatureDB = class(TInterfacedObject, IChineseEncodingFeatureDB)
  private
    FStorage: IFeatureDataStorage;
    FIndex: IFeatureDataIndex;
    FLoader: IFeatureDataLoader;
    FMatcher: IFeatureMatcher;
    FUpdater: IFeatureDataUpdater;
    
    // 实现接口的属性访问方法
    function GetStorage: IFeatureDataStorage;
    function GetIndex: IFeatureDataIndex;
    function GetLoader: IFeatureDataLoader;
    function GetMatcher: IFeatureMatcher;
    function GetUpdater: IFeatureDataUpdater;
  public
    constructor Create(const AStorageType: string = 'memory'); 
    destructor Destroy; override;
    
    // 实现IChineseEncodingFeatureDB接口方法
    procedure Initialize;
    procedure LoadBuiltInData;
    function GetSupportedEncodings: TArray<TChineseEncodingType>;
    function GetSupportedFeatureTypes: TArray<TFeatureDataType>;
    function QueryData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
    function LoadData(AID: Integer): TFeatureData;
    function SaveData(AData: TFeatureData): Boolean;
    function DeleteData(AID: Integer): Boolean;
  end;

// 创建特征数据库的工厂函数
function CreateChineseEncodingFeatureDB(const AStorageType: string = 'memory'): IChineseEncodingFeatureDB;

// 获取编码类型的显示名称
function EncodingTypeToString(AEncoding: TChineseEncodingType): string;

// 获取特征数据类型的显示名称
function FeatureDataTypeToString(ADataType: TFeatureDataType): string;

implementation

uses
  System.StrUtils;

// 创建特征数据库的工厂函数
function CreateChineseEncodingFeatureDB(const AStorageType: string): IChineseEncodingFeatureDB;
begin
  Result := TChineseEncodingFeatureDB.Create(AStorageType);
end;

// 获取编码类型的显示名称
function EncodingTypeToString(AEncoding: TChineseEncodingType): string;
begin
  case AEncoding of
    cetGB18030: Result := 'GB18030';
    cetGBK: Result := 'GBK';
    cetGB2312: Result := 'GB2312';
    cetBig5: Result := 'Big5';
    cetBig5HKSCS: Result := 'Big5-HKSCS';
    cetUTF8: Result := 'UTF-8';
    cetUTF16LE: Result := 'UTF-16 LE';
    cetUTF16BE: Result := 'UTF-16 BE';
    cetUTF32LE: Result := 'UTF-32 LE';
    cetUTF32BE: Result := 'UTF-32 BE';
    cetUnknown: Result := '未知编码';
    else Result := '未定义编码';
  end;
end;

// 获取特征数据类型的显示名称
function FeatureDataTypeToString(ADataType: TFeatureDataType): string;
begin
  case ADataType of
    fdtByteFrequency: Result := '字节频率';
    fdtCharFrequency: Result := '字符频率';
    fdtBytePair: Result := '字节对';
    fdtRegion: Result := '区域特征';
    fdtSpecialChar: Result := '特殊字符';
    fdtLanguageFeature: Result := '语言特征';
    fdtOther: Result := '其他特征';
    else Result := '未定义特征';
  end;
end;

{ TChineseEncodingFeatureDB }

constructor TChineseEncodingFeatureDB.Create(const AStorageType: string);
begin
  inherited Create;
  
  // 创建存储对象
  if SameText(AStorageType, 'file') then
  begin
    var StorageDir := ExtractFilePath(ParamStr(0)) + 'FeatureDB';
    FStorage := TFeatureDataStorageFactory.CreateFileStorage(StorageDir);
  end
  else if SameText(AStorageType, 'database') then
  begin
    var ConnStr := 'FeatureDB.db';
    FStorage := TFeatureDataStorageFactory.CreateDatabaseStorage(ConnStr);
  end
  else
  begin
    // 默认使用内存存储
    FStorage := TFeatureDataStorageFactory.CreateMemoryStorage;
  end;
  
  // 创建索引对象
  FIndex := TFeatureDataIndexFactory.CreateMemoryIndex;
  
  // 创建加载器对象
  FLoader := TFeatureDataLoaderFactory.CreateBaseLoader(FStorage);
  
  // 创建匹配器对象
  FMatcher := TFeatureMatcherFactory.CreateMatcher(FStorage);
  
  // 创建更新器对象
  FUpdater := TFeatureDataUpdaterFactory.CreateUpdater(FStorage);
end;

destructor TChineseEncodingFeatureDB.Destroy;
begin
  inherited;
end;

function TChineseEncodingFeatureDB.GetStorage: IFeatureDataStorage;
begin
  Result := FStorage;
end;

function TChineseEncodingFeatureDB.GetIndex: IFeatureDataIndex;
begin
  Result := FIndex;
end;

function TChineseEncodingFeatureDB.GetLoader: IFeatureDataLoader;
begin
  Result := FLoader;
end;

function TChineseEncodingFeatureDB.GetMatcher: IFeatureMatcher;
begin
  Result := FMatcher;
end;

function TChineseEncodingFeatureDB.GetUpdater: IFeatureDataUpdater;
begin
  Result := FUpdater;
end;

procedure TChineseEncodingFeatureDB.Initialize;
begin
  // 加载内置数据
  LoadBuiltInData;
end;

procedure TChineseEncodingFeatureDB.LoadBuiltInData;
begin
  // 使用加载器加载内置数据
  FLoader.LoadBuiltInData;
end;

function TChineseEncodingFeatureDB.GetSupportedEncodings: TArray<TChineseEncodingType>;
begin
  // 返回所有支持的编码类型
  SetLength(Result, 11);
  Result[0] := cetGB18030;
  Result[1] := cetGBK;
  Result[2] := cetGB2312;
  Result[3] := cetBig5;
  Result[4] := cetBig5HKSCS;
  Result[5] := cetUTF8;
  Result[6] := cetUTF16LE;
  Result[7] := cetUTF16BE;
  Result[8] := cetUTF32LE;
  Result[9] := cetUTF32BE;
  Result[10] := cetUnknown;
end;

function TChineseEncodingFeatureDB.GetSupportedFeatureTypes: TArray<TFeatureDataType>;
begin
  // 返回所有支持的特征数据类型
  SetLength(Result, 7);
  Result[0] := fdtByteFrequency;
  Result[1] := fdtCharFrequency;
  Result[2] := fdtBytePair;
  Result[3] := fdtRegion;
  Result[4] := fdtSpecialChar;
  Result[5] := fdtLanguageFeature;
  Result[6] := fdtOther;
end;

function TChineseEncodingFeatureDB.QueryData(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType): TFeatureDataCollection;
begin
  // 使用存储对象查询特征数据
  Result := FStorage.QueryFeatureData(AEncoding, ADataType);
end;

function TChineseEncodingFeatureDB.LoadData(AID: Integer): TFeatureData;
begin
  // 使用存储对象加载特征数据
  Result := FStorage.LoadFeatureData(AID);
end;

function TChineseEncodingFeatureDB.SaveData(AData: TFeatureData): Boolean;
begin
  // 使用存储对象保存特征数据
  Result := FStorage.SaveFeatureData(AData);
end;

function TChineseEncodingFeatureDB.DeleteData(AID: Integer): Boolean;
begin
  // 使用存储对象删除特征数据
  Result := FStorage.DeleteFeatureData(AID);
end;

end. 