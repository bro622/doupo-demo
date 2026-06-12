# 斗破苍穹·斗帝之路 — 官网

纯静态游戏介绍官网，可直接部署到 GitHub Pages / Vercel。

## 本地预览

直接在浏览器中打开 `index.html`，或用任意 HTTP 服务器：

```bash
cd website
python -m http.server 8080
# 访问 http://localhost:8080
```

## 部署

### GitHub Pages
将 `website/` 目录内容推送到 `gh-pages` 分支。

### Vercel
将 `website/` 作为项目根目录导入 Vercel。

## 目录结构

```
website/
├── index.html              # 单页官网
├── README.md               # 本文件
└── assets/
    ├── portraits/          # 角色头像
    │   ├── xiaoyan.png     #   萧炎
    │   ├── xuner.png       #   萧薰儿
    │   └── cailin.png      #   彩鳞
    └── idle/               # 角色待机立绘（Hero 装饰用）
        ├── xiaoyan.png
        ├── xuner.png
        └── cailin.png
```

## 技术栈

- HTML5 + CSS3 + vanilla JS
- 字体：ZCOOL XiaoWei + Noto Serif/Sans SC（Google Fonts）
- 无构建工具，无框架依赖
