unit EncodingExceptions;

interface

uses
  System.SysUtils;

type
  EEncodingException = class(Exception);
  EEncodingDetectionException = class(EEncodingException);
  EEncodingConversionException = class(EEncodingException);
  EFileAccessException = class(EEncodingException);
  EInvalidEncodingException = class(EEncodingException);

implementation

end.
