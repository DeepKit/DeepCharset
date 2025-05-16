program ChineseEncodingFeatureDBDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  ChineseEncodingFeatureDB.Types in 'ChineseEncodingFeatureDB.Types.pas',
  ChineseEncodingFeatureDB.Storage in 'ChineseEncodingFeatureDB.Storage.pas',
  ChineseEncodingFeatureDB.Index in 'ChineseEncodingFeatureDB.Index.pas',
  ChineseEncodingFeatureDB.Serialization in 'ChineseEncodingFeatureDB.Serialization.pas',
  ChineseEncodingFeatureDB.Loader in 'ChineseEncodingFeatureDB.Loader.pas',
  ChineseEncodingFeatureDB.Matcher in 'ChineseEncodingFeatureDB.Matcher.pas',
  ChineseEncodingFeatureDB.Updater in 'ChineseEncodingFeatureDB.Updater.pas',
  ChineseEncodingFeatureDB in 'ChineseEncodingFeatureDB.pas';

// 加载进度事件处理
procedure HandleLoadProgress(Sender: TObject; Current, Total: Integer; State: TLoaderState);
begin
  case State of
    lsIdle: Writeln('状态: 空闲');
    lsLoading: Writeln('状态: 正在加载, 进度: ', Current, '/', Total);
    lsVerifying: Writeln('状态: 正在验证, 进度: ', Current, '/', Total);
    lsMerging: Writeln('状态: 正在合并, 进度: ', Current, '/', Total);
    lsCompleted: Writeln('状态: 完成, 进度: ', Current, '/', Total);
    lsError: Writeln('状态: 错误, 进度: ', Current, '/', Total);
  end;
end;

// 加载完成事件处理
procedure HandleLoadCompleted(Sender: TObject; const Result: TLoadResult);
begin
  Writeln('加载完成:');
  Writeln('  成功: ', Result.Success);
  if not Result.ErrorMessage.IsEmpty then
    Writeln('  错误: ', Result.ErrorMessage);
  Writeln('  已加载项: ', Result.LoadedItems);
  Writeln('  已跳过项: ', Result.SkippedItems);
  Writeln('  无效项: ', Result.InvalidItems);
  Writeln('  耗时(毫秒): ', Result.Duration);
end;

// 更新进度事件处理
procedure HandleUpdateProgress(Sender: TObject; Current, Total: Integer; State: TUpdaterState);
begin
  case State of
    usIdle: Writeln('状态: 空闲');
    usUpdating: Writeln('状态: 正在更新, 进度: ', Current, '/', Total);
    usCompleted: Writeln('状态: 完成, 进度: ', Current, '/', Total);
    usError: Writeln('状态: 错误, 进度: ', Current, '/', Total);
  end;
end;

// 更新完成事件处理
procedure HandleUpdateCompleted(Sender: TObject; const Result: TUpdateResult);
begin
  Writeln('更新完成:');
  Writeln('  成功: ', Result.Success);
  if not Result.ErrorMessage.IsEmpty then
    Writeln('  错误: ', Result.ErrorMessage);
  Writeln('  已更新项: ', Result.UpdatedItems);
  Writeln('  已跳过项: ', Result.SkippedItems);
  Writeln('  耗时(毫秒): ', Result.Duration);
end;

// 打印数据库信息
procedure PrintDatabaseInfo(FeatureDB: IChineseEncodingFeatureDB);
var
  Count: Integer;
begin
  Count := FeatureDB.Storage.GetFeatureDataCount;
  Writeln('数据库信息:');
  Writeln('  特征数据数量: ', Count);
  
  // 打印所有支持的编码类型
  Writeln('  支持的编码类型:');
  for var Encoding in FeatureDB.GetSupportedEncodings do
    Writeln('    ', EncodingTypeToString(Encoding));
  
  // 打印所有支持的特征类型
  Writeln('  支持的特征类型:');
  for var DataType in FeatureDB.GetSupportedFeatureTypes do
    Writeln('    ', FeatureDataTypeToString(DataType));
end;

// 打印GB18030字节频率数据
procedure PrintGB18030ByteFrequencyData(FeatureDB: IChineseEncodingFeatureDB);
var
  DataCollection: TFeatureDataCollection;
  ByteFreqData: TByteFrequencyFeatureData;
  i: Integer;
