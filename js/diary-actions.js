/* diary-actions.js · 日记的删除操作，沿用现有卡片样式 */
(function () {
  if (!window.Pages || typeof window.Pages.diary !== 'function') return;

  const renderDiary = window.Pages.diary;
  const bindDiary = window.Pages.diaryBind;

  window.Pages.diary = function () {
    const html = renderDiary();
    const list = Array.isArray(window.XW.S.diary) ? window.XW.S.diary : [];
    const template = document.createElement('template');
    template.innerHTML = html;

    Array.prototype.forEach.call(template.content.querySelectorAll('.dcard'), function (card, displayIndex) {
      const date = card.querySelector('.dcard-date');
      if (!date) return;

      const head = document.createElement('div');
      head.className = 'dcard-head';
      date.parentNode.insertBefore(head, date);
      head.appendChild(date);

      const remove = document.createElement('button');
      remove.type = 'button';
      remove.className = 'dcard-remove';
      remove.dataset.diaryDelete = String(list.length - 1 - displayIndex);
      remove.setAttribute('aria-label', '删除这篇日记');
      remove.textContent = '×';
      head.appendChild(remove);
    });

    return template.innerHTML;
  };

  window.Pages.diaryBind = function (bodyEl) {
    if (typeof bindDiary === 'function') bindDiary(bodyEl);

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-diary-delete]'), function (button) {
      button.addEventListener('click', function () {
        const index = Number(button.dataset.diaryDelete);
        const entries = Array.isArray(window.XW.S.diary) ? window.XW.S.diary : [];
        if (!Number.isInteger(index) || index < 0 || index >= entries.length) return;
        if (!window.confirm('确定删除这篇日记吗？')) return;

        entries.splice(index, 1);
        window.XW.S.diary = entries;
        window.XW.save('diary');
        window.UI.toast('日记已删除');
        window.Router.reopen('diary');
      });
    });
  };
})();
