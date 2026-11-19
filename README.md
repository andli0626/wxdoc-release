# 微文存阅 · 产品发布页

纯静态单页，按《GitHub Pages 国内访问分析与发布方案》落地：

- 零第三方依赖：系统字体、同源 `styles.css`、内联 SVG、无统计埋点
- 同源下载：所有安装包放在 `downloads/`，页面用相对路径引用，不走 GitHub Release
- Pages 就绪：根目录 `index.html` + `.nojekyll`，可直接用 `Deploy from a branch` 发布

## 目录

```
release-page/
├── index.html           # 发布页入口
├── styles.css           # 同源样式（用 ?v= 打版本号）
├── .nojekyll            # 跳过 Jekyll，避免下划线目录 404
├── check.sh             # 零外部依赖 + 下载完整性自检
├── assets/              # 图标与产品截图
│   ├── icon-128.png
│   ├── icon-256.png
│   ├── icon-512.png
│   ├── article-list.jpg
│   └── guide-page.jpg
└── downloads/           # 同源安装包
    ├── wxdoc-desk-2.0.23-macos-universal.dmg
    ├── wxdoc-desk-2.0.23-windows-x64.msi
    ├── wxdoc-desk-2.0.23-windows-x64-setup.exe
    ├── wxdoc-app-3.1.20-android.apk
    ├── wxdoc-web-pc.zip
    ├── wxdoc-web-h5.zip
    └── wxdoc-web-ext.zip
```

## 本地预览

```bash
cd release-page
python3 -m http.server 8765
# 打开 http://127.0.0.1:8765/
```

不要直接双击 `index.html`：`file://` 下相对下载与部分浏览器行为不一致，用本地 HTTP 服务最接近线上。

## 发布前自检

```bash
./check.sh
```

检查四项：高风险外部依赖、必要文件、下载链接是否都存在、单文件是否超过 100 MB。

## 发布到 GitHub Pages

方案里的硬约束：**GitHub 免费账号只能用 public 仓库发布 Pages**。当前 `andli0626/wx-article` 是私有仓库，不能直接开 Pages（除非升级 GitHub Pro，约 $4/月）。

推荐做法：另建一个只放发布页的 public 仓库，例如 `wxdoc-release`。

1. 新建 public 仓库 `wxdoc-release`（不要勾选 README，保持空仓库）。
2. 把本目录全部内容推到仓库根目录：

```bash
cd release-page
git init
git add -A
git commit -m "release: 微文存阅多端发布页"
git branch -M main
git remote add origin git@github.com:<你的账号>/wxdoc-release.git
git push -u origin main
```

3. 仓库 **Settings → Pages**：
   - Source 选 `Deploy from a branch`
   - Branch 选 `main`
   - 目录选 `/ (root)`
   - Save
4. 等待 1–10 分钟，访问 `https://<你的账号>.github.io/wxdoc-release/`。

> 公开仓库意味着页面源码与 `downloads/` 里的安装包对全网可见。若安装包只供内部使用，建议改用飞书知识库/企业内网 OSS，或给 Pages 仓库单独做访问控制（GitHub Pages 本身不支持鉴权）。

## 更新版本时

1. 替换 `downloads/` 下的安装包，文件名保持「产品-版本-平台」格式。
2. 同步修改 `index.html` 中的：
   - 下载链接文件名
   - 文件大小、系统要求、版本号
   - 顶部 `brand-version` 与页脚版本行
3. 修改 `styles.css` 后，把 `index.html` 里的 `styles.css?v=20261119-v1` 改成新日期，避免边缘缓存。
4. 跑 `./check.sh`，通过后再提交。

## 三条红线

1. **免费账号必须 public**：页面、源码、安装包都会公开。
2. **禁止商用**：不能把 GitHub Pages 当作商业官网、电商或 SaaS 托管。
3. **体积限制**：单文件 ≤ 100 MB，整站 ≤ 1 GB。当前整站约 93 MB。

## 下载文件来源

- macOS DMG、Windows MSI/EXE、Web PC、H5、浏览器扩展：GitHub Actions 运行 #4（`44427310821`）的构建产物
- Android APK：本地 `./gradlew assembleProdRelease` 产物（v3.1.20）

## 国内访问预期

按方案实测，`*.github.io` 在国内可直连，但存在跨境链路波动；企业网络、政务内网大概率不通。对外分享可用，正式客户交付请走国内托管 + 备案，或内网通道。
