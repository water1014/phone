/* music.js · 网易云官方网页播放入口，不依赖自建音乐后端 */
(function () {
  const D = document;

  function music() {
    return Pages.hero('MUSIC', '一起听', '网易云音乐 · 官方网页') +
      '<section class="sheet music-official-intro">' +
        '<div class="sheet-head"><span class="sheet-title">网易云音乐</span><span class="kicker">OFFICIAL</span></div>' +
        '<p class="sheet-note">直接使用网易云官方网页登录与播放，不需要配置自己的音乐服务器。</p>' +
        '<a class="btn-solid" href="https://music.163.com/" target="_blank" rel="noopener noreferrer" style="display:flex;align-items:center;justify-content:center;text-decoration:none">在新页面打开网易云</a>' +
        '<p class="sheet-note" style="margin-top:.65rem">如果下方页面无法登录或播放，请使用上方官方入口。部分浏览器会限制第三方网页内的登录 Cookie 或音频播放。</p>' +
      '</section>' +
      '<section class="music-official-frame" style="height:calc(100dvh - 245px);min-height:420px;overflow:hidden;border:1px solid var(--line,rgba(0,0,0,.08));border-radius:18px;background:var(--card,#fff)">' +
        '<iframe title="网易云音乐官方网页" src="https://music.163.com/" allow="autoplay; encrypted-media; fullscreen; picture-in-picture" referrerpolicy="strict-origin-when-cross-origin" style="display:block;width:100%;height:100%;border:0;background:#fff"></iframe>' +
      '</section>';
  }

  function musicBind(bodyEl) {
    const frame = bodyEl.querySelector('.music-official-frame iframe');
    if (!frame) return;
    frame.addEventListener('error', function () {
      UI.toast('官方网页暂时无法嵌入，请使用上方入口打开');
    });
  }

  window.Pages = window.Pages || {};
  window.Pages.music = music;
  window.Pages.musicBind = musicBind;
})();
