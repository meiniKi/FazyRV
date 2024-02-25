# FazyRV

This commit archives the initial implementation of FazyRV. **We highly recommend using the current implementation in the `main` branch instead.**

## Initial Implementation Results

All results below refer to the implementation of _fsoc_. The minimal reference SoC uses the FazyRV core and aims to provide a representative area for a potential target application.

### nextpnr-ice40

```
<arch> - <chunk size> - <interrupt support> - <regfile type>
===================================================================================
ice40-1-MIN-BRAM:       LUT4 409   cells 717   fmax 63.52 MHz  ICESTORM_LC 551
ice40-1-MIN-BRAM_BP:    LUT4 440   cells 747   fmax 60.02 MHz  ICESTORM_LC 585
ice40-1-MIN-BRAM_DP:    LUT4 375   cells 682   fmax 60.97 MHz  ICESTORM_LC 515
ice40-1-MIN-BRAM_DP_BP: LUT4 364   cells 671   fmax 60.13 MHz  ICESTORM_LC 511
ice40-1-MIN-LOGIC:      LUT4 453   cells 1651  fmax 55.93 MHz  ICESTORM_LC 1522
-----------------------------------------------------------------------------------
ice40-2-MIN-BRAM:       LUT4 430   cells 732   fmax 52.87 MHz  ICESTORM_LC 578
ice40-2-MIN-BRAM_BP:    LUT4 477   cells 778   fmax 56.73 MHz  ICESTORM_LC 622
ice40-2-MIN-BRAM_DP:    LUT4 396   cells 697   fmax 55.01 MHz  ICESTORM_LC 542
ice40-2-MIN-BRAM_DP_BP: LUT4 390   cells 691   fmax 57.33 MHz  ICESTORM_LC 539
ice40-2-MIN-LOGIC:      LUT4 583   cells 1775  fmax 45.54 MHz  ICESTORM_LC 1626
-----------------------------------------------------------------------------------
ice40-4-MIN-BRAM:       LUT4 492   cells 795   fmax 46.34 MHz  ICESTORM_LC 635
ice40-4-MIN-BRAM_BP:    LUT4 523   cells 825   fmax 45.58 MHz  ICESTORM_LC 664
ice40-4-MIN-BRAM_DP:    LUT4 449   cells 751   fmax 47.86 MHz  ICESTORM_LC 593
ice40-4-MIN-BRAM_DP_BP: LUT4 452   cells 754   fmax 46.78 MHz  ICESTORM_LC 604
ice40-4-MIN-LOGIC:      LUT4 827   cells 2020  fmax 41.20 MHz  ICESTORM_LC 1810
-----------------------------------------------------------------------------------
ice40-8-MIN-BRAM:       LUT4 640   cells 939   fmax 37.42 MHz  ICESTORM_LC 763
ice40-8-MIN-BRAM_BP:    LUT4 685   cells 983   fmax 39.37 MHz  ICESTORM_LC 808
ice40-8-MIN-BRAM_DP:    LUT4 595   cells 893   fmax 40.17 MHz  ICESTORM_LC 721
ice40-8-MIN-BRAM_DP_BP: LUT4 590   cells 888   fmax 37.21 MHz  ICESTORM_LC 731
ice40-8-MIN-LOGIC:      LUT4 1275  cells 2464  fmax 36.65 MHz  ICESTORM_LC 2116
===================================================================================
ice40-1-INT-BRAM:       LUT4 447   cells 759   fmax 62.38 MHz  ICESTORM_LC 595  (*)
ice40-1-INT-BRAM_BP:    LUT4 477   cells 788   fmax 63.69 MHz  ICESTORM_LC 627  (*)
ice40-1-INT-BRAM_DP:    LUT4 416   cells 727   fmax 62.00 MHz  ICESTORM_LC 560  (*)
ice40-1-INT-BRAM_DP_BP: LUT4 407   cells 718   fmax 62.38 MHz  ICESTORM_LC 558  (*)
-----------------------------------------------------------------------------------
ice40-2-INT-BRAM:       LUT4 466   cells 772   fmax 54.57 MHz  ICESTORM_LC 614  (*)
ice40-2-INT-BRAM_BP:    LUT4 498   cells 803   fmax 55.37 MHz  ICESTORM_LC 648  (*)
ice40-2-INT-BRAM_DP:    LUT4 424   cells 729   fmax 54.90 MHz  ICESTORM_LC 573  (*)
ice40-2-INT-BRAM_DP_BP: LUT4 431   cells 736   fmax 55.41 MHz  ICESTORM_LC 585  (*)
-----------------------------------------------------------------------------------
ice40-4-INT-BRAM:       LUT4 523   cells 830   fmax 47.87 MHz  ICESTORM_LC 673  (*)
ice40-4-INT-BRAM_BP:    LUT4 564   cells 870   fmax 42.59 MHz  ICESTORM_LC 710  (*)
ice40-4-INT-BRAM_DP:    LUT4 491   cells 797   fmax 44.67 MHz  ICESTORM_LC 637  (*)
ice40-4-INT-BRAM_DP_BP: LUT4 485   cells 791   fmax 45.79 MHz  ICESTORM_LC 641  (*)
-----------------------------------------------------------------------------------
ice40-8-INT-BRAM:       LUT4 677   cells 980   fmax 37.16 MHz  ICESTORM_LC 802  (*) 
ice40-8-INT-BRAM_BP:    LUT4 720   cells 1022  fmax 36.98 MHz  ICESTORM_LC 849  (*) 
ice40-8-INT-BRAM_DP:    LUT4 647   cells 949   fmax 38.84 MHz  ICESTORM_LC 774  (*) 
ice40-8-INT-BRAM_DP_BP: LUT4 646   cells 948   fmax 38.77 MHz  ICESTORM_LC 789  (*) 
===================================================================================
(*) preliminary
```

