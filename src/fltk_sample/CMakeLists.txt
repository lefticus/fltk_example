add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE fltk_example::fltk_example_options
          fltk_example::fltk_example_warnings)

target_link_system_libraries(
  intro
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          fltk::fltk)

target_include_directories(intro PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
