#!/data/data/com.termux/files/usr/bin/bash


#rm -f instalador.sh && curl -s -f -L --retry 3 --connect-timeout 3 --max-time 10 --retry-delay 1 --raw -o instalador.sh https://raw.githubusercontent.com/mateusoro/box64simples/refs/heads/main/instalador.sh && chmod +x instalador.sh && ./instalador.sh
#rm -f instalador.sh && curl -s -f -L --retry 3 --connect-timeout 3 --max-time 10 --retry-delay 1 --raw -o instalador.sh http://192.168.0.12:5500/instalador.sh && chmod +x instalador.sh && ./instalador.sh

#wget -O ./box64.log http://192.168.0.21:8081/box64.log


echo "Iniciando3"
whoami
#ssh u0_a499@192.168.0.18 -p 8022

curl -s -f -L --raw -o variaveis.sh http://192.168.0.12:5500/variaveis.sh && chmod +x variaveis.sh && source ./variaveis.sh

echo "Instalando dependencias0"
echo ""

# Verificar se o armazenamento já está montado e acessível
#termux-setup-storage

#termux-wake-lock

carregar_exports

rm -f "$HOME/box64.log"

apt-get update
apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade
apt install python -y
pkg install x11-repo glibc-repo -y
pkg update
pkg install file glibc-runner libandroid-sysv-semaphore libandroid-spawn cmake make clang busybox -y
pkg install openssh pulseaudio iproute2 wget glibc git xkeyboard-config freetype fontconfig libpng xorg-xrandr -y
pkg install termux-x11-nightly termux-am zenity which bash curl sed cabextract -y

echo "Instalando Glibc"
echo ""

if [ ! -d "$PREFIX/glibc" ]; then
  wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/glibc-prefix.tar.xz
  tar -xJf glibc-prefix.tar.xz -C $PREFIX/
  mv "$PREFIX/glibc-prefix" "$PREFIX/glibc"
else
  echo "Glibc já instalado. Pulando a instalação."
fi



# 3) Compilar o box64 no prefixo glibc
carregar_exports

