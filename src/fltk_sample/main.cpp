#include <cstdlib>
#include <exception>
#include <fmt/base.h>
#include <fmt/format.h>
#include <optional>


#include <CLI/CLI.hpp>
#include <spdlog/spdlog.h>


// This file will be generated automatically when cur_you run the CMake
// configuration step. It creates a namespace called `fltk_example`. You can modify
// the source template at `configured_files/config.hpp.in`.
#include <internal_use_only/config.hpp>
#include <string>

#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>

// Callback function for the button
void on_quit([[maybe_unused]] Fl_Widget* widget, [[maybe_unused]] void* data) {
    // this is not a great idea, but it's an example project
    // with a toolkit I don't fully understand
    exit(0); // NOLINT
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
    auto window = std::make_unique<Fl_Window>(340, 180, "FLTK Demo"); // NOLINT magic numbers

    // Create a button
    auto button = std::make_unique<Fl_Button>(120, 70, 100, 40, "Quit"); // NOLINT magic numbers
    button->callback(on_quit);

    window->end();   // End window construction
    window->show(argc, argv);  // Show the window

    return Fl::run();  // Start the FLTK event loop
  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
  }
}
