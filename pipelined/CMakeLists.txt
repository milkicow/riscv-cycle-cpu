cmake_minimum_required(VERSION 3.15)
project(RISCV_simulator_model LANGUAGES CXX)

find_package(verilator REQUIRED)

add_executable(model sim/main.cpp)
target_compile_features(model PRIVATE cxx_std_23)

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

verilate(model
    SOURCES ${VERILATOR_SOURCES}
    TOP_MODULE top
    PREFIX Vriscv
    VERILATOR_ARGS -Wall -Wno-UNUSED -Wno-UNDRIVEN
)
