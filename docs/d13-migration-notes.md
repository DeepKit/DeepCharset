# DeepCharset — Delphi 13.1 迁移笔记

> 最后更新：2026-05-09

---

## 组件就绪状态盘点

| 组件 | 13.1 状态 | 备注 |
|---|---|---|
| Delphi 13.1 IDE | ✅ 已安装 | BDS 37.0 |
| Skia4Delphi 7.1.0 | ✅ 已安装 | Skia.Package.*.370.bpl 已注册,unit 名（System.Skia/Vcl.Skia/FMX.Skia）未变 |
| VirtualTreeView | ⏳ 安装中 | |
| SynEdit | ⏳ 安装中 | |
| Python4Delphi | ⏳ 安装中 | |
| madCollection | ⛔ 不需要 | 源码不实际使用 madExcept，madExcept.pas 是空桩，`{$DEFINE USE_MADEXCEPT}` 被注释禁用 |
| DeepBase | ❌ 未迁移 | 人类单独处理 |

## 阻塞项

- [ ] 全项目 Build（等 DeepBase BPL 就绪）
- [ ] VTV 集成（等 VTV 13.1 安装完成）
- [ ] SynEdit 集成（等 SynEdit 13.1 安装完成）
- [ ] P4D 集成（等 P4D 13.1 安装完成）
- 阻塞原因：DeepBase + 三大组件未就绪
- 预计解除：各组件就绪后逐个解除

## madCollection 决策记录

**决定不使用 madCollection**。理由：
1. 全代码库无 `madExcept/madBasic/madDisAsm` 引用（`grep` 零命中）
2. `DeepCharset.dpr` 中 `{.$DEFINE USE_MADEXCEPT}` 前导点注释，条件编译块从未启用
3. 本地 `madExcept.pas` 只有 `unit madExcept; interface implementation end.`，是占位空桩
4. 源码注释写明："madExcept 暂时禁用 - 版本不兼容问题"

`build.bat` 的 `MADPATHS` 已清除。如未来要启用异常追踪，推荐 EurekaLog（`EUREKALOG_SETUP.md` 已有配置指引）或直接用 13.1 自带的 `JclDebug`。

## 可推进的工作

1. ✅ 阶段 0 准备（tag、备份、分支）
2. ✅ 阶段 1.1 更新编译脚本
3. ✅ 阶段 3 语法现代化

## 更新日志

| 日期 | 变更 |
|---|---|
| 2026-05-09 | 初始化盘点,记录组件就绪状态 |
