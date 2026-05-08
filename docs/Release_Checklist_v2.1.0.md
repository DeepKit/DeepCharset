# DeepCharset v2.1.0 发布�?Checklist

> 目标：在不引入新大功能的前提下，最大限度降低检�?转码错误风险，发布一个“质量修复版”�?

---

## 一、代码与构建

- [ ] 使用 Delphi 打开主工程，**全量重新编译**（Release 配置）�?
- [ ] 确认以下单元成功编译且无警告级别的致命信息：
  - `EncodingConverter_Improved.pas`
  - `UtilsEncodingUTF8Detector_Improved.pas`
  - `ChineseEncodingDetector_Improved.pas`
  - `JapaneseEncodingDetector_Improved.pas`
  - `KoreanEncodingDetector_Improved.pas`
  - `UtilsEncodingConfig.pas`
  - `UtilsPathSecurity.pas` / `UtilsTempFileSecurity.pas`
  - `EncodingExceptions.pas`
- [ ] 编译测试工程 `Tests/SelfTest_Encoding.dpr`，生成最新的 `SelfTest_Encoding.exe`�?

---

## 二、自动化自测（SelfTest_Encoding�?

### 2.1 快速冒�?

- [ ] 在命令行执行：`SelfTest_Encoding.exe /quick`
- [ ] 确认�?
  - 进程正常退出（退出码 0）�?
  - 日志中无明显 `[FAIL]` / `Exception`�?

### 2.2 完整自测

- [ ] 执行：`SelfTest_Encoding.exe`
- [ ] 检查日�?控制台输出：
  - [ ] P2�? 相关用例（ConversionIntegrity）全�?**PASS**�?
  - [ ] P2�? 相关用例（BoundaryCases：空文件/单字�?�?BOM/损坏 UTF�?/混合编码/置信度边�?多编码低置信度）全部 **PASS**�?
  - [ ] 不存在访问冲突、内存错误或未捕获异常�?

> 如有失败用例，记录：用例名称 + 日志片段，先不要发布�?

---

## 三、GUI 手工验证（主窗体�?

### 3.1 基础功能

针对每个场景，选用 1�? 个真实文件进行确认：

- [ ] **GBK -> UTF�?**�?
  - 转换后中文不乱码�?
  - 文件大小/行数大致合理（无明显截断）�?
- [ ] **GB18030 -> UTF�?**�?
- [ ] **Big5 -> UTF�?**�?
- [ ] **UTF�? �?BOM -> UTF�? �?BOM**�?
- [ ] **UTF�? �?BOM -> UTF�? �?BOM**�?

### 3.2 非文�?/ 路径安全

- [ ] �?`.exe` / `.dll` / `.png` 等文件：
  - 被正确识别为非文�?/ 被跳过，不进行转换；
  - 不产生异常弹窗或崩溃�?
- [ ] 尝试选择 `C:\Windows` / `C:\Windows\System32` 等目录进行转换：
  - 程序给出合理提示（路径不安全或不支持）；
  - 不会静默覆盖系统文件�?

### 3.3 大文件（100MB 级）

- [ ] 准备至少 1 �?100MB 以上的文本文件：
  - �?GUI 中执行一次编码转换（�?GBK -> UTF�?）；
  - 确认�?
    - 程序可以完成，不崩溃�?
    - 内存占用在可接受范围�?
    - 转换结果文件可以正常打开、内容完整�?

---

## 四、命令行工具验证（ControllerCommandLine�?

假设主程序名�?`DeepCharset.exe`，在命令行中进行以下测试�?

### 4.1 单文件场�?

- [ ] `DeepCharset.exe -s GBK -t UTF-8 input_gbk.txt`
  - 输出文件编码�?UTF�?�?
  - 终端输出“成功”信息�?
- [ ] `DeepCharset.exe -s auto -t UTF-8 input_auto.txt -o output.txt`
  - `output.txt` 正常生成�?
  - 原文件不被破坏�?
- [ ] `DeepCharset.exe -s Big5 -t UTF-8 --add-bom input_big5.txt`
  - 输出�?UTF�? with BOM�?

### 4.2 目录 & 备份

- [ ] `DeepCharset.exe -s GBK -t UTF-8 -r -b C:\MyFiles\`
  - 转换�?*.bak 备份文件正确生成�?
  - 失败时不会删除原文件�?

### 4.3 异常与错误信�?

- [ ] 对不存在文件执行：`DeepCharset.exe -s GBK -t UTF-8 not_exists.txt`
  - 输出�?`[错误]` �?`✗` 的清晰错误消息；
  - 程序正常退出，无堆栈信息泄漏�?
- [ ] 制造一个损�?UTF�? 文件�?
  - 确认 CLI 输出“编码异常”或“检测失败”的合理提示，而不是崩溃�?

---

## 五、边界与异常场景回归

- [ ] 空文件（0 字节）转换：
  - 输入/输出均为空文件；
  - 无多�?BOM、无异常�?
- [ ] �?BOM 文件（UTF�?、UTF�?6LE）：
  - 转换成功，不报错�?
  - 输出编码正确，内容只包含合法 BOM 或空�?
- [ ] 损坏 UTF�? / 混合编码文件�?
  - GUI �?CLI 均不会崩溃；
  - 日志或错误信息中能看出是“编码问题”，而不�?IO 问题�?

---

## 六、配置与默认值检查（UtilsEncodingConfig + ui.ini�?

- [ ] 打开 `ini/ui.ini`（如存在），确认�?
  - `MinUTF8Confidence` = 0.80（或你认可的默认值）�?
  - `MinChineseConfidence` / `MinJapaneseConfidence` / `MinKoreanConfidence` = 0.75（或你配置的值）�?
- [ ] 确认程序�?**没有 ui.ini** 的情况下也能正常启动，并使用合理默认值�?
- [ ] 如有必要，在 README 或内部文档中简要说明这些配置项的含义和推荐值�?

---

## 七、日志与异常处理（基础验证�?

- [ ] 故意触发一个编码错误（例如用错误编码打开文件）：
  - 日志中出现清晰的错误描述�?
  - 如走�?CLI �?GUI，对用户显示的信息简短清晰（中文或英文统一）�?
- [ ] 故意触发一�?IO 问题（访问只读文�?/ 无权限目录）�?
  - 错误信息能区分“文件访问问题”和“编码问题”（至少文案不同）；
  - 不出现访问冲突或未捕获异常框�?

---

## 八、文档与版本标记

- [ ] 更新 `tasks.md`�?
  - 确认 P0 / P1 / P2�? / P2�? / P2�? 状态为已完成；
  - P2�? 标注为“部分完成”，说明已做的范围（异常层次结构 + 核心路径）�?
- [ ] 更新 `hiDeepDeepDeepDeepDeepStory.md`�?
  - 增加一�?“v2.1.0 发布�?或等价条目，简单说明本版本重点（检�?转码质量修复）�?
- [ ] 确认主程序关于框（或 CLI `--version`）中的版本号、版权信息是最新的�?
