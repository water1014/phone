# 小窝 · 小组件格式说明

> 这份文档是给**写代码的 AI** 看的。请严格按它输出，不要问问题，不要解释。

---

## 你要交什么

**一段代码**，用户会整段粘贴进小窝的「美化 → 小组件 → 写代码」，点预览、点加到桌面。

这个小组件会被放进**一张固定尺寸的卡片**里，当作一个独立网页运行。

---

## 硬规格

| 项 | 值 |
|---|---|
| 对话宽度 | 手机 375px 竖屏（`device-width`） |
| 卡片宽度 | 1 格 ≈ **78px** / 2 格 ≈ **166px** / 4 格 ≈ **343px** |
| 卡片高度 | **90 / 140 / 200 / 280 px**，四选一，超出的部分直接裁掉 |
| 背景 | 默认透明，会透出卡片的白色。要底色就自己写 `body{background:...}` |
| 运行环境 | Android WebView，等价现代手机浏览器 |
| 滚动 | **没有**。内容必须刚好塞进固定高度 |

---

## 输出格式

只要**一个代码块**，里面是完整的 HTML 片段，`<style>` 和 `<script>` 可以放在同一个块里：

```html
<div class="wrap">内容</div>
<style>
  body{ background:#fff }
  .wrap{ }
</style>
<script>
  // 可选
</script>
```

**不要**：分段输出、写「以下是代码」、写解释、写 `<!DOCTYPE>`（除非用户明确要完整网页）。

---

## 系统会自动补上的基础样式

```css
*{ box-sizing:border-box }
html, body{
  margin:0; height:100%;
  background:transparent;
  font-family:-apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif;
  color:#3a3733;
  -webkit-tap-highlight-color:transparent;
}
img{ max-width:100% }
```

你可以直接覆盖它。

---

## 可用的占位符（渲染前会替换成真值）

| 占位符 | 换成 |
|---|---|
| `{{HIS}}` | 他的名字（如「宋祁」） |
| `{{HER}}` | 她的名字（如「淼淼」） |
| `{{DAYS}}` | 在一起第几天（纯数字） |
| `{{SINCE}}` | 纪念日，`2025-01-01` 格式 |
| `{{TODAY}}` | 今天，`2026-11-21` 格式 |

写在 HTML、CSS、JS 里都行，会被当普通文本替换。

---

## 禁用的东西

| 不能用 | 原因 |
|---|---|
| `localStorage` / `sessionStorage` | 沙箱无同源，一碰就抛错，整个脚本停 |
| `alert` / `confirm` / `prompt` | 会被拦 |
| `location.href = ...` | 会跳走，卡片变空白 |
| 外链 `<link rel="stylesheet">` / `<script src>` | 可以写，但不保证加载成功，要稳就全部内联 |
| `window.parent` 访问外层 | 跨域，报错 |
| 大型图片 | 卡片只有 78~343px 宽，用 CSS 渐变 / 内联 SVG 更好 |

---

## 设计约束

1. **一屏只放一件事**。一个时钟就只放时钟，不要塞标题 + 时钟 + 天气 + 按钮。
2. **字号不要小于 10px**，手机上会糊。
3. **高度写死，内容要刚好填满**。居中就用 `body{display:flex;align-items:center;justify-content:center}`。
4. **字偶平行**：想跟小窝风格贴近——中文用衬线（`Georgia, "Songti SC", serif`），数字用衬线正体，字母间距稍微拉开（`letter-spacing:1px`）。
5. **颜色**：小窝是米白底（`#fff` / `#fbfaf8`）+ 墨色字（`#2a2723`）+ 灰注脚（`#a8a196`）。别用高饱和度色。
6. **不要 emoji 当图标**，渲染不一致；要图标就用内联 SVG，`stroke-width:1.25`、`fill:none`、`stroke-linecap:round`。

---

## 示例一：时钟（建议 2 格 × 140）

```html
<div class="t" id="t">--:--</div>
<style>
  body{ background:#fff; display:flex; align-items:center; justify-content:center }
  .t{ font-family:Georgia,serif; font-size:34px; letter-spacing:2px; color:#2a2723 }
</style>
<script>
  var el = document.getElementById('t');
  function tick(){
    var d = new Date();
    el.textContent = ('0'+d.getHours()).slice(-2) + ':' + ('0'+d.getMinutes()).slice(-2);
  }
  tick();
  setInterval(tick, 10000);
</script>
```

---

## 示例二：在一起天数（建议 4 格 × 140）

```html
<div class="w">
  <div class="k">TOGETHER</div>
  <div class="n">{{DAYS}}<span>days</span></div>
  <div class="s">{{HIS}} &amp; {{HER}}</div>
</div>
<style>
  body{ background:#fff; display:flex; align-items:center; justify-content:center }
  .w{ text-align:center; font-family:Georgia,"Songti SC",serif; color:#2a2723 }
  .k{ font-size:10px; letter-spacing:2.4px; color:#a8a196 }
  .n{ margin-top:9px; font-size:42px; line-height:1 }
  .n span{ margin-left:7px; font-size:12px; font-style:italic; letter-spacing:1px; color:#a8a196 }
  .s{ margin-top:9px; font-size:12px; letter-spacing:1.2px; color:#7d786f }
</style>
```

---

## 示例三：进度条（建议 2 格 × 90）

```html
<div class="p"><i style="width:62%"></i></div>
<style>
  body{ background:#fff; display:flex; align-items:center; justify-content:center; padding:14px }
  .p{ width:100%; height:8px; border-radius:4px; background:#f1eee8; overflow:hidden }
  .p i{ display:block; height:100%; border-radius:4px;
        background:linear-gradient(90deg,#d8cbb4,#8e9c83) }
</style>
```

---

## 常见错误清单

1. 用了 `height:100vh` —— 卡片高度是**外部给的**，`100vh` 会溢出被裁；用 `100%`。
2. 定时器写在 `<head>` 里 —— 元素还没解析到，`getElementById` 拿到 null。把 `<script>` 放最后。
3. 用了 `body{overflow:auto}` 想滚动 —— 没用的，外层会裁。
4. 用 `position:fixed` 做布局 —— 可以，但别依赖它撑高。
5. 忘写背景 —— 卡片可能变成透明，叠在深色桌面上就看不清了。
6. 用 `fetch` 拉接口 —— 可能被封（CORS / 无网），用手写数据更稳。

---

## 最后一句

只输出代码块。不解释。不多版本。不要问用户尺寸选哪个——**默认给 2 格 × 140**，并在代码第一行用注释写一句宽度建议。