### nextpnr-ecp5

```
<arch> - <chunk size> - <interrupt support> - <regfile type>
===================================================================================
ecp5-1-MIN-BRAM:          fmax 99.74 MHz          TRELLIS_COMB 720
ecp5-1-MIN-BRAM_BP:       fmax 93.96 MHz          TRELLIS_COMB 768
ecp5-1-MIN-BRAM_DP:       fmax 92.62 MHz          TRELLIS_COMB 812
ecp5-1-MIN-BRAM_DP_BP:    fmax 105.79 MHz         TRELLIS_COMB 810
ecp5-1-MIN-LOGIC:         fmax 96.75 MHz          TRELLIS_COMB 845
-----------------------------------------------------------------------------------
ecp5-2-MIN-BRAM:          fmax 112.68 MHz         TRELLIS_COMB 709
ecp5-2-MIN-BRAM_BP:       fmax 108.68 MHz         TRELLIS_COMB 703
ecp5-2-MIN-BRAM_DP:       fmax 106.51 MHz         TRELLIS_COMB 782
ecp5-2-MIN-BRAM_DP_BP:    fmax 117.97 MHz         TRELLIS_COMB 789
ecp5-2-MIN-LOGIC:         fmax 112.23 MHz         TRELLIS_COMB 1096
-----------------------------------------------------------------------------------
ecp5-4-MIN-BRAM:          fmax 102.88 MHz         TRELLIS_COMB 807
ecp5-4-MIN-BRAM_BP:       fmax 104.64 MHz         TRELLIS_COMB 813
ecp5-4-MIN-BRAM_DP:       fmax 110.53 MHz         TRELLIS_COMB 881
ecp5-4-MIN-BRAM_DP_BP:    fmax 105.81 MHz         TRELLIS_COMB 892
ecp5-4-MIN-LOGIC:         fmax 97.30 MHz          TRELLIS_COMB 1271
-----------------------------------------------------------------------------------
ecp5-8-MIN-BRAM:          fmax 75.72 MHz          TRELLIS_COMB 992
ecp5-8-MIN-BRAM_BP:       fmax 77.74 MHz          TRELLIS_COMB 1083
ecp5-8-MIN-BRAM_DP:       fmax 76.75 MHz          TRELLIS_COMB 1096
ecp5-8-MIN-BRAM_DP_BP:    fmax 77.01 MHz          TRELLIS_COMB 1102
ecp5-8-MIN-LOGIC:         fmax 77.71 MHz          TRELLIS_COMB 1901
===================================================================================
ecp5-1-INT-BRAM:          fmax 98.43 MHz          TRELLIS_COMB 803  (*)
ecp5-1-INT-BRAM_BP:       fmax 99.97 MHz          TRELLIS_COMB 824  (*)
ecp5-1-INT-BRAM_DP:       fmax 103.23 MHz         TRELLIS_COMB 879  (*)
ecp5-1-INT-BRAM_DP_BP:    fmax 96.99 MHz          TRELLIS_COMB 877  (*)
-----------------------------------------------------------------------------------
ecp5-2-INT-BRAM:          fmax 103.41 MHz         TRELLIS_COMB 740  (*)
ecp5-2-INT-BRAM_BP:       fmax 104.34 MHz         TRELLIS_COMB 755  (*)
ecp5-2-INT-BRAM_DP:       fmax 101.68 MHz         TRELLIS_COMB 812  (*)
ecp5-2-INT-BRAM_DP_BP:    fmax 106.92 MHz         TRELLIS_COMB 815  (*)
-----------------------------------------------------------------------------------
ecp5-4-INT-BRAM:          fmax 103.50 MHz         TRELLIS_COMB 779  (*)
ecp5-4-INT-BRAM_BP:       fmax 101.92 MHz         TRELLIS_COMB 859  (*)
ecp5-4-INT-BRAM_DP:       fmax 106.28 MHz         TRELLIS_COMB 859  (*)
ecp5-4-INT-BRAM_DP_BP:    fmax 100.34 MHz         TRELLIS_COMB 872  (*)
-----------------------------------------------------------------------------------
ecp5-8-INT-BRAM:          fmax 75.08 MHz          TRELLIS_COMB 1035 (*)
ecp5-8-INT-BRAM_BP:       fmax 72.22 MHz          TRELLIS_COMB 1069 (*)
ecp5-8-INT-BRAM_DP:       fmax 76.72 MHz          TRELLIS_COMB 1117 (*)
ecp5-8-INT-BRAM_DP_BP:    fmax 71.47 MHz          TRELLIS_COMB 1124 (*)
===================================================================================
(*) preliminary
```

