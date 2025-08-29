import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate
import riscof.constants as constants
from riscv_isac.isac import isac

logger = logging.getLogger()


class sail_cSim(pluginTemplate):
    __model__ = "sail_c_simulator"
    __version__ = "0.5.0"

    config = """{
  "base": {
    "xlen": 32,
    "writable_misa": true,
    "writable_fiom": true,
    "writable_hpm_counters": {
      "len": 32,
      "value": "0xFFFF_FFFF"
    },
    "mtval_has_illegal_instruction_bits": false
  },
  "memory": {
    "pmp": {
      "grain": 0,
      "count": 16,
      "tor_supported": true,
      "na4_supported": true,
      "napot_supported": true
    },
    "misaligned": {
      "supported": true,
      "byte_by_byte": false,
      "order_decreasing": false,
      "allowed_within_exp": 0
    },
    "translation": {
      "dirty_update": false
    }
  },
  "platform": {
    "vendorid": 0,
    "archid": 0,
    "impid": 0,
    "hartid": 0,
    "reset_vector": 4096,
    "cache_block_size_exp": 6,
    "ram": {
      "base": 2147483648,
      "size": 2147483648
    },
    "rom": {
      "base": 4096,
      "size": 4096
    },
    "clint": {
      "base": 33554432,
      "size": 786432
    },
    "clock_frequency": 1000000000,
    "instructions_per_tick": 2,
    "wfi_is_nop": true
  },
  "extensions": {
    "M": {
      "supported": true
    },
    "A": {
      "supported": true
    },
    "F": {
      "supported": true
    },
    "D": {
      "supported": true
    },
    "V": {
      "supported": true,
      "vlen_exp": 9,
      "elen_exp": 6,
      "vl_use_ceil": false
    },
    "B": {
      "supported": true
    },
    "S": {
      "supported": true
    },
    "U": {
      "supported": true
    },
    "Zicbom": {
      "supported": true
    },
    "Zicboz": {
      "supported": true
    },
    "Zicond": {
      "supported": true
    },
    "Zicntr": {
      "supported": true
    },
    "Zicsr": {
      "supported": true
    },
    "Zifencei": {
      "supported": true
    },
    "Zihpm": {
      "supported": true
    },
    "Zimop": {
      "supported": true
    },
    "Zmmul": {
      "supported": false
    },
    "Zaamo": {
      "supported": false
    },
    "Zabha": {
      "supported": true
    },
    "Zacas": {
      "supported": true
    },
    "Zalrsc": {
      "supported": false
    },
    "Zawrs": {
      "supported": true,
      "nto": {
        "is_nop": false
      },
      "sto": {
        "is_nop": false
      }
    },
    "Zfa": {
      "supported": true
    },
    "Zfh": {
      "supported": true
    },
    "Zfhmin": {
      "supported": false
    },
    "Zfinx": {
      "supported": false
    },
    "Zca": {
      "supported": true
    },
    "Zcf": {
      "supported": false
    },
    "Zcd": {
      "supported": true
    },
    "Zcb": {
      "supported": true
    },
    "Zcmop": {
      "supported": true
    },
    "Zba": {
      "supported": false
    },
    "Zbb": {
      "supported": false
    },
    "Zbs": {
      "supported": false
    },
    "Zbc": {
      "supported": true
    },
    "Zbkb": {
      "supported": true
    },
    "Zbkc": {
      "supported": true
    },
    "Zbkx": {
      "supported": true
    },
    "Zknd": {
      "supported": true
    },
    "Zkne": {
      "supported": true
    },
    "Zknh": {
      "supported": true
    },
    "Zkr": {
      "supported": true,
      "sseed_reset_value": false,
      "useed_reset_value": false,
      "sseed_read_only_zero": false,
      "useed_read_only_zero": false
    },
    "Zksed": {
      "supported": true
    },
    "Zksh": {
      "supported": true
    },
    "Zkt": {
      "supported": true
    },
    "Zhinx": {
      "supported": false
    },
    "Zhinxmin": {
      "supported": false
    },
    "Zvbb": {
      "supported": true
    },
    "Zvbc": {
      "supported": true
    },
    "Zvkb": {
      "supported": false
    },
    "Zvkg": {
      "supported": true
    },
    "Zvkned": {
      "supported": true
    },
    "Zvknha": {
      "supported": true
    },
    "Zvknhb": {
      "supported": true
    },
    "Zvksed": {
      "supported": true
    },
    "Zvksh": {
      "supported": true
    },
    "Zvkt": {
      "supported": true
    },
    "Sscofpmf": {
      "supported": true
    },
    "Smcntrpmf": {
      "supported": true
    },
    "Sstc": {
      "supported": true
    },
    "Svinval": {
      "supported": true
    },
    "Svbare": {
      "supported": true,
      "sfence_vma_illegal_if_svbare_only": true
    },
    "Sv32": {
      "supported": false
    },
    "Sv39": {
      "supported": true
    },
    "Sv48": {
      "supported": true
    },
    "Sv57": {
      "supported": true
    }
  }
}

"""

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get("config")
        if config is None:
            logger.error("Config node for sail_cSim missing.")
            raise SystemExit(1)
        self.num_jobs = str(config["jobs"] if "jobs" in config else 1)
        self.pluginpath = os.path.abspath(config["pluginpath"])
        self.sail_exe = {
            "32": os.path.join(
                config["PATH"] if "PATH" in config else "", "sail_riscv_sim"
            ),
            "64": os.path.join(
                config["PATH"] if "PATH" in config else "", "sail_riscv_sim"
            ),
        }
        self.isa_spec = os.path.abspath(config["ispec"]) if "ispec" in config else ""
        self.platform_spec = (
            os.path.abspath(config["pspec"]) if "ispec" in config else ""
        )
        self.make = config["make"] if "make" in config else "make"
        logger.debug("SAIL CSim plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry + " : " + config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.suite = suite
        self.work_dir = work_dir
        self.objdump_cmd = "riscv{1}-unknown-elf-objdump -D {0} > {2};"
        self.compile_cmd = (
            "riscv{1}-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles\
         -T "
            + self.pluginpath
            + "/env/link.ld\
         -I "
            + self.pluginpath
            + "/env/\
         -I "
            + archtest_env
        )
        print(self.compile_cmd)

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)["hart0"]
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"
        self.isa = "rv" + self.xlen
        self.compile_cmd = (
            self.compile_cmd
            + " -mabi="
            + ("lp64 " if 64 in ispec["supported_xlen"] else "ilp32 ")
        )
        if "I" in ispec["ISA"]:
            self.isa += "i"
        if "M" in ispec["ISA"]:
            self.isa += "m"
        if "C" in ispec["ISA"]:
            self.isa += "c"
        if "F" in ispec["ISA"]:
            self.isa += "f"
        if "D" in ispec["ISA"]:
            self.isa += "d"
        objdump = "riscv{0}-unknown-elf-objdump".format(self.xlen)
        if shutil.which(objdump) is None:
            logger.error(
                objdump + ": executable not found. Please check environment setup."
            )
            raise SystemExit(1)
        compiler = "riscv{0}-unknown-elf-gcc".format(self.xlen)
        if shutil.which(compiler) is None:
            logger.error(
                compiler + ": executable not found. Please check environment setup."
            )
            raise SystemExit(1)
        if shutil.which(self.sail_exe[self.xlen]) is None:
            logger.error(
                self.sail_exe[self.xlen]
                + ": executable not found. Please check environment setup."
            )
            raise SystemExit(1)
        if shutil.which(self.make) is None:
            logger.error(
                self.make + ": executable not found. Please check environment setup."
            )
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None):
        if os.path.exists(self.work_dir + "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir + "/Makefile." + self.name[:-1])
        make = utils.makeUtil(
            makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1])
        )
        make.makeCommand = self.make + " -j" + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry["test_path"]
            test_dir = testentry["work_dir"]
            test_name = test.rsplit("/", 1)[1][:-2]

            elf = "ref.elf"

            execute = "@cd " + testentry["work_dir"] + ";"

            cmd = (
                self.compile_cmd.format(testentry["isa"].lower(), self.xlen)
                + " "
                + test
                + " -o "
                + elf
            )
            compile_cmd = cmd + " -D" + " -D".join(testentry["macros"])
            execute += compile_cmd + ";"

            execute += self.objdump_cmd.format(elf, self.xlen, "ref.disass")
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            # todo: make this more clean
            with open(test_dir + "/config.json", "w") as f:
                f.write(sail_cSim.config)

            execute += (
                self.sail_exe[self.xlen]
                + " --config {0}".format(test_dir + "/config.json")
                + " --test-signature={0} {1} > {2}.log 2>&1;".format(
                    sig_file, elf, test_name
                )
            )

            cov_str = " "
            for label in testentry["coverage_labels"]:
                cov_str += " -l " + label

            if cgf_file is not None:
                coverage_cmd = "riscv_isac --verbose info coverage -d \
                        -t {0}.log --parser-name c_sail -o coverage.rpt  \
                        --sig-label begin_signature  end_signature \
                        --test-label rvtest_code_begin rvtest_code_end \
                        -e ref.elf -c {1} -x{2} {3};".format(
                    test_name, " -c ".join(cgf_file), self.xlen, cov_str
                )
            else:
                coverage_cmd = ""

            execute += coverage_cmd

            make.add_target(execute)
        make.execute_all(self.work_dir)
