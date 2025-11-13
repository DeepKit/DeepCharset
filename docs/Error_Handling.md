# 错误与异常处理规范

本项目的错误/异常处理遵循以下原则：

- 背景与目标
  - 提供可诊断的上下文（operation、file、details），便于复现与定位。
  - CLI/UI 均应输出简明的人类可读信息；详细信息写入日志/报告。

- 上下文结构（UtilsExceptionContext）
  - TExceptionContext.Operation：发生操作（如 ProcessSingleFile/Detect/Convert 等）
  - TExceptionContext.FilePath：当前处理的文件路径
  - TExceptionContext.Details：额外说明（目标编码、阶段信息等）
  - ToMessage：将 Original Message 包裹为 “原始信息 | op=..., file=..., details=...”

- CLI 集成（ControllerCommandLine）
  - ProcessSingleFile 捕获到异常后，使用 TExceptionContext 包裹消息并输出到控制台与报告。
  - --report 输出 JSON/XML 中的 error 字段使用带上下文的消息。

- UI 日志
  - 取消动作、扫描/检测/转换异常均记录明确信息。

- 约定
  - 不在业务常态流程中抛出泛型 Exception；若需要抛出，优先采用带上下文的消息。
  - 后续批次将逐步替换关键路径的捕获点，统一注入上下文信息。

- 已覆盖模块（当前进度）
  - ControllerCommandLine（已集成）
  - ControllerEncoding（新增：ConvertSingleFile、检测读取失败、检测失败路径加入上下文日志）
  - HelperFiles（新增：ConvertFile、DetectFileEncoding、EnsurePathExists 捕获点加入上下文日志）
  - UI 层（ViewMainCode）通过日志呈现，不直接抛异常
