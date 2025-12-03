#!/usr/bin/env bash
set -e

CHARTS_DIR="charts"
ALLOWED_BRANCH="main"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "$ALLOWED_BRANCH" ]; then
  echo "❌ Current branch is '$CURRENT_BRANCH'. Only '$ALLOWED_BRANCH' branch is allowed to release charts."
  exit 1
fi

for chart in $CHARTS_DIR/*; do
  [ -d "$chart" ] || continue

  NAME=$(basename "$chart")
  HAS_CHANGES=$(git diff --name-only HEAD~1 HEAD -- "$chart" | wc -l)

  # Get version from Chart.yaml
  VERSION=$(grep "^version:" "$chart/Chart.yaml" | awk '{print $2}')
  MAJOR="v$(echo "$VERSION" | cut -d. -f1)"

  TAG_VERSION="chart-$NAME@$VERSION"
  TAG_MAJOR="chart-$NAME@$MAJOR"

  echo "📦 Processing chart: $NAME"
  echo "   → version: $VERSION"
  echo "   → major: $MAJOR"

  # Create tags only if they don't exist
  if git rev-parse "$TAG_VERSION" >/dev/null 2>&1; then
    echo "⚠️  Tag $TAG_VERSION already exists — skipping"
  else
    echo "🏷  Creating tag $TAG_VERSION"
    git tag "$TAG_VERSION"
  fi
  
  TAG_MAJOR_EXISTS=$(git rev-parse "$TAG_MAJOR" >/dev/null 2>&1 && echo "yes" || echo "no")
  
  if [ "$TAG_MAJOR_EXISTS" = "yes" ]; then
    if [ "$HAS_CHANGES" -eq 0 ]; then
      echo "⚠️  No changes detected for $NAME — skipping major tag update"
      continue
    fi

    echo "⚠️  Tag $TAG_MAJOR already exists — updating to this commit"
    git tag -f "$TAG_MAJOR"
    git push -f origin "$TAG_MAJOR"
  else
    echo "🏷  Creating tag $TAG_MAJOR"
    git tag "$TAG_MAJOR"
  fi
done

git push origin --tags
echo "🚀 Finished!"
