#!/bin/bash

#rm -f instalador.sh && curl -s -f -L --retry 3 --connect-timeout 3 --max-time 10 --retry-delay 1 --raw -o instalador.sh https://raw.githubusercontent.com/mateusoro/box64simples/refs/heads/main/instalador.sh && chmod +x instalador.sh && ./instalador.sh

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
pkg install pulseaudio iproute2 wget glibc git xkeyboard-config freetype fontconfig libpng xorg-xrandr termux-x11-nightly termux-am zenity which bash curl sed cabextract -y --no-install-recommends #&>/dev/null

box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true

echo "Matando qualquer servidor HTTP existente na porta 8081..."
pkill -f "python -m http.server 8081" || true


clear
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


# Matar processos existentes que podem interferir
echo "Matando processos antigos..."
box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true
pkill -f "python -m http.server 8081" || true

# Reiniciar serviços necessários
echo "Iniciando Termux-X11..."
termux-x11 :0 &>/dev/null &
sleep 2

echo "Iniciando PulseAudio..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null
sleep 1

# Configurar variáveis de ambiente
export DISPLAY=:0
export WINEDEBUG=+all
export WINEDLLOVERRIDES="mscoree,mshtml="

# Configurações do Box64 para otimizar desempenho
export BOX64_LOG=1
export BOX64_DYNAREC=1  # Ativar Dynarec para melhor desempenho
export BOX64_DYNAREC_BIGBLOCK=3
export BOX64_DYNAREC_STRONGMEM=1
export BOX64_DYNAREC_SAFEFLAGS=2
export BOX64_NOBANNER=1
export BOX64_JITGDB=0
export BOX64_SDL2_JOYWASD=0
export BOX64_PREFER_EMULATED=0
export BOX64_NORCFILES=0

# Iniciar o jogo com argumentos melhorados
mkdir -p "$HOME_DIR/http_logs"

# Verificar se a inicialização do X11 foi bem-sucedida
am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null
sleep 3  # Aguardar X11 iniciar

# Limpar logs anteriores
> "$HOME/box64.log"

echo "Iniciando o jogo..."
cd "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/" || {
  echo "Erro: Não foi possível acessar o diretório do jogo!"
  exit 1
}

# Lançar o jogo com parâmetros otimizados
box64 wine BorderlandsGOTY.exe > "$HOME/box64.log" 2>&1 &
PID=$!

# Função para atualizar o log continuamente
update_log() {
  while kill -0 $PID 2>/dev/null; do
    cp "$HOME/box64.log" "$HOME/http_logs/box64.log"
    sleep 10
  done
}

# Iniciar a função de atualização de log em segundo plano
update_log &

# Iniciar servidor HTTP no diretório de logs
cd "$HOME/http_logs"
IP_ADDRESS=$(ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed -n '2p')

# Iniciar o servidor com binding explícito para 0.0.0.0 (todas as interfaces)
echo "Iniciando servidor HTTP na porta 8081..."
python -m http.server 8081 &

echo "Acesse o log em: http://$IP_ADDRESS:8081/box64.log"

# Aguardar por tecla para encerrar
echo "Pressione qualquer tecla para encerrar o jogo e limpar os processos"
read -n1
box64 wineserver -k
pkill -f "python -m http.server 8081"