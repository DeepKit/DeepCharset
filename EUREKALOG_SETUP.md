# EurekaLog 快速启动指�?

## �?已完成的配置

### 1. 代码已启�?
- `DeepCharset.dpr` 中已启用 EurekaLog 单元
- 包含内存泄漏检测、异常追踪、调用栈分析等功�?

### 2. 项目配置已更�?
- Win64 Debug 配置：已添加 EurekaLog 库路�?
- Win64 Release 配置：已添加 EurekaLog 库路�?
- EurekaLog 路径：`D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\EurekaLogTools-7.12.0.0\`

### 3. 配置文件
- `DeepCharset.eof` - EurekaLog 配置文件已创�?

---

## 🚀 立即开始使�?

### �?Delphi IDE 中编�?

```
1. 打开 Delphi IDE
2. File �?Open Project �?选择 DeepCharset.dproj
3. Build �?Build DeepCharset (Ctrl+F9)
4. Run �?Run (F9)
```

### 如果出现编译错误

检�?EurekaLog 单元路径是否正确�?

```
Tools �?Options �?Language �?Delphi �?Library
�?Library path (Win64)
```

确保包含以下路径�?
```
D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\EurekaLogTools-7.12.0.0\Lib\Win64\Release
D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\EurekaLogTools-7.12.0.0\Source\Common
```

---

## 🎯 功能验证

### 测试异常捕获

在程序中触发一个异常：

```pascal
procedure TForm1.TestException;
begin
  raise Exception.Create('测试 EurekaLog 异常捕获');
end;
```

运行程序后，EurekaLog 会显示详细的异常对话框，包含�?
- 异常类型和消�?
- 完整调用栈（20层深度）
- 源代码位�?
- 内存状�?
- 系统信息

### 测试内存泄漏检�?

程序正常关闭时，如果有内存泄漏，EurekaLog 会自动显示：
- 泄漏的内存大�?
- 分配位置的调用栈
- 泄漏对象的类�?

---

## 📋 当前配置

### 异常追踪
- �?自动捕获所有异�?
- �?调用栈深度：20 �?
- �?显示源代码（前后 3 行）
- �?相对地址和行�?

### 内存泄漏检�?
- �?启用内存泄漏检�?
- �?程序关闭时显示泄漏信�?
- ⚙️ 不忽略小内存泄漏（便于调试）

### 日志选项
- 📝 日志类型：无（可�?DeepCharset.eof 中启用）
- 📁 日志文件：`DeepCharset.log`
- 📊 最大日志大小：1000 KB
- 🔄 最大日志文件数�?0

### 性能选项
- �?优化调用栈收�?
- �?使用快速调用栈遍历
- �?仅在异常时收集调用栈

---

## ⚙️ 自定义配�?

编辑 `DeepCharset.eof` 文件来修�?EurekaLog 行为�?

### 启用日志文件
```ini
[Log]
LogType=ltDetailed
LogFileName=%EXEName%.log
```

### 调整调用栈深�?
```ini
[Call Stack Options]
CallStackCount=30  ; 默认 20
```

### 自动发送错误报�?
```ini
[Sending Options]
SendMethod=smHTTP
SendBugReport=True
```

---

## 🔧 故障排除

### 问题1: 找不�?EurekaLog 单元
**解决方案**�?
1. 确认 EurekaLog 已正确安�?
2. 检查库路径配置
3. 重新启动 Delphi IDE

### 问题2: 编译时提�?"Cannot find EMemLeaks.dcu"
**解决方案**�?
```
�?DeepCharset.dpr 中临时禁�?EurekaLog�?
{.$DEFINE USE_EUREKALOG}
```

### 问题3: 调用栈显示地址而非函数�?
**解决方案**�?
1. 确保编译时包含调试信�?
2. Project �?Options �?Compiling �?Debugging �?Debug information = True
3. Project �?Options �?Linking �?Map file = Detailed

---

## 📚 参考文�?

- 完整文档：`docs/EurekaLog_Integration.md`
- 配置文件：`DeepCharset.eof`
- 官方文档：http://www.eurekalog.com/help/

---

## �?快速提�?

1. **Debug 模式**：完整的异常信息和内存检�?
2. **Release 模式**：轻量级异常追踪，性能影响 <1%
3. **生产环境**：建议启用自动错误报告，禁用对话�?
4. **开发环�?*：建议显示详细对话框和内存泄漏信�?

---

**状�?*: �?已配置完成，可直接使�? 
**更新日期**: 2025-11-03 14:42
