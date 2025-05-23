#include <cstdio>

#include <CLI/CLI.hpp>

#include <verilated.h>
#include "Vriscv.h"

int main(int argc, char **argv)
{
    CLI::App app{"RISCV simulator model"};
    CLI11_PARSE(app, argc, argv);

    const auto context = std::make_unique<VerilatedContext>();
    context->commandArgs(argc, argv);

    const auto top = new Vriscv{context.get()};

    top->clk = 0;
    // top->rst = 0;
    // top->count = 0;

    while (!context->gotFinish())
    {
        context->timeInc(1);
        top->clk = !top->clk;
        top->eval();

        std::printf("clock: %d\n", top->clk);
    }

    delete top;

    return 0;
}
