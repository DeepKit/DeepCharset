unit EncodingErrorLocator;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // 错误类型枚举
  TEncodingErrorType = (
    eetInvalidSequence,      // 无效字节序列
    eetUnmappableCharacter,  // 无法映射的字符
    eetIncompleteSequence,   // 不完整的字节序列
    eetMalformedInput,       // 输入格式错误
    eetUnsupportedEncoding,  // 不支持的编码
    eetIOError,              // IO错误
    eetUnknown               // 未知错误
  );

  // 错误严重程度枚举
  TErrorSeverity = (
    esNone,      // 无错误
    esInfo,      // 信息
    esWarning,   // 警告
    esError,     // 错误
    esCritical   // 严重错误
  );

  // 错误位置记录，包含文件位置和行列信息
  TErrorLocation = record
    // 文件偏移量
    ByteOffset: Int64;
    // 错误所在行号 (1-based)
    LineNumber: Integer;
    // 错误所在列号 (1-based)
    ColumnNumber: Integer;
    // 错误的字节长度
    ByteLength: Integer;
    
    // 构造函数
    constructor Create(AByteOffset: Int64; ALineNumber, AColumnNumber, AByteLength: Integer);
  end;

  // 错误上下文，包含错误发生的前后内容
  TErrorContext = record
    // 错误前的内容 (UTF-8编码)
    BeforeError: string;
    // 错误的内容 (十六进制表示)
    ErrorContent: string;
    // 错误后的内容 (UTF-8编码)
    AfterError: string;
    
    // 构造函数
    constructor Create(const ABeforeError, AErrorContent, AAfterError: string);
  end;

  // 完整错误信息记录
  TEncodingError = class
  private
    FErrorType: TEncodingErrorType;
    FSeverity: TErrorSeverity;
    FLocation: TErrorLocation;
    FContext: TErrorContext;
    FMessage: string;
    FSourceEncoding: string;
    FTargetEncoding: string;
  public
    constructor Create(
      AErrorType: TEncodingErrorType;
      ASeverity: TErrorSeverity;
      const ALocation: TErrorLocation;
      const AContext: TErrorContext;
      const AMessage: string;
      const ASourceEncoding, ATargetEncoding: string
    );
    
    function ToString: string; override;
    function ToDetailedString: string;
    
    property ErrorType: TEncodingErrorType read FErrorType;
    property Severity: TErrorSeverity read FSeverity;
    property Location: TErrorLocation read FLocation;
    property Context: TErrorContext read FContext;
    property Message: string read FMessage;
    property SourceEncoding: string read FSourceEncoding;
    property TargetEncoding: string read FTargetEncoding;
  end;

  // 错误定位器接口
  IEncodingErrorLocator = interface
    ['{4A832D53-F3E4-4D7B-A4E9-8C2B60E62E78}']
    // 重置定位器
    procedure Reset;
    // 添加字节到定位器
    procedure AddByte(AByte: Byte);
    // 添加字节数组到定位器
    procedure AddBytes(const ABytes: TBytes; AStart, ACount: Integer);
    // 记录行尾
    procedure RecordLineEnd;
    // 记录错误
    function RecordError(
      AErrorType: TEncodingErrorType;
      ASeverity: TErrorSeverity;
      AByteLength: Integer;
      const AMessage: string;
      const ASourceEncoding, ATargetEncoding: string
    ): TEncodingError;
    // 获取所有错误
    function GetErrors: TArray<TEncodingError>;
    // 获取错误数量
    function GetErrorCount: Integer;
    // 清除所有错误
    procedure ClearErrors;
    // 当前位置
    function GetCurrentOffset: Int64;
    // 当前行号
    function GetCurrentLine: Integer;
    // 当前列号
    function GetCurrentColumn: Integer;
  end;

  // 编码错误定位器实现
  TEncodingErrorLocator = class(TInterfacedObject, IEncodingErrorLocator)
  private
    // 当前字节偏移量
    FByteOffset: Int64;
    // 当前行号 (1-based)
    FLineNumber: Integer;
    // 当前列号 (1-based)
    FColumnNumber: Integer;
    // 存储的错误列表
    FErrors: TList<TEncodingError>;
    // 字节环形缓冲区 (用于提取上下文)
    FRingBuffer: TBytes;
    // 环形缓冲区大小
    FRingBufferSize: Integer;
    // 环形缓冲区当前位置
    FRingBufferPos: Integer;
    // 环形缓冲区是否已满
    FRingBufferFull: Boolean;
    
    // 获取错误前的上下文
    function GetBeforeContext(AContextSize: Integer): string;
    // 获取错误的十六进制表示
    function GetErrorHexContent(AByteLength: Integer): string;
  public
    constructor Create(AContextBufferSize: Integer = 100);
    destructor Destroy; override;
    
    // IEncodingErrorLocator实现
    procedure Reset;
    procedure AddByte(AByte: Byte);
    procedure AddBytes(const ABytes: TBytes; AStart, ACount: Integer);
    procedure RecordLineEnd;
    function RecordError(
      AErrorType: TEncodingErrorType;
      ASeverity: TErrorSeverity;
      AByteLength: Integer;
      const AMessage: string;
      const ASourceEncoding, ATargetEncoding: string
    ): TEncodingError;
    function GetErrors: TArray<TEncodingError>;
    function GetErrorCount: Integer;
    procedure ClearErrors;
    function GetCurrentOffset: Int64;
    function GetCurrentLine: Integer;
    function GetCurrentColumn: Integer;
  end;

