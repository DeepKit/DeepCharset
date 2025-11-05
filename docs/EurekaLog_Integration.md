# EurekaLog 7.12.0.0 集成指南
 
 > 本文档已弃用（Deprecated）。由于 JCL 包安装不成功，项目已改用 madExcept 作为异常处理与崩溃报告方案。请参考最新文档：`docs/madExcept_Integration.md`。
 
 
 ## 📦 安装位置
 ```
 D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\EurekaLogTools-7.12.0.0\
 ```

## ✅ 集成步骤

### 1. IDE 配置
在 Delphi IDE 中：
1. 打开 **Tools → Options → EurekaLog**
2. 确认 EurekaLog 已正确安装并激活
3. 检查 EurekaLog 工具链路径是否正确

### 2. 项目文件配置

已在 `TransSuccess.dpr` 中添加必要的 EurekaLog 单元：

```pascal
{$IFDEF EUREKALOG}
  {$DEFINE USE_EUREKALOG}
{$ENDIF}

uses
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
```

### 3. EurekaLog 配置文件

已创建 `TransSuccess.eof` 配置文件，主要设置：

#### 异常追踪
- ✅ 自动捕获所有异常
- ✅ 生成详细调用栈（深度20层）
- ✅ 显示源代码行号（前后3行）
- ✅ 显示相对地址和行号

#### 内存泄漏检测
- ✅ 启用内存泄漏检测
- ✅ 程序关闭时显示泄漏信息
- ⚠️ 不忽略小内存泄漏（便于调试）

#### 日志选项
- 📝 日志类型：无（可根据需要启用）
- 📁 日志文件：`%EXEName%.log`
- 📊 最大日志大小：1000 KB
- 🔄 最大日志文件数：10

#### 性能选项
- ⚡ 优化调用栈收集
- ⚡ 使用快速调用栈遍历
- ⚡ 仅在异常时收集调用栈

## 🔧 使用方法

### 编译项目
```batch
# Debug 模式（包含 EurekaLog）
dcc32 -B -$D+ -$L+ -GD TransSuccess.dpr

# Release 模式（包含 EurekaLog）
dcc32 -B -$D- -$L- TransSuccess.dpr
```

### 在 IDE 中编译
1. 打开 `TransSuccess.dproj`
2. 右键点击项目 → **EurekaLog Project Options**
3. 确认 **Activate EurekaLog** 已勾选
4. 点击 **Compile** 或 **Build**

## 📊 功能说明

### 1. 异常对话框
当程序发生异常时，会显示详细的错误信息：
- 异常类型和消息
- 完整调用栈
- 源代码位置
- 模块信息
- 系统信息
- 内存状态

### 2. 内存泄漏报告
程序关闭时，如果检测到内存泄漏，会显示：
- 泄漏的内存大小
- 分配位置的调用栈
- 泄漏的对象类型
- 泄漏次数统计

### 3. 日志文件
可以启用日志文件记录：
- 所有异常信息
- 程序运行轨迹
- 性能统计
- 自定义日志消息

## 🎯 调试技巧

### 添加自定义日志
```pascal
uses
  ExceptionLog7;

procedure MyFunction;
begin
  // 记录信息
  LogMessage('开始执行 MyFunction');
  
  try
    // 你的代码
  except
    on E: Exception do
    begin
      // 记录异常
      LogException(E);
      raise;
    end;
  end;
end;
```

### 添加性能追踪
```pascal
uses
  ExceptionLog7;

procedure ProcessLargeFile(const FileName: string);
var
  StartTime: Cardinal;
begin
  StartTime := GetTickCount;
  try
    // 处理文件
  finally
    LogMessage(Format('处理文件耗时: %d ms', [GetTickCount - StartTime]));
  end;
end;
```

### 条件性启用 EurekaLog
```pascal
{$IFDEF DEBUG}
  // Debug 模式下启用详细日志
  SetEurekaLogOption('LogType', 'ltDetailed');
{$ELSE}
  // Release 模式下只记录错误
  SetEurekaLogOption('LogType', 'ltError');
{$ENDIF}
```

## 🔍 已知问题和解决方案

### 问题1：MAP 文件未生成
**解决方案**：
1. 打开 **Project → Options → Delphi Compiler → Linking**
2. 勾选 **Map file** → **Detailed**
3. 重新编译项目

### 问题2：调用栈显示地址而非函数名
**解决方案**：
1. 确保编译时包含调试信息
2. 检查 MAP 文件是否存在
3. 在 `TransSuccess.eof` 中设置：
   ```
   [Exception Log]
   DeleteMapAfterCompile=0
   ```

### 问题3：内存泄漏误报
**解决方案**：
1. 某些第三方库可能产生预期的内存泄漏
2. 在 `TransSuccess.eof` 中添加到忽略列表
3. 或设置 `IgnoreSmallLeaks=1`

## 📈 性能影响

### Debug 模式
- 启动时间增加：~50-100ms
- 运行时性能：~1-3% 开销
- 内存占用：额外 2-5MB

### Release 模式
- 启动时间增加：~20-50ms
- 运行时性能：<1% 开销
- 内存占用：额外 1-2MB

## 🚀 优化建议

### 生产环境
```ini
[Exception Log]
Activate=1

[Log]
LogType=ltError
LogMaxSize=5000
LogMaxCount=5

[Leaks Options]
CheckMemoryLeaks=0  ; 生产环境关闭
ShowLeaksInfoOnShutdown=0

[Automatic Options]
AutoSend=1  ; 自动发送错误报告
AutoShowDialog=0  ; 不显示对话框
```

### 开发环境
```ini
[Exception Log]
Activate=1

[Log]
LogType=ltDetailed
LogMaxSize=10000
LogMaxCount=20

[Leaks Options]
CheckMemoryLeaks=1
ShowLeaksInfoOnShutdown=1

[Automatic Options]
AutoShowDialog=1
AutoSend=0
```

## 📚 参考资源

- [EurekaLog 官方文档](http://www.eurekalog.com/help/)
- [EurekaLog 论坛](http://forum.eurekalog.com/)
- [JCL 调试支持](http://jcl.sourceforge.net/)

## ⚠️ 注意事项

1. **许可证**：确保已购买 EurekaLog 许可证
2. **编译器版本**：EurekaLog 7.12 支持 Delphi XE2 - Delphi 11
3. **第三方库**：某些库可能与 EurekaLog 冲突，需要特殊处理
4. **代码签名**：EurekaLog 会修改 PE 文件，可能需要重新签名

## 🔄 更新日志

### 2025-11-03
- ✅ 创建 EurekaLog 配置文件
- ✅ 集成到 TransSuccess.dpr
- ✅ 配置内存泄漏检测
- ✅ 配置异常追踪
- ✅ 添加详细注释

---

**维护者**: TransSuccess 开发团队  
**最后更新**: 2025-11-03 11:46:38
