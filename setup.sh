#!/bin/sh

set -e

`which zsh` --version || (echo "Make sure zsh is installed!"; exit 2)

if [ ! -e ".zshrc" ] || [ ! -e ".vimrc" ] || [ ! -e "themes" ]; then
  echo "Please run the script from the repository root where .zshrc, .vimrc, and themes are located."
  exit 1
fi

REPO_PATH="$(pwd)"
USERNAME=""
CREATE_USER=false
GROUP="wheel"

# Parse command-line arguments
while true; do
  case "$1" in
    --user ) USERNAME="$2"; CREATE_USER=true; shift 2 ;;
    --group ) GROUP="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# Create user if specified
if $CREATE_USER; then
  echo "Creating user ${USERNAME}..."
  useradd -m -s `which zsh` "${USERNAME}"
  passwd "${USERNAME}"
  usermod -aG "${GROUP}" "${USERNAME}"
  echo "User ${USERNAME} created and added to the wheel group."
  HOME_DIR="/home/${USERNAME}"
else
  USERNAME="${USER}"
  chsh -s `which zsh` "${USER}"
  HOME_DIR="${HOME}"
fi

# Clone oh-my-zsh repository
echo "Cloning oh-my-zsh repository..."
git clone https://github.com/robbyrussell/oh-my-zsh.git "${HOME_DIR}/.oh-my-zsh"

# Create .zshenv file with ZSH_CUSTOM
if [ -e "${HOME_DIR}/.zshenv" ]; then
  echo ".zshenv file already exists. Do you want to back it up or overwrite? (b/o): "
  read -r ZSHENV_CHOICE
  case "$ZSHENV_CHOICE" in
    b|B ) mv "${HOME_DIR}/.zshenv" "${HOME_DIR}/.zshenv.bak";;
    o|O ) ;;
    * ) echo "Invalid choice. Exiting."; exit 1;;
  esac
fi

echo "ZSH_CUSTOM=${REPO_PATH}" > "${HOME_DIR}/.zshenv"


# Symlink .zshrc
if [ -e "${HOME_DIR}/.zshrc" ]; then
  echo ".zshrc file already exists. Do you want to back it up or overwrite? (b/o): "
  read -r ZSHRC_CHOICE
  case "$ZSHRC_CHOICE" in
    b|B ) mv "${HOME_DIR}/.zshrc" "${HOME_DIR}/.zshrc.bak";;
    o|O ) ;;
    * ) echo "Invalid choice. Exiting."; exit 1;;
  esac
fi
ln -sf "${REPO_PATH}/.zshrc" "${HOME_DIR}/.zshrc"

# Symlink .vimrc
if [ -e "${HOME_DIR}/.vimrc" ]; then
  echo ".vimrc file already exists. Do you want to back it up or overwrite? (b/o): "
  read -r VIMRC_CHOICE
  case "$VIMRC_CHOICE" in
    b|B ) mv "${HOME_DIR}/.vimrc" "${HOME_DIR}/.vimrc.bak";;
    o|O ) ;;
    * ) echo "Invalid choice. Exiting."; exit 1;;
  esac
fi
ln -sf "${REPO_PATH}/.vimrc" "${HOME_DIR}/.vimrc"

chown -R "${USERNAME}" "${HOME_DIR}/.oh-my-zsh" "${HOME_DIR}/.zshrc" "${HOME_DIR}/.vimrc" "${HOME_DIR}/.zshenv"
echo "Setup complete."
