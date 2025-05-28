import subprocess
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description='Model and simulation comparun')
    parser.add_argument('--elf', help='Path to ELF file')
    parser.add_argument('-t', '--time_sim', type=int, default=10000,
                       help='Model simulation time, default = 10000')

    args = parser.parse_args()

    try:
        print(f"Running: ./model -t {args.time_sim} -f {args.elf} > out.log")
        with open("out.log", "w") as out_file:
            subprocess.run(["./model", "-t", str(args.time_sim), "-f", args.elf],
                          stdout=out_file, check=True)

        print(f"Running: ./bin/sim -l 1 -f {args.elf}")
        subprocess.run(["./bin/sim", "-l", "1", "-f", args.elf], check=True)

        print("Running: diff full.log out.log")
        subprocess.run(["diff", "full.log", "out.log"], check=True)

        print("Success!")
    except subprocess.CalledProcessError as e:
        print(f"Command failed with error: {e}")
    except FileNotFoundError as e:
        print(f"Executable not found: {e}")

if __name__ == "__main__":
    main()