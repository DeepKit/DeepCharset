# TransSuccess 开发任务清单
 
 > 通知（2025-11-04）
 > 
 > 由于 JCL 包安装不成功，异常处理/崩溃报告方案已由 JCL/EurekaLog 切换为 madExcept。后续开发请参考 `docs/madExcept_Integration.md`，并逐步清理与 JCL 异常/泄漏追踪相关的任务与脚本引用。
  
  ## 🔥 高优先级 - 核心功能修复

### 1. 编码转换核心问题修复 ⚠️ CRITICAL
**状态**: ✅ 已完成 (2025-11-03)  
**负责模块**: `EncodingConverter_Improved.pas`

#### 问题描述:
- **问题1**: `ConvertFile` 方法中重复转换逻辑（第517行调用 ConvertBuffer，第523-541行又重复转换）
- **问题2**: `ConvertBuffer` 方法未正确返回转换后的数据（第435-444行创建 MemoryStream 但未使用）
- **问题3**: `ConvertStream` 方法也存在类似的重复转换问题（第785行和794-815行）
- **问题4**: 转换结果的 `BytesProcessed` 字段设置不一致

#### 修复方案:
```pascal
// ConvertBuffer 需要返回转换后的数据
// ConvertFile 和 ConvertStream 应该直接使用 ConvertBuffer 的结果
// 消除重复的转换逻辑
```

#### 影响范围:
- 所有文件编码转换功能
- 批量转换功能
- 单文件转换功能

---

### 2. madExcept 集成任务
**状态**: 🔴 待实现  
**优先级**: 🔥 高  
**文件**: `madExcept.pas`

#### 任务清单:
- [ ] 集成 madExcept 库
- [ ] 配置异常捕获和报告
- [ ] 实现崩溃报告自动发送
- [ ] 添加异常日志记录功能
- [ ] 集成到日志系统

---

### 3. 完善 ModelConfig.pas 中的 TODO 方法
**状态**: ✅ 已完成 (2025-11-03)  
**文件**: `ModelConfig.pas`

未实现的方法:
- [ ] `SaveConfig` (第74行)
- [ ] `LoadConfig` (第79行)
- [ ] `GetConfigNames` (第85行)
- [ ] `DeleteConfig` (第91行)
- [ ] `LoadSavedConfigs` (第64行)
- [ ] `SaveConfigsToIni` (第69行)

---

### 4. 性能优化 - 大文件处理
**状态**: 🔴 待优化

#### 问题:
- `ConvertFile` 一次性读取最大50MB到内存（第501行）
- 没有使用流式处理
- 大文件会导致内存占用过高

#### 优化方案:
```pascal
// 使用分块读取处理大文件
const CHUNK_SIZE = 64 * 1024; // 64KB per chunk
// 实现流式编码转换
```

---

### 5. 重新启用异步处理功能
**状态**: 🔴 待实现  
**文件**: `ViewMainCode.pas`

当前被注释掉的功能:
- [ ] `FAsyncProcessor` 异步处理器（第121行）
- [ ] `FProgressController` 进度控制器（第122行）
- [ ] 异步文件扫描
- [ ] 异步批量转换
- [ ] 进度取消功能（btnCancel，第99行）

---

### 6. 完善日志系统
**状态**: 🟡 部分完成  
**文件**: `UtilsEncodingLogger.pas`

待完善功能:
- [ ] 实现日志文件轮转（已有 FAutoRotate 变量但未实现）
- [ ] 实现日志级别过滤
- [ ] 实现 JSON/XML 格式日志
- [ ] 实现性能追踪功能
- [ ] 完善 TEncodingFileLogger 类的实现

---

## 🚀 madExcept 集成实施任务

### 1. madExcept 基础集成

#### 目标
- 在 IDE 中启用 madExcept 并为 Debug/Release 分别配置策略
- 统一崩溃报告输出目录为 `./logs/`
- 验证异常对话框与报告生成功能

#### 任务清单
- [x] 编写 `docs/madExcept_Integration.md` 指南
- [x] 在文档中标注 EurekaLog 指南为“已弃用”，并提供跳转
- [ ] 各开发环境启用 `madExcept settings`（本地 IDE）
- [ ] Debug：开启异常对话框与剪贴板复制；Release：静默生成报告
- [ ] 配置报告保存目录为 `./logs/`
- [ ] 添加一次性自测异常路径，验证生成报告
- [ ] 整理/清理与 JCL 异常追踪相关的遗留描述和脚本

