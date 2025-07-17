
MESSAGE(STATUS "Finding embree4...")
find_package(embree 4 CONFIG)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

IF ( embree_FOUND )

  MESSAGE(STATUS "Found embree version ${embree_VERSION}.")

ENDIF()
