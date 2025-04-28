unit ChineseEncodingFeatureDB.Serialization;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  ChineseEncodingFeatureDB.Types;

type
  // 序列化格式类型
  TSerializationFormat = (
    sfJSON,     // JSON格式
    sfXML,      // XML格式
    sfBinary,   // 二进制格式
    sfCustom    // 自定义格式
  );

  // 序列化接口
  IFeatureDataSerializer = interface
    ['{D1E2F3A4-B5C6-4D5E-9F8A-1B2C3D4E5F6A}']
    // 序列化特征数据
    function Serialize(AData: TFeatureData): string;
    
    // 反序列化特征数据
    function Deserialize(const ASerializedData: string): TFeatureData;
    
    // 获取序列化格式
    function GetFormat: TSerializationFormat;
  end;

  // JSON序列化器
  TJSONFeatureDataSerializer = class(TInterfacedObject, IFeatureDataSerializer)
  public
    // 实现IFeatureDataSerializer接口
    function Serialize(AData: TFeatureData): string;
    function Deserialize(const ASerializedData: string): TFeatureData;
    function GetFormat: TSerializationFormat;
  end;

  // XML序列化器
  TXMLFeatureDataSerializer = class(TInterfacedObject, IFeatureDataSerializer)
  public
    // 实现IFeatureDataSerializer接口
    function Serialize(AData: TFeatureData): string;
    function Deserialize(const ASerializedData: string): TFeatureData;
    function GetFormat: TSerializationFormat;
  end;

  // 二进制序列化器
  TBinaryFeatureDataSerializer = class(TInterfacedObject, IFeatureDataSerializer)
  public
    // 实现IFeatureDataSerializer接口
    function Serialize(AData: TFeatureData): string;
    function Deserialize(const ASerializedData: string): TFeatureData;
    function GetFormat: TSerializationFormat;
  end;

  // 序列化器工厂
  TFeatureDataSerializerFactory = class
  public
    // 创建JSON序列化器
    class function CreateJSONSerializer: IFeatureDataSerializer;
    
    // 创建XML序列化器
    class function CreateXMLSerializer: IFeatureDataSerializer;
    
    // 创建二进制序列化器
    class function CreateBinarySerializer: IFeatureDataSerializer;
  end;

implementation

{ TJSONFeatureDataSerializer }

function TJSONFeatureDataSerializer.Serialize(AData: TFeatureData): string;
var
  JsonObj: TJSONObject;
begin
  if AData = nil then
    Exit('');
  
  JsonObj := TJSONObject.Create;
  try
    // 序列化基本信息
    JsonObj.AddPair('id', TJSONNumber.Create(AData.ID));
    JsonObj.AddPair('data_type', TJSONNumber.Create(Ord(AData.DataType)));
    JsonObj.AddPair('encoding', TJSONNumber.Create(Ord(AData.Encoding)));
    JsonObj.AddPair('description', AData.Description);
    JsonObj.AddPair('last_updated', FormatDateTime('yyyy-mm-dd hh:nn:ss', AData.LastUpdated));
    
    // 序列化特定类型的数据
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
      
      fdtBytePair:
        begin
          var BytePairData := AData as TBytePairFreatureData;
          var PairData := TJSONObject.Create;
          
          PairData.AddPair('first_byte', TJSONNumber.Create(BytePairData.Data.FirstByte));
          PairData.AddPair('second_byte', TJSONNumber.Create(BytePairData.Data.SecondByte));
          PairData.AddPair('frequency', TJSONNumber.Create(BytePairData.Data.Frequency));
          
          JsonObj.AddPair('byte_pair_data', PairData);
        end;
      
      fdtRegion:
        begin
          var RegionData := AData as TRegionFeatureData;
          var RegData := TJSONObject.Create;
          
          RegData.AddPair('region_type', TJSONNumber.Create(Ord(RegionData.Data.RegionType)));
          RegData.AddPair('start_range', TJSONNumber.Create(RegionData.Data.StartRange));
          RegData.AddPair('end_range', TJSONNumber.Create(RegionData.Data.EndRange));
          RegData.AddPair('description', RegionData.Data.Description);
          
          JsonObj.AddPair('region_data', RegData);
        end;
      
      fdtSpecialChar:
        begin
          var SpecialCharData := AData as TSpecialCharFeatureData;
          var CharData := TJSONObject.Create;
          
          CharData.AddPair('char_type', TJSONNumber.Create(Ord(SpecialCharData.Data.CharType)));
          CharData.AddPair('char_code', TJSONNumber.Create(SpecialCharData.Data.CharCode));
          CharData.AddPair('first_byte', TJSONNumber.Create(SpecialCharData.Data.FirstByte));
          CharData.AddPair('second_byte', TJSONNumber.Create(SpecialCharData.Data.SecondByte));
          CharData.AddPair('third_byte', TJSONNumber.Create(SpecialCharData.Data.ThirdByte));
          CharData.AddPair('fourth_byte', TJSONNumber.Create(SpecialCharData.Data.FourthByte));
          CharData.AddPair('character', SpecialCharData.Data.Character);
          CharData.AddPair('description', SpecialCharData.Data.Description);
          
          JsonObj.AddPair('special_char_data', CharData);
        end;
      
      fdtLanguageFeature:
        begin
          var LangFeatureData := AData as TLanguageFeatureFeatureData;
          var FeatureData := TJSONObject.Create;
          
          FeatureData.AddPair('feature_type', TJSONNumber.Create(Ord(LangFeatureData.Data.FeatureType)));
          FeatureData.AddPair('content', LangFeatureData.Data.Content);
          FeatureData.AddPair('frequency', TJSONNumber.Create(LangFeatureData.Data.Frequency));
          FeatureData.AddPair('description', LangFeatureData.Data.Description);
          
          // 编码字节序列
          var BytesArray := TJSONArray.Create;
          for var I := 0 to Length(LangFeatureData.Data.EncodedBytes) - 1 do
            BytesArray.AddElement(TJSONNumber.Create(LangFeatureData.Data.EncodedBytes[I]));
          
          FeatureData.AddPair('encoded_bytes', BytesArray);
          
          JsonObj.AddPair('language_feature_data', FeatureData);
        end;
    end;
    
    Result := JsonObj.ToJSON;
  finally
    JsonObj.Free;
  end;
