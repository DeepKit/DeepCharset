# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

项目：DeepCharset（Windows/Delphi VCL 应用 + CLI 文本编码检�?转换�?

常用命令与操�?

- 构建（批处理脚本，优�?msbuild�?
  - 清理：`build.bat clean`
  - Debug 构建：`build.bat Debug`
  - Release 构建：`build.bat Release`
  - 产物：`bin\DeepCharset.exe`（msbuild 成功时会�?`Win64\\<Config>` 复制�?
- 使用 Delphi IDE 构建
  - 打开 `DeepCharset.dproj`，选择 Win64 + Debug/Release 构建�?
- 运行（GUI/CLI�?
  - `bin\DeepCharset.exe [选项]`（CLI 具体�?`docs/CommandLine_Usage.md`�?
- 测试（自测控制台程序�?
  - 快速冒烟：`tests_run.bat /quick`
  - 关键 UTF-8/BOM：`tests_run.bat /crit`
  - 跨码页回归：`tests_run.bat /cp`
- 打开日志：追�?`/openlogs`；性能计时：追�?`/perf`（输出到 `tmp_tests\perf_log.txt`�?
- 预检环境：`pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/dev_check.ps1`（可�?`-FailOnWarn`�?
  - 直接运行单体测试：编译并运行 `Tests\QuickTest.dpr`（`dcc64 -B -U.. -Ebin Tests\QuickTest.dpr` -> `bin\QuickTest.exe`�?

仓库约定与规则（只列关键点）

- Cursor 规则（`.cursor/rules`�?
  - 需�?SynEdit 源码；常见路径（可按本机调整）：
    - `D:\ProgramData\SynEdit-master\Source`
    - `D:\ProgramData\SynEdit-master\Source\Highlighters`
  - 命名/分层：Model*（核心逻辑）、View*（界面）、Controller*（编�?CLI）、Helper*/Utils*（工具）�?

架构总览（大图）

- 双模式入口（`DeepCharset.dpr`�?
  - CLI：存在有效参数时创建 `TCommandLineController` 执行并以其返回码退出�?
  - GUI：VCL 主窗�?`ViewMainCode.pas`，按需打开 `ViewSynEdit.pas`�?
- 编码转换流水�?
  - `EncodingConverter_Improved.pas` 作为总控；BOM/UTF-8 �?`UtilsEncodingBOM_Improved.pas` �?`UtilsEncodingUTF8Detector_Improved.pas`；中/�?韩检测分别在 `Chinese/Japanese/KoreanEncodingDetector_Improved.pas`�?
  - 公共类型/日志：`UtilsEncodingTypes.pas`、`UtilsEncodingLogger.pas`、`UtilsTypes.pas`�?
- 配置与多语言
  - `ini/` 提供多语言资源；`config/language.cfg` 控制当前语言�?
- 异常处理方案
  - 推荐 madExcept（见 `docs/madExcept_Integration.md`）；EurekaLog 文档仅历史参考�?

CI（GitHub Actions�?

- 工作流：`.github/workflows/build-test.yml`
  - 步骤：`build.bat clean` �?`build.bat Debug` �?运行 `tests_run.bat` �?`/quick`、`/crit /perf`、`/cp`
  - 工件：上�?`bin/*.exe` �?`tmp_tests/selftest_log.txt`、`tmp_tests/perf_log.txt`
  - 发布：下�?`DeepCharset-build` 工件，打包为 `DeepCharset.zip`

依赖说明（关键）

- Delphi 工具链：Win64 目标；脚本优�?`msbuild`，回退 `dcc64`。可通过环境变量覆盖：`MSBUILD` 指定 msbuild 路径，`DCC64` 指定 dcc64 路径�?
- SynEdit：确�?`.dproj` �?UnitSearchPath 指向的路径在本机存在，或按需修改�?
- madExcept/EurekaLog：均为可选，默认未启用，按文档选择其一�?

常见构建失败排查（精简�?

- 缺少 msbuild：已自动回退�?dcc64；若两者都不可用，请安�?Visual Studio Build Tools（含 msbuild）或 Embarcadero 编译器，并将路径加入 PATH，或通过 `MSBUILD`/`DCC64` 环境变量指定�?
- 找不�?SynEdit 单元：根�?WARP.md 顶部给出�?SynEdit 源路径，�?IDE �?`.dproj` �?UnitSearchPath 中修正为本机实际安装路径�?
- madExcept/EurekaLog 报错：默认未启用；若需启用请先按对应文档完成安装与设置，再打开条件编译�?.dproj 定义�?

重要文件（不易从树上直观看出的）

- 入口：`DeepCharset.dpr`、`DeepCharset.dproj`
- 文档：`docs/CommandLine_Usage.md`、`docs/madExcept_Integration.md`、`EUREKALOG_SETUP.md`
- 测试：`Tests/SelfTest_Encoding.dpr`、`Tests/QuickTest.dpr`
- 脚本：`build.bat`、`tests_run.bat`
