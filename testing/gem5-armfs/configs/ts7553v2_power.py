# configs/ts7553v2_power.py
#
# Minimal ARMv7 FS with simple power models (CPU + DRAM).
# Inspired by gem5's example fs_power.py and ARM FS configs.  [2](https://www.gem5.org/documentation/learning_gem5/part2/arm_power_modelling/)[1](https://www.gem5.org/documentation/general_docs/fullsystem/building_arm_kernel)

import m5
from m5.objects import *
from m5.util import addToPath
import os
import argparse

# ---- Simple power models (toy coefficients you will calibrate) ----
class CpuOn(MathExprPowerModel):
    # Dynamic power: proportional to IPC and L1 D$ misses (example)
    dyn = "voltage * (1.8 * ipc + 1e-9 * dcache.overall_misses / sim_seconds)"
    # Static/leakage (scaled by temp)
    st  = "0.5 * temp"

class CpuOff(MathExprPowerModel):
    dyn = "0"
    st  = "0"

class CpuPwr(PowerModel):
    pm = [CpuOn(), CpuOff(), CpuOff(), CpuOff()]

class DramOn(MathExprPowerModel):
    # Simple DRAM power: bandwidth proxy via read/write bytes per second
    dyn = "1e-10 * (dram.readReqs + dram.writeReqs) / sim_seconds"
    st  = "0.2"

class DramPwr(PowerModel):
    pm = [DramOn(), DramOn(), DramOn(), DramOn()]

# ---- Build system ----
def build_system(kernel, disk, num_cpus=1, cpu_clock="1GHz", sys_clock="1GHz", mem_size="512MB"):
    system = ArmSystem()
    system.workload = ArmFsLinux()  # Full-system Linux workload
    system.mem_mode = "timing"
    system.mmap_using_noreserve = False

    # Clocks
    system.clk_domain = SrcClockDomain(clock=sys_clock, voltage_domain=VoltageDomain())
    system.cpu_voltage_domain = VoltageDomain()
    system.cpu_clk_domain = SrcClockDomain(clock=cpu_clock, voltage_domain=system.cpu_voltage_domain)

    # Platform + memory
    system.realview = VExpress_GEM5_V1()
    system.mem_ranges = [AddrRange(mem_size)]
    system.membus = SystemXBar(width=64)

    # CPUs
    system.cpu = [MinorCPU() for _ in range(num_cpus)]
    for i, cpu in enumerate(system.cpu):
        cpu.clk_domain = system.cpu_clk_domain
        cpu.createThreads()
        cpu.icache = Icache = L1I(size="32kB", assoc=2)
        cpu.dcache = Dcache = L1D(size="32kB", assoc=2)
        cpu.icache.connectCPU(cpu)
        cpu.dcache.connectCPU(cpu)
        cpu.itb = ArmTLB()
        cpu.dtb = ArmTLB()

        # Simple power model per CPU
        cpu.power_model = CpuPwr()

    # L2
    system.l2 = L2XBar()
    system.l2cache = L2Cache(size="512kB", assoc=8)
    system.l2cache.mem_side = system.membus.cpu_side_ports
    for cpu in system.cpu:
        cpu.icache.connectBus(system.l2)
        cpu.dcache.connectBus(system.l2)
    system.l2.mem_side = system.l2cache.cpu_side

    # Interrupts & system ports
    for cpu in system.cpu:
        cpu.createInterruptController()
        cpu.interrupts[0].piobus = system.membus.mem_side_ports
        cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
        cpu.interrupts[0].int_responder = system.membus.mem_side_ports
    system.system_port = system.membus.cpu_side_ports

    # Memory controller + power model
    system.mem_ctrl = DDR3_1600_8x8()
    system.mem_ctrl.range = system.mem_ranges[0]
    system.mem_ctrl.port = system.membus.mem_side_ports
    system.mem_ctrl.power_model = DramPwr()

    # Devices
    system.iobus = SystemXBar()
    system.realview.attachOnChipIO(system.membus, system.iobus)
    system.realview.attachIO(system.iobus)

    # Workload: kernel, dtb, cmdline, disk
    system.kernel = kernel
    # The DTB for VExpress_GEM5_V1 ships with gem5; let gem5 auto-pick.  [5](https://gem5.googlesource.com/public/gem5-website/+/8ba768199ecfaaaefb5e74f99ba2aff6a9f9e1f8/_pages/documentation/general_docs/fullsystem/building_arm_kernel.md)
    system.readfile = ""  # no rcS script by default
    system.boot_loader = [ ArmFsBootLoader() ]  # from aarch-system tarball  [3](https://www.gem5.org/documentation/general_docs/fullsystem/guest_binaries)

    # Disk image
    system.disk_image = CowDiskImage(child=RawDiskImage(read_only=True), read_only=False)
    system.disk_image.child.image_file = disk
    system.realview.vio[0].pcidev.config[0].BAR0 = system.disk_image  # virtio-blk hookup via VExpress

    # Connect I/O and memory
    system.iobridge = Bridge(delay='50ns')
    system.iobridge.mem_side_port = system.membus.cpu_side_ports
    system.iobridge.cpu_side_port = system.iobus.mem_side_ports

    return system

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--kernel", required=True, help="Path to ARMv7 vmlinux")
    p.add_argument("--disk", required=True, help="Path to AArch32 disk image")
    p.add_argument("--num-cpus", type=int, default=1)
    p.add_argument("--cpu-clock", default="1GHz")
    p.add_argument("--sys-clock", default="1GHz")
    p.add_argument("--mem-size", default="512MB")
    args = p.parse_args()

    system = build_system(args.kernel, args.disk, args.num_cpus, args.cpu_clock, args.sys_clock, args.mem_size)

    root = Root(full_system=True, system=system)
    m5.instantiate()
    exit_event = m5.simulate()  # run until guest shutdown or m5 exit
    print("Exiting @ tick {} because {}"
          .format(m5.curTick(), exit_event.getCause()))

if __name__ == "__main__":
    main()