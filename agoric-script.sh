#!/bin/bash

curl https://deb.nodesource.com/setup_12.x | sudo bash
sleep 4
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
sleep 4
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sleep 2
sudo apt update
sleep 4
sudo apt upgrade -y
sleep 4
sudo apt install git -y
sleep 4
sudo apt install tmux -y
sleep 4
sudo apt install mc -y

sleep 4
sudo apt install nodejs=12.* yarn build-essential jq -y
sleep 4
curl https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -
sleep 4
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

sleep 2
source $HOME/.profile
sleep 2
git clone https://github.com/Agoric/agoric-sdk
sleep 4
cd agoric-sdk
git checkout @agoric/sdk@2.12.1
yarn install
sleep 4
yarn build
sleep 4
(cd packages/cosmic-swingset && make)
sleep 4
curl https://testnet.agoric.com/network-config > chain.json
sleep 2
chainName=`jq -r .chainName < chain.json`
sleep 2
ag-chain-cosmos init --chain-id $chainName agoric-2m
sleep 2
curl https://testnet.agoric.com/genesis.json > $HOME/.ag-chain-cosmos/config/genesis.json 
sleep 4
ag-chain-cosmos unsafe-reset-all
sleep 6
peers=`jq '.peers | join(",")' < chain.json`
sleep 2
sed -i -e "s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.ag-chain-cosmos/config/config.toml
sleep 2
sed -i -e 's/^\(timeout_commit *=\).*/\1 "5s"/' $HOME/.ag-chain-cosmos/config/config.toml
sleep 4
sudo tee <<EOF >/dev/null /etc/systemd/system/ag-chain-cosmos.service Sasha
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/ag-chain-cosmos start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sleep 2
cat /etc/systemd/system/ag-chain-cosmos.service
sleep 2
sudo systemctl enable ag-chain-cosmos
sleep 2
sudo systemctl start ag-chain-cosmos
sleep 2
sudo systemctl status ag-chain-cosmos
