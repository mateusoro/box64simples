#!/bin/bash

# Arquivo de funções - funcoes.sh
# Hospede este arquivo em 192.168.0.11:5500/funcoes.sh

info_sistema() {
    echo "=== INFORMAÇÕES DO SISTEMA ==="
    echo "Arquitetura: $(uname -m)"
    echo "Kernel: $(uname -r)"
    echo "Versão Android: $(getprop ro.build.version.release)"
    echo "Modelo do dispositivo: $(getprop ro.product.model)"
    echo "Espaço em disco:"
    df -h $HOME
    echo "Memória:"
    free -h
    
    echo ""
    echo "=== STATUS DOS COMPONENTES ==="
    
    # Verifica GLIBC
    if [ -d "/data/data/com.termux/files/usr/glibc" ]; then
        echo "✓ GLIBC: Instalado em /data/data/com.termux/files/usr/glibc"
    else
        echo "✗ GLIBC: Não instalado"
    fi
    
    # Verifica Box64
    if [ -f "/data/data/com.termux/files/usr/glibc/bin/box64" ]; then
        echo "✓ Box64: Instalado em /data/data/com.termux/files/usr/glibc/bin/box64"
    else
        echo "✗ Box64: Não instalado"
    fi
    
    echo "=============================="
}

instalar_winetricks() {
    echo "Instalando Winetricks..."
    
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O winetricks &>/dev/null
    chmod +x winetricks
    mv winetricks "$GLIBC_PREFIX/bin"
    
    echo "Winetricks instalado!"
}

instalar_turnip_custom() {
    echo "Instalando driver Turnip customizado..."
    
    # Define variáveis
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    
    # URL correto do driver
    DRIVER_URL="https://github.com/K11MCH1/WinlatorTurnipDrivers/releases/download/winlator_r9/libvulkan_freedreno.so"
    TEMP_DIR="$HOME_DIR/turnip_temp"
    
    echo "📁 Criando diretório temporário..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo "⬇️ Baixando driver Turnip customizado..."
    
    if wget --user-agent="Mozilla/5.0" -q --show-progress "$DRIVER_URL" -O libvulkan_freedreno.so; then
        echo "✅ Download concluído"
    elif curl -L -H "User-Agent: Mozilla/5.0" "$DRIVER_URL" -o libvulkan_freedreno.so; then
        echo "✅ Download concluído"
    else
        echo "❌ Falha no download. Verifique conectividade"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Verifica arquivo baixado
    if [ ! -f "libvulkan_freedreno.so" ] || [ $(stat -c%s "libvulkan_freedreno.so") -lt 100000 ]; then
        echo "❌ Arquivo inválido ou muito pequeno"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo "📥 Instalando driver no ambiente glibc..."
    
    # Cria diretórios necessários
    mkdir -p "$GLIBC_PREFIX/lib/aarch64-linux-gnu"
    mkdir -p "$GLIBC_PREFIX/share/vulkan/icd.d"
    
    # Backup do driver anterior se existir
    if [ -f "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ]; then
        echo "💾 Fazendo backup do driver anterior..."
        mv "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
           "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Instala novo driver
    cp libvulkan_freedreno.so "$GLIBC_PREFIX/lib/aarch64-linux-gnu/" || {
        echo "❌ Erro: Falha ao copiar driver"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    # Define permissões
    chmod 755 "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
    
    echo "⚙️ Configurando ICD Vulkan..."
    
    # Cria arquivo ICD customizado
    cat > "$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json" << EOF
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so",
        "api_version": "1.3.250"
    }
}
EOF
    
    
    # Limpeza
    echo "🧹 Limpando arquivos temporários..."
    cd "$HOME_DIR"
    rm -rf "$TEMP_DIR"
    
    echo ""
    echo "✅ Driver Turnip customizado instalado com sucesso!"
    echo "📁 Local: $GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
    echo "📄 ICD: $GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json"
    echo ""
     
    return 0
}