// 错误类型到字符串的转换
function ErrorTypeToString(ErrorType: TEncodingErrorType): string;
// 错误严重程度到字符串的转换
function ErrorSeverityToString(Severity: TErrorSeverity): string;
// 字节数组转十六进制字符串
function BytesToHex(const ABytes: TBytes; AStart, ACount: Integer): string;

implementation

uses
  System.StrUtils;

{ TErrorLocation }

constructor TErrorLocation.Create(AByteOffset: Int64; ALineNumber, AColumnNumber, AByteLength: Integer);
begin
  ByteOffset := AByteOffset;
  LineNumber := ALineNumber;
  ColumnNumber := AColumnNumber;
  ByteLength := AByteLength;
end;

{ TErrorContext }

constructor TErrorContext.Create(const ABeforeError, AErrorContent, AAfterError: string);
begin
  BeforeError := ABeforeError;
  ErrorContent := AErrorContent;
  AfterError := AAfterError;
end;

{ TEncodingError }

constructor TEncodingError.Create(
  AErrorType: TEncodingErrorType;
  ASeverity: TErrorSeverity;
  const ALocation: TErrorLocation;
  const AContext: TErrorContext;
  const AMessage: string;
  const ASourceEncoding, ATargetEncoding: string
);
begin
  inherited Create;
  FErrorType := AErrorType;
  FSeverity := ASeverity;
  FLocation := ALocation;
  FContext := AContext;
  FMessage := AMessage;
  FSourceEncoding := ASourceEncoding;
  FTargetEncoding := ATargetEncoding;
end;

function TEncodingError.ToString: string;
begin
  Result := Format('[%s] %s at line %d, column %d: %s', [
    ErrorSeverityToString(FSeverity),
    ErrorTypeToString(FErrorType),
    FLocation.LineNumber,
    FLocation.ColumnNumber,
    FMessage
  ]);
end;

function TEncodingError.ToDetailedString: string;
begin
  Result := 
    Format('错误类型: %s', [ErrorTypeToString(FErrorType)]) + sLineBreak +
    Format('严重程度: %s', [ErrorSeverityToString(FSeverity)]) + sLineBreak +
    Format('位置: 偏移量=%d, 行=%d, 列=%d, 长度=%d', [FLocation.ByteOffset, FLocation.LineNumber, FLocation.ColumnNumber, FLocation.ByteLength]) + sLineBreak +
    Format('上下文: %s[%s]%s', [FContext.BeforeError, FContext.ErrorContent, FContext.AfterError]) + sLineBreak +
    Format('错误信息: %s', [FMessage]) + sLineBreak +
    Format('源编码: %s', [FSourceEncoding]) + sLineBreak +
    Format('目标编码: %s', [FTargetEncoding]);
