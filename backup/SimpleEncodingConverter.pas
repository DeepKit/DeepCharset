function TSimpleEncodingConverter.ConvertFromUtf16LE(const Bytes: TBytes; TargetEncoding: TEncoding): TBytes;
var
  StartIndex: Integer;
  UTF16String: string;
  HasBOM: Boolean;
begin
  HasBOM := (Length(Bytes) >= 2) and (Bytes[0] = $FF) and (Bytes[1] = $FE);
  StartIndex := IfThen(HasBOM, 2, 0);

  // 将UTF-16LE字节转换为字符串
  SetLength(UTF16String, (Length(Bytes) - StartIndex) div 2);
  Move(Bytes[StartIndex], PChar(UTF16String)^, Length(UTF16String) * 2);

  // 转换为目标编码
  Result := TargetEncoding.GetBytes(UTF16String);
end;

function TSimpleEncodingConverter.ConvertToUtf16LE(const Bytes: TBytes; SourceEncoding: TEncoding; AddBOM: Boolean = True): TBytes;
var
  UTF16String: string;
  BOMSize: Integer;
begin
  // 从源编码转换为字符串
  UTF16String := SourceEncoding.GetString(Bytes);

  // 计算BOM大小
  BOMSize := IfThen(AddBOM, 2, 0);

  // 分配结果空间
  SetLength(Result, Length(UTF16String) * 2 + BOMSize);

  // 添加BOM
  if AddBOM then
  begin
    Result[0] := $FF;
    Result[1] := $FE;
  end;

  // 复制UTF-16LE数据
  Move(PChar(UTF16String)^, Result[BOMSize], Length(UTF16String) * 2);
end; 