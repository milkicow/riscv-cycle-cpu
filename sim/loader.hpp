#include <cstring>
#include <filesystem>
#include <stdexcept>
#include <string_view>
#include <vector>

#include "Vtop.h"
#include "Vtop_datapath.h"
#include "Vtop_imem.h"
#include "Vtop_riscvpipelined.h"
#include "Vtop_top.h"
#include "elfio/elfio.hpp"

class Loader {
    ELFIO::elfio m_elf_file;

   public:
    Loader(const std::filesystem::path &elf_file) {
        if (!m_elf_file.load(elf_file)) {
            std::runtime_error{"Can not load ELF file: " + elf_file.string()};
        }

        if (!(m_elf_file.get_class() == ELFIO::ELFCLASS64 ||
            m_elf_file.get_class() == ELFIO::ELFCLASS32)) {
            throw std::runtime_error{"Elf file class doesn't match with ELFCLASS64 or ELFCLASS32"};
        }
    }

    auto getLoadableSegments() {
        std::vector<uint32_t> segments{};

        for (const auto &segment : m_elf_file.segments) {
            if (segment->get_type() == ELFIO::PT_LOAD) {
                segments.push_back(segment->get_index());
            }
        }
        return segments;
    }

    auto getSegmentAddr(uint32_t segment_index) {
        const auto *segment = m_elf_file.segments[segment_index];
        if (segment == nullptr) {
            std::runtime_error{"Unavailable segment index"};
        }
        return segment;
    }

    auto getStartPoint() { return m_elf_file.get_entry(); }
};

void load_elf_in_mem(const std::filesystem::path &program_path, Vtop *top) {
    Loader loader{program_path};
    top->top->rvpipelined->dp->startPC = loader.getStartPoint();

    for (const auto segment_index : loader.getLoadableSegments()) {
        auto *segment = loader.getSegmentAddr(segment_index);

        auto segment_addr = segment->get_virtual_address();
        auto segment_size = segment->get_file_size();

        auto src = reinterpret_cast<const uint8_t *>(segment->get_data());
        auto dest = reinterpret_cast<uint8_t *>(top->top->imem->RAM.data());

        std::memcpy(dest + segment_addr, src, segment_size);
    }
}