begin
  Writeln('GB18030字节频率数据:');
  
  // 查询GB18030的字节频率数据
  DataCollection := FeatureDB.QueryData(cetGB18030, fdtByteFrequency);
  try
    if (DataCollection = nil) or (DataCollection.Count = 0) then
    begin
      Writeln('  没有找到GB18030字节频率数据');
      Exit;
    end;
    
    // 显示第一个数据
    ByteFreqData := DataCollection.GetItem(0) as TByteFrequencyFeatureData;
    Writeln('  ID: ', ByteFreqData.ID);
    Writeln('  描述: ', ByteFreqData.Description);
    Writeln('  最后更新时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', ByteFreqData.LastUpdated));
    
    // 显示前10个高频字节
    Writeln('  前10个高频字节:');
    var TopBytes: array[0..9] of record
      ByteValue: Byte;
      Frequency: Double;
    end;
    
    // 初始化
    for i := 0 to 9 do
    begin
      TopBytes[i].ByteValue := 0;
      TopBytes[i].Frequency := 0.0;
    end;
    
    // 找出最高频的字节
    for i := 0 to 255 do
    begin
      var Freq := ByteFreqData.Data.ByteValues[i];
      var MinIndex := 0;
      var MinFreq := TopBytes[0].Frequency;
      
      // 找出当前最小频率的索引
      for var j := 1 to 9 do
      begin
        if TopBytes[j].Frequency < MinFreq then
        begin
          MinIndex := j;
          MinFreq := TopBytes[j].Frequency;
        end;
      end;
      
      // 如果当前字节频率高于最小的，则替换
      if Freq > MinFreq then
      begin
        TopBytes[MinIndex].ByteValue := i;
        TopBytes[MinIndex].Frequency := Freq;
      end;
    end;
    
    // 按频率排序
    for i := 0 to 8 do
    begin
      for var j := i + 1 to 9 do
      begin
        if TopBytes[i].Frequency < TopBytes[j].Frequency then
        begin
          var Temp := TopBytes[i];
          TopBytes[i] := TopBytes[j];
          TopBytes[j] := Temp;
        end;
      end;
    end;
    
    // 输出结果
    for i := 0 to 9 do
    begin
      if TopBytes[i].Frequency > 0 then
        Writeln(Format('    0x%2.2X: %.6f', [TopBytes[i].ByteValue, TopBytes[i].Frequency]));
    end;
  finally
    DataCollection.Free;
  end;
end;

// 添加自定义特征数据
procedure AddCustomFeatureData(FeatureDB: IChineseEncodingFeatureDB);
var
  CharFreqData: TCharFrequencyFeatureData;
begin
  Writeln('添加自定义特征数据:');
  
  // 创建一个汉字字符频率数据
  CharFreqData := TCharFrequencyFeatureData.Create(cetGB18030);
  try
    CharFreqData.Description := '自定义汉字字符频率数据';
    CharFreqData.LastUpdated := Now;
    
    // 设置"中"字的数据
    CharFreqData.Data.CharCode := $4E2D; // 中
    CharFreqData.Data.FirstByte := $D6;
    CharFreqData.Data.SecondByte := $D0;
    CharFreqData.Data.ThirdByte := 0;
    CharFreqData.Data.FourthByte := 0;
    CharFreqData.Data.Frequency := 0.0289;
    CharFreqData.Data.Character := '中';
    CharFreqData.Data.CharType := ctCommon;
    CharFreqData.Data.Description := '常用汉字"中"';
    
    // 保存到数据库
    if FeatureDB.SaveData(CharFreqData) then
      Writeln('  添加成功，ID: ', CharFreqData.ID)
    else
      Writeln('  添加失败');
  finally
    CharFreqData.Free;
  end;
end;

// 测试匹配功能
procedure TestMatching(FeatureDB: IChineseEncodingFeatureDB);
var
  TestText: string;
  TestData: TBytes;
  Result: TMatchResult;