### nextpnr-gowin

```
<arch> - <chunk size> - <interrupt support> - <regfile type>
===================================================================================
gowin-1-MIN-BRAM:         fmax 48.81 MHz          SLICE 1026
gowin-1-MIN-BRAM_BP:      fmax 38.80 MHz          SLICE 1137
gowin-1-MIN-BRAM_DP:      fmax 38.85 MHz          SLICE 1146
gowin-1-MIN-BRAM_DP_BP:   fmax 38.08 MHz          SLICE 1137
gowin-1-MIN-LOGIC:        fmax 36.17 MHz          SLICE 2029
-----------------------------------------------------------------------------------
gowin-2-MIN-BRAM:         fmax 35.20 MHz          SLICE 1142
gowin-2-MIN-BRAM_BP:      fmax 39.53 MHz          SLICE 1149
gowin-2-MIN-BRAM_DP:      fmax 39.91 MHz          SLICE 1114
gowin-2-MIN-BRAM_DP_BP:   fmax 38.63 MHz          SLICE 1117
gowin-2-MIN-LOGIC:        fmax 32.80 MHz          SLICE 2579
-----------------------------------------------------------------------------------
gowin-4-MIN-BRAM:         fmax 27.57 MHz          SLICE 1379
gowin-4-MIN-BRAM_BP:      fmax 27.61 MHz          SLICE 1336
gowin-4-MIN-BRAM_DP:      fmax 26.35 MHz          SLICE 1487
gowin-4-MIN-BRAM_DP_BP:   fmax 25.48 MHz          SLICE 1427
gowin-4-MIN-LOGIC:        fmax 22.14 MHz          SLICE 2924
-----------------------------------------------------------------------------------
gowin-8-MIN-BRAM:         fmax 23.53 MHz          SLICE 1605
gowin-8-MIN-BRAM_BP:      fmax 23.02 MHz          SLICE 1861
gowin-8-MIN-BRAM_DP:      fmax 22.49 MHz          SLICE 1847
gowin-8-MIN-BRAM_DP_BP:   fmax 22.65 MHz          SLICE 1924
gowin-8-MIN-LOGIC:        fmax 18.98 MHz          SLICE 3521
===================================================================================
gowin-1-INT-BRAM:         fmax 40.05 MHz          SLICE 1066  (*) 
gowin-1-INT-BRAM_BP:      fmax 33.96 MHz          SLICE 1189  (*) 
gowin-1-INT-BRAM_DP:      fmax 32.25 MHz          SLICE 1267  (*) 
gowin-1-INT-BRAM_DP_BP:   fmax 41.94 MHz          SLICE 1188  (*) 
-----------------------------------------------------------------------------------
gowin-2-INT-BRAM:         fmax 36.08 MHz          SLICE 1148  (*) 
gowin-2-INT-BRAM_BP:      fmax 33.25 MHz          SLICE 1285  (*) 
gowin-2-INT-BRAM_DP:      fmax 32.71 MHz          SLICE 1345  (*) 
gowin-2-INT-BRAM_DP_BP:   fmax 37.42 MHz          SLICE 1199  (*) 
-----------------------------------------------------------------------------------
gowin-4-INT-BRAM:         fmax 24.89 MHz          SLICE 1397  (*) 
gowin-4-INT-BRAM_BP:      fmax 23.61 MHz          SLICE 1443  (*) 
gowin-4-INT-BRAM_DP:      fmax 28.76 MHz          SLICE 1357  (*) 
gowin-4-INT-BRAM_DP_BP:   fmax 28.30 MHz          SLICE 1356  (*) 
-----------------------------------------------------------------------------------
gowin-8-INT-BRAM:         fmax 20.20 MHz          SLICE 1744  (*) 
gowin-8-INT-BRAM_BP:      fmax 19.45 MHz          SLICE 1693  (*) 
gowin-8-INT-BRAM_DP:      fmax 19.46 MHz          SLICE 1744  (*) 
gowin-8-INT-BRAM_DP_BP:   fmax 18.68 MHz          SLICE 1814  (*) 
===================================================================================
(*) preliminary
```

