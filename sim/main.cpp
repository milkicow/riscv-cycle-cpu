#include <verilated.h>
#include <verilated_vcd_c.h>

#include <CLI/CLI.hpp>
#include <format>
#include <memory>
#include <sstream>
#include <string>

#include "Vtop.h"
#include "Vtop_datapath.h"
#include "Vtop_regfile.h"
#include "Vtop_riscvpipelined.h"
#include "Vtop_top.h"
#include "decoder.hpp"
#include "instruction.hpp"
#include "loader.hpp"
#include "tracer.hpp"

static void format_all_registers(std::ostringstream& oss, VlUnpacked<IData, 32> regfile) {
    for (int i = 0; i < 32; ++i) {
        oss << "x" << std::dec << i << " = " << std::dec << regfile[i] << '\n';
    }
}

int main(int argc, char** argv) {
    CLI::App app{"RISCV simulator model"};

    uint32_t simulation_time{};
    std::filesystem::path elf_file{};
    std::filesystem::path vcd_output{};

    app.add_option("-t,--timer", simulation_time, "Simulation time (clock cycles)")
        ->default_val(1000)
        ->check(CLI::PositiveNumber);

    app.add_option("-o,--output", vcd_output, "Output VCD file path")
        ->default_val("waves.vcd")
        ->check(CLI::ExistingFile | CLI::NonexistentPath);

    app.add_option("-f,--file", elf_file, "Simulation input elf file")
        ->required()
        ->check(CLI::ExistingFile);

    CLI11_PARSE(app, argc, argv);

    const auto context = std::make_unique<VerilatedContext>();
    context->commandArgs(argc, argv);

    const auto top = std::make_unique<Vtop>();

    // VCD Tracer
    Verilated::traceEverOn(true);
    auto trace = std::make_unique<VerilatedVcdC>();
    top->trace(trace.get(), 99);
    trace->open(vcd_output.string().c_str());

    // Load program from elf and setup startPC
    // load_elf_in_mem(elf_file, top.get());

    // Start setup
    top->clk = 1;
    top->reset = 1;
    top->top->rvpipelined->dp->startPC = 0;

    uint64_t main_time = 0;

    std::ostringstream oss{};

    auto prev_regfile = top->top->rvpipelined->dp->regfile_inst->rf;
    auto regfile = prev_regfile;

    // format_all_registers(oss, regfile);

    Tracer tracer{top.get()};

    // Stack pointer
    top->top->rvpipelined->dp->regfile_inst->rf[2] = 0x90000;
    oss << "\tx2: " << std::hex << top->top->rvpipelined->dp->regfile_inst->rf[2] << '\n';

    while (!context->gotFinish()) {
        context->timeInc(1);
        top->clk ^= 1;
        top->eval();

        if (main_time == 0) {
            top->reset = 1;
        } else {
            top->reset = 0;
        }

        trace->dump(main_time);
        ++main_time;

        prev_regfile = regfile;
        regfile = top->top->rvpipelined->dp->regfile_inst->rf;

        uint32_t raw_instr = top->Instr;

        if (raw_instr == 0xFFFFFFFF || main_time > simulation_time) {
            break;
        }

        //
        if (!top->clk) {
            tracer.log_cycle(oss);
        }
    }

    // format_all_registers(oss, regfile);
    trace->close();

    std::cout << oss.str();
    return 0;
}
