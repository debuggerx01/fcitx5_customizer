#!/usr/bin/env bash

#   Copyright 2023 DebuggerX-DEV
#   Author:     DebuggerX <dx8917312@gmail.com>
#   Version:    1.0.6

BASE_URL="https://www.debuggerx.com/fcitx5_customizer/"
GHPROXY_MIRROR_URL="https://mirror.ghproxy.com/https://raw.githubusercontent.com/debuggerx01/fcitx5_customizer/master/docs/"
SOGOU_SCEL_DOWNLOAD_URL="https://pinyin.sogou.com/d/dict/download_cell.php"
SELECTED_SKIN=''

PM_COMMAND=''
PACKAGE_MANAGER=''

read -r -d '' PACKAGES << EOJSON
{
  "apt": {
    "curl": "curl",
    "dialog": "dialog",
    "unzip": "unzip",
    "sougou_dict": "fcitx5-pinyin-sougou",
    "cloudpinyin": "fcitx5-module-cloudpinyin",
    "emoji": "fcitx5-module-emoji",
    "emoji_font": "fonts-noto-color-emoji",
    "lua": "fcitx5-module-lua",
    "liblua": "liblua5.3-0",
    "breeze": "fcitx5-breeze",
    "material_color": "fcitx5-material-color",
    "nord": "fcitx5-nord",
    "solarized": "fcitx5-solarized",
    "fcitx5_chinese_addons": "fcitx5-chinese-addons",
    "libime": "libime-bin"
  },
  "pacman": {
    "curl": "curl",
    "dialog": "dialog",
    "unzip": "unzip",
    "emoji_font": "noto-fonts-emoji",
    "lua": "fcitx5-lua",
    "breeze": "fcitx5-breeze",
    "material_color": "fcitx5-material-color",
    "nord": "fcitx5-nord",
    "fcitx5_chinese_addons": "fcitx5-chinese-addons",
    "libime": "libime"
  }
}
EOJSON