end;

{ TEncodingErrorLocator }

constructor TEncodingErrorLocator.Create(AContextBufferSize: Integer);
begin
  inherited Create;
  FRingBufferSize := AContextBufferSize;
  SetLength(FRingBuffer, FRingBufferSize);
  FErrors := TList<TEncodingError>.Create;
  Reset;
end;

destructor TEncodingErrorLocator.Destroy;
begin
  ClearErrors;
  FErrors.Free;
  inherited;
end;

procedure TEncodingErrorLocator.Reset;
begin
  FByteOffset := 0;
  FLineNumber := 1;
  FColumnNumber := 1;
  FRingBufferPos := 0;
  FRingBufferFull := False;
  ClearErrors;
end;

procedure TEncodingErrorLocator.AddByte(AByte: Byte);
begin
  // 存储字节到环形缓冲区
  FRingBuffer[FRingBufferPos] := AByte;
  
  // 更新环形缓冲区位置
  Inc(FRingBufferPos);
  if FRingBufferPos >= FRingBufferSize then
  begin
    FRingBufferPos := 0;
    FRingBufferFull := True;
  end;
  
  // 更新位置信息
  Inc(FByteOffset);
  Inc(FColumnNumber);
  
  // 处理行尾
  if (AByte = 10) or (AByte = 13) then
  begin
    RecordLineEnd;
  end;
end;

procedure TEncodingErrorLocator.AddBytes(const ABytes: TBytes; AStart, ACount: Integer);
var
  I: Integer;
begin
  for I := AStart to AStart + ACount - 1 do
  begin
    AddByte(ABytes[I]);
  end;
end;

procedure TEncodingErrorLocator.RecordLineEnd;
begin
  Inc(FLineNumber);
  FColumnNumber := 1;
end;

function TEncodingErrorLocator.RecordError(
  AErrorType: TEncodingErrorType;
  ASeverity: TErrorSeverity;
  AByteLength: Integer;
  const AMessage: string;
  const ASourceEncoding, ATargetEncoding: string
): TEncodingError;
var
  Location: TErrorLocation;
  Context: TErrorContext;
  BeforeContext: string;
  ErrorHexContent: string;
  AfterContext: string;
begin
  // 创建错误位置信息
  Location := TErrorLocation.Create(
    FByteOffset - AByteLength,  // 错误起始偏移量
    FLineNumber,
    FColumnNumber - AByteLength,
    AByteLength
  );
  
  // 获取错误上下文
  BeforeContext := GetBeforeContext(50);  // 获取错误前50个字符
  ErrorHexContent := GetErrorHexContent(AByteLength);  // 获取错误的十六进制表示
  AfterContext := '';  // 目前我们只提供错误前的上下文，错误后的上下文需要更复杂的缓冲管理
  
  Context := TErrorContext.Create(BeforeContext, ErrorHexContent, AfterContext);
  
  // 创建错误对象
  Result := TEncodingError.Create(
    AErrorType,
    ASeverity,
    Location,
    Context,
    AMessage,
    ASourceEncoding,
    ATargetEncoding
  );
  
  // 添加到错误列表
  FErrors.Add(Result);
end;

function TEncodingErrorLocator.GetErrors: TArray<TEncodingError>;
var
  I: Integer;
begin
  SetLength(Result, FErrors.Count);
  for I := 0 to FErrors.Count - 1 do
  begin
    Result[I] := FErrors[I];
  end;
end;

function TEncodingErrorLocator.GetErrorCount: Integer;
begin
  Result := FErrors.Count;
end;

procedure TEncodingErrorLocator.ClearErrors;
var
  I: Integer;
begin
  for I := 0 to FErrors.Count - 1 do
  begin
    FErrors[I].Free;
  end;
  FErrors.Clear;
end;

function TEncodingErrorLocator.GetCurrentOffset: Int64;
begin
  Result := FByteOffset;
