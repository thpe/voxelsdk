FUNCTION(create_cmake_config package targets component build_include_dir)
# Add all targets to the build-tree export set
export(TARGETS ${targets}
  FILE "${PROJECT_BINARY_DIR}/${package}Targets.cmake" NAMESPACE Voxel::)

string(TOUPPER ${package} UPACKAGE)

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE ${package})

if(WINDOWS)
  set(INSTALL_CMAKE_DIR CMake)
elseif(LINUX)
  set(INSTALL_CMAKE_DIR lib/cmake/${package})
endif()

# Create the FooBarConfig.cmake and FooBarConfigVersion files
file(RELATIVE_PATH REL_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/${INSTALL_CMAKE_DIR} "${CMAKE_INSTALL_PREFIX}/include/voxel-${VOXEL_VERSION}")
# ... for the build tree
set(CONF_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/${build_include_dir}" "${PROJECT_BINARY_DIR}/${build_include_dir}")
configure_file("${PROJECT_SOURCE_DIR}/config/${package}Config.cmake.in" "${PROJECT_BINARY_DIR}/${package}Config.cmake" @ONLY)
# ... for the install tree
set(CONF_INCLUDE_DIRS "\${${UPACKAGE}_CMAKE_DIR}/${REL_INCLUDE_DIR}")
configure_file("${PROJECT_SOURCE_DIR}/config/${package}Config.cmake.in" "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${package}Config.cmake" @ONLY)
# ... for both
configure_file("${PROJECT_SOURCE_DIR}/config/${package}ConfigVersion.cmake.in" "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake" @ONLY)

# Install the FooBarConfig.cmake and FooBarConfigVersion.cmake
install(FILES
    "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${package}Config.cmake"
    "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake"
  DESTINATION ${INSTALL_CMAKE_DIR} COMPONENT ${component})

# Install the export set for use with the install-tree
install(EXPORT ${package}Targets
  DESTINATION ${INSTALL_CMAKE_DIR}
  NAMESPACE Voxel::
  COMPONENT ${component})

ENDFUNCTION()


function(set_output_directory target path)
  if(NOT CMAKE_CONFIGURATION_TYPES)
    set_target_properties(${target}
      PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${path}
        RUNTIME_OUTPUT_DIRECTORY ${path}
        ARCHIVE_OUTPUT_DIRECTORY ${path}
      )
  else()
    foreach(config ${CMAKE_CONFIGURATION_TYPES})
      string(TOUPPER ${config} c)
      set_target_properties(${target}
        PROPERTIES
          LIBRARY_OUTPUT_DIRECTORY_${c} ${path}
          RUNTIME_OUTPUT_DIRECTORY_${c} ${path}
          ARCHIVE_OUTPUT_DIRECTORY_${c} ${path}
      )
    endforeach()
  endif()
endfunction()

function(get_library_output_directory OUTDIR)
  set(OUTDIR ${PROJECT_BINARY_DIR}/lib/${ARGV0} PARENT_SCOPE)
endfunction()

function(set_library_output_directory target)
  set_output_directory(${target} ${PROJECT_BINARY_DIR}/lib/${ARGV1})
endfunction()

function(set_voxel_library_output_directory target)
  set_library_output_directory(${target} voxel)
endfunction()

function (read_config filename key value)
  file (STRINGS ${filename} _config
        REGEX "^${key}="
        )
  string (REGEX REPLACE
        "^${key}=\"?\(.*\)\"?" "\\1" val "${_config}"
        )
  set(${value} "${val}" PARENT_SCOPE)
endfunction()

if(LINUX)
  function(get_distribution_codename codename)
    if (EXISTS "/etc/lsb-release")
      read_config(/etc/lsb-release DISTRIB_CODENAME cn)
    else ()
      execute_process(COMMAND lsb_release -s -c OUTPUT_VARIABLE cn)
    endif ()
    set(${codename} "${cn}" PARENT_SCOPE)
  endfunction()


  function(create_cpack_config name ver)
    set(CPACK_PACKAGE_VERSION "${ver}")
    set(CPACK_PACKAGE_NAME "${name}")
    get_distribution_codename(codename)
    set(CPACK_PACKAGE_FILE_NAME "${name}-${ver}-${ARCH}-${codename}")
    set(CPACK_OUTPUT_CONFIG_FILE "${CMAKE_BINARY_DIR}/CPackConfig-${name}.cmake")
    include(CPack)
  endfunction(create_cpack_config)
endif()
