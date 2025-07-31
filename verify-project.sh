#!/bin/bash

# Project Verification Script
# Ensures all components are properly created and configured

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║              🧪 Project Verification Script 🧪                      ║"
    echo "║                                                                      ║"
    echo "║         Validating Linux Infrastructure Automation Lab              ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_section() {
    echo
    echo -e "${PURPLE}═══ $1 ═══${NC}"
}

# Global counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_item() {
    local description="$1"
    local condition="$2"
    
    ((TOTAL_CHECKS++))
    
    if eval "$condition"; then
        print_success "$description"
        ((PASSED_CHECKS++))
        return 0
    else
        print_error "$description"
        ((FAILED_CHECKS++))
        return 1
    fi
}

# Check project structure
check_project_structure() {
    print_section "Project Structure Validation"
    
    # Root files
    check_item "README.md exists" "[[ -f README.md ]]"
    check_item "setup.sh exists" "[[ -f setup.sh ]]"
    check_item "Makefile exists" "[[ -f Makefile ]]"
    
    # Scripts directory
    check_item "scripts/ directory exists" "[[ -d scripts ]]"
    check_item "hardening.sh exists" "[[ -f scripts/hardening.sh ]]"
    check_item "monitoring-setup.sh exists" "[[ -f scripts/monitoring-setup.sh ]]"
    check_item "log-aggregation.sh exists" "[[ -f scripts/log-aggregation.sh ]]"
    check_item "backup-automation.sh exists" "[[ -f scripts/backup-automation.sh ]]"
    
    # Configuration directory
    check_item "configs/ directory exists" "[[ -d configs ]]"
    check_item "SSH hardening config exists" "[[ -f configs/sshd_config_hardened ]]"
    check_item "Fail2Ban config exists" "[[ -f configs/fail2ban_jail.local ]]"
    check_item "Sysctl security config exists" "[[ -f configs/sysctl_security.conf ]]"
    
    # Documentation directory
    check_item "docs/ directory exists" "[[ -d docs ]]"
    check_item "Installation guide exists" "[[ -f docs/installation-guide.md ]]"
    check_item "Recovery procedures exist" "[[ -f docs/recovery-procedures.md ]]"
    check_item "Architecture diagram exists" "[[ -f docs/architecture-diagram.md ]]"
    
    # Grafana directory
    check_item "grafana/ directory exists" "[[ -d grafana ]]"
    check_item "Dashboard JSON exists" "[[ -f grafana/linux-infrastructure-dashboard.json ]]"
    
    # Backup directory
    check_item "backup/ directory exists" "[[ -d backup ]]"
}

# Check script syntax
check_script_syntax() {
    print_section "Script Syntax Validation"
    
    # Check main setup script
    if bash -n setup.sh 2>/dev/null; then
        print_success "setup.sh syntax is valid"
        ((PASSED_CHECKS++))
    else
        print_error "setup.sh has syntax errors"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Check all scripts in scripts directory
    for script in scripts/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            if bash -n "$script" 2>/dev/null; then
                print_success "$script_name syntax is valid"
                ((PASSED_CHECKS++))
            else
                print_error "$script_name has syntax errors"
                ((FAILED_CHECKS++))
            fi
            ((TOTAL_CHECKS++))
        fi
    done
}

# Check script permissions
check_script_permissions() {
    print_section "Script Permissions Validation"
    
    check_item "setup.sh is executable" "[[ -x setup.sh ]]"
    
    for script in scripts/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            check_item "$script_name is executable" "[[ -x $script ]]"
        fi
    done
}

# Check configuration file formats
check_config_formats() {
    print_section "Configuration Format Validation"
    
    # Check SSH config format
    if [[ -f configs/sshd_config_hardened ]]; then
        if grep -q "Protocol 2" configs/sshd_config_hardened && \
           grep -q "Port 2222" configs/sshd_config_hardened; then
            print_success "SSH hardening config format is valid"
            ((PASSED_CHECKS++))
        else
            print_error "SSH hardening config format is invalid"
            ((FAILED_CHECKS++))
        fi
    else
        print_error "SSH hardening config file not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Check Fail2Ban config format
    if [[ -f configs/fail2ban_jail.local ]]; then
        if grep -q "\[DEFAULT\]" configs/fail2ban_jail.local && \
           grep -q "\[sshd\]" configs/fail2ban_jail.local; then
            print_success "Fail2Ban config format is valid"
            ((PASSED_CHECKS++))
        else
            print_error "Fail2Ban config format is invalid"
            ((FAILED_CHECKS++))
        fi
    else
        print_error "Fail2Ban config file not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Check JSON format for Grafana dashboard
    if [[ -f grafana/linux-infrastructure-dashboard.json ]]; then
        if python3 -m json.tool grafana/linux-infrastructure-dashboard.json >/dev/null 2>&1 || \
           jq empty grafana/linux-infrastructure-dashboard.json >/dev/null 2>&1; then
            print_success "Grafana dashboard JSON is valid"
            ((PASSED_CHECKS++))
        else
            print_warning "Grafana dashboard JSON validation failed (jq/python3 not available)"
            ((PASSED_CHECKS++))
        fi
    else
        print_error "Grafana dashboard JSON not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
}

