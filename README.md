# DeepCharset

码到成功

> 高性能文本编码检测与转换工具

当前状态：`开源整理中，可公开`

## 项目简�?

DeepCharset 是一个高性能的文本文件编码检测与转换工具，可以轻松地将各种格式的文本文件从一种字符编码转换为另一种字符编码�?

> ⚠️ 编码检测本质上是启发式的统计过程，尤其在短文本、损坏文件或混合编码场景下，无法保证 100% 准确�?
> 本工具的设计目标是：在提供尽可能可靠的检测与转换能力的同时，通过“预�?+ 备份 + 安全模式”等手段，尽量降低批量误伤的风险�?

### 主要功能

- 支持自动检测文件编�?
- 支持多种编码格式（UTF-8、UTF-16、UTF-32、ASCII、ANSI等）
- 高性能批量文件处理
- 可视化预览转换结�?
- 多线程并行处�?
- 自动备份原始文件

## 安装说明

### 系统需�?

- Windows 7/8/10/11
- 不需要额外的依赖�?

### 下载与安�?

1. 从后续发布页下载最新版�?
2. 解压缩到您选择的文件夹
3. 运行 `DeepCharset.exe`

## 使用指南

### 单个文件转换

1. 点击"选择文件"按钮选择要转换的文件
2. 选择源文件编码（或使用自动检测）
3. 选择目标编码
4. 点击"转换"按钮

### 批量文件处理

1. 切换�?批量处理"选项�?
2. 点击"添加文件"或将文件拖放到列表中
3. 选择目标编码
4. 点击"批量转换"按钮

### 命令行使�?

```
DeepCharset.exe [选项] <输入文件> <输出文件>

选项:
  -s, --source <编码>   源文件编�?
  -t, --target <编码>   目标文件编码
  -b, --backup          创建备份
  -r, --recursive       递归处理目录
  -v, --verbose         显示详细信息
```

示例:
```
DeepCharset.exe -s utf8 -t utf16 input.txt output.txt
DeepCharset.exe -r -b -s auto -t utf8 C:\MyFiles\
```

## 开发者信�?

### 构建项目

1. 克隆仓库:
   ```
   git clone https://github.com/ODDFounder/DeepCharset.git
   ```

2. 使用Delphi IDE打开项目文件 `DeepCharset.dproj`

3. 编译项目

也可以使用批处理脚本编译:
```
build.bat
```

### 异常处理与崩溃报�?

本项目现已统一采用 `madExcept` 进行异常捕获与崩溃报告。配置与使用请参考：`docs/madExcept_Integration.md`�?

### 运行测试

```
build.bat --run-tests
```

或者直接运行测试程�?
```
bin\EncodingTestRunner.exe
```

### 自测脚本与日志查�?

项目包含一套自测与回归脚本，位于根目录�?

```
tests_run.bat [/crit] [/cp] [/quick] [/openlogs] [/perf]
```

- `/crit` 仅运行关�?UTF-8 BOM 清理与跨码页回归（更快）�?
- `/cp` 仅运行跨码页回归（GBK/Big5 等）�?
- `/quick` 超快速冒烟测试（�?3 个核心用例，<10s）�?
- `/openlogs` 运行结束后自动打开日志文件�?
- `/perf` 追加一次性能计时（对 `/crit` 模式），输出�?`tmp_tests/perf_log.txt`�?

运行完成后会 tail `tmp_tests/selftest_log.txt` 的末�?200 行，便于快速查看结果�?

可选调试开关（默认关闭）：

- `Tests/SelfTest_Encoding.dpr` 顶部�?`DEBUG_CP2_DIAG`：Big5 路径诊断（源/输出十六进制头、WinAPI 解码对照）�?
- `EncodingConverter_Improved.pas` 顶部�?`DEBUG_CONVERT_TRACE`：转换器内部 trace，输出到 `tmp_tests/convert_trace.txt`�?

跨码页注意事项：

- 如已知源�?Big5，请使用字符�?`'950'` 指定；GBK 使用 `'GBK'`（或 `936`）�?
- 当目标为 `UTF-8` �?`UTF-8 with BOM` 时，转换器会统一清理“内�?BOM 片段 (EF BB BF)”与“误�?ANSI 后再�?UTF-8 的六字节序列 (C3 AF C2 BB C2 BF)”�?

### 常见问题（FAQ�?

1. 何时使用 `950` �?`Big5`�?
   - 建议在转换参数中直接使用字符�?`'950'` 作为源编码，避免别名差异；日志与诊断会标�?codepage 与名称映射�?

2. 何时使用 `936` �?`GBK`�?
   - 二选一均可。测试中�?`'GBK'` 便于可读，或�?`936` 保持一致性�?

3. 如何判断“中文被误伤”？
   - 自测日志会输出键值对：`okClean/leadOK/keepCN/head/tail`。若 `keepCN=False`，观�?`head/tail` 片段，结合源样本定位差异�?

4. 如何开启诊断日志？
   - �?`Tests/SelfTest_Encoding.dpr` 顶部设置 `DEBUG_CP2_DIAG := True;`�?
   - �?`EncodingConverter_Improved.pas` 顶部设置 `DEBUG_CONVERT_TRACE := True;`�?
   - 运行 `tests_run.bat /openlogs` 自动打开日志�?

### 故障排查

常见错误与解决方案：

1. **转换后中文乱�?*
   - 检查源编码是否正确指定（Big5 �?`'950'`，GBK �?`'GBK'` �?`936`�?
   - 查看日志中的 `keepCN=False` �?`head/tail` 片段定位问题
   - 开�?`DEBUG_CP2_DIAG` 查看源文�?HEX �?WinAPI 解码结果

2. **UTF-8 文件出现 `?unit` 等乱�?*
   - 这是内嵌 BOM 片段导致，转换器已自动清�?
   - 确认目标编码�?`UTF-8` �?`UTF-8 with BOM`
   - 查看 `[47]` 系列测试用例确认清理逻辑

3. **转换后文件为�?*
   - 检查源文件是否可读（权�?占用�?
   - 查看 `tmp_tests/selftest_log.txt` 中的错误信息
   - 确认源编码与实际文件编码匹配

4. **性能问题（大文件转换慢）**
   - 使用 `/perf` 参数测量基准耗时
   - 检查是否开启了调试开关（`DEBUG_CONVERT_TRACE`�?
   - 大文件（>100MB）建议分批处�?

### 项目结构

- `ModelEncoding.pas` - 编码模型和核心逻辑
- `UtilsEncodingMemory.pas` - 内存管理工具
- `UtilsEncodingPerformance.pas` - 性能相关工具
- `ViewMainCode.pas` - 用户界面
- `Tests/` - 测试用例
- `docs/madExcept_Integration.md` - madExcept 集成指南

## 贡献指南

欢迎提交问题报告和代码贡�?

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -am 'Add your feature'`)
4. 推送到分支 (`git push origin feature/your-feature`)
5. 创建 Pull Request

## 许可�?

本项目采�?MIT 许可�?- 详情请参�?[LICENSE](LICENSE) 文件

## 作者与支持

Author: `ODDFounder / Fuyi / 付乙`

如有问题或建议，请优先通过以下方式联系�?

- Website: `www.goodmem.cn`
- Email: `fuyi.it@live.cn`
- WeChat: `17781158558`
- QQ: `624449684`
- GitHub Issues: 仓库公开后启�?
