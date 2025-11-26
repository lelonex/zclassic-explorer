#!/bin/bash

# Script per rinominare tutti i riferimenti da Zcash a Zclassic
# nel progetto Zclassic Explorer

set -e

echo "🔄 Inizio conversione da Zcash a Zclassic..."

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per sostituire testo in tutti i file
replace_in_files() {
    local search="$1"
    local replace="$2"
    local extension="$3"
    
    echo -e "${YELLOW}Sostituendo '$search' con '$replace' nei file $extension...${NC}"
    
    find . -type f -name "*.$extension" ! -path "*/node_modules/*" ! -path "*/_build/*" ! -path "*/deps/*" ! -path "*/.git/*" -exec sed -i "s/$search/$replace/g" {} +
}

# Rinomina moduli Elixir
echo -e "${GREEN}📝 Rinominando moduli Elixir...${NC}"
replace_in_files "ZcashExplorer" "ZclassicExplorer" "ex"
replace_in_files "ZcashExplorer" "ZclassicExplorer" "exs"
replace_in_files "ZcashExplorerWeb" "ZclassicExplorerWeb" "ex"
replace_in_files "ZcashExplorerWeb" "ZclassicExplorerWeb" "exs"
replace_in_files "Zcashex" "Zclassicex" "ex"
replace_in_files "Zcashex" "Zclassicex" "exs"

# Rinomina nei template
echo -e "${GREEN}🎨 Aggiornando template...${NC}"
replace_in_files "zcash_explorer" "zclassic_explorer" "eex"
replace_in_files "zcash_explorer" "zclassic_explorer" "heex"
replace_in_files "ZcashExplorer" "ZclassicExplorer" "eex"
replace_in_files "ZcashExplorer" "ZclassicExplorer" "heex"
replace_in_files "Zcash" "Zclassic" "eex"
replace_in_files "Zcash" "Zclassic" "heex"
replace_in_files "ZEC" "ZCL" "eex"
replace_in_files "ZEC" "ZCL" "heex"

# Rinomina nei file di configurazione
echo -e "${GREEN}⚙️  Aggiornando configurazioni...${NC}"
replace_in_files "zcash_explorer" "zclassic_explorer" "exs"
replace_in_files "zcashd_" "zclassicd_" "exs"
replace_in_files "ZCASHD_" "ZCLASSICD_" "exs"
replace_in_files "zcash_network" "zclassic_network" "exs"
replace_in_files "ZCASH_NETWORK" "ZCLASSIC_NETWORK" "exs"

# Rinomina file HTML statici
echo -e "${GREEN}🌐 Aggiornando file HTML...${NC}"
replace_in_files "Zcash" "Zclassic" "html"
replace_in_files "zcash" "zclassic" "html"
replace_in_files "ZEC" "ZCL" "html"

# Rinomina nei file JavaScript
echo -e "${GREEN}💻 Aggiornando JavaScript...${NC}"
replace_in_files "zcash" "zclassic" "js"
replace_in_files "Zcash" "Zclassic" "js"

# Rinomina nei file CSS
echo -e "${GREEN}🎨 Aggiornando CSS...${NC}"
replace_in_files "zcash" "zclassic" "scss"
replace_in_files "zcash" "zclassic" "css"

# Rinomina directory lib/zcash_explorer -> lib/zclassic_explorer
if [ -d "lib/zcash_explorer" ]; then
    echo -e "${GREEN}📁 Rinominando directory lib/zcash_explorer...${NC}"
    mv lib/zcash_explorer lib/zclassic_explorer
fi

# Rinomina directory lib/zcash_explorer_web -> lib/zclassic_explorer_web
if [ -d "lib/zcash_explorer_web" ]; then
    echo -e "${GREEN}📁 Rinominando directory lib/zcash_explorer_web...${NC}"
    mv lib/zcash_explorer_web lib/zclassic_explorer_web
fi

# Rinomina file principale
if [ -f "lib/zcash_explorer.ex" ]; then
    echo -e "${GREEN}📄 Rinominando lib/zcash_explorer.ex...${NC}"
    mv lib/zcash_explorer.ex lib/zclassic_explorer.ex
fi

if [ -f "lib/zcash_explorer_web.ex" ]; then
    echo -e "${GREEN}📄 Rinominando lib/zcash_explorer_web.ex...${NC}"
    mv lib/zcash_explorer_web.ex lib/zclassic_explorer_web.ex
fi

# Rinomina file test
if [ -d "test/zcash_explorer_web" ]; then
    echo -e "${GREEN}🧪 Rinominando directory test...${NC}"
    mv test/zcash_explorer_web test/zclassic_explorer_web
fi

# Aggiorna README
if [ -f "README.md" ]; then
    echo -e "${GREEN}📖 Aggiornando README.md...${NC}"
    sed -i 's/ZcashExplorer/ZclassicExplorer/g' README.md
    sed -i 's/Zcash Explorer/Zclassic Explorer/g' README.md
    sed -i 's/zcash_explorer/zclassic_explorer/g' README.md
    sed -i 's/zcashblockexplorer\.com/zclassicexplorer.com/g' README.md
    sed -i 's/ZEC/ZCL/g' README.md
    sed -i 's/Zcash/Zclassic/g' README.md
fi

# Aggiorna Dockerfile
if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}🐳 Aggiornando Dockerfile...${NC}"
    sed -i 's/zcash_explorer/zclassic_explorer/g' Dockerfile
    sed -i 's/zcash-explorer/zclassic-explorer/g' Dockerfile
fi

# Aggiorna Makefile
if [ -f "Makefile" ]; then
    echo -e "${GREEN}🔧 Aggiornando Makefile...${NC}"
    sed -i 's/zcash_explorer/zclassic_explorer/g' Makefile
    sed -i 's/zcash-explorer/zclassic-explorer/g' Makefile
fi

echo -e "${GREEN}✅ Conversione completata!${NC}"
echo ""
echo -e "${YELLOW}📋 Prossimi passi:${NC}"
echo "1. Verificare che il nodo Zclassic sia in esecuzione"
echo "2. Aggiornare il file .env con le credenziali corrette"
echo "3. Eseguire: mix deps.get"
echo "4. Eseguire: mix compile"
echo "5. Eseguire: mix phx.server"
echo ""
echo -e "${YELLOW}⚠️  Note:${NC}"
echo "- La libreria zclassicex è stata creata localmente in lib/zclassicex.ex"
echo "- Configurare zclassicd sulla porta 8023 (default per Zclassic)"
echo "- Verificare le credenziali RPC in config/dev.exs"
