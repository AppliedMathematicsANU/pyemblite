
CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

IF (NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF()

if(DEFINED CMAKE_TOOLCHAIN_FILE) # Print toolchain information
  message(STATUS "Using toolchain: ${CMAKE_TOOLCHAIN_FILE}")
elseif(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
  message(STATUS "Using toolchain: $ENV{CMAKE_TOOLCHAIN_FILE}")
  set(CMAKE_TOOLCHAIN_FILE
    "$ENV{CMAKE_TOOLCHAIN_FILE}"
    CACHE FILEPATH ""
  )
elseif(DEFINED ENV{VCPKG_ROOT})
  message(STATUS "Using vcpkg installed in $ENV{VCPKG_ROOT}")
  set(CMAKE_TOOLCHAIN_FILE
    "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    CACHE FILEPATH ""
  )
elseif(CMAKE_FETCH_VCPKG OR DEFINED ENV{CMAKE_FETCH_VCPKG})
  message(STATUS "Fetching vcpkg")
  include(FetchContent)
  FetchContent_Declare(vcpkg
    GIT_REPOSITORY https://github.com/microsoft/vcpkg/
    GIT_TAG 2023.12.12
  )
  FetchContent_MakeAvailable(vcpkg)
  set(CMAKE_TOOLCHAIN_FILE
    "${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake"
    CACHE FILEPATH ""
  )
  message(STATUS "Fetching vcpkg -- done")
else()
  message(STATUS "No VCPKG_ROOT or CMAKE_TOOLCHAIN_FILE defined, skipping vcpkg use.")
endif()

enable_language(CXX)

MESSAGE(STATUS "Finding Python...")
FIND_PACKAGE(Python COMPONENTS Interpreter Development.Module REQUIRED)
MESSAGE(STATUS "Finding Cython...")
FIND_PACKAGE(Cython REQUIRED)
MESSAGE(STATUS "Finding NumPy...")
FIND_PACKAGE(NumPy REQUIRED)
MESSAGE(STATUS "Finding embree3...")
find_package(embree 3 CONFIG REQUIRED)
MESSAGE(STATUS "Finding PythonExtensions...")
SET(Python_ADDITIONAL_VERSIONS "${Python_VERSION_MAJOR}.${Python_VERSION_MINOR}")
FIND_PACKAGE(PythonExtensions REQUIRED)

PROJECT(pyemblite)

INCLUDE_DIRECTORIES(${PYTHON_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${NumPy_INCLUDE_DIRS})
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/pyemblite)

MESSAGE(STATUS "CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

SET(
  PYTHON_SITE_PACKAGES_INSTALL_DIR
  ${CMAKE_INSTALL_PREFIX}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages
)
SET(
  PCSR_PYTHON_SITE_PACKAGES_INSTALL_DIR
  ${PYTHON_SITE_PACKAGES_INSTALL_DIR}/pcsr
)

IF (DEFINED VCPKG_INSTALLED_DIR)
  # List `vcpkg` dependencies from VCPKG_INSTALLED_DIR so we can install them
  # together with the python API.
  FILE(
    GLOB VCPKG_DEPENDENCIES
    RELATIVE "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin/"
    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin/*"
  )
ENDIF()

foreach (cymod rtcore rtcore_scene mesh_construction test_scene)
  add_cython_target(${cymod} pyemblite/${cymod}.pyx)
  add_library(${cymod} MODULE ${cymod})
  PYTHON_EXTENSION_MODULE(${cymod})
  target_link_libraries(${cymod} embree)
  INSTALL(
    TARGETS ${cymod}
    RUNTIME_DEPENDENCIES
    PRE_INCLUDE_REGEXES ${VCPKG_DEPENDENCIES}
    PRE_EXCLUDE_REGEXES ".*"
    DESTINATION pyemblite
  )
endforeach()

