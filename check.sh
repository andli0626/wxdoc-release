#!/usr/bin/env bash
# 发布页自检：零外部依赖 + 同源下载 + Pages 必要条件
set -u

cd "$(dirname "$0")"

RISK='fonts\.googleapis|fonts\.gstatic|cdn\.jsdelivr|unpkg\.com|cdnjs\.cloudflare'
RISK+='|google-analytics|googletagmanager|gtag\(|hm\.baidu'
RISK+='|raw\.githubusercontent|codeload\.github|objects\.githubusercontent'
RISK+='|releases\/download|polyfill\.io|staticfile\.org|bootcdn'

fail=0

echo "== 1. 外部依赖扫描 =="
while IFS= read -r -d '' f; do
  hits=$(grep -nEo "$RISK" "$f" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "[风险] $f"
    echo "$hits" | sed 's/^/    /'
    fail=1
  fi
done < <(find . -type f \( -name '*.html' -o -name '*.css' -o -name '*.js' \) -print0)

if [ "$fail" -eq 0 ]; then
  echo "[通过] 未发现高风险外部依赖"
else
  echo "[失败] 请移除上述引用后再发布"
fi

echo
echo "== 2. 必要文件检查 =="
for f in index.html styles.css .nojekyll; do
  if [ -e "$f" ]; then
    echo "[通过] $f"
  else
    echo "[缺失] $f"
    fail=1
  fi
done

echo
echo "== 3. 下载链接检查 =="
missing=0
while IFS= read -r href; do
  path=${href#downloads/}
  path="downloads/${path%%\?*}"
  if [ -f "$path" ]; then
    size=$(du -h "$path" | cut -f1)
    echo "[通过] $path ($size)"
  else
    echo "[缺失] $path"
    missing=1
    fail=1
  fi
done < <(grep -oE 'href="downloads/[^"]+"' index.html | sed 's/href="//; s/"$//' | sort -u)

echo
echo "== 4. 体积检查 =="
# 只统计实际站点文件，排除 .git（Pages 不托管 .git 目录）
site_bytes=$(find . -path ./.git -prune -o -type f -print0 | xargs -0 wc -c | tail -1 | awk '{print $1}')
site_mb=$((site_bytes / 1024 / 1024))
echo "整站体积：${site_mb} MB（不含 .git；GitHub Pages 上限 1 GB）"
big=$(find downloads -type f -size +100M 2>/dev/null)
if [ -n "$big" ]; then
  echo "[风险] 以下文件超过 100 MB："
  echo "$big"
  fail=1
else
  echo "[通过] 单文件均不超过 100 MB"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "== 自检通过，可以发布 =="
  exit 0
fi

echo "== 自检未通过，请按上方提示修正 =="
exit 1