function select_skin {
  local THEMES SKIN OPTS ITEMS THEME INDEX
  THEMES=()
  THEMES+=("$(ls ~/.local/share/fcitx5/themes/)")
  THEMES+=("$(ls /usr/share/fcitx5/themes/)")
  OPTS=()
  ITEMS=()
  INDEX=0
  for THEME in $(echo "${THEMES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '); do
    ((INDEX++)) || true
    OPTS+=("$INDEX" "$THEME")
    ITEMS+=("$THEME")
  done
  SKIN=$(dialog --stdout --menu "请选择想要应用的皮肤后回车" 0 0 0 "${OPTS[@]}")

  clear

  if [ ${#SKIN} == 0 ]; then
    echo '未选择皮肤'
  else
    SELECTED_SKIN=${ITEMS[$SKIN - 1]}
    echo "选择了[${ITEMS[$SKIN - 1]}]皮肤"
  fi
}

# params: <key> <value> <配置文件路径>
function change_config() {
  if [ -f "$3" ] && grep <"$3" -q "$1"; then
    sed -i "s/$1.*/$1=$2/" "$3"
  else
    echo "$1=$2" >>"$3"
  fi
}

# params: <匹配行> <替换行> <文件不存在时的内容> <配置文件路径>
function change_config_next_line() {
  if [ -f "$4" ] && grep <"$4" -q "$1"; then
    sed -i "/$1/{n;s/.*/$2/}" "$4"
  else
    sed -i "1s/^/$3\n/" "$4"
  fi
}

# params: <zip包名> <中文名> <解压路径>
function download_and_unzip() {
  echo "开始下载$2[$BASE_URL$1]"
  curl -o /tmp/"$1" "$BASE_URL$1"
  if unzip -z /tmp/"$1"; then
    echo "$2下载成功"
  else
    echo "重试下载$2[$GHPROXY_MIRROR_URL$1]"
    curl -o /tmp/"$1" "$GHPROXY_MIRROR_URL$1"
    if unzip -z /tmp/"$1"; then
      echo "$2下载成功"
    else
      echo "$2下载失败"
      return 1
    fi
  fi
  mkdir -p "$3"
  yes | unzip -q /tmp/"$1" -d "$3"
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
  for ITEM in "$@"; do
    ((INDEX++)) || true
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

# 添加aptss支持：若aptss可用，对deepin加速（deepin官方源似乎....已经买不起大流量了？)
function decide_apt_command() {
  if grep -Eqii "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
    DISTRO='Deepin'
  elif grep -Eqi "UnionTech" /etc/issue || grep -Eq "UnionTech" /etc/*-release; then
    DISTRO='UniontechOS'
  elif grep -Eqi "UOS" /etc/issue || grep -Eq "UOS" /etc/*-release; then
    DISTRO='UniontechOS'
  else
    DISTRO='OtherOS'
  fi

  if [ "$DISTRO" = "Deepin" ] && [ "$(which aptss)" != "" ]; then
    echo "检测到正在使用deepin,且aptss加速可用，使用aptss进行安装加速"
    PM_COMMAND="aptss install -y"
  else
    echo "使用/usr/bin/apt来提供安装服务"
    PM_COMMAND="/usr/bin/apt install -y"
  fi
}

# 检查包，未安装则执行安装
# params: <包名> <包的中文名>
function check_and_install() {
  local PACKAGE
  if [ "$1" == "jq" ] ; then
    PACKAGE="jq"
  else
    PACKAGE=$(echo "$PACKAGES" | jq .$PACKAGE_MANAGER."$1" | tr -d '"')
  fi
  if [ $PACKAGE_MANAGER == "apt" ] && [ "$PACKAGE" != "null" ] && check_installed "$PACKAGE"; then
    if ! [ "$2" == "" ]; then
      echo "$2已安装"
    fi
  else
    if [ "$2" == "" ]; then
      echo "安装$PACKAGE"
    else
      echo "安装$2"
    fi
    if [ "$PACKAGE" != "null" ] ; then
      sudo $PM_COMMAND "$PACKAGE"
    fi
  fi
}

# 从搜狗细胞词库官网下载细胞词库文件，并转换为Fcitx5可用的dict词库文件
# params: <细胞词库id> <细胞词库名称>
function download_scel_and_convert() {
  local SCEL_DOWNLOAD_URL="$SOGOU_SCEL_DOWNLOAD_URL?id=$1&name=$2"
  echo "开始下载$2[$SCEL_DOWNLOAD_URL]"
  local TIMES=0
  while [ $TIMES -lt 5 ]; do
    curl -o /tmp/"$2.scel" "$SCEL_DOWNLOAD_URL"
    if [ -s /tmp/"$2.scel" ] && [ $(wc -c < /tmp/"$2.scel") -le 100 ]; then
      ((TIMES++))
      echo "重试下载[第$TIMES次]$2[$SCEL_DOWNLOAD_URL]"
    else
      TIMES=5
    fi
  done

  if [ -s /tmp/"$2.scel" ] && [ $(wc -c < /tmp/"$2.scel") -le 100 ]; then
    echo "[$2]下载失败"
  else
    scel2org5 /tmp/"$2.scel" -o /tmp/"$2.org"
    libime_pinyindict /tmp/"$2.org" /tmp/sogou_dict/"$2.dict"
  fi
}

function import_sogou_scel_dict() {
  # 确保 scel2org5 已安装
  check_and_install fcitx5_chinese_addons
  # 确保 libime_pinyindict 已安装
  check_and_install libime

  mkdir -p /tmp/sogou_dict/
  download_scel_and_convert 15127 "财经金融词汇大全【官方推荐】"
  download_scel_and_convert 15128 "法律词汇大全【官方推荐】"
  download_scel_and_convert 2 "古诗词名句【官方推荐】"
  download_scel_and_convert 15126 "机械词汇大全【官方推荐】"
  download_scel_and_convert 15117 "计算机词汇大全【官方推荐】"
  download_scel_and_convert 15118 "建筑词汇大全【官方推荐】"
  download_scel_and_convert 15149 "农业词汇大全【官方推荐】"
  download_scel_and_convert 15125 "医学词汇大全【官方推荐】"
  download_scel_and_convert 22421 "政府机关团体机构大全【官方推荐】"
  download_scel_and_convert 15130 "中国历史词汇大全【官方推荐】"

  mkdir -p ~/.local/share/fcitx5/pinyin/dictionaries
  mv /tmp/sogou_dict/* ~/.local/share/fcitx5/pinyin/dictionaries
}

if [ -e /usr/bin/apt ]; then
  PACKAGE_MANAGER="apt"
  decide_apt_command
elif [ -e /usr/bin/pacman ]; then
  PACKAGE_MANAGER="pacman"
  PM_COMMAND="/usr/bin/pacman -S --noconfirm"
else
  dialog --msgbox "目前本脚本只能在 debian 系 (deepin、ubuntu、mint等) 和 arch 系 (manjaro、asahi等) 发行版中运行" 10 32
  clear
  echo "目前本脚本只能在 debian 系 (deepin、ubuntu、mint等) 和 arch 系 (manjaro、asahi等) 发行版中运行"
  exit
fi

check_and_install jq 'json解析工具'

# 先确保dialog、unzip和curl已安装
check_and_install unzip ''
check_and_install dialog ''
check_and_install curl ''

if ! [ -e /usr/bin/fcitx5 ] || [ "$GTK_IM_MODULE" != "fcitx" ]; then
  dialog --msgbox "本脚本只针对Fcitx5进行优化，而您使用的输入法是[$GTK_IM_MODULE]，请确认后重试" 10 32
  exit
fi

FLAGS=()
for i in {0..22}; do
  FLAGS+=('off')
done

if [ "$1" == "recommend" ]; then
  FLAGS[0]='on'
  FLAGS[1]='on'
  FLAGS[2]='on'
  FLAGS[3]='on'
  FLAGS[5]='on'
  FLAGS[6]='on'
  FLAGS[7]='on'
  FLAGS[8]='on'
  FLAGS[9]='on'
  FLAGS[11]='on'
  FLAGS[12]='on'
  FLAGS[13]='on'
  FLAGS[14]='on'
  FLAGS[15]='on'
  FLAGS[16]='on'
  FLAGS[23]='on'
fi

# 弹出主选框
OPTIONS=$(
  dialog --stdout --checklist "请使用上下方向键移动选项，空格键勾选，回车键确认" 0 0 0 \
    安装搜狗词库 从仓库中安装搜狗词库 "${FLAGS[0]}" \
    导入中文维基词库 导入中文维基词库20230605版 "${FLAGS[1]}" \
    导入精选搜狗细胞词库 导入部分来自搜狗的精选细胞词库 "${FLAGS[2]}" \
    开启云拼音 基于百度的云拼音，默认在第二个候选词位置 "${FLAGS[3]}" \
    竖排显示 不勾选则为横向显示候选词 "${FLAGS[4]}" \
    修改候选词数量 进入候选词数量选择页面 "${FLAGS[5]}" \
    修改字体大小 进入输入法字体大小选择页面 "${FLAGS[6]}" \
    保持输入法状态 切换程序和窗口后输入法保持不变 "${FLAGS[7]}" \
    修改默认加减号翻页 快速输入时生效，默认为上下方向键 "${FLAGS[8]}" \
    关闭预编辑 关闭在程序中显示输入中的拼音功能 "${FLAGS[9]}" \
    开启数字键盘选词 使用数字小键盘选词 "${FLAGS[10]}" \
    禁用不常用快捷键 切换简繁体、剪切板、Unicode输入等 "${FLAGS[11]}" \
    优化中文标点 解决方括号输入问题 "${FLAGS[12]}" \
    配置快速输入 按v键快速输入特殊符号及函数 "${FLAGS[13]}" \
    安装Emoji支持组件 可以显示彩色Emoji表情 "${FLAGS[14]}" \
    大写时关闭拼音输入 输入大写字母时临时禁用输入法 "${FLAGS[15]}" \
    安装皮肤-星空黑 DebuggerX转换的搜狗主题 "${FLAGS[16]}" \
    安装皮肤-breeze 与KDE默认的Breeze主题匹配的外观 "${FLAGS[17]}" \
    安装皮肤-material-color 谷歌MD风格的主题 "${FLAGS[18]}" \
    安装皮肤-nord 'Nord主题(北极蓝)' "${FLAGS[19]}" \
    安装皮肤-solarized 'Solarized主题(暗青)' "${FLAGS[20]}" \
    '安装皮肤-简约黑/白' 'Maicss专为深度制作的主题' "${FLAGS[21]}" \
    安装皮肤-dracula 'drbbr制作的德古拉主题' "${FLAGS[22]}" \
    选择皮肤 "进入皮肤选择页面" "${FLAGS[23]}"
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

# 先退出Fcitx，避免修改的配置被运行中的进程恢复
fcitx5-remote -e

# 确保配置文件中有[Behavior]段
if ! ([ -e ~/.config/fcitx5/config ] && grep <~/.config/fcitx5/config -q "Behavior"); then
  echo -e '[Behavior]\n' >>~/.config/fcitx5/config
fi

for OPTION in $OPTIONS; do
  case $OPTION in
  安装搜狗词库)
    check_and_install sougou_dict "搜狗词库"
    ;;
  导入中文维基词库)
    download_and_unzip 'zhwiki.zip' '中文维基词库' ~/.local/share/fcitx5/pinyin/dictionaries
    ;;
  导入精选搜狗细胞词库)
    import_sogou_scel_dict
    ;;
  开启云拼音)
    check_and_install cloudpinyin "云拼音组件"
    change_config 'CloudPinyinEnabled' 'True' ~/.config/fcitx5/conf/pinyin.conf
    change_config 'MinimumPinyinLength' '2' ~/.config/fcitx5/conf/cloudpinyin.conf
    change_config 'Backend' 'Baidu' ~/.config/fcitx5/conf/cloudpinyin.conf
    echo '已配置云拼音'
    ;;
  竖排显示)
    VERTICAL_CANDIDATE_LIST=true
    ;;
  修改候选词数量)
    SELECTED_INDEX=$(
      select_from_array '请选择候选词数量' 3 \
        '5个候选词，建议竖排模式下使用' \
        '7个候选词，这是Fcitx5拼音的默认数量' \
        '10个候选词，建议横排模式使用'
    )

    clear

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
    SELECTED_INDEX=$(
      select_from_array '请选择字体大小' 2 \
        '8' \
        "10(默认大小)" \
        '12' \
        '14' \
        '16' \
        '18' \
        '20' \
        '22' \
        '24'
    )

    clear

    if [ "${SELECTED_INDEX:-0}" -ge "0" ]; then
      FONT_SIZES=(8 10 12 14 16 18 20 22 24)
      FONT_SIZE=${FONT_SIZES[$SELECTED_INDEX]}

      if [ -f ~/.config/fcitx5/conf/classicui.conf ] && grep <~/.config/fcitx5/conf/classicui.conf -q "^Font.*"; then
        sed -i "/^Font.*/{s/[0-9]\{1,2\}/$FONT_SIZE/}" ~/.config/fcitx5/conf/classicui.conf
      else
        echo "Font=\"Sans $FONT_SIZE\"" >>~/.config/fcitx5/conf/classicui.conf
      fi

      echo "已修改字体大小为$FONT_SIZE"
    fi
    ;;
  保持输入法状态)
    change_config 'ShareInputState' "All" ~/.config/fcitx5/config
    echo '已设置保持输入法状态'
    ;;
  修改默认加减号翻页)
    change_config_next_line "\[Hotkey\/PrevPage\]" "0\=minus" "[Hotkey/PrevPage]\n0=minus" ~/.config/fcitx5/config
    change_config_next_line "\[Hotkey\/NextPage\]" "0\=equal" "[Hotkey/NextPage]\n0=equal" ~/.config/fcitx5/config
    echo '已修改默认加减号翻页'
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
    # 禁用unicode相关快捷键
    change_config 'TriggerKey' "" ~/.config/fcitx5/conf/unicode.conf
    change_config 'DirectUnicodeMode' "" ~/.config/fcitx5/conf/unicode.conf
    # 云拼音切换快捷键
    change_config_next_line '\[Toggle Key\]' '' '' ~/.config/fcitx5/conf/cloudpinyin.conf
    sed -i "s/\[Toggle Key\]//" ~/.config/fcitx5/conf/cloudpinyin.conf
    change_config 'Toggle Key' '' ~/.config/fcitx5/conf/cloudpinyin.conf
    # 简繁体切换
    change_config_next_line '\[Hotkey\]' '' '' ~/.config/fcitx5/conf/chttrans.conf
    sed -i "s/\[Hotkey\]//" ~/.config/fcitx5/conf/chttrans.conf
    change_config 'Hotkey' '' ~/.config/fcitx5/conf/chttrans.conf
    # 剪切板
    echo -e 'PastePrimaryKey=\nTriggerKey=' >~/.config/fcitx5/conf/clipboard.conf

    echo '已禁用不常用快捷键'
    ;;
  优化中文标点)
    download_and_unzip 'punc_zh_CN.zip' '中文标点优化配置' ~/.local/share/fcitx5/punctuation
    ;;
  配置快速输入)
    download_and_unzip 'symbols.zip' '特殊符号集' ~/.local/share/fcitx5/data/quickphrase.d
    download_and_unzip 'lua.zip' 'lua脚本集' ~/.local/share/fcitx5
    ;;
  安装Emoji支持组件)
    check_and_install emoji "Emoji支持组件"
    check_and_install emoji_font "Emoji字体"
    ;;
  大写时关闭拼音输入)
    download_and_unzip 'uppercase_addon.zip' '大写时关闭拼音输入插件' ~/.local/share/fcitx5
    cp -rn ~/.local/share/fcitx5/uppercase_addon/* ~/.local/share/fcitx5
    rm -r ~/.local/share/fcitx5/uppercase_addon
    check_and_install lua 'lua支持模块'
    check_and_install liblua 'lua运行库'
    if [ -e "/usr/lib/x86_64-linux-gnu/liblua5.3.so.0.0.0" ] && [ ! -e "/usr/lib/x86_64-linux-gnu/liblua5.3.so" ]; then
      echo '修复lua动态库链接丢失问题'
      sudo ln -s /usr/lib/x86_64-linux-gnu/liblua5.3.so.0.0.0 /usr/lib/x86_64-linux-gnu/liblua5.3.so
    fi
    ;;
  *星空黑)
    download_and_unzip '星空黑.zip' '皮肤-星空黑' ~/.local/share/fcitx5/themes
    ;;
  *breeze)
    check_and_install breeze '皮肤-breeze'
    ;;
  *material*)
    check_and_install material_color '皮肤-material-color'
    ;;
  *nord)
    check_and_install nord '皮肤-nord'
    ;;
  *solarized)
    check_and_install solarized '皮肤-solarized'
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

# 设置是否为竖排模式
if $VERTICAL_CANDIDATE_LIST; then
  change_config 'Vertical Candidate List' 'True' ~/.config/fcitx5/conf/classicui.conf
  echo "已设置候选词为竖排显示"
else
  change_config 'Vertical Candidate List' 'False' ~/.config/fcitx5/conf/classicui.conf
  echo "已设置候选词为横向显示"
fi

if [ ${#SELECTED_SKIN} -gt 0 ]; then
  change_config 'Theme' "$SELECTED_SKIN" ~/.config/fcitx5/conf/classicui.conf
  echo "已设置皮肤为[$SELECTED_SKIN]"
fi

echo "配置完成，正在重启Fcitx5"
fcitx5 -rd >/dev/null 2>&1 &

RESTART_FLAG=''
CHECK_COUNT=0

while true; do
  CHECK_COUNT=$((CHECK_COUNT + 1))
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