### GateMate

```
<arch> - <chunk size> - <interrupt support> - <regfile type>
===================================================================================
gatemate-1-MIN-BRAM:        fmax 32.18 MHz          CPEs 668
gatemate-1-MIN-BRAM_BP:     fmax 34.47 MHz          CPEs 712
gatemate-1-MIN-BRAM_DP:     fmax 36.44 MHz          CPEs 701
gatemate-1-MIN-BRAM_DP_BP:  fmax 36.20 MHz          CPEs 674
gatemate-1-MIN-LOGIC:       fmax 38.98 MHz          CPEs 1234
-----------------------------------------------------------------------------------
gatemate-2-MIN-BRAM:        fmax 27.23 MHz          CPEs 708
gatemate-2-MIN-BRAM_BP:     fmax 27.30 MHz          CPEs 742
gatemate-2-MIN-BRAM_DP:     fmax 28.31 MHz          CPEs 735
gatemate-2-MIN-BRAM_DP_BP:  fmax 27.17 MHz          CPEs 726
gatemate-2-MIN-LOGIC:       fmax 31.01 MHz          CPEs 1367
-----------------------------------------------------------------------------------
gatemate-4-MIN-BRAM:        fmax 24.78 MHz          CPEs 758
gatemate-4-MIN-BRAM_BP:     fmax 25.44 MHz          CPEs 796
gatemate-4-MIN-BRAM_DP:     fmax 26.10 MHz          CPEs 788
gatemate-4-MIN-BRAM_DP_BP:  fmax 25.18 MHz          CPEs 785
gatemate-4-MIN-LOGIC:       fmax 26.57 MHz          CPEs 1576
-----------------------------------------------------------------------------------
gatemate-8-MIN-BRAM:        fmax 21.06 MHz          CPEs 919
gatemate-8-MIN-BRAM_BP:     fmax 20.55 MHz          CPEs 905
gatemate-8-MIN-BRAM_DP:     fmax 22.06 MHz          CPEs 921
gatemate-8-MIN-BRAM_DP_BP:  fmax 19.13 MHz          CPEs 886
gatemate-8-MIN-LOGIC:       fmax 21.01 MHz          CPEs 1961
===================================================================================
gatemate-1-INT-BRAM:        fmax 29.08 MHz          CPEs 708  (*)
gatemate-1-INT-BRAM_BP:     fmax 28.39 MHz          CPEs 742  (*)
gatemate-1-INT-BRAM_DP:     fmax 35.71 MHz          CPEs 727  (*)
gatemate-1-INT-BRAM_DP_BP:  fmax 28.72 MHz          CPEs 717  (*)
-----------------------------------------------------------------------------------
gatemate-2-INT-BRAM:        fmax 24.92 MHz          CPEs 736  (*)
gatemate-2-INT-BRAM_BP:     fmax 25.62 MHz          CPEs 774  (*)
gatemate-2-INT-BRAM_DP:     fmax 27.71 MHz          CPEs 773  (*)
gatemate-2-INT-BRAM_DP_BP:  fmax 25.12 MHz          CPEs 735  (*)
-----------------------------------------------------------------------------------
gatemate-4-INT-BRAM:        fmax 23.63 MHz          CPEs 812  (*)
gatemate-4-INT-BRAM_BP:     fmax 20.19 MHz          CPEs 861  (*)
gatemate-4-INT-BRAM_DP:     fmax 21.77 MHz          CPEs 850  (*)
gatemate-4-INT-BRAM_DP_BP:  fmax 25.07 MHz          CPEs 818  (*)
-----------------------------------------------------------------------------------
gatemate-8-INT-BRAM:        fmax 18.64 MHz          CPEs 919  (*)
gatemate-8-INT-BRAM_BP:     fmax 18.39 MHz          CPEs 954  (*)
gatemate-8-INT-BRAM_DP:     fmax 20.10 MHz          CPEs 954  (*)
gatemate-8-INT-BRAM_DP_BP:  fmax 18.44 MHz          CPEs 934  (*)
===================================================================================
(*) preliminary
```

