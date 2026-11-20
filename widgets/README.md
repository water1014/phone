# widgets · 小组件参照库

这里放**参照素材**，不是直接嵌进小窝的代码。

小窝里的组件是我自己写的 HTML + CSS（在 `css/home.css`、`js/widget.js`），
这里的文件只用来**看别人怎么做**，看中的效果我再手写进小窝。

## 目录约定

```
widgets/
├─ README.md              ← 本文件
├─ refs/                  ← 参照素材（原始文件放这里）
│   ├─ canoe-calendar.json
│   ├─ flip-card.docx
│   └─ korean-simple.docx
└─ extracted/             ← 从素材里拆出来的代码（可运行片段）
```

## 三个文件是什么

| 文件 | 来源 | 类型 | 怎么用 |
|---|---|---|---|
| `canoe-calendar.json` | canoe 日历小组件 by 阿懵 | JSON，约 518KB | 里面是 `widgetImg` / `widgetPhotos` 的 base64 图片，代码字段需单独导出 |
| `flip-card.docx` | 病态翻转卡片 by 小玖 | Word 文档 | 里面是提示词 / 说明，代码贴在正文里 |
| `korean-simple.docx` | 韩系简约组合 by 小玖 | Word 文档 | 同上 |

## 为什么 docx 读不了

`.docx` 本质是一个 zip 压缩包（里面是一堆 XML）。
我这边只能按文本读文件，读出来是乱码，提不出里面的文字。

## 真要接进小窝的两条路

**路一：你贴代码**
把 docx 里的 HTML / CSS 复制成文本粘到聊天里，我直接写成 `extracted/xxx.html`，
然后再拆成小窝用的组件（改尺寸、改配色、接真数据）。

**路二：你上传文件**
在 GitHub 网页版里点 `widgets/refs/` → `Add file` → `Upload files`，
把那三个文件拖进去提交。这样它们会存在仓库里，不占聊天。

## 小窝现有组件清单

| 组件 | 文件 | 数据来源 |
|---|---|---|
| 时钟 | `js/widget.js` → `clock()` | 系统时间 |
| 天数 | `days()` | `XW.S.loveDate` |
| 天气 | `weatherCard()` | open-meteo，不要 key |
| 额度 | `quota()` | `XW.S.usage` / `ctxLimit` |
| 在听 | `nowPlaying()` | `XW.S.songs` / `nowSong` |
| 月历 | `calendar()` | `XW.S.diary` 的日期 |
| 摘句 | `quote()` | `XW.S.diary` 最后一条 |
| 2×2 方块 | `appGrid()` | `Apps.ALL` |
| 列表 | `rows()` | 日记 / 聊天条数 |

## 后续想加的新组件（待做）

- 潮汐（需先填基线：起始日、周期、每次天数）
- 游客留言（需一个留言板，现在没后端）
- 记账（`XW.S.ledger`，每日一笔）
- 语录（从日记里挑句子收藏）
- 倒计时（生日 / 见面日）

> 上面这几项**都不靠编**：有真数据才做，没数据就写「还没接」。