begin
  Writeln('测试匹配功能:');
  
  // 测试文本
  TestText := '这是一段中文测试文本，用于测试中文编码特征数据库的匹配功能。';
  Writeln('  测试文本: ', TestText);
  
  // 将文本转换为UTF-8字节序列
  TestData := TEncoding.UTF8.GetBytes(TestText);
  
  // 测试字节频率匹配
  Writeln('  字节频率匹配:');
  Result := FeatureDB.Matcher.MatchByteFrequency(TestData, cetUTF8);
  Writeln('    结果类型: ', Ord(Result.ResultType));
  Writeln('    分数: ', Result.Score:0:4);
  Writeln('    描述: ', Result.Description);
  
  // 测试字符频率匹配
  Writeln('  字符频率匹配:');
  Result := FeatureDB.Matcher.MatchCharFrequency(TestText, cetUTF8);
  Writeln('    结果类型: ', Ord(Result.ResultType));
  Writeln('    分数: ', Result.Score:0:4);
  Writeln('    描述: ', Result.Description);
  
  // 测试综合匹配
  Writeln('  综合匹配:');
  Result := FeatureDB.Matcher.MatchComprehensive(TestData, TestText, cetUTF8);
  Writeln('    结果类型: ', Ord(Result.ResultType));
  Writeln('    分数: ', Result.Score:0:4);
  Writeln('    描述: ', Result.Description);
end;

// 导出和导入数据
procedure ExportAndImportData(FeatureDB: IChineseEncodingFeatureDB);
var
  TempFileName: string;
  CountBefore, CountAfter: Integer;
  Result: TUpdateResult;
begin
  Writeln('测试导出和导入功能:');
  
  // 创建临时文件名
  TempFileName := TPath.GetTempFileName;
  Writeln('  临时文件: ', TempFileName);
  
  try
    // 记录当前数据数量
    CountBefore := FeatureDB.Storage.GetFeatureDataCount;
    Writeln('  当前数据数量: ', CountBefore);
    
    // 导出所有数据
    Writeln('  导出所有数据到文件...');
    Result := FeatureDB.Updater.ExportFeatureData(TempFileName);
    Writeln('    成功: ', Result.Success);
    Writeln('    导出项数: ', Result.UpdatedItems);
    
    // 清空数据库
    Writeln('  清空数据库...');
    var IDs := FeatureDB.Storage.GetFeatureDataIDs;
    for var ID in IDs do
      FeatureDB.DeleteData(ID);
      
    // 验证数据库已清空
    CountAfter := FeatureDB.Storage.GetFeatureDataCount;
    Writeln('  清空后数据数量: ', CountAfter);
    
    // 导入数据
    Writeln('  从文件导入数据...');
    Result := FeatureDB.Updater.ImportFeatureData(TempFileName);
    Writeln('    成功: ', Result.Success);
    Writeln('    导入项数: ', Result.UpdatedItems);
    
    // 验证数据已导入
    CountAfter := FeatureDB.Storage.GetFeatureDataCount;
    Writeln('  导入后数据数量: ', CountAfter);
  finally
    // 删除临时文件
    if FileExists(TempFileName) then
    begin
      TFile.Delete(TempFileName);
      Writeln('  临时文件已删除');
    end;
  end;
end;

// 注册进度和完成事件处理器
procedure RegisterEventHandlers(FeatureDB: IChineseEncodingFeatureDB);
begin
  // 注册加载器事件
  FeatureDB.Loader.SetOnProgress(HandleLoadProgress);
  FeatureDB.Loader.SetOnCompleted(HandleLoadCompleted);
  
  // 注册更新器事件
  FeatureDB.Updater.SetOnProgress(HandleUpdateProgress);
  FeatureDB.Updater.SetOnCompleted(HandleUpdateCompleted);
end;

var
  FeatureDB: IChineseEncodingFeatureDB;

begin
  try
    Writeln('中文编码特征数据库演示程序');
    Writeln('============================');
    
    // 创建内存数据库
    Writeln('创建特征数据库...');
    FeatureDB := CreateChineseEncodingFeatureDB('memory');
    
    // 注册事件处理
    RegisterEventHandlers(FeatureDB);
    
    // 加载内置数据
    Writeln('加载内置数据...');
    FeatureDB.LoadBuiltInData;
    
    // 打印数据库信息
    PrintDatabaseInfo(FeatureDB);
    
    // 打印GB18030字节频率数据
    PrintGB18030ByteFrequencyData(FeatureDB);
    
    // 添加自定义特征数据
    AddCustomFeatureData(FeatureDB);
    
    // 测试匹配功能
    TestMatching(FeatureDB);
    
    // 导出和导入数据
    ExportAndImportData(FeatureDB);
    
    Writeln('演示完成');
    Writeln('按Enter键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('发生错误: ', E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end. 