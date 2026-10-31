# 神机 · ASCII Ocean 桌面终端

两层：**Lively 的动态壁纸**（ASCII 海底）＋ **钉在底层的真终端**（Alacritty）。
终端永远压在海面上、被其他窗口盖住，但可以点进去打字、选中、复制。

## 现在的样子

- 壁纸：Lively 加载 `index.html`（只有海，没有假终端文字）
- 终端：Alacritty，无边框、82% 不透明、1320×760 居中，跑 PowerShell
- 层级：`pin-terminal.ps1` 每 150ms 把它 `SetWindowPos(HWND_BOTTOM)`，所以它一直在所有窗口下面、壁纸上面
- 桌面图标：已隐藏（右键桌面 → 查看 → 显示桌面图标 可恢复）
- 开机自启：`%APPDATA%\...\Startup\Desktop Terminal.lnk` → `E:\Apps\DesktopTerminal\start-terminal.cmd`

## 已验证

- 钉底层后窗口仍可见、可聚焦、可打字（实测输入 `echo pinned-at-bottom` 正常回显）
- 层级：其他窗口打开时盖住终端，终端不抢焦点

## 已知限制

- 点终端时 Windows 会短暂把它抬起来，守护进程 150ms 内压回去，可能有轻微闪动
- 壁纸层里**不能**放可交互的真窗口：`SetParent` 到桌面会让 DWM 合成崩掉（实测）
- DSH 这个版本没有 `tui` profile；`dsh headless` 读不到 GUI 里存的 API key，所以“在终端里和 DSH 对话”暂时不可用。终端里的 `claude` / `codex` 可以直接用
- Lively 暂停规则：有窗口盖住屏幕时会暂停壁纸动画

## 文件

```
desktop-wallpaper/
  index.html              海的壁纸（Lively 加载）
  assets/ocean.js         海洋引擎（改编自 GqqQq-Q/dsh-ascii-ocean）
  assets/app.js           海洋参数
  assets/style.css        深海渐变 / 暗角
  pin-terminal.ps1        钉底层守护进程
  start-terminal.cmd      启动终端 + 守护
  collect.ps1             采集本机数据（备用）
  *.png                   过程截图
E:\Apps\Alacritty\alacritty.exe
E:\Apps\DesktopTerminal\{start-terminal.cmd, pin-terminal.ps1}
%APPDATA%\alacritty\alacritty.toml
```

## 关机 / 撤销

1. 退出 Alacritty
2. 结束隐藏的 `powershell`（pin-terminal）
3. 删除 `Startup\Desktop Terminal.lnk`
4. Lively 里换回别的壁纸
