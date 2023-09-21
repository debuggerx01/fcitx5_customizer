#!/usr/bin/env bash

copy_file_and_zip() {
  cp ../assets/"$1" ./"$2"
  touch -t "202309150000" ./"$2"
  zip "$3".zip "$2"
  rm ./"$2"
}

copy_dir_and_zip() {
  cp -r ../assets/"$1" ./"$1"
  find ./"$1" -exec touch -t "202309150000" '{}' \;
  zip -r -D -X -9 -A --compression-method deflate "$1".zip "$1"
  rm -r ./"$1"
}

if [ "$(ls -A ./docs)" ]; then
  rm -r ./docs/*
fi

cd ./docs || exit 1

copy_file_and_zip zhwiki-20230823.dict zhwiki.dict zhwiki
copy_file_and_zip symbols.mb symbols.mb symbols
copy_file_and_zip punc.mb.zh_CN punc.mb.zh_CN punc_zh_CN
copy_dir_and_zip 星空黑
copy_dir_and_zip dracula
copy_dir_and_zip Simple-dark
copy_dir_and_zip Simple-white
copy_dir_and_zip sogou_dict
copy_dir_and_zip uppercase_addon
copy_dir_and_zip lua

cp ../fcitx5_customizer.sh ./fcitx5_customizer.sh