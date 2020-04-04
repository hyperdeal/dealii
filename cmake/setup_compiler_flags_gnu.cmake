## ---------------------------------------------------------------------
##
## Copyright (C) 2012 - 2018 by the deal.II authors
##
## This file is part of the deal.II library.
##
## The deal.II library is free software; you can use it, redistribute
## it, and/or modify it under the terms of the GNU Lesser General
## Public License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## The full text of the license can be found in the file LICENSE.md at
## the top level directory of deal.II.
##
## ---------------------------------------------------------------------

#
# General setup for GCC and compilers sufficiently close to GCC
#
# Please read the fat note in setup_compiler_flags.cmake prior to
# editing this file.
#

IF( CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND
    CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.9" )
  MESSAGE(WARNING "\n"
    "deal.II requires support for features of C++11 that are not present in\n"
    "versions of GCC prior to 4.9."
    )
ENDIF()

IF( CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND
    CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.0" )
  MESSAGE(WARNING "\n"
    "deal.II requires support for features of C++11 that are not present in\n"
    "versions of Clang prior to 4.0."
    )
ENDIF()


########################
#                      #
#    General setup:    #
#                      #
########################

#
# Set -pedantic if the compiler supports it.
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-pedantic")

#
# Set the pic flag.
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-fPIC")

#
# Check whether the -as-needed flag is available. If so set it to link
# the deal.II library with it.
#
ENABLE_IF_LINKS(DEAL_II_LINKER_FLAGS "-Wl,--as-needed")

#
# Setup various warnings:
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wall")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wextra")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Woverloaded-virtual")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wpointer-arith")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wsign-compare")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wsuggest-override")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wswitch")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wsynth")
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wwrite-strings")

#
# Disable Wplacement-new that will trigger a lot of warnings
# in the BOOST function classes that we include via the
# BOOST signals classes:
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-placement-new")

#
# Disable deprecation warnings
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-deprecated-declarations")

#
# Disable warning generated by Debian version of openmpi
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-literal-suffix")

#
# Disable warning about ABI changes
#
ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-psabi")

#
# Disable warnings regarding improper direct memory access
# if compiling without C++17 support
#
IF(NOT DEAL_II_WITH_CXX17)
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-class-memaccess")
ENDIF()

IF(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # Enable warnings for conversion from real types to integer types.
  # The warning is too noisy in gcc and therefore only enabled for clang.
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wfloat-conversion")

  #
  # Silence Clang warnings about unused compiler parameters (works around a
  # regression in the clang driver frontend of certain versions):
  #
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Qunused-arguments")

  #
  # Clang verbosely warns about not supporting all our friend declarations
  # (and consequently removing access control altogether)
  #
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-unsupported-friend")

  #
  # Disable a diagnostic that warns about potentially uninstantiated static
  # members. This leads to a ton of false positives.
  #
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-undefined-var-template")

  #
  # Clang versions prior to 3.6 emit a lot of false positives wrt
  # "-Wunused-function". Also suppress warnings for Xcode older than 6.3
  # (which is equivalent to clang < 3.6).
  # Policy CMP0025 allows to differentiate between Clang and AppleClang
  # which admits a more fine-grained control. Otherwise, we are left
  # with just disabling this feature for all versions between 4.0 and 6.3.
  #
  IF (POLICY CMP0025)
    IF( (CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
         AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6")
        OR (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
         AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "6.3"))
      ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-unused-function")
    ENDIF()
  ELSEIF(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6" OR
      ( NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.0" AND
        CMAKE_CXX_COMPILER_VERSION VERSION_LESS "6.3") )
    ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS "-Wno-unused-function")
  ENDIF()
ENDIF()


IF(DEAL_II_STATIC_EXECUTABLE)
  #
  # To produce a static executable, we have to statically link libstdc++
  # and gcc's support libraries and glibc:
  #
  ENABLE_IF_SUPPORTED(DEAL_II_LINKER_FLAGS "-static")
  ENABLE_IF_SUPPORTED(DEAL_II_LINKER_FLAGS "-pthread")
ENDIF()


#############################
#                           #
#    For Release target:    #
#                           #
#############################

IF (CMAKE_BUILD_TYPE MATCHES "Release")
  #
  # General optimization flags:
  #
  ADD_FLAGS(DEAL_II_CXX_FLAGS_RELEASE "-O2")

  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_RELEASE "-funroll-loops")
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_RELEASE "-funroll-all-loops")
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_RELEASE "-fstrict-aliasing")

  #
  # There are many places in the library where we create a new typedef and then
  # immediately use it in an Assert. Hence, only ignore unused typedefs in Release
  # mode.
  #
  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_RELEASE "-Wno-unused-local-typedefs")
ENDIF()


###########################
#                         #
#    For Debug target:    #
#                         #
###########################

IF (CMAKE_BUILD_TYPE MATCHES "Debug")

  LIST(APPEND DEAL_II_DEFINITIONS_DEBUG "DEBUG")
  LIST(APPEND DEAL_II_USER_DEFINITIONS_DEBUG "DEBUG")

  #
  # In recent versions, gcc often eliminates too much debug information
  # using '-Og' to be useful.
  #
  IF(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_DEBUG "-Og")
  ENDIF()
  #
  # If -Og is not available, fall back to -O0:
  #
  IF(NOT DEAL_II_HAVE_FLAG_Og)
    ADD_FLAGS(DEAL_II_CXX_FLAGS_DEBUG "-O0")
  ENDIF()

  ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_DEBUG "-ggdb")
  ENABLE_IF_SUPPORTED(DEAL_II_LINKER_FLAGS_DEBUG "-ggdb")
  #
  # If -ggdb is not available, fall back to -g:
  #
  IF(NOT DEAL_II_HAVE_FLAG_ggdb)
    ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_DEBUG "-g")
    ENABLE_IF_SUPPORTED(DEAL_II_LINKER_FLAGS_DEBUG "-g")
  ENDIF()

  IF(DEAL_II_SETUP_COVERAGE)
    #
    # Enable test coverage
    #
    ENABLE_IF_SUPPORTED(DEAL_II_CXX_FLAGS_DEBUG "-fno-elide-constructors")
    ADD_FLAGS(DEAL_II_CXX_FLAGS_DEBUG "-ftest-coverage -fprofile-arcs")
    ADD_FLAGS(DEAL_II_LINKER_FLAGS_DEBUG "-ftest-coverage -fprofile-arcs")
  ENDIF()

ENDIF()
