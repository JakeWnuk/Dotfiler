#!/bin/bash

# Ensure that no existing dotfiles (that you want) are installed in $HOME otherwise stow will not link them.
echo 'By using this script you agree that the developers assume no liability for damages and you are fully responsible for your actions.'

user=$(whoami)
cwd=$(echo $PWD)

# prepare base packages
echo 'Preparing Base Packages'
sudo apt-get update -qq
sudo apt install -y tmux jq golang parallel grc python3-venv exploitdb zsh-syntax-highlighting fonts-powerline chromium
sudo apt update --fix-missing

# pipx
python3 -m pip install --user pipx && python3 -m pipx ensurepath

# REMOVING DOTFILES
rm ~/.bashrc
rm ~/.zshrc
rm ~/.vimrc

# restore dot files
echo 'Restoring Dot Files'
sudo apt install -y stow
cp -r ./dotfiles $HOME/
cd $HOME/dotfiles/vim/ && tar -xf $HOME/dotfiles/vim/dot-vim.tar.gz; rm -f $HOME/dotfiles/vim/dot-vim.tar.gz
# stow all dotfiles
for dir in $HOME/dotfiles/*; do
  cd $HOME/dotfiles/ && stow --dotfiles $(echo $dir | awk '{gsub(/\/.*\//,"",$1); print}')
done

# shell stuff
source ~/.bashrc; source ~/.zshrc
sudo chsh -s $(which zsh) $user
touch $HOME/.z

# docker
sudo usermod -aG docker $USER
sudo systemctl enable docker --now

# install Go Tools
echo 'Installing Go Tools'
for line in $(cat $cwd/config/tools.json | jq -r '.go[] | select(.v11=="false") | [.name,.url] | @csv')
do
  name="$(echo $line | cut -d "," -f 1 | tr -d '"')"
  url="$(echo $line | cut -d "," -f 2 | tr -d '"')"
  echo "Installing $name"
  sudo /bin/su -l $user -c "go get -u -v $url"
done

for line in $(cat $cwd/config/tools.json | jq -r '.go[] | select(.v11=="true") | [.name,.url] | @csv')
do
  name="$(echo $line | cut -d "," -f 1 | tr -d '"')"
  url="$(echo $line | cut -d "," -f 2 | tr -d '"')"
  echo "Installing $name" 
  sudo /bin/su -l $user -c "GO111MODULE=on go get -v $url"
done

# install Git Repos
echo 'Installing Git Repos'
for line in $(cat $cwd/config/tools.json | jq -r '.git[] | [.name,.url,.directory] | @csv')
do
  name="$(echo $line | cut -d "," -f 1 | tr -d '"')"
  url="$(echo $line | cut -d "," -f 2 | tr -d '"')"
  directory="$(echo $line | cut -d "," -f 3 | tr -d '"')"
  echo "Installing $name" 
  sudo /bin/su -l $user -c "git clone https://$url $directory"
done

# Install manual tools
sudo git clone https://github.com/codingo/Interlace.git /opt/interlace && cd /opt/interlace/ && sudo python3 setup.py install
git clone https://github.com/blechschmidt/massdns.git /tmp/massdns && cd /tmp/massdns && make && sudo mv bin/massdns /usr/bin/massdns
wget -O /tmp/aquatone.zip https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip && cd /tmp/ && sudo unzip /tmp/aquatone.zip && sudo mv /tmp/aquatone $HOME/go/bin/aquatone
wget -O /tmp/kiterunner.tar.gz https://github.com/assetnote/kiterunner/releases/download/v1.0.2/kiterunner_1.0.2_linux_amd64.tar.gz && cd /tmp/ && sudo tar -xf kiterunner.tar.gz && sudo mv ./kr /bin/kr
mkdir ~/.zsh/; wget -O ~/.zsh/zsh-z.plugin.zsh https://raw.githubusercontent.com/agkozak/zsh-z/master/zsh-z.plugin.zsh

# install Wordlists
echo 'Installing Wordlists'
for line in $(cat $cwd/config/tools.json | jq -r '.wordlists[] | [.name,.url,.directory] | @csv')
do
  name="$(echo $line | cut -d "," -f 1 | tr -d '"')"
  url="$(echo $line | cut -d "," -f 2 | tr -d '"')"
  directory="$(echo $line | cut -d "," -f 3 | tr -d '"')"
  echo "Installing $name" 
  sudo /bin/su -l $user -c "git clone https://$url $directory"
done

# install manual wordlists
mkdir -p $HOME/wordlists/{jhaddix,tomnomnom,assetnote}
wget -O $HOME/wordlists/tomnomnom/short-wordlist.txt https://gist.githubusercontent.com/tomnomnom/57af04c3422aac8c6f04451a4c1daa51/raw/9f551e023ff17d093dcb9f8b355c3af55827cb34/short-wordlist.txt
wget -O $HOME/wordlists/jhaddix/content_discovery_all.txt https://gist.github.com/jhaddix/b80ea67d85c13206125806f0828f4d10/raw/c81a34fe84731430741e0463eb6076129c20c4c0/content_discovery_all.txt
wget -O $HOME/wordlists/jhaddix/dns_all.txt https://gist.github.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt
cd $HOME/wordlists/assetnote && wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH
cd ./data/kiterunner && sudo tar -xf routes-small.kite.tar.gz  && sudo tar -xf routes-large.kite.tar.gz

# custom wordlists
mkdir -p $HOME/wordlists/custom/ && cp $cwd/config/wordlists/* $HOME/wordlists/custom/
# set up vimprev
sudo cp $cwd/config/vimprev /bin/vimprev && sudo chmod +x /bin/vimprev
# set up vimprev
sudo cp $cwd/config/bypass4031 /bin/bypass4031 && sudo chmod +x /bin/bypass4031
# copy over gf patterns
cp -r $GOPATH/src/github.com/tomnomnom/gf/examples/* ~/.gf

# want to put these in a folder eventually
gf -save webcontent-filter -ivE '*.css|*.eos|*.jpg|*.png|*.gif|*.svg|*.woff|*.ttf'
gf -save whois-filter -E 'NetRange|CIDR|Customer|CustName|Organization|OrgName'

# end
echo 'Finished set up. Updating Machine...'
# please read content of scripts before running
# updates box and tools and creates grc alias file
bash $cwd/config/grc-config.sh
bash $cwd/config/updater.sh
# pipx install
pipx install arjun
pipx install crackmapexec
pipx install impacket
pipx install bloodhound
pipx install nmaptocsv
pipx install csvtomd
echo 'Completed!'
