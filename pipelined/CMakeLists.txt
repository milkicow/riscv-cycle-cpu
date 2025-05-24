cmake_minimum_required(VERSION 3.15)
project(RISCV_simulator_model LANGUAGES CXX)

find_package(verilator REQUIRED)

add_subdirectory(RV64I_SIM)

set(VERILATOR_SOURCES
    rtl/adder.v
    rtl/aludec.v
    rtl/alu.v
    rtl/controller.v
    rtl/dmem.v
    rtl/datapath.v
    rtl/extend.v
    rtl/flopenr.v
    rtl/flopr.v
    rtl/imem.v
    rtl/maindec.v
    rtl/mux2.v
    rtl/mux3.v
    rtl/regfile.v
    rtl/riscvpipelined.v
    rtl/top.v
)

add_executable(model sim/main.cpp)
target_compile_features(model PRIVATE cxx_std_23)


verilate(model
    SOURCES ${VERILATOR_SOURCES}
    TOP_MODULE top
    PREFIX Vtop
    VERILATOR_ARGS -Wall -Wno-UNUSED -Wno-UNDRIVEN --trace --public
)

target_link_libraries(model PRIVATE sim_decoder)
target_include_directories(model PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/RV64I_SIM/decoder/include)