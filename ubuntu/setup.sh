# TODO INSTALL LATTE DOCK
# TODO INSTALL DOCKER
# TODO INSTALL DISCORD
# TODO deprecate apt-key for /etc/apt/trusted.gpg.d
# TODO move spotify to /etc/apt/trusted.gpg.d

# check for file created when a machine is configured using our automation.
FILE=~/.new-machine-configured
if [[ -f "$FILE" ]]; then
    echo "This machine has already been provisioned using this script. If you would like to run this script again delete ~/.new-machine-configured and run again."
	exit 1
fi

echo "Enter GIT user.name?"
echo "For example, \"Ricky Bobby\""
read git_config_user_name

echo "Enter GIT user.email?"
echo "For example, mine will be \"rickybobby@shakeandbake.com\""
read git_config_user_email

echo "Enter github username?"
echo "For example, mine will be \"rickybobby\""
read username

echo "Adding apt repositories for depenencies"
sudo add-apt-repository ppa:git-core/ppa -y # git apt repository

# peek repo
sudo add-apt-repository ppa:peek-developers/stable -y

# protonvpn repo
wget -q https://protonvpn.com/download/protonvpn-stable-release_1.0.1-1_all.deb
sudo dpkg -i protonvpn-stable-release_1.0.1-1_all.deb
rm -f protonvpn-stable-release_1.0.1-1_all.deb

# adding spotify repo and signing key 
wget -q -O - https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# adding vscode repo and signing key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

echo "Updating apt package information for all sources" 
cd ~ && sudo apt update # This ensures that apt can determine what software and versions are available.

echo 'Installing dependencies using apt' 
sudo apt install \
	apt-transport-https \
	code \
	curl \
	fonts-firacode \
	gir1.2-appindicator3-0.1 \
	git \
	gnome-shell-extension-appindicator \
	gpg \
	neofetch \
	peek \
	protonvpn \
	python3-pip \
	spotify-client \
	virtualbox \
	vlc \
	vlc-plugin-access-extra \
	wget \
	xclip \
	zsh \
	-y


echo 'Installing getgist to download dot files from gist'
sudo pip3 install getgist
export GETGIST_USER=$username

echo "Setting up your git global user name and email"
git config --global user.name "$git_config_user_name"
git config --global user.email $git_config_user_email

echo 'Generating a SSH Key'
ssh-keygen -t rsa -b 4096 -C $git_config_user_email
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard

echo 'Launching Firefox on Github so you can paste your SSH key'
firefox https://github.com/settings/keys </dev/null >/dev/null 2>&1 & disown

echo 'Copying .zshrc'
cp dotfiles/.zshrc ~/

echo 'Configuring zsh using ohmyzsh install.sh'
sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
chsh -s $(which zsh)

echo 'Indexing snap to ZSH'
sudo chmod 777 /etc/zsh/zprofile
echo "emulate sh -c 'source /etc/profile.d/apps-bin-path.sh'" >> /etc/zsh/zprofile

echo 'Installing Spaceship ZSH Theme'
git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
source ~/.zshrc

echo 'Installing Zoom'
wget -c https://cdn.zoom.us/prod/5.9.6.2225/zoom_amd64.deb
sudo apt install ./zoom_amd64.deb -y

echo 'Updating and Cleaning Unnecessary Packages'
sudo -- sh -c 'apt update; apt upgrade -y; apt full-upgrade -y; apt autoremove -y; apt autoclean -y'
clear

echo 'Bumping the max file watchers'
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

echo 'Generating GPG key'
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG

echo 'Adding GPG key ID to your global .gitconfig'
gpg_key_id=$(gpg --list-secret-keys --keyid-format LONG | grep sec | grep -o -P '(?<=/)[A-Z0-9]{16}')
git config --global user.signingkey $gpg_key_id
gpg --armor --export $gpg_key_id | xclip -selection clipboard

echo 'Launching Firefox on Github so you can paste your GPG key'
firefox https://github.com/settings/keys </dev/null >/dev/null 2>&1 & disown

# creating file to indicate configuration was ran for future attempts
echo "This machine was configured using new-machine https://github.com/trydydd/new-machine." > ~/.new-machine-configured

echo 'All setup, enjoy!'

