unit EncodingExceptions;

interface

uses
  System.SysUtils;

type
  // 编码相关基础异常（所有编码子系统异常的根类）
  EEncodingException = class(Exception);

  // 检测阶段异常（编码探测、置信度配置等）
  EEncodingDetectionException = class(EEncodingException);

  // 转换阶段异常（缓冲区转换、流转换、文件转换）
  EEncodingConversionException = class(EEncodingException);

  // 文件访问异常（路径非法、权限不足、文件被占用等）
  EFileAccessException = class(EEncodingException);

  // 非法编码配置或不支持的编码名称
  EInvalidEncodingException = class(EEncodingException);

  // 缓冲区/长度相关异常（越界、截断等逻辑错误）
  EBufferOverflowException = class(EEncodingException);

  // 路径安全异常（违反 PathSecurity 策略）
  EPathSecurityException = class(EEncodingException);

implementation

end.
