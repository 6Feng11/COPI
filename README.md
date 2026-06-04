# Copy

Copy 是一款 Mac 本地剪贴板历史工具。第一版以菜单栏应用形式运行，默认记录用户复制过的文字、链接和图片，并把历史数据保存在本机。

## 当前版本能力

- 菜单栏常驻入口。
- 记录文字和链接内容。
- 记录图片原始数据到本地目录。
- 历史记录本地 JSON 保存。
- 历史面板搜索。
- 点击历史记录后重新写回系统剪贴板。
- 暂停记录。
- 删除单条记录。
- 清空全部历史。

## 本地数据位置

```text
~/Library/Application Support/Copy/
```

其中：

- `history.json` 保存剪贴板历史元数据。
- `Images/original/` 保存复制过的图片原始数据。
- `Images/thumbnails/` 预留给缩略图文件。

## 运行

推荐先打包成 Mac 应用：

```bash
scripts/build-app-bundle.sh
open .build/app/Copy.app
```

运行后，点击系统菜单栏里的 Copy 图标打开菜单，再选择“打开剪贴板历史”。

开发调试时也可以直接运行 SwiftPM 可执行目标：

```bash
swift run CopyApp
```

## 验证

```bash
swift test
swift build
scripts/verify-app-bundle.sh
```

## 后续改进

- 添加真正的全局快捷键唤起历史面板。
- 从 JSON 元数据存储升级到 SQLite。
- 为图片生成和展示真实缩略图。
- 增加开机启动。
- 增加历史保留数量设置。
