#!/usr/bin/env bash

BASE_URL="https://www.debuggerx.com/fcitx5_customizer/"

SELECTED_SKIN=''

function select_skin {
  local THEMES SKIN OPTS ITEMS THEME INDEX
  THEMES=()
  THEMES+=("$(ls ~/.local/share/fcitx5/themes/)")
  THEMES+=("$(ls /usr/share/fcitx5/themes/)")
  OPTS=()
  ITEMS=()
  INDEX=0
  for THEME in $(echo "${THEMES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ') ; do
    (( INDEX++ )) || true
    OPTS+=("$INDEX" "$THEME")
    ITEMS+=("$THEME")
  done
  SKIN=$(dialog --stdout --menu "请选择想要应用的皮肤后回车" 0 0 0 "${OPTS[@]}")

  clear

  if [ ${#SKIN} == 0 ]; then
    echo '未选择皮肤'
  else
    SELECTED_SKIN=${ITEMS[$SKIN-1]}
    echo "选择了[${ITEMS[$SKIN-1]}]皮肤"
  fi
}

# params: <key> <value> <配置文件路径>
function change_config() {
  if [ -f "$3" ] &&  < "$3" grep -q "$1" ; then
    sed -i "s/$1.*/$1=$2/" "$3"
  else
    echo "$1=$2" >> "$3"
  fi
}

# params: <zip包名> <中文名> <解压路径>
function download_and_unzip() {
  echo "开始下载$2[$BASE_URL$1]"
  curl -o /tmp/"$1" "$BASE_URL$1"
  if [ -f /tmp/"$1" ]; then
    echo "$2下载成功"
  fi
  mkdir -p "$3"
  unzip -q /tmp/"$1" -d "$3"
  echo "$2安装成功"
}

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

# 检查软件包是否已安装
# params: <检查的包名>
# return: 0-已安装 1-未安装
function check_installed() {
  local RES
  RES="$(dpkg-query -W -f='${Status}' "$1")"
  if [ "$RES" == "install ok installed" ]; then
    return 0
  fi
  return 1
}

# 检查包，未安装则执行安装
# params: <包名> <包的中文名>
function check_and_install() {
  if check_installed "$1"; then
    echo "$2已安装"
  else
    echo "安装$2"
    sudo apt install "$1"
  fi
}

# 配置云拼音
function config_cloudpinyin() {
  change_config 'CloudPinyinEnabled' 'True' ~/.config/fcitx5/conf/pinyin.conf
  cat << EOF > ~/.config/fcitx5/conf/cloudpinyin.conf
# 最小拼音长度
MinimumPinyinLength=2
# 后端
Backend=Baidu
# 代理
Proxy=

[Toggle Key]
0=Control+Alt+Shift+C

EOF
}


FLAGS=()
for i in {0..22}
do
  FLAGS+=('off')
done

if [ "$1" == "recommend" ]; then
  FLAGS[0]='on'
  FLAGS[1]='on'
  FLAGS[2]='on'
  FLAGS[3]='on'
  FLAGS[6]='on'
  FLAGS[8]='on'
  FLAGS[10]='on'
  FLAGS[11]='on'
  FLAGS[12]='on'
  FLAGS[13]='on'
fi

# 弹出主选框
OPTIONS=$(dialog --stdout --checklist "请使用上下方向键移动选项，空格键勾选，回车键确认" 0 0 0 \
安装搜狗词库 从仓库中安装搜狗词库 "${FLAGS[0]}" \
导入中文维基词库 导入中文维基词库20230605版 "${FLAGS[1]}" \
导入精选搜狗细胞词库 导入部分来自搜狗的精选细胞词库 "${FLAGS[2]}" \
开启云拼音 基于百度的云拼音，默认在第二个候选词位置 "${FLAGS[3]}" \
竖排显示 不勾选则为横向显示候选词 "${FLAGS[4]}" \
修改候选词数量 进入候选词数量选择页面 "${FLAGS[5]}" \
修改字体大小 进入输入法字体大小选择页面 "${FLAGS[6]}" \
修改默认加减号翻页 快速输入时生效，默认为上下方向键 "${FLAGS[7]}" \
关闭预编辑 关闭在程序中显示输入中的拼音功能 "${FLAGS[8]}" \
开启数字键盘选词 使用数字小键盘选词 "${FLAGS[9]}" \
禁用不常用快捷键 切换简繁体、剪切板、Unicode输入 "${FLAGS[10]}" \
优化中文标点 解决方括号输入问题 "${FLAGS[11]}" \
配置特殊符号 按v键触发快速输入特殊符号 "${FLAGS[12]}" \
安装Emoji支持组件 可以显示彩色Emoji表情 "${FLAGS[13]}" \
大写时关闭拼音输入 输入大写字母时临时禁用输入法 "${FLAGS[14]}" \
安装皮肤-星空黑 DebuggerX转换的搜狗主题 "${FLAGS[15]}" \
安装皮肤-breeze 与KDE默认的Breeze主题匹配的外观 "${FLAGS[16]}" \
安装皮肤-material-color 谷歌MD风格的主题 "${FLAGS[17]}" \
安装皮肤-nord 'Nord主题(北极蓝)' "${FLAGS[18]}" \
安装皮肤-solarized 'Solarized主题(暗青)' "${FLAGS[19]}" \
'安装皮肤-简约黑/白' 'Maicss专为深度制作的主题' "${FLAGS[20]}" \
安装皮肤-dracula 'drbbr制作的德古拉主题' "${FLAGS[21]}" \
选择皮肤 "进入皮肤选择页面(新皮肤安装时会自动进入)" "${FLAGS[22]}" \
)

clear

if [ ${#OPTIONS} == 0 ]; then
  echo '无事可做，退出脚本。'
  exit 0
fi

# 默认为非竖排
VERTICAL_CANDIDATE_LIST=false
# 默认候选词数量为7
PAGE_SIZE=7
# 进入皮肤选择界面
SKIN_SELECT=false


for OPTION in $OPTIONS ; do
  case $OPTION in
  安装搜狗词库)
    check_and_install fcitx5-pinyin-sougou "搜狗词库"
    ;;
  导入中文维基词库)
    download_and_unzip 'zhwiki.zip' '中文维基词库' ~/.local/share/fcitx5/pinyin/dictionaries
    ;;
  导入精选搜狗细胞词库)
    download_and_unzip 'sogou_dict.zip' '精选搜狗细胞词库' ~/.local/share/fcitx5/pinyin/dictionaries
    mv ~/.local/share/fcitx5/pinyin/dictionaries/sogou_dict/* ~/.local/share/fcitx5/pinyin/dictionaries
    rm -r ~/.local/share/fcitx5/pinyin/dictionaries/sogou_dict
    ;;
  开启云拼音)
    check_and_install fcitx5-module-cloudpinyin "云拼音组件"
    echo '配置云拼音'
    config_cloudpinyin
    ;;
  竖排显示)
    VERTICAL_CANDIDATE_LIST=true
    ;;
  修改候选词数量)
    SELECTED_INDEX=$(select_from_array '请选择候选词数量' 3 \
      '5个候选词，建议竖排模式下使用' \
      '7个候选词，这是Fcitx5拼音的默认数量' \
      '10个候选词，建议横排模式使用' \
    )

    if [ "${SELECTED_INDEX:-0}" -ge "0" ]; then
      PAGE_SIZES=(5 7 10)
      PAGE_SIZE=${PAGE_SIZES[$SELECTED_INDEX]}
      # 设置候选词数量，同时修改默认候选词数量和拼音候选词数量
      change_config 'DefaultPageSize' "$PAGE_SIZE" ~/.config/fcitx5/config
      change_config 'PageSize' "$PAGE_SIZE" ~/.config/fcitx5/conf/pinyin.conf
      echo "已设置候选词数量为$PAGE_SIZE"
    fi
  ;;
  修改字体大小)
    SELECTED_INDEX=$(select_from_array '请选择候选词数量' 3 \
      '8' \
      '10' \
      '12' \
      '14' \
      '16' \
      '18' \
      '20' \
      '22' \
      '24' \
    )

    if [ "${SELECTED_INDEX:-0}" -ge "0" ]; then
      FONT_SIZES=(8 10 12 14 16 18 20 22 24)
      FONT_SIZE=${FONT_SIZES[$SELECTED_INDEX]}
      echo "todo: 修改字体大小"
      echo "已修改字体大小为$FONT_SIZE"
    fi
  ;;
  修改默认加减号翻页)
    echo 'todo:修改默认加减号翻页'
  ;;
  关闭预编辑)
    change_config 'PreeditEnabledByDefault' "False" ~/.config/fcitx5/config
    change_config 'PreeditInApplication' "False" ~/.config/fcitx5/conf/pinyin.conf
    echo '已关闭预编辑'
  ;;
  开启数字键盘选词)
    change_config 'UseKeypadAsSelection' "False" ~/.config/fcitx5/conf/pinyin.conf
    echo '已开启数字键盘选词'
  ;;
  禁用不常用快捷键)
    change_config 'TriggerKey' "" ~/.config/fcitx5/conf/unicode.conf
    change_config 'DirectUnicodeMode' "" ~/.config/fcitx5/conf/unicode.conf
    change_config '0' "" ~/.config/fcitx5/conf/cloudpinyin.conf
    echo 'todo:禁用不常用快捷键'
  ;;
  优化中文标点)
    echo 'todo:优化中文标点'
  ;;
  配置特殊符号)
    echo 'todo:配置特殊符号'
  ;;
  安装Emoji支持组件)
    check_and_install fcitx5-module-emoji "Emoji支持组件"
  ;;
  大写时关闭拼音输入)
    echo 'todo:大写时关闭拼音输入'
  ;;
  *星空黑)
    download_and_unzip '星空黑.zip' '皮肤-星空黑' ~/.local/share/fcitx5/themes
    ;;
  *breeze)
    check_and_install fcitx5-breeze '皮肤-breeze'
    ;;
  *material*)
    check_and_install fcitx5-material-color '皮肤-material-color'
    ;;
  *nord)
    check_and_install fcitx5-nord '皮肤-nord'
    ;;
  *solarized)
    check_and_install fcitx5-solarized '皮肤-solarized'
    ;;
  *简约黑*)
    download_and_unzip 'Simple-dark.zip' '皮肤-简约黑' ~/.local/share/fcitx5/themes
    download_and_unzip 'Simple-white.zip' '皮肤-简约白' ~/.local/share/fcitx5/themes
    ;;
  *dracula)
    download_and_unzip 'dracula.zip' '皮肤-dracula' ~/.local/share/fcitx5/themes
    ;;
  选择皮肤)
    SKIN_SELECT=true
    ;;
  esac
done

if $SKIN_SELECT; then
  select_skin
fi

# 先退出Fcitx，避免修改的配置被运行中的进程恢复
fcitx5-remote -e

# 设置是否为竖排模式
if $VERTICAL_CANDIDATE_LIST; then
  sed -i "s/Vertical Candidate List.*/Vertical Candidate List=True/" ~/.config/fcitx5/conf/classicui.conf
  echo "已设置候选词为竖排显示"
else
  sed -i "s/Vertical Candidate List.*/Vertical Candidate List=False/" ~/.config/fcitx5/conf/classicui.conf
  echo "已设置候选词为横向显示"
fi


if [ ${#SELECTED_SKIN} -gt 0 ]; then
  sed -i "s/Theme.*/Theme=$SELECTED_SKIN/" ~/.config/fcitx5/conf/classicui.conf
  echo "已设置皮肤为[$SELECTED_SKIN]"
fi

echo "配置完成，正在重启Fcitx5"
fcitx5 -rd >/dev/null 2>&1 &

RESTART_FLAG=''
CHECK_COUNT=0

while true; do
  CHECK_COUNT=$((CHECK_COUNT+1))
  if [ $CHECK_COUNT -gt 100 ]; then
    break
  fi
  if [ "$RESTART_FLAG" == "Failed to get reply." ]; then
    if [ "$(fcitx5-remote 2>&1)" != "Failed to get reply." ]; then
      break
    fi
  else
    RESTART_FLAG=$(fcitx5-remote 2>&1)
  fi

  sleep 0.2
done

echo "重启完成"
