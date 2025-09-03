#!/usr/bin/env bash

# Script to check and diagnose GitHub Actions scheduled workflow issues
# Usage: ./scripts/check-workflow-schedule.sh

set -euo pipefail

REPO="AodhanHayter/opencode-flake"
WORKFLOW_FILE=".github/workflows/update-opencode.yml"

echo "GitHub Actions Scheduled Workflow Diagnostic"
echo "==========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it to use this script."
    echo "   Visit: https://cli.github.com/"
    exit 1
fi

echo "✓ GitHub CLI is installed"
echo ""

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Please run: gh auth login"
    exit 1
fi

echo "✓ Authenticated with GitHub"
echo ""

# Check workflow runs
echo "📊 Recent workflow runs:"
echo "------------------------"
gh run list --workflow=update-opencode.yml --limit=5 --repo="$REPO" || echo "No recent runs found"
echo ""

# Get last successful run
LAST_RUN=$(gh run list --workflow=update-opencode.yml --limit=1 --repo="$REPO" --json createdAt,status,conclusion --jq '.[0]' 2>/dev/null || echo "{}")

if [ "$LAST_RUN" != "{}" ]; then
    CREATED_AT=$(echo "$LAST_RUN" | jq -r '.createdAt')
    STATUS=$(echo "$LAST_RUN" | jq -r '.status')
    CONCLUSION=$(echo "$LAST_RUN" | jq -r '.conclusion')
    
    echo "📅 Last run details:"
    echo "  - Date: $CREATED_AT"
    echo "  - Status: $STATUS"
    echo "  - Conclusion: $CONCLUSION"
    
    # Calculate days since last run
    if [ "$(uname)" = "Darwin" ]; then
        LAST_RUN_SECONDS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CREATED_AT" "+%s" 2>/dev/null || echo "0")
    else
        LAST_RUN_SECONDS=$(date -d "$CREATED_AT" "+%s" 2>/dev/null || echo "0")
    fi
    
    if [ "$LAST_RUN_SECONDS" != "0" ]; then
        CURRENT_SECONDS=$(date "+%s")
        DAYS_AGO=$(( (CURRENT_SECONDS - LAST_RUN_SECONDS) / 86400 ))
        
        echo "  - Days since last run: $DAYS_AGO"
        
        if [ "$DAYS_AGO" -gt 60 ]; then
            echo ""
            echo "⚠️  WARNING: Last run was more than 60 days ago!"
            echo "   GitHub disables scheduled workflows after 60 days of inactivity."
            echo "   To reactivate:"
            echo "   1. Make any commit to the repository, or"
            echo "   2. Manually trigger the workflow"
        fi
    fi
else
    echo "⚠️  No workflow runs found. The workflow may never have run."
    echo ""
    echo "To activate the scheduled workflow:"
    echo "1. Ensure the workflow file is on the default branch (master/main)"
    echo "2. Manually trigger it once: gh workflow run update-opencode-nix.yml --repo=$REPO"
fi

echo ""
echo "📝 Workflow schedule configuration:"
echo "-----------------------------------"
grep -A 2 "schedule:" "$WORKFLOW_FILE" | sed 's/^/  /'

echo ""
echo "🔧 Quick Actions:"
echo "-----------------"
echo "1. Manually trigger workflow:"
echo "   gh workflow run update-opencode.yml --repo=$REPO"
echo ""
echo "2. View workflow in browser:"
echo "   gh workflow view update-opencode.yml --web --repo=$REPO"
echo ""
echo "3. Check GitHub Actions status:"
echo "   https://www.githubstatus.com/history"
echo ""
echo "4. If workflow fails due to hash mismatch:"
echo "   - Check the workflow logs for the correct vendorHash"
echo "   - Update package.nix with the new hash manually"
echo "   - This is normal when Go module dependencies change between versions"
echo ""

# Check repository activity
echo "📊 Repository activity check:"
echo "-----------------------------"
LAST_COMMIT=$(git log -1 --format="%ai" 2>/dev/null || echo "unknown")
echo "  Last commit: $LAST_COMMIT"

if [ "$LAST_COMMIT" != "unknown" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        LAST_COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d' ' -f1)
        LAST_COMMIT_SECONDS=$(date -j -f "%Y-%m-%d" "$LAST_COMMIT_DATE" "+%s" 2>/dev/null || echo "0")
    else
        LAST_COMMIT_SECONDS=$(date -d "$LAST_COMMIT" "+%s" 2>/dev/null || echo "0")
    fi
    
    if [ "$LAST_COMMIT_SECONDS" != "0" ]; then
        CURRENT_SECONDS=$(date "+%s")
        DAYS_SINCE_COMMIT=$(( (CURRENT_SECONDS - LAST_COMMIT_SECONDS) / 86400 ))
        echo "  Days since last commit: $DAYS_SINCE_COMMIT"
        
        if [ "$DAYS_SINCE_COMMIT" -gt 50 ]; then
            echo ""
            echo "⚠️  WARNING: Approaching 60-day inactivity limit!"
            echo "   Make a commit soon to prevent workflow deactivation."
        fi
    fi
fi

echo ""
echo "✅ Diagnostic complete!"