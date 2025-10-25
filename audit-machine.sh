#!/bin/bash

# Machine Audit Wrapper Script for Claude Code Security Auditor
# This script runs security audits on registered machines

set -e

REPO_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACHINES_DIR="$REPO_BASE/machines"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    cat << EOF
Usage: $0 <machine_name> [options]

Options:
  --quick           Run quick security check only
  --full            Run comprehensive security audit (default)
  --report-only     Generate report from previous audit data
  --help            Show this help message

Examples:
  $0 my_server                    # Run full audit on my_server
  $0 my_server --quick            # Run quick check on my_server
  $0 my_server --report-only      # Generate report without re-auditing

EOF
}

# Parse arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Machine name required${NC}"
    show_usage
    exit 1
fi

MACHINE_NAME="$1"
shift

AUDIT_TYPE="full"
REPORT_ONLY=false

while [ $# -gt 0 ]; do
    case "$1" in
        --quick)
            AUDIT_TYPE="quick"
            shift
            ;;
        --full)
            AUDIT_TYPE="full"
            shift
            ;;
        --report-only)
            REPORT_ONLY=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

MACHINE_DIR="$MACHINES_DIR/$MACHINE_NAME"

# Verify machine exists
if [ ! -d "$MACHINE_DIR" ]; then
    echo -e "${RED}Error: Machine '$MACHINE_NAME' not found${NC}"
    echo ""
    echo "Available machines:"
    ls -1 "$MACHINES_DIR" 2>/dev/null || echo "  (none)"
    echo ""
    echo "Run './add-machine.sh' to add a new machine"
    exit 1
fi

# Load machine profile
if [ ! -f "$MACHINE_DIR/user-responses.json" ]; then
    echo -e "${RED}Error: Machine profile not found${NC}"
    exit 1
fi

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Claude Code Security Audit - $MACHINE_NAME"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Load machine configuration
eval "$(python3 -c "
import json
with open('$MACHINE_DIR/user-responses.json') as f:
    data = json.load(f)
    print(f'BASH_ALIAS=\"{data.get(\"bash_alias\", \"\")}\"')
    print(f'LOCAL_IP=\"{data.get(\"local_ip\", \"\")}\"')
    print(f'HAS_ROOT_ACCESS={\"true\" if data.get(\"has_root_access\") else \"false\"}')
    print(f'CLAUDE_INSTALLED={\"true\" if data.get(\"claude_installed\") else \"false\"}')
    print(f'OS_TYPE=\"{data.get(\"os_type\", \"\")}\"')
    print(f'DESCRIPTION=\"{data.get(\"description\", \"\")}\"')
")"

echo -e "${BLUE}Machine Profile:${NC}"
echo "  Name: $MACHINE_NAME"
echo "  Description: $DESCRIPTION"
echo "  OS: $OS_TYPE"
echo "  IP: $LOCAL_IP"
[ -n "$BASH_ALIAS" ] && echo "  SSH Alias: $BASH_ALIAS"
echo ""

# Verify SSH connectivity
if [ -z "$BASH_ALIAS" ]; then
    echo -e "${RED}Error: No SSH alias configured for this machine${NC}"
    echo "Please run: ./add-machine.sh --edit $MACHINE_NAME"
    exit 1
fi

echo -e "${BLUE}Testing SSH connection...${NC}"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$BASH_ALIAS" "echo 'Connection OK'" &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to $BASH_ALIAS${NC}"
    echo ""
    echo "Please verify:"
    echo "  - SSH alias '$BASH_ALIAS' is configured"
    echo "  - Machine is reachable at $LOCAL_IP"
    echo "  - SSH key authentication is set up"
    exit 1
fi
echo -e "${GREEN}✓ Connection successful${NC}"
echo ""

# Generate timestamp for this audit
AUDIT_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$MACHINE_DIR/reports/$AUDIT_TIMESTAMP"

