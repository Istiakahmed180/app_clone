cmake_minimum_required(VERSION 3.22.1)
project(storageprobe)

add_library(storageprobe SHARED native_probe.cpp)

find_library(log-lib log)
target_link_libraries(storageprobe ${log-lib})
