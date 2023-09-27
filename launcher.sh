#!/usr/bin/env bash

# params: <选择框提示语> <初始选中的项目> <项目1> <项目2> …
# return: 选择的项目的下标
function select_from_array() {
  local TITLE OPTS INDEX ITEM
  TITLE=$1
  shift
  local DEFAULT_ITEM=$1
  shift
  OPTS=()
  INDEX=0
  for ITEM in "$@" ; do
    (( INDEX++ )) || true
    OPTS+=("$INDEX" "$ITEM")
  done
  ITEM=$(dialog --stdout --default-item "$DEFAULT_ITEM" --menu "$TITLE" 0 0 0 "${OPTS[@]}")

  echo "$((${ITEM:-0} - 1))"
}

SELECTED_INDEX=$(select_from_array "欢迎使用Fcitx5优化脚本，请选择运行方式" 1 \
  "在线运行最新版本 - 使用推荐配置" \
  "在线运行最新版本 - 自选配置" \
  "运行已下载的版本 - 使用推荐配置" \
  "运行已下载的版本 - 自选配置" \
)

clear

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

case $SELECTED_INDEX in
0)
  curl -sSL https://www.debuggerx.com/fcitx5_customizer/fcitx5_customizer.sh | bash -s -- recommend
  ;;
1)
  bash -c "$(curl -fsSL https://www.debuggerx.com/fcitx5_customizer/fcitx5_customizer.sh)"
  ;;
2)
  bash "$CURRENT_DIR"/fcitx5_customizer.sh recommend
  ;;
3)
  bash "$CURRENT_DIR"/fcitx5_customizer.sh
  ;;
esac