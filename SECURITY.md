# 安全说明

## 支持范围

安全修复仅针对最新发布版本。由于 Cursor 会调整安装文件结构，旧版 Cursor 和旧版安装器不保证继续获得修复。

## 报告漏洞

请通过 GitHub Security Advisories 的 [Report a vulnerability](https://github.com/652036/cursor-zh-cn/security/advisories/new) 私下报告安全问题。报告中请包含：

- 受影响的 Cursor 和 CursorZh 版本
- 操作系统和安装方式
- 最小复现步骤
- 预期行为、实际行为和安全影响
- 已脱敏的日志、截图或示例文件

请勿在公开 Issue 中发布可直接利用的漏洞、令牌、Cookie、账号信息、完整日志或包含隐私的截图。维护者确认问题后会协调修复和披露时间。

## 安全边界

安装器按设计只修改以下内容：

- Cursor 安装目录中的 `workbench.html`
- `product.json` 中与 workbench HTML 对应的校验值
- workbench 目录中的 `cursor-zh.js`
- 用户目录中的 `User/locale.json`

项目不会索取 Cursor 登录凭据，也不会修改账号、订阅、用量、模型请求或网络通信。如果脚本出现这些行为，或写入其他不相关文件，请停止使用并提交安全报告。

## 获取方式

本项目只以源码形式分发，请从本仓库下载或克隆。批处理和脚本文件均为明文，运行前可自行审阅。
