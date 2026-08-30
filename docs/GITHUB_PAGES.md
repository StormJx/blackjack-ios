# GitHub Pages：托管隐私政策

App Store Connect 需要一个**不登录就能打开**的 https 隐私政策 URL。本仓库把页面放在 `docs/privacy.html`，用 GitHub Pages 的 **`/docs` 文件夹**发布。

发布后地址（仓库为 `StormJx/blackjack-ios`）：

- 首页：`https://stormjx.github.io/blackjack-ios/`
- **隐私政策（填进商店）：** `https://stormjx.github.io/blackjack-ios/privacy.html`

`docs/.nojekyll` 已放入，避免 Jekyll 改写静态 HTML。

---

## 一次性开启（约 3 分钟）

1. 先把包含 `docs/privacy.html` 的 commit **push 到 `main`**  
   （本地已提交但未推送时，在仓库根目录执行 `git push`；或在 GitHub Desktop 推送。）
2. 打开仓库：**https://github.com/StormJx/blackjack-ios**
3. **Settings** → 左侧 **Pages**
4. **Build and deployment**
   - Source：选 **Deploy from a branch**
   - Branch：选 **`main`**
   - Folder：选 **`/docs`**
5. 点 **Save**
6. 等 1–2 分钟。同一页顶部会出现 “Your site is live at …”
7. 浏览器打开  
   `https://stormjx.github.io/blackjack-ios/privacy.html`  
   应看到中英「隐私说明」，且是 https、无需登录。
8. 把该 URL 填进 App Store Connect → App 信息 → **隐私政策网址**。

若打开是 404：再等一两分钟，或确认 Pages 的 Branch 是 `main`、Folder 是 `/docs`，且 `main` 上已有 `docs/privacy.html`。

---

## 以后改隐私文案

1. 只改 `docs/privacy.html`（与应用内 `PrivacyView` / `Localizable.xcstrings` 的 `privacy.body.*` 保持一致）。
2. commit + push `main`。
3. 一两分钟后刷新上述 URL，无需再改 Pages 设置。
4. 若接了广告或统计：同时改本页、应用内说明、`PrivacyInfo.xcprivacy` 和商店隐私标签。

---

## 不使用 GitHub Pages 时

把 `docs/privacy.html` 原样上传到任意 https 静态托管，把最终链接填进 Connect 即可。
