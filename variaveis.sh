#!/data/data/com.termux/files/usr/bin/bash

#curl -s -f -L --retry 3 --connect-timeout 3 --max-time 10 --retry-delay 1 --raw -o variaveis.sh http://192.168.0.12:5500/variaveis.sh && chmod +x variaveis.sh && source ./variaveis.sh


carregar_exports() {
  # padrões caso não estejam definidos
  unset LD_PRELOAD 

  PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
  HOME_DIR=${HOME:-/data/data/com.termux/files/home}
  GLIBC_PREFIX="$PREFIX/glibc"
  OPT_DIR="$GLIBC_PREFIX/opt"

  # vars de PATH
  export PATH="$GLIBC_PREFIX/bin:$PREFIX/bin:$PATH"

  # prefixos e bibliotecas
  export GLIBC_PREFIX
  export BOX86_ENV='LD_LIBRARY_PATH=$PREFIX/glibc/lib32'
  export BOX64_PATH="$OPT_DIR/wine/bin"
  export BOX64_LD_LIBRARY_PATH="$OPT_DIR/wine/lib/wine/i386-unix:$OPT_DIR/wine/lib/wine/x86_64-unix:$GLIBC_PREFIX/lib/x86_64-linux-gnu"
  export LIBGL_DRIVERS_PATH="$GLIBC_PREFIX/lib32/dri:$GLIBC_PREFIX/lib/dri"
  export VK_ICD_FILENAMES="$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_icd.aarch64.json:$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_icd.armhf.json"

  # display e áudio
  export DISPLAY=":0"
  export PULSE_SERVER="127.0.0.1"
  export PULSE_LATENCY_MSEC="60"

  # mesa/zink/vkd3d
  export MESA_LOADER_DRIVER_OVERRIDE="zink"
  export MESA_NO_ERROR="1"
  export MESA_VK_WSI_PRESENT_MODE="mailbox"
  export ZINK_DESCRIPTORS="lazy"
  export ZINK_CONTEXT_THREADED="false"
  export ZINK_DEBUG="compact"
  export TU_DEBUG="noconform"
  export MANGOHUD="0"
  export VKD3D_FEATURE_LEVEL="12_0"

  # DXVK/D8VK
  export DXVK_CONFIG_FILE="$OPT_DIR/DXVK_D8VK.conf"
  export DXVK_HUD="fps,version,devinfo,gpuload"

  # fontes e HUD
  export FONTCONFIG_PATH="$PREFIX/etc/fonts"
  export GALLIUM_HUD="simple,fps"

  # Wine
  export WINEESYNC="0"
  export WINEESYNC_TERMUX="0"
  export WINEDEBUG="fixme-all,warn+all,err+all,warn-font,warn-keyboard"
  export WINEDLLOVERRIDES="wineusb.dll=n,b;winebus.sys=n,b;nsi.sys=n,b"

  # logs do Box64
  export BOX64_LOG="0"
  export BOX64_DYNAREC_LOG="0"
  export BOX64_SHOWSEGV="1"

  # binários alternativos do Bash para Box64/Box86
  export BOX64_BASH="$GLIBC_PREFIX/opt/box64_bash"
  export BOX86_BASH="$GLIBC_PREFIX/opt/box86_bash"

  # flags de dynarec Box64
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

  # flags de dynarec Box86
  export BOX86_DYNAREC_BIGBLOCK="3"
  export BOX86_ALLOWMISSINGLIBS="1"
  export BOX86_DYNAREC_STRONGMEM="1"
  export BOX86_DYNAREC_X87DOUBLE="0"
  export BOX86_DYNAREC_FASTNAN="0"
  export BOX86_DYNAREC_FASTROUND="1"
  export BOX86_DYNAREC_SAFEFLAGS="2"
  export BOX86_DYNAREC_BLEEDING_EDGE="1"
  export BOX86_DYNAREC_CALLRET="0"
  export BOX86_FUTEX_WAITV="0"

  # sobrescreve BOX64_BASH para o shell correto
  export BOX64_BASH="$GLIBC_PREFIX/bin/bash"
  echo $GLIBC_PREFIX
  echo "Variaveis carregadas com sucesso!"
}

export -f carregar_exports