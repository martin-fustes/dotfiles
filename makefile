all:
	./build/setup.sh

update:
	stow --verbose --target=$$HOME --restow .

delete:
	stow --verbose --target=$$HOME --delete .
