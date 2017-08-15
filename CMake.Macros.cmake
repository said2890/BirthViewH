########################################################################################################################
### Initialization
########################################################################################################################

set (CMAKE_CXX_STANDARD 11)

# link to an external library with a CMakeLists.txt file at "path" with name "to"
macro(LINK_TO path to)
    ADD_SUBDIRECTORY(${path} ${to})
    SET(LIBS ${LIBS} ${to})
    SET(LIBS ${LIBS} ${${to}_LIBS})
    SET(DEBUG_LIBS ${DEBUG_LIBS} ${${to}_DEBUG_LIBS})
    SET(RELEASE_LIBS ${RELEASE_LIBS} ${${to}_RELEASE_LIBS})
    SET(INCLUDE_DIRS ${INCLUDE_DIRS} ${${to}_INCLUDE_DIR})
endmacro()

set(BV_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

# link to a bv_{whatever} project
macro(LINK to)
    LINK_TO(${BV_ROOT_DIR}/bv_${to} bv_${to})
endmacro()

########################################################################################################################
### Setup
########################################################################################################################

macro(SETUP target)
    SET(target ${target})
    SET(INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include ${EXTRA_INCLUDES})
    SET(${target}_INCLUDE_DIR ${INCLUDE_DIRS} PARENT_SCOPE)
    UNSET(LIBS)
    UNSET(DEBUG_LIBS)
    UNSET(RELEASE_LIBS)
    UNSET(SOURCE_FILES)
endmacro()


########################################################################################################################
### Bootstrapping
########################################################################################################################

# bootstrap executable target by adding a target with name {target} and specifiying include dirs and libs
macro(BOOTSTRAP_EXE target)
    if(TARGET ${target})
    else()
        if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
            find_library(COCOA_LIB Cocoa)
            find_library(IOKIT_LIB IOKit)
            find_library(QUARTZ_LIB QuartzCore)
            #SET(METAL_LIB Metal.framework)
            set(LIBS ${LIBS} ${COCOA_LIB} ${IOKIT_LIB} ${QUARTZ_LIB})
        elseif(WIN32)
            if(MINGW)
                find_library(PSAPI_LIB Psapi)
                find_library(GDI32_LIB GDI32)
                find_library(WS2_32_LIB ws2_32)
                set(LIBS ${LIBS} ${PSAPI_LIB} ${GDI32_LIB} ${WS2_32_LIB})
#                set(CMAKE_EXE_LINKER_FLAGS "-static -static-libgcc -static-libstdc++")
            elseif(MSVC)
                set(LIBS ${LIBS} delayimp.lib gdi32.lib psapi.lib ws2_32.lib)
            endif()
        endif()

        # the application needs to be executed in the runtime directory
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")

        MESSAGE(STATUS "Bootstrapping executable - ${target}")
        MESSAGE(STATUS "INCLUDE_DIRS ${INCLUDE_DIRS}")
        MESSAGE(STATUS "LIBS ${LIBS} release: ${RELEASE_LIBS} debug: ${DEBUG_LIBS}")
        INCLUDE_DIRECTORIES(${INCLUDE_DIRS})
        ADD_EXECUTABLE(${target} ${SOURCE_FILES})
        TARGET_LINK_LIBRARIES(${target} ${LIBS})
        if(RELEASE_LIBS)
            foreach(LIB ${RELEASE_LIBS})
                TARGET_LINK_LIBRARIES(${target} optimized ${LIB})
            endforeach()
        endif()
        if(DEBUG_LIBS)
            foreach(LIB ${DEBUG_LIBS})
                TARGET_LINK_LIBRARIES(${target} debug ${LIB})
            endforeach()
        endif()
    endif()
endmacro()

# make the target library avaiable for all other linking projects
macro(EXPORT target)
    set(${target}_LIBS ${LIBS} PARENT_SCOPE)
    set(${target}_DEBUG_LIBS ${DEBUG_LIBS} PARENT_SCOPE)
    set(${target}_RELEASE_LIBS ${RELEASE_LIBS} PARENT_SCOPE)
endmacro()

# bootstrap the target by adding a library with name {target} and specifiying include dirs and libs
macro(BOOTSTRAP target)
    if(TARGET ${target})
    else()
        MESSAGE(STATUS "Bootstrapping ${target}")
        MESSAGE(STATUS "INCLUDE_DIRS ${INCLUDE_DIRS}")
        MESSAGE(STATUS "LIBS ${LIBS} release: ${RELEASE_LIBS} debug: ${DEBUG_LIBS}")
        INCLUDE_DIRECTORIES(${INCLUDE_DIRS})
        ADD_LIBRARY(${target} STATIC ${SOURCE_FILES})
        TARGET_LINK_LIBRARIES(${target} ${LIBS})
        EXPORT(${target})
    endif()
endmacro()


########################################################################################################################
### Adding source files
########################################################################################################################

macro(ADD_HEADER name)
    SET(SOURCE_FILES ${SOURCE_FILES} include/${name}.h)
endmacro()

macro(ADD_SOURCE name)
    SET(SOURCE_FILES ${SOURCE_FILES} src/${name}.cpp)
endmacro()

macro(ADD_CLASS name)
    ADD_HEADER(${name})
    ADD_SOURCE(${name})
endmacro()

