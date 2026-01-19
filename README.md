# AI 2026

Prediction and speculation for AI in 2026.

<!-- vim-markdown-toc GFM -->

- [The Anthropic Skill Supply Chain Attack](#the-anthropic-skill-supply-chain-attack)
- [AI26 Plugin](#ai26-plugin)
    - [Quickstart](#quickstart)
    - [Developer Guide](#developer-guide)

<!-- vim-markdown-toc -->

## The Anthropic Skill Supply Chain Attack

> [!WARNING]
> **Security Research Code - Use At Your Own Risk**
>
> This folder contains code that demonstrates supply chain attacks capable of exfiltrating sensitive data (API keys, credentials) from your environment.
>
> **For educational and authorized security research purposes only.**
>
> By accessing or executing this code, you acknowledge:
> - You understand the risks involved
> - You accept full responsibility for any consequences
> - You will only use this in environments you own or have explicit authorization to test
> - The author provides this code "AS IS" without warranty of any kind
> - The author is not liable for any damages, data loss, or credential exposure
>
> **Do not run this code in production environments or with real credentials.**

Content in:

[./supply-chain](./supply-chain)

## AI26 Plugin

PDF conversion and document processing tools for Claude Code.

### Quickstart

```
/plugin marketplace add dwmkerr/ai26
/plugin install ai26@ai26
```

### Developer Guide

For local development:

```bash
git clone https://github.com/dwmkerr/ai26.git
cd ai26
claude plugin marketplace add ./plugins/ai26
claude plugin install ai26@ai26
```

Uninstall:

```bash
claude plugin marketplace remove ai26
```