end;

function TEncodingErrorLocator.GetCurrentLine: Integer;
begin
  Result := FLineNumber;
end;

function TEncodingErrorLocator.GetCurrentColumn: Integer;
begin
  Result := FColumnNumber;
end;

function TEncodingErrorLocator.GetBeforeContext(AContextSize: Integer): string;
var
  StartPos, EndPos, I, BufferSize: Integer;
  ContextBytes: TBytes;
begin
  Result := '';
  
  // 如果缓冲区为空，则返回空字符串
  if (not FRingBufferFull) and (FRingBufferPos = 0) then
    Exit;
  
  // 计算上下文大小
  if FRingBufferFull then
    BufferSize := FRingBufferSize
  else
    BufferSize := FRingBufferPos;
    
  // 上下文不能超过缓冲区大小
  if AContextSize > BufferSize then
    AContextSize := BufferSize;
  
  // 计算起始位置
  if FRingBufferFull then
  begin
    StartPos := (FRingBufferPos + FRingBufferSize - AContextSize) mod FRingBufferSize;
    EndPos := FRingBufferPos - 1;
    if EndPos < 0 then
      EndPos := FRingBufferSize - 1;
  end
  else
  begin
    StartPos := FRingBufferPos - AContextSize;
    if StartPos < 0 then
      StartPos := 0;
    EndPos := FRingBufferPos - 1;
  end;
  
  // 复制上下文字节
  SetLength(ContextBytes, AContextSize);
  I := 0;
  while I < AContextSize do
  begin
    ContextBytes[I] := FRingBuffer[(StartPos + I) mod FRingBufferSize];
    Inc(I);
  end;
  
  // 尝试将字节转换为UTF-8字符串
  try
    Result := TEncoding.UTF8.GetString(ContextBytes);
  except
    // 如果转换失败，则返回空字符串
    Result := '[无法转换的上下文]';
  end;
end;

function TEncodingErrorLocator.GetErrorHexContent(AByteLength: Integer): string;
var
  StartPos, I, Pos: Integer;
  ErrorBytes: TBytes;
begin
  // 计算错误起始位置
  if FRingBufferFull then
  begin
    StartPos := (FRingBufferPos + FRingBufferSize - AByteLength) mod FRingBufferSize;
  end
  else
  begin
    StartPos := FRingBufferPos - AByteLength;
    if StartPos < 0 then
      StartPos := 0;
  end;
  
  // 复制错误字节
  SetLength(ErrorBytes, AByteLength);
  for I := 0 to AByteLength - 1 do
  begin
    Pos := (StartPos + I) mod FRingBufferSize;
    ErrorBytes[I] := FRingBuffer[Pos];
  end;
  
  // 将字节转换为十六进制字符串
  Result := BytesToHex(ErrorBytes, 0, Length(ErrorBytes));
end;

{ 辅助函数 }

function ErrorTypeToString(ErrorType: TEncodingErrorType): string;
begin
  case ErrorType of
    eetInvalidSequence: Result := '无效字节序列';
    eetUnmappableCharacter: Result := '无法映射的字符';
    eetIncompleteSequence: Result := '不完整的字节序列';
    eetMalformedInput: Result := '输入格式错误';
    eetUnsupportedEncoding: Result := '不支持的编码';
    eetIOError: Result := 'IO错误';
    eetUnknown: Result := '未知错误';
  else
    Result := '未定义错误类型';
  end;
end;

function ErrorSeverityToString(Severity: TErrorSeverity): string;
begin
  case Severity of
    esNone: Result := '无';
    esInfo: Result := '信息';
    esWarning: Result := '警告';
    esError: Result := '错误';
    esCritical: Result := '严重错误';
  else
    Result := '未定义严重程度';
  end;
end;

function BytesToHex(const ABytes: TBytes; AStart, ACount: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := AStart to AStart + ACount - 1 do
  begin
    Result := Result + IntToHex(ABytes[I], 2) + ' ';
  end;
  Result := Trim(Result);
end;

end. 