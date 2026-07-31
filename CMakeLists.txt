cmake_minimum_required(VERSION 3.15)

project(bcsh C)

add_executable(
    bcsh
    src/main.c
)

target_compile_options(
    bcsh PRIVATE
    -O2
)

target_link_options(
    bcsh PRIVATE
    -static
)
