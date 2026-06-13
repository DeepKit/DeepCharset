program DeepCharset;

{$R *.res}

// EurekaLog �쳣׷�ٺ͵���֧��
// ��ʱ���� - ��Ҫ���ÿ�·����������
// ���÷�����ȥ������ĵ�ţ���Ϊ {$DEFINE USE_EUREKALOG}
{.$DEFINE USE_EUREKALOG}

// JCL �쳣׷�ٺ��ڴ�й©��⣨�����ã�
// ���л��� madExcept����� docs/madExcept_Integration.md
// madExcept ��ʱ���� - �汾����������
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
  EMemLeaks,        // �ڴ�й©���
  EResLeaks,        // ��Դй©���  
  EDialogWinAPIMSClassic,  // �쳣�Ի���
  EDialogWinAPIEurekaLogDetailed, // ��ϸ�쳣�Ի���
  EDebugExports,    // ������Ϣ����
  EDebugJCL,        // JCL ����֧��
  EFixSafeCallException,  // SafeCall �쳣�޸�
  EMapWin32,        // MAP �ļ�֧��
  EAppWinAPI,       // Windows API Ӧ��֧��
  ExceptionLog7,    // �����쳣��־
  {$ENDIF}
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  DeepBase.AutoFix,
  DeepBase.AutoFix.VclHook,
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
  ViewExceptionReport in 'ViewExceptionReport.pas' {ExceptionReportForm},
  UtilsTempFileSecurity in 'UtilsTempFileSecurity.pas';

{$R *.res}

var
  CLIController: TCommandLineController;
  ExitCode: Integer;

begin
  // ��ʼ��ȫ�ֱ���
  InitializeGlobalVariables;

  // ����Ƿ�Ϊ������ģʽ
  if ParamCount > 0 then
  begin
    // ����һ��������������ǵ��Բ��������CLIģʽ
    if not (FindCmdLineSwitch('self-test-exception', ['-', '/'], True) or
            SameText(ParamStr(1), '--self-test-exception')) then
    begin
      // ������ģʽ
      CLIController := TCommandLineController.Create;
      try
        ExitCode := CLIController.Execute;
      finally
        CLIController.Free;
      end;
      // v2.0.1 P0.4: Halt ǰ��ʽ������ʱ�ļ�����ֹй©��
      // ��ΪֱӽHalt ���� finalization ����
      try
        UtilsTempFileSecurity.TTempFileSecurityManager.CleanupAllTempFiles;
      except
        // ����ʧ�ܲ�Ӱ���˳���
      end;
      Halt(ExitCode); // �˳����򣬷��ش�����
    end;
  end;

  // GUIģʽ����ʼ��Ӧ�ó���
  AutoFix.Install;
  TAutoFixVclHook.Install;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DeepCharset';
  
  {$IFDEF DEBUG}
  // Debug �Բ⣺ͨ�������в��������쳣����֤ madExcept ����
  // �÷���DeepCharset.exe --self-test-exception
  if FindCmdLineSwitch('self-test-exception', ['-', '/'], True) or
     SameText(ParamStr(1), '--self-test-exception') then
    raise Exception.Create('madExcept integration self-test');
  {$ENDIF}

  try
    // ����������
    Application.CreateForm(TForm1, Form1);
    // ����ҪԤ�ȴ���SynEditForm������Ҫʱ�ٴ���
    // Application.CreateForm(TSynEditForm, SynEditForm);
    AutoFix.RegisterScenario('smoke',
      procedure
      begin
        // smoke: verify AutoFix infrastructure is alive
      end);

    Application.Run;
  except
    on E: Exception do
    begin
      MessageBox(0, PChar('DeepCharset' + E.Message), 'DeepCharset', MB_OK or MB_ICONERROR);
    end;
  end;
  
end.
