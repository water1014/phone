/* apps.js · App 注册表
   图标统一：24 画布，内容收在 4–20 的方框里，只留必要笔画 */
(function () {
  const APPS = [
    /* 聊天：圆角对话框，尾巴留直角 */
    { id: 'chat', name: '聊天', icon: ['M4 6.5A2 2 0 0 1 6 4.5h12a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-7.5L7 19v-3.5H6a2 2 0 0 1-2-2z'] },

    { id: 'personas', name: '联系人', icon: ['M16 20v-1.5a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4V20', 'M10 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z', 'M16 4.5a3.5 3.5 0 0 1 0 6.8', 'M17 14.5a4 4 0 0 1 3 4V20'] },

    /* 记忆：书签，下部一个缺口 */
    { id: 'memory', name: '记忆', icon: ['M7 4h10v16l-5-3.5-5 3.5z'] },

    /* 日记：左边书脊，右边两行字 */
    { id: 'diary', name: '日记', icon: ['M6.5 4h11v16h-11z', 'M9.6 4v16', 'M12.2 8.6h3.6', 'M12.2 12h3.6'] },

    /* 相册：相框里一道山和一个太阳 */
    { id: 'album', name: '相册', icon: ['M4.5 5.5h15v13h-15z', 'M15 15l-3.5-3.5L6.5 16.5', 'M6.8 9.5a1.2 1.2 0 1 0 2.4 0 1.2 1.2 0 1 0-2.4 0'] },

    /* 情书：信封 */
    { id: 'letter', name: '情书', icon: ['M4 7h16v10H4z', 'M4 7l8 5.5L20 7'] },

    /* 一起听：双音符 */
    { id: 'music', name: '一起听', icon: ['M11 16v-9.5l7-1.5v9', 'M8.8 18a2.1 2.1 0 1 0 0-4.2 2.1 2.1 0 0 0 0 4.2z', 'M15.8 16.5a2.1 2.1 0 1 0 0-4.2 2.1 2.1 0 0 0 0 4.2z'] },

    /* 日历：挂历，两个挂环 */
    { id: 'calendar', name: '日历', icon: ['M4.5 6.5h15v13h-15z', 'M8.5 4v4', 'M15.5 4v4', 'M4.5 10.6h15'] },

    /* 安排：方格里两件事 */
    { id: 'plans', name: '安排', icon: ['M4.5 5.8h3.4v3.4h-3.4z', 'M11 7.5h8.5', 'M4.5 14.8h3.4v3.4h-3.4z', 'M11 16.5h6'] },

    /* 记账：硬币上的 ¥，三道就够了 */
    { id: 'accounting', name: '记账', icon: ['M12 20a8 8 0 1 0 0-16 8 8 0 0 0 0 16z', 'M9 9l3 3.5 3-3.5', 'M12 12.5v4.2', 'M9.9 13.9h4.2'] },

    /* 天气：一朵云 */
    { id: 'weather', name: '天气', icon: ['M7.5 17.5h9a3.7 3.7 0 0 0 .3-7.4 5.3 5.3 0 0 0-10.1 1.4 3.2 3.2 0 0 0 .8 6z'] },

    /* 心情：笑脸 */
    { id: 'mood', name: '心情', icon: ['M12 20a8 8 0 1 0 0-16 8 8 0 0 0 0 16z', 'M8.7 13.6s1.3 2.1 3.3 2.1 3.3-2.1 3.3-2.1', 'M9.3 9.9h.7', 'M14 9.9h.7'] },

    /* 健康：一道心跳 */
    { id: 'health', name: '健康', icon: ['M3.5 12.5h3.4l2-5.4 3 10.8 2-5.4h6.6'] },

    /* 经期：一滴 */
    { id: 'cycle', name: '经期', icon: ['M12 4c3 4 5.5 6.5 5.5 9.6a5.5 5.5 0 0 1-11 0C6.5 10.5 9 8 12 4z'] },

    /* 学习：打开的书 */
    { id: 'study', name: '学习', icon: ['M4 5.8c3-1 5.5-1 8 .7 2.5-1.7 5-1.7 8-.7v11.8c-3-1-5.5-1-8 .7-2.5-1.7-5-1.7-8-.7z', 'M12 6.5v11.8'] },

    /* 语录：一对引号 */
    { id: 'quotes', name: '语录', icon: ['M8.4 8.4h3v3.2c0 2.2-1.3 3.6-3.4 4.2', 'M15.4 8.4h3v3.2c0 2.2-1.3 3.6-3.4 4.2'] },

    /* 动态：叠在一起的两张卡 */
    { id: 'moments', name: '动态', icon: ['M7.5 8.5h8.5v11.5H7.5z', 'M10 4.5h8.5v11.5'] },

    /* 收藏：星 */
    { id: 'favorites', name: '收藏', icon: ['M12 4.5l2.2 4.5 5 .7-3.6 3.5.9 5-4.5-2.4-4.5 2.4.9-5L4.8 9.7l5-.7z'] },

    /* 游戏：手柄 */
    { id: 'games', name: '游戏', icon: ['M8 8.5h8a3.8 3.8 0 0 1 3.7 4.7l-.6 2.1a2.2 2.2 0 0 1-4 .8L14 15h-4l-1.1 1.1a2.2 2.2 0 0 1-4-.8l-.6-2.1A3.8 3.8 0 0 1 8 8.5z', 'M8.2 11.6v1.6', 'M7.4 12.4h1.6', 'M16 12.1h.7'] },

    /* 生图室：一支画笔 */
    { id: 'studio', name: '生图室', icon: ['M14.8 4.8l4.4 4.4-9 9-5.4 1.4 1.4-5.4z', 'M12.8 6.8l4.4 4.4'] },

    /* 世界书：地球 */
    { id: 'worldbook', name: '世界书', icon: ['M12 20a8 8 0 1 0 0-16 8 8 0 0 0 0 16z', 'M4 12h16', 'M12 4c2.5 2.4 3.8 5 3.8 8s-1.3 5.6-3.8 8c-2.5-2.4-3.8-5-3.8-8s1.3-5.6 3.8-8z'] },

    /* 窗廊：四格窗 */
    { id: 'windows', name: '窗廊', icon: ['M4.5 4.5h15v15h-15z', 'M12 4.5v15', 'M4.5 12h15'] },

    /* MCP：一个插头 */
    { id: 'mcp', name: 'MCP', icon: ['M8.5 6.5V3.5', 'M15.5 6.5V3.5', 'M6.5 6.5h11v3.4a5.5 5.5 0 0 1-11 0z', 'M12 15.4v4.1'] },

    /* 美化：两颗星，一大一小 */
    { id: 'beautify', name: '美化', icon: ['M10 4.5l1.6 3.9 3.9 1.6-3.9 1.6L10 15.5l-1.6-3.9L4.5 10l3.9-1.6z', 'M17.3 15.3l.8 1.9 1.9.8-1.9.8-.8 1.9-.8-1.9-1.9-.8 1.9-.8z'] },

    /* MioWatery 原版独立应用入口：只放入侧栏，不挤占 phone 桌面布局 */
    { id: 'wallet', name: '钱包', icon: ['M4 7h16v12H4z', 'M4 10h16', 'M16 15h1'], sidebarOnly: true },
    { id: 'life', name: '生活', icon: ['M4 5h16v14H4z', 'M8 9h8', 'M8 13h8'], sidebarOnly: true },
    { id: 'coread', name: '一起读', icon: ['M4 5c3-1 5.5-.5 8 1v13c-2.5-1.5-5-2-8-1z', 'M20 5c-3-1-5.5-.5-8 1v13c2.5-1.5 5-2 8-1z'], sidebarOnly: true },
    { id: 'offline', name: '离线内容', icon: ['M5 4h14v16H5z', 'M8 8h8', 'M8 12h8', 'M8 16h5'], sidebarOnly: true },
    { id: 'preset', name: '预设', icon: ['M5 5h14v14H5z', 'M8 9h8', 'M8 13h5'], sidebarOnly: true },
    { id: 'repo', name: '资源仓库', icon: ['M4 7h16v13H4z', 'M4 7l2-3h12l2 3'], sidebarOnly: true },
    { id: 'youtube', name: '视频', icon: ['M4 7h16v10H4z', 'M10 10l5 2-5 2z'], sidebarOnly: true },
    { id: 'crread', name: '共读书架', icon: ['M4 5h16v14H4z', 'M8 8h8', 'M8 12h8'], sidebarOnly: true },
    { id: 'couple', name: '情侣空间', icon: ['M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z'], sidebarOnly: true },
    { id: 'msgs', name: '消息', icon: ['M4 5h16v12H9l-5 3z'], sidebarOnly: true },
    { id: 'iff', name: '互动', icon: ['M5 5h14v14H5z', 'M8 9h8', 'M8 13h5'], sidebarOnly: true },
    { id: 'xinji', name: '心迹', icon: ['M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z'], sidebarOnly: true },
    { id: 'rolephones', name: '角色手机', icon: ['M7 3h10v18H7z', 'M10 6h4', 'M11 18h2'], sidebarOnly: true },
    { id: 'stickers', name: '表情包', icon: ['M5 5h14v14H5z', 'M8 10h.1', 'M16 10h.1', 'M8 14q4 4 8 0'], sidebarOnly: true },
    { id: 'desktopcustom', name: '桌面自定义', icon: ['M3 4h18v13H3z', 'M8 21h8', 'M12 17v4'], sidebarOnly: true },
    { id: 'css', name: '样式设置', icon: ['M4 5h16v14H4z', 'M8 9h8', 'M8 13h5'], sidebarOnly: true },
    { id: 'profile', name: '个人资料', icon: ['M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z', 'M4 21a8 8 0 0 1 16 0'], sidebarOnly: true },
    { id: 'app', name: '应用中心', icon: ['M4 4h6v6H4z', 'M14 4h6v6h-6z', 'M4 14h6v6H4z', 'M14 14h6v6h-6z'], sidebarOnly: true },
    { id: 'cset', name: '聊天设置', icon: ['M4 7h16', 'M4 12h16', 'M4 17h16', 'M8 5v4', 'M15 10v4', 'M10 15v4'], sidebarOnly: true },
    { id: 'deco', name: '主页装饰', icon: ['M4 5h16v14H4z', 'M8 9h8', 'M8 13h5'], sidebarOnly: true },

    /* 设置：两根滑块 */
    { id: 'settings', name: '设置', icon: ['M4.5 8.5h4.5', 'M13 8.5h6.5', 'M10.5 6.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z', 'M4.5 15.5h4.5', 'M13 15.5h6.5', 'M16.5 13.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z'] }
  ];

  const DOCK_IDS = ['chat', 'diary', 'album', 'memory', 'settings'];

  const PER_PAGE = 8;

  function pages() {
    const out = [];
    const homeApps = APPS.filter(function (app) { return !app.sidebarOnly; });
    for (let i = 0; i < homeApps.length; i += PER_PAGE) out.push(homeApps.slice(i, i + PER_PAGE));
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
