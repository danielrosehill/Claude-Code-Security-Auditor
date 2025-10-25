# Claude Code Security Auditor

[![Claude Code](https://img.shields.io/badge/Claude-Code-8A2BE2?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Claude Code Projects](https://img.shields.io/badge/Claude_Code-Projects_Index-blue?logo=github)](https://github.com/danielrosehill/Claude-Code-Repos-Index)
[![Master Index](https://img.shields.io/badge/GitHub-Master_Index-green?logo=github)](https://github.com/danielrosehill/Github-Master-Index)

A comprehensive system for managing and auditing security configurations across multiple machines in your infrastructure using Claude Code.

## Features

- **Machine Management**: Register and track multiple machines with detailed profiles
- **Security Auditing**: Automated security audits covering antivirus, rootkits, permissions, and more
- **Remote Execution**: Deploy Claude Code and run audits remotely via SSH
- **Audit History**: Track all security audits with timestamped reports
- **Profile Tracking**: Maintain structured JSON and human-readable profiles for each machine
- **Context Deployment**: Automatically create CLAUDE.md files on remote machines

## Quick Start

### 1. Add Your First Machine

```bash
./add-machine.sh
```

Follow the interactive prompts to provide:
- Machine name and description
- Network configuration (IP, SSH alias)
- Access methods (user/root)
- System information (OS, machine type)

The script will:
- Test SSH connectivity
- Check for Claude Code
- Offer to install Claude Code if needed
- Create CLAUDE.md context file on remote
- Generate complete machine profile

### 2. Run a Security Audit

```bash
# List available machines
./list-machines.sh

# Run audit on a specific machine
./audit-machine.sh <machine_name>

# View the audit report
cat machines/<machine_name>/reports/latest/audit-report.md
```

### 3. View Machine Profiles

```bash
# Brief list of all machines
./list-machines.sh

# Detailed information
./list-machines.sh --detailed

# Check connectivity status
./list-machines.sh --status

# View specific machine
./list-machines.sh <machine_name>
```

## Installation

### Prerequisites

- Bash 4.0+
- Python 3.6+
- SSH access to remote machines
- SSH key-based authentication configured

### Setup

1. Clone this repository:
```bash
cd ~/repos/github
git clone <repository-url> Claude-Code-Security-Auditor
cd Claude-Code-Security-Auditor
```

2. Ensure scripts are executable:
```bash
chmod +x add-machine.sh audit-machine.sh list-machines.sh
```

3. Verify SSH access to your machines:
```bash
ssh your-machine-alias
```

4. Add your first machine:
```bash
./add-machine.sh
```

## Security Audit Coverage

Each audit includes comprehensive checks:

### 1. Antivirus & Malware Protection
- Installation status
- Active/running status
- Automatic definition updates
- Recent scan logs

### 2. Rootkit Detection
- Detection tool installation (chkrootkit, rkhunter)
- Automated scanning configuration
- Recent scan results

### 3. System Updates
- Update status
- Automatic update configuration
- Pending security updates

### 4. File Permissions
- Critical system file permissions
- World-writable files
- SUID/SGID binaries
- Unsafe permission identification

### 5. User Accounts & Authentication
- User account enumeration
- Password-less accounts
- Sudo configuration
- SSH configuration security

### 6. Network Security
- Open ports and services
- Firewall status and rules
- Running network services
- Unnecessary service identification

### 7. Additional Security Tools
- Intrusion prevention (fail2ban)
- System log analysis
- Security monitoring tools

## Architecture

### Directory Structure

```
.
├── machines/                    # Machine profiles and data
│   └── {machine_name}/
│       ├── claude-profile.json  # Claude-optimized profile
│       ├── user-responses.json  # User input data
│       ├── user-responses.md    # Human-readable responses
│       ├── readable-profile.md  # Human-readable profile
│       ├── audit-log.json       # Audit event log
│       └── reports/             # Timestamped audit reports
│           └── {timestamp}/
│               └── audit-report.md
├── reports/                     # Global reports
├── private/                     # Sensitive data
├── add-machine.sh               # Machine management
├── audit-machine.sh             # Security auditing
├── list-machines.sh             # Machine listing
├── CLAUDE.md                    # Detailed documentation
└── README.md                    # This file
```

### Data Files

Each machine has multiple profile files:

- **claude-profile.json**: Machine profile for Claude Code integration
- **user-responses.json**: Structured user input in JSON format
- **user-responses.md**: Human-readable version of user responses
- **readable-profile.md**: Comprehensive human-readable profile
- **audit-log.json**: Chronological log of all audit events

## Usage Examples

### Adding a Machine with Full Configuration

```bash
./add-machine.sh

# Interactive prompts:
# Machine name: Ubuntu Development Server
# Description: Primary development environment
# Local IP: 10.0.0.4
# SSH alias: dev-server
# Tailscale: yes
# Tailscale IP: 100.64.1.10
# Root access: yes
# Default access: user
# OS: Linux
# Machine type: Server
# Claude Code: yes
```

### Running Different Audit Types

```bash
# Full comprehensive audit
./audit-machine.sh my_server --full

# Quick security check
./audit-machine.sh my_server --quick

# Generate report from existing data
./audit-machine.sh my_server --report-only
```

### Viewing and Managing Machines

```bash
# List all machines (brief)
./list-machines.sh

# Detailed view with all information
./list-machines.sh --detailed

# Test connectivity to all machines
./list-machines.sh --status

# View specific machine details
./list-machines.sh dev_server

# JSON output for programmatic access
./list-machines.sh --json
```

### Editing Existing Machines

```bash
# Edit a machine profile
./add-machine.sh --edit dev_server

# Update any field (previous values shown as defaults)
```

## Claude Code Integration

This system integrates seamlessly with Claude Code:

1. **Local Management**: Use these scripts from your local machine
2. **Remote Deployment**: Automatically deploy Claude Code to remote machines
3. **Context Files**: CLAUDE.md files provide machine-specific context
4. **Automated Audits**: Claude performs comprehensive security analysis
5. **Structured Reports**: Markdown reports with clear findings and recommendations

### Example Remote CLAUDE.md

When you add a machine, the system creates this context on the remote:

```markdown
# CLAUDE.md for dev_server

## Machine Purpose
Primary development environment for web applications

## System Information
- Machine Type: Server
- Operating System: Linux
- Local IP: 10.0.0.4

## Security Audit Context
This machine is part of the Claude Code Security Auditor system.
Regular security audits ensure best practices are followed.

## Audit Records
Records stored at: ~/repos/.../machines/dev_server/reports/
```

## Workflow

### Initial Setup Workflow

1. Add machine with `./add-machine.sh`
2. Provide all configuration details
3. System tests SSH connectivity
4. Claude Code installed if needed
5. CLAUDE.md deployed to remote
6. Complete profile created locally

### Regular Audit Workflow

1. Run `./audit-machine.sh <machine>`
2. System connects via SSH
3. Audit executed (Claude Code or manual)
4. Report generated and stored
5. Audit log updated
6. Machine status updated

### Review Workflow

1. List machines with `./list-machines.sh`
2. Review specific machine profile
3. Check audit history
4. Read latest audit report
5. Implement recommended fixes
6. Re-run audit to verify

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH alias
ssh <alias>

# Check machine reachability
ping <ip>

# Verify SSH keys
ssh-add -l

# Test direct connection
ssh user@<ip>
```

### Audit Failures

- Ensure SSH connectivity works
- Verify user has necessary permissions
- Check machine is Linux-based (primary support)
- Review audit-log.json for error details

### Claude Code Installation Issues

```bash
# Manual installation on remote
ssh <machine>
bash -c '$(curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh)'

# Verify installation
claude --version
```

### Profile Corruption

```bash
# Re-edit the machine
./add-machine.sh --edit <machine_name>

# Provide all information again
# System will overwrite corrupted data
```

## Commands Reference

### Machine Management
| Command | Description |
|---------|-------------|
| `./add-machine.sh` | Add new machine interactively |
| `./add-machine.sh --edit <name>` | Edit existing machine |
| `./list-machines.sh` | List all machines (brief) |
| `./list-machines.sh --detailed` | Detailed listing |
| `./list-machines.sh --status` | Check connectivity |
| `./list-machines.sh <name>` | View specific machine |
| `./list-machines.sh --json` | JSON output |

### Security Audits
| Command | Description |
|---------|-------------|
| `./audit-machine.sh <name>` | Full audit |
| `./audit-machine.sh <name> --quick` | Quick check |
| `./audit-machine.sh <name> --full` | Comprehensive audit |
| `./audit-machine.sh <name> --report-only` | Generate report only |

### Viewing Reports
```bash
# Latest report
cat machines/<name>/reports/latest/audit-report.md

# List all audits
ls -la machines/<name>/reports/

# View audit log
cat machines/<name>/audit-log.json

# View machine profile
cat machines/<name>/readable-profile.md
```

## Best Practices

1. **Regular Audits**: Run audits weekly or monthly
2. **Document Changes**: Update profiles when configurations change
3. **Review Reports**: Always read audit reports thoroughly
4. **Act on Findings**: Implement recommended security improvements
5. **Verify Fixes**: Re-audit after applying changes
6. **Maintain SSH**: Keep SSH key authentication working
7. **Backup Profiles**: Commit profiles to version control
8. **Use Descriptive Names**: Choose clear, meaningful machine names

## Security Considerations

- SSH keys should be properly secured
- Consider using Tailscale for additional security layer
- Review audit reports for sensitive information before sharing
- Keep machine profiles in private repository if needed
- Use the `private/` directory for sensitive data
- Ensure proper file permissions on audit reports

## Contributing

This is a personal security auditing system. If you'd like to adapt it for your infrastructure:

1. Fork the repository
2. Customize audit checklist for your needs
3. Modify scripts for your environment
4. Add additional security checks as needed

## Future Enhancements

Planned features:
- Automated scheduling with cron
- Aggregated reports across all machines
- Automated remediation scripts
- Security posture comparison tools
- Alert system for critical findings
- Historical trend analysis
- Compliance framework mapping

## License

MIT

## Author

**Daniel Rosehill**
- Website: [danielrosehill.com](https://danielrosehill.com)
- Email: public@danielrosehill.com

---

For detailed documentation, see [CLAUDE.md](CLAUDE.md)