cmake_minimum_required(VERSION 3.16...3.21)

################################################################################
# OBS Plugin Template
################################################################################

# Change obs-plugintemplate to your plugin's name in a machine-readable format (e.g.:
# obs-myawesomeplugin) and set
add_library(${CMAKE_PROJECT_NAME} MODULE)

# Replace `Your Name Here` with the name (yours or your organization's) you want to see as the
# author of the plugin (in the plugin's metadata itself and in the installers)
set(PLUGIN_AUTHOR "${PROJECT_AUTHORS}")

# Replace `com.example.obs-plugin-template` with a unique Bundle ID for macOS releases (used both in
# the installer and when submitting the installer for notarization)
set(MACOS_BUNDLEID "com.elgato.ElgatoRemoteControlOBS")

# Replace `me@contoso.com` with the maintainer email address you want to put in Linux packages
set(LINUX_MAINTAINER_EMAIL "")

set(PROJECT_DEFINITIONS )
list(APPEND PROJECT_DEFINITIONS
    -DASIO_STANDALONE
    -D_WEBSOCKETPP_CPP11_STL_
)
list(APPEND PROJECT_DEFINITIONS
    -DVERSION_STR=\"${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}\"
)

target_compile_definitions(${PROJECT_NAME} PRIVATE ${PROJECT_DEFINITIONS})

# Add your custom source files here - header files are optional and only required for visibility
# e.g. in Xcode or Visual Studio

if(NOT BUILD_LOADER)
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE
            "source/module.hpp"
            "source/module.cpp"
            "source/json-rpc.hpp"
            "source/json-rpc.cpp"
            "source/server.hpp"
            "source/server.cpp"
            "source/handlers/handler-system.hpp"
            "source/handlers/handler-system.cpp"
            "source/handlers/handler-obs-frontend.hpp"
            "source/handlers/handler-obs-frontend.cpp"
            "source/handlers/handler-obs-source.hpp"
            "source/handlers/handler-obs-source.cpp"
            "source/handlers/handler-obs-scene.hpp"
            "source/handlers/handler-obs-scene.cpp"
            "source/details-popup.cpp"
            "source/details-popup.hpp"
            "${PROJECT_BINARY_DIR}/generated/module.cpp"
                        
    )

    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
            "${PROJECT_BINARY_DIR}/generated"
            "${PROJECT_SOURCE_DIR}/source"
            "third-party/nlohmann-json/single_include/"
            "third-party/websocketpp/"
            "${ASIO_PATH}/asio/include"
    )
else()
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE
        "source/loader/module.cpp"
    )
    #set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES LINKER_LANGUAGE CXX)
endif()


# Import libobs as main plugin dependency
find_package(libobs REQUIRED)
include(cmake/ObsPluginHelpers.cmake)


if(NOT BUILD_LOADER)
    # Uncomment these lines if you want to use the OBS Frontend API in your plugin
    find_package(obs-frontend-api REQUIRED)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)

    find_qt(COMPONENTS Widgets Core)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt::Core Qt::Widgets)
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        AUTOMOC ON
        AUTOUIC ON
        AUTORCC ON
        AUTOUIC_SEARCH_PATHS "${PROJECT_SOURCE_DIR};${PROJECT_SOURCE_DIR}/ui"
    )
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)

# Configure Files
configure_file(
    "templates/config.hpp.in"
    "generated/config.hpp"
)

configure_file(
    "templates/version.hpp.in"
    "generated/version.hpp"
)
configure_file(
    "templates/module.cpp.in"
    "generated/module.cpp"
)

if(D_PLATFORM_WINDOWS) # Windows Support
    set(PROJECT_PRODUCT_NAME "${PROJECT_FULL_NAME}")
    set(PROJECT_COMPANY_NAME "${PROJECT_AUTHORS}")
    set(PROJECT_COPYRIGHT "${PROJECT_COPYRIGHT_YEARS}, ${PROJECT_AUTHORS}")
    set(PROJECT_LEGAL_TRADEMARKS_1 "")
    set(PROJECT_LEGAL_TRADEMARKS_2 "")

    configure_file(
        "templates/version.rc.in"
        "generated/version.rc"
        @ONLY
    )
endif()


# /!\ TAKE NOTE: No need to edit things past this point /!\

# --- Platform-independent build settings ---

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/src)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

# --- End of section ---

# --- Windows-specific build settings and tasks ---
if(OS_WINDOWS)
  configure_file(cmake/bundle/windows/installer-Windows.iss.in
                 ${CMAKE_BINARY_DIR}/installer-Windows.generated.iss)

  configure_file(cmake/bundle/windows/resource.rc.in ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.rc)
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.rc)

  if(MSVC)
    target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE /W4)
  endif()
  # --- End of section ---

  # -- macOS specific build settings and tasks --
elseif(OS_MACOS)
  configure_file(cmake/bundle/macos/installer-macos.pkgproj.in
                 ${CMAKE_BINARY_DIR}/installer-macos.generated.pkgproj)

  set(MACOSX_PLUGIN_GUI_IDENTIFIER "${MACOS_BUNDLEID}")
  set(MACOSX_PLUGIN_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}")
  set(MACOSX_PLUGIN_SHORT_VERSION_STRING "1")

  target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE -Wall)
  # --- End of section ---

  # --- Linux-specific build settings and tasks ---
else()
  target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE -Wall)
endif()
# --- End of section ---

setup_plugin_target(${CMAKE_PROJECT_NAME})
