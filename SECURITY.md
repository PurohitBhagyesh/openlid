# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Considerations

OpenLid interfaces with low-level macOS power management assertions and privileged power management settings (`/usr/bin/pmset`).

- **Thermal Safety**: OpenLid implements automatic thermal guard callbacks using `ProcessInfo.processInfo.thermalState`. In the event of system thermal elevation (`.serious` or `.critical`), OpenLid automatically terminates sleep-prevention.
- **Privilege Separation**: When installing the passwordless helper, OpenLid writes a strictly scoped sudoers rule (`/etc/sudoers.d/openlid`) that authorizes ONLY `/usr/bin/pmset -a disablesleep *` and nothing else.
- **Fail-Safe Cleanup**: Intercepts `SIGINT`, `SIGTERM`, and application termination to guarantee `pmset -a disablesleep 0` is restored.

## Reporting a Vulnerability

If you discover a security vulnerability within OpenLid, please do NOT file a public issue. Instead, report it privately via GitHub Security Advisories or email the maintainers directly.

