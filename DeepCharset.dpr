program DeepCharset;

{$R *.res}

// EurekaLog 异常追踪和调试支持
// 暂时禁用 - 需要配置库路径后再启用
// 启用方法：去掉下面的点号，改为 {$DEFINE USE_EUREKALOG}
{.$DEFINE USE_EUREKALOG}

// JCL 异常追踪和内存泄漏检测（已弃用）
// 已切换到 madExcept，详见 docs/madExcept_Integration.md
// madExcept 暂时禁用 - 版本不兼容问题
{.$DEFINE USE_MADEXCEPT}

uses
{$IFDEF USE_MADEXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
{$ENDIF}
 {$IFDEF USE_EUREKALOG}
  EMemLeaks,        // 内存泄漏检测
  EResLeaks,        // 资源泄漏检测  
  EDialogWinAPIMSClassic,  // 异常对话框
  EDialogWinAPIEurekaLogDetailed, // 详细异常对话框
  EDebugExports,    // 调试信息导出
  EDebugJCL,        // JCL 调试支持
  EFixSafeCallException,  // SafeCall 异常修复
  EMapWin32,        // MAP 文件支持
  EAppWinAPI,       // Windows API 应用支持
  ExceptionLog7,    // 核心异常日志
  {$ENDIF}
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  ViewMainCode in 'ViewMainCode.pas' {Form1},
  ModelEncoding in 'ModelEncoding.pas',
  UtilsTypes in 'UtilsTypes.pas',
  ControllerEncoding in 'ControllerEncoding.pas',
  HelperFiles in 'HelperFiles.pas',
  HelperUI in 'HelperUI.pas',
  ModelConfig in 'ModelConfig.pas',
  HelperLanguage in 'HelperLanguage.pas',
  ViewSynEdit in 'ViewSynEdit.pas' {SynEditForm},
  ControllerLanguage in 'ControllerLanguage.pas',
  ControllerCommandLine in 'ControllerCommandLine.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingLogger in 'UtilsEncodingLogger.pas',

  UtilsEncodingBOM_Improved in 'UtilsEncodingBOM_Improved.pas',
  UtilsEncodingUTF8Detector_Improved in 'UtilsEncodingUTF8Detector_Improved.pas',
  ChineseEncodingDetector_Improved in 'ChineseEncodingDetector_Improved.pas',
  JapaneseEncodingDetector_Improved in 'JapaneseEncodingDetector_Improved.pas',
  KoreanEncodingDetector_Improved in 'KoreanEncodingDetector_Improved.pas',
  EncodingConverter_Improved in 'EncodingConverter_Improved.pas',
  UTF8BOMConverter_Improved in 'UTF8BOMConverter_Improved.pas',
  ViewExceptionReport in 'ViewExceptionReport.pas' {ExceptionReportForm};

{$R *.res}

var
  CLIController: TCommandLineController;
  ExitCode: Integer;

begin
  // 初始化全局变量
  InitializeGlobalVariables;

  // 检查是否为命令行模式
  if ParamCount > 0 then
  begin
    // 检查第一个参数，如果不是调试参数则进入CLI模式
    if not (FindCmdLineSwitch('self-test-exception', ['-', '/'], True) or
            SameText(ParamStr(1), '--self-test-exception')) then
    begin
      // 命令行模式
      CLIController := TCommandLineController.Create;
      try
        ExitCode := CLIController.Execute;
        Halt(ExitCode); // 退出程序，返回错误码
      finally
        CLIController.Free;
      end;
    end;
  end;

  // GUI模式：初始化应用程序
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '码到成功 - 文件编码转换工具';
  
  {$IFDEF DEBUG}
  // Debug 自测：通过命令行参数触发异常以验证 madExcept 集成
  // 用法：DeepCharset.exe --self-test-exception
  if FindCmdLineSwitch('self-test-exception', ['-', '/'], True) or
     SameText(ParamStr(1), '--self-test-exception') then
    raise Exception.Create('madExcept integration self-test');
  {$ENDIF}

  try
    // 创建主窗体
    Application.CreateForm(TForm1, Form1);
    // 不需要预先创建SynEditForm，在需要时再创建
    // Application.CreateForm(TSynEditForm, SynEditForm);
    Application.Run;
  except
    on E: Exception do
    begin
      MessageBox(0, PChar('程序启动时发生异常: ' + E.Message), '错误', MB_OK or MB_ICONERROR);
    end;
  end;
  
end.
