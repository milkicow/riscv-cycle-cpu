#include <verilated.h>
#include <verilated_vcd_c.h>

#include <CLI/CLI.hpp>
#include <cstdio>
#include <memory>

#include "Vtop.h"

int main(int argc, char **argv) {
    CLI::App app{"RISCV simulator model"};
    CLI11_PARSE(app, argc, argv);

    const auto context = std::make_unique<VerilatedContext>();
    context->commandArgs(argc, argv);

    const auto top = std::make_unique<Vtop>(context.get());

    // VCD Tracer
    const std::string vcd_path{"waves.vcd"};
    Verilated::traceEverOn(true);
    auto trace = std::make_unique<VerilatedVcdC>();
    top->trace(trace.get(), 99);
    trace->open(vcd_path.c_str());

    // Start setup
    top->clk = 0;

    uint64_t main_time = 0;

    while (!context->gotFinish()) {
        context->timeInc(1);
        top->clk = !top->clk;
        top->eval();

        trace->dump(main_time);

        ++main_time;

        //
        std::printf("clock: %d\n", top->clk);
        std::printf("Write Data: %d\n", top->WriteData);

        if (top->Instr == 0xFFFFFFFF) {
            printf("Simulation end.");
            break;
        }
    }

    trace->close();
    return 0;
}
