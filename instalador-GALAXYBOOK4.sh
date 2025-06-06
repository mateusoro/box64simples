#!/bin/bash

#curl -Lo instalador.sh https://raw.githubusercontent.com/mateusoro/box64simples/refs/heads/main/instalador.sh && chmod +x instalador.sh && ./instalador.sh


clear
echo "Instalando dependencias"
echo ""

# Verificar se o armazenamento já está montado e acessível
if [ ! -d "/storage/emulated/0" ] && [ ! -d "$HOME/storage" ]; then
  termux-setup-storage
fi

apt-get update #&>/dev/null
apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade #&>/dev/null
apt install python --no-install-recommends -y #&>/dev/null
pkg install x11-repo glibc-repo -y #&>/dev/null
pkg install pulseaudio wget glibc git xkeyboard-config freetype fontconfig libpng xorg-xrandr termux-x11-nightly termux-am zenity which bash curl sed cabextract -y --no-install-recommends #&>/dev/null

box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true


echo "Instalando Glibc"
echo ""

if [ ! -d "$PREFIX/glibc" ]; then
  wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/glibc-prefix.tar.xz
  tar -xJf glibc-prefix.tar.xz -C $PREFIX/
  mv "$PREFIX/glibc-prefix" "$PREFIX/glibc"
else
  echo "Glibc já instalado. Pulando a instalação."
fi

unset LD_PRELOAD
# Variáveis
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
GLIBC_PREFIX="$PREFIX/glibc"
OPT_DIR="$GLIBC_PREFIX/opt"
BIN_DIR="$GLIBC_PREFIX/bin"
HOME_DIR=${HOME:-/data/data/com.termux/files/home}

# 1) Criar links simbólicos para os binários do Wine
ln -sf "$OPT_DIR/wine/bin/wine"       "$BIN_DIR/wine"


# 3) Compilar o box64 no prefixo glibc
cd "$OPT_DIR/wine/bin"
unset LD_PRELOAD
export GLIBC_PREFIX
export PATH="$GLIBC_PREFIX/bin:$PATH"

cd "$HOME_DIR"
if [ ! -e "$GLIBC_PREFIX/bin/box64" ]; then
  git clone https://github.com/ptitSeb/box64 box64-src
  cd box64-src
  sed -i 's/\/usr/\/data\/data\/com.termux\/files\/usr\/glibc/g' CMakeLists.txt
  sed -i 's/\/etc/\/data\/data\/com.termux\/files\/usr\/glibc\/etc/g' CMakeLists.txt
  mkdir -p build && cd build
  cmake .. \
  -DARM_DYNAREC=1 \
  -DCMAKE_INSTALL_PREFIX="$GLIBC_PREFIX" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBAD_SIGNAL=ON \
  -DSD845=ON
  make -j8 && make install
  cd "$HOME_DIR"
  rm -rf box64-src
else
  echo "Box64 já compilado. Pulando a compilação."
fi

# 4) Atualizar variáveis de ambiente para esta sessão
export GLIBC_PREFIX
export PATH="$GLIBC_PREFIX/bin:$PATH"

# 5) Reiniciar wineserver (silencioso) e matar pulseaudio/X11
box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true

# 6) Copiar configurações para o SD Card, se ainda não existirem
CONFIG_DIR="/sdcard/Box64Droid (native)"
mkdir -p "$CONFIG_DIR"

cp_if_missing() {
  local src="$1" dst="$2"
  [ -f "$dst" ] || cp "$src" "$dst"
}

cp_if_missing "$OPT_DIR/Box64Droid.conf"          "$CONFIG_DIR/Box64Droid.conf"
cp_if_missing "$OPT_DIR/DXVK_D8VK.conf"           "$CONFIG_DIR/DXVK_D8VK.conf"
cp_if_missing "$OPT_DIR/DXVK_D8VK_HUD.conf"       "$CONFIG_DIR/DXVK_D8VK_HUD.conf"

# 7) Criar prefixo Wine se não existir
if [ ! -d "$HOME_DIR/.wine" ]; then
  echo "Wine prefix not found! Creating..."
  WINEDLLOVERRIDES="mscoree=" box64 wineboot &>/dev/null
  cp -r "$OPT_DIR/Shortcuts/"* "$HOME_DIR/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/"

  rm -f "$HOME_DIR/.wine/dosdevices/z:" "$HOME_DIR/.wine/dosdevices/d:" || true
  ln -s /sdcard/Download "$HOME_DIR/.wine/dosdevices/d:"   || true
  ln -s /sdcard           "$HOME_DIR/.wine/dosdevices/e:"   || true
  ln -s /data/data/com.termux/files "$HOME_DIR/.wine/dosdevices/z:" || true

  echo "Installing DXVK, D8VK and vkd3d-proton..."
  box64 wine "$OPT_DIR/Resources64/Run if you will install on top of WineD3D.bat" &>/dev/null
  box64 wine "$OPT_DIR/Resources64/DXVK2.3/DXVK2.3.bat"          &>/dev/null

  box64 wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" /v d3d12      /d native /f &>/dev/null
  box64 wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" /v d3d12core  /d native /f &>/dev/null

  cp "$OPT_DIR/Resources/vkd3d-proton/"*     "$HOME_DIR/.wine/drive_c/windows/syswow64/"
  cp "$OPT_DIR/Resources64/vkd3d-proton/"*   "$HOME_DIR/.wine/drive_c/windows/system32/"

  echo "Done!"
fi

# 8) Limpar tela e iniciar serviços
clear
unset LD_PRELOAD

echo "Starting Termux-X11..."
termux-x11 :0 &>/dev/null &

echo "Starting PulseAudio..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null

# 9) Carregar configurações do usuário

import_python_conf(){
  local file="$1"
  # cada linha tipo: os.environ["NOME"]=valor
  # converte em: export NOME="valor"
  sed -En '
    s|^.*\["([^"]+)"\]\s*=\s*"(.*)"$|export \1="\2"|p
    s|^.*\["([^"]+)"\]\s*=\s*([^"].*)$|export \1=\2|p
  ' "$file"
}

# carrega as variáveis
eval "$(import_python_conf "$CONFIG_DIR/Box64Droid.conf")"
eval "$(import_python_conf "$CONFIG_DIR/DXVK_D8VK_HUD.conf")"

# 10) Iniciar Box64 + Wine e o launcher do X11
#taskset -c 4-7 box64 wine explorer /desktop=shell,800x600 "$OPT_DIR/autostart.bat" &>/dev/null &
# 10) Iniciar Box64 + Wine e o launcher do X11
export DISPLAY=:0

am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null &
sleep 2  # Aguarda o X11 iniciar (ajuste se necessário)
export DISPLAY=:0

BOX64_LOG=1 BOX64_DYNAREC=0 box64 wine "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe" &