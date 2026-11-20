# Security Policy

Thank you for helping keep this project and its users safe. This document explains how to report vulnerabilities, what versions are supported, and how we handle security fixes.

## Supported Versions

We follow [SemVer](https://semver.org/). Lisdex is a small app built from source, so only the latest release receives fixes.

|          Version | Status          | Security Fixes |
| ---------------: | --------------- | -------------- |
| Latest `MAJOR.MINOR` | **Active**      | ✅ Yes         |
|   Older versions | **End of Life** | ❌ No — update with `brew upgrade lisdex` or rebuild from the latest tag |

## Reporting a Vulnerability

**Please DO NOT open a public GitHub issue for security reports.**

Use the following private channel:

- **GitHub Security Advisory:** Navigate to **Security → Report a vulnerability** at [/security](https://github.com/pedrol2b/lisdex/security/advisories).

When reporting, include:

- A clear description of the issue and its impact
- Steps to reproduce (PoC, logs, screenshots)
- Affected versions and environment details (macOS version, install method)
- Any known mitigations or workarounds

We’ll acknowledge receipt within the **Service Levels** below and keep you updated throughout triage and remediation.

> If you believe the issue affects the broader ecosystem (e.g., the Homebrew tap or a supply-chain compromise), please indicate that so we can coordinate responsibly.

## Service Levels (SLA)

We aim to meet or exceed the timelines below. If coordinated disclosure requires an embargo, we’ll communicate expected dates.

| Severity (CVSS v3.1)    | Acknowledge | Triage Completed | Fix/Advisory Target |
| ----------------------- | ----------- | ---------------- | ------------------- |
| **Critical (9.0–10.0)** | 24 hours    | 48 hours         | 7 days              |
| **High (7.0–8.9)**      | 48 hours    | 5 days           | 14 days             |
| **Medium (4.0–6.9)**    | 5 days      | 10 days          | Best effort         |
| **Low (0.1–3.9)**       | 7 days      | Best effort      | Best effort         |

> These targets are goals, not guarantees. Complex issues may require more time.

## Security Hardening & Supply-Chain Practices

To reduce risk for users, maintainers strive to:

- Require **2FA** for maintainers on GitHub.
- Use **protected branches**, required reviews, and signed commits where possible.
- Keep the app **dependency-free** (Apple frameworks only) so there is no third-party code to audit.
- Distribute **source only**: the Homebrew formula pins each release tarball by **SHA-256**, and the app is compiled on the user's Mac.
- Request **no special privileges**: no root helper, no Accessibility or Full Disk Access, no network access. Lisdex only holds standard power assertions (or runs `/usr/bin/caffeinate` if the user picks it).
- Pin GitHub Actions to commit SHAs and keep CI permissions read-only by default.

If you observe suspicious activity (e.g., a look-alike tap or a modified formula), please include that context in your report.

## Scope & Non-Security Issues

Please use **GitHub Issues** for non-security bugs, feature requests, or usage questions. Bugs such as "my Mac still went to sleep" or crashes without a security impact should not be reported via private channels.
