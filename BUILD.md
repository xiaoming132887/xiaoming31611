# 构建说明（OpenListApp）

> 这是 **Flutter** 工程，不是普通的 Android/Gradle 工程。
> **AndroidIDE 不能构建它** —— 直接打开 `android/` 目录跑 Gradle 必然失败。

## 一、你在 AndroidIDE 里看到的报错是什么

```
Settings file '.../android/settings.gradle.kts' line: 4
> .../android/local.properties (No such file or directory)
```

- `android/local.properties` 里要写 `flutter.sdk=<Flutter SDK 路径>`，
  `android/settings.gradle.kts` 第 4 行要读它来加载 Flutter 的 Gradle 插件；
- 这个文件被 `android/.gitignore` 忽略了，**官方源码包里本来就没有**（不是这次改动弄没的），
  它由 Flutter 工具在 `flutter pub get` / `flutter build` 时自动生成；
- 就算你手写一个 local.properties，AndroidIDE 也构建不了：
  Flutter 工程的 Dart 编译、资源打包都要 `flutter` 命令参与，缺了 Flutter SDK 的 Gradle 插件和
  `flutter pub get` 生成的 `.dart_tool/package_config.json`，Gradle 只是空转。

## 二、正确构建方式 A：电脑上装 Flutter

1. 装 Flutter **3.29.3**（stable）和 Android SDK（AGP 8.7 / Kotlin 1.9.10，JDK 17 即可）。
2. 进工程根目录，先补 Android 端的 native 依赖（官方 CI 也是这么做的，仓库里只有占位文件
   `openlist_background_service/android/libs/mobile.aar.keep`）：

```bash
curl -L -o openlist_background_service/android/libs/mobile.aar \
  https://github.com/OpenListApp/OpenListLib/releases/latest/download/mobile.aar
```
> 文件约 270MB，用 GitHub 官方地址下不动就挂代理或用下载工具续传。

3. 构建：

```bash
flutter pub get
flutter build apk --debug                  # 调试包，无需签名
# 要正式包时再配 android/key.properties + key.jks：
flutter build apk --release
```

产物在 `build/app/outputs/flutter-apk/app-debug.apk`（或 `app-release.apk`）。

> 已顺手修了一处：原来的 `android/app/build.gradle.kts` 里
> `keyAlias = keystoreProperties["keyAlias"] as String` 在**没有** key.properties 时会因为
> `null as String` 直接抛异常，导致连 debug 包都构建不了。现在没配置时会自动退回 debug 签名。

## 三、正确构建方式 B：GitHub Actions（不用电脑）

我已经在仓库里加好了 `.github/workflows/build-apk.yml`：

1. 把这份代码 push 到你自己的 GitHub 仓库（main / master 分支）；
2. 打开仓库的 **Actions → Build APK (debug) → Run workflow**（或直接 push 触发）；
3. 跑完在 Actions 页面的 Artifacts 里下载 `app-debug-apk`。

这个 workflow 会自动下载 mobile.aar、执行 `flutter build apk --debug`，不需要任何签名密钥。

## 四、为什么不能直接在这台手机上构建

- AndroidIDE：只支持原生 Android/Gradle 工程，不支持 Flutter；
- Termux / 手机 Linux 终端：Flutter 官方**没有提供 Linux arm64 版 SDK**
  （`releases_linux.json` 里只有 `linux/flutter_linux_*.tar.xz`，即 x86_64），
  而且 Android SDK 里的 `aapt2` 也只有 x86_64，
  所以手机本地基本走不通，老老实实用电脑或 GitHub Actions。

## 五、本次改动的验证情况

- 新增/修改的 Dart 文件用 Dart 3.13 `dart format` 做过语法校验，全部通过；
- `flutter_inappwebview 6.1.5` 用到的 API（`CookieManager.instance().getCookies(url:)`、
  `deleteAllCookies()`、`Cookie.name/value`、`WebUri`、`InAppWebViewSettings` 各项、
  `onLoadStop` 回调签名）都对照包源码逐个核对过；
- 本机没有 Flutter SDK，所以 `flutter build apk` 需要你在电脑或 CI 上跑一次确认。
