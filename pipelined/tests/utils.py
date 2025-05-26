
import vcdvcd as vcd
from pathlib import Path

def convert_decimal_signed(num: str):
    bit_len = 32

    if (len(num) > bit_len):
        print("Invalid number to convert! Maximum 32 bitwise!")
        assert False

    if (num == 'x'):
        print(f"Invalid number format when convert: num={num}")
        return 'x'

    num = '0'*(bit_len - len(num)) + num
    signed_bit = num[0]
    dec_value = int(num, 2)

    if signed_bit == "1":
        dec_value -= 1 << bit_len

    return dec_value


def signal_expand(signal: list, expand_len: int = None) -> list:
    expand_len = signal[-1][0] if expand_len is None else expand_len
    signal_expanded = []

    def iterate_next(lst: list):
        for i in range(len(lst)):
            current = lst[i]
            next_elem = lst[i + 1] if i + 1 < len(lst) else None
            yield current, next_elem

    for sig_cur, sig_next in iterate_next(signal):
        i = sig_cur[0]
        while sig_next is not None and i < sig_next[0]:
            signal_expanded.append(convert_decimal_signed(sig_cur[1]))
            i += 1

    padding_len = expand_len - len(signal_expanded) if len(signal_expanded) < expand_len else 0
    signal_expanded.extend([convert_decimal_signed(sig_cur[1])] * padding_len)

    return signal_expanded

def get_last_write_event(sig_write: list, sig_data: list, sig_addr: list):
    ts = 0
    wr = 0
    data = 0
    addr = 0

    expand_len = max(sig_write[-1][0], sig_data[-1][0], sig_addr[-1][0])

    for w_ts, w in enumerate(reversed(signal_expand(sig_write, expand_len))):
        if w == 1:
            ts = w_ts
            wr = w
            break

    data = signal_expand(sig_data, expand_len)[::-1][ts]
    addr = signal_expand(sig_addr, expand_len)[::-1][ts]

    return (wr, data, addr)

"""
input:
    signals: Path - path to raw .vcd file after simulation
output:
    tree: defaultdict - structuraly organized signals dictinary
"""
def read_signals(signals: Path) -> dict:
    read_vcd = vcd.VCDVCD(signals, signals=None, store_tvs=True)
    output = {}

    for signal in [sig.__dict__ for sig in read_vcd.data.values()]:
        sig_name = signal['references'][0].split('.')[-1]
        output[sig_name] = signal['tv']

    return output

def gen_instrtxt(instr: str, instr_file: Path):
    with open(instr_file, "w") as i:
        match instr:
            case "addi":
                # res x5 = 52
                i.write("03400293\n") # addi x5 x0 52
            case "sub":
                # res: x1 = 5
                i.write("00800293\n") # addi x5 x0 8
                i.write("00300113\n") # addi x2 x0 3
                i.write("402280B3\n") # sub x1 x5 x2
            case "sw":
                # res MemWrite=1 WriteAddr=52 DataWrite=-34
                i.write("FDE00113\n") # addi x2 x0 -34
                i.write("02202A23\n") # sw x2 52(x0)
            case "lw":
                # res x7 = -34
                i.write("FDE00113\n") # addi x2 x0 -34
                i.write("02202A23\n") # sw x2 52(x0)
                i.write("03402383\n") # lw x7 52(x0)
            case "and":
                # res x7 = 8 & 3
                i.write("00800293\n") # addi x5 x0 8
                i.write("00300113\n") # addi x2 x0 3
                i.write("0022F3B3\n") # and x7 x5 x2
            case "or":
                # res x7 = 8 | 3
                i.write("00800293\n") # addi x5 x0 8
                i.write("00300113\n") # addi x2 x0 3
                i.write("0022E3B3\n") # or x7 x5 x2
            case "jal":
                # res x5 = 8
                i.write("00400293\n") # 00: addi x5 x0 4
                i.write("008003EF\n") # 04: jal x7 8
                i.write("00428293\n") # 08: addi x5 x5 4 shouldn't execute
                i.write("00428293\n") # 0C: addi x5 x5 4
            case "beq":
                # res x5 = 0B
                i.write("00400293\n") # 00: addi x5 x0 4
                i.write("00300113\n") # 04: addi x2 x0 3
                i.write("00228463\n") # 08: beq x5 x2 8 # shouldn't jump offset
                i.write("00428293\n") # 0C: addi x5 x5 4
                i.write("00000463\n") # 10: beq x0 x0 8 # should jump offset
                i.write("00A10113\n") # 14: addi x2 x2 10
                i.write("002282B3\n") # 18: add x5 x5 x2
            case "slt":
                # res x5 = 0
                i.write("00400293\n") # addi x5 x0 4
                i.write("00300113\n") # addi x2 x0 3
                i.write("0022A2B3\n") # slt x5 x5 x2
            case "test1": # example from Haris&Haris
                i.write ("""00500113
00C00193
FF718393
0023E233
0041F2B3
004282B3
02728863
0041A233
00020463
00000293
0023A233
005203B3
402383B3
0471AA23
06002103
005104B3
008001EF
00100113
00910133
0221A023
00210063
00000013
00000013
""")


if __name__ == "__main__":
    read_signals(Path("../dump.vcd"))
