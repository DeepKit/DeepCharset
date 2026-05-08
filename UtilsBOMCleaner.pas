unit UtilsBOMCleaner;

{
  统一BOM清理模块
  
  目的：
  - 消除EncodingConverter_Improved和UTF8BOMConverter_Improved中重复的BOM清理代码
  - 提供统一的UTF-8 BOM和误编码序列清理功能
  
  P1-1: Bug #10 重复代码重构
  创建时间: 2025-12-06
}

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  /// BOM清理器
  /// </summary>
  TBOMCleaner = class
  public
    /// <summary>
    /// 清理UTF-8内容中的内部BOM片段与被误编码的6字节序列
    /// </summary>
    /// <param name="Buffer">要清理的缓冲区</param>
    /// <param name="EnsureLeadingBOM">True=保证首部有且仅有一个BOM; False=移除所有BOM</param>
    /// <returns>清理后的缓冲区</returns>
    class function CleanUTF8Artifacts(const Buffer: TBytes; EnsureLeadingBOM: Boolean): TBytes;
    
    /// <summary>
    /// 移除缓冲区中的所有UTF-8 BOM (EF BB BF)
    /// </summary>
    class function RemoveAllBOM(const Buffer: TBytes): TBytes;
    
    /// <summary>
    /// 确保缓冲区首部有且仅有一个UTF-8 BOM
    /// </summary>
    class function EnsureSingleLeadingBOM(const Buffer: TBytes): TBytes;
    
    /// <summary>
    /// 清理误编码的6字节序列 (C3 AF C2 BB C2 BF)
    /// 这是UTF-8 BOM被误当作ANSI再转UTF-8后的结果
    /// </summary>
    class function CleanMisEncodedBOM(const Buffer: TBytes): TBytes;
  end;

implementation

uses
  UtilsEncodingBOM_Improved;

{ TBOMCleaner }

class function TBOMCleaner.CleanUTF8Artifacts(const Buffer: TBytes; EnsureLeadingBOM: Boolean): TBytes;
var
  B: TBytes;
  i: Integer;
begin
  B := Copy(Buffer);

  if EnsureLeadingBOM then
  begin
    // 确保首部有BOM
    var Leading := (Length(B) >= 3) and (B[0]=$EF) and (B[1]=$BB) and (B[2]=$BF);
    if not Leading then
      B := TEncodingBOMDetector_Improved.AddBOM(B, 1);
      
    // 从索引3开始清理内部BOM
    i := 3;
    while i <= Length(B) - 3 do
    begin
      if (B[i]=$EF) and (B[i+1]=$BB) and (B[i+2]=$BF) then
      begin
        var tail := Length(B) - (i + 3);
        if tail > 0 then 
          System.Move(B[i+3], B[i], tail);
        SetLength(B, Length(B) - 3);
        Continue;
      end;
      Inc(i);
    end;
    
    // 清理六字节序列（索引3开始）
    i := 3;
    while i <= Length(B) - 6 do
    begin
      if (B[i]=$C3) and (B[i+1]=$AF) and (B[i+2]=$C2) and 
         (B[i+3]=$BB) and (B[i+4]=$C2) and (B[i+5]=$BF) then
      begin
        var tail6 := Length(B) - (i + 6);
        if tail6 > 0 then 
          System.Move(B[i+6], B[i], tail6);
        SetLength(B, Length(B) - 6);
        Continue;
      end;
      Inc(i);
    end;
  end
  else
  begin
    // 移除所有位置的BOM
    i := 0;
    while i <= Length(B) - 3 do
    begin
      if (B[i]=$EF) and (B[i+1]=$BB) and (B[i+2]=$BF) then
      begin
        var tail := Length(B) - (i + 3);
        if tail > 0 then 
          System.Move(B[i+3], B[i], tail);
        SetLength(B, Length(B) - 3);
        Continue;
      end;
      Inc(i);
    end;
    
    // 移除六字节序列
    i := 0;
    while i <= Length(B) - 6 do
    begin
      if (B[i]=$C3) and (B[i+1]=$AF) and (B[i+2]=$C2) and 
         (B[i+3]=$BB) and (B[i+4]=$C2) and (B[i+5]=$BF) then
      begin
        var tail6 := Length(B) - (i + 6);
        if tail6 > 0 then 
          System.Move(B[i+6], B[i], tail6);
        SetLength(B, Length(B) - 6);
        Continue;
      end;
      Inc(i);
    end;
  end;

  Result := B;
end;

class function TBOMCleaner.RemoveAllBOM(const Buffer: TBytes): TBytes;
begin
  Result := CleanUTF8Artifacts(Buffer, False);
end;

class function TBOMCleaner.EnsureSingleLeadingBOM(const Buffer: TBytes): TBytes;
begin
  Result := CleanUTF8Artifacts(Buffer, True);
end;

class function TBOMCleaner.CleanMisEncodedBOM(const Buffer: TBytes): TBytes;
var
  B: TBytes;
  i: Integer;
begin
  B := Copy(Buffer);
  
  // 清理六字节序列 (C3 AF C2 BB C2 BF)
  i := 0;
  while i <= Length(B) - 6 do
  begin
    if (B[i]=$C3) and (B[i+1]=$AF) and (B[i+2]=$C2) and 
       (B[i+3]=$BB) and (B[i+4]=$C2) and (B[i+5]=$BF) then
    begin
      var tail := Length(B) - (i + 6);
      if tail > 0 then 
        System.Move(B[i+6], B[i], tail);
      SetLength(B, Length(B) - 6);
      Continue;
    end;
    Inc(i);
  end;
  
  Result := B;
end;

end.
