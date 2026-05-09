---
inclusion: always
---

# Delphi 13.1 语法规范 — DeepCharset

## 推荐模式

### 1. 三元表达式 + inline var

```pascal
// ✅
var TargetEnc := if AddBOM then ENCODING_UTF8_BOM else ENCODING_UTF8;
```

### 2. 字符串处理

本项目核心是编码检测/转换，`TEncoding` 使用必须显式：

```pascal
// ❌
S := TEncoding.ANSI.GetString(Buffer);

// ✅ 显式指定目标编码
S := TEncoding.UTF8.GetString(Buffer);
```

### 3. `PAnsiChar` / `AnsiString`

作为**编码工具**，本项目需要 `AnsiString` 做字节级处理，这是合理的。但新写代码：

- 只在确实需要 code page 转换时使用 `AnsiString`
- 不要在普通字符串拼接里混用 `AnsiString` 和 `string`
- 显式转换：`string(AnsiStr)` / `AnsiString(Str)`，避免隐式警告

## 禁用模式

- ❌ `with X do ...`
- ❌ 手写 BOM 解析（用 `UtilsEncodingBOM_Improved` 里现成的 `TEncodingBOMDetector_Improved`）
- ❌ 再引入新的 JCL/madCollection 依赖

## Warning 策略

- 13.1 对 `IMPLICIT_STRING_CAST` 告警更严
- 本项目已有多处 `{$WARN IMPLICIT_STRING_CAST OFF}`，迁移后复核是否仍需要
- 新代码用 `string(X)` / `AnsiString(X)` 显式转换，不要依赖 `{$WARN ... OFF}`

## 已采用样板

- `ModelConfig.pas` — inline var（`SaveConfig`、`Create`）
