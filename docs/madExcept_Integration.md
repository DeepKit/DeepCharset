# madExcept 5 集成指南

本项目由于 JCL 包安装不成功，现已改用 madExcept 作为异常处理与崩溃报告方案。本指南说明如何在 `TransSuccess` 项目中安装、启用与配置 madExcept。

## 📦 安装与环境

- 支持 IDE：Delphi XE–Delphi 12（推荐使用与当前 IDE 匹配的 madExcept 版本）
- 建议安装路径（示例）：
  ```
  D:\Personal\Tools\madCollection\madExcept\
  ```
- 安装完成后，请确认 IDE 中已出现 “madExcept” 菜单，以及项目右键菜单中的 “madExcept settings”。

## ✅ 项目集成步骤

### 1. 在 IDE 中启用 madExcept
1. 打开 `TransSuccess.dproj`
2. 右键项目 → 选择 `madExcept settings`
3. 在弹出窗口中勾选：
   - Activate madExcept
   - Show exception box (开发环境建议开启)
   - Create crash reports
4. 保存设置并重新编译项目

### 2. 源码与单元引用（可选）
通常启用 madExcept 后，无需手动在 `uses` 中添加单元。但若需要自定义控制，可在 `TransSuccess.dpr` 中通过条件编译引用：
```pascal
{$IFDEF USE_MADEXCEPT}
uses
  madExcept, madLinkDisAsm, madListHardware, madListProcesses, madListModules;
{$ENDIF}
```
并在项目的 `Conditional defines` 中添加 `USE_MADEXCEPT` 以便按需开关。

### 3. 调试与日志建议
- 开发环境：
  - 开启 “Show exception box”
  - 开启 “Append bug report to clipboard” 便于复制
  - 保存崩溃报告到 `./logs/` 目录
- 生产环境：
  - 关闭异常对话框，仅生成报告并支持静默发送（如有需要）

### 4. 报告内容与位置
- 报告包含：异常类型/消息、调用栈、线程与模块信息、硬件/系统信息、寄存器与内存快照（可选）
- 推荐路径：`%exeDir%\logs\`（可在 madExcept settings 中设置）

### 5. 与 JCL/EurekaLog 的差异与迁移
- 本项目已放弃 JCL 的异常/泄漏追踪集成与 EurekaLog 集成，统一使用 madExcept。
- 如需将历史文档或脚本切换到 madExcept：
  - 构建脚本无需再设置 JCL 的 `-U` 路径用于异常调试单元
  - MAP/PDB 等符号文件可选（madExcept 可直接生成调用栈）

## 🔧 常用配置建议

### 开发环境
```ini
[Debug]
ShowExceptionBox=1
SaveReports=1
ReportsDir=.\logs\
AppendToClipboard=1
SendInBackground=0
```

### 生产环境
```ini
[Release]
ShowExceptionBox=0
SaveReports=1
ReportsDir=.\logs\
AutoSend=1
AskUser=0
```

以上选项需在 “madExcept settings” 图形界面中设置；此处为推荐策略说明。

## 🧪 验证集成
- 在应用启动时与退出时进行一次简单的 try/except 测试：
```pascal
try
  raise Exception.Create('madExcept integration self-test');
except
  on E: Exception do
    ; // 运行时应弹出 madExcept 对话框（Debug），并生成报告
end;
```
- 查看 `./logs/` 下是否生成崩溃报告文件。

## ❓常见问题
- 未显示 madExcept 设置：确认 madCollection 安装成功并与 IDE 版本匹配。
- 无调用栈或符号信息：确保使用完整的 madExcept 集成；必要时开启详细调用栈与模块列表。
- 与第三方保护/壳冲突：生产环境请测试签名与打包流程，必要时在 madExcept 中排除干扰选项。

---
维护者: TransSuccess 开发团队  
最后更新: 2025-11-04 11:28:48