iniciar_jogo() {

    carregar_exports
    echo "Preparando para iniciar o jogo..."
    parar_servidores
    sleep 3
    iniciar_servidores
    # Execute em background com log
    (
        
        carregar_exports
        echo "Iniciando o jogo..."
        am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null
        box64 wine "/sdcard/Download/Jogos Winlator/Borderlands Game of the Year Enhanced/Binaries/Win64/BorderlandsGOTY.exe"
        
    
    ) 2>&1 | grep -v -E "(warn:module:find_builtin_dll|warn:system:find_adapter_device_by_id)" > "$HOME/box64.log" &
    
    echo "Jogo iniciado em background. Log: $HOME/box64.log"
}
testar_turnip_custom() {
    echo "🔍 TESTANDO DRIVER TURNIP CUSTOMIZADO"
    echo "====================================="
    
    # Variáveis
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    RESULTADO_TESTE=$HOME/box64.log
    
    # Limpa resultado anterior
    > "$RESULTADO_TESTE"
    
    # Função para log
    log_test() {
        echo "$@" | tee -a "$RESULTADO_TESTE"
    }
    
    log_test "Data do teste: $(date)"
    log_test ""
    
    # 1. Verificar se o driver existe
    log_test "1️⃣ VERIFICANDO ARQUIVOS DO DRIVER:"
    if [ -f "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ]; then
        log_test "✅ Driver encontrado"
        log_test "   Tamanho: $(ls -lh "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" | awk '{print $5}')"
        log_test "   Permissões: $(ls -l "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" | awk '{print $1}')"
    else
        log_test "❌ Driver NÃO encontrado em $GLIBC_PREFIX/lib/aarch64-linux-gnu/"
        return 1
    fi
    
    # 2. Verificar ICD JSON
    log_test ""
    log_test "2️⃣ VERIFICANDO ARQUIVO ICD:"
    if [ -f "$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json" ]; then
        log_test "✅ ICD encontrado"
        log_test "   Conteúdo:"
        cat "$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json" | tee -a "$RESULTADO_TESTE"
    else
        log_test "❌ ICD NÃO encontrado"
    fi
    
    # 3. Verificar variáveis de ambiente
    log_test ""
    log_test "3️⃣ CONFIGURANDO VARIÁVEIS DE AMBIENTE:"
    
    # Carrega variáveis essenciais
    export VK_ICD_FILENAMES="$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json"
    export VK_LOADER_DEBUG=all
    export DISPLAY=:0
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export MESA_NO_ERROR=1
    export MESA_GL_VERSION_OVERRIDE=4.3COMPAT
    export MESA_GLES_VERSION_OVERRIDE=3.2
    
    log_test "VK_ICD_FILENAMES=$VK_ICD_FILENAMES"
    log_test "DISPLAY=$DISPLAY"
    log_test "MESA_LOADER_DRIVER_OVERRIDE=$MESA_LOADER_DRIVER_OVERRIDE"
    
    # 4. Teste com vulkaninfo
    log_test ""
    log_test "4️⃣ TESTANDO VULKANINFO:"
    if command -v vulkaninfo &>/dev/null; then
        # Captura saída do vulkaninfo
        VULKAN_OUTPUT=$(vulkaninfo 2>&1)
        
        # Verifica se detectou o driver
        if echo "$VULKAN_OUTPUT" | grep -q "freedreno"; then
            log_test "✅ Driver Turnip detectado!"
            
            # Verifica extensões críticas
            log_test ""
            log_test "Extensões Vulkan:"
            if echo "$VULKAN_OUTPUT" | grep -q "VK_KHR_surface"; then
                log_test "✅ VK_KHR_surface: SUPORTADA"
            else
                log_test "❌ VK_KHR_surface: NÃO SUPORTADA"
            fi
            
            if echo "$VULKAN_OUTPUT" | grep -q "VK_KHR_xlib_surface"; then
                log_test "✅ VK_KHR_xlib_surface: SUPORTADA"
            else
                log_test "❌ VK_KHR_xlib_surface: NÃO SUPORTADA"
            fi
            
            if echo "$VULKAN_OUTPUT" | grep -q "VK_KHR_display"; then
                log_test "✅ VK_KHR_display: SUPORTADA"
            else
                log_test "❌ VK_KHR_display: NÃO SUPORTADA"
            fi
            
            # Mostra versão do Vulkan
            VULKAN_VERSION=$(echo "$VULKAN_OUTPUT" | grep -o "Vulkan Instance Version: [0-9.]*" | head -1)
            log_test ""
            log_test "Versão: $VULKAN_VERSION"
            
            # Mostra informações do GPU
            GPU_INFO=$(echo "$VULKAN_OUTPUT" | grep -A2 "deviceName" | head -3)
            log_test ""
            log_test "GPU Info:"
            echo "$GPU_INFO" | tee -a "$RESULTADO_TESTE"
            
        else
            log_test "❌ Driver Turnip NÃO foi detectado pelo vulkaninfo"
            log_test "Saída do erro:"
            echo "$VULKAN_OUTPUT" | grep -E "error|Error|ERROR|failed|Failed" | head -10 | tee -a "$RESULTADO_TESTE"
        fi
    else
        log_test "❌ vulkaninfo não instalado. Instale com: pkg install vulkan-tools"
    fi
    
    # 5. Teste com vkcube
    log_test ""
    log_test "5️⃣ TESTANDO VKCUBE:"
    
    # Verifica se X11 está rodando
    if ! pgrep -f "termux-x11" >/dev/null && ! pgrep -f "Xvfb" >/dev/null; then
        log_test "⚠️ X11 não está rodando. Iniciando Xvfb para teste..."
        Xvfb :0 -screen 0 1024x768x24 &
        XVFB_PID=$!
        sleep 2
    fi
    
    if command -v vkcube &>/dev/null; then
        log_test "Executando vkcube por 3 segundos..."
        timeout 3 vkcube 2>&1 | tee -a "$RESULTADO_TESTE" &
        VKCUBE_PID=$!
        sleep 3
        
        if kill -0 $VKCUBE_PID 2>/dev/null; then
            kill $VKCUBE_PID 2>/dev/null
            log_test "✅ vkcube executou sem erros aparentes"
        else
            log_test "❌ vkcube falhou ao executar"
        fi
    else
        log_test "❌ vkcube não instalado"
    fi
    
    # Para Xvfb se foi iniciado
    [ ! -z "$XVFB_PID" ] && kill $XVFB_PID 2>/dev/null
    
    # 6. Teste com glmark2 (se disponível)
    log_test ""
    log_test "6️⃣ TESTANDO GLMARK2 (se disponível):"
    if command -v glmark2 &>/dev/null; then
        log_test "Executando glmark2 com virgl..."
        GALLIUM_DRIVER=virpipe timeout 5 glmark2 --off-screen 2>&1 | grep -E "Score:|FPS:" | head -5 | tee -a "$RESULTADO_TESTE"
    else
        log_test "glmark2 não instalado (opcional)"
    fi
    
    # 7. Verificar se consegue criar contexto Vulkan via Python
    log_test ""
    log_test "7️⃣ TESTE PYTHON VULKAN (se disponível):"
    if command -v python3 &>/dev/null; then
        python3 -c "
try:
    import ctypes
    vk = ctypes.CDLL('libvulkan.so.1')
    print('✅ libvulkan.so.1 carregada com sucesso')
except Exception as e:
    print(f'❌ Erro ao carregar libvulkan: {e}')
" 2>&1 | tee -a "$RESULTADO_TESTE"
    fi
    
    # 8. Verificar compatibilidade do dispositivo
    log_test ""
    log_test "8️⃣ INFORMAÇÕES DO DISPOSITIVO:"
    log_test "Modelo: $(getprop ro.product.model)"
    log_test "GPU: $(getprop ro.hardware.vulkan)"
    log_test "Android: $(getprop ro.build.version.release)"
    log_test "Kernel: $(uname -r)"
    
    # Verifica se é Adreno 6xx/7xx
    GPU_MODEL=$(getprop ro.hardware.vulkan)
    if [[ "$GPU_MODEL" =~ adreno6|adreno7 ]]; then
        log_test "✅ GPU Adreno 6xx/7xx detectada - compatível com Turnip"
    else
        log_test "⚠️ GPU pode não ser totalmente compatível com Turnip"
    fi
    
    # 9. Resumo final
    log_test ""
    log_test "9️⃣ RESUMO DO TESTE:"
    log_test "=================="
    
    TOTAL_TESTES=0
    TESTES_OK=0
    
    # Conta resultados
    TESTES_OK=$(grep -c "✅" "$RESULTADO_TESTE")
    TOTAL_TESTES=$(grep -c "❌\|✅" "$RESULTADO_TESTE")
    
    log_test "Testes bem-sucedidos: $TESTES_OK"
    log_test "Total de verificações: $TOTAL_TESTES"
    
    if grep -q "VK_KHR_surface: SUPORTADA" "$RESULTADO_TESTE"; then
        log_test ""
        log_test "🎉 TURNIP ESTÁ FUNCIONANDO! Pode usar com DXVK"
    else
        log_test ""
        log_test "⚠️ TURNIP INSTALADO MAS PRECISA DE AJUSTES"
        log_test ""
        log_test "AÇÕES RECOMENDADAS:"
        log_test "1. Use Zink ao invés de DXVK:"
        log_test "   export MESA_LOADER_DRIVER_OVERRIDE=zink"
        log_test "   unset WINEDLLOVERRIDES"
        log_test ""
        log_test "2. Ou compile Turnip com suporte X11"
        log_test "3. Ou use Box64Droid/Termux-box que já vem configurado"
    fi
    
    log_test ""
    log_test "📄 Resultado completo salvo em: $RESULTADO_TESTE"
    
    # Pergunta se quer ver log detalhado
    echo ""
    read -p "Deseja ver o log detalhado do Vulkan? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        vulkaninfo 2>&1 | less
    fi
    
    return 0
}
iniciar_desktop() {

    carregar_exports
    echo "Preparando para iniciar o jogo..."
    parar_servidores
    sleep 3
    iniciar_servidores
    # Execute em background com log
    (
        
        carregar_exports
        echo "Iniciando o jogo..."
        am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null
        box64 wine explorer /desktop=shell,800x600
        
    
    ) 2>&1 | grep -v -E "(warn:module:find_builtin_dll|warn:system:find_adapter_device_by_id)" > "$HOME/box64.log" &
    
    echo "Jogo iniciado em background. Log: $HOME/box64.log"
}

parar_servidores() {
    echo "Matando processos antigos..."
    
    carregar_exports

    # Para processos Wine
    pkill -f wine || true
    pkill -f wineserver || true 
    killall wine || true
    killall wineserver || true
    
    # Para processos Box64/Box86
    pkill -f box64 || true
    pkill -f box86 || true
    killall box64 || true
    killall box86 || true
    
    # Para outros serviços
    pkill -f "python -m http.server" || true
    pkill -f pulseaudio || true
    pkill -f 'app_process / com.termux.x11' || true
    pkill -f termux-x11 || true
    pkill -f sshd || true
    
    # Força parada Wine
    box64 wineserver -k || true
    
    echo "Servidores parados!"
}

iniciar_servidores() {
    echo "Iniciando servidores..."

    rm -f "$HOME/box64.log"

    # Define variáveis
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    OPT_DIR="$GLIBC_PREFIX/opt"

    # Carrega exports inline
    unset LD_PRELOAD 
    export PATH="$GLIBC_PREFIX/bin:$PREFIX/bin:$PATH"
    export GLIBC_PREFIX
    export BOX64_PATH="$OPT_DIR/wine/bin"
    export BOX64_LD_LIBRARY_PATH="$OPT_DIR/wine/lib/wine/i386-unix:$OPT_DIR/wine/lib/wine/x86_64-unix:$GLIBC_PREFIX/lib/x86_64-linux-gnu"
    export DISPLAY=":0"
    export PULSE_SERVER="127.0.0.1"
    
    # Inicia SSH
    sshd &>/dev/null
    
    # Inicia Termux X11
    termux-x11 :0 &   

    echo "Iniciando PulseAudio..."
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    sleep 1
    
    # Configura servidor HTTP para logs
    mkdir -p "$HOME_DIR/http_logs"
    ln -sf "$HOME/box64.log" "$HOME/http_logs/box64.log"
    python -m http.server 8081 --bind 0.0.0.0 --directory "$HOME/http_logs" &
    
    IP_ADDRESS=$(ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed -n '2p')
    echo "Iniciando servidor HTTP na porta 8081 em http://$IP_ADDRESS:8081/box64.log"
    
    echo "Servidores iniciados!"
}

instalar_dxvk() {
    # Verificar se o parâmetro foi fornecido
    if [ -z "$1" ]; then
        echo "❌ Erro: Uso: instalar_dxvk <versão>"
        echo "Exemplo: instalar_dxvk 2.3"
        return 1
    fi

    # Define variáveis
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    
    VERSAO=$1
    TEMP_DIR="$HOME_DIR/dxvk_temp"
    WINE_SYSTEM32="$HOME_DIR/.wine/drive_c/windows/system32"
    WINE_SYSWOW64="$HOME_DIR/.wine/drive_c/windows/syswow64"
    
    echo "🔧 Instalando DXVK versão $VERSAO..."
    echo "📁 HOME_DIR: $HOME_DIR"
    echo "📁 GLIBC_PREFIX: $GLIBC_PREFIX"
    echo "📁 TEMP_DIR: $TEMP_DIR"
    
    # Verificar se Wine está instalado
    echo "🍷 Verificando instalação do Wine..."
    if [ ! -f "$GLIBC_PREFIX/bin/wine" ]; then
        echo "❌ Erro: Wine não encontrado em $GLIBC_PREFIX/bin/wine"
        return 1
    fi
    echo "✅ Wine encontrado: $GLIBC_PREFIX/bin/wine"
    
    # Verificar se prefix Wine existe
    echo "🍷 Verificando prefix do Wine..."
    if [ ! -d "$HOME_DIR/.wine" ]; then
        echo "❌ Erro: Prefix do Wine não encontrado em $HOME_DIR/.wine"
        echo "Execute primeiro: box64 wineboot --init"
        return 1
    fi
    echo "✅ Prefix Wine encontrado: $HOME_DIR/.wine"
    
    # Verificar diretórios do Windows
    echo "📂 Verificando diretórios do Windows..."
    if [ ! -d "$WINE_SYSTEM32" ]; then
        echo "❌ Erro: Diretório system32 não encontrado: $WINE_SYSTEM32"
        return 1
    fi
    if [ ! -d "$WINE_SYSWOW64" ]; then
        echo "❌ Erro: Diretório syswow64 não encontrado: $WINE_SYSWOW64"
        return 1
    fi
    echo "✅ Diretórios Windows OK"
    
    # Listar DLLs atuais antes da instalação
    echo "📋 DLLs atuais em system32:"
    ls -la "$WINE_SYSTEM32" | grep -E "(d3d|dxgi)" || echo "Nenhuma DLL D3D/DXGI encontrada"
    echo "📋 DLLs atuais em syswow64:"
    ls -la "$WINE_SYSWOW64" | grep -E "(d3d|dxgi)" || echo "Nenhuma DLL D3D/DXGI encontrada"
    
    # Criar diretório temporário
    echo "📁 Criando diretório temporário..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || {
        echo "❌ Erro: Não foi possível acessar $TEMP_DIR"
        return 1
    }
    echo "✅ Diretório temporário criado: $TEMP_DIR"
    
    # Baixar a versão especificada do DXVK
    echo "⬇️ Baixando DXVK $VERSAO..."
    URL="https://github.com/doitsujin/dxvk/releases/download/v$VERSAO/dxvk-$VERSAO.tar.gz"
    echo "🌐 URL: $URL"
    
    wget -q --show-progress "$URL" || {
        echo "❌ Erro: Falha no download do DXVK $VERSAO"
        echo "Verifique se a versão $VERSAO existe em: https://github.com/doitsujin/dxvk/releases"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    if [ ! -f "dxvk-$VERSAO.tar.gz" ]; then
        echo "❌ Erro: Arquivo não foi baixado: dxvk-$VERSAO.tar.gz"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Verificar tamanho do arquivo
    TAMANHO=$(stat -c%s "dxvk-$VERSAO.tar.gz")
    echo "✅ Download concluído. Tamanho: $TAMANHO bytes"
    
    # Extrair o arquivo
    echo "📦 Extraindo DXVK $VERSAO..."
    tar -xzf "dxvk-$VERSAO.tar.gz" || {
        echo "❌ Erro: Falha ao extrair dxvk-$VERSAO.tar.gz"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    if [ ! -d "dxvk-$VERSAO" ]; then
        echo "❌ Erro: Diretório não foi criado: dxvk-$VERSAO"
        echo "📁 Conteúdo atual:"
        ls -la
        rm -rf "$TEMP_DIR"
        return 1
    fi
    echo "✅ Extração concluída"
    
    # Verificar conteúdo extraído
    echo "📋 Conteúdo do DXVK extraído:"
    ls -la "dxvk-$VERSAO/"
    echo "📋 DLLs x64:"
    ls -la "dxvk-$VERSAO/x64/" || echo "❌ Diretório x64 não encontrado"
    echo "📋 DLLs x32:"
    ls -la "dxvk-$VERSAO/x32/" || echo "❌ Diretório x32 não encontrado"
    
    # Verificar se DLLs existem
    X64_DLLS=$(find "dxvk-$VERSAO/x64/" -name "*.dll" 2>/dev/null | wc -l)
    X32_DLLS=$(find "dxvk-$VERSAO/x32/" -name "*.dll" 2>/dev/null | wc -l)
    echo "📊 DLLs encontradas: x64=$X64_DLLS, x32=$X32_DLLS"
    
    if [ "$X64_DLLS" -eq 0 ] || [ "$X32_DLLS" -eq 0 ]; then
        echo "❌ Erro: DLLs não encontradas nos diretórios x64/x32"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Copiar arquivos para o prefixo Wine
    echo "📥 Instalando DXVK $VERSAO no prefixo Wine..."
    
    # Backup das DLLs existentes
    echo "💾 Fazendo backup das DLLs existentes..."
    BACKUP_DIR="$HOME_DIR/dxvk_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR/system32" "$BACKUP_DIR/syswow64"
    
    for dll in d3d9 d3d10core d3d11 d3d12 d3d12core dxgi; do
        [ -f "$WINE_SYSTEM32/${dll}.dll" ] && cp "$WINE_SYSTEM32/${dll}.dll" "$BACKUP_DIR/system32/"
        [ -f "$WINE_SYSWOW64/${dll}.dll" ] && cp "$WINE_SYSWOW64/${dll}.dll" "$BACKUP_DIR/syswow64/"
    done
    echo "✅ Backup salvo em: $BACKUP_DIR"
    
    # DLLs de 64 bits para system32
    echo "📥 Copiando DLLs x64 para system32..."
    cp -v "dxvk-$VERSAO/x64/"*.dll "$WINE_SYSTEM32/" || {
        echo "❌ Erro: Falha ao copiar DLLs x64"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    # DLLs de 32 bits para syswow64
    echo "📥 Copiando DLLs x32 para syswow64..."
    cp -v "dxvk-$VERSAO/x32/"*.dll "$WINE_SYSWOW64/" || {
        echo "❌ Erro: Falha ao copiar DLLs x32"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    # Verificar se DLLs foram copiadas
    echo "🔍 Verificando DLLs instaladas..."
    DLLS_INSTALADAS=0
    for dll in d3d9 d3d10core d3d11 d3d12 d3d12core dxgi; do
        if [ -f "$WINE_SYSTEM32/${dll}.dll" ] && [ -f "$WINE_SYSWOW64/${dll}.dll" ]; then
            echo "✅ ${dll}.dll: OK"
            DLLS_INSTALADAS=$((DLLS_INSTALADAS + 1))
        else
            echo "❌ ${dll}.dll: FALTANDO"
        fi
    done
    
    echo "📊 DLLs instaladas: $DLLS_INSTALADAS/6"
    
    # Configurar registro do Wine
    echo "⚙️ Configurando registro do Wine..."
    
    # Carregar exports primeiro
    export PATH="$GLIBC_PREFIX/bin:$PREFIX/bin:$PATH"
    export BOX64_PATH="$GLIBC_PREFIX/opt/wine/bin"
    export BOX64_LD_LIBRARY_PATH="$GLIBC_PREFIX/opt/wine/lib/wine/i386-unix:$GLIBC_PREFIX/opt/wine/lib/wine/x86_64-unix:$GLIBC_PREFIX/lib/x86_64-linux-gnu"
    
    # Testar Wine primeiro
    echo "🍷 Testando Wine..."
    "$GLIBC_PREFIX/bin/box64" "$GLIBC_PREFIX/bin/wine" --version || {
        echo "❌ Erro: Wine não está funcionando"
        rm -rf "$TEMP_DIR"
        return 1
    }
    echo "✅ Wine funcionando"
    
    # Adicionar entradas no registro
    DLLS_REGISTRY=(d3d9 d3d10core d3d11 d3d12 d3d12core dxgi)
    REGISTRY_OK=0
    
    for dll in "${DLLS_REGISTRY[@]}"; do
        echo "📝 Configurando $dll no registro..."
        if "$GLIBC_PREFIX/bin/box64" "$GLIBC_PREFIX/bin/wine" reg add "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" /v "$dll" /d native /f; then
            echo "✅ $dll: OK"
            REGISTRY_OK=$((REGISTRY_OK + 1))
        else
            echo "❌ $dll: FALHOU"
        fi
    done
    
    echo "📊 Entradas de registro: $REGISTRY_OK/${#DLLS_REGISTRY[@]}"
    
    # Verificar registry
    echo "🔍 Verificando registro..."
    "$GLIBC_PREFIX/bin/box64" "$GLIBC_PREFIX/bin/wine" reg query "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" || {
        echo "❌ Erro ao ler registro"
    }
    
    # Criar arquivo de configuração DXVK
    echo "📄 Criando arquivo de configuração DXVK..."
    cat > "$HOME_DIR/.wine/drive_c/dxvk.conf" << EOF
# DXVK Configuration
dxvk.enableAsync = true
dxvk.hud = fps,version
dxvk.logLevel = info
EOF
    echo "✅ Configuração DXVK criada"
    
    # Limpeza
    echo "🧹 Limpando arquivos temporários..."
    cd "$HOME_DIR"
    rm -rf "$TEMP_DIR"
    
    # Resumo final
    echo ""
    echo "📋 RESUMO DA INSTALAÇÃO:"
    echo "✅ DXVK $VERSAO instalado com sucesso!"
    echo "📁 Backup das DLLs antigas: $BACKUP_DIR"
    echo "📊 DLLs instaladas: $DLLS_INSTALADAS/6"
    echo "📊 Entradas de registro: $REGISTRY_OK/${#DLLS_REGISTRY[@]}"
    echo "📄 Configuração: $HOME_DIR/.wine/drive_c/dxvk.conf"
    
    echo ""
    echo "🔧 Para testar DXVK:"
    echo "export DXVK_HUD=fps,version"
    echo "box64 wine <seu_jogo.exe>"
    
    return 0
}

configurar_wine_gaming() {
    echo "Configurando Wine para Gaming (vkd3d)..."
    
    # Define variáveis
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    OPT_DIR="$GLIBC_PREFIX/opt"
    
    # Copia atalhos para menu iniciar
    cp -r "$OPT_DIR/Shortcuts/"* "$HOME_DIR/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/"
    
    # Remove e recria drives D: e Z:
    rm -f "$HOME_DIR/.wine/dosdevices/z:" "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /sdcard/Download "$HOME_DIR/.wine/dosdevices/d:" || true
    ln -s /data/data/com.termux/files "$HOME_DIR/.wine/dosdevices/z:" || true
    
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12 /d native /f
    box64 wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d12core /d native /f
    
    cp "$OPT_DIR/Resources/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/syswow64/"
    cp "$OPT_DIR/Resources64/vkd3d-proton/"* "$HOME_DIR/.wine/drive_c/windows/system32/"
    
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O winetricks &>/dev/null
    chmod +x winetricks
    mv winetricks "$GLIBC_PREFIX/bin"
    
    echo "Configuração Gaming concluída!"
}

instalar_wine() {
    echo "Instalando Wine 9.13 (WoW64)..."
    

    PREFIX_PATH="/data/data/com.termux/files/home/.wine"
    ARQUIVO="wine-9.13-glibc-amd64-wow64.tar.xz"
    
    echo "Removendo Wine anterior..."
    rm -rf "$PREFIX_PATH"
    rm -rf "/data/data/com.termux/files/usr/glibc/opt/wine"
    
    # Verifica se arquivo já existe
    if [ -f "$ARQUIVO" ]; then
        echo "Arquivo $ARQUIVO já existe, pulando download..."
    else
        echo "Baixando $ARQUIVO..."
        wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/wine-9.13-glibc-amd64-wow64.tar.xz
    fi
    
    echo "Extraindo Wine..."
    tar -xf "$ARQUIVO" -C "/data/data/com.termux/files/usr/glibc/opt"
    mv "/data/data/com.termux/files/usr/glibc/opt/wine-git-8d25995-exp-wow64-amd64" "/data/data/com.termux/files/usr/glibc/opt/wine"
    
    echo "Criando links simbólicos..."
    rm -f "/data/data/com.termux/files/usr/glibc/bin/"{wine,wine64,wineserver,wineboot,winecfg}
    ln -sf "/data/data/com.termux/files/usr/glibc/opt/wine/bin/wine" "/data/data/com.termux/files/usr/glibc/bin/wine"
    ln -sf "/data/data/com.termux/files/usr/glibc/opt/wine/bin/wine64" "/data/data/com.termux/files/usr/glibc/bin/wine64"
    ln -sf "/data/data/com.termux/files/usr/glibc/opt/wine/bin/wineserver" "/data/data/com.termux/files/usr/glibc/bin/wineserver"
    ln -sf "/data/data/com.termux/files/usr/glibc/opt/wine/bin/wineboot" "/data/data/com.termux/files/usr/glibc/bin/wineboot"
    ln -sf "/data/data/com.termux/files/usr/glibc/opt/wine/bin/winecfg" "/data/data/com.termux/files/usr/glibc/bin/winecfg"
    
    echo "Wine instalado!"
}

compilar_box64() {
    echo "Compilando Box64..."
    
    # Define HOME_DIR se não estiver definido
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    
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
    
    echo "Box64 compilado e instalado em /data/data/com.termux/files/usr/glibc/bin/box64"
}

limpar_glibc() {
    echo "Removendo arquivos do GLIBC..."
    
    # Remove arquivo tar
    if [ -f "glibc-prefix.tar.xz" ]; then
        /system/bin/rm -f glibc-prefix.tar.xz
        echo "Arquivo glibc-prefix.tar.xz removido"
    fi
    
    # Remove diretório glibc
    if [ -d "/data/data/com.termux/files/usr/glibc" ]; then
        /system/bin/rm -rf "/data/data/com.termux/files/usr/glibc"
        echo "Diretório glibc removido"
    fi
    
    # Remove glibc-prefix se existir
    if [ -d "/data/data/com.termux/files/usr/glibc-prefix" ]; then
        /system/bin/rm -rf "/data/data/com.termux/files/usr/glibc-prefix"
        echo "Diretório glibc-prefix removido"
    fi
    
    echo "Limpeza do GLIBC concluída"
}

instalar_glibc() {
    echo "Instalando GLIBC prefix..."
    
    ARQUIVO="glibc-prefix.tar.xz"
    GLIBC_DIR="/data/data/com.termux/files/usr/glibc"
    
    # Verifica se arquivo já existe
    if [ -f "$ARQUIVO" ]; then
        echo "Arquivo $ARQUIVO já existe, pulando download..."
    else
        echo "Baixando $ARQUIVO..."
        wget -q --show-progress https://github.com/Ilya114/Box64Droid/releases/download/alpha/glibc-prefix.tar.xz
    fi
    
    # Remove diretório existente se houver
    if [ -d "$GLIBC_DIR" ]; then
        echo "Removendo instalação anterior..."
        rm -rf "$GLIBC_DIR"
    fi
    
    echo "Extraindo para $GLIBC_DIR..."
    mkdir -p "$GLIBC_DIR"
    tar -xJf "$ARQUIVO" -C "$GLIBC_DIR" --strip-components=1
    
    echo "GLIBC instalado em $GLIBC_DIR"
}


instalar_ambiente_completo() {
    echo "Instalando ambiente completo..."
    
    echo "Atualizando sistema base..."
    apt-get update
    apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade
    
    echo "Instalando Python..."
    apt install python -y
    
    echo "Adicionando repositórios..."
    pkg install x11-repo glibc-repo -y
    pkg update
    
    echo "Instalando ferramentas de desenvolvimento..."
    pkg install file glibc-runner libandroid-sysv-semaphore libandroid-spawn cmake make clang busybox -y
    
    echo "Instalando pacotes de rede e sistema..."
    pkg install openssh pulseaudio iproute2 wget glibc git xkeyboard-config freetype fontconfig libpng xorg-xrandr -y
    
    echo "Instalando Termux X11 e utilitários..."
    pkg install termux-x11-nightly termux-am zenity which bash curl sed cabextract vulkan-tools -y
    
    echo "Ambiente completo instalado!"
}
diagnostico() {
    carregar_exports
    echo "=== DIAGNÓSTICO DO SISTEMA DE JOGOS ==="
    echo "Data: $(date)"
    echo ""
    
    # Variáveis de ambiente
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    LOG_FILE="$HOME_DIR/box64.log"
    
    # Função para logar e exibir
    log_output() {
        echo "$@" | tee -a "$LOG_FILE"
    }
    
    # Adiciona separador no log
    echo "" >> "$LOG_FILE"
    echo "========== DIAGNÓSTICO $(date) ==========" >> "$LOG_FILE"
    
    # Verifica Vulkan
    log_output "🔍 VERIFICANDO VULKAN:"
    if command -v vulkaninfo &>/dev/null; then
        log_output "✓ vulkaninfo instalado"
        log_output "Extensões disponíveis:"
        vulkaninfo 2>&1 | grep -E "VK_KHR_surface|VK_KHR_display" | tee -a "$LOG_FILE" || log_output "✗ Extensões críticas não encontradas"
    else
        log_output "✗ vulkaninfo não instalado"
    fi
    
    # Verifica driver Turnip
    log_output ""
    log_output "🔍 VERIFICANDO DRIVER TURNIP:"
    if [ -f "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ]; then
        log_output "✓ Driver encontrado"
        ls -lh "$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so" | tee -a "$LOG_FILE"
    else
        log_output "✗ Driver Turnip não encontrado"
    fi
    
    # Verifica ICD files
    log_output ""
    log_output "🔍 VERIFICANDO ICD FILES:"
    find "$GLIBC_PREFIX/share/vulkan/icd.d/" -name "*.json" 2>/dev/null | while read icd; do
        log_output "ICD: $icd"
        cat "$icd" | grep -E "library_path|api_version" | tee -a "$LOG_FILE" || true
    done
    
    # Verifica DXVK
    log_output ""
    log_output "🔍 VERIFICANDO DXVK:"
    WINE_SYSTEM32="$HOME_DIR/.wine/drive_c/windows/system32"
    for dll in d3d9 d3d10core d3d11 d3d12 dxgi; do
        if [ -f "$WINE_SYSTEM32/${dll}.dll" ]; then
            log_output "✓ ${dll}.dll encontrada"
        else
            log_output "✗ ${dll}.dll NÃO encontrada"
        fi
    done
    
    # Verifica variáveis críticas
    log_output ""
    log_output "🔍 VERIFICANDO VARIÁVEIS CRÍTICAS:"
    log_output "VK_ICD_FILENAMES: ${VK_ICD_FILENAMES:-NÃO DEFINIDA}"
    log_output "DISPLAY: ${DISPLAY:-NÃO DEFINIDA}"
    log_output "MESA_LOADER_DRIVER_OVERRIDE: ${MESA_LOADER_DRIVER_OVERRIDE:-NÃO DEFINIDA}"
    
    # Verifica processos

    log_output ""
    log_output "🔍 VERIFICANDO PROCESSOS:"

    # Termux X11 - verifica como app Android
    if ps aux 2>/dev/null | grep -E "app_process.*com.termux.x11|termux.x11.*MainActivity" | grep -v grep >/dev/null; then
        log_output "✓ Termux X11 rodando"
    elif pgrep -f "termux-x11" >/dev/null; then
        log_output "✓ Termux X11 rodando"
    else
        log_output "✗ Termux X11 NÃO rodando"
    fi

    # PulseAudio - verifica de múltiplas formas
    if pactl info &>/dev/null; then
        log_output "✓ PulseAudio rodando (conectado)"
    elif pgrep -f "pulseaudio" >/dev/null; then
        log_output "✓ PulseAudio rodando"
    elif ps aux 2>/dev/null | grep -E "[p]ulseaudio" >/dev/null; then
        log_output "✓ PulseAudio rodando"
    else
        log_output "✗ PulseAudio NÃO rodando"
    fi

    # Wineserver - verifica através do box64
    if ps aux 2>/dev/null | grep -E "box64.*wineserver|wineserver" | grep -v grep >/dev/null; then
        log_output "✓ Wineserver rodando"
    elif [ -f "$HOME_DIR/.wine/server-*/lock" ]; then
        log_output "✓ Wineserver rodando (lock file encontrado)"
    else
        log_output "✗ Wineserver NÃO rodando"
    fi
    log_output ""
    log_output "=== AÇÕES RECOMENDADAS ==="
    grep -q "VK_KHR_surface not supported" "$LOG_FILE" 2>/dev/null && log_output "→ Instale driver Turnip: ./install.sh --instalar_turnip_custom"
    [ ! -f "$WINE_SYSTEM32/d3d11.dll" ] && log_output "→ Instale DXVK: ./install.sh --instalar_dxvk 1.10.3"
    ! pgrep -f "termux-x11" >/dev/null && log_output "→ Inicie servidores: ./install.sh --iniciar_servidores"
    
    echo "========== FIM DO DIAGNÓSTICO ==========" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    echo ""
    echo "Diagnóstico salvo em: $LOG_FILE"
}

carregar_exports2() {

    echo "Carregando variáveis de ambiente..."
    
    # Define variáveis base
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    OPT_DIR="$GLIBC_PREFIX/opt"
    
    # Cria arquivo de exports
    cat > "$HOME_DIR/.box64_exports.sh" << 'EOF'
# Box64/Wine exports
export PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin:$PATH"
export GLIBC_PREFIX="/data/data/com.termux/files/usr/glibc"
export BOX64_PATH="/data/data/com.termux/files/usr/glibc/opt/wine/bin"
export BOX64_LD_LIBRARY_PATH="/data/data/com.termux/files/usr/glibc/opt/wine/lib/wine/i386-unix:/data/data/com.termux/files/usr/glibc/opt/wine/lib/wine/x86_64-unix:/data/data/com.termux/files/usr/glibc/lib/x86_64-linux-gnu"

# Display e áudio
export DISPLAY=":0"
export PULSE_SERVER="127.0.0.1"

# Vulkan - CRÍTICO
export VK_ICD_FILENAMES="/data/data/com.termux/files/usr/glibc/share/vulkan/icd.d/freedreno_custom.json:/data/data/com.termux/files/usr/glibc/share/vulkan/icd.d/freedreno_icd.aarch64.json"
export VK_DRIVER_FILES="/data/data/com.termux/files/usr/glibc/lib/aarch64-linux-gnu/libvulkan_freedreno.so"

# Mesa/Zink
# Define variáveis
HOME_DIR=${HOME:-/data/data/com.termux/files/home}
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
GLIBC_PREFIX="$PREFIX/glibc"
OPT_DIR="$GLIBC_PREFIX/opt"

# Carrega exports inline
unset LD_PRELOAD 
export PATH="$GLIBC_PREFIX/bin:$PREFIX/bin:$PATH"
export GLIBC_PREFIX
export BOX64_PATH="$OPT_DIR/wine/bin"
export BOX64_LD_LIBRARY_PATH="$OPT_DIR/wine/lib/wine/i386-unix:$OPT_DIR/wine/lib/wine/x86_64-unix:$GLIBC_PREFIX/lib/x86_64-linux-gnu"
export DISPLAY=":0"
export PULSE_SERVER="127.0.0.1"

export BOX64_SHOWSEGV="0"

# mesa/zink/vkd3d
export MESA_LOADER_DRIVER_OVERRIDE="zink"
export MESA_NO_ERROR="1"
export MESA_VK_WSI_PRESENT_MODE="mailbox"
export ZINK_DESCRIPTORS="lazy"
export ZINK_CONTEXT_THREADED="false"
export ZINK_DEBUG="compact"
export TU_DEBUG="noconform,rast_order"
export MANGOHUD="0"
export VKD3D_FEATURE_LEVEL="12_0"
export VK_ICD_FILENAMES="$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_custom.json:$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_icd.aarch64.json"
export VK_DRIVER_FILES="$GLIBC_PREFIX/lib/aarch64-linux-gnu/libvulkan_freedreno.so"


# DXVK/D8VK
export DXVK_HUD="fps,version,devinfo,gpuload"

# fontes e HUD
export FONTCONFIG_PATH="$PREFIX/etc/fonts"
export GALLIUM_HUD="simple,fps"

# Wine
export WINEESYNC="0"
export WINEESYNC_TERMUX="0"

# logs do Box64
export BOX64_LOG="1"
export BOX64_DYNAREC_LOG="0"

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
export BOX64_DYNAREC_BLEEDING_EDGE="0"
export BOX64_DYNAREC_CALLRET="0"
export BOX64_FUTEX_WAITV="1"
export BOX64_MMAP32="0"


export WINEDEBUG="fixme-all,warn+all,err+all,warn-font,warn-keyboard,warn-file,warn-globalmem,warn-msvcrt,warn-x11drv,warn-xrandr,warn-rpc,warn-seh,warn-bcrypt,warn-crypt,warn-threadname,warn-wineboot,warn-profile,warn-mountmgr,warn-cursor,warn-nsi,err-nsi,warn-virtual,err-wineusb,err-ntoskrnl"
export WINEDLLOVERRIDES="openvr_api_dxvk.dll=n,b;wineusb.dll=n,b;winebus.sys=n,b;nsi.sys=n,b;winemac.drv=n,b;nvapi64.dll=n,b"


EOF
    
    # Carrega imediatamente
    source "$HOME_DIR/.box64_exports.sh"
    
    echo "✓ Exports salvos em ~/.box64_exports.sh"
    echo "✓ Variáveis carregadas na sessão atual"
    echo ""
    echo "Para carregar automaticamente, adicione ao ~/.bashrc:"
    echo "source ~/.box64_exports.sh"
}
carregar_exports() {

    echo "Carregando variáveis de ambiente..."
    
    # Define variáveis base
    HOME_DIR=${HOME:-/data/data/com.termux/files/home}
    PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
    GLIBC_PREFIX="$PREFIX/glibc"
    OPT_DIR="$GLIBC_PREFIX/opt"
    
    # Cria arquivo de exports
    cat > "$HOME_DIR/.box64_exports.sh" << 'EOF'
# Box64/Wine exports
# Caminhos essenciais
export PATH="/data/data/com.termux/files/usr/glibc/bin:/data/data/com.termux/files/usr/bin:$PATH"
export GLIBC_PREFIX="/data/data/com.termux/files/usr/glibc"

# Configurações do Vulkan
export VK_ICD_FILENAMES="$GLIBC_PREFIX/share/vulkan/icd.d/freedreno_icd.aarch64.json"

# Configurações do Zink
export MESA_LOADER_DRIVER_OVERRIDE="turnip"

# Configurações do Wine
export WINEESYNC="0"
export WINEESYNC_TERMUX="0"

# Configurações do Box64
export BOX64_PATH="$GLIBC_PREFIX/opt/wine/bin"
export BOX64_LD_LIBRARY_PATH="$GLIBC_PREFIX/opt/wine/lib/wine/i386-unix:$GLIBC_PREFIX/opt/wine/lib/wine/x86_64-unix:$GLIBC_PREFIX/lib/x86_64-linux-gnu"
export BOX64_ALLOWMISSINGLIBS="1"


# logs do Box64
export BOX64_LOG="1"
export BOX64_DYNAREC_LOG="0"

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
export BOX64_DYNAREC_BLEEDING_EDGE="0"
export BOX64_DYNAREC_CALLRET="0"
export BOX64_FUTEX_WAITV="1"
export BOX64_MMAP32="0"


export WINEDEBUG="fixme-all,warn+all,err+all,warn-font,warn-keyboard,warn-file,warn-globalmem,warn-msvcrt,warn-x11drv,warn-xrandr,warn-rpc,warn-seh,warn-bcrypt,warn-crypt,warn-threadname,warn-wineboot,warn-profile,warn-mountmgr,warn-cursor,warn-nsi,err-nsi,warn-virtual,err-wineusb,err-ntoskrnl"
export WINEDLLOVERRIDES="openvr_api_dxvk.dll=n,b;wineusb.dll=n,b;winebus.sys=n,b;nsi.sys=n,b;winemac.drv=n,b;nvapi64.dll=n,b"


EOF
    
    # Carrega imediatamente
    source "$HOME_DIR/.box64_exports.sh"
    
    echo "✓ Exports salvos em ~/.box64_exports.sh"
    echo "✓ Variáveis carregadas na sessão atual"
    echo ""
    echo "Para carregar automaticamente, adicione ao ~/.bashrc:"
    echo "source ~/.box64_exports.sh"
}

ajuda() {
    echo "==== FUNÇÕES DISPONÍVEIS ===="
    echo "./install.sh --info_sistema             - Mostra informações do sistema"
    echo "./install.sh --instalar_dxvk 1.10.1             - Instala DXVK 1.10.1"
    echo "./install.sh --instalar_turnip_custom             - Instala DXVK 1.10.1"
    echo "./install.sh --instalar_ambiente_completo - Instala ambiente completo com X11"
    echo "./install.sh --instalar_glibc           - Instala GLIBC prefix do Box64Droid"
    echo "./install.sh --instalar_wine            - Instala Wine 9.13 WoW64"
    echo "./install.sh --configurar_wine_gaming   - Configura DXVK/vkd3d para games"
    echo "./install.sh --compilar_box64           - Compila e instala Box64 do código fonte"
    echo "./install.sh --limpar_glibc             - Remove arquivos do GLIBC (tar e diretórios)"
    echo "./install.sh --parar_servidores                    - Mostra esta ajuda"
    echo "./install.sh --iniciar_servidores                    - Mostra esta ajuda"
    echo "./install.sh --iniciar_jogo                    - Mostra esta ajuda"
    echo "./install.sh --iniciar_desktop                    - Mostra esta ajuda"
    echo "./install.sh --ajuda                    - Mostra esta ajuda"
    echo "./install.sh --diagnostico                    - Mostra esta ajuda"
    echo "./install.sh --testar_turnip_custom"
    echo "============================="
}