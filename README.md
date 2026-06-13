# DeepCharset

> 码到成功 · 高性能文本编码检测与转换工具

当前状态：`v2.0.1 稳定版 · 开源可用`

## 项目简介

DeepCharset 是一个面向 Windows 的文本文件编码检测与转换工具，可以将各种格式的文本文件从一种字符编码转换为另一种。

> ⚠️ 编码检测本质上是启发式的统计过程，尤其在短文本、损坏文件或混合编码场景下无法保证 100% 准确。
> 本工具的设计目标是：在提供尽可能可靠的检测与转换能力的同时，通过"预览 + 备份 + 安全模式"等手段，尽量降低批量误伤的风险。

### 主要功能

- 自动检测文件编码
- 支持 UTF-8 / UTF-16LE/BE / UTF-32 / GBK / GB18030 / Big5 / Shift-JIS / EUC-JP / EUC-KR 等 30+ 种编码的互转
- 高性能批量文件处理（大文件自动走流式路径）
- 可视化预览转换结果
- 自动备份原始文件（CLI 默认启用）
- GUI 与 CLI 双模式

## 安装说明

### 系统需求

- Windows 10 / 11（64 位）
- 无需额外运行时依赖（绿色版，解压即用）

### 开发者构建要求

- Embarcadero Delphi 13.1 (RAD Studio)
- Git（克隆仓库）
- 详见 [CONTRIBUTING.md](CONTRIBUTING.md)

### 下载与安装

1. 从发布页下载最新版本
2. 解压到任意目录
3. 运行 `DeepCharset.exe`

## 使用指南

### 图形界面

1. 点击"选择文件"
2. 选择源编码（或使用"自动检测"）
3. 选择目标编码
4. 点击"转换"

### 批量处理

1. 切换到"批量处理"选项卡
2. 将文件拖入列表，或点击"添加文件"
3. 选择目标编码
4. 点击"批量转换"

### 命令行

```
DeepCharset.exe [选项] <输入文件或目录>
```

常用选项：

```
-s, --source <编码>     源编码（默认 auto）
-t, --target <编码>     目标编码（默认 UTF-8）
-o, --output <文件>     输出路径（默认覆盖原文件）
-r, --recursive         递归处理目录
-b, --backup            创建 .bak 备份（CLI 默认启用）
    --no-backup         显式关闭备份
-q, --quiet             静默模式
    --verbose           显示详细信息
    --add-bom           输出添加 BOM
    --remove-bom        移除 BOM
-h, --help              查看帮助
-v, --version           查看版本
```

示例：

```bash
# GBK 转 UTF-8（默认自动创建 .bak）
DeepCharset.exe -s GBK -t UTF-8 input.txt

# 递归目录转换
DeepCharset.exe -s auto -t UTF-8 -r C:\MyFiles\

# 指定输出路径，不覆盖源文件
DeepCharset.exe -s Big5 -t UTF-8 input.txt -o output.txt

# 使用数字码页
DeepCharset.exe -s 936 -t 65001 input.txt
```

## 开发者信息

### 构建项目

```bash
# 克隆仓库
git clone https://github.com/ODDFounder/DeepCharset.git
cd DeepCharset

# 使用 Delphi 13.1 IDE 打开 DeepCharset.dproj 编译
# 或使用构建脚本（需要 scripts/env/delphi-13.1.bat）
build.bat            # Debug 构建
build.bat Release    # Release 构建
```

> **注意**：构建前需安装第三方组件（见 [CONTRIBUTING.md](CONTRIBUTING.md)）。  
> `madExcept` 当前禁用（代码中为占位桩）；若需异常追踪推荐 EurekaLog。

### 运行自测

```bash
tests_run.bat /quick       # 冒烟测试（<10s）
tests_run.bat /crit /perf  # 关键回归 + 性能计时
tests_run.bat /cp          # 跨码页回归（GBK/Big5）
```

- `/crit`   关键 UTF-8 BOM 清理 + 跨码页回归
- `/cp`     跨码页回归（GBK/Big5）
- `/quick`  冒烟测试（3 个核心用例）
- `/perf`   `/crit` 模式追加性能计时

## 常见问题

**Q: 何时使用 `950` 还是 `Big5`？**
A: 建议直接使用字符串 `'950'` 作为源编码，避免别名差异。

**Q: 何时使用 `936` 还是 `GBK`？**
A: 两者等价，任选其一。

**Q: 转换后出现乱码怎么办？**
A: 检查源编码指定是否正确；查看 `tmp_tests/selftest_log.txt` 中的 `keepCN=False` 与 `head/tail` 片段定位问题。可以开启 `DEBUG_CP2_DIAG` / `DEBUG_CONVERT_TRACE` 获取诊断日志。

**Q: UTF-8 文件出现 `?unit` 等乱码？**
A: 这是内嵌 BOM 片段导致，工具已自动清理。确认目标编码为 `UTF-8` 或 `UTF-8 with BOM`。

**Q: 大文件转换慢？**
A: `ConvertFile` 对 >16 MB 文件会自动走流式路径。若仍过慢，检查是否开启了 `DEBUG_CONVERT_TRACE`。

## 项目结构

- `DeepCharset.dpr` - 程序入口
- `ControllerEncoding.pas` - 编码控制器
- `ControllerCommandLine.pas` - CLI 控制器
- `EncodingConverter_Improved.pas` - 核心转换引擎
- `ChineseEncodingDetector_Improved.pas` / `JapaneseEncodingDetector_Improved.pas` / `KoreanEncodingDetector_Improved.pas` - 语言特定检测器
- `UtilsBOMCleaner.pas` - 统一 BOM 清理
- `UtilsPathSecurity.pas` - 路径安全校验
- `UtilsTempFileSecurity.pas` - 临时文件安全管理
- `ViewMainCode.pas` - 主窗体
- `Tests/` - 测试用例
- `docs/` - 详细技术文档

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -am 'Add your feature'`)
4. 推送到分支 (`git push origin feature/your-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证，详情请参见 [LICENSE](LICENSE)。

## 作者与支持

Author: `ODDFounder / Fuyi / 付乙`

- Website: `www.goodmem.cn`
- Email: `fuyi.it@live.cn`
- WeChat: `17781158558`
- QQ: `624449684`
- GitHub Issues: 仓库公开后启用
