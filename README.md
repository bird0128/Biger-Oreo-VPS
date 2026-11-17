# Biger & Oreo VPS

A one-click Xray VLESS + REALITY deployment project for Linux VPS servers.

本项目用于快速部署和管理 Xray VPN 节点，当前基于 VLESS + REALITY 协议，支持 TCP + XTLS Vision 和 XHTTP 传输方式。

## Project Information

- **Repository:** [Biger-Oreo-VPS](https://github.com/bird0128/Biger-Oreo-VPS)
- **Website:** https://us1.lcxsdsg.ccwu.cc:8445/
- **Platform:** Linux VPS
- **Core:** Xray
- **Protocol:** VLESS + REALITY
- **Transport:** TCP + XTLS Vision / XHTTP

## Quick Start

在一台全新的 Linux VPS 上，以 root 权限执行：

```bash
wget https://raw.githubusercontent.com/bird0128/Biger-Oreo-VPS/main/xray-install.sh && sudo bash xray-install.sh
```

脚本将引导完成安装，并生成客户端连接信息。

**注意：**
- 建议在全新的 Linux VPS 上执行。
- 服务器需要开放 TCP 443 端口。
- 如果 443 端口已经被其他服务占用，请先确认端口情况。
- 不要在正在运行其他 Xray 服务的生产服务器上直接测试。

## Features

- 自动安装 Xray-core
- 自动生成 UUID
- 自动生成 REALITY 密钥和 Short ID
- 支持 TCP + XTLS Vision
- 支持 XHTTP
- 自动配置 systemd 服务
- 支持客户端添加和删除
- 支持服务状态查看与重启
- 自动配置 TCP BBR
- 生成客户端连接 URI 和二维码

## Project Roadmap

后续计划逐步整合：

- VPS 一键初始化与部署
- 节点配置自动生成
- Clash / Shadowrocket 订阅文件管理
- Biger & Oreo 网站整合
- 配置备份与迁移
- 多服务器部署管理

以上功能将分阶段开发，尚未完成的功能不会视为当前已支持功能。

## Upstream Project & License

本项目基于以下开源项目进行二次开发：

- Original project: [ndatg/xray-vless-reality-installer](https://github.com/ndatg/xray-vless-reality-installer)
- Original author: NDA
- License: MIT

保留原项目的 MIT License 许可及原作者版权声明。

## Disclaimer

本项目仅供技术研究和学习使用。使用者应遵守所在国家或地区的法律法规，并自行承担使用本项目产生的责任。
