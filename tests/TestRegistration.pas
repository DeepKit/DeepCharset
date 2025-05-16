unit TestRegistration;

interface

procedure RegisterTests;

implementation

uses
  TestFramework, 
  TestSmartBufferManager;  // 注册智能缓冲区管理器测试

procedure RegisterTests;
begin
  // 智能缓冲区管理器测试
  RegisterTest(TTestSmartBufferManager.Suite);
  
  // 可以在这里添加更多测试套件
end;

end. 