#!/bin/bash

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

command_exists() {
	command -v $1 >/dev/null 2>&1
}

checkEnv() {
	## Check for requirements.
	REQUIREMENTS='curl groups sudo'
	if ! command_exists ${REQUIREMENTS}; then
		echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
		exit 1
	fi

	## Check Package Handeler
	PACKAGEMANAGER='apt yum dnf pacman zypper brew'
	for pgm in ${PACKAGEMANAGER}; do
		if command_exists ${pgm}; then
			PACKAGER=${pgm}
			echo -e "Using ${pgm}"
		fi
	done

	if [ -z "${PACKAGER}" ]; then
		echo -e "${RED}Can't find a supported package manager"
		exit 1
	fi

	## Check if the current directory is writable.
	GITPATH="$(dirname "$(realpath "$0")")"
	if [[ ! -w ${GITPATH} ]]; then
		echo -e "${RED}Can't write to ${GITPATH}${RC}"
		exit 1
	fi

	## Check SuperUser Group
	SUPERUSERGROUP='wheel sudo root'
	for sug in ${SUPERUSERGROUP}; do
		if groups | grep ${sug}; then
			SUGROUP=${sug}
			echo -e "Super user group ${SUGROUP}"
		fi
	done

	## Check if member of the sudo group.
	if ! groups | grep ${SUGROUP} >/dev/null; then
		echo -e "${RED}You need to be a member of the sudo group to run me!"
		exit 1
	fi

}

UpdateUpgrade() {
	sudo ${PACKAGER} update
	sudo ${PACKAGER} upgrade -y
	if [[ ${PACKAGER} == "apt" ]]; then
		sudo apt-get install software-properties-common -y
	fi
}

InstallNVim() {
	## Prerequisites
	sudo $PACKAGER install python-dev python-pip python3-dev python3-pip python3-venv
	## Install Nvim Unstable
	case $(command -v apt || command -v zypper || command -v dnf || command -v pacman) in
	*apt)
		curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
		chmod u+x nvim.appimage
		./nvim.appimage --appimage-extract
		sudo mv squashfs-root /opt/neovim
		sudo ln -s /opt/neovim/AppRun /usr/bin/nvim
		;;
	*zypper)
		sudo zypper refresh
		sudo zypper install -y neovim
		;;
	*dnf)
		sudo dnf check-update
		sudo dnf install -y neovim
		;;
	*pacman)
		sudo pacman -Syu
		sudo pacman -S --noconfirm neovim
		;;
	*)
		echo "No supported package manager found. Please install neovim manually."
		;;
	esac
}

InstallLazyGit() {
	if [[ $PACKAGER == "apt" ]]; then
		LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
		curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
		tar xf lazygit.tar.gz lazygit
		sudo install lazygit /usr/local/bin
	elif [[ $PACKAGER == "dnf" ]]; then
		sudo dnf copr enable atim/lazygit -y
	else
		sudo $PACKAGER install lazygit -yq
	fi
}

InstallCcompiler() {
	sudo $PACKAGER install gcc -yq
}

InstallTelescopeDependecies() {
	sudo $PACKAGER install ripgrep -yq
	sudo $PACKAGER install fd-find -yq
}

InstallRustLang() {
	curl https://sh.rustup.rs -sSf | sh
}

InstallDotnetLang() {
	if [[ $PACKAGER == "apt" ]]; then
		sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0
		sudo apt-get update && sudo apt-get install -y aspnetcore-runtime-8.0
		sudo apt-get install -y dotnet-runtime-8.0
	else
		sudo $PACKAGER install dotnet-sdk-8.0 -yq
	fi
}

InstallBtm() {
	if [[ $PACKAGER == "apt" ]]; then
		curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb
		sudo dpkg -i bottom_0.9.6_amd64.deb
	else
		if [[ $PACKAGER == "dnf" ]]; then
			sudo dnf copr enable atim/bottom -y
		fi
		sudo $PACKAGER install bottom -yq
	fi
}

SetupStow() {
	sudo $PACKAGER install stow -yq
	cd ~/dotfiles/
	sudo stow --adopt .
}

InstallFullUnicode() {
	sudo $PACKAGER install google-noto-* --allowerasing --skip-broken
}

InstallAlsaAudioPlugin() {
	sudo $PACKAGER install alsa-plugins-pulseaudio
}

InstallTmux() {
	sudo $PACKAGER install tmux
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

installBashDepend() {
	## Check for dependencies.
	DEPENDENCIES='bash bash-completion tar tree multitail fastfetch tldr trash-cli'
	echo -e "${YELLOW}Installing dependencies...${RC}"
	if [[ $PACKAGER == "pacman" ]]; then
		if ! command_exists yay && ! command_exists paru; then
			echo "Installing yay as AUR helper..."
			sudo ${PACKAGER} --noconfirm -S base-devel
			cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git
			cd yay-git && makepkg --noconfirm -si
		else
			echo "Aur helper already installed"
		fi
		if command_exists yay; then
			AUR_HELPER="yay"
		elif command_exists paru; then
			AUR_HELPER="paru"
		else
			echo "No AUR helper found. Please install yay or paru."
			exit 1
		fi
		${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
	else
		sudo ${PACKAGER} install -yq ${DEPENDENCIES}
	fi
}

installStarship() {
	if command_exists starship; then
		echo "Starship already installed"
		return
	fi

	if ! curl -sS https://starship.rs/install.sh | sh; then
		echo -e "${RED}Something went wrong during starship install!${RC}"
		exit 1
	fi
	if command_exists fzf; then
		echo "Fzf already installed"
	else
		git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
		~/.fzf/install
	fi
}

installZoxide() {
	if command_exists zoxide; then
		echo "Zoxide already installed"
		return
	fi

	if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
		echo -e "${RED}Something went wrong during zoxide install!${RC}"
		exit 1
	fi
}

checkEnv
UpdateUpgrade
InstallNVim
InstallCcompiler
InstallLazyGit
InstallTelescopeDependecies
InstallDotnetLang
InstallRustLang
InstallNodeJs
InstallTmux
installBashDepend
installStarship
installZoxide
SetupStow

echo "Done!"
