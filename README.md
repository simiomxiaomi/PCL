# PCL (Minecraft Download Fix)

> **第三方修改版**：本仓库不是 PCL 官方项目，与 [龙腾猫跃](https://github.com/Meloong-Git) / [Meloong-Git/PCL](https://github.com/Meloong-Git/PCL) 无关。
> 本仓库仅提供一份**官方 2.99.0.0 二进制的补丁版本**，把被关闭的「下载 Minecraft」功能恢复回来，其余代码与官方完全一致。

---

## 这是什么

官方 PCL **2.99.0.0** 在源码里用一个常量关掉了整个 MC 下载功能：

```vb
Public Const RestrictMcDownload As Boolean = True
```

编译时这个常量把 `If ... Then` 的另一半分支直接删掉了，所以官方 exe 里
`PageDownloadInstall.LoaderInit` 只剩下一个立刻抛错的「关闭下载」加载器，点「下载 → 安装 MC」只会看到：

> 为遵守相关法律法规，PCL 暂时不再提供 MC 下载功能，非常抱歉 qwq……

本仓库的 [`pcl.exe`](pcl.exe) 是**官方原版 exe 打了 1 个方法的 IL 补丁**的产物：
把 `PageDownloadInstall::LoaderInit` 改回调用程序内部本来就存在的
`DlClientListLoader`（版本清单加载器），回调复用 exe 里现成的 `_Lambda$__R3-4`
（内部调用 `LoadMinecraft_OnFinish` 填充版本列表）。

**没有重新编译，没有替换任何其它方法**，因此正版（微软）登录、离线登录、联机、
自动更新、主题、整合包等功能与官方版**完全一致**。

## 快速使用

1. 关闭 PCL，找到你的 `pcl.exe`（通常在 PCL 根目录），把它改名为 `pcl.exe.bak` 备份；
2. 下载仓库里的 [`pcl.exe`](pcl.exe)，放到同一位置；
3. 启动 PCL → 打开「下载」，应该能看到 最新版本 / 正式版 / 预览版 / 远古版 / 愚人节版 分组。

配置文件保存在同目录的 `PCL\` 文件夹里，**替换 exe 不会丢失任何设置**。

## 校验

| 文件 | 大小 | SHA256 |
| --- | --- | --- |
| `pcl.exe` | 5,972,480 字节 | `a2f6122dfd295e4c62cf0f04484cfd8e261b15a243162dd3b12193f2378e0afc` |
| 官方原版 `pcl.exe`（对照） | 5,980,160 字节 | `6b6e1260cb5a1d6a303855f1c60cab3d0bc1aebba7e40a964180188b271e7386` |

也可以直接跑校验脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

> 说明：用元数据工具查看时，`RestrictMcDownload` 这个常量仍然是 `True`——补丁改的是**分支代码**而不是常量。
> 不要用常量值判断补丁是否生效，以「下载页能列出 MC 版本」为准。

## 已验证

在 Windows 11、.NET Framework 4.8 实机运行：

- 打开「下载」页：日志 `DlClientList Main 状态改变：Finished`，OptiFine / LiteLoader / Fabric / NeoForge 列表均加载完成；
- 页面正常渲染，显示 `26.3`（正式版）、`26.4-snapshot-4`（预览版）等；
- 启动、切换页面、退出无异常；exe 的图标、版本信息、manifest 均保留；
- 与官方原版逐字节对比：只有 `PageDownloadInstall.LoaderInit` 的方法体不同。

## 原理与复现

补丁工具源码打包在 [`PclPatch-tools.zip`](PclPatch-tools.zip)（解压后 `dotnet run -c Release -- fix <官方 pcl.exe> <输出.exe>`），
基于 [dnlib](https://github.com/0xd4d/dnlib)，能在改写 IL 的同时保留 exe 的 Win32 资源
（图标、manifest、版本信息）。

工具做三件事：

1. 定位 `PCL.PageDownloadInstall::LoaderInit`；
2. 用新方法体替换：`PageLoaderInit(this, LoadMinecraft, PanLoad, PanAllBack, null, DlClientListLoader, new Action<...>(_Lambda$__R3-4), null, true)`；
3. 其余方法、资源、元数据原样写回。

`scan` 子命令可以列出目标 exe 里所有与 `RestrictMcDownload` 相关的常量使用点，便于排查版本差异。
实测用该工具对官方 exe 重新打补丁，输出与本仓库 `pcl.exe` 的 SHA256 完全一致。

## 仍然受限的两处

官方原版即如此，与本次补丁无关，暂未修改：

| 位置 | 现象 |
| --- | --- |
| 版本设置 → 修改版本 | 左上角的 Minecraft 卡片仍是隐藏的 |
| 本地整合包（.zip）安装 | `ModpackInstall()` 在官方 exe 里已被整段替换成提示文字，无代码可恢复 |

需要的话可以继续补丁（第一处已有确认的 patch 点：`LoadInstanceFinished` 里
`CardMinecraft.Visibility` 的 `ldc.i4.2` → `ldc.i4.0`）。

## 兼容性

- 仅适用于 **2.99.0.0（VersionCode 413）**；其它版本的方法体结构不同，补丁工具会找不到目标方法或产生错误结果；
- PCL 自动更新后会被官方 exe 覆盖，需要重新打补丁；
- 程序未签名，SmartScreen 可能提示「未知发布者」，选择「仍要运行」即可。

## 许可与致谢

- PCL 的著作权归 **龙腾猫跃** 及贡献者所有；
- 本仓库是**第三方基于 PCL 进行的二次修改**，命名遵循 [PCL 存储库合理使用指南](https://github.com/Meloong-Git/PCL/blob/main/LICENCE)（`PCL (XX Bug Fix)` 形式）；
- 完整许可文本见 [`LICENSE.md`](LICENSE.md)，请在使用或分发前阅读；
- 详细技术说明见 [`说明.md`](说明.md)；
- 感谢 PCL 作者与社区，本仓库只做了一处功能的还原，不主张任何原创权利。

如果本仓库帮助到了你，请去支持 PCL 官方：<https://meloong.com/pcl> / <https://meloong.com/afd/a/LTCat>
