# TransSuccess 待办任务清单

> 📝 **文档说明**
> - 已完成的任务已移至 `history.md`
> - 已修复的 Bug 已移至 `bugfix.md`
> - 本文档仅记录待办任务
>
> **最后更新**: 2025-11-08

---

## 🔥 高优先级任务

### 1. madExcept 完整集成
**状态**: 🔴 待实现  
**优先级**: 🔥 高  
**预计工期**: 1-2周

#### 任务清单
- [ ] 在 IDE 中为 Debug/Release 分别配置 madExcept 策略
- [ ] Debug：开启异常对话框与剪贴板复制
- [ ] Release：静默生成报告到 `./logs/` 目录
- [ ] 添加自测异常路径，验证报告生成
- [ ] 集成崩溃报告自动发送功能
- [ ] 添加异常日志记录到统一日志系统
- [ ] 整理/清理与 JCL 异常追踪相关的遗留代码

#### 参考文档
- `docs/madExcept_Integration.md`

---

### 2. 异步处理功能重启
**状态**: 🔴 待实现  
**优先级**: 🔥 高  
**文件**: `ViewMainCode.pas`  
**预计工期**: 2-3周

#### 当前被注释的功能
- [ ] `FAsyncProcessor` 异步处理器（第121行）
- [ ] `FProgressController` 进度控制器（第122行）
- [ ] 异步文件扫描
- [ ] 异步批量转换
- [ ] 进度取消功能（btnCancel，第99行）

#### 实施计划
1. 重构异步处理架构
2. 实现任务队列管理
3. 添加线程安全的进度回调
4. 实现取消机制
5. 完善错误处理

---

### 3. 流式大文件处理
**状态**: 🔴 待实现  
**优先级**: 🔥 高  
**文件**: `EncodingConverter_Improved.pas`  
**预计工期**: 1-2周

#### 问题描述
- 当前 `ConvertFile` 一次性读取最大50MB到内存
- 大文件（>100MB）会导致内存占用过高
- 缺乏流式处理支持

#### 实施方案
```pascal
const CHUNK_SIZE = 64 * 1024; // 64KB per chunk

function ConvertFileStreaming(
  const SourceFileName, TargetFileName: string;
  const SourceEncoding, TargetEncoding: string;
  const ProgressCallback: TProgressCallback = nil): TEncodingConversionResult;
// 实现分块读取、转换、写入
```

#### 性能目标
- 支持任意大小文件（>2GB）
- 内存占用控制在100MB以内
- 转换速度不低于当前实现

---

## 🔧 中优先级任务

### 4. 完善日志系统
**状态**: 🟡 部分完成  
**文件**: `UtilsEncodingLogger.pas`  
**预计工期**: 1周

#### 待实现功能
- [ ] 日志文件轮转（已有 FAutoRotate 变量但未实现）
- [ ] 日志级别过滤（DEBUG/INFO/WARNING/ERROR）
- [ ] JSON/XML 格式日志输出
- [ ] 性能追踪功能（记录关键操作耗时）
- [ ] 完善 TEncodingFileLogger 类
- [ ] 日志压缩与归档

---

### 5. 单元测试扩展
**状态**: 🟡 部分完成  
**预计工期**: 2-3周

#### 已完成
- ✅ UTF-8 BOM 清理测试
- ✅ 跨码页转换测试
- ✅ 边界条件测试
- ✅ 自动化性能回归检测

#### 待扩展测试
- [ ] 编码检测器完整测试（所有支持编码）
- [ ] 错误处理路径测试
- [ ] 并发转换测试
- [ ] 压力测试（1000+文件批量转换）
- [ ] 异常输入测试扩展
- [ ] 性能基准测试自动化

#### 推荐框架
- DUnitX 或继续扩展现有测试框架

---

### 6. JCL 文件操作增强
**状态**: 🔴 待实现  
**文件**: `HelperFiles.pas`  
**预计工期**: 1周

#### 优化内容
```pascal
uses JclFileUtils;

// 支持大文件（>2GB）
function GetFileSize64(const FileName: string): Int64;

// 原子文件写入（防止写入失败导致数据损坏）
procedure SafeWriteFile(const FileName: string; const Data: TBytes);

// 文件备份机制
procedure CreateBackup(const FileName: string);
```

#### 任务清单
- [ ] 集成 `JclFileUtils` 到 `HelperFiles.pas`
- [ ] 实现大文件支持（>2GB）
- [ ] 添加文件原子操作
- [ ] 实现自动文件备份
- [ ] 优化文件锁定处理
- [ ] 添加文件完整性校验

---

### 7. 内存管理优化
**状态**: 🔴 待实现  
**预计工期**: 1-2周

#### 优化方案
```pascal
// 实现对象池模式减少频繁创建销毁
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
- [ ] 实现 `TEncodingBufferPool` 对象池
- [ ] 实现 `TStreamPool` 流对象池
- [ ] 优化频繁分配释放的缓冲区
- [ ] 添加内存使用监控
- [ ] 性能对比测试

---

## 💡 低优先级任务

### 8. UI/UX 增强
**状态**: 🔴 待实现  
**预计工期**: 2-3周

#### 功能清单
- [ ] 文件拖放支持
- [ ] 转换历史记录
- [ ] 转换预览功能
- [ ] 改进进度显示（百分比、速度、剩余时间）
- [ ] 主题切换支持（明亮/暗黑）
- [ ] 多语言界面支持

---

### 9. 命令行工具完善
**状态**: 🔴 待实现  
**预计工期**: 1周

#### 当前状态
- README.md 中有文档但未完全实现

#### 待实现功能
```bash
# 单文件转换
TransSuccess.exe -s utf8 -t utf16 input.txt output.txt

