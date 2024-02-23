/* Copyright (C) 2017 Embecosm Limited and University of Bristol

   Contributor Graham Markall <graham.markall@embecosm.com>

   This file is part of Embench and was formerly part of the Bristol/Embecosm
   Embedded Benchmark Suite.

   SPDX-License-Identifier: GPL-3.0-or-later */

#include <support.h>
#include "boardsupport.h"

void
initialise_board ()
{
}

void __attribute__ ((noinline)) __attribute__ ((externally_visible))
start_trigger ()
{
  __asm__ volatile ("li a0, 1\n\t");
  __asm__ volatile ("li a1, %0\n\t" : : "i"(PIN_ADR));
  __asm__ volatile ("sw a0, 0(a1)\n\t" : : : "memory");
}

void __attribute__ ((noinline)) __attribute__ ((externally_visible))
stop_trigger ()
{
  __asm__ volatile ("li a0, 0\n\t");
  __asm__ volatile ("li a1, %0\n\t" : : "i"(PIN_ADR));
  __asm__ volatile ("sw a0, 0(a1)\n\t" : : : "memory");
}