end;

function TJSONFeatureDataSerializer.Deserialize(const ASerializedData: string): TFeatureData;
var
  JsonObj: TJSONObject;
  DataType: TFeatureDataType;
  Encoding: TChineseEncodingType;
begin
  Result := nil;
  
  if ASerializedData.IsEmpty then
    Exit;
  
  JsonObj := TJSONObject.ParseJSONValue(ASerializedData) as TJSONObject;
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
            for var I := 0 to Min(255, ByteValues.Count - 1) do
              ByteFreqData.Data.ByteValues[I] := ByteValues.Items[I].GetValue<Double>;
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
            CharFreqData.Data.CharCode := CharData.GetValue<UInt32>('char_code');
            CharFreqData.Data.FirstByte := CharData.GetValue<Byte>('first_byte');
            CharFreqData.Data.SecondByte := CharData.GetValue<Byte>('second_byte');
            CharFreqData.Data.ThirdByte := CharData.GetValue<Byte>('third_byte');
            CharFreqData.Data.FourthByte := CharData.GetValue<Byte>('fourth_byte');
            CharFreqData.Data.Frequency := CharData.GetValue<Double>('frequency');
            CharFreqData.Data.Character := CharData.GetValue<string>('character');
            CharFreqData.Data.CharType := TCharType(CharData.GetValue<Integer>('char_type'));
            CharFreqData.Data.Description := CharData.GetValue<string>('description');
          end;
          
          Result := CharFreqData;
        end;
      
      fdtBytePair:
        begin
          var BytePairData := TBytePairFreatureData.Create(Encoding);
          
          BytePairData.ID := JsonObj.GetValue<Integer>('id');
          BytePairData.Description := JsonObj.GetValue<string>('description');
          
          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            BytePairData.LastUpdated := StrToDateTime(LastUpdatedStr);
          
          var PairData := JsonObj.GetValue<TJSONObject>('byte_pair_data');
          if PairData <> nil then
          begin
            BytePairData.Data.FirstByte := PairData.GetValue<Byte>('first_byte');
            BytePairData.Data.SecondByte := PairData.GetValue<Byte>('second_byte');
            BytePairData.Data.Frequency := PairData.GetValue<Double>('frequency');
          end;
          
          Result := BytePairData;
        end;
      
      fdtRegion:
        begin
          var RegionData := TRegionFeatureData.Create(Encoding);
          
          RegionData.ID := JsonObj.GetValue<Integer>('id');
          RegionData.Description := JsonObj.GetValue<string>('description');
          
          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            RegionData.LastUpdated := StrToDateTime(LastUpdatedStr);
          
          var RegData := JsonObj.GetValue<TJSONObject>('region_data');
          if RegData <> nil then
          begin
            RegionData.Data.RegionType := TRegionType(RegData.GetValue<Integer>('region_type'));
            RegionData.Data.StartRange := RegData.GetValue<UInt32>('start_range');
            RegionData.Data.EndRange := RegData.GetValue<UInt32>('end_range');
            RegionData.Data.Description := RegData.GetValue<string>('description');
          end;
          
          Result := RegionData;
        end;
      
      fdtSpecialChar:
        begin
          var SpecialCharData := TSpecialCharFeatureData.Create(Encoding);
          
          SpecialCharData.ID := JsonObj.GetValue<Integer>('id');
          SpecialCharData.Description := JsonObj.GetValue<string>('description');
          
          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            SpecialCharData.LastUpdated := StrToDateTime(LastUpdatedStr);
          
          var CharData := JsonObj.GetValue<TJSONObject>('special_char_data');
          if CharData <> nil then
          begin
            SpecialCharData.Data.CharType := TSpecialCharType(CharData.GetValue<Integer>('char_type'));
            SpecialCharData.Data.CharCode := CharData.GetValue<UInt32>('char_code');
            SpecialCharData.Data.FirstByte := CharData.GetValue<Byte>('first_byte');
            SpecialCharData.Data.SecondByte := CharData.GetValue<Byte>('second_byte');
            SpecialCharData.Data.ThirdByte := CharData.GetValue<Byte>('third_byte');
            SpecialCharData.Data.FourthByte := CharData.GetValue<Byte>('fourth_byte');
            SpecialCharData.Data.Character := CharData.GetValue<string>('character');
            SpecialCharData.Data.Description := CharData.GetValue<string>('description');
          end;
          
          Result := SpecialCharData;
        end;
      
      fdtLanguageFeature:
        begin
          var LangFeatureData := TLanguageFeatureFeatureData.Create(Encoding);
          
          LangFeatureData.ID := JsonObj.GetValue<Integer>('id');
          LangFeatureData.Description := JsonObj.GetValue<string>('description');
          
          var LastUpdatedStr := JsonObj.GetValue<string>('last_updated');
          if not LastUpdatedStr.IsEmpty then
            LangFeatureData.LastUpdated := StrToDateTime(LastUpdatedStr);
          
          var FeatureData := JsonObj.GetValue<TJSONObject>('language_feature_data');
          if FeatureData <> nil then
          begin
            LangFeatureData.Data.FeatureType := TLanguageFeatureType(FeatureData.GetValue<Integer>('feature_type'));
            LangFeatureData.Data.Content := FeatureData.GetValue<string>('content');
            LangFeatureData.Data.Frequency := FeatureData.GetValue<Double>('frequency');
            LangFeatureData.Data.Description := FeatureData.GetValue<string>('description');
            
            // 编码字节序列
            var BytesArray := FeatureData.GetValue<TJSONArray>('encoded_bytes');
            if BytesArray <> nil then
            begin
              SetLength(LangFeatureData.Data.EncodedBytes, BytesArray.Count);
              for var I := 0 to BytesArray.Count - 1 do
                LangFeatureData.Data.EncodedBytes[I] := BytesArray.Items[I].GetValue<Byte>;
            end;
          end;
          
          Result := LangFeatureData;
        end;
    end;
  finally
    JsonObj.Free;
  end;
