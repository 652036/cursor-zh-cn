# 贡献指南

欢迎提交翻译修正、兼容性改进和缺陷修复。提交前请确认改动范围明确，并完成与改动相关的本地检查。

## 开始之前

- 搜索现有 Issue，避免重复报告或重复实现。
- 缺陷报告应包含 Cursor 版本、操作系统、复现步骤和实际结果。
- 不要在 Issue、提交记录或日志中包含账号、令牌、Cookie、个人路径等敏感信息。
- 安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

## 项目文件

| 文件 | 用途 |
| --- | --- |
| `locales/zh-CN.json` | 翻译词典，新增或修正译文时优先修改 |
| `src/runtime.js` | 运行时翻译和保护区域规则 |
| `cursor_zh.py` | 跨平台安装、移除和状态检查 |
| `CursorZh.ps1` | Windows PowerShell 5.1 兼容入口 |
| `scripts/build_js.py` | 根据词典和运行时源码生成发布脚本 |
| `cursor-zh.js` | 自动生成文件，不应直接编辑 |

修改词典或运行时源码后，重新生成 `cursor-zh.js`：

```bash
python scripts/build_js.py
```

提交中应同时包含源文件和更新后的 `cursor-zh.js`。

## 词典结构

`locales/zh-CN.json` 包含以下字段：

- `phrase`：完整句子、设置项、弹窗和按钮。包含多个单词的文本可在普通界面中匹配，单个短词仅在明确的界面控件中匹配。
- `short`：侧边栏、工具栏和菜单中的短文本，例如 `Agents`。该字段的匹配范围较小，用于降低正文误翻风险。
- `patterns`：包含变量的句子。`match` 使用 JavaScript 正则表达式，`replace` 可通过 `$1` 等语法引用捕获组。

包含空格的句子应放入 `phrase`，而不是 `short`。文件树、标签页、面包屑、编辑器、终端、输入框和聊天正文属于保护区域，不应通过增加宽泛短词绕过保护。

## 翻译原则

1. 只翻译用户可见界面，不翻译协议字段、模型 ID、文件路径和命令名。
2. 保留快捷键原文，例如 `Ctrl+Enter` 和 `⌘K`。
3. 产品名和通用技术术语可保留英文，例如 `Cursor Tab` 和 `MCP`。
4. 词典键必须与界面原文一致，包括大小写、标点和省略号形式。
5. 不要将调试、测试、遥测或内部协议文本加入词典。
6. 动态内容使用 `patterns`，不要为变量的每个可能值添加固定句子。

例如：

```json
{
  "match": "^Accept the next word of a suggestion via (.+)$",
  "replace": "通过 $1 接受建议中的下一个词"
}
```

## 本地检查

```bash
python scripts/build_js.py --check
python -m unittest discover -s tests -v
node --check cursor-zh.js
node -e "const d=require('./locales/zh-CN.json'); for (const p of d.patterns) new RegExp(p.match)"
python cursor_zh.py status
```

扫描本机 Cursor 安装中的候选漏翻：

```bash
python scripts/scan_cursor_strings.py --output missing.json
```

扫描结果不能直接批量导入。请结合界面或安装包上下文逐条确认；开发工具、测试文本、遥测、日志、协议字段、模型 ID、CSS、HTML、LaTeX 和动态模板片段通常不是用户界面文案。

## Pull Request

- 一个 Pull Request 应集中解决一个问题。
- 说明改动原因、验证方式和受影响的 Cursor 版本。
- 界面变化或翻译修正可附脱敏截图。
- 不要提交构建产物、临时扫描结果或本机配置，`cursor-zh.js` 除外。
- 确保 CI 通过后再请求审查。
