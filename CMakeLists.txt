# vim et sw=4

cmake_minimum_required (VERSION 2.8.7)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/)

project(cpp-coverage-stub)
enable_testing()

# Update the documentation string of CMAKE_BUILD_TYPE: add Coverage
set(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
    "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel Coverage."
    FORCE
)

add_subdirectory(library)
add_subdirectory(tests)
