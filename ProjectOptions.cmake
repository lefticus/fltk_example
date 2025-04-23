include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(fltk_example_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(fltk_example_setup_options)
  option(fltk_example_ENABLE_HARDENING "Enable hardening" ON)
  option(fltk_example_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    fltk_example_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    fltk_example_ENABLE_HARDENING
    OFF)

  fltk_example_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR fltk_example_PACKAGING_MAINTAINER_MODE)
    option(fltk_example_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(fltk_example_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(fltk_example_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(fltk_example_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(fltk_example_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(fltk_example_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(fltk_example_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(fltk_example_ENABLE_PCH "Enable precompiled headers" OFF)
    option(fltk_example_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(fltk_example_ENABLE_IPO "Enable IPO/LTO" ON)
    option(fltk_example_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(fltk_example_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(fltk_example_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(fltk_example_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(fltk_example_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(fltk_example_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(fltk_example_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(fltk_example_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(fltk_example_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(fltk_example_ENABLE_PCH "Enable precompiled headers" OFF)
    option(fltk_example_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      fltk_example_ENABLE_IPO
      fltk_example_WARNINGS_AS_ERRORS
      fltk_example_ENABLE_USER_LINKER
      fltk_example_ENABLE_SANITIZER_ADDRESS
      fltk_example_ENABLE_SANITIZER_LEAK
      fltk_example_ENABLE_SANITIZER_UNDEFINED
      fltk_example_ENABLE_SANITIZER_THREAD
      fltk_example_ENABLE_SANITIZER_MEMORY
      fltk_example_ENABLE_UNITY_BUILD
      fltk_example_ENABLE_CLANG_TIDY
      fltk_example_ENABLE_CPPCHECK
      fltk_example_ENABLE_COVERAGE
      fltk_example_ENABLE_PCH
      fltk_example_ENABLE_CACHE)
  endif()

  fltk_example_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (fltk_example_ENABLE_SANITIZER_ADDRESS OR fltk_example_ENABLE_SANITIZER_THREAD OR fltk_example_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(fltk_example_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(fltk_example_global_options)
  if(fltk_example_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    fltk_example_enable_ipo()
  endif()

  fltk_example_supports_sanitizers()

  if(fltk_example_ENABLE_HARDENING AND fltk_example_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR fltk_example_ENABLE_SANITIZER_UNDEFINED
       OR fltk_example_ENABLE_SANITIZER_ADDRESS
       OR fltk_example_ENABLE_SANITIZER_THREAD
       OR fltk_example_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${fltk_example_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${fltk_example_ENABLE_SANITIZER_UNDEFINED}")
    fltk_example_enable_hardening(fltk_example_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(fltk_example_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(fltk_example_warnings INTERFACE)
  add_library(fltk_example_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  fltk_example_set_project_warnings(
    fltk_example_warnings
    ${fltk_example_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(fltk_example_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    fltk_example_configure_linker(fltk_example_options)
  endif()

  include(cmake/Sanitizers.cmake)
  fltk_example_enable_sanitizers(
    fltk_example_options
    ${fltk_example_ENABLE_SANITIZER_ADDRESS}
    ${fltk_example_ENABLE_SANITIZER_LEAK}
    ${fltk_example_ENABLE_SANITIZER_UNDEFINED}
    ${fltk_example_ENABLE_SANITIZER_THREAD}
    ${fltk_example_ENABLE_SANITIZER_MEMORY})

  set_target_properties(fltk_example_options PROPERTIES UNITY_BUILD ${fltk_example_ENABLE_UNITY_BUILD})

  if(fltk_example_ENABLE_PCH)
    target_precompile_headers(
      fltk_example_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(fltk_example_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    fltk_example_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(fltk_example_ENABLE_CLANG_TIDY)
    fltk_example_enable_clang_tidy(fltk_example_options ${fltk_example_WARNINGS_AS_ERRORS})
  endif()

  if(fltk_example_ENABLE_CPPCHECK)
    fltk_example_enable_cppcheck(${fltk_example_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(fltk_example_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    fltk_example_enable_coverage(fltk_example_options)
  endif()

  if(fltk_example_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(fltk_example_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(fltk_example_ENABLE_HARDENING AND NOT fltk_example_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR fltk_example_ENABLE_SANITIZER_UNDEFINED
       OR fltk_example_ENABLE_SANITIZER_ADDRESS
       OR fltk_example_ENABLE_SANITIZER_THREAD
       OR fltk_example_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    fltk_example_enable_hardening(fltk_example_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
