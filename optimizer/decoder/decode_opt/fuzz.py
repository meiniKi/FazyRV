# Copyright (c) 2023 - 2024 Meinhard Kissich
# -----------------------------------------------------------------------------
# File   :  fuzz.py
# Usage  :  Fuzzer to optimize FazyRV's decoder (area) by testing individual
#           bits and invoking a formal solver.
# Limit. :  Only one bit at a time is tested.
# -----------------------------------------------------------------------------

import subprocess
import argparse
from tqdm import tqdm

def add_args(parser):
    parser.add_argument(
        '--espresso_file',
        type=str,
        default=None,
        help='Path to espresso input file'
    )

    parser.add_argument(
        '--espresso_optimized',
        type=str,
        default=None,
        help='Path to write optimized espresso file'
    )

    parser.add_argument(
        '--riscvtests_dir',
        type=str,
        default=None,
        help='Path to folder of riscvtests'
    )

    parser.add_argument(
        '--riscvformal_dir',
        type=str,
        default=None,
        help='Path to folder of riscvformal make'
    )

    parser.add_argument(
        '--template_verilog',
        type=str,
        default=None,
        help='Path to template decoder'
    )

    parser.add_argument(
        '--template_marker',
        type=str,
        default=None,
        help='Marker to insert the block'
    )

    parser.add_argument(
        '--destination_verilog',
        type=str,
        default=None,
        help='Marker to insert the block'
    )

riscv_test_logfile = "riscvtests.log"

# necessary but not sufficient, thus run formal check afterwards
def test_riscv_tests(dir):
    global riscv_test_logfile
    with open(riscv_test_logfile, 'a') as log_file:
        command = f"make -C {dir} test"
        result = subprocess.run(command, shell=True, stdout=log_file, stderr=subprocess.STDOUT)
        return result.returncode == 0
    
def test_riscv_formal(dir):
    global riscv_test_logfile
    with open(riscv_test_logfile, 'a') as log_file:
        command = f"make -C {dir} fv.rvformal.bmc.insn.8"
        result = subprocess.run(command, shell=True, stdout=log_file, stderr=subprocess.STDOUT)
        return result.returncode == 0

def run_espresso(input_file, output_file):
    command = f"espresso -o eqntott -Dso_both {input_file} > {output_file}"
    result = subprocess.run(command, shell=True)
    return result.returncode == 0

def read_espresso_file(filename):
    data = {
        'inputs': 0,
        'outputs': 0,
        'input_labels': [],
        'output_labels': [],
        'rows': [],  # Now each row will store data and comment
        'comments': []  # Standalone comments
    }

    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            if '#' in line:
                # Split the line at the comment
                parts, comment = line.split('#', 1)
                comment = '#' + comment.strip()
            else:
                parts, comment = line, ''

            if parts.startswith('.i '):
                data['inputs'] = int(parts.split()[1])
            elif parts.startswith('.o '):
                data['outputs'] = int(parts.split()[1])
            elif parts.startswith('.ilb'):
                data['input_labels'] = parts.split()[1:]
            elif parts.startswith('.ob'):
                data['output_labels'] = parts.split()[1:]
            elif parts.startswith('.e'):
                break
            elif parts.startswith('#'):
                data['comments'].append(comment)
            elif parts:
                row_data = parts.split()
                row = {
                    'inputs': list(row_data[0]),
                    'outputs': list(row_data[1]) if len(row_data) > 1 else ['-' * data['outputs']],
                    'comment': comment
                }
                data['rows'].append(row)

    return data

def get_ouput_value(data, number_row, number_output):
    return data["rows"][number_row]["outputs"][number_output]

def set_output_value(data, number_row, number_output, value):
    data["rows"][number_row]["outputs"][number_output] = value

def write_espresso_file(data, filename):
    with open(filename, 'w') as file:
        file.write('.i {}\n'.format(data['inputs']))
        file.write('.o {}\n'.format(data['outputs']))
        file.write('.ilb {}\n'.format(' '.join(data['input_labels'])))
        file.write('.ob {}\n'.format(' '.join(data['output_labels'])))

        # Write standalone comments
        for comment in data['comments']:
            file.write(comment + '\n')

        # Write input and output values with inline comments
        for row in data['rows']:
            line = '{} {}'.format(''.join(row['inputs']), ''.join(row['outputs']))
            if row['comment']:
                line += ' ' + row['comment']
            file.write(line + '\n')

        file.write('.e\n')


