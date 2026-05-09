# DeepCharset — Delphi 13.1 迁移任务包

> 所属分组：Group D（配置/工具/多组件）— 组内优先级 2
> 项目定位：编码工具,56 个 pas,SynEdit + VTV + Skia + P4D + madCollection
> 升级收益：多组件统一升级 + madCollection 新版
> 前置条件：DeepBase 阶段 1 已完成 + SynEdit/VTV/P4D/madCollection 就绪
> 总纲参考：`02Business/docs/delphi-13-migration/README.md`

---

## 阶段 0：准备

- [ ] 0.1 确认 DeepBase 已完成 13.1 迁移
- [ ] 0.2 确认阻塞组件就绪:
  - [ ] 0.2.1 SynEdit 13.1 ✓/✗
  - [ ] 0.2.2 VirtualTreeView 13.1 ✓/✗
  - [ ] 0.2.3 Python4Delphi 13.1 ✓/✗
  - [ ] 0.2.4 madCollection BDS24 ✓/✗
- [ ] 0.3 打 git tag `pre-d13-deepcharset`
- [ ] 0.4 确认 12.3 下可编译,记录 Warning 基线
- [ ] 0.5 创建分支 `upgrade/delphi-13`

## 阶段 1：环境与组件

- [ ] 1.1 更新编译脚本
- [ ] 1.2 用 13.1 IDE 打开,升级 dproj
- [ ] 1.3 确认 SynEdit + VTV + P4D 集成（可复用 DeepConfig 的验证结果）
- [ ] 1.4 确认 madCollection BDS24 版本替换 madExcept
- [ ] 1.5 确认 Skia 7.1.0
- [ ] 1.6 检查 Search Path

## 阶段 2：编译修复

- [ ] 2.1 Clean + Build
- [ ] 2.2 修复 madCollection 迁移（madExcept → madCollection 新 API）
- [ ] 2.3 修复 SynEdit/VTV/P4D API 变化
- [ ] 2.4 修复 Skia 路径变化
- [ ] 2.5 处理 Warning

## 阶段 3：语法现代化

- [ ] 3.1 选 1-2 个核心文件做三元 + inline var 重构
- [ ] 3.2 确认编译通过

## 阶段 4：测试与收尾

- [ ] 4.1 冒烟测试（编码检测 / 转换 / 批量处理）
- [ ] 4.2 Warning ≤ 基线
- [ ] 4.3 更新 CHANGELOG
- [ ] 4.4 合并分支,打 tag `d13-deepcharset-done`

---

## DoD

- [ ] Clean + Build 成功
- [ ] SynEdit + VTV + P4D + Skia + madCollection 五组件正常
- [ ] 冒烟测试通过
- [ ] Warning ≤ 基线