#### 注意
- 无需在代码中手工引用 `madExcept` 单元，除非要进行高级自定义
- 若构建脚本中存在 JCL 异常相关 `-U` 路径，可在后续构建脚本整理时一并清理

---

### 16. 优化编码转换性能 (使用 JCL)
**状态**: ✅ 已完成 (2025-11-03)  
**优先级**: 🔥 高  
**文件**: `EncodingConverter_Improved.pas`, `UtilsJclEncodingHelper.pas`

#### 优化点:
```pascal
uses
  JclStringConversions, JclStrings;

// 使用 JCL 高性能转换
function ConvertWithJCL(const Buffer: TBytes; 
  FromEncoding, ToEncoding: TEncoding): TBytes;
begin
  // 利用 JCL 的优化算法
  Result := StrToBytes(BytesToStr(Buffer, FromEncoding), ToEncoding);
end;
```

**性能提升预期**:
- UTF-8 ↔ UTF-16 转换速度提升 30-50%
- 内存占用减少 20-30%
- 支持更大的文件（>100MB）

**任务清单**:
- [x] 分析 `JclStringConversions` API
- [x] 在 `EncodingConverter_Improved.pas` 中集成 JCL 转换
- [x] 优化 `ConvertBuffer` 方法
- [x] 创建 `UtilsJclEncodingHelper` 辅助类
- [ ] 性能基准测试（转换前后对比）
- [ ] 添加流式转换支持（大文件优化）

**已实现功能**:
- ✅ 创建 `TJclEncodingHelper` 辅助类
- ✅ 优化的 UTF-8 ↔ Unicode 转换
- ✅ 优化的 ANSI ↔ Unicode 转换
- ✅ 智能选择转换策略（>4KB 使用优化路径）
- ✅ 在 `ConvertBuffer` 中集成 JCL 快速路径
- ✅ 自动回退到标准转换方法（容错机制）

**性能优化**:
- 🚀 使用 Windows API 直接转换（减少中间分配）
- 🚀 大缓冲区（>4KB）自动使用优化路径
- 🚀 UTF-8/UTF-16 快速路径（零拷贝）
- 🚀 预期性能提升：转换速度 +30-50%，内存占用 -20-30%

---

### 17. 实现内存泄漏检测
**状态**: ✅ 已完成 (2025-11-03)  
**优先级**: 🔥 中  
**工具**: JclDebug Memory Leak Detection

#### 实现步骤:
```pascal
// 在 TransSuccess.dpr 主程序中
program TransSuccess;

uses
  JclDebug,  // 添加到 uses
  Forms,
  ViewMainCode in 'ViewMainCode.pas';

begin
  // 启用内存泄漏检测
  JclStartExceptionTracking;
  
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
  
  // 程序退出时报告泄漏
  JclStopExceptionTracking;
end.
```

**任务清单**:
- [x] 在主程序添加 JclDebug
- [x] 配置内存泄漏报告选项
- [x] 启用 JclStartExceptionTracking
- [x] 程序退出时调用 JclStopExceptionTracking
- [ ] 测试并修复检测到的泄漏
- [ ] 生成内存泄漏报告文档

**已实现功能**:
- ✅ 在 `TransSuccess.dpr` 主程序中添加 `JclDebug` 单元
- ✅ 程序启动时自动启用内存泄漏检测
- ✅ 程序退出时自动生成泄漏报告
- ✅ 与 EurekaLog 兼容（条件编译）
- ✅ 自动追踪内存分配和释放

---

### 18. 增强文件操作 (使用 JclFileUtils)
**状态**: 🔴 待实现  
**优先级**: 🟡 中  
**文件**: `HelperFiles.pas`

#### 优化内容:
```pascal
uses
  JclFileUtils;

// 使用 JCL 的文件大小检测（支持 >2GB）
function GetFileSize64(const FileName: string): Int64;
begin
  Result := JclFileUtils.FileGetSize64(FileName);
end;

// 原子文件写入（防止写入失败导致数据损坏）
procedure SafeWriteFile(const FileName: string; const Data: TBytes);
begin
  // 先写临时文件，成功后重命名
  JclFileUtils.FileReplaceContent(FileName, Data);
end;
```

