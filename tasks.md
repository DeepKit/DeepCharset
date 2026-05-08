# DeepCharset 待办任务清单

> 📝 **文档说明**
> - 已完成的任务已移�?`hiDeepDeepDeepDeepDeepStory.md`
> - 已修复的 Bug 已移�?`bugfix.md`
> - 本文档仅记录待办任务
>
> **最后更�?*: 2025-12-07

---

## 🔧 高优先级任务 (v2.2.0 - 大文件与异步)

### 1. madExcept 完整集成
**状�?*: 🔴 待实�? 
**优先�?*: 🔥 �? 
**预计工期**: 1-2�?

#### 任务清单
- [ ] �?IDE 中为 Debug/Release 分别配置 madExcept 策略
- [ ] Debug：开启异常对话框与剪贴板复制
- [ ] Release：静默生成报告到 `./logs/` 目录
- [ ] 添加自测异常路径，验证报告生�?
- [ ] 集成崩溃报告自动发送功�?
- [ ] 添加异常日志记录到统一日志系统
- [ ] 整理/清理�?JCL 异常追踪相关的遗留代�?

#### 参考文�?
- `docs/madExcept_Integration.md`

---

### 2. 异步处理功能重启
**状�?*: 🔴 待实�? 
**优先�?*: 🔥 �? 
**文件**: `ViewMainCode.pas`  
**预计工期**: 2-3�?

#### 当前被注释的功能
- [ ] `FAsyncProcessor` 异步处理器（�?21行）
- [ ] `FProgressController` 进度控制器（�?22行）
- [ ] 异步文件扫描
- [ ] 异步批量转换
- [ ] 进度取消功能（btnCancel，第99行）

#### 实施计划
1. 重构异步处理架构
2. 实现任务队列管理
3. 添加线程安全的进度回�?
4. 实现取消机制
5. 完善错误处理

---

### 3. 流式大文件处�?�?
**状�?*: �?已完�?(2025-12-07)  
**文件**: `EncodingConverter_Improved.pas`  

#### 已实现功�?
- `ConvertFileStreaming` 方法�?4KB 分块处理
- 支持任意大小文件�?2GB�?
- 内存占用控制�?64KB + 缓冲�?
- 支持进度回调 `TStreamingProgressCallback`
- 支持取消转换操作
- 正确处理 UTF-8/GBK/Big5 多字节编码块边界

---

## 🔧 中优先级任务 (P2 - 质量改进)

### P2-4: 错误处理策略统一
**状�?*: 🟡 部分完成  
**优先�?*: 🟡 P2  
**预计工期**: 3�?
**Code Review 建议**

#### 任务清单
- [x] 定义异常层次结构（EncodingExceptions.pas�?
- [x] 在核心编码路径使用领域异常（EncodingConverter_Improved / HelperFiles / ControllerCommandLine�?
- [ ] 添加异常上下文信�?
- [ ] 统一异常日志记录

---

### P2-5: 第二�?Code Review 问题收敛
**状�?*: 🟡 部分完成  
**优先�?*: 🟡 P2  
**预计工期**: 3-5�?

#### 任务清单
- [ ] 统一 BOM 清理逻辑：将 `EncodingConverter_Improved.pas` �?BOM/六字节清理代码重构为调用 `UtilsBOMCleaner.TBOMCleaner.CleanUTF8Artifacts`（Issue #3，核心编码路径已完成 2025-12-06�?
- [ ] 统一检测阈值配置使用：接入 `TEncodingDetectionConfig.MinUTF8Confidence`，并�?`ControllerEncoding.DetectFileEncoding` 中使用配置阈值替代硬编码 0.75（Issue #4，MinUTF8/MinJapanese/MinKorean 已接�?2025-12-06�?
- [ ] 临时文件安全落地：在 `EncodingConverter_Improved.ConvertFile` / 控制器等路径中统一使用 `TTempFileSecurityManager.GetSecureTempFile` �?`SecureDeleteFile`（Issue #5，ConvertFile 主路径已接入 2025-12-06�?
- [ ] 为现有检测器和转换器添加基于 `InterfacesEncoding.pas` 的接口适配器，实现接口抽象层的真正落地（Task #14，`EncodingAdapters.pas` 已实现具体适配器与工厂；`TFileHelper.ConvertFile` 已改为通过 `IEncodingConverter`/`IEncodingConverterFactory` 调用核心转换逻辑，首个真实调用方落地 2025-12-06�?

---

### P2-6: 编码检测安全策略与适用范围说明
**状�?*: 🔴 待设计与实现  
**优先�?*: 🟡 P2  
**预计工期**: 1-2�?

> 目标：在产品层面明确编码检�?转换的“安全区”和“灰区”，通过 UI + 文档 + 配置，让用户对工具的适用范围有清晰预期，尽量避免批量误伤�?

#### 任务清单
- [ ] 设计并实现“检测结果对话框”：显示推断编码、置信度、备选编码列表，以及简单解释（例如：依据样本分�?字符覆盖率）
- [ ] 在批量转换入口增加“安全模�?高级模式”开关：
  - 安全模式�?
    - 低置信或多候选编码时默认仅标注，不直接转�?
    - 强制开启备份或仅输出到新目�?
  - 高级模式�?
    - 允许在低置信场景也自动转换，但需二次确认
- [ ] 为“已知源编码”场景提供清晰引导：当用户手动指定源编码时，跳过自动检测，减少误判
- [ ] 在自测集�?`Tests/SelfTest_Encoding.dpr` 中新增一组“含�?边界样本”测试（短文本、混合编码、损坏文件），验证安全模式下的行为：不崩溃、不 silent 误伤
- [ ] 为日志系统增加“检测决策”记录：�?DEBUG/INFO 级别输出检测步骤、候选列表与最终选择，便于问题排�?
- [ ] 新增或更新一份文档：`docs/EncodingSafetyAndUsage.md`（或�?`README.md` 添加“安全使用与适用范围”章节），明确：推荐场景、需人工确认的场景、强烈不建议的用�?

---

### 4. 完善日志系统
**状�?*: 🟡 部分完成  
**文件**: `UtilsEncodingLogger.pas`  
**预计工期**: 1�?

#### 待实现功�?
- [ ] 日志文件轮转（已�?FAutoRotate 变量但未实现�?
- [ ] 日志级别过滤（DEBUG/INFO/WARNING/ERROR�?
- [ ] JSON/XML 格式日志输出
- [ ] 性能追踪功能（记录关键操作耗时�?
- [ ] 完善 TEncodingFileLogger �?
- [ ] 日志压缩与归�?

---

### 5. 单元测试扩展
**状�?*: 🟡 部分完成  
**预计工期**: 2-3�?

#### 待扩展测�?
- [ ] 编码检测器完整测试（所有支持编码）
- [ ] 错误处理路径测试
- [ ] 并发转换测试
- [ ] 压力测试�?000+文件批量转换�?
- [ ] 异常输入测试扩展
- [ ] 性能基准测试自动�?

#### 推荐框架
- DUnitX 或继续扩展现有测试框�?

---

### 6. JCL 文件操作增强
**状�?*: 🔴 待实�? 
**文件**: `HelperFiles.pas`  
**预计工期**: 1�?

#### 优化内容
```pascal
uses JclFileUtils;

// 支持大文件（>2GB�?
function GetFileSize64(const FileName: string): Int64;

// 原子文件写入（防止写入失败导致数据损坏）
procedure SafeWriteFile(const FileName: string; const Data: TBytes);

// 文件备份机制
procedure CreateBackup(const FileName: string);
```

#### 任务清单
- [ ] 集成 `JclFileUtils` �?`HelperFiles.pas`
- [ ] 实现大文件支持（>2GB�?
- [ ] 添加文件原子操作
- [ ] 实现自动文件备份
- [ ] 优化文件锁定处理
- [ ] 添加文件完整性校�?

---

### 7. 内存管理优化
**状�?*: 🔴 待实�? 
**预计工期**: 1-2�?

#### 优化方案
```pascal
// 实现对象池模式减少频繁创建销�?
type
  TEncodingBufferPool = class
  private
    FBufferPool: TObjectList<TBytes>;
  public
    function AcquireBuffer(Size: Integer): TBytes;
    procedure ReleaseBuffer(const Buffer: TBytes);
  end;
```

#### 任务清单
- [ ] 实现 `TEncodingBufferPool` 对象�?
- [ ] 实现 `TStreamPool` 流对象池
- [ ] 优化频繁分配释放的缓冲区
- [ ] 添加内存使用监控
- [ ] 性能对比测试

---

## 💡 低优先级任务

### 8. UI/UX 增强
**状�?*: 🔴 待实�? 
**预计工期**: 2-3�?

#### 功能清单
- [ ] 文件拖放支持
- [ ] 转换历史记录
- [ ] 转换预览功能
- [ ] 改进进度显示（百分比、速度、剩余时间）
- [ ] 主题切换支持（明�?暗黑�?
- [ ] 多语言界面支持

---

### 9. 命令行工具完�?
**状�?*: 🔴 待实�? 
**预计工期**: 1�?

#### 当前状�?
- README.md 中有文档但未完全实现

#### 待实现功�?
```bash
# 单文件转�?
DeepCharset.exe -s utf8 -t utf16 input.txt output.txt

# 批量转换
DeepCharset.exe -r -b -s auto -t utf8 C:\MyFiles\

# 静默模式
DeepCharset.exe -q -s gbk -t utf8 input.txt output.txt

# 生成报告
DeepCharset.exe -report result.json -s auto -t utf8 C:\Files\
```

#### 任务清单
- [ ] 实现完整命令行参数解�?
- [ ] 添加批量转换支持
- [ ] 实现静默模式
- [ ] 添加进度输出到控制台
- [ ] 生成JSON/XML格式报告
- [ ] 编写命令行使用文�?

---

### 10. 代码重构
**状�?*: 🔴 待实�? 
**预计工期**: 持续进行

#### 重构目标
- [ ] 消除代码重复（编码检测逻辑在多处重复）
- [ ] 提取公共错误处理方法
- [ ] 统一命名规范
- [ ] 减少嵌套层级（部分方法超�?层）
- [ ] 消除魔法数字（如 MIN_CONFIDENCE = 0.75�?
- [ ] 改进全局状态管�?

#### 策略模式重构
```pascal
// 统一编码检测接�?
type
  IEncodingDetector = interface
    function Detect(const Buffer: TBytes): TEncodingDetectionResult;
  end;

  TUTF8Detector = class(TInterfacedObject, IEncodingDetector)
  TChineseDetector = class(TInterfacedObject, IEncodingDetector)
  TJapaneseDetector = class(TInterfacedObject, IEncodingDetector)
```

---

### 11. 错误处理增强
**状�?*: 🔴 待实�? 
**预计工期**: 1�?

#### 实施方案
```pascal
// 定义自定义异常类�?
type
  EEncodingException = class(Exception);
  EEncodingDetectionException = class(EEncodingException);
  EEncodingConversionException = class(EEncodingException);
  EFileAccessException = class(EEncodingException);
  EInvalidEncodingException = class(EEncodingException);
```

#### 任务清单
- [ ] 定义异常层次结构
- [ ] 替换通用 Exception 为具体异常类�?
- [ ] 添加异常上下文信�?
- [ ] 完善异常处理策略
- [ ] 记录异常日志

---

### 12. JCL 容器优化
**状�?*: 🔴 待实�? 
**优先�?*: 🟡 �? 
**预计工期**: 1�?

#### 优化目标
```pascal
uses JclContainers;

// 使用高性能 HashMap 替代字符串列�?
type
  TEncodingCache = class
  private
    FCache: IJclMap<string, TEncodingDetectionInfo>;
  public
    constructor Create;
    procedure AddToCache(const FileName: string; const Info: TEncodingDetectionInfo);
    function GetFromCache(const FileName: string): TEncodingDetectionInfo;
  end;
```

#### 性能目标
- 编码检测结果缓存（避免重复检测）
- 文件列表处理速度提升 2-3 �?
- 内存占用优化

#### 任务清单
- [ ] 创建编码检测结果缓�?
- [ ] 使用 `TJclHashMap` 优化查找
- [ ] 实现对象池模�?
- [ ] 批量操作性能测试

---

## 📝 文档任务

### 13. API 文档
**状�?*: 🔴 待创�? 
**预计工期**: 1�?

#### 内容清单
- [ ] 创建 API 参考文�?
- [ ] 添加使用示例
- [ ] 创建架构设计文档
- [ ] 添加常见问题解答（FAQ�?
- [ ] 编写集成指南
- [ ] 生成 XML 文档注释

---

### 14. 代码注释完善
**状�?*: 🟡 部分完成  
**预计工期**: 持续进行

#### 待添加注释的地方
- [ ] 复杂的编码检测算�?
- [ ] 字节序列匹配逻辑
- [ ] 置信度计算方�?
- [ ] 文件操作重试机制
- [ ] 性能优化关键�?
- [ ] 线程安全说明

---

## 🎯 版本规划

### v2.0.1 (已完�? - 关键问题修复
**实际完成**: 2025-12-06

- P0/P1 关键问题已全部完成，详见 `hiDeepDeepDeepDeepDeepStory.md` �?`bugfix.md`

---

### v2.1.0 (计划�? - 架构优化与测试完�?
**预计发布**: 2026-01
**依赖**: v2.0.1 P0/P1任务完成

#### 架构改进
- [ ] 接口抽象层引�?(P1-2)
- [ ] 错误处理统一 (P2-4)
- [x] 魔法数字常量�?(P2-3 已完�?2025-12-06)

#### 测试增强
- [x] 数据完整性验�?(P2-1 已完�?2025-12-06)
- [x] 边界条件测试 (P2-2 已完�?2025-12-06)
- [ ] Fuzzing测试

---

### v2.2.0 (计划�? - 异步与大文件
**预计发布**: 2026-03

- [ ] 异步处理功能
- [ ] 流式大文件处�?
- [ ] 完善日志系统
- [ ] madExcept 完整集成

---

### v2.3.0 (计划�? - 性能与稳定�?
**预计发布**: 2026-Q2

- [ ] JCL 文件操作增强
- [ ] 内存管理优化
- [ ] JCL 容器优化
- [ ] 代码重构

---

### v3.0.0 (远期规划) - 功能扩展
**预计发布**: 2026-Q3

- [ ] 命令行工具完�?
- [ ] UI/UX 增强
- [ ] 插件系统
- [ ] 云同步支�?
- [ ] AI 编码检�?

---

## 📊 技术债务清单

### 待偿还的技术债务

1. **硬编码问�?*
   - 魔法数字散落各处（如 MIN_CONFIDENCE = 0.75�?
   - 需要提取为配置常量

2. **命名不一�?*
   - 变量命名规范需统一
   - 方法命名需遵循统一约定

3. **嵌套层级过深**
   - 部分方法嵌套超过4�?
   - 需要提取子方法

4. **全局状态依�?*
   - 使用全局变量 `InitializeGlobalVariables`
   - 需要重构为单例模式或依赖注�?

5. **资源管理不完�?*
   - 部分地方未使�?try-finally 保护
   - 需要全面检查资源释�?

---

## 🤝 贡献指南

1. 从待办列表选择任务
2. 在本文档标记�?`[x]` 进行�?
3. 创建功能分支 `feature/task-name`
4. 完成开发和测试
5. 更新相关文档
6. 提交 Pull Request
7. 完成后移动到 `hiDeepDeepDeepDeepDeepStory.md`

---

## 📅 更新日志

### 2025-12-06
- 🔍 **Code Review 完成** - 盘古、鲁班、仙儿、李冰团队审�?
- 🔴 **发现关键问题** - 11个严重问�? 10个中等问�?
- 📋 **新增任务** - P0/P1/P2 三级任务清单 (11�?
- 🐛 **更新 bugfix.md** - 记录Bug #5-#10
- 📆 **更新版本规划** - v2.0.1 关键修复版本
- 📄 **更新 hiDeepDeepDeepDeepDeepStory.md** - 记录Code Review事件

**下一�?*: 开�?P2 质量改进任务开发（数据完整性验证、边界条件测试、魔法数字常量化、错误处理统一），目标�?v2.1.0 �?2026-01 完成

---

### 2025-12-07
- 🐛 新增 Bug #11-#17（代码审查发现）
- �?修复 Bug #12, #14, #15（安全与线程问题�?
- �?修复 Bug #18-#19（编译错误）
- 📋 已完成任务移�?hiDeepDeepDeepDeepDeepStory.md
- 📋 对齐 bugfix.md �?hiDeepDeepDeepDeepDeepStory.md

### 2025-11-08
- 📋 重新整理任务清单
- 📋 已完成任务移�?`hiDeepDeepDeepDeepDeepStory.md`
- 📋 已修�?Bug 移至 `bugfix.md`
- 📋 更新版本规划
- 📋 明确任务优先级和预计工期

---

**维护�?*: DeepCharset 开发团�? 
**最后更�?*: 2025-12-07
