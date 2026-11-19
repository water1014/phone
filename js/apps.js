/* apps.js · App 注册表
   桌面图标从这张表生成，每页 8 个，4 列 x 2 行。
   想加/改/删 App、改名字，只改这里。 */
(function () {
  const APPS = [
    { id: 'chat', name: '聊天', icon: ['M4 5h16v11H9l-5 4z'] },
    { id: 'memory', name: '记忆', icon: ['M12 21s-7.5-4.9-9.5-9C1 8.5 3 4.5 7 4.5c2.2 0 3.7 1.2 5 3 1.3-1.8 2.8-3 5-3 4 0 6 4 4.5 7.5-2 4.1-9.5 9-9.5 9z'] },
    { id: 'diary', name: '日记', icon: ['M6 3h12v18H6z', 'M9 8h6', 'M9 12h6', 'M9 16h4'] },
    { id: 'album', name: '相册', icon: ['M4 4h16v16H4z', 'M9.4 10a1.6 1.6 0 1 0 0-3.2 1.6 1.6 0 0 0 0 3.2z', 'M20 16l-4-4-9 8'] },
    { id: 'letter', name: '情书', icon: ['M3 6h18v12H3z', 'M3.5 7l8.5 6 8.5-6'] },
    { id: 'music', name: '一起听', icon: ['M9 18V5l12-2v13', 'M6 21a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 'M18 19a3 3 0 1 0 0-6 3 3 0 0 0 0 6z'] },
    { id: 'calendar', name: '日历', icon: ['M4 6h16v15H4z', 'M8 3v4M16 3v4M4 11h16'] },
    { id: 'plans', name: '安排', icon: ['M5 4h14v17H5z', 'M9 9h6M9 13h6M9 17h3'] },

    { id: 'accounting', name: '记账', icon: ['M4 6h16v13H4z', 'M8 11h8', 'M8 15h5'] },
    { id: 'weather', name: '天气', icon: ['M7.5 18.2h9.2a4.3 4.3 0 0 0 .3-8.6 5.7 5.7 0 0 0-10.9 1.6 3.6 3.6 0 0 0 1.4 7z'] },
    { id: 'mood', name: '心情', icon: ['M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z', 'M8.5 14s1.4 2 3.5 2 3.5-2 3.5-2', 'M9.5 9.5h.01M14.5 9.5h.01'] },
    { id: 'health', name: '健康', icon: ['M3 12h4l2-6 3 12 2.5-6H21'] },
    { id: 'cycle', name: '经期', icon: ['M12 3c3 4 6 6.6 6 10a6 6 0 0 1-12 0c0-3.4 3-6 6-10z'] },
    { id: 'study', name: '学习', icon: ['M4 5h7v15H4z', 'M13 5h7v15h-7z'] },
    { id: 'quotes', name: '语录', icon: ['M7 7h6v6H7z', 'M7 17h10'] },
    { id: 'moments', name: '动态', icon: ['M12 3v18', 'M3 12h18', 'M6 6l12 12', 'M18 6L6 18'] },

    { id: 'favorites', name: '收藏', icon: ['M12 4l2.5 5 5.5.8-4 3.9 1 5.5-5-2.7-5 2.7 1-5.5-4-3.9 5.5-.8z'] },
    { id: 'games', name: '游戏', icon: ['M7 8h10a4 4 0 0 1 4 4v1a3 3 0 0 1-5.4 1.8L14.5 14h-5l-1.1.8A3 3 0 0 1 3 13v-1a4 4 0 0 1 4-4z', 'M8 11v2M7 12h2'] },
    { id: 'studio', name: '生图室', icon: ['M4 5h16v14H4z', 'M8 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', 'M20 15l-5-5-9 9'] },
    { id: 'worldbook', name: '世界书', icon: ['M4 5h7v15H4z', 'M13 5h7v15h-7z', 'M6.5 9h2M6.5 13h2'] },
    { id: 'windows', name: '窗廊', icon: ['M3 5h18v14H3z', 'M9 5v14'] },
    { id: 'mcp', name: 'MCP', icon: ['M9 7V5a3 3 0 0 1 6 0v2', 'M7 7h10v6a5 5 0 0 1-10 0z', 'M12 18v3'] },
    { id: 'beautify', name: '美化', icon: ['M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z'] },
    { id: 'settings', name: '设置', icon: ['M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 'M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.6 5.6l1.7 1.7M16.7 16.7l1.7 1.7M18.4 5.6l-1.7 1.7M7.3 16.7l-1.7 1.7'] }
  ];

  /* dock 和每页图标都从这里引，不另存一份 */
  const DOCK_IDS = ['chat', 'diary', 'album', 'settings'];

  const PER_PAGE = 8;

  function pages() {
    const out = [];
    for (let i = 0; i < APPS.length; i += PER_PAGE) out.push(APPS.slice(i, i + PER_PAGE));
    return out.length ? out : [[]];
  }

  function find(id) {
    return APPS.find(function (app) { return app.id === id; }) || null;
  }

  window.Apps = {
    ALL: APPS,
    DOCK: DOCK_IDS,
    PER_PAGE: PER_PAGE,
    pages: pages,
    find: find
  };
})();
