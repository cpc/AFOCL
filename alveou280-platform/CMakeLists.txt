
cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(afocl)
set(CMAKE_PROJECT_DESCRIPTION "AFOCL generates bitstreams for OpenCL built-in kernel implementations.")

enable_testing()

add_subdirectory(tests)
