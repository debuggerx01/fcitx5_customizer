# fcitx5-dracula-theme

Note: This enlglish translation was made using ChatGPT.

## Normal Mode
![](./shot/normal_shot1.png)  
![](./shot/normal_shot2.png)  

## Transparent Mode
![](./shot/trans_shot1.png)
![](./shot/trans_shot2.png)

## Installation Steps
Clone the entire project to your local machine:

```
mkdir -p ~/.local/share/fcitx5/themes/dracula
git clone https://github.com/drbbr/fcitx5-dracula-theme.git ~/.local/share/fcitx5/themes/dracula
```

Modify the configuration file:
`vim ~/.config/fcitx5/conf/classicui.conf`

Add the following parameters:

```
# Vertical candidate list
Vertical Candidate List=False

# Use screen DPI
PerScreenDPI=True

# Font (set to your preferred font)
Font="Source Han Sans CN Medium 13"

# Theme
Theme=dracula
```

To switch between modes, you can edit the theme.conf file:

```
# Transparent mode: select peneltrans.png
# Normal mode: select panel.png
[InputPanel/Background]
Image=paneltrans.png
```
