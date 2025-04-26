#!/bin/bash

#rm -f instalador.sh && curl -s -f -L --retry 3 --connect-timeout 3 --max-time 10 --retry-delay 1 --raw -o instalador.sh https://raw.githubusercontent.com/mateusoro/box64simples/refs/heads/main/instalador.sh && chmod +x instalador.sh && ./instalador.sh

clear
echo "Instalando dependencias"
echo ""

# Verificar se o armazenamento já está montado e acessível
if [ ! -d "/storage/emulated/0" ] && [ ! -d "$HOME/storage" ]; then
  termux-setup-storage
fi

termux-wake-lock


apt-get update #&>/dev/null
apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade #&>/dev/null
apt install python --no-install-recommends -y #&>/dev/null
pkg install x11-repo glibc-repo -y #&>/dev/null
pkg install busybox pulseaudio iproute2 wget glibc git xkeyboard-config freetype fontconfig libpng xorg-xrandr termux-x11-nightly termux-am zenity which bash curl sed cabextract -y --no-install-recommends #&>/dev/null

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

export PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin"
export BOX86_ENV='LD_LIBRARY_PATH=$PREFIX/glibc/lib32'
export BOX64_PATH="/data/data/com.termux/files/usr/glibc/opt/wine/bin"
export BOX64_LD_LIBRARY_PATH="/data/data/com.termux/files/usr/glibc/opt/wine/lib/wine/i386-unix:/data/data/com.termux/files/usr/glibc/opt/wine/lib/wine/x86_64-unix:/data/data/com.termux/files/usr/glibc/lib/x86_64-linux-gnu"
export LIBGL_DRIVERS_PATH="/data/data/com.termux/files/usr/glibc/lib32/dri:/data/data/com.termux/files/usr/glibc/lib/dri"
export VK_ICD_FILENAMES="/data/data/com.termux/files/usr/glibc/share/vulkan/icd.d/freedreno_icd.aarch64.json:/data/data/com.termux/files/usr/glibc/share/vulkan/icd.d/freedreno_icd.armhf.json"
export DISPLAY=":0"
export PULSE_SERVER="127.0.0.1"
export MESA_LOADER_DRIVER_OVERRIDE="zink"
export MESA_NO_ERROR="1"
export MESA_VK_WSI_PRESENT_MODE="mailbox"
export PULSE_LATENCY_MSEC="60"
export ZINK_DESCRIPTORS="lazy"
export ZINK_CONTEXT_THREADED="false"
export ZINK_DEBUG="compact"
export MESA_SHADER_CACHE_DISABLE="false"
export MESA_SHADER_CACHE_MAX_SIZE="false"
export DXVK_CONFIG_FILE="/sdcard/Box64Droid (native)/DXVK_D8VK.conf"
export FONTCONFIG_PATH="/data/data/com.termux/files/usr/etc/fonts"
export GALLIUM_HUD="simple,fps"
export ZINK_DESCRIPTORS="lazy"
export ZINK_DEBUG="compact"
export TU_DEBUG="noconform"
export MANGOHUD="0"

export DXVK_HUD="fps,version,devinfo,gpuload"

export BOX64_BASH="/data/data/com.termux/files/usr/glibc/opt/box64_bash"
export BOX64_DYNAREC_BIGBLOCK="3"
export BOX64_ALLOWMISSINGLIBS="1"
export BOX64_DYNAREC_STRONGMEM="1"
export BOX64_DYNAREC_X87DOUBLE="0"
export BOX64_DYNAREC_FASTNAN="0"
export BOX64_DYNAREC_FASTROUND="1"
export BOX64_DYNAREC_SAFEFLAGS="2"
export BOX64_DYNAREC_BLEEDING_EDGE="1"
export BOX64_DYNAREC_CALLRET="0"
export BOX64_FUTEX_WAITV="0"
export BOX64_MMAP32="1"
export BOX86_BASH="/data/data/com.termux/files/usr/glibc/opt/box86_bash"
export BOX86_DYNAREC_BIGBLOCK="0"
export BOX86_ALLOWMISSINGLIBS="1"
export BOX86_DYNAREC_STRONGMEM="0"
export BOX86_DYNAREC_X87DOUBLE="0"
export BOX86_DYNAREC_FASTNAN="0"
export BOX86_DYNAREC_FASTROUND="1"
export BOX86_DYNAREC_SAFEFLAGS="1"
export BOX86_DYNAREC_BLEEDING_EDGE="1"
export BOX86_DYNAREC_CALLRET="0"
export BOX86_FUTEX_WAITV="0"

export WINEESYNC="0"
export WINEESYNC_TERMUX="0"
export VKD3D_FEATURE_LEVEL="12_0"


# Configurar variáveis de ambiente