end;

function TJSONFeatureDataSerializer.GetFormat: TSerializationFormat;
begin
  Result := sfJSON;
end;

{ TXMLFeatureDataSerializer }

function TXMLFeatureDataSerializer.Serialize(AData: TFeatureData): string;
begin
  // 在实际实现中，这里应该序列化特征数据为XML
  Result := '';
end;

function TXMLFeatureDataSerializer.Deserialize(const ASerializedData: string): TFeatureData;
begin
  // 在实际实现中，这里应该反序列化XML为特征数据
  Result := nil;
end;

function TXMLFeatureDataSerializer.GetFormat: TSerializationFormat;
begin
  Result := sfXML;
end;

{ TBinaryFeatureDataSerializer }

function TBinaryFeatureDataSerializer.Serialize(AData: TFeatureData): string;
begin
  // 在实际实现中，这里应该序列化特征数据为二进制格式
  Result := '';
end;

function TBinaryFeatureDataSerializer.Deserialize(const ASerializedData: string): TFeatureData;
begin
  // 在实际实现中，这里应该反序列化二进制格式为特征数据
  Result := nil;
end;

function TBinaryFeatureDataSerializer.GetFormat: TSerializationFormat;
begin
  Result := sfBinary;
end;

{ TFeatureDataSerializerFactory }

class function TFeatureDataSerializerFactory.CreateJSONSerializer: IFeatureDataSerializer;
begin
  Result := TJSONFeatureDataSerializer.Create;
end;

class function TFeatureDataSerializerFactory.CreateXMLSerializer: IFeatureDataSerializer;
begin
  Result := TXMLFeatureDataSerializer.Create;
end;

class function TFeatureDataSerializerFactory.CreateBinarySerializer: IFeatureDataSerializer;
begin
  Result := TBinaryFeatureDataSerializer.Create;
end;

end.
