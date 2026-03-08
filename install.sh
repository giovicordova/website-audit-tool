#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/giovicordova/website-audit-tool.git"
INSTALL_DIR="${HOME}/.claude/skills/website-audit"
SKILLS_DIR="${HOME}/.claude/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}OK${NC}  $1"; }
warn() { echo -e "  ${YELLOW}!!${NC}  $1"; }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; }

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: install.sh [--local]"
  echo ""
  echo "Installs the website-audit skill for Claude Code."
  echo ""
  echo "Options:"
  echo "  --local   Symlink the current directory instead of cloning from GitHub."
  echo "            Use this if you already cloned the repo."
  echo "  --help    Show this help message."
  echo ""
  echo "What it does:"
  echo "  1. Checks dependencies (Node.js 22+, Lighthouse, Python 3, Playwright CLI)"
  echo "  2. Clones the repo (or symlinks current dir with --local)"
  echo "  3. Creates a symlink at ~/.claude/skills/website-audit"
  echo ""
  echo "After install, use in Claude Code: /website-audit https://example.com"
  exit 0
fi

LOCAL_MODE=false
if [[ "${1:-}" == "--local" ]]; then
  LOCAL_MODE=true
fi

echo ""
echo "Website Audit Skill — Installer"
echo "================================"
echo ""

# Check dependencies
echo "Checking dependencies..."
DEPS_OK=true

# Node.js 22+
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_VERSION" -ge 22 ]]; then
    pass "Node.js v$(node --version | sed 's/v//')"
  else
    warn "Node.js v$(node --version | sed 's/v//') found — v22+ recommended for Lighthouse"
  fi
else
  fail "Node.js not found — required for Lighthouse"
  DEPS_OK=false
fi

# Lighthouse
if npx lighthouse --version &>/dev/null 2>&1; then
  pass "Lighthouse $(npx lighthouse --version 2>/dev/null)"
else
  warn "Lighthouse not found — will be auto-installed on first audit via npx"
fi

# Python 3
if command -v python3 &>/dev/null; then
  pass "Python 3 ($(python3 --version 2>&1 | cut -d' ' -f2))"
else
  fail "Python 3 not found — required for scoring engine"
  DEPS_OK=false
fi

# Playwright CLI
if npx @anthropic-ai/claude-code-playwright --help &>/dev/null 2>&1 || npx playwright --version &>/dev/null 2>&1; then
  pass "Playwright CLI available"
else
  warn "Playwright CLI not detected"
  echo "       The skill needs Playwright CLI for headless page crawling."
  echo "       Install: npm install -g @anthropic-ai/claude-code-playwright"
fi

echo ""

if ! $DEPS_OK; then
  fail "Missing required dependencies. Install them and re-run."
  exit 1
fi

# Install
if [[ -L "$INSTALL_DIR" ]]; then
  CURRENT_TARGET=$(readlink "$INSTALL_DIR")
  echo "Skill already installed (symlink -> $CURRENT_TARGET)"
  echo ""
  read -p "Update symlink? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipped. Existing installation unchanged."
    exit 0
  fi
  rm "$INSTALL_DIR"
elif [[ -d "$INSTALL_DIR" ]]; then
  echo "Directory exists at $INSTALL_DIR (not a symlink)."
  echo "Remove it manually if you want to reinstall."
  exit 1
fi

mkdir -p "$SKILLS_DIR"

if $LOCAL_MODE; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ln -s "$SOURCE_DIR" "$INSTALL_DIR"
  pass "Symlinked $SOURCE_DIR -> $INSTALL_DIR"
else
  CLONE_DIR="${HOME}/.claude/skills/.website-audit-repo"
  if [[ -d "$CLONE_DIR" ]]; then
    echo "Updating existing clone..."
    git -C "$CLONE_DIR" pull --quiet
  else
    echo "Cloning repository..."
    git clone --quiet "$REPO_URL" "$CLONE_DIR"
  fi
  ln -s "$CLONE_DIR" "$INSTALL_DIR"
  pass "Cloned and symlinked to $INSTALL_DIR"
fi

echo ""
echo "================================"
echo "Installation complete!"
echo ""
echo "Try it in Claude Code:"
echo "  /website-audit https://example.com"
echo ""
