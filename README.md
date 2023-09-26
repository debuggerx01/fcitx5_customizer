# Fcitx5定制优化脚本
![logo](https://www.debuggerx.com/fcitx5_customizer/logo.png)
一个针对 [Fcitx5](https://github.com/fcitx/fcitx5) 的优化脚本，力求更符合简中用户的使用习惯～

# 使用方法
```shell
# 完全自定义
bash fcitx5_customizer.sh

# 使用推荐配置
bash fcitx5_customizer.sh recommend

# 在线运行
bash -c "$(curl -fsSL https://www.debuggerx.com/fcitx5_customizer/fcitx5_customizer.sh)"

# 在线运行并使用推荐配置
curl -sSL https://www.debuggerx.com/fcitx5_customizer/fcitx5_customizer.sh | bash -s -- recommend
```

# 可能遇到的问题
## curl未找到命令
如果执行优化命令时提示`curl`未找到命令，请先手动执行 `sudo apt install curl` 安装即可。
## 当前输入法不是fcitx
只有当前系统正确安装并启用了 Fcitx5 输入法是，优化脚本才会真正执行。有一种情况是，当使用系统自带的输入法切换器将系统的输入法切换为 Fcitx5 时，虽然看上去已经切换成功并且输入法已经可以正常使用，但是系统的环境变量还没有及时刷新，所以脚本还是会认为系统输入法不是 Fcitx5。此时只要注销或重启一次系统，再次执行优化命令即可正确识别。


更多说明及资料：[fcitx5_customizer —— 一个让 Fcitx5 更符合简中用户使用习惯的优化脚本](https://www.debuggerx.com/2023/09/20/fcitx5-customizer/)
