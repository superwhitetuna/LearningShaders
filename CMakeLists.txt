cmake_minimum_required(VERSION 3.10)
project(GLSLRenderer)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)

# Manually find GLEW (bypasses broken config)
find_path(GLEW_INCLUDE_DIR GL/glew.h HINTS /opt/homebrew/include)
find_library(GLEW_LIBRARY NAMES GLEW glew HINTS /opt/homebrew/lib)

if(NOT GLEW_INCLUDE_DIR OR NOT GLEW_LIBRARY)
    message(FATAL_ERROR "GLEW not found. Ensure it's installed via Homebrew and paths are correct.")
endif()

include_directories(${OPENGL_INCLUDE_DIR} ${GLEW_INCLUDE_DIR})

add_executable(GLSLRenderer main.cpp)

target_link_libraries(GLSLRenderer OpenGL::GL glfw ${GLEW_LIBRARY})