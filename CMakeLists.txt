cmake_minimum_required(VERSION 3.21)
project(host-gcc LANGUAGES C CXX)

# store defaults in cache so they can be overriden on the command line

set(CMAKE_C_STANDARD 11 CACHE STRING "Default C version")
set(CMAKE_CXX_STANDARD 17 CACHE STRING "Default C++ version")

message(STATUS "Standards: C${CMAKE_C_STANDARD} C++${CMAKE_CXX_STANDARD}")

set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CLANG_TIDY_OPTIONS -checks=-*,readability-* CACHE STRING "clang-tidy options" )

message(STATUS "Language versions: C++${CMAKE_CXX_STANDARD} C${CMAKE_C_STANDARD}")

# uncomment this line to include clang_tidy as part of 
# the compilation phase
# set(CMAKE_CXX_CLANG_TIDY clang-tidy ${CLANG_TIDY_OPTIONS})

if(MSVC)
add_compile_options(
    /std:c++latest
    /experimental:module	   
    /DWIN32 
    /D_WINDOWS 
    /W4 
    /GR 
    /EHsc
    $<$<CONFIG:DEBUG>:/Od>
    $<$<CONFIG:RELEASE>:/O2>
)
else()
add_compile_options(
    -Wall
    -Wextra
    -Wconversion
    -Wsign-conversion
    # -save-temps
    $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<EQUAL:${CMAKE_CXX_STANDARD},20>>:-Wno-deprecated>
    # $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<VERSION_GREATER_EQUAL:${CMAKE_CXX_STANDARD},20>>:-fcoroutines>
    $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<VERSION_GREATER_EQUAL:${CMAKE_CXX_STANDARD},20>>:-fmodules-ts>
    $<$<CONFIG:DEBUG>:-g3>
    $<$<CONFIG:DEBUG>:-Og>
    $<$<CONFIG:RELEASE>:-O3>
)
endif()

add_compile_definitions(
    $<$<CONFIG:DEBUG>:DEBUG>
    $<$<CONFIG:DEBUG>:_DEBUG>     # MSVC enables assert
    $<$<CONFIG:RELEASE>:NDEBUG>   # GCC/G++ disables asserts
)

# WARNING: wildcards are expanded at generate time, not build time
# regenerate the build if new source files are added

file (GLOB USER_SRC ${CMAKE_SOURCE_DIR}/src/*.c ${CMAKE_SOURCE_DIR}/src/*.cpp)

add_executable(Application ${USER_SRC})

target_include_directories(Application PRIVATE
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_SOURCE_DIR}/include
)

# C++20 support requires a CMakeLists.txt file to be added to the src folder
# to build a modules OBJECT with .ixx source file in required build order

if (EXISTS ${CMAKE_SOURCE_DIR}/src/CMakeLists.txt)
  if (${CMAKE_GENERATOR} STREQUAL Ninja )
    message(SEND_ERROR "C++20 module build requires Makefile generator not: ${CMAKE_GENERATOR}")
  endif()
  if (${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    set(GCM_CACHE_DIR ${CMAKE_BINARY_DIR}/gcm.cache)
    file (MAKE_DIRECTORY ${GCM_CACHE_DIR})    
    add_compile_options(
      -fmodule-mapper=|@g++-mapper-server\ -r${GCM_CACHE_DIR}
    )
  endif()

  add_subdirectory(${CMAKE_SOURCE_DIR}/src)
  target_link_libraries(Application PRIVATE modules)
endif()

set(CMAKE_THREAD_PREFER_PTHREAD ON)
set(THREADS_PREFER_PTHREAD_FLAG ON)

find_package(Threads REQUIRED)
target_link_libraries(Application PRIVATE Threads::Threads)

# strip release exe 

if (CMAKE_BUILD_TYPE STREQUAL Release)
  if ("${CMAKE_STRIP}")
    add_custom_command(
      TARGET Application
      POST_BUILD
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:Application>
    )
  else()
    message(STATUS "'strip' not found: cannot strip executable binary")
  endif()
endif()

# static analysis targets

find_program(CLANG_TIDY clang-tidy)

if (CLANG_TIDY)
    add_custom_target(
        clang-tidy clang-tidy -p ${CMAKE_BINARY_DIR} ${CLANG_TIDY_OPTIONS} ${USER_SRC}
        DEPENDS ${USER_SRC})
endif()

# optional testing

if (EXISTS ${CMAKE_SOURCE_DIR}/tests/CMakeLists.txt)
  enable_testing()
  add_subdirectory(tests)
endif()

