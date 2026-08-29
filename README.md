# Cursor 简体中文补充翻译

[![CI](https://github.com/652036/cursor-zh-cn/actions/workflows/check.yml/badge.svg)](https://github.com/652036/cursor-zh-cn/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

本项目为 Cursor 专有界面提供简体中文补充翻译，包括设置、智能体、消息队列和部分弹窗。VS Code 基础界面由微软简体中文语言包翻译。

这是非官方社区项目，与 Anysphere 或 Cursor 无隶属关系。项目不修改账号、订阅、用量、模型请求或网络通信。

## 兼容性

当前版本在 Cursor 3.17.x 上完成测试。Cursor 更新可能覆盖安装目录中的改动；更新后重新双击 `一键汉化.bat` 即可。其他版本可能因文件结构变化而无法使用。

| 界面范围 | 翻译来源 |
| --- | --- |
| 菜单、命令面板、资源管理器和大部分 VS Code 设置 | 微软简体中文语言包 |
| Cursor 设置、智能体、消息队列和部分弹窗 | 本项目 |

## 安装

### Windows

1. 下载本仓库（Code → Download ZIP）并解压，或使用 `git clone`。
2. 双击 `一键汉化.bat`，脚本会关闭 Cursor、写入翻译并重新启动。

- `一键汉化.bat`：应用翻译。
- `取消汉化.bat`：移除翻译。

批处理脚本优先使用 Python 3；未安装 Python 时自动改用 Windows PowerShell 5.1，无需额外依赖。

### macOS 和 Linux

需要 Python 3.10 或更高版本：

```bash
python3 cursor_zh.py apply --kill --restart
python3 cursor_zh.py revert --kill --restart
python3 cursor_zh.py status
```

常见安装路径：

- macOS：`/Applications/Cursor.app/Contents/Resources/app`
- Linux：`/usr/share/cursor/resources/app`
- Linux 用户安装：`~/.local/share/cursor/resources/app`

如果安装器无法定位 Cursor，可将 `CURSOR_PATH` 设置为 Cursor 可执行文件或 `resources/app` 目录。

## 命令行

```text
python cursor_zh.py apply [--kill] [--restart] [--no-langpack]
python cursor_zh.py revert [--kill] [--restart]
python cursor_zh.py status
python cursor_zh.py --version
```

`--kill` 允许安装器关闭正在运行的 Cursor，`--restart` 在操作完成后重新启动 Cursor。

## 工作方式

安装器执行以下操作：

1. 将 `cursor-zh.js` 复制到 Cursor workbench 目录。
2. 在 `workbench.html` 中插入脚本引用。
3. 更新 `product.json` 中对应的完整性校验值。
4. 将 `User/locale.json` 设置为 `zh-cn`。
5. 尝试安装微软简体中文语言包。

安装器不会修改 `argv.json`。写入采用临时文件替换；操作失败时会恢复本次改动。备份按安装位置、Cursor 版本和原文件哈希分开保存：

- Windows：`%APPDATA%\CursorZh\backup`
- macOS：`~/Library/Application Support/CursorZh/backup`
- Linux：`~/.config/CursorZh/backup`

“取消汉化”只删除本项目插入的脚本引用和词典文件，并按当前文件重新计算校验值。它不会使用旧版备份覆盖更新后的 Cursor 文件。

运行时通过 `MutationObserver` 处理新增或变化的界面节点。编辑器、终端、文件树、标签页、面包屑和聊天正文不会参与翻译，以减少文件名、代码和用户内容被误翻的情况。

## 开发

翻译词典位于 [`locales/zh-CN.json`](locales/zh-CN.json)。修改后运行：

```bash
python scripts/build_js.py
python scripts/build_js.py --check
python -m unittest discover -s tests -v
node --check cursor-zh.js
```

扫描本机 Cursor 安装中的候选漏翻：

```bash
python scripts/scan_cursor_strings.py --output missing.json
```

扫描结果包含调试文本和内部字段，必须人工确认后再加入词典。贡献流程和翻译约定见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 已知限制

- Cursor 更新会覆盖 workbench 文件，需要重新运行 `一键汉化.bat`。
- macOS 应用资源被修改后，原有代码签名可能失效，并影响 Gatekeeper 或自动更新。
- 安全软件可能将修改应用安装目录的行为识别为风险。
- 本项目不是 Cursor Marketplace 扩展。

## 安全

漏洞和敏感问题请按 [SECURITY.md](SECURITY.md) 私下报告。公开 Issue 不应包含令牌、Cookie、账号信息或未脱敏日志。

## 许可证

本项目采用 [MIT License](LICENSE)。
