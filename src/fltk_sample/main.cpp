#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <exception>
#include <fmt/base.h>
#include <fmt/format.h>
#include <functional>
#include <optional>

#include <random>

#include <CLI/CLI.hpp>
#include <spdlog/spdlog.h>

#include <lefticus/tools/non_promoting_ints.hpp>

// This file will be generated automatically when cur_you run the CMake
// configuration step. It creates a namespace called `fltk_example`. You can modify
// the source template at `configured_files/config.hpp.in`.
#include <internal_use_only/config.hpp>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>

// Callback function for the button
void on_quit([[maybe_unused]] Fl_Widget* w, [[maybe_unused]] void* data) {
    exit(0);
}

int main(int argc, char **argv)
{
  try {
    CLI::App app{ fmt::format("{} version {}", fltk_example::cmake::project_name, fltk_example::cmake::project_version) };

    std::optional<std::string> message;
    app.add_option("-m,--message", message, "A message to print back out");
    bool show_version = false;
    app.add_flag("--version", show_version, "Show version information");

    CLI11_PARSE(app, argc, argv);

    if (show_version) {
      fmt::print("{}\n", fltk_example::cmake::project_version);
      return EXIT_SUCCESS;
    }

    // Create a window
    Fl_Window *window = new Fl_Window(340, 180, "FLTK Demo");

    // Create a button
    Fl_Button *button = new Fl_Button(120, 70, 100, 40, "Quit");
    button->callback(on_quit);

    window->end();   // End window construction
    window->show(argc, argv);  // Show the window

    return Fl::run();  // Start the FLTK event loop
  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
  }
}
