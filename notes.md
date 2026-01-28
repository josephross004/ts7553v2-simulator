### Simulating TS-7553 Board

Specifications: 
- CPU: **NXP i.MX6UL (UltraLite)
- ARM core: **ARM Cortex A7**
- Architecture: **ARMv7-A (hard-float, NEON)**
- Debian equivalent: **armhf**

Simulation takes place on two 'tracks'.

Track A: ARM Build/Dev Container

`FROM --platform=linux/arm/v7 debian:bookworm-slim`

A 32-bit ARMv7 (armhf) Debian environment specifically designed for native ARM compilation. Runs at the same speed as the host PC and does not monitor energy or memory usage. 

The purpose is to have a real ARMv7-A userspace to compile ARM binaries, run 32-bit ARM programs, ensure ABI compatibility, and use Debian packages similar to what runs on the real board. 

The image means that `gcc` and `clang` inside the container target 32-bit ARM hf by default. As a sanity check, feel free to run `dpkg --print-architecture` and it will report `armhf`.

The TS-7553-v2 runs Debian Jesse/Stretch armhf so binaries built on Track A are guaranteed to run (machine-instructions wise - memory is still limited.)

Track B: `gem5` simulation container

An x86-64 host, which runs `gem5`, simulating the `ARM Cortex-A7` CPU and the i.MX6UL-class SoC timing, performance, and power models. 

This is the performance, timing, memory, and power analysis environment. Runs  `gem5` on the local host, simulates the `Cortex A7 class ARMv7-A` core, boots a full Linux ARM guest, and measurs runtime, CPU power modeling, DRAM power modeling, instruction counts, IPC, MPKI, DRAM accesses, etc. 

This is not for compiling, it's only for measuring. 


|Step|Track|What happens|
|----|-----|------|
|1|A|Compile the program to armhf binary|
|2|A|Confirm functionality|
|3|B|Boot gem5 ARM Linux and run the same binary|
|4|B|Measure timing, power, memory|
|5|Real Board|Deploy the same armhf binary to the real board for production.

--------
Redistributability

On my computer I need to run: 

```powershell 
docker save -o gem5-armfs-image.tar gem5-armfs
```

which will copy the `.tar` file image, the Dockerfile, and the `ps1` script to the hard drive.

Then on a target machine, anyone can load the image to skip the build process; 

```powershell
docker load -i gem5-armfs-image.tar
```

IF AND ONLY IF it's another x86 computer (**New Apple won't work!!**)

----------
Sanity testing for track A

Write up a dummy program:
```c
// hello.c

#include <stdio.h>
int main(void) { puts("Hello from 32-bit!"); return 0; }
```

Compile: 

```bash
gcc hello.c
```

Check the ELF header of resulting `a.out`:

```bash
file a.out
```

> `a.out: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=d4a4f5ccfe813185b47b827fc2889ede0d9ba1d3, for GNU/Linux 3.2.0, not stripped`