CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)

FILE(GLOB src *.cc *.h)
FILE(GLOB luasrc *.lua)
SET(luasrc ${luasrc} neswrap.inl)

MESSAGE(STATUS "CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}")
MESSAGE(STATUS "TORCH_INSTALL_PREFIX ${TORCH_INSTALL_PREFIX}")
MESSAGE(STATUS "LUAROCKS_INSTALL_PREFIX ${LUAROCKS_INSTALL_PREFIX}")

IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    MESSAGE(STATUS "Using Clang")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")        ## Optimize
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftemplate-depth=1024")
    MESSAGE(STATUS "FLAGS ${CMAKE_CXX_FLAGS}")
# Using GCC.

# DEBUG - adding debug symbols and deleting -O3
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    MESSAGE(STATUS "Using GCC")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")        ## Optimize 
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")        ## Optimize
    MESSAGE(STATUS "FLAGS ${CMAKE_CXX_FLAGS}")
# Using Intel C++.
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    MESSAGE(STATUS "Using Intel C++")
# Using Visual Studio C++.
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    MESSAGE(STATUS "Using Visual Studio C++")
ENDIF()


# We specify the paths to includes and library.
# INCLUDE_DIRECTORIES(${Torch_SOURCE_INCLUDES})
find_path(FCEUX_INCLUDE_DIR fceux/nes_interface.hpp
          HINTS 
          ${TORCH_INSTALL_PREFIX}/include
          ${CMAKE_INSTALL_PREFIX}/include
          ${CMAKE_INSTALL_PREFIX}/../../../../../include
          ${LUAROCKS_INSTALL_PREFIX}/../../../../../include
          PATH_SUFFIXES include)

find_path(FCEUX_LIBRARY_DIR NAMES libfceux.so
          HINTS 
          ${TORCH_INSTALL_PREFIX}/lib 
          ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/../../../../../lib 
          ${LUAROCKS_INSTALL_PREFIX}/../../../../../lib)

find_library(FCEUX_LIBRARY NAMES libfceux.so
          HINTS 
          ${TORCH_INSTALL_PREFIX}/lib 
          ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/../../../../../lib 
          ${LUAROCKS_INSTALL_PREFIX}/../../../../../lib)

IF(NOT(FCEUX_INCLUDE_DIR))
  MESSAGE(ERROR "Could not find fceux include location")
ENDIF()

IF(NOT(FCEUX_LIBRARY_DIR))
  MESSAGE(ERROR "Could not find fceux library")
ENDIF()

IF(NOT(FCEUX_LIBRARY))
  MESSAGE(ERROR "Could not find fceux library")
ENDIF()

SET(INCDIR "${FCEUX_INCLUDE_DIR}")
SET(LIBDIR "${FCEUX_LIBRARY_DIR}")

INCLUDE_DIRECTORIES("${INCDIR}")
LINK_DIRECTORIES("${LIBDIR}")

ADD_TORCH_PACKAGE(neswrap "${src}" "${luasrc}" "NES Wrapper")
TARGET_LINK_LIBRARIES(neswrap ${FCEUX_LIBRARY})








