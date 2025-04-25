import os, time, shutil, sys

os.system("ln -s $PREFIX/glibc/opt/wine/bin/wine $PREFIX/glibc/bin/wine")
os.system("ln -s $PREFIX/glibc/opt/wine/bin/wine64 $PREFIX/glibc/bin/wine64")
os.system("ln -s $PREFIX/glibc/opt/wine/bin/wineserver $PREFIX/glibc/bin/wineserver")
os.system("ln -s $PREFIX/glibc/opt/wine/bin/wineboot $PREFIX/glibc/bin/wineboot")
os.system("ln -s $PREFIX/glibc/opt/wine/bin/winecfg $PREFIX/glibc/bin/winecfg")


if not os.path.exists("/data/data/com.termux/files/usr/glibc/opt/wine"):  
    print("Downloading Wine 9.13 (WoW64)...")
    print("")  
    os.system("wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/wine-9.13-glibc-amd64-wow64.tar.xz")
    print("")
    print("Unpacking Wine 9.13 (WoW64)...")
    os.system("tar -xf wine-9.13-glibc-amd64-wow64.tar.xz -C $PREFIX/glibc/opt")
    os.system("mv $PREFIX/glibc/opt/wine-git-8d25995-exp-wow64-amd64 $PREFIX/glibc/opt/wine")

os.system(r"cd $PREFIX/glibc/opt/wine/bin/; unset LD_PRELOAD; export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc; export PATH=$GLIBC_PREFIX/bin:$PATH; cd ~/; git clone https://github.com/ptitSeb/box64; cd ~/box64; sed -i 's/\/usr/\/data\/data\/com.termux\/files\/usr\/glibc/g' CMakeLists.txt; sed -i 's/\/etc/\/data\/data\/com.termux\/files\/usr\/glibc\/etc/g' CMakeLists.txt; mkdir build; cd build; cmake --install-prefix $PREFIX/glibc .. -DARM_DYNAREC=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBAD_SIGNAL=ON -DSD845=ON; make -j8; make install; rm -rf ~/box64; cd ~/")
os.system("export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc")
os.system("export PATH=$GLIBC_PREFIX/bin:$PATH")           
os.system("box64 wineserver -k &>/dev/null")
os.system("pkill -f pulseaudio && pkill -f 'app_process / com.termux.x11'")
    

config_folder = "/sdcard/Box64Droid (native)/"
box64droid_config = config_folder + "Box64Droid.conf"
dxvk_config = config_folder + "DXVK_D8VK.conf"
dxvk_config_hud =  config_folder + "DXVK_D8VK_HUD.conf"
print("Checking configuration...")
if not os.path.exists(config_folder):
    os.mkdir(config_folder)
if not os.path.exists(box64droid_config):
    shutil.copyfile("/data/data/com.termux/files/usr/glibc/opt/Box64Droid.conf", box64droid_config)
if not os.path.exists(dxvk_config):
    shutil.copyfile("/data/data/com.termux/files/usr/glibc/opt/DXVK_D8VK.conf", dxvk_config)
if not os.path.exists(dxvk_config_hud):
    shutil.copyfile("/data/data/com.termux/files/usr/glibc/opt/DXVK_D8VK_HUD.conf", dxvk_config_hud)

if not os.path.exists("/data/data/com.termux/files/home/.wine"):
    print("Wine prefix not found! Creating...")
    os.system('WINEDLLOVERRIDES="mscoree=" box64 wineboot &>/dev/null')
    os.system('cp -r $PREFIX/glibc/opt/Shortcuts/* "$HOME/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu"')
    os.system("rm $HOME/.wine/dosdevices/z: && rm $HOME/.wine/dosdevices/d: &>/dev/null")
    os.system("ln -s /sdcard/Download $HOME/.wine/dosdevices/d: &>/dev/null && ln -s /sdcard $HOME/.wine/dosdevices/e: &>/dev/null && ln -s /data/data/com.termux/files $HOME/.wine/dosdevices/z:")
    print("Installing DXVK, D8VK and vkd3d-proton...")
    os.system(r'box64 wine "$PREFIX/glibc/opt/Resources64/Run if you will install on top of WineD3D.bat" &>/dev/null && box64 wine "$PREFIX/glibc/opt/Resources64/DXVK2.3/DXVK2.3.bat" &>/dev/null')
    os.system(r'box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12 /d native /f &>/dev/null && box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12core /d native /f &>/dev/null')
    os.system("cp $PREFIX/glibc/opt/Resources/vkd3d-proton/* $HOME/.wine/drive_c/windows/syswow64 && cp $PREFIX/glibc/opt/Resources64/vkd3d-proton/* $HOME/.wine/drive_c/windows/system32")
    print("Done!")

os.system("clear")
if "LD_PRELOAD" in os.environ:
    del os.environ["LD_PRELOAD"]
print("Starting Termux-X11...")
os.system("termux-x11 :0 &>/dev/null &")
print("Starting PulseAudio...")
os.system('pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null')

exec(open('/sdcard/Box64Droid (native)/Box64Droid.conf').read())
exec(open('/sdcard/Box64Droid (native)/DXVK_D8VK_HUD.conf').read())

os.system("taskset -c 4-7 box64 wine explorer /desktop=shell,800x600 $PREFIX/glibc/opt/autostart.bat &>/dev/null &")
os.system("am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null")

