# 网盘登录后自动保存 Cookie（一键添加网盘）

## 背景

原来的流程是：在「存储」页的 OpenList 网页管理页里添加存储时，Cookie 需要用户自己
去浏览器开发者工具 / 手机抓包里复制，再粘贴进输入框。普通用户基本做不来。

现在在「存储」页右下角加了一个 **「一键添加网盘」** 浮动按钮：
选网盘 → 用 App 内嵌 WebView 正常登录 → 登录成功后自动从 WebView 的 Cookie 仓库里
取出该网盘域名下的 Cookie → 直接调 OpenList 接口创建存储。**全程不需要手动粘贴 Cookie。**

## 改动清单

新增（`openlist_web_ui/lib/pages/storages/`）：

| 文件 | 作用 |
|---|---|
| `cookie_login_sites.dart` | 网盘站点表：登录页地址、要读取 Cookie 的域名、对应 OpenList 驱动名、Cookie 有效性判定 |
| `CookieLoginPage.dart` | 内嵌 WebView 登录页，轮询抓取 Cookie，出现有效登录态自动完成 |
| `QuickAddStoragePage.dart` | 「一键添加网盘」页：选网盘 → 登录 → 自动生成配置并创建存储 |

修改：

| 文件 | 改动 |
|---|---|
| `openlist_web_ui/lib/pages/storages/StoragesPage.dart` | 原来只有 WebScreen；现在用 Stack 叠加一个「一键添加网盘」FAB，创建成功后刷新网页 |
| `openlist_web_ui/lib/pages/web/web.dart` | `WebScreenState` 增加公开的 `reload()`，供外部刷新 |

依赖没有变化：`openlist_web_ui` 本来就依赖 `flutter_inappwebview: ^6.1.5`。

## 内置支持的网盘

| 网盘 | 登录页 | 判定为登录态的 Cookie |
|---|---|---|
| 夸克网盘 | pan.quark.cn | `__pus` + `__puus` |
| UC 网盘 | drive.uc.cn | `__pus` + `__puus` |
| 百度网盘 | pan.baidu.com | `BDUSS` |
| 115 网盘 | 115.com | `UID` + `CID` |
| 移动云盘（139/和彩云） | yun.139.com | `authorization` / `Login_UserNumber` / `ORCHES-I-ACCOUNT-ENCRYPT` 任一 |

另外还有「**其它网盘（自定义登录网址）**」：输入任意网盘登录页地址，登录后抓该域名下的
全部 Cookie，再手动选一次对应的 OpenList 驱动即可。

要新增网盘，只要往 `cookie_login_sites.dart` 的 `kCookieSites` 里加一条即可。

## 实现要点

1. **Cookie 从哪来**：`CookieManager.instance().getCookies(url: WebUri(...))`，
   按站点表里配置的域名取，多个域名时按名字去重后拼成 `k1=v1; k2=v2`。
2. **怎么知道登录成功**：WebView 没有可靠的「登录完成」回调，所以用 1.2 秒轮询 +
   `CookieSite.isValidCookie()` 校验必需 Cookie 名；一旦校验通过就自动返回。
   顶栏也保留了「完成」按钮和「复制」按钮作为兜底。
3. **配置怎么拼**：`GET /api/admin/driver/list` 拿到该驱动的表单 schema，
   `common` / `additional` 里的字段全部按 `default` 填充，
   再把 Cookie 塞进名字里带 `cookie` 的那个字段，
   `mount_path` / `remark` 用弹窗里填的值，最后 `POST /api/admin/storage/create`。
4. **换账号**：登录页右上角有「清除登录状态」，会清掉本机 WebView 的 Cookie 后重新登录。
5. 桌面端（Linux）走的是 `openlist_native_ui` 的原生添加存储界面，
   本次没有改它；如需同样能力，把 `CookieLoginPage` 复用过去即可
   （`openlist_native_ui` 需要额外加 `flutter_inappwebview` 依赖）。

## 已知限制

- 123 云盘、迅雷、阿里云盘三家的 OpenList 驱动要的不是浏览器 Cookie（是账号密码 /
  refresh_token），不在这次范围内；阿里云盘可以先用「自定义登录网址」抓 Cookie，
  如果驱动只认 refresh_token 则仍需手动获取。
- 有些驱动除了 Cookie 还要求额外参数（如 115 的 qrcode token），
  创建后如果提示缺字段，请到网页管理页补齐——Cookie 已经自动填好了。