export WINEDEBUG=+err+all,+loaddll,+module
export WINEDLLOVERRIDES="mscoree,mshtml=;wineusb.dll=n,b;winebus.sys=n,b;nsi.sys=n,b"

# Configurações do Box64 para otimizar desempenho
export BOX64_LOG=0        # Nenhum log (exceto erros fatais) :contentReference[oaicite:0]{index=0}
export BOX64_DYNAREC_LOG=0  # Desativa todos os logs do Dynarec :contentReference[oaicite:1]{index=1}
export BOX64_SHOWSEGV=1   # Exibe só detalhes de SIGSEGV (falhas de segmentação) :contentReference[oaicite:2]{index=2}



# 7) Criar prefixo Wine se não existir

PREFIX_PATH="/data/data/com.termux/files/home/.wine"
echo "Removing previous Wine prefix..."
rm -rf "$PREFIX_PATH"


rm -rf "/data/data/com.termux/files/usr/glibc/opt/wine"
echo "Wine 9.13 (WoW64)..."
echo ""
if [ ! -f wine-9.13-glibc-amd64-wow64.tar.xz ]; then
    wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/wine-9.13-glibc-amd64-wow64.tar.xz
    echo ""
    echo "Unpacking Wine 9.13 (WoW64)..."
    tar -xf wine-9.13-glibc-amd64-wow64.tar.xz -C "$PREFIX/glibc/opt"
    mv "$PREFIX/glibc/opt/wine-git-8d25995-exp-wow64-amd64" "$PREFIX/glibc/opt/wine"
    echo "Wine prefix! Creating..."
    WINEDLLOVERRIDES="mscoree=" box64 wineboot
    cp -r "$OPT_DIR/Shortcuts/"* "$HOME_DIR/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/"

    rm -f "$HOME_DIR/.wine/dosdevices/z:" "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /sdcard/Download "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /data/data/com.termux/files "$HOME_DIR/.wine/dosdevices/z:" || true

    echo "Installing DXVK, D8VK and vkd3d-proton..."
    box64 wine "$OPT_DIR/Resources64/Run if you will install on top of WineD3D.bat"
    box64 wine "$OPT_DIR/Resources64/DXVK2.3/DXVK2.3.bat"

    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12core /d native /f

    cp "$OPT_DIR/Resources/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/syswow64/"
    cp "$OPT_DIR/Resources64/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/system32/"

    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O winetricks &>/dev/null
    chmod +x box64droid winetricks
    mv winetricks "$PREFIX/bin/"

else
  echo "Arquivo instalado."
fi


export PATH="$GLIBC_PREFIX/bin:$PATH"

box64 winetricks vcrun2019 corefonts

echo "Done!"


# 8) Limpar tela e iniciar serviços
clear
unset LD_PRELOAD


# Matar processos existentes que podem interferir
echo "Matando processos antigos..."
box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true
pkill -f "python -m http.server" || true
pkill -f termux-x11
pkill -f "busybox"

# Reiniciar serviços necessários
echo "Iniciando Termux-X11..."
export DISPLAY=:0
termux-x11 :0 &>/dev/null &
sleep 3

echo "Iniciando PulseAudio..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null
sleep 1




rm -f "$HOME/box64.log"
mkdir -p "$HOME_DIR/http_logs"
ln -sf "$HOME/box64.log" "$HOME/http_logs/box64.log"
ln -sf "$CONFIG_DIR/Box64Droid.conf" "$HOME_DIR/http_logs/Box64Droid.conf"
ln -sf "$CONFIG_DIR/DXVK_D8VK.conf" "$HOME_DIR/http_logs/DXVK_D8VK.conf"
ln -sf "$CONFIG_DIR/DXVK_D8VK_HUD.conf" "$HOME_DIR/http_logs/DXVK_D8VK_HUD.conf"

python -m http.server 8081 --bind 0.0.0.0 --directory "$HOME/http_logs" &

IP_ADDRESS=$(ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed -n '2p')
echo "Iniciando servidor HTTP na porta 8081 em http://$IP_ADDRESS:8081/box64.log"

# Verificar se a inicialização do X11 foi bem-sucedida
am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null
sleep 3  # Aguardar X11 iniciar


echo "Iniciando o jogo..."
cd "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/" || {
  echo "Erro: Não foi possível acessar o diretório do jogo!"
  exit 1
}

#taskset -c 4-7 box64 wine explorer /desktop=shell,800x600 $PREFIX/glibc/opt/autostart.bat &
# Lançar o jogo com parâmetros otimizados
box64 wine BorderlandsGOTY.exe /desktop=shell,800x600 > "$HOME/box64.log" 2>&1 &

# Aguardar por tecla para encerrar
echo "Pressione qualquer tecla para encerrar o jogo e limpar os processos"
read -n1
box64 wineserver -k
pkill -f "python -m http.server"
pkill -f termux-x11
pkill -f "busybox"