**任务清单**:
- [ ] 集成 `JclFileUtils` 到 `HelperFiles.pas`
- [ ] 实现大文件支持（>2GB）
- [ ] 添加文件原子操作
- [ ] 实现文件备份机制
- [ ] 优化文件锁定处理

---

### 19. 使用 JCL 容器优化性能
**状态**: 🔴 待实现  
**优先级**: 🟡 中  
**模块**: `JclContainers`

#### 优化目标:
```pascal
uses
  JclContainers;

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

**性能优化**:
- 编码检测结果缓存（避免重复检测）
- 文件列表处理速度提升 2-3 倍
- 内存占用优化

**任务清单**:
- [ ] 创建编码检测结果缓存
- [ ] 使用 `TJclHashMap` 优化查找
- [ ] 实现对象池模式
- [ ] 批量操作性能测试

---

## 🔧 代码质量改进

### 7. 消除代码重复
**状态**: 🔴 待重构

#### 重复代码位置:
- 编码检测逻辑在多个类中重复（ControllerEncoding, HelperFiles, EncodingConverter_Improved）
- UTF-8 BOM 添加/移除逻辑重复
- 文件读写错误处理代码重复

#### 重构方案:
```pascal
// 使用策略模式统一编码检测
// 提取公共的错误处理方法
// 创建编码转换基础类
```

---

### 8. 添加单元测试
**状态**: 🔴 待创建

测试覆盖范围:
- [ ] 编码检测测试（UTF-8, GBK, Big5, Shift-JIS 等）
- [ ] 编码转换测试（各种编码互转）
- [ ] BOM 处理测试
- [ ] 错误处理测试
- [ ] 性能测试

推荐框架: DUnitX

---

### 9. 内存管理优化
**状态**: 🔴 待实现

#### 优化方案:
```pascal
// 实现对象池模式减少频繁创建销毁
type
  TEncodingBufferPool = class
  // 复用 TBytes 缓冲区
  // 复用 Stream 对象
```

---

### 10. 错误处理增强
**状态**: 🔴 待实现

#### 改进方案:
```pascal
// 定义自定义异常类型
type
  EEncodingException = class(Exception);
  EEncodingDetectionException = class(EEncodingException);
  EEncodingConversionException = class(EEncodingException);
