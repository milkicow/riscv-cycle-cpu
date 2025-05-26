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
// #include "vpi_user.h"

#include "decoder.hpp"
#include "instruction.hpp"
#include "loader.hpp"
#include "tracer.hpp"

static void format_all_registers(std::ostringstream& oss, VlUnpacked<IData, 32> regfile) {
    for (int i = 0; i < 32; ++i) {
        oss << "x" << std::dec << i << " = " << std::hex << regfile[i] << '\n';
    }
}

int main(int argc, char** argv) {
    CLI::App app{"RISCV simulator model"};

    uint32_t simulation_time{};
    std::filesystem::path vcd_output{};

    app.add_option("-t,--timer", simulation_time, "Simulation time (clock cycles)")
        ->default_val(1000)
        ->check(CLI::PositiveNumber);

    app.add_option("-o,--output", vcd_output, "Output VCD file path")
        ->default_val("waves.vcd")
        ->check(CLI::ExistingFile | CLI::NonexistentPath);

    CLI11_PARSE(app, argc, argv);

    const auto context = std::make_unique<VerilatedContext>();
    context->commandArgs(argc, argv);

    const auto top = std::make_unique<Vtop>();

    // VCD Tracer
    Verilated::traceEverOn(true);
    auto trace = std::make_unique<VerilatedVcdC>();
    top->trace(trace.get(), 99);
    trace->open(vcd_output.string().c_str());

    // Load program from elf
    // const std::filesystem::path program_path{"../programs_bin/factorial"};
    // load_elf_in_mem(program_path, top.get());

    // Start setup
    top->clk = 1;
    top->top->rvpipelined->dp->startPC = 0;

    uint64_t main_time = 0;

    std::ostringstream oss{};
    sim::EncInstr enc_instr;

    auto prev_regfile = top->top->rvpipelined->dp->regfile_inst->rf;
    auto regfile = prev_regfile;

    format_all_registers(oss, regfile);

    Tracer tracer{top.get()};

    while (!context->gotFinish()) {
        context->timeInc(1);
        top->clk ^= 1;
        top->eval();

        prev_regfile = regfile;
        regfile = top->top->rvpipelined->dp->regfile_inst->rf;

        trace->dump(main_time);
        ++main_time;

        uint32_t raw_instr = top->Instr;

        if (raw_instr == 0xFFFFFFFF || main_time > simulation_time) {
            oss << "Simulation end.\n";
            break;
        }

        //
        if (!top->clk) {
            tracer.log_cycle(oss);
        }
    }

    format_all_registers(oss, regfile);
    trace->close();

    std::cout << oss.str();
    return 0;
}