if [ "$REPORT_ONLY" = false ]; then
    mkdir -p "$REPORT_DIR"

    echo -e "${YELLOW}Starting security audit (${AUDIT_TYPE})...${NC}"
    echo ""

    # Create audit task file on remote
    AUDIT_TASK=$(cat << 'EOFTASK'
# Security Audit Task

## Objective
Perform a security audit on this machine to ensure security best practices are followed.

## Audit Checklist

### 1. Antivirus & Malware Protection
- [ ] Check if antivirus is installed
- [ ] Verify antivirus is running
- [ ] Check automatic definition updates are enabled
- [ ] Review recent scan logs

### 2. Rootkit Detection
- [ ] Check if rootkit detection tools are installed (chkrootkit, rkhunter, etc.)
- [ ] Verify tools run automatically/periodically
- [ ] Review recent scan results

### 3. System Updates
- [ ] Check system update status
- [ ] Verify automatic updates are configured
- [ ] List any pending security updates

### 4. File Permissions
- [ ] Audit critical system file permissions
- [ ] Check for world-writable files
- [ ] Review SUID/SGID binaries
- [ ] Identify files with unsafe permissions

### 5. User Accounts & Authentication
- [ ] List user accounts
- [ ] Check for accounts without passwords
- [ ] Review sudo configuration
- [ ] Check SSH configuration security

### 6. Network Security
- [ ] List open ports and services
- [ ] Check firewall status and rules
- [ ] Review running network services
- [ ] Identify unnecessary services

### 7. Additional Security Tools
- [ ] Check for fail2ban or similar intrusion prevention
- [ ] Review system logs for suspicious activity
- [ ] Check for security monitoring tools

## Output Requirements

For each section, provide:
1. Current status (installed/not installed, enabled/disabled)
2. Findings (issues discovered)
3. Recommendations (suggested fixes)

Use clear formatting and highlight any critical issues.
EOFTASK
)

    # Check if Claude is installed on remote
    if [ "$CLAUDE_INSTALLED" = "true" ]; then
        echo -e "${BLUE}Using Claude Code on remote machine...${NC}"

        # Create temporary task file
        TMP_TASK="/tmp/audit-task-$AUDIT_TIMESTAMP.md"
        echo "$AUDIT_TASK" | ssh "$BASH_ALIAS" "cat > $TMP_TASK"

        # Run Claude Code audit
        if [ "$AUDIT_TYPE" = "quick" ]; then
            ssh "$BASH_ALIAS" "cd ~ && claude --task '$TMP_TASK' --output /tmp/audit-report-$AUDIT_TIMESTAMP.md --quick"
        else
            ssh "$BASH_ALIAS" "cd ~ && claude --task '$TMP_TASK' --output /tmp/audit-report-$AUDIT_TIMESTAMP.md"
        fi

        # Retrieve report
        scp "$BASH_ALIAS:/tmp/audit-report-$AUDIT_TIMESTAMP.md" "$REPORT_DIR/audit-report.md"

        # Cleanup
        ssh "$BASH_ALIAS" "rm -f $TMP_TASK /tmp/audit-report-$AUDIT_TIMESTAMP.md"

        echo -e "${GREEN}✓ Audit completed via Claude Code${NC}"
    else
        echo -e "${YELLOW}Claude Code not available, running manual audit...${NC}"

        # Run manual audit commands
        AUDIT_SCRIPT=$(cat << 'EOFSCRIPT'
#!/bin/bash

echo "# Security Audit Report"
echo "Generated: $(date)"
echo ""

echo "## 1. Antivirus & Malware Protection"
if command -v clamav &>/dev/null; then
    echo "- ClamAV: Installed"
    systemctl is-active clamav-freshclam &>/dev/null && echo "  Status: Active" || echo "  Status: Inactive"
else
    echo "- ClamAV: Not installed"
fi
echo ""

echo "## 2. Rootkit Detection"
if command -v rkhunter &>/dev/null; then
    echo "- rkhunter: Installed"
else
    echo "- rkhunter: Not installed"
fi
if command -v chkrootkit &>/dev/null; then
    echo "- chkrootkit: Installed"
else
    echo "- chkrootkit: Not installed"
fi
echo ""

echo "## 3. System Updates"
if command -v apt &>/dev/null; then
    echo "- Package manager: apt"
    apt list --upgradable 2>/dev/null | tail -n +2 | head -10
elif command -v dnf &>/dev/null; then
    echo "- Package manager: dnf"
    dnf check-update 2>/dev/null | head -10
fi
echo ""

echo "## 4. File Permissions"
echo "### World-writable files (sample):"
find / -xdev -type f -perm -0002 2>/dev/null | head -10
echo ""
echo "### SUID binaries (sample):"
find / -xdev -type f -perm -4000 2>/dev/null | head -20
echo ""

echo "## 5. User Accounts"
echo "### User accounts:"
cat /etc/passwd | grep -v nologin | grep -v false
echo ""

echo "## 6. Network Security"
echo "### Open ports:"
ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null
echo ""
echo "### Firewall status:"
if command -v ufw &>/dev/null; then
    ufw status
elif command -v firewall-cmd &>/dev/null; then
    firewall-cmd --list-all
else
    echo "No firewall detected"
fi
echo ""

echo "## 7. Additional Security"
if command -v fail2ban-client &>/dev/null; then
    echo "- fail2ban: Installed"
    fail2ban-client status 2>/dev/null
else
    echo "- fail2ban: Not installed"
fi
EOFSCRIPT
)

        echo "$AUDIT_SCRIPT" | ssh "$BASH_ALIAS" "bash" > "$REPORT_DIR/audit-report.md" 2>&1

        echo -e "${GREEN}✓ Manual audit completed${NC}"
    fi

    # Update audit log
    python3 << EOFPYTHON
import json
from datetime import datetime

with open('$MACHINE_DIR/audit-log.json', 'r+') as f:
    data = json.load(f)
    data['events'].append({
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'event_type': 'audit_completed',
        'description': 'Security audit completed',
        'audit_type': '$AUDIT_TYPE',
        'report_path': 'reports/$AUDIT_TIMESTAMP/audit-report.md'
    })
    f.seek(0)
    json.dump(data, f, indent=2)
    f.truncate()

# Update claude-profile.json
with open('$MACHINE_DIR/claude-profile.json', 'r+') as f:
    data = json.load(f)
    data['audit']['status'] = 'completed'
    data['audit']['last_audit'] = datetime.utcnow().isoformat() + 'Z'
    data['metadata']['updated_at'] = datetime.utcnow().isoformat() + 'Z'
    f.seek(0)
    json.dump(data, f, indent=2)
    f.truncate()
EOFPYTHON

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            Audit Complete!                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Report saved to:${NC}"
    echo "  $REPORT_DIR/audit-report.md"
    echo ""
    echo -e "${BLUE}View report:${NC}"
    echo "  cat $REPORT_DIR/audit-report.md"
    echo "  or"
    echo "  code $REPORT_DIR/audit-report.md"
else
    echo -e "${YELLOW}Report-only mode: Generating summary from existing audits${NC}"
    # TODO: Implement report generation from audit history
fi

echo ""
