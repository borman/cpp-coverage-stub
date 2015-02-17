# vim: et sw=4

# Only include code coverage when "Coverage"
# build type is selected. Measuring coverage with
# optimization enabled is useless anyway.
if (${CMAKE_BUILD_TYPE} STREQUAL "Coverage")
    include(CodeCoverage)
endif()

# Link with "target" library
set(MYLIBS coverage_stub)
# Use "target" library's headers
include_directories(${PROJECT_SOURCE_DIR}/library)

# The following is required for test coverage assessment
# it prevents untested objects from library from not being linked
# Different linkers use different command line arguments
# for controlling whether all object files are linked.
if (APPLE)
    # Apple ld
    link_libraries(-Wl,-all_load ${MYLIBS})
else()
    # GNU ld
    link_libraries(-Wl,-whole-archive ${MYLIBS} -Wl,-no-whole-archive)
endif()

# Add tests to run
add_executable(run_test test.cpp)
add_test(test run_test)

# Add coverage target
if (CMAKE_BUILD_TYPE STREQUAL "Coverage")
    setup_target_for_coverage(
        test_coverage  # test target
        run_test       # test command
        tests/coverage # output directory
    )
endif()
