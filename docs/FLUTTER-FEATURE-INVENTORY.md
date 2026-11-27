# Flutter 功能迁移盘点

来源：旧版 `js/apps.js` 的真实应用注册表与 `js/desktop.js` 的侧栏分组。此表是迁移追踪，不代表功能已经完成。所有项目初始均为待迁移。

## 聊天与关系

- [ ] 聊天（chat）：消息、流式输出、思考/工具记录、附件、会话管理、独立聊天设置
- [ ] 联系人（personas）
- [ ] 记忆（memory）
- [ ] 世界书（worldbook）
- [ ] 情书（letter）
- [ ] 动态（moments）
- [ ] 消息（msgs）
- [ ] 情侣空间（couple）
- [ ] 互动（iff）
- [ ] 心迹（xinji）

## 生活与记录

- [ ] 日记（diary）
- [ ] 日历（calendar）
- [ ] 安排（plans）
- [ ] 记账（accounting）
- [ ] 钱包（wallet，侧栏入口）
- [ ] 生活（life，侧栏入口）
- [ ] 心情（mood）
- [ ] 健康（health）
- [ ] 经期（cycle）
- [ ] 学习（study）
- [ ] 天气（weather）

## 内容与收藏

- [ ] 相册（album）
- [ ] 一起听（music）
- [ ] 语录（quotes）
- [ ] 收藏（favorites）
- [ ] 游戏（games）
- [ ] 生图室（studio）
- [ ] 窗廊（windows）
- [ ] 一起读（coread，侧栏入口）
- [ ] 共读书架（crread，侧栏入口）
- [ ] 离线内容（offline，侧栏入口）
- [ ] 视频（youtube，侧栏入口）
- [ ] 资源仓库（repo，侧栏入口）
- [ ] 预设（preset，侧栏入口）
- [ ] 表情包（stickers，侧栏入口）

## 系统与扩展

- [ ] MCP（mcp）
- [ ] 美化（beautify）
- [ ] 设置（settings）
- [ ] 角色手机（rolephones，侧栏入口）
- [ ] 桌面自定义（desktopcustom，侧栏入口）
- [ ] 样式设置（css，侧栏入口）
- [ ] 个人资料（profile，侧栏入口）
- [ ] 应用中心（app，侧栏入口）
- [ ] 聊天设置（cset，侧栏入口）
- [ ] 主页装饰（deco，侧栏入口）

## 迁移规则

- [ ] 每个功能先检查旧版真实实现、数据结构、事件入口和依赖，再设计 Flutter 页面。
- [ ] 同一类数据只保留一个权威数据源，避免记账/钱包等功能重复造数据。
- [ ] 旧版 localStorage 与 IndexedDB 需要单独导出、映射、备份和导入。
- [ ] 业务页面完成后补充空状态、错误状态、长内容、键盘、滚动与深色模式测试。
- [ ] Android 系统能力单独验收：边缘返回、安全区、状态栏、媒体选择、通知和后台任务。
