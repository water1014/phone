# 小窝 Flutter App

这是小窝 Android App 的 Flutter UI 迁移工程。旧版 Web/PWA 与 Capacitor 工程保留在仓库根目录，作为功能、数据结构和页面行为的迁移参照，不会被本工程覆盖。

## 本地开发

- 进入 flutter_app 目录
- 执行 flutter pub get
- 执行 flutter analyze
- 执行 flutter test
- 执行 flutter run

## Android APK

执行 flutter build apk --debug。APK 输出在 build/app/outputs/flutter-apk/app-debug.apk。

## 架构约定

- lib/app：应用入口、路由、主题与全局配置。
- lib/core：通用基础设施、数据、安全存储、平台适配。
- lib/features：按业务功能拆分页面、状态和数据访问。
- UI 使用 Flutter Widget 自绘与统一设计令牌，不用 WebView 承载主界面。
- Riverpod 管理状态，GoRouter 管理页面路由；网络与密钥能力集中封装。
- 每个业务页面独立实现，避免一个超长页面和跨页面样式污染。
- 旧数据迁移先备份，再导入和核对；不假定 localStorage / IndexedDB 会自动出现在 Flutter 数据库中。

## 迁移原则

1. phone 旧版是功能来源，Mio 是聊天布局与交互参考。
2. 已确认的首页布局不擅自重设计；当前 HomePage 仅是可运行工程壳，后续需按旧版首页结构还原。
3. 不因 UI 骨架存在就标记业务功能完成。
4. 未在 vivo S19 真机验证的项目标记为「待真机验收」。
