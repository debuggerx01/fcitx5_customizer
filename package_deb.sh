#!/usr/bin/env bash

VERSION=$(grep 'Version:' fcitx5_customizer.sh | awk '{print $3}')

if [ -e deb_builder ]; then
    rm -rf deb_builder
fi


mkdir "deb_builder"

cp -r debian deb_builder/DEBIAN
chmod -R 755 deb_builder/DEBIAN

cp ./LICENSE deb_builder/DEBIAN/copyright

echo "设置版本号为: $VERSION"

echo Version: "$VERSION" >> deb_builder/DEBIAN/control

mkdir -p deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/files

cp -r dde_package_info/* deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/

cp launcher.sh deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/files
chmod a+x deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/files/launcher.sh

cp fcitx5_customizer.sh deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/files

mkdir -p deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/entries/icons/hicolor/scalable/apps/

cp assets/logo.png deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/entries/icons/hicolor/scalable/apps/fcitx5_customizer.png

sed -i "s/VERSION/$VERSION/g" deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/info

sed -i "s/VERSION/$VERSION/g" deb_builder/opt/apps/com.debuggerx.fcitx5-customizer/entries/applications/com.debuggerx.fcitx5-customizer.desktop

echo "开始打包deb"

fakeroot dpkg-deb -b deb_builder

mv deb_builder.deb com.debuggerx.fcitx5-customizer_"$VERSION".deb

echo "打包完成！"
