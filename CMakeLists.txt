cmake_minimum_required(VERSION 2.6)
project(SIP)

# Options
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build, options are: None (CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif()

if (NOT DEFINED SIP_PYTHON_INTERPRETER)
    set(SIP_PYTHON_INTERPRETER "python" CACHE STRING "The python interpreter for which the modules must be generated")
endif()

if (NOT DEFINED SIP_PYTHON_INCLUDE_PATH)
    set(SIP_PYTHON_INCLUDE_PATH "" CACHE STRING "Include path for the header files of Python (can be blank for the default interpreter)")
endif()

if (NOT DEFINED SIP_PYTHON_LIBRARIES)
    set(SIP_PYTHON_LIBRARIES "" CACHE STRING "Libraries to link for Python (can be blank for the default interpreter)")
endif()


# Set the output path
if (NOT DEFINED SIP_BINARY_DIRECTORY)
    set(SIP_BINARY_DIRECTORY "${SIP_BINARY_DIR}")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${SIP_BINARY_DIR}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${SIP_BINARY_DIR}/bin")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${SIP_BINARY_DIR}/lib")
endif()

# XMake settings
if (EXISTS "${SIP_SOURCE_DIR}/xmake/XMake.cmake")
    include("${SIP_SOURCE_DIR}/xmake/XMake.cmake")
endif()

if (DEFINED XMAKE_VERSION)
    xmake_init_dynamic(SIP)
    xmake_add_include_paths(SIP ${SIP_SOURCE_DIR}/siplib)
    xmake_add_link_paths(SIP "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
    xmake_add_link_targets(SIP siplib)
endif()


# Find the instance of Python to use
if (NOT SIP_PYTHON_INCLUDE_PATH)
    include(FindPythonLibs)
    SET(SIP_PYTHON_INCLUDE_PATH "${PYTHON_INCLUDE_PATH}")
    SET(SIP_PYTHON_LIBRARIES "${PYTHON_LIBRARIES}")
endif()

include_directories("${SIP_PYTHON_INCLUDE_PATH}")


# We use an external script to configure SIP
add_custom_target(sip-configuration ALL "${SIP_SOURCE_DIR}/configure_sip.sh" "${SIP_SOURCE_DIR}" "${SIP_PYTHON_INTERPRETER}"
                  WORKING_DIRECTORY "${SIP_BINARY_DIR}"
                  COMMENT "Configuring SIP")


# List the source files of the library
set(LIB_SRCS siplib/apiversions.c
             siplib/bool.cpp
             siplib/descriptors.c
             siplib/objmap.c
             siplib/qtlib.c
             siplib/siplib.c
             siplib/threads.c
             siplib/voidptr.c
)


# Declaration of the library
add_library(siplib SHARED ${LIB_SRCS})
add_dependencies(siplib sip-configuration)
set_target_properties(siplib PROPERTIES LINK_FLAGS "${SIP_PYTHON_LIBRARIES}"
                                        OUTPUT_NAME "sip")


# List the source files of the executable
set(EXE_SRCS sipgen/export.c
             sipgen/extracts.c
             sipgen/gencode.c
             sipgen/heap.c
             sipgen/lexer.c
             sipgen/main.c
             sipgen/parser.c
             sipgen/transform.c
)


# Declaration of the executable
add_executable(sip ${EXE_SRCS})
add_dependencies(sip sip-configuration)

if (NOT WIN32)
    set_target_properties(sip PROPERTIES COMPILE_FLAGS "-fPIC")
    set_target_properties(siplib PROPERTIES COMPILE_FLAGS "-fPIC")
endif()