if [ ! -e "$GLIBC_PREFIX/bin/box64" ]; then
  cd "$HOME_DIR"
  git clone https://github.com/ptitSeb/box64 box64-src
  cd box64-src
  sed -i 's/\/usr/\/data\/data\/com.termux\/files\/usr\/glibc/g' CMakeLists.txt
  sed -i 's/\/etc/\/data\/data\/com.termux\/files\/usr\/glibc\/etc/g' CMakeLists.txt
  # Esta opção modifica diretamente a definição do TERMUX_PATH
  sed -i 's/set(TERMUX_PATH "\/data\/data\/com.termux\/files")/set(TERMUX_PATH "")/g' CMakeLists.txt
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX="/data/data/com.termux/files/usr/glibc/" -DTERMUX=ON -DARM_DYNAREC=ON -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=RelWithDebInfo -DSD8G2=ON -DBAD_SIGNAL=ON -DGLES=ON -DVULKAN=ON -DARM64_DYNAREC_PASS=ON -DARM64_DYNAREC_BIGBLOCK=ON
  make -j8 && make install
  cd "$HOME_DIR"
  rm -rf box64-src
  mkdir -p /data/data/com.termux/files/usr/glibc/
  cp -a /data/data/com.termux/files/data/data/com.termux/files/usr/glibc/* /data/data/com.termux/files/usr/glibc/
else
  echo "Box64 já compilado. Pulando a compilação."
fi

# 4) Atualizar variáveis de ambiente para esta sessão
carregar_exports

# 5) Reiniciar wineserver (silencioso) e matar pulseaudio/X11
box64 wineserver -k #&>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true
pkill -f sshd   || true

echo "Matando qualquer servidor HTTP existente na porta 8081..."
pkill -f "python -m http.server 8081" || true


# 7) Criar prefixo Wine se não existir

#instalacao limpa
#rm -rf wine-9.13-glibc-amd64-wow64.tar.xz

echo "Wine 9.13 (WoW64)..."
echo ""
if [ ! -f wine-9.13-glibc-amd64-wow64.tar.xz ]; then

    carregar_exports
    PREFIX_PATH="/data/data/com.termux/files/home/.wine"
    echo "Removing previous Wine prefix..."
    rm -rf "$PREFIX_PATH"
    rm -rf "/data/data/com.termux/files/usr/glibc/opt/wine"
    wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/wine-9.13-glibc-amd64-wow64.tar.xz
    echo ""
    echo "Unpacking Wine 9.13 (WoW64)..."
    tar -xf wine-9.13-glibc-amd64-wow64.tar.xz -C "$PREFIX/glibc/opt"
    mv "$PREFIX/glibc/opt/wine-git-8d25995-exp-wow64-amd64" "$PREFIX/glibc/opt/wine"
    
    rm -f "$PREFIX/glibc/bin/"{wine,wine64,wineserver,wineboot,winecfg}
    ln -sf "$PREFIX/glibc/opt/wine/bin/wine" "$PREFIX/glibc/bin/wine"
    ln -sf "$PREFIX/glibc/opt/wine/bin/wine64" "$PREFIX/glibc/bin/wine64"
    ln -sf "$PREFIX/glibc/opt/wine/bin/wineserver" "$PREFIX/glibc/bin/wineserver"
    ln -sf "$PREFIX/glibc/opt/wine/bin/wineboot" "$PREFIX/glibc/bin/wineboot"
    ln -sf "$PREFIX/glibc/opt/wine/bin/winecfg" "$PREFIX/glibc/bin/winecfg"
    
    carregar_exports

    echo "Wine prefix! Creating..."
    echo "Pressione para iniciar o boot"
    read -n1
    box64 wineboot --init
    echo "boot finalizado"
    read -n1

    cp -r "$OPT_DIR/Shortcuts/"* "$HOME_DIR/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/"

    rm -f "$HOME_DIR/.wine/dosdevices/z:" "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /sdcard/Download "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /data/data/com.termux/files "$HOME_DIR/.wine/dosdevices/z:" || true

    echo "Pressione qualquer tecla para continuar"
    read -n1
    echo "Installing DXVK, D8VK and vkd3d-proton..."
    box64 wine "$OPT_DIR/Resources64/Run if you will install on top of WineD3D.bat" 
    echo "Pressione qualquer tecla para continuar"
    read -n1
    box64 wine "$OPT_DIR/Resources64/DXVK2.3/DXVK2.3.bat"
    echo "Pressione qualquer tecla para continuar"
    read -n1

    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12core /d native /f
    echo "Pressione qualquer tecla para continuar"
    read -n1

    cp "$OPT_DIR/Resources/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/syswow64/"
    cp "$OPT_DIR/Resources64/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/system32/"

    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O winetricks &>/dev/null
    chmod +x winetricks
    mv winetricks "$GLIBC_PREFIX/bin"

else
  echo "Wine instalado."
fi

#export PATH="$PREFIX/glibc/bin:$PATH"; unset LD_PRELOAD
#box64 winetricks vcrun2019 corefonts

instalar_dxvk() {
    # Verificar se o parâmetro foi fornecido
    if [ -z "$1" ]; then
        echo "Uso: instalar_dxvk <versão>"
        echo "Exemplo: instalar_dxvk 2.3"
        return 1
    fi

    # Carregar variáveis de ambiente necessárias
    carregar_exports
    
    VERSAO=$1
    TEMP_DIR="$HOME_DIR/dxvk_temp"
    
    echo "Instalando DXVK versão $VERSAO..."
    
    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Baixar a versão especificada do DXVK
    echo "Baixando DXVK $VERSAO..."
    wget -q --show-progress "https://github.com/doitsujin/dxvk/releases/download/v$VERSAO/dxvk-$VERSAO.tar.gz"
    
    if [ ! -f "dxvk-$VERSAO.tar.gz" ]; then
        echo "Erro: Não foi possível baixar DXVK $VERSAO"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Extrair o arquivo
    echo "Extraindo DXVK $VERSAO..."
    tar -xzf "dxvk-$VERSAO.tar.gz"
    
    if [ ! -d "dxvk-$VERSAO" ]; then
        echo "Erro: Não foi possível extrair DXVK $VERSAO"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Copiar arquivos para o prefixo Wine
    echo "Instalando DXVK $VERSAO no prefixo Wine..."
    
    # DLLs de 64 bits para system32
    cp "dxvk-$VERSAO/x64/"*.dll "$HOME_DIR/.wine/drive_c/windows/system32/"
    
    # DLLs de 32 bits para syswow64
    cp "dxvk-$VERSAO/x32/"*.dll "$HOME_DIR/.wine/drive_c/windows/syswow64/"
    
    # Adicionar entradas no registro para usar as DLLs nativas
    echo "Configurando registro do Wine..."
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d9 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d10core /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d11 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12core /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v dxgi /d native /f
    
    # Limpeza
    echo "Limpando arquivos temporários..."
    cd "$HOME_DIR"
    rm -rf "$TEMP_DIR"
    
    echo "DXVK $VERSAO instalado com sucesso!"
    return 0
}


echo "Done!"

carregar_exports

instalar_dxvk 1.10.3

# Matar processos existentes que podem interferir
echo "Matando processos antigos..."
pkill -f "python -m http.server" || true
box64 wineserver -k
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true
pkill -f termux-x11
pkill -f "busybox"

# Reiniciar serviços necessários

echo "Iniciando Termux-X11..."
# Forçar orientação landscape no Termux-X11
carregar_exports

sshd &>/dev/null

termux-x11 :0 &
#sleep 3
am broadcast -a com.termux.x11.SET_ORIENTATION --ez landscape true

echo "Iniciando PulseAudio..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null
sleep 1

mkdir -p "$HOME_DIR/http_logs"
ln -sf "$HOME/box64.log" "$HOME/http_logs/box64.log"
ln -sf "$CONFIG_DIR/Box64Droid.conf" "$HOME_DIR/http_logs/Box64Droid.conf"
ln -sf "$CONFIG_DIR/DXVK_D8VK.conf" "$HOME_DIR/http_logs/DXVK_D8VK.conf"
ln -sf "$CONFIG_DIR/DXVK_D8VK_HUD.conf" "$HOME_DIR/http_logs/DXVK_D8VK_HUD.conf"
cp $PREFIX/glibc/opt/autostart.bat "$HOME/http_logs/autostart.bat"

python -m http.server 8081 --bind 0.0.0.0 --directory "$HOME/http_logs" &

IP_ADDRESS=$(ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed -n '2p')
echo "Iniciando servidor HTTP na porta 8081 em http://$IP_ADDRESS:8081/box64.log"

# Verificar se a inicialização do X11 foi bem-sucedida
#am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null
#sleep 3  # Aguardar X11 iniciar


echo "Iniciando o jogo..."
cd "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/" || {
  #
  echo "Erro: Não foi possível acessar o diretório do jogo!"
  exit 1
}

#taskset -c 4-7 box64 wine explorer /desktop=shell,800x600 $PREFIX/glibc/opt/autostart.bat &
# Lançar o jogo com parâmetros otimizados BorderlandsGOTY.exe


(
carregar_exports
echo "Baixando Microsoft Visual C++ 2005 SP1 Redistributable (x64)..."
curl -s -f -L --raw -o vcredist_x64.exe "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe"
echo "Instalando vcrun2005 x64..."
carregar_exports
ls vcredist_x64.exe
box64 wine vcredist_x64.exe /Q

#box64 winetricks -q --self-update
#box64 winetricks -q vcrun2005 vcrun2008 dotnet20 d3dx9 d3dcompiler_43 physx
#box64 wine explorer /desktop=shell,800x600 "$PREFIX/glibc/opt/autostart.bat"
) > "$HOME/box64.log" 2>&1 &

(

carregar_exports
echo "iniciando o jogo..."
box64 wine /sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe

) > "$HOME/box64.log" 2>&1 &


#box64 wine /sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe> "$HOME/box64.log" 2>&1 &

#unset LD_PRELOAD;PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin" box64 wineboot --init &> "$HOME/box64.log" 2>&1 &
#curl -s -f -L --raw -o instalador.sh http://192.168.0.12:5500/instalador.sh && chmod +x instalador.sh && ./instalador.sh

#box64 wine "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe"