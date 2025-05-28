import subprocess
import sys

def main():
    if len(sys.argv) < 2:
        print("Specify path_to_elf")
        sys.exit(1)

    elffile_path = sys.argv[1]

    try:
        print(f"Running: ./model -t 10000 -f {elffile_path} > out.log")
        with open("out.log", "w") as out_file:
            subprocess.run(["./model", "-t", "10000", "-f", elffile_path],
                          stdout=out_file, check=True)

        print(f"Running: ./bin/sim -l 1 -f {elffile_path}")
        subprocess.run(["./bin/sim", "-l", "1", "-f", elffile_path], check=True)

        print("Running: diff full.log out.log")
        subprocess.run(["diff", "full.log", "out.log"], check=True)

        print("Success!")
    except subprocess.CalledProcessError as e:
        print(f"Command failed with error: {e}")
    except FileNotFoundError as e:
        print(f"Executable not found: {e}")

if __name__ == "__main__":
    main()