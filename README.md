# 小窝 · phone

一个装得下的虚拟手机：桌面 → 点图标 → App 整屏打开 → 返回。

## 目录

```
index.html              入口，只做壳，内容都靠 js 渲染
css/tokens.css          颜色与尺寸变量（唯一色值来源）
css/base.css            重置、屏幕容器、toast
css/desktop.css         桌面：时间、分页、图标格、dock、分页点
css/app-shell.css       App 全屏层：标题栏、返回键、内容区
js/store.js             本地状态（localStorage，前缀 xw_）
js/ui.js                提示、日期、问候、图标小工具
js/apps.js              App 注册表：改名字/加图标只改这里
js/router.js            打开 App / 返回桌面
js/desktop.js           桌面渲染与翻页
js/main.js              启动
manifest.webmanifest    PWA（装到手机桌面）
sw.js                   离线缓存（网络优先）
```

## 现在的结构

- 桌面分页：一页 8 个图标（4 x 2），横向滑翻页
- 第一页顶部是「在一起 N 天」
- 底部 dock：聊天 / 日记 / 相册 / 设置
- 点任意图标 → 那个 App 独占整屏，左上返回

## 哪些 App 真能用

| App | 状态 |
|---|---|
| 日记 | 能写能存（本地） |
| 设置 | 只读展示名字与起算日 |
| 其余 21 个 | 显示「还没开门」 |

## 加一个 App

1. 在 `js/apps.js` 的 `APPS` 里加一行（id / 中文名 / 图标 path）
2. 在 `js/router.js` 的 `render(id)` 里加一个分支，返回这个 App 的 HTML
3. 需要交互就在 `bind(id)` 里绑事件

超过 8 个会自动开新的一页。
