// Adapted from https://github.com/olofk/serv/blob/main/bench/servant_tb.cpp
//

#include <fcntl.h>
#include <stdint.h>
#include <signal.h>

#include "verilated_fst_c.h"
#include "Vfsoc_sim.h"

using namespace std;

static bool done;

vluint64_t main_time = 0;     // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {     // Called by $time in Verilog
  return main_time;           // converts to double, to match
  // what SystemC does
}

void INThandler(int signal)
{
  printf("\nCaught ctrl-c\n");
  done = true;
}

typedef struct {
  bool last_value;
} gpio_context_t;

void do_gpio(gpio_context_t *context, bool gpio) {
  if (context->last_value != gpio) {
    context->last_value = gpio;
    printf("%lu output q is %s\n", main_time, gpio ? "ON" : "OFF");
  }
}

int main(int argc, char **argv, char **env)
{
  gpio_context_t gpio_context;
  Verilated::commandArgs(argc, argv);

  Vfsoc_sim* top = new Vfsoc_sim;

  VerilatedFstC * tfp = 0;
  const char *vcd = Verilated::commandArgsPlusMatch("vcd=");
  if (vcd[0]) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedFstC;
    top->trace (tfp, 99);
    tfp->open ("trace.fst");
  }

  signal(SIGINT, INThandler);

  int tf = 0;
  const char *arg_trace_pc = Verilated::commandArgsPlusMatch("trace_pc=");
  if (arg_trace_pc[0])
    tf = open("trace.bin", O_WRONLY | O_CREAT | O_TRUNC, S_IRWXU);

  vluint64_t timeout = 0;
  const char *arg_timeout = Verilated::commandArgsPlusMatch("timeout=");
  if (arg_timeout[0]) {
    timeout = 1000 * 1000 * 1000 * (vluint64_t)(atoi(arg_timeout+9));
    printf("Timeout set: %lu ns\n", timeout);
  }

  vluint64_t vcd_start = 0;
  const char *arg_vcd_start = Verilated::commandArgsPlusMatch("vcd_start=");
  if (arg_vcd_start[0])
    vcd_start = 1000 * 1000 * 1000 * (vluint64_t)(atoi(arg_vcd_start+11));

  const vluint64_t half_period = 500;  // Half period for 1MHz clock (500ns)

  bool dump = false;
  top->clk_i = 1;
  bool q = top->q;
  while (!(done || Verilated::gotFinish())) {
    if (tfp && !dump && (main_time > vcd_start)) {
      dump = true;
    }
    top->rst_in = main_time > 2000;
    top->eval();
    if (dump)
      tfp->dump(main_time);
    do_gpio(&gpio_context, top->q);

    if (timeout && (main_time >= timeout)) {
      printf("Timeout: Exiting at time %lu\n", main_time);
      printf("Timeout: %lu \t MainTime: %lu\n", timeout, main_time);
      done = true;
    }

    if (main_time % half_period == 0) {
      top->clk_i = !top->clk_i;
    }
    main_time+=half_period/2;
  }
  close(tf);
  if (tfp)
    tfp->close();
  exit(0);
}