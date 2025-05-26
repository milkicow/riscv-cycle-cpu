from utils import read_signals, gen_instrtxt, get_last_write_event
from pathlib import Path
from subprocess import run
import configparser
import pytest

config = configparser.ConfigParser()
config.read("./setup.cfg")

INSTR_FILE_DIR = Path(config["device"]["instr_input"])

REG_WRITE = config["device"]["reg_write"]
REG_DATA = config["device"]["reg_data"]
REG_ADDR = config["device"]["reg_addr"]

MEMORY_WRITE = config["device"]["mem_write"]
MEMORY_DATA = config["device"]["mem_data"]
MEMORY_ADDR = config["device"]["mem_addr"]

TARGET_BIN = config["run"]["target_bin"]
TARGET_WAVES = config["run"]["dump_waves"]
CLEAN = config.getboolean("run", "clean")

# covered by tests instructions, you may want to expand them
@pytest.mark.parametrize("instr,res", [
    ("addi", (1, 52, 5)),
    ("sub",  (1, 5, 1)),
    ("sw",   (1, -34, 52)),
    ("lw",   (1, -34, 7)),
    ("and",  (1, 0, 7)),
    ("or",   (1, 11, 7)),
    ("jal",  (1, 8, 5)),
    ("beq",  (1, 11, 5)),
    ("slt",  (1, 0, 5)),
])
def test_instructions(instr: str, res: tuple):
    INSTR_FILE_DIR.mkdir(exist_ok=True)
    gen_instrtxt(instr, INSTR_FILE_DIR / "riscvtest.mem")

    run(["chmod", "777", f"{TARGET_BIN}"])
    run([f"{TARGET_BIN}"])

    signals = read_signals(f"{TARGET_WAVES}")
    result = False

    if instr == "sw":
        memory_event = get_last_write_event(signals[MEMORY_WRITE],
                                            signals[MEMORY_DATA],
                                            signals[MEMORY_ADDR]
                                           )
        result = (memory_event == res)
    else:
        reg_event = get_last_write_event(signals[REG_WRITE],
                                         signals[REG_DATA],
                                         signals[REG_ADDR]
                                        )
        result = (reg_event == res)

    if CLEAN:
        run(["rm", f"{INSTR_FILE_DIR / 'riscvtest.mem'}"])
        run(["rm", f"{TARGET_WAVES}"])

    assert result
