# DeepCharset v2.0.1 Release Notes

**Release Date**: 2025-12-18
**Version**: 2.0.1
**Platform**: Windows 64-bit (Win64)
**Status**: 🎉 Release Ready

---

## 概述

v2.0.1 是一个**质量修复版**，在 v2.0.0beta 的基础上整合了从 2025-11 至 2025-12 期间发现并修复的 15 个 Bug（Bug #5 ~ #19），覆盖线程安全、路径安全、命令注入、大文件内存、资源管理等多个维度。

---

## 本次修复亮点

### 🔒 安全性加固

- **路径遍历防护** (Bug #7, #12)：全面拦截 `C:\temp\..\Windows\system32\` 等路径遍历尝试；在路径规范化**之前**检查 `..` 字符，杜绝绕过
- **系统目录保护** (Bug #7)：自动识别并拒绝写入 `Windows\System32`、`Program Files` 等受保护位置
- **临时文件安全** (Bug #9, #14)：使用 GUID 生成不可预测的临时文件名；使用多次覆写进行安全删除；类级文件列表加锁保护多线程并发
- **跨卷原子替换** (Bug #11)：临时文件直接在目标目录生成，避免 `RenameFile` 跨卷失败

### 🧵 线程安全

- **CodePage 缓存加锁** (Bug #5)：`CodePageCache` 加入 `TCriticalSection`，多线程批量转换不再竞争

### 📦 大文件支持

- **流式处理** (Bug #16)：新增 `ConvertFileStreaming` 方法，64KB 分块处理任意大小文件（2GB 内），内存占用恒定；v2.0.1 默认自动对 >16 MB 文件走流式路径
- **CLI 默认备份** (v2.0.1 新增)：CLI 模式 `--backup` 默认开启，首次误覆盖风险降低

### 🧹 代码质量

- **统一 BOM 清理** (Bug #10)：消除 200+ 行重复代码，`TBOMCleaner` 成为唯一真相源
- **W1057 警告归零**：通过精准的编译器指令维持 0 警告
- **异常层次结构** (P2-4)：`EncodingExceptions` 单元定义领域异常，替代裸 `Exception`

### 🐛 其他关键修复

- **CLI 资源清理** (v2.0.1)：`Halt(ExitCode)` 前显式调用 `TTempFileSecurityManager.CleanupAllTempFiles`，避免残留 .tmp 文件
- **BOM-only 文件误报**：仅包含 BOM 的源文件不再被判为"数据丢失"并拒绝写入
- **编码置信度配置** (Issue #4)：检测器接入 `MinChineseConfidence` / `MinJapaneseConfidence` / `MinKoreanConfidence`，不再硬编码 0.75

---

## 安装与快速开始

### 系统要求

- Windows 7 SP1 或更高版本（64 位）

### 快速使用

```bash
# GBK 转 UTF-8（默认自动备份为 .bak）
DeepCharset.exe -s GBK -t UTF-8 input.txt

# 递归转换整个目录
DeepCharset.exe -s auto -t UTF-8 -r C:\MyFiles\

# 指定输出路径
DeepCharset.exe -s Big5 -t UTF-8 --add-bom input.txt -o output.txt
```

---

## 与 v2.0.0beta 的差异

| 维度 | v2.0.0beta (2025-11-13) | v2.0.1 (2025-12-18) |
|------|-------------------------|---------------------|
| 版本状态 | beta | 稳定 |
| Bug 修复 | Bug #1-#4 | +Bug #5-#19 |
| 线程安全 | ❌ CodePageCache 无锁 | ✅ 加锁保护 |
| 路径安全 | ❌ 未实现 | ✅ `UtilsPathSecurity` |
| 临时文件 | ❌ 时间戳命名 | ✅ GUID + 安全删除 |
| 大文件 | ❌ 全量加载 | ✅ 自动流式 |
| CLI 备份 | ❌ 默认关闭 | ✅ 默认开启 |
| CLI 退出 | ❌ 泄漏临时文件 | ✅ 显式清理 |

---

## 支持的编码

### Unicode
UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE

### 中文
GBK, GB2312, GB18030, Big5

### 日文
Shift-JIS, EUC-JP, ISO-2022-JP

### 韩文
EUC-KR, JOHAB

### 欧洲与其他
Windows-1250..1258, ISO-8859-1..15, KOI8-R, KOI8-U, ASCII

### 代码页
支持数字代码页（936 / 950 / 65001 / 1200 等）

---

## 已知限制

- **检测采样窗口**：超大文件 (>4 MB) 编码检测仅读取前 4 MB 样本
- **混合编码文件**：无法对"前半 GBK + 后半 UTF-8"的文件做分段转换，建议先拆分
- **Unicode → 单字节损失**：UTF-8 转 GBK 等单字节编码时，未覆盖的 Unicode 字符会被替换为 `?`
- **安全模式 UI**：低置信度转换的"安全模式"开关尚在 v2.1.0 路线图中

---

## 文档导航

- `README.md` - 项目概览
- `CHANGELOG.md` - 版本历史
- `docs/Quick_Start_Guide.md` - 快速上手
- `docs/CommandLine_Usage.md` - CLI 完整参考
- `docs/Detection_Settings.md` - 检测参数调优
- `docs/Error_Handling.md` - 故障排查
- `docs/EncodingSafetyAndUsage.md` - 安全使用与适用范围（v2.1.0）

---

## 升级建议

从 v2.0.0beta 升级到 v2.0.1：
- **强烈建议升级**：本版修复了 CLI 临时文件泄漏和潜在路径遍历安全问题
- **兼容性**：完全向后兼容，无配置变更
- **唯一行为差异**：CLI `-b/--backup` 默认从关闭改为开启，如需保持旧行为请加 `--no-backup`

---

## 支持

- 问题反馈：见 `docs/Error_Handling.md`
- 作者：ODDFounder / Fuyi / 付乙
- Website: www.goodmem.cn

---

Thank you for using DeepCharset v2.0.1！
