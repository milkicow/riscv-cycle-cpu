#include <cstdio>
#include <sstream>

#include "Vtop.h"
#include "Vtop_datapath.h"
#include "Vtop_regfile.h"
#include "Vtop_riscvpipelined.h"
#include "Vtop_top.h"
#include "decoder.hpp"
#include "instruction.hpp"

static std::string format_pc(uint32_t pc) { return std::format("{:04x}", pc); }

static std::string format_addr(uint32_t addr) { return std::format("{:04x}", addr); }

static std::string format_value(uint32_t value) { return std::format("0x{:x}", value); }

static std::string format_instr_hex(uint32_t instr) { return std::format("0x{:08x}", instr); }

static void format_changed_registers(std::ostringstream &oss, VlUnpacked<IData, 32> prev_regfile,
                                     VlUnpacked<IData, 32> regfile) {
    for (int i = 0; i < 32; ++i) {
        if (prev_regfile[i] == regfile[i]) {
            continue;
        }

        oss << "x" << std::dec << i << ": " << std::hex << prev_regfile[i] << " -> " << std::hex
            << regfile[i] << '\n';
    }
}

class Tracer {
    Vtop *m_top;

   public:
    Tracer(Vtop *top) : m_top{top} {}

    void log_cycle(std::ostringstream &oss) {
        auto pc = m_top->top->rvpipelined->dp->PCW;
        auto instr = m_top->top->rvpipelined->dp->InstrW;

        auto MemWrite = m_top->top->rvpipelined->dp->MemWriteW;
        auto MemAddress = m_top->top->rvpipelined->dp->ALUResultW;
        auto WriteData = m_top->top->rvpipelined->dp->WriteDataW;

        auto RegWrite = m_top->top->rvpipelined->dp->RegWriteW;
        auto RdW = m_top->top->rvpipelined->dp->RdW;
        auto ResultW = m_top->top->rvpipelined->dp->ResultW;

        sim::EncInstr enc_instr;
        if (instr) try {
                sim::Decoder::decode_instruction(instr, enc_instr);

                oss << '[' << format_pc(pc) << "]: " << enc_instr.format() << ' '
                    << format_instr_hex(instr) << '\n';

            } catch (std::runtime_error &err) {
                oss << "Unknow instr: [" << format_pc(pc) << "]: " << format_instr_hex(instr)
                    << '\n';
            }

        if (MemWrite) {
            oss << "\tDATA_MEM[" << format_addr(MemAddress) << "] = " << format_value(WriteData)
                << '\n';
        }

        if (RegWrite && (RdW != 0)) {
            oss << "\tx" << std::dec << int(RdW) << ": " << std::hex << ResultW << '\n';
        }
    }
};