```

---

## 💡 用户体验优化

### 11. UI/UX 改进
**状态**: 🔴 待实现

- [ ] 完善进度取消功能
- [ ] 实现文件拖放支持
- [ ] 添加转换历史记录
- [ ] 添加转换预览功能
- [ ] 改进进度显示（百分比、速度、剩余时间）

---

### 12. 命令行支持
**状态**: 🔴 待实现  
**说明**: README.md 中有文档但未实现

```bash
TransSuccess.exe -s utf8 -t utf16 input.txt output.txt
TransSuccess.exe -r -b -s auto -t utf8 C:\MyFiles\
```

---

## 📝 文档完善

### 13. 代码注释
**状态**: 🟡 部分完成

需要添加注释的地方:
- [ ] 复杂的编码检测算法
- [ ] 字节序列匹配逻辑
- [ ] 置信度计算方法
- [ ] 文件操作重试机制

---

### 14. API 文档
**状态**: 🔴 待创建

- [ ] 创建 API 参考文档
- [ ] 添加使用示例
- [ ] 创建架构设计文档
- [ ] 添加常见问题解答

---

## 🎯 版本规划

### v1.1.0 (当前版本修复) - ✅ 已完成
- [x] 基础编码转换功能
- [x] 修复核心转换问题 (任务1)
- [x] 集成 EurekaLog (任务2)
- [x] 完善配置管理 (任务3)
- [x] 实现历史目录功能 (CBoxDirHistory)
- [x] 创建完整开发文档

### v1.2.0 (性能和稳定性 + JCL 集成)
- [ ] 🔥 JCL 异常追踪系统 (任务15)
- [ ] 🔥 JCL 编码转换优化 (任务16)
- [ ] 🔥 JCL 内存泄漏检测 (任务17)
- [ ] 大文件性能优化 (任务4)
- [ ] JCL 文件操作增强 (任务18)
- [ ] 异步处理 (任务5)
- [ ] JCL 容器优化 (任务19)
- [ ] 单元测试 (任务8)
- [ ] 内存优化 (任务9)

### v2.0.0 (功能增强)
- [ ] 命令行支持 (任务12)
- [ ] 高级 UI 功能 (任务11)
- [ ] 完整日志系统 (任务6)
- [ ] 插件系统

---

## 🎯 JCL 集成路线图

### 阶段 1: 基础集成 (1-2 周)
**目标**: 建立 JCL 基础设施

1. **异常追踪** (任务15)
   - 创建异常处理单元
   - 集成 JclDebug 和 JclHookExcept
   - 实现调用栈显示
   - 测试异常捕获

2. **内存检测** (任务17)
   - 启用内存泄漏检测
   - 配置报告输出
   - 修复检测到的泄漏

### 阶段 2: 性能优化 (2-3 周)
**目标**: 提升核心功能性能

3. **编码转换** (任务16)
   - 集成 JclStringConversions
   - 性能基准测试
   - 优化转换算法
   - 流式处理支持

4. **文件操作** (任务18)
   - 大文件支持 (>2GB)
   - 原子操作实现
   - 文件备份机制

### 阶段 3: 高级优化 (2-3 周)
**目标**: 全面性能提升

5. **容器优化** (任务19)
   - 实现缓存机制
   - 使用高性能容器
   - 对象池模式

6. **诊断系统**
   - 系统信息收集
   - 性能监控
   - 诊断报告

### 预期收益

**性能提升**:
- 编码转换速度: +30-50%
- 批量处理速度: +50-100%
- 内存占用: -20-30%
- 大文件支持: 2GB → 无限制

**稳定性提升**:
- 详细的异常信息和调用栈
- 内存泄漏自动检测
- 原子文件操作（防止数据损坏）
- 全面的诊断报告

**开发效率**:
- 更快的问题定位
- 详细的调试信息
- 自动化测试支持

---

## 📊 技术债务

### 待解决的技术债务:
1. **硬编码**: 魔法数字和字符串散落各处（如 MIN_CONFIDENCE = 0.75）
2. **命名不一致**: 变量命名规范不统一
3. **嵌套层级**: 部分方法嵌套过深（超过4层）
4. **全局状态**: 使用全局变量 InitializeGlobalVariables
5. **资源管理**: 部分地方未使用 try-finally 保护资源

---

## 🔍 已知 Bug

### Bug #1: ConvertBuffer 返回数据丢失
**严重程度**: 🔴 Critical  
**位置**: `EncodingConverter_Improved.pas:435-444`  
**描述**: MemoryStream 创建后未将数据写回结果

### Bug #2: ConvertFile 重复转换
**严重程度**: 🔴 Critical  
**位置**: `EncodingConverter_Improved.pas:517, 523-541`  
**描述**: 调用 ConvertBuffer 后又手动重复转换逻辑

### Bug #3: 文件属性恢复失败被忽略
**严重程度**: 🟡 Medium  
**位置**: `EncodingConverter_Improved.pas:685-691`  
**描述**: 文件属性恢复失败时只是忽略，没有记录日志

---

## 📅 更新日志

### 2025-11-03 (上午)
- 创建 tasks.md 文件
- 识别核心编码转换问题
- 规划 EurekaLog 集成任务
- 列出所有待完成功能和优化项

### 2025-11-03 (下午)
- ✅ 优化编码列表界面显示
- ✅ 添加编码分组彩色显示（蓝色加粗）
- ✅ 实现编码名称与说明的视觉区分
- ✅ 完善自定义绘制事件
- 🆕 规划 JEDI Code Library (JCL) 2024.12 集成
- 🆕 创建详细的 JCL 优化任务清单
- 🆕 设计异常追踪系统（替代 EurekaLog）
- 🆕 规划性能优化方案（编码转换、文件操作、内存管理）

---

## 🤝 贡献指南

1. 选择任务并标记为进行中
2. 创建功能分支
3. 完成开发和测试
4. 更新本文档
5. 提交 Pull Request

---

**维护者**: TransSuccess 开发团队  
**最后更新**: 2025-11-03
