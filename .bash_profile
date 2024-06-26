if [ -f /otp/homebrew ]; then
	export PATH="/usr/local/bin:$PATH"
	export PATH="/opt/homebrew/bin:$PATH"
	export BASH_SILENCE_DEPRECATION_WARNING=1
fi

source ~/.bashrc
