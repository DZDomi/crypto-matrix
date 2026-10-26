cmake_minimum_required(VERSION 3.16)
project(display LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Prefer the CMake package of protobuf, older distribution packages only ship
# the FindProtobuf module
find_package(Protobuf CONFIG QUIET)
if (NOT Protobuf_FOUND)
    find_package(Protobuf REQUIRED)
endif ()
find_package(gRPC CONFIG REQUIRED)

# The C++ sources are generated at build time, so they always match the
# installed protobuf and gRPC versions
set(PROTO_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../proto)
set(PROTO_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/gen)
set(PROTO_IMPORT_DIRS ${PROTO_DIR}/models ${PROTO_DIR}/services)
file(MAKE_DIRECTORY ${PROTO_GEN_DIR})

file(GLOB PROTO_MODELS ${PROTO_DIR}/models/*.proto)

add_library(display_proto STATIC ${PROTO_MODELS} ${PROTO_DIR}/services/ledmatrix.proto)
target_link_libraries(display_proto PUBLIC protobuf::libprotobuf gRPC::grpc++)
target_include_directories(display_proto PUBLIC ${PROTO_GEN_DIR})

protobuf_generate(
        TARGET display_proto
        IMPORT_DIRS ${PROTO_IMPORT_DIRS}
        PROTOC_OUT_DIR ${PROTO_GEN_DIR})

protobuf_generate(
        OUT_VAR PROTO_GRPC_SOURCES
        PROTOS ${PROTO_DIR}/services/ledmatrix.proto
        LANGUAGE grpc
        GENERATE_EXTENSIONS .grpc.pb.h .grpc.pb.cc
        PLUGIN protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
        IMPORT_DIRS ${PROTO_IMPORT_DIRS}
        PROTOC_OUT_DIR ${PROTO_GEN_DIR})
target_sources(display_proto PRIVATE ${PROTO_GRPC_SOURCES})

file(GLOB HEADER_FILES *.h)
file(GLOB SOURCE_FILES *.cpp)

add_executable(display ${HEADER_FILES} ${SOURCE_FILES})

target_link_libraries(display display_proto atomic rgbmatrix)