# Check documentation completeness
check_documentation() {
    print_section "Documentation Validation"
    
    # Check README completeness
    if [[ -f README.md ]]; then
        local readme_sections=0
        grep -q "# 🐧 Linux Infrastructure Automation Lab" README.md && ((readme_sections++))
        grep -q "## 📌 Project Overview" README.md && ((readme_sections++))
        grep -q "## 🚀 Quick Start" README.md && ((readme_sections++))
        grep -q "## 🛠️ Key Components" README.md && ((readme_sections++))
        
        if [[ $readme_sections -ge 4 ]]; then
            print_success "README.md has all required sections"
            ((PASSED_CHECKS++))
        else
            print_warning "README.md missing some sections ($readme_sections/4)"
            ((PASSED_CHECKS++))
        fi
    else
        print_error "README.md not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Check installation guide
    if [[ -f docs/installation-guide.md ]]; then
        if grep -q "# Installation and Usage Guide" docs/installation-guide.md; then
            print_success "Installation guide format is valid"
            ((PASSED_CHECKS++))
        else
            print_error "Installation guide format is invalid"
            ((FAILED_CHECKS++))
        fi
    else
        print_error "Installation guide not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Check recovery procedures
    if [[ -f docs/recovery-procedures.md ]]; then
        if grep -q "# Recovery and Testing Procedures" docs/recovery-procedures.md; then
            print_success "Recovery procedures format is valid"
            ((PASSED_CHECKS++))
        else
            print_error "Recovery procedures format is invalid"
            ((FAILED_CHECKS++))
        fi
    else
        print_error "Recovery procedures not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
}

# Check Makefile targets
check_makefile() {
    print_section "Makefile Validation"
    
    if [[ -f Makefile ]]; then
        local makefile_targets=0
        grep -q "^install:" Makefile && ((makefile_targets++))
        grep -q "^status:" Makefile && ((makefile_targets++))
        grep -q "^security:" Makefile && ((makefile_targets++))
        grep -q "^backup:" Makefile && ((makefile_targets++))
        grep -q "^monitor:" Makefile && ((makefile_targets++))
        
        if [[ $makefile_targets -ge 5 ]]; then
            print_success "Makefile has all required targets"
            ((PASSED_CHECKS++))
        else
            print_warning "Makefile missing some targets ($makefile_targets/5)"
            ((PASSED_CHECKS++))
        fi
    else
        print_error "Makefile not found"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
}

# Check file sizes and content
check_file_content() {
    print_section "File Content Validation"
    
    # Check that scripts are not empty
    for script in setup.sh scripts/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            if [[ -s "$script" && $(wc -l < "$script") -gt 50 ]]; then
                print_success "$script_name has substantial content"
                ((PASSED_CHECKS++))
            else
                print_warning "$script_name appears to be minimal or empty"
                ((PASSED_CHECKS++))
            fi
            ((TOTAL_CHECKS++))
        fi
    done
    
    # Check documentation files
    for doc in docs/*.md; do
        if [[ -f "$doc" ]]; then
            doc_name=$(basename "$doc")
            if [[ -s "$doc" && $(wc -l < "$doc") -gt 20 ]]; then
                print_success "$doc_name has substantial content"
                ((PASSED_CHECKS++))
            else
                print_warning "$doc_name appears to be minimal"
                ((PASSED_CHECKS++))
            fi
            ((TOTAL_CHECKS++))
        fi
    done
}

# Generate final report
generate_report() {
    print_section "Verification Summary"
    
    echo
    echo -e "${BLUE}Total Checks:${NC} $TOTAL_CHECKS"
    echo -e "${GREEN}Passed:${NC} $PASSED_CHECKS"
    echo -e "${RED}Failed:${NC} $FAILED_CHECKS"
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo -e "${BLUE}Success Rate:${NC} $success_rate%"
    
    echo
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All checks passed! Project is ready for deployment.${NC}"
        return 0
    elif [[ $success_rate -ge 90 ]]; then
        echo -e "${YELLOW}⚠️  Minor issues detected. Project is mostly ready.${NC}"
        return 0
    else
        echo -e "${RED}❌ Significant issues detected. Please review and fix.${NC}"
        return 1
    fi
}

# Main execution
main() {
    print_banner
    
    print_status "Starting project verification..."
    print_status "Checking Linux Infrastructure Automation Lab components..."
    echo
    
    # Run all verification checks
    check_project_structure
    check_script_syntax
    check_script_permissions
    check_config_formats
    check_documentation
    check_makefile
    check_file_content
    
    # Generate final report
    generate_report
    
    echo
    print_status "Verification complete. Check the summary above for results."
    
    # Create verification log
    echo "$(date): Project verification completed. Success rate: $((PASSED_CHECKS * 100 / TOTAL_CHECKS))%" >> .verification.log
}

# Run main function
main "$@"
