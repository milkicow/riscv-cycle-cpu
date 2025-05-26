from utils import read_signals, gen_instrtxt, get_last_write_event
from pathlib import Path
from subprocess import run
import configparser
import pytest

config = configparser.ConfigParser()
config.read("./setup.cfg")

INSTR_FILE_DIR = Path(config["device"]["instr_input"])

MEMORY_WRITE = config["device"]["mem_write"]
MEMORY_DATA = config["device"]["mem_data"]
MEMORY_ADDR = config["device"]["mem_addr"]

TARGET_BIN = config["run"]["target_bin"]
TARGET_WAVES = config["run"]["dump_waves"]
CLEAN = config.getboolean("run", "clean")


@pytest.mark.parametrize("test,res", [
    ("test1", (1, 25, 100))
])
def test_main(test: str, res: tuple):
    gen_instrtxt(test, INSTR_FILE_DIR / "riscvtest.mem")

    run(["chmod", "777", f"{TARGET_BIN}"])
    run([f"{TARGET_BIN}"])

    signals = read_signals(f"{TARGET_WAVES}")
    result = False

    if (test == "test1"):
        memory_event = get_last_write_event(signals[MEMORY_WRITE],
                                             signals[MEMORY_DATA],
                                             signals[MEMORY_ADDR]
                                            )
        print(memory_event)
        result = (memory_event == res)

    if CLEAN:
        run(["rm", f"{INSTR_FILE_DIR / 'riscvtest.mem'}"])
        run(["rm", f"{TARGET_WAVES}"])

    assert result
