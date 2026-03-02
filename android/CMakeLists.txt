cmake_minimum_required(VERSION 3.13)
project(imageprocessing)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD 17)

add_library(
  react-native-image-processing
  SHARED
  ../cpp/react-native-image-processing.cpp
  src/main/cpp/JsiInstaller.cpp
)

find_package(ReactAndroid REQUIRED CONFIG)

target_include_directories(
        react-native-image-processing
        PRIVATE
        ../cpp
)

target_link_libraries(
  react-native-image-processing
  ReactAndroid::jsi
)
