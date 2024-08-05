#!/bin/bash

PURPLE='\033[38;5;63m'
GREEN='\033[38;5;49m'
RED='\033[38;5;196m'
BLUE='\033[38;5;33m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

set_rpc() {
    if [ "$RPC" == "mainnet" ]; then
        solana config set --url https://api.mainnet-beta.solana.com > /dev/null 2>&1
    elif [ "$RPC" == "devnet" ]; then
        solana config set --url https://api.devnet.solana.com > /dev/null 2>&1
    else
        echo -e "${RED}Invalid RPC value. Please set RPC to either 'mainnet' or 'devnet'.${NC}"
        read -p "Press Enter to return to the menu"
        return
    fi
}

RPC=${RPC:-mainnet}
set_rpc

generate_wallet() {
    read -p "Enter a name for the new wallet: " WALLET_NAME
    WALLET_PATH="/wallets/${WALLET_NAME}.json"

    if [ -f "$WALLET_PATH" ]; then
        echo -e "${RED}Wallet file already exists at $WALLET_PATH. Returning to menu...${NC}"
        read -p "Press Enter to return to the menu"
        return
    fi

    output=$(solana-keygen new -o "$WALLET_PATH" --no-bip39-passphrase --word-count 24)

    pubkey=$(echo "$output" | grep -oP 'pubkey: \K[^\n]+')

    seed_phrase=$(echo "$output" | grep -A1 'Save this seed phrase' | tail -n1)

    clear
    echo -e "${PURPLE}============================================================"
    echo -e "                   Solana Wallet Generated                  "
    echo -e "============================================================${NC}"
    echo
    echo -e "${GREEN}🌐 Environment: ${NC}$RPC"
    echo
    echo -e "${GREEN}🔑 Public Key (Address):${NC}"
    echo -e "$pubkey"
    echo
    echo -e "${GREEN}📝 Seed Phrase (Recovery Phrase):${NC}"
    echo -e "$seed_phrase"
    echo
    echo -e "${PURPLE}============================================================"
    echo -e " 🔐 ${RED}IMPORTANT: Save this seed phrase in a secure location.     ${NC}"
    echo -e " 🚫 ${RED}Do not share it with anyone.                    ${NC}"
    echo -e "============================================================${NC}"
    echo
    echo -e "${GREEN}🔓 Public Key QR Code:${NC}"
    echo
    qrencode -t ANSIUTF8i "$pubkey"
    echo
    echo -e "${PURPLE}============================================================"
    echo -e " 🚀 To start using this address, send some Solana (SOL) to the "
    echo -e " public address above.                                      "
    echo -e "============================================================${NC}"

    read -p "Press Enter to return to the menu"
}

