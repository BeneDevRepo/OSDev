#!/bin/bash -li

export PATH="$(realpath toolchain/bin):$PATH"

./makeIso.sh

bochsdbg.exe -q -f bochs_config_win