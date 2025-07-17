
MESSAGE(STATUS "Finding embree3...")
find_package(embree 3 CONFIG REQUIRED)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

IF ( embree_FOUND )

  MESSAGE(STATUS "Found embree version ${embree_VERSION}.")

  foreach (cymod rtcore rtcore_scene mesh_construction test_scene)
    add_cython_target(${cymod} ${cymod}.pyx CXX PY3)
    add_library(${cymod} MODULE ${cymod})
    PYTHON_EXTENSION_MODULE(${cymod})
    target_link_libraries(${cymod} embree)
    INSTALL(
      TARGETS ${cymod}
      RUNTIME_DEPENDENCIES
      PRE_INCLUDE_REGEXES ${VCPKG_DEPENDENCIES}
      PRE_EXCLUDE_REGEXES ".*"
      DESTINATION pyemblite/embree3
    )
  endforeach()

ENDIF()
