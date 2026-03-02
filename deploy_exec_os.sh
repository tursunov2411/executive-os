#!/bin/bash
# ================================================
# EXECUTIVE OS — One-Command Full Stack Deployment
# ================================================
# 1. Deploy FastAPI backend (Railway)
# 2. Update frontend .env.local with backend URL
# 3. Deploy Next.js frontend (Vercel)
# 4. Update iOS APIService.swift with backend URL
# 5. Optionally commit and push URL changes
# ================================================
# Prerequisites: railway CLI, vercel CLI, git
#   npm install -g railway vercel
#   railway login && vercel login
# ================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
IOS_DIR="$SCRIPT_DIR/ios-companion"
IOS_API_FILE="$IOS_DIR/APIService.swift"

# --------------------------
# Config (override via env)
# --------------------------
RAILWAY_PROJECT="${RAILWAY_PROJECT:-executive-os-backend}"
VERCEL_PROJECT="${VERCEL_PROJECT:-executive-os}"
SKIP_BACKEND="${SKIP_BACKEND:-}"
SKIP_FRONTEND="${SKIP_FRONTEND:-}"
SKIP_IOS="${SKIP_IOS:-}"
COMMIT_CHANGES="${COMMIT_CHANGES:-}"

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --skip-backend)  SKIP_BACKEND=1 ;;
    --skip-frontend) SKIP_FRONTEND=1 ;;
    --skip-ios)      SKIP_IOS=1 ;;
    --commit)        COMMIT_CHANGES=1 ;;
    --help)
      echo "Usage: $0 [--skip-backend] [--skip-frontend] [--skip-ios] [--commit]"
      echo "  --skip-backend   Skip Railway backend deploy"
      echo "  --skip-frontend  Skip Vercel frontend deploy"
      echo "  --skip-ios       Skip iOS APIService.swift URL update"
      echo "  --commit         Commit and push .env.local + APIService.swift changes"
      echo "Env: BACKEND_URL (override detected URL), RAILWAY_PROJECT, VERCEL_PROJECT"
      exit 0
      ;;
  esac
done

echo ""
echo " ============================================="
echo "  EXECUTIVE OS — DEPLOYMENT"
echo " ============================================="
echo ""

# --------------------------
# 1. Deploy Backend (Railway)
# --------------------------
if [ -z "$SKIP_BACKEND" ]; then
  echo "🚀 [1/5] Deploying FastAPI backend (Railway)..."
  cd "$BACKEND_DIR"
  railway up --yes || railway up
  # Try to get live URL (Railway CLI output varies)
  if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL=$(railway status 2>/dev/null | grep -oE 'https?://[^ ]+' | head -n 1) || true
  fi
  if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL=$(railway domain 2>/dev/null | head -n 1) || true
  fi
  if [ -z "$BACKEND_URL" ]; then
    echo "⚠️  Could not auto-detect backend URL. Set BACKEND_URL and re-run, or check Railway dashboard."
    read -p "Enter backend URL (e.g. https://xxx.railway.app): " BACKEND_URL
  fi
  # Ensure no trailing slash
  BACKEND_URL="${BACKEND_URL%/}"
  echo "✅ Backend deployed at $BACKEND_URL"
else
  if [ -z "$BACKEND_URL" ]; then
    echo "⚠️  SKIP_BACKEND set but BACKEND_URL not set. Using existing frontend .env.local or prompt."
    if [ -f "$FRONTEND_DIR/.env.local" ]; then
      BACKEND_URL=$(grep NEXT_PUBLIC_BACKEND_URL "$FRONTEND_DIR/.env.local" | cut -d= -f2- | tr -d '"' | tr -d "'")
    fi
    if [ -z "$BACKEND_URL" ]; then
      read -p "Enter backend URL: " BACKEND_URL
    fi
  fi
  echo "⏭️  [1/5] Backend deploy skipped (using BACKEND_URL=$BACKEND_URL)"
fi

# --------------------------
# 2. Update Frontend .env.local
# --------------------------
echo ""
echo "📝 [2/5] Updating frontend .env.local..."
mkdir -p "$FRONTEND_DIR"
echo "NEXT_PUBLIC_BACKEND_URL=$BACKEND_URL" > "$FRONTEND_DIR/.env.local"
echo "✅ Frontend .env.local updated"

# --------------------------
# 3. Deploy Frontend (Vercel)
# --------------------------
if [ -z "$SKIP_FRONTEND" ]; then
  echo ""
  echo "🚀 [3/5] Deploying Next.js frontend (Vercel)..."
  cd "$FRONTEND_DIR"
  vercel --prod --yes 2>/dev/null || vercel --prod --confirm
  echo "✅ Frontend deployed to Vercel"
else
  echo ""
  echo "⏭️  [3/5] Frontend deploy skipped"
fi

# --------------------------
# 4. Update iOS APIService.swift
# --------------------------
if [ -z "$SKIP_IOS" ] && [ -f "$IOS_API_FILE" ]; then
  echo ""
  echo "📝 [4/5] Updating iOS APIService.swift baseURL..."
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i.bak "s|baseURL = \".*\"|baseURL = \"$BACKEND_URL\"|" "$IOS_API_FILE"
  else
    sed -i '.bak' "s|baseURL = \".*\"|baseURL = \"$BACKEND_URL\"|" "$IOS_API_FILE"
  fi
  rm -f "$IOS_API_FILE.bak"
  echo "✅ iOS APIService.swift updated with $BACKEND_URL"
elif [ -z "$SKIP_IOS" ] && [ ! -f "$IOS_API_FILE" ]; then
  echo ""
  echo "⚠️  [4/5] APIService.swift not found at $IOS_API_FILE"
else
  echo ""
  echo "⏭️  [4/5] iOS update skipped"
fi

# --------------------------
# 5. Optional: Commit and push
# --------------------------
echo ""
if [ -n "$COMMIT_CHANGES" ]; then
  echo "📤 [5/5] Committing and pushing URL updates..."
  cd "$SCRIPT_DIR"
  git add "$FRONTEND_DIR/.env.local" "$IOS_API_FILE" 2>/dev/null || true
  if git diff --staged --quiet 2>/dev/null; then
    echo "   No changes to commit."
  else
    git commit -m "chore: update frontend and iOS backend URLs for deployment"
    git push origin main
    echo "✅ Changes pushed to GitHub"
  fi
else
  echo "⏭️  [5/5] Commit skipped (use --commit to commit and push)"
fi

echo ""
echo " ============================================="
echo "  🎉 EXECUTIVE OS DEPLOYMENT COMPLETE"
echo " ============================================="
echo "  Backend:  $BACKEND_URL"
echo "  Frontend: (see Vercel dashboard or 'vercel ls')"
echo " ============================================="
echo ""
