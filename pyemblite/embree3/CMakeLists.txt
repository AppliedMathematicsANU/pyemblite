
MESSAGE(STATUS "Finding embree3...")
find_package(embree 3 CONFIG REQUIRED)
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/pyemblite/include)

IF ( embree_FOUND )

  MESSAGE(STATUS "Found embree version ${embree_VERSION}.")

  foreach (cymod rtcore rtcore_scene mesh_construction test_scene)
    SET(cymod_target "${cymod}${embree_VERSION_MAJOR}")
    add_cython_target(${cymod_target} ${cymod_target}.pyx CXX PY3 OUTPUT_VAR cymod_target_sources)
    add_library(${cymod_target} MODULE ${cymod_target_sources})
    PYTHON_EXTENSION_MODULE(${cymod_target})
    target_link_libraries(${cymod_target} embree)
    INSTALL(
      TARGETS ${cymod_target}
      RUNTIME_DEPENDENCIES
      PRE_INCLUDE_REGEXES ${VCPKG_DEPENDENCIES}
      PRE_EXCLUDE_REGEXES ".*"
      DESTINATION "pyemblite/embree${embree_VERSION_MAJOR}"
    )
  endforeach()

ENDIF()