display_wallets() {
    wallets=($(ls /wallets/*.json 2> /dev/null))
    if [ ${#wallets[@]} -eq 0 ]; then
        echo -e "${RED}No wallets found. Returning to menu...${NC}"
        read -p "Press Enter to return to the menu"
        return
    fi

    clear
    echo -e "${PURPLE}============================================================"
    echo -e "                        Wallets List                        "
    echo -e "============================================================${NC}"
    
    for i in "${!wallets[@]}"; do
        wallet=${wallets[$i]}
        pubkey=$(solana address -k "$wallet")
        balance=$(solana balance -k "$wallet")
        wallet_name=$(basename "$wallet" .json)
        echo -e "${GREEN}$((i+1)). Wallet Name: ${NC}$wallet_name"
        echo -e "${GREEN}   🔑 Public Key: ${NC}$pubkey"
        echo -e "${GREEN}   💰 Balance: ${NC}$balance"
        echo -e "${GREEN}   🔓 QR Code:${NC}"
        qrencode -t ANSIUTF8i "$pubkey"
        echo -e "${PURPLE}------------------------------------------------------------${NC}"
    done
    read -p "Press Enter to return to the menu"
}

airdrop_devnet() {
    RPC="devnet"
    set_rpc
    wallets=($(ls /wallets/*.json 2> /dev/null))
    if [ ${#wallets[@]} -eq 0 ]; then
        echo -e "${RED}No wallets found. Returning to menu...${NC}"
        read -p "Press Enter to return to the menu"
        return
    fi

    select_wallet() {
        clear
        echo "Select a wallet for airdrop:"
        for i in "${!wallets[@]}"; do
            wallet_name=$(basename "${wallets[$i]}" .json)
            if [ "$i" -eq "$selected_wallet" ]; then
                echo -e "> ${YELLOW}$wallet_name${NC}"
            else
                echo "  $wallet_name"
            fi
        done
    }

    selected_wallet=0

    while true; do
        select_wallet

        read -rsn1 input
        if [ "$input" = $'\x1b' ]; then
            read -rsn2 -t 0.1 input
            if [ "$input" = "[A" ]; then
                ((selected_wallet--))
                if [ "$selected_wallet" -lt 0 ]; then
                    selected_wallet=$((${#wallets[@]} - 1))
                fi
            elif [ "$input" = "[B" ]; then
                ((selected_wallet++))
                if [ "$selected_wallet" -ge "${#wallets[@]}" ]; then
                    selected_wallet=0
                fi
            fi
        elif [ "$input" = "" ]; then
            WALLET_PATH="${wallets[$selected_wallet]}"
            break
        fi
    done
    
    output=$(solana airdrop 1 "$WALLET_PATH" 2>&1)
    if [[ $output == *"Error: airdrop request failed. This can happen when the rate limit is reached."* ]]; then
        echo -e "${RED}Airdrop request failed due to rate limit. Please try again after 24 hours.${NC}"
        read -p "Press Enter to return to the menu"
        return
    fi 
    solana airdrop 1 "$WALLET_PATH"
    balance=$(solana balance -k "$WALLET_PATH")
    pubkey=$(solana address -k "$WALLET_PATH")

    clear
    echo -e "${PURPLE}============================================================"
    echo -e "                      Airdrop Completed                     "
    echo -e "============================================================${NC}"
    echo
    echo -e "${GREEN}🌐 Environment: ${NC}$RPC"
    echo
    echo -e "${GREEN}🔑 Public Key (Address):${NC}"
    echo -e "$pubkey"
    echo
    echo -e "${GREEN}💰 Current Balance:${NC}"
    echo -e "$balance"
    echo
    echo -e "${PURPLE}============================================================"
    echo -e " You have received 1 SOL as an airdrop to the above address."
    echo -e "============================================================${NC}"
    read -p "Press Enter to return to the menu"
}


display_menu() {
    clear
    echo -e "${BLUE}✨ Main Menu ✨${NC}"
    for i in "${!options[@]}"; do
        if [ "$i" -eq "$selected" ]; then
            echo -e "${YELLOW}> ${options[i]}${NC}"
        else
            echo "  ${options[i]}"
        fi
    done
}

options=("🆕 Generate New Wallet" "📄 Display Wallets")
if [ "$RPC" == "devnet" ]; then
    options+=("💸 Airdrop")
fi
options+=("❌ Quit")

selected=0

while true; do
    display_menu

    read -rsn1 input
    if [ "$input" = $'\x1b' ]; then
        read -rsn2 -t 0.1 input
        if [ "$input" = "[A" ]; then
            ((selected--))
            if [ "$selected" -lt 0 ]; then
                selected=$((${#options[@]} - 1))
            fi
        elif [ "$input" = "[B" ]; then
            ((selected++))
            if [ "$selected" -ge "${#options[@]}" ]; then
                selected=0
            fi
        fi
    elif [ "$input" = "" ]; then
        case ${options[selected]} in
            "🆕 Generate New Wallet") generate_wallet;;
            "📄 Display Wallets") display_wallets;;
            "💸 Airdrop (DEVNET)") airdrop_devnet;;
            "❌ Quit") echo "👋 Bye"; break;;
        esac
    fi
done