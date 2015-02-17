# CHANGELOG:
#
# 2012-01-31, Lars Bilke
# - Enable Code Coverage
#
# 2013-09-17, Joakim Söderberg
# - Added support for Clang.
# - Some additional usage instructions.
#
# 2014-2015, Mikhail Borisov
# - Massive refactoring of cmake script
# - Introduce `Coverage' build type
# - Handle various compiler-related glitches
# - Use bundled versions of coverage-processing scripts
# - Use lcov_cobertura.py to generate a Cobertura-comatible report


# USAGE:
#
# 1. Copy this file into your cmake modules path.
#
# 2. Add the following line to your CMakeLists.txt:
#
#    include(CodeCoverage)
#
# 3. Use the function `setup_target_for_coverage' to create a custom make target
#    which runs your test executable and produces a lcov code coverage report:
#    Example:
#
#    setup_target_for_coverage(
#        my_coverage_target  # Name for custom target.
#        test_driver         # Name of the test driver executable that runs the tests.
#                            # NOTE! This should always have a ZERO as exit code
#                            # otherwise the coverage generation will not complete.
#        coverage            # Name of output directory.
#    )
#
# 4. Build a `Coverage' build:
#
#    cmake -DCMAKE_BUILD_TYPE=Coverage ..
#    make
#    make my_coverage_target



# Check prereqs
find_program(GCOV_PATH gcov)
find_program(LCOV_PATH lcov
    NO_DEFAULT_PATH
    PATHS
        ${CMAKE_SOURCE_DIR}/scripts
)
find_program(GENHTML_PATH genhtml
    NO_DEFAULT_PATH
    PATHS
        ${CMAKE_SOURCE_DIR}/scripts
)

find_program(LCOV_COBERTURA_PATH lcov_cobertura.py
    NO_DEFAULT_PATH
    PATHS
        ${CMAKE_SOURCE_DIR}/scripts
)

if (GCOV_PATH)
    message(STATUS "Found gcov: ${GCOV_PATH}")
else()
    message(FATAL_ERROR "gcov not found! Aborting...")
endif() # GCOV_PATH

if (LCOV_PATH)
    message(STATUS "Found lcov: ${LCOV_PATH}")
endif()

if (GENHTML_PATH)
    message(STATUS "Found genhtml: ${GENHTML_PATH}")
endif()

if (LCOV_COBERTURA_PATH)
    message(STATUS "Found lcov_cobertura.py: ${LCOV_COBERTURA_PATH}")
endif()


if (NOT CMAKE_COMPILER_IS_GNUCXX)
    # Clang version 3.0.0 and greater now supports gcov as well.
    message(WARNING "Compiler is not GNU gcc! Clang Version 3.0.0 and greater supports gcov as well, but older versions don't.")

    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        message(FATAL_ERROR "Compiler is not GNU gcc! Aborting...")
    endif()
endif() # NOT CMAKE_COMPILER_IS_GNUCXX


set(CMAKE_CXX_FLAGS_COVERAGE
    "-g -O0 --coverage -fkeep-inline-functions"
    CACHE STRING
        "Flags used by the C++ compiler during coverage builds."
    FORCE
)
set(CMAKE_C_FLAGS_COVERAGE
    "-g -O0 --coverage -fkeep-inline-functions"
    CACHE STRING
        "Flags used by the C compiler during coverage builds."
    FORCE
)
set(CMAKE_EXE_LINKER_FLAGS_COVERAGE
    "--coverage"
    CACHE STRING
        "Flags used for linking binaries during coverage builds."
    FORCE
)
set(CMAKE_SHARED_LINKER_FLAGS_COVERAGE
    "--coverage"
    CACHE STRING
        "Flags used by the shared libraries linker during coverage builds."
    FORCE
)

mark_as_advanced(
    CMAKE_CXX_FLAGS_COVERAGE
    CMAKE_C_FLAGS_COVERAGE
    CMAKE_EXE_LINKER_FLAGS_COVERAGE
    CMAKE_SHARED_LINKER_FLAGS_COVERAGE
)

if (CMAKE_BUILD_TYPE STREQUAL "Coverage" AND CMAKE_COMPILER_IS_GNUCXX)
    # linking fails with -fkeep-inline-functions
    # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=51333
    link_libraries(supc++)
endif()


if (NOT (CMAKE_BUILD_TYPE STREQUAL "Debug"
      OR CMAKE_BUILD_TYPE STREQUAL "Coverage"))

    message( WARNING "Code coverage results with an optimized (non-Debug) build may be misleading" )

endif()


# Param _targetname     The name of new the custom make target
# Param _testrunner     The name of the target which runs the tests.
#                        MUST return ZERO always, even on errors.
#                        If not, no coverage report will be created!
# Param _outputname     lcov output is generated as _outputname.info
#                       HTML report is generated in _outputname/index.html
#                       Cobertura report is generated in _outputname.xml
# Optional fourth parameter is passed as arguments to _testrunner
#   Pass them in list form, e.g.: "-j;2" for -j 2
function(setup_target_for_coverage _targetname _testrunner _outputname)

    if (NOT LCOV_PATH)
        message(FATAL_ERROR "lcov not found! Aborting...")
    endif() # NOT LCOV_PATH

    if (NOT GENHTML_PATH)
        message(FATAL_ERROR "genhtml not found! Aborting...")
    endif() # NOT GENHTML_PATH

    if (NOT LCOV_COBERTURA_PATH)
        message(FATAL_ERROR "lcov_cobertura.py not found! Aborting...")
    endif() # NOT LCOV_COBERTURA_PATH

    set(LCOV_BRANCHES --rc lcov_branch_coverage=1)
    set(LCOV_TOOL ${LCOV_PATH} ${LCOV_BRANCHES} --gcov-tool ${GCOV_PATH})
    set(GENHTML_TOOL ${GENHTML_PATH} ${LCOV_BRANCHES})

    # Setup target
    add_custom_target(${_targetname}
        # Cleanup lcov
        ${LCOV_TOOL} --directory .
            --zerocounters

        # Run tests
        COMMAND
            ${_testrunner} ${ARGV3}

        # Capture "raw" lcov counters
        COMMAND
            ${LCOV_TOOL} --directory .
            --capture
            --output-file ${_outputname}.info

        # Remove coverage counters for system and imported libraries
        # and test code
        COMMAND
            ${LCOV_TOOL}
            --remove ${_outputname}.info '*/gtest*' 'tests/*' '/usr/*' '*/contrib/*'
            --output-file ${_outputname}.info.cleaned

        # Create HTML report for humans
        COMMAND
            ${GENHTML_TOOL}
            -o ${_outputname} ${_outputname}.info.cleaned

        # Create Cobertura report for CI tools
        COMMAND
            ${LCOV_COBERTURA_PATH} ${_outputname}.info.cleaned
            --base-dir=${CMAKE_SOURCE_DIR}
            --output=${_outputname}.xml

        # Remove intermediate files
        # COMMAND
        #    ${CMAKE_COMMAND} -E remove
        #    ${_outputname}.info ${_outputname}.info.cleaned

        WORKING_DIRECTORY
            ${CMAKE_BINARY_DIR}

        COMMENT
            "Resetting code coverage counters to zero.\nProcessing code coverage counters and generating report."
    )

    # Show info where to find the report
    add_custom_command(
        TARGET
            ${_targetname}
        POST_BUILD
        COMMAND
            ;  # Empty command
        COMMENT
            "Open ./${_outputname}/index.html in your browser to view the coverage report."
    )

endfunction() # setup_target_for_coverage
