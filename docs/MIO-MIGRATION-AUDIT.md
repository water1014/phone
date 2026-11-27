# Mio 原版移植审计（2026-11-27）

## 当前基线

- 仓库：`water1014/phone`
- 工作分支：`feature/complete-frontend`
- 审计时 HEAD：`6238389cc3e6f1ff1bd279b6246ca7e47579af67`
- 最新 Actions：run `45923505994`，结果 success。这里只代表 workflow 成功，不代表页面交互验收通过。
- `mio/index.html` 在 Git tree 中大小为 **1,715,433 bytes**，Blob 可读取约 1,587,278 个字符。Contents 接口对该大文件返回空正文，不能据此判定文件为空。
- Mio 原版入口仍以独立 HTML 文档运行，phone 通过 iframe 承载，并以 hash 请求原版视图。当前属于“原版整页嵌入”，不是已经拆成 phone 原生组件的模块化移植。

## 当前已核实的集成内容

- `js/router.js` 有 27 个 `MIO_VIEWS` 映射。
- 映射目标包括：chat、personas、worlds、diary、music、mcp、settings、wallet、life、coread、offline、preset、repo、youtube、crread、couple、msgs、iff、xinji、app、cset、deco、css、prof、rolephones、stickers、desktopcustom。
- `mio/index.html` 尾部存在 Phone adapter：从 URL hash 读取请求视图，检查原版 `R[view]` 是否存在，再调用原版 `go()`；chat 无已选角色时回退到 personas。
- phone 的桌面和左侧栏仍由 phone 自己管理；被映射的模块在 iframe 内使用 Mio 原版页面。
- 目前尚无真实浏览器/手机端验收记录，不能把入口存在或 Actions success 当作功能通过。

## 必须保留的边界

phone 当前本地状态在 `js/store.js` 中以 `localStorage` 的 `xw_` 前缀保存。

Mio 原版页面使用独立存储：
- IndexedDB：`xiaoshouji-v62-store`，object store `state`，主状态 key `xsj`
- 兼容 localStorage key：`xsj`
- 音乐 IndexedDB：`xsj-music`
- 字体 IndexedDB：`xsj-fonts`

这意味着两个应用在同源页面下可以访问各自的存储，但数据结构和主键并不相同。**不能直接把 phone 的 xw_ 数据覆盖到 Mio 的 xsj 状态，也不能在没有备份和字段映射的情况下做双向合并。**

## 原版服务端依赖

Mio 上游仓库包含：
- `server/music/main.py`：QQ 音乐 FastAPI 服务，需要 ACCESS_KEY、持久化登录凭证目录及 Python 依赖。
- `server/repo/server.py`：资源仓库 HTTP 服务，需要持久化数据目录，可配置管理员密钥等。

这两个服务源码存在于 Mio 上游仓库；本次审计未在 phone 当前分支找到对应的 `server/` 文件，因此不能宣称这些服务已随 phone 部署。音乐、资源仓库的在线功能需要继续核对前端 API 地址和部署配置。

## phone 自有入口与 Mio 映射的区别

phone 的 app registry 还包含 memory、album、letter、calendar、plans、accounting、weather、mood、health、cycle、study、quotes、moments、favorites、games、studio、windows、beautify 等 phone 自有入口。它们没有被当前 27 项 Mio 映射覆盖。

这些入口不能仅因名字相似就伪装成 Mio 原版功能。后续需要按上游实际存在的页面/功能逐项归类：
1. Mio 原版确实有对应模块：复用原版，不重写。
2. 属于 phone 自有功能：保留 phone 实现，不标成 Mio 已移植。
3. 原版有功能但 phone 无入口：补齐入口和路由。
4. 依赖服务端/API：先确认部署和配置，再验收。

## 下一阶段验收清单

- [ ] 浏览器中确认 iframe 加载的是完整 Mio 原版，而不是空白页或首页回退。
- [ ] 逐个点击 27 个映射入口，确认 hash 进入目标原版视图。
- [ ] 检查原版返回/前进、弹窗、文件选择、图片预览、下载、通知和 PWA 行为。
- [ ] 检查 Mio IndexedDB 是否能在刷新后保留数据；不得覆盖现有数据。
- [ ] 逐项核对音乐、资源仓库的 API 地址、CORS、鉴权和服务部署。
- [ ] 制定 phone xw_ 与 Mio xsj 的只读盘点及备份方案，再设计可回滚的数据迁移。
- [ ] 真机检查 phone 外层导航、iframe 高度/滚动、键盘、状态栏和刘海屏适配。

## 当前结论

目前完成的是：原版页面文件恢复、phone 外层承载、部分原版视图入口映射。

目前未完成的是：原版每个功能的实际运行验收、服务端部署、phone 与 Mio 数据迁移/互通，以及把 Mio 模块拆成 phone 原生页面组件。

不得将当前状态描述为“完整移植完成”。
