
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
GLIBC_PREFIX="$PREFIX/glibc"
OPT_DIR="$GLIBC_PREFIX/opt"
BIN_DIR="$GLIBC_PREFIX/bin"
HOME_DIR=${HOME:-/data/data/com.termux/files/home}
unset LD_PRELOAD
export GLIBC_PREFIX
export PATH="$GLIBC_PREFIX/bin:$PATH"
export PATH="$PREFIX/glibc/bin:$PATH"

echo "Matando processos antigos..."
pkill -f "python -m http.server" || true
box64 wineserver -k &>/dev/null
pkill -f pulseaudio   || true
pkill -f 'app_process / com.termux.x11' || true
pkill -f termux-x11
pkill -f "busybox"
kill -9 $(pgrep -f "termux.x11")

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

export WINEDEBUG=+err-all,-loaddll,-module
export WINEDLLOVERRIDES="mscoree,mshtml=;wineusb.dll=n,b;winebus.sys=n,b;nsi.sys=n,b"

export BOX64_LOG=0
export BOX64_DYNAREC_LOG=0
export BOX64_SHOWSEGV=1


export DISPLAY=:0
termux-x11 :0 &

pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null

rm -f "$HOME/box64.log"

python -m http.server 8081 --bind 0.0.0.0 --directory "$HOME/http_logs" &

am start -n com.termux.x11/com.termux.x11.MainActivity &

unset LD_PRELOAD
export PATH="$PREFIX/glibc/bin:$PATH"

(
  rm -f "$HOME/box64.log"
  unset LD_PRELOAD
  export PATH="/data/data/com.termux/files/usr/glibc/bin:$PATH"
  box64 wineboot --init
) &> "$HOME/box64.log" &



( unset LD_PRELOAD; export BOX64_BASH=/data/data/com.termux/files/usr/glibc/bin/bash; export PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin:$PATH"; box64 wineboot --init ) &> "$HOME/box64.log" &

rm -f "$HOME/box64.log"
unset LD_PRELOAD;PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin";BOX64_BASH=/data/data/com.termux/files/usr/glibc/bin/bash; box64 wineboot --init&> "$HOME/box64.log" 2>&1 &
unset LD_PRELOAD;box64 wineboot --init &> "$HOME/box64.log" 2>&1 &
#unset LD_PRELOAD;PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin";BOX64_BASH=/data/data/com.termux/files/usr/glibc/bin/bash; box64 wine "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe" &> "$HOME/box64.log" 2>&1 &