# 批量转换
TransSuccess.exe -r -b -s auto -t utf8 C:\MyFiles\

# 静默模式
TransSuccess.exe -q -s gbk -t utf8 input.txt output.txt

# 生成报告
TransSuccess.exe -report result.json -s auto -t utf8 C:\Files\
```

#### 任务清单
- [ ] 实现完整命令行参数解析
- [ ] 添加批量转换支持
- [ ] 实现静默模式
- [ ] 添加进度输出到控制台
- [ ] 生成JSON/XML格式报告
- [ ] 编写命令行使用文档

---

### 10. 代码重构
**状态**: 🔴 待实现  
**预计工期**: 持续进行

#### 重构目标
- [ ] 消除代码重复（编码检测逻辑在多处重复）
- [ ] 提取公共错误处理方法
- [ ] 统一命名规范
- [ ] 减少嵌套层级（部分方法超过4层）
- [ ] 消除魔法数字（如 MIN_CONFIDENCE = 0.75）
- [ ] 改进全局状态管理

#### 策略模式重构
```pascal
// 统一编码检测接口
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
**状态**: 🔴 待实现  
**预计工期**: 1周

#### 实施方案
```pascal
// 定义自定义异常类型
type
  EEncodingException = class(Exception);
  EEncodingDetectionException = class(EEncodingException);
  EEncodingConversionException = class(EEncodingException);
  EFileAccessException = class(EEncodingException);
  EInvalidEncodingException = class(EEncodingException);
```

#### 任务清单
- [ ] 定义异常层次结构
- [ ] 替换通用 Exception 为具体异常类型
- [ ] 添加异常上下文信息
- [ ] 完善异常处理策略
- [ ] 记录异常日志

---

### 12. JCL 容器优化
**状态**: 🔴 待实现  
**优先级**: 🟡 中  
**预计工期**: 1周

#### 优化目标
```pascal
uses JclContainers;

// 使用高性能 HashMap 替代字符串列表
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
- 文件列表处理速度提升 2-3 倍
- 内存占用优化

#### 任务清单
- [ ] 创建编码检测结果缓存
- [ ] 使用 `TJclHashMap` 优化查找
- [ ] 实现对象池模式
- [ ] 批量操作性能测试

---

## 📝 文档任务

### 13. API 文档
**状态**: 🔴 待创建  
**预计工期**: 1周

#### 内容清单
- [ ] 创建 API 参考文档
- [ ] 添加使用示例
- [ ] 创建架构设计文档
- [ ] 添加常见问题解答（FAQ）
- [ ] 编写集成指南
- [ ] 生成 XML 文档注释

---

### 14. 代码注释完善
**状态**: 🟡 部分完成  
**预计工期**: 持续进行

#### 待添加注释的地方
- [ ] 复杂的编码检测算法
- [ ] 字节序列匹配逻辑
- [ ] 置信度计算方法
- [ ] 文件操作重试机制
- [ ] 性能优化关键点
- [ ] 线程安全说明

---

## 🎯 版本规划

### v1.3.0 (计划中) - 异步与大文件
**预计发布**: 2025-12

- [ ] 异步处理功能（任务2）
- [ ] 流式大文件处理（任务3）
- [ ] 完善日志系统（任务4）
- [ ] madExcept 完整集成（任务1）
- [ ] 单元测试扩展（任务5）

### v1.4.0 (计划中) - 性能与稳定性
**预计发布**: 2026-Q1

- [ ] JCL 文件操作增强（任务6）
- [ ] 内存管理优化（任务7）
- [ ] JCL 容器优化（任务12）
- [ ] 错误处理增强（任务11）
- [ ] 代码重构（任务10）

### v2.0.0 (远期规划) - 功能扩展
**预计发布**: 2026-Q2

- [ ] 命令行工具完善（任务9）
- [ ] UI/UX 增强（任务8）
- [ ] 插件系统
- [ ] 云同步支持
- [ ] AI 编码检测

---

## 📊 技术债务清单

### 待偿还的技术债务

1. **硬编码问题**
   - 魔法数字散落各处（如 MIN_CONFIDENCE = 0.75）
   - 需要提取为配置常量

2. **命名不一致**
   - 变量命名规范需统一
   - 方法命名需遵循统一约定

3. **嵌套层级过深**
   - 部分方法嵌套超过4层
   - 需要提取子方法

4. **全局状态依赖**
   - 使用全局变量 `InitializeGlobalVariables`
   - 需要重构为单例模式或依赖注入

5. **资源管理不完整**
   - 部分地方未使用 try-finally 保护
   - 需要全面检查资源释放

---

## 🤝 贡献指南

1. 从待办列表选择任务
2. 在本文档标记为 `[x]` 进行中
3. 创建功能分支 `feature/task-name`
4. 完成开发和测试
5. 更新相关文档
6. 提交 Pull Request
7. 完成后移动到 `history.md`

---

## 📅 更新日志

### 2025-11-08
- 📋 重新整理任务清单
- 📋 已完成任务移至 `history.md`
- 📋 已修复 Bug 移至 `bugfix.md`
- 📋 更新版本规划
- 📋 明确任务优先级和预计工期

---

**维护者**: TransSuccess 开发团队  
**最后更新**: 2025-11-08
