#!/bin/bash

#pkg update -y && pkg install -y && wget -O ./install.sh http://192.168.0.11:5500/install.sh
#chmod +x install.sh
#./install.sh --instalar_ambiente_completo
#/data/data/com.termux/files/usr/glibc/bin/box64 wineboot --init

#while($true) { 
#    curl -o "./box64.log" "http://192.168.0.12:8081/box64.log" 
#    Write-Host "$(Get-Date -Format 'HH:mm:ss') - Baixado"
#    Start-Sleep 5 
#}

# URL do arquivo de funções
FUNCOES_URL="http://192.168.0.11:5500/funcoes.sh"
TEMP_FILE="$HOME/.funcoes_temp.sh"

# Verifica se foi passado um parâmetro
if [ $# -eq 0 ]; then
    echo "Uso: $0 --<nome_da_funcao> [argumentos...]"
    echo "Exemplo: $0 --instalar_dxvk 1.10.3"
    exit 1
fi

# Remove o -- do parâmetro para obter o nome da função
FUNCAO=${1#--}

echo "Baixando arquivo de funções..."
if wget -q "$FUNCOES_URL" -O "$TEMP_FILE" || curl -s "$FUNCOES_URL" -o "$TEMP_FILE"; then
    echo "Arquivo baixado com sucesso!"
    
    # Carrega as funções
    source "$TEMP_FILE"
    
    # Verifica se a função existe
    if declare -f "$FUNCAO" > /dev/null; then
        echo "Executando função: $FUNCAO"
        # Passa todos os argumentos exceto o primeiro (que é o nome da função)
        $FUNCAO "${@:2}"
    else
        echo "Erro: Função '$FUNCAO' não encontrada!"
        echo "Funções disponíveis:"
        grep "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" "$TEMP_FILE" | sed 's/().*//' | sed 's/^/  - /'
    fi
    
    # Remove arquivo temporário
    rm -f "$TEMP_FILE"
else
    echo "Erro: Não foi possível baixar o arquivo de $FUNCOES_URL"
    echo "Verifique se o servidor está rodando e acessível."
    exit 1
fi