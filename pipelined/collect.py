import re
import sys

def extract_unique_opcodes(log_text):
    opcode_pattern = re.compile(r'^\[\w+\]:\s+([A-Z]+)')

    unique_opcodes = set()

    for line in log_text.split('\n'):
        match = opcode_pattern.search(line)
        if match:
            opcode = match.group(1)
            unique_opcodes.add(opcode)

    return sorted(unique_opcodes)

def main():
    if len(sys.argv) < 2:
        print("Specify log file")
        sys.exit(1)

    with open(sys.argv[1], 'r') as log_file:
        print(extract_unique_opcodes(log_file.read()))

if __name__ == "__main__":
    main()
