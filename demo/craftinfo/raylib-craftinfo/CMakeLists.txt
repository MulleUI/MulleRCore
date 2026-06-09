cmake_minimum_required( VERSION 3.13...99.99)

project( raylib-craftinfo LANGUAGES NONE)


# install build script, if any into "${DEPENDENCY_DIR}/bin"

file( GLOB SCRIPTS
   bin/raylib-build
   bin/raylib-build.*
)

list( FILTER SCRIPTS EXCLUDE REGEX ".*[.]example")

if( SCRIPTS)
	install( FILES ${SCRIPTS} DESTINATION "bin"
	         PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
	                     GROUP_EXECUTE GROUP_READ
	                     WORLD_EXECUTE WORLD_READ
	)
endif()

# install craftinfos

file( GLOB DEFINITION_DIRS
   definition*
)

if( DEFINITION_DIRS)
	foreach( DIR ${DEFINITION_DIRS} )
	   install( DIRECTORY "${DIR}" DESTINATION "share/mulle-craft/raylib"
	            USE_SOURCE_PERMISSIONS
	            PATTERN "*._DS_Store" EXCLUDE
	   )
	endforeach()
else()
   message( SEND_ERROR "Remove craftinfo \"raylib\" as it is empty with:\n   mulle-sourcetree remove craftinfo/raylib\n   rm -rf craftinfo/raylib")
endif()
