cmake_minimum_required( VERSION 3.1.0 FATAL_ERROR )

project( "restbed" VERSION 4.7.0 LANGUAGES CXX )
message( "Copyright 2013-2018, Corvusoft Ltd, All Rights Reserved." )

#
# Build Options
#
option( BUILD_SSL      "Build secure socket layer support."  ON )
option( BUILD_TESTS    "Build unit tests."  ON )
option( BUILD_COVERAGE    "Build code coverage tests."  ON )
option( BUILD_STATIC   "Build static library."  ON )
option( BUILD_SHARED   "Build shared library."  OFF )

#
# Configuration
#
set( CMAKE_CXX_STANDARD 11 )
set( INCLUDE_DIR "${PROJECT_SOURCE_DIR}/source" )
set( SOURCE_DIR  "${PROJECT_SOURCE_DIR}/source/corvusoft/${PROJECT_NAME}" )
set( CMAKE_BINARY_DIR  "${PROJECT_SOURCE_DIR}/build" )
set( CMAKE_LD_FLAGS  "${CMAKE_LD_FLAGS} -lgcov --coverage" )
	
if ( NOT DEFINED CMAKE_INSTALL_LIBDIR )
    set( CMAKE_INSTALL_LIBDIR lib )
endif ( )

if ( CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT )
    set( CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}/distribution" CACHE PATH "Install path prefix" FORCE )
endif ( )

if( ${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC )
    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /D_WIN32_WINNT=0x0601 /W4 /wd4068 /wd4702" )
endif ( )

if( NOT WIN32 )
    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Weffc++ -pedantic -Wno-unknown-pragmas" )
endif ( )

if ( UNIX AND NOT APPLE )
    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread" )
endif ( )

if ( APPLE )
    set( CMAKE_MACOSX_RPATH ON )
endif ( )

set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake" )

find_package( asio REQUIRED )
if ( BUILD_SSL )
    find_package( openssl REQUIRED )
endif ( )

if ( BUILD_COVERAGE )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g ")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif ( )

if ( BUILD_VALGRIND )
    set(MEMORYCHECK_COMMAND_OPTIONS "${MEMORYCHECK_COMMAND_OPTIONS} --leak-check=full")
    set(MEMORYCHECK_COMMAND_OPTIONS "${MEMORYCHECK_COMMAND_OPTIONS} --track-fds=yes")
    set(MEMORYCHECK_COMMAND_OPTIONS "${MEMORYCHECK_COMMAND_OPTIONS} --trace-children=yes")
    set(MEMORYCHECK_COMMAND_OPTIONS "${MEMORYCHECK_COMMAND_OPTIONS} --error-exitcode=1")
endif ( )

include_directories( ${INCLUDE_DIR} SYSTEM ${asio_INCLUDE} ${kashmir_INCLUDE} ${ssl_INCLUDE} )

#
# Build
#
file( GLOB_RECURSE MANIFEST "${SOURCE_DIR}/*.cpp" )

if ( BUILD_STATIC )
    set( STATIC_LIBRARY_NAME "${PROJECT_NAME}-static" )
    add_library( ${STATIC_LIBRARY_NAME} STATIC ${MANIFEST} )
    set_property( TARGET ${STATIC_LIBRARY_NAME} PROPERTY CXX_STANDARD 11 )
    set_property( TARGET ${STATIC_LIBRARY_NAME} PROPERTY CXX_STANDARD_REQUIRED ON )
    set_target_properties( ${STATIC_LIBRARY_NAME} PROPERTIES OUTPUT_NAME ${PROJECT_NAME} )
    if ( BUILD_SSL )
        target_link_libraries( ${STATIC_LIBRARY_NAME} LINK_PRIVATE ${ssl_LIBRARY_STATIC} ${crypto_LIBRARY_STATIC} ${CMAKE_DL_LIBS})
    else ( )
        target_link_libraries( ${STATIC_LIBRARY_NAME} ${CMAKE_DL_LIBS})
    endif ( )
endif ( )

if ( BUILD_SHARED )
    set( SHARED_LIBRARY_NAME "${PROJECT_NAME}-shared" )
    add_library( ${SHARED_LIBRARY_NAME} SHARED ${MANIFEST} )
    set_property( TARGET ${SHARED_LIBRARY_NAME} PROPERTY CXX_STANDARD 11 )
    set_property( TARGET ${SHARED_LIBRARY_NAME} PROPERTY CXX_STANDARD_REQUIRED ON )
    set_target_properties( ${SHARED_LIBRARY_NAME} PROPERTIES OUTPUT_NAME ${PROJECT_NAME} )
    set_target_properties( ${SHARED_LIBRARY_NAME} PROPERTIES SOVERSION ${PROJECT_VERSION_MAJOR} VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} )
    if ( BUILD_SSL )
        target_link_libraries( ${SHARED_LIBRARY_NAME} LINK_PRIVATE ${ssl_LIBRARY_SHARED} ${crypto_LIBRARY_SHARED} )
    else ( )
        target_link_libraries( ${SHARED_LIBRARY_NAME} )
    endif ( )
endif ( )

# Create the gcov target. Run coverage tests with 'make gcov'
add_custom_target(gcov
    COMMAND mkdir -p coverage
    COMMAND ${CMAKE_MAKE_PROGRAM} test
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
add_custom_command(TARGET gcov
    COMMAND echo "=================== GCOV ===================="
    COMMAND gcov -abcfu ${CMAKE_SOURCE_DIR}/test/unit/source/*.cpp -o ${CMAKE_BINARY_DIR}/test/unit/CMakeFiles/*/source/*
    #COMMAND cat CoverageSummary.tmp
    COMMAND cp ${PROJECT_SOURCE_DIR}/test/unit/source/*.cpp ${PROJECT_SOURCE_DIR}/build/coverage
    COMMAND cp ${PROJECT_SOURCE_DIR}/build/test/unit/CMakeFiles/*/source/*.gcda ${PROJECT_SOURCE_DIR}/build/coverage
    COMMAND cp ${PROJECT_SOURCE_DIR}/build/test/unit/CMakeFiles/*/source/*.gcno ${PROJECT_SOURCE_DIR}/build/coverage
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/coverage
    COMMAND lcov --directory . --capture --output-file app.info
    COMMAND genhtml app.info
    COMMAND echo "-- Coverage files have been output to ${CMAKE_BINARY_DIR}/coverage"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/coverage  # Need separate command for this line
    )

include(CTest)

if ( BUILD_TESTS )
    find_package( catch REQUIRED )
    enable_testing( )
    add_subdirectory( "${PROJECT_SOURCE_DIR}/test/unit" )
    add_subdirectory( "${PROJECT_SOURCE_DIR}/test/feature" )
    add_subdirectory( "${PROJECT_SOURCE_DIR}/test/regression" )
    add_subdirectory( "${PROJECT_SOURCE_DIR}/test/integration" )
endif ( )

#
# Install
#
file( GLOB ARTIFACTS "${SOURCE_DIR}/*.hpp" )

install( FILES "${INCLUDE_DIR}/${PROJECT_NAME}" DESTINATION "${CMAKE_INSTALL_PREFIX}/include" )
install( FILES ${ARTIFACTS} DESTINATION "${CMAKE_INSTALL_PREFIX}/include/corvusoft/${PROJECT_NAME}" )
if ( BUILD_STATIC )
    install( TARGETS ${STATIC_LIBRARY_NAME} LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT library )
endif ( )
if ( BUILD_SHARED )
    install( TARGETS ${SHARED_LIBRARY_NAME} LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT library )
endif ( )
