cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_CXX_STANDARD 14)

add_compile_options(-masm=intel)
add_compile_options(-ffreestanding)
add_compile_options(-mno-red-zone)
add_compile_options(-fno-exceptions -fno-rtti)

add_link_options(-L "A:/_Info_Projects/_Vscode_Cpp/_OS_Dev/Bootloader" -T "bootloader.ld")
add_link_options(-nostdlib)
add_link_options(-lgcc)

add_link_options(-nostdinc) # not recommended.

file(GLOB_RECURSE files "src/*.cpp")
add_executable(Aufgaben_2 BootMain.cpp ${files})
target_include_directories(Aufgaben_2 PUBLIC "src")
