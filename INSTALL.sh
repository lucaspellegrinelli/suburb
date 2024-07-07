#!/bin/bash

set -euo pipefail

mkdir -p ~/.suburb/build
mkdir -p ~/.suburb/bin

rm -rf ~/.suburb/build/*
rm -rf ~/.suburb/bin/*

if ! gleam export erlang-shipment; then
    echo "Failed to export Gleam shipment"
    exit 1
fi

if ! mv ./build/erlang-shipment/* ~/.suburb/build; then
    echo "Failed to move files to ~/.suburb/build"
    exit 1
fi

{
    echo "#!/bin/bash"
    echo "$HOME/.suburb/build/entrypoint.sh run \"\$@\""
} > ~/.suburb/bin/suburb

if ! chmod +x ~/.suburb/bin/suburb; then
    echo "Failed to make ~/.suburb/bin/suburb executable"
    exit 1
fi

SHELL_RC=""
if [ -f "${HOME}/.zshrc" ]; then
    SHELL_RC=$HOME/.zshrc
elif [ -f "${HOME}/.bashrc" ]; then
    SHELL_RC=$HOME/.bashrc
else
    echo "Unsupported shell. Please manually add ~/.suburb/bin to your PATH."
    exit 1
fi

if ! grep -q "export PATH=\"$HOME/.suburb/bin:\$PATH\"" "$SHELL_RC"; then
    echo "export PATH=\"$HOME/.suburb/bin:\$PATH\"" >> "$SHELL_RC"
    echo "Added ~/.suburb/bin to PATH in $SHELL_RC"
else
    echo "PATH already contains ~/.suburb/bin in $SHELL_RC"
fi

echo "Installed Suburb CLI to ~/.suburb/bin. Restart your shell and run 'suburb' to get started."