### 7-Series

```
<arch> - <chunk size> - <interrupt support> - <regfile type>; optimized for size
===================================================================================
xilinx-1-MIN-BRAM:          fmax 84.30 MHz        Slice 80
xilinx-1-MIN-BRAM_BP:       fmax 84.33 MHz        Slice 85
xilinx-1-MIN-BRAM_DP:       fmax 84.74 MHz        Slice 81
xilinx-1-MIN-BRAM_DP_BP:    fmax 96.73 MHz        Slice 71
xilinx-1-MIN-LOGIC:         fmax 77.11 MHz        Slice 83
-----------------------------------------------------------------------------------
xilinx-2-MIN-BRAM:          fmax 81.16 MHz        Slice 77
xilinx-2-MIN-BRAM_BP:       fmax 67.54 MHz        Slice 93
xilinx-2-MIN-BRAM_DP:       fmax 77.40 MHz        Slice 85
xilinx-2-MIN-BRAM_DP_BP:    fmax 78.98 MHz        Slice 74
xilinx-2-MIN-LOGIC:         fmax 58.57 MHz        Slice 106
-----------------------------------------------------------------------------------
xilinx-4-MIN-BRAM:          fmax 63.98 MHz        Slice 89
xilinx-4-MIN-BRAM_BP:       fmax 71.75 MHz        Slice 88
xilinx-4-MIN-BRAM_DP:       fmax 68.81 MHz        Slice 90
xilinx-4-MIN-BRAM_DP_BP:    fmax 65.38 MHz        Slice 81
xilinx-4-MIN-LOGIC:         fmax 57.47 MHz        Slice 162
-----------------------------------------------------------------------------------
xilinx-8-MIN-BRAM:          fmax 53.55 MHz        Slice 105
xilinx-8-MIN-BRAM_BP:       fmax 46.97 MHz        Slice 99
xilinx-8-MIN-BRAM_DP:       fmax 56.09 MHz        Slice 106
xilinx-8-MIN-BRAM_DP_BP:    fmax 53.10 MHz        Slice 94
xilinx-8-MIN-LOGIC:         fmax 47.31 MHz        Slice 229
===================================================================================
xilinx-1-INT-BRAM:          fmax 88.33 MHz        Slice 87   (*)
xilinx-1-INT-BRAM_BP:       fmax 90.36 MHz        Slice 90   (*)
xilinx-1-INT-BRAM_DP:       fmax 76.68 MHz        Slice 86   (*)
xilinx-1-INT-BRAM_DP_BP:    fmax 90.41 MHz        Slice 79   (*)
-----------------------------------------------------------------------------------
xilinx-2-INT-BRAM:          fmax 73.29 MHz        Slice 86   (*)
xilinx-2-INT-BRAM_BP:       fmax 65.65 MHz        Slice 91   (*)
xilinx-2-INT-BRAM_DP:       fmax 69.73 MHz        Slice 80   (*)
xilinx-2-INT-BRAM_DP_BP:    fmax 62.47 MHz        Slice 85   (*)
-----------------------------------------------------------------------------------
xilinx-4-INT-BRAM:          fmax 64.33 MHz        Slice 86   (*)
xilinx-4-INT-BRAM_BP:       fmax 65.23 MHz        Slice 91   (*)
xilinx-4-INT-BRAM_DP:       fmax 61.06 MHz        Slice 94   (*)
xilinx-4-INT-BRAM_DP_BP:    fmax 56.19 MHz        Slice 88   (*)
-----------------------------------------------------------------------------------
xilinx-8-INT-BRAM:          fmax 42.74 MHz        Slice 106  (*)
xilinx-8-INT-BRAM_BP:       fmax 45.36 MHz        Slice 109  (*)
xilinx-8-INT-BRAM_DP:       fmax 42.00 MHz        Slice 113  (*)
xilinx-8-INT-BRAM_DP_BP:    fmax 47.52 MHz        Slice 104  (*)
===================================================================================
(*) preliminary
```

## Verilog Sources


> [!IMPORTANT]  
> Note that even slight changes (e.g., removing or adding comments) in the Verilog design can lead to some fluctuations in the implemented design when reproducing the results. An example is given below.


`rtl_mod/fazyrv_spm_d_mod1.sv` and `rtl_mod/fazyrv_spm_d_mod2.sv` are two modifications of `rtl/fazyrv_spm_d.sv` that remove a different number of comment lines in the header. Although the rest of the Verilog code is identical, this leads to some variance in the implemented SoC.


```
ice40-8-MIN-BRAM_DP_BP
=====================
==> rtl/fazyrv_spm_d.sv 
   Number of cells:                888
     SB_LUT4                       590

==> rtl_mod/fazyrv_spm_d_mod1.sv 
   Number of cells:                887
     SB_LUT4                       589
     
==> rtl_mod/fazyrv_spm_d_mod2.sv 
   Number of cells:                901
     SB_LUT4                       603
```


## Tools and Versions

| Tool              | Version | Git        |
|-------------------|---------|------------|
| Yosys             | 0.35    | `cc31c6e`  |
| nextpnr           | 0.6     | `ca2e328`  |
| Vivado            | v2023.2 |            |
| Cologne Chip p_r  | 4.2     |            |
