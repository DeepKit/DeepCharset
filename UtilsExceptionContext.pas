unit UtilsExceptionContext;

interface

uses
  System.SysUtils;

type
  TExceptionContext = record
    Operation: string;
    FilePath: string;
    Details: string;
    function ToMessage(const Original: string): string;
    class function Create(const AOperation, AFilePath, ADetails: string): TExceptionContext; static;
  end;

procedure RaiseWithContext(const E: Exception; const Ctx: TExceptionContext);

implementation

{ TExceptionContext }

class function TExceptionContext.Create(const AOperation, AFilePath, ADetails: string): TExceptionContext;
begin
  Result.Operation := AOperation;
  Result.FilePath := AFilePath;
  Result.Details := ADetails;
end;

function TExceptionContext.ToMessage(const Original: string): string;
begin
  Result := Format('%s | op=%s, file=%s, details=%s', [Original, Operation, FilePath, Details]);
end;

procedure RaiseWithContext(const E: Exception; const Ctx: TExceptionContext);
begin
  raise Exception.Create(Ctx.ToMessage(E.Message)) at ExceptAddr;
end;

end.
