cmake_minimum_required(VERSION 3.18)
project(mathex)

set(CMAKE_CXX_STANDARD 17)
if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:__cplusplus")
endif()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

add_executable(${PROJECT_NAME} main.cpp)