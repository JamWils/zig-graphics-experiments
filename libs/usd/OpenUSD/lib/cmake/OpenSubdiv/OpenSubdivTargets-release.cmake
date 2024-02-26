#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "OpenSubdiv::osdCPU_static" for configuration "Release"
set_property(TARGET OpenSubdiv::osdCPU_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::osdCPU_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libosdCPU.a"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::osdCPU_static )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::osdCPU_static "${_IMPORT_PREFIX}/lib/libosdCPU.a" )

# Import target "OpenSubdiv::osdGPU_static" for configuration "Release"
set_property(TARGET OpenSubdiv::osdGPU_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::osdGPU_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libosdGPU.a"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::osdGPU_static )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::osdGPU_static "${_IMPORT_PREFIX}/lib/libosdGPU.a" )

# Import target "OpenSubdiv::osdCPU" for configuration "Release"
set_property(TARGET OpenSubdiv::osdCPU APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::osdCPU PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libosdCPU.3.6.0.dylib"
  IMPORTED_SONAME_RELEASE "@rpath/libosdCPU.3.6.0.dylib"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::osdCPU )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::osdCPU "${_IMPORT_PREFIX}/lib/libosdCPU.3.6.0.dylib" )

# Import target "OpenSubdiv::osdGPU" for configuration "Release"
set_property(TARGET OpenSubdiv::osdGPU APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::osdGPU PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libosdGPU.3.6.0.dylib"
  IMPORTED_SONAME_RELEASE "@rpath/libosdGPU.3.6.0.dylib"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::osdGPU )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::osdGPU "${_IMPORT_PREFIX}/lib/libosdGPU.3.6.0.dylib" )

# Import target "OpenSubdiv::OpenSubdiv_static" for configuration "Release"
set_property(TARGET OpenSubdiv::OpenSubdiv_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::OpenSubdiv_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/OpenSubdiv_static.framework/Versions/A/OpenSubdiv_static"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::OpenSubdiv_static )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::OpenSubdiv_static "${_IMPORT_PREFIX}/lib/OpenSubdiv_static.framework/Versions/A/OpenSubdiv_static" )

# Import target "OpenSubdiv::OpenSubdiv" for configuration "Release"
set_property(TARGET OpenSubdiv::OpenSubdiv APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSubdiv::OpenSubdiv PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/OpenSubdiv.framework/Versions/A/OpenSubdiv"
  IMPORTED_SONAME_RELEASE "@rpath/OpenSubdiv.framework/OpenSubdiv/OpenSubdiv.framework/Versions/A/OpenSubdiv"
  )

list(APPEND _cmake_import_check_targets OpenSubdiv::OpenSubdiv )
list(APPEND _cmake_import_check_files_for_OpenSubdiv::OpenSubdiv "${_IMPORT_PREFIX}/lib/OpenSubdiv.framework/Versions/A/OpenSubdiv" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
