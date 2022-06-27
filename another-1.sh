#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"


# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export ANONE_CHAIN_ID=anone-testnet-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl build-essential git wget jq make gcc tmux -y

# install go
source $HOME/.bash_profile
    if go version > /dev/null 2>&1
    then
        echo -e '\n\e[40m\e[92mSkipped Go installation\e[0m'
    else
        echo -e '\n\e[40m\e[92mStarting Go installation...\e[0m'
        ver="1.18.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version
    fi

# download binary
git clone https://github.com/notional-labs/anone.git
cd anone
git checkout testnet-1.0.3
make install
anoned version

# config
anoned config chain-id $ANONE_CHAIN_ID
anoned config keyring-backend test

# init
anoned init $NODENAME --chain-id $ANONE_CHAIN_ID

# download genesis
wget -O ~/.anone/config/genesis.json https://raw.githubusercontent.com/notional-labs/anone/master/networks/testnet-1/genesis.json

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0uan1\"/" $HOME/.anone/config/app.toml

# set peers and seeds
SEEDS="49a49db05e945fc38b7a1bc00352cafdaef2176c@95.217.121.243:2280,80f0ef5d7c432d2bae99dc8437a9c3db464890cd@65.108.128.139:2280,3afac655e3be5c5fc4a64ec5197346ffb5a855c1@49.12.213.105:2280"
PEERS="a0ff256334e6781972beec33739123fd852153a3@95.217.121.243:2280,35c14ef98034511e716504c6b7aa9d9ed416a75f@62.141.41.220:26656,4d2099cb772f639e7e2936f9f9f2a9a85ab35e62@173.249.7.49:26656,82ba6b00244af1b1fee3dc415d398188de40217b@75.119.135.167:26656,75e21f3f515294caadaed054297b591e7aff1ff0@173.212.223.37:26656,6abd85339523371ceb44ecc45c17b24836e4a13d@209.126.7.201:26656,c52aa7de58b29d93b17d09a373e6adb2eb29f5f1@144.126.138.48:26656,7130dc7f837215eba6429c752b606f2165f72463@207.244.246.217:26656,a6090021754819f1e055be8ff814c1fdb3ab5e51@144.126.140.91:26656,1fcf5a1cbdec73092ef3bfe3944fbfc6d240c6d6@185.230.138.141:26656,c760ef73579bc95fd15367f81a015113bd79e675@65.21.129.95:26656,b3e85b210dce19c7d5682a836ec7287a96a9d4c0@159.223.34.123:26656,05a4c982b3bc5a4dff9508c0b0d9d401357018f6@144.126.137.231:26656,74c334436da9e0e6d17ac083653601649aad4498@185.209.229.135:26656,5c2b1c4deb14501871c773e8c6c41bbcfe853471@207.244.243.245:26656,05c242cf520fc35b1ddc3536d55e6ce25cdc4117@161.97.126.98:26656,5bd7cef7ff9b50847532f311e17aa74e7e45a56d@135.181.214.164:26656,0d83b9159805de0aa0a3a0c213362de565dad64e@95.217.198.243:26656,300507b829a8befac579dd0c7357851a188ab973@144.126.138.115:26656,229b31707536e32447a94edf63f9e0c999e31097@95.111.239.233:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.anone/config/config.toml

#index
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.anone/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.anone/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.anone/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.anone/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.anone/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.anone/config/app.toml

# reset
anoned unsafe-reset-all


# create service
sudo tee /etc/systemd/system/anoned.service > /dev/null <<EOF
[Unit]
Description=anone
After=network-online.target
[Service]
User=$USER
ExecStart=$(which anoned) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable anoned
sudo systemctl restart anoned

break
;;

"Create Wallet")
anoned keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
ANONE_WALLET_ADDRESS=$(anoned keys show $WALLET -a)
ANONE_VALOPER_ADDRESS=$(anoned keys show $WALLET --bech val -a)
echo 'export ANONE_WALLET_ADDRESS='${ANONE_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export ANONE_VALOPER_ADDRESS='${ANONE_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;


"Create Validator")
anoned tx staking create-validator \
  --amount=1500000000uan1 \
  --from $WALLET \
  --commission-max-change-rate="0.01" \
  --commission-max-rate="0.20" \
  --commission-rate="0.05" \
  --min-self-delegation=1 \
  --pubkey=$(anoned tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $ANONE_CHAIN_ID \
  --gas 200000 \
  --fees 250000uan1 \
  --keyring-backend os \
 
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
