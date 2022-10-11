set options="-v"
set "options=%options% -L \"A:/_Info_Projects/_Vscode_Cpp/_OS_Dev/Bootloader\""
set "options=%options% -T bootloader.ld"
@REM set "options=%options% -T \"A:/_Info Projects/_Vscode_Cpp/_OS_Dev/Bootloader/bootloader.ld\""
set "options=%options% -masm=intel"
set "options=%options% -o out"
gcc %options% main.cpp