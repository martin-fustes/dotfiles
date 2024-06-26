all:
	stow --verbose --target=$$HOME --restow */

setup:
	./build/setup.sh

delete:
	stow --verbose --target=$$HOME --delete */
