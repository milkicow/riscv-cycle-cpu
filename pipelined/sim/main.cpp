#include <verilated.h>
#include <verilated_vcd_c.h>

#include <CLI/CLI.hpp>
#include <format>
#include <memory>
#include <sstream>
#include <string>

#include "Vtop.h"

#include "decoder.hpp"
#include "instruction.hpp"
#include "loader.hpp"

static std::string format_pc(uint32_t pc) { return std::format("{:04x}", pc); }

static std::string format_addr(uint32_t addr) { return std::format("{:04x}", addr); }

static std::string format_value(uint32_t value) { return std::format("0x{:x}", value); }

static std::string format_instr_hex(uint32_t instr) { return std::format("0x{:08x}", instr); }

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

    // Load program from elf
    const std::filesystem::path program_path{"../programs_bin/factorial"};
    load_elf_in_mem(program_path, top.get());

    // Start setup
    top->clk = 0;

    uint64_t main_time = 0;

    std::ostringstream oss{};
    sim::EncInstr enc_instr;

    while (!context->gotFinish()) {
        context->timeInc(1);

        top->clk = !top->clk;
        top->eval();

        trace->dump(main_time);

        ++main_time;

        uint32_t raw_instr = top->Instr;

        if (raw_instr == 0xFFFFFFFF || main_time > 1000) {
            oss << "Simulation end.";
            break;
        }

        //
        if (top->clk) {
            sim::Decoder::decode_instruction(raw_instr, enc_instr);

            oss << '[' << format_pc(top->PC) << "]: " << enc_instr.format() << ' '
                << format_instr_hex(raw_instr) << '\n';

            if (top->MemWrite) {
                oss << "\tDATA_MEM[" << format_addr(top->DataAdr)
                    << "] = " << format_value(top->WriteData) << '\n';
            }
        }
    }

    trace->close();

    std::cout << oss.str();
    return 0;
}
