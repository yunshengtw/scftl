# SCFTL Artifact

## Overview

This document describes the artifact of our SCFTL paper and explains the connection between the artifact and the paper.
It will guide readers on how to verify SCFTL, and how to perform the same set of experiments described in the paper to replicate the main results.

The artifact consists of four major parts:

1. Verifying snapshot consistency (Section 4)
2. Verifying SCFTL against its specification (Section 5)
3. Testing crash safety of SCFTL (Section 7.1)
4. Running experiments on SCFTL (Section 7.2 and 7.3)

### OS requirement

* Most recent Linux distributions should work. We have tested on Ubuntu 18.04 and NixOS 20.03.

Although we provide a Docker image, the last part (running experiments on SCFTL) will **NOT** work on Windows or Mac even with *Docker Desktop for Windows* or *Docker Desktop for Mac*. The reason is that the last part requires the host OS to expose the KVM interface.

### Hardware requirement

* At least 16 GB of DRAM
* CPU supporting KVM (Intel VT or AMD-V)


We need at least 16 GB of DRAM because the experiments will be conducted on [FEMU](https://github.com/ucare-uchicago/femu), a QEMU-based emulator supporting the emulation of an Open-Channel SSD (OCSSD), and FEMU emulates an 8-GB OCSSD with 8 GB of DRAM.

You can run the following command to check if your CPU supports KVM:

```
$ egrep -c '(vmx|svm)' /proc/cpuinfo
```

If the result is a number larger than 0, then your CPU *does* supports KVM. Still, please make sure you have enabled virtualization support in BIOS.

## Step 0: Setting up Docker

**Estimated execution time**: less than 15 minutes

### Install Docker

Please refer to the following guides:
[CentOS](https://docs.docker.com/engine/install/centos/),
[Debian](https://docs.docker.com/engine/install/debian/),
[Fedora](https://docs.docker.com/engine/install/fedora/), and
[Ubuntu](https://docs.docker.com/engine/install/ubuntu/).
 
### Download our Docker image

We provide a Docker image containing all the tools required to evaluate this artifact.
You can pull the image with the following command:

```
$ docker pull yunshengchang/scftl
```

### Start a Docker container

```
$ sudo docker run -it --rm --privileged yunshengchang/scftl
```

The flag `--privileged` is required because FEMU needs to access the KVM interface (at `/dev/kvm`).
We will assume the following steps are performed on the container.

## Step 1: Verifying snapshot consistency

Our formal verification framework starts with some high-level definitions and theorems described in Section 4 of the paper, including the SCFTL specification (Section 4.1), the definition of snapshot consistency (Section 4.2), and the reduction of a behavioral correctness property over multiple FTL operations (Section 4.3 and 4.4).
All these definitions and theorems are mechanized in `agda/SnapshotConsistency.agda` using the Agda proof assistant.

Below are the commands to mechanically check the proof.

### Instruction

**Estimated execution time**: less than 3 minutes

```
$ cd /env/scftl/agda
$ ./check.sh
```

### Expected results

```
Checking snapshot consistency
Pass
```

### Detailed description

We wrote a [document](https://github.com/yunshengtw/scftl/blob/master/agda/sc.pdf) to describe the mechanized proof in detail.

## Step 2: Verifying SCFTL against its specification

We use the symbolic executor [Serval](https://unsat.cs.washington.edu/projects/serval/) and the SMT solver [Z3](https://github.com/Z3Prover/z3) to prove that every FTL operation meets its specification:

* Regular operations should preserve the representation invariant $RI$ and the abstraction relation $AR$ when successfully executed, and establish the crash representation invariant $CI$ and the crash abstraction relation $CR$ on a crash.
* The recovery operation should establish $RI$ and $AR$ when successfully executed and preserve $CI$ and $CR$ on a crash.
* The read operation should ensure that the results produced by the implementation and by the specification are the same when $RI$ and $AR$ are established.
* The format operation should establish $CI$ and $CR$.

### Instruction

**Estimated execution time**: 1 hour ~ 3 hours

```
$ cd /env/scftl/verif
$ make
```

### Expected results

Checking that`ftl_write`, `ftl_flush`, `ftl_gc_copy`, `ftl_gc_erase`, and `ftl_recovery` meet their specification.
Here we show the expected results for `ftl_write`:

```
Running test "@ftl_write"
...
Number of side conditions: 40
Side conditions checked
Checking RI
Sectors in usable blocks do not appear in L2P [Proved]
...
RI holds
Checking AR
The GC counters are equal [Proved]
...
AR holds
Checking CI
Proving crash state 0
At least one full checkpoint is committed [Proved]
...
CI holds
Checking CR
Proving crash state 0 under initial state partition 0
The page address of the last committed delta page is less than or equal to the number of pages per block [Proved]
...
CR holds
cpu time: 1379 real time: 507533 gc time: 33
Finished test "@ftl_write"
```

Checking that `ftl_read` ensures observational equivalence:

```
Running test "Observational equivalence"
Number of side conditions: 4
Side conditions checked
Checking observational equivalence
Observational equivalence checked
cpu time: 44 real time: 7041 gc time: 5
Finished test "Observational equivalence"
```

Checking that `ftl_format` establishes initial consistency:

```
Running test "Initial consistency"
Number of side conditions: 1
Side conditions checked
Checking CI
At least one full checkpoint is committed [Proved]
...
CI holds
Checking CR
The page address of the last committed delta page is less than or equal to the number of pages per block [Proved]
...
CR holds
cpu time: 19 real time: 425 gc time: 0
Finished test "Initial consistency"
```

Finally, a successful verification should display the following messages:

```
20 success(es) 0 failure(s) 0 error(s) 20 test(s) run
cpu time: 8523 real time: 3786908 gc time: 339
0
  20 ftl.rkt
20 tests passed
```

### Important files

* `verif/lib/llvm-extend.rkt`: this file intercepts Serval's LLVM `call` command to support flash operations (e.g., `flash_program`)
* `verif/lib/flash.rkt`: the flash memory model described in Section 5.1
* `verif/ftl.rkt`: this file contains the code that actually performs the verfication tasks
* `verif/inv-rel.rkt`: the definitions of $RI$, $AR$, $CI$, and $CR$, including the optimization of grouping conditions described in Section 5.3
* `verif/spec.rkt`: the SCFTL specification, including the use of auxiliary variables described in Section 5.2
* `verif/partition.rkt`: the use of the partitioning technique described in Section 5.4
* `src/ftl.c`: the SCFTL implementation

## Step 3: Testing crash-safety of SCFTL

As described in Section 7.1, we also design a testing framework that could emulate flash memory, generate disk workloads, simulate crashes, and compare the results of SCFTL with the golden results.

The testing framework is implemented by `src/crash-test.c` and `src/flashemu.c`.

### Instruction

**Estimated execution time**: ~10 minutes

```
$ cd /env/scftl/test
$ make && ./test.sh 2
```

### Expected results

```
[crash-test] Hello crash! crash = 10000 wr = 100 cmp = 100
Simulated 19846 writes, 218 flushes, and 1 crashes.
Pass all 186 times of comparison.

```

### Notes

1. As described in the paper, we ran the test with 4 configurations, each for 8 hours, but the instruction above only executes each configuration for two minutes. You can modify this by telling `test.sh` how long (in minutes) you want to run the test. For example, `./test.sh 480` will run the test with 4 configurations, each for 8 hours.
2. We use main memory to emulate flash memory, so running each test may require up to 8 GB of main memory. The test may fail when the system runs out of memory.

## Step 4: Running experiments on SCFTL

There are two sets of experiments in the paper.
The first set (Section 7.2) uses a random write workload to analyze the overhead due to snapshot consistency.
The second set (Section 7.3) uses existing file system benchmarks to understand the usefulness of SCFTL from the perspective of a file system.

The experimental results we reported in the paper are produced by a machine with a 3.2 GHz Intel i7-8700 CPU and 16 GB of DRAM; the results generated on your machine may be somewhat different than ours.

We include the results reported in the paper (Figure 5, 6, and 7) under the directory `exp/ref`, and prepare a script to easily compare the results produced on your machine with the ones produced on ours.
Although the results may differ from one machine to another, there are some key findings that should be replicated across machines:

1. The overhead due to snapshot consistency should be little when the write interval is large enough.
2. SCFTL should be useful from the perspective of a file system.
3. The performance of xv6 + SCFTL should not be too far from that of the state-of-the-art ext4 + pblk.

The script for comparing results will also summarize whether these key findings can be replicated on your machine.

### Instruction

**Estimated execution time**: ~ 4 hours

First, start an FEMU instance:

```
$ cd /env
$ ./boot-femu.sh
The FEMU instance is booting up.
nohup: appending output to 'nohup.out'
The FEMU instance is ready. Use '$ ssh-femu' to connect to the instance.
```

If you did not see the above message in five minutes (most likely due to KVM disabled or out of memory), please run: `dmesg > dmesg.out` and send us two files: `nohup.out` and `dmesg.out`. Both of them are located under the directory `/env`. Thank you very much!

Connect to the FEMU instance via ssh:

```
$ ssh-femu
```

The following commands are performed on the FEMU instance.

```
$ git clone https://github.com/yunshengtw/scftl.git && cd scftl && make
$ cd exp
$ ./randwr.sh && ./app.sh
```

All the benchmarks that we use in Section 7.2 and 7.3 will begin.
The benchmarks should take 3.5~4 hours to complete.

Finally, you can run the parsing and comparing scripts:

```
$ python parse.py && python cmp.py
```

### Expected results



In the output, *yours* is the result produced on your machine, *ours* is the result produced on our machine (of course, it is also the one reported in the paper), and *diff* = *yours* - *ours*.

Figure 5

```
Comparing Figure 5(c) legend = scftl (unit: K IOPS)
[x = 0 sec] yours = 19.56 ours = 19.56 diff = 0.00 (+0.01%)
[x = 100 sec] yours = 17.66 ours = 17.64 diff = 0.03 (+0.15%)
[x = 200 sec] yours = 17.74 ours = 17.72 diff = 0.03 (+0.14%)
[x = 300 sec] yours = 17.77 ours = 17.64 diff = 0.13 (+0.73%)
[x = 400 sec] yours = 17.61 ours = 17.74 diff = -0.13 (-0.72%)
[x = 500 sec] yours = 17.77 ours = 17.64 diff = 0.13 (+0.73%)
[average] yours = 17.97 ours = 17.94 diff = 0.02 (+0.13%)
```

Figure 6

```
Comparing Figure 6 application = SQLite (unit: txn/s)
[legend = xv6/async] yours = 8.74 ours = 9.00 diff = -0.26 (-2.86%)
[legend = xv6/sync] yours = 11.33 ours = 11.00 diff = 0.33 (+3.03%)
[legend = xv6-xlog] yours = 10.80 ours = 11.00 diff = -0.20 (-1.81%)
[legend = xv6-group] yours = 65.29 ours = 61.00 diff = 4.29 (+7.03%)
```

Figure 7

```
Comparing Figure 7 application = SQLite (unit: txn/s)
[legend = ext4-metadata] yours = 93.82 ours = 93.00 diff = 0.82 (+0.89%)
[legend = ext4-data] yours = 141.13 ours = 142.00 diff = -0.87 (-0.61%)
[legend = xv6-group] yours = 65.29 ours = 61.00 diff = 4.29 (+7.03%)
```

Summary

```
Key finding 1: The overhead due to snapshot consistency should be little when the write interval is large enough.
Computing the relative performance of *scftl* to *async* given write interval = 2048 (Figure 5)
yours = 95.20% ours = 95.28% diff = -0.07%

Key finding 2: SCFTL should be useful from the perspective of a file system.
Computing the relative performance of *xv6-group* to *xv6/async* (Figure 6)
[SQLite] yours = 7.47x ours = 6.78x diff = +0.69x
[smallfiles] yours = 3.68x ours = 3.43x diff = +0.25x
[largefile] yours = 82.56x ours = 65.00x diff = +17.56x
[mailbench] yours = 8.33x ours = 7.74x diff = +0.60x

Key finding 3: The performance of xv6 + SCFTL should not be too far from that of the state-of-the-art ext4 + pblk.
Computing the relative performance of *xv6-group* to *ext4-metadata* (Figure 7)
[SQLite] yours = 0.70x ours = 0.66x diff = +0.04x
[smallfiles] yours = 0.56x ours = 0.52x diff = +0.04x
[largefile] yours = 0.80x ours = 0.62x diff = +0.18x
[mailbench] yours = 1.00x ours = 0.93x diff = +0.07x
```

### Play with xv6 + SCFTL

You can also play with the xv6 + SCFTL stack with your own applications/benchmarks.
Please note that there are some limitations with the xv6 file system (e.g., the maximum file size is relatively small and some operations are not supported).

Run the following commands to mount the file system at `/tmp/fs`.

```
$ cd /home/ubuntu/scftl
$ ./scripts/mount.sh xv6fs-xlog-gcm
```