unit TestsRegister;

interface

procedure RegisterTests;

implementation

uses
  TestFramework, 
  TestSmartBufferManager;
  
procedure RegisterTests;
begin
  RegisterTest(TTestSmartBufferManager.Suite);
  // 后续可添加其他测试套件的注册
end;

end. 