def read_eqntott(filename, outputs_to_remove):
    with open(filename, 'r') as file:
        input_text = file.readlines()

    input_text = [line for line in input_text if not line.strip().startswith('#')]
    input_text = ''.join(input_text)

    # Remove lines that start with "#" and separate blocks
    blocks = [line for line in input_text.split('\n\n') if not line == ""]

    filtered_blocks = [s for s in blocks if not any(s.startswith(word + " ") for word in outputs_to_remove)]

    return ["assign " + " " + s for s in filtered_blocks]


def write_to_verilog_template(processed_blocks, template_filename, destination_filename, marker):
    # Read the content of the target file
    with open(template_filename, 'r') as file:
        content = file.readlines()

    # Find the marker and get the index
    index = -1
    for i, line in enumerate(content):
        if marker in line:
            index = i
            break

    # Check if marker was found
    if index == -1:
        raise FileExistsError
        ##print(f"Marker '{marker}' not found in the file.")
        return

    # Insert the processed blocks at the marker position
    insertion = '\n'.join(processed_blocks) + '\n'
    content.insert(index, insertion)

    # Write the modified content back to the file
    with open(destination_filename, 'w') as file:
        file.writelines(content)

    ##print(f"Blocks inserted into {destination_filename} at marker '{marker}'.")


if __name__ == "__main__":

    FILE_ESPRESSO = "test.espresso"
    FILE_EQNTOTT = "test.eqn"
    outputs_to_remove = ["instr_csr_o", "mret_o", "is_b_imm", "is_s_imm", "is_i_imm", "is_j_imm", "is_u_imm"]


    parser = argparse.ArgumentParser(description="Fuzz espresso logic analyzer")
    add_args(parser)
    args = parser.parse_args()

    data = read_espresso_file(args.espresso_file)

    nr_outputs = data["outputs"]
    nr_rows = len(data["rows"])

    performance_errors = 0
    performance_optimized = 0
    performance_left = 0
    performance_ignored = 0

    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    print("WARNING: This will overwrite fazyrv_decode.sv !!!!")
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    input("Press Enter to continue...")

    row_pbar = tqdm(range(nr_rows), desc="Row", leave=True)
    for r in row_pbar:
        for o in tqdm(range(nr_outputs), desc="Output number", leave=False):

            val = get_ouput_value(data, r, o)
            if val == "-":
                performance_ignored += 1
            else:
                try:
                    #set_output_value(data, r, o, "0" if val == "1" else "1")
                    write_espresso_file(data, FILE_ESPRESSO)
                    run_espresso(FILE_ESPRESSO, FILE_EQNTOTT)
                    assignments = read_eqntott(FILE_EQNTOTT, outputs_to_remove)
                    write_to_verilog_template(assignments, args.template_verilog, args.destination_verilog, args.template_marker)
                    success_riscv_tests = test_riscv_tests(args.riscvtests_dir)
                    success_riscv_formal = True

                    # if the sanity check is true, make the more extensive test
                    # to check if it really can be set to a "don't care" value
                    if success_riscv_tests:
                        success_riscv_formal = test_riscv_formal(args.riscvformal_dir)

                    if success_riscv_tests and success_riscv_formal:
                        set_output_value(data, r, o, "-")
                        performance_optimized += 1
                    else:
                        set_output_value(data, r, o, val)
                        performance_left += 1

                except Exception as e:
                    set_output_value(data, r, o, val)
                    performance_errors += 1

            row_pbar.set_postfix(Errors=performance_errors, Optimized=performance_optimized, Left=performance_left, Ignored=performance_ignored, refresh=True)

    print(f"Numer of Errors: {performance_errors}")
    print(f"Numer of optimized outputs: {performance_optimized}")
    print(f"Numer of non-optimized ouputs: {performance_left}")
    print(f"Numer of ignored ouputs: {performance_ignored}")

    write_espresso_file(data, args.espresso_optimized)