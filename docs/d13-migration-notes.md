# DeepCharset — Delphi 13.1 迁移笔记

> 最后更新：2026-05-09

---

## 组件就绪状态盘点

| 组件 | 13.1 状态 | 备注 |
|---|---|---|
| Delphi 13.1 IDE | ✅ 已安装 | BDS 37.0 |
| Skia4Delphi 7.1.0 | ✅ 已安装 | Skia.Package.*.370.bpl 已注册 |
| VirtualTreeView | ❌ 未安装 | 需手动重编 |
| SynEdit | ❌ 未安装 | 需手动重编 |
| Python4Delphi | ❌ 未安装 | 需手动重编 |
| madCollection | ❌ 未安装 | 需安装 BDS24 版本 |
| DeepBase | ❌ 未迁移 | 人类单独处理 |

## 阻塞项

- [ ] 全项目 Build（等 DeepBase BPL 就绪）
- [ ] VTV 集成（等 VTV 13.1 重编安装）
- [ ] SynEdit 集成（等 SynEdit 13.1 重编安装）
- [ ] P4D 集成（等 P4D 13.1 重编安装）
- [ ] madCollection 迁移（等 madCollection BDS24 安装）
- 阻塞原因：五大组件均未在 BDS 37.0 中注册
- 预计解除：各组件就绪后逐个解除

## 可推进的工作

1. ✅ 阶段 0 准备（tag、备份、分支）
2. ✅ 阶段 1.1 更新编译脚本
3. ✅ 阶段 3 语法现代化

## 更新日志

| 日期 | 变更 |
|---|---|
| 2026-05-09 | 初始化盘点,记录组件就绪状态 |
