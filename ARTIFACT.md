# SCFTL Artifact

## Artifact overview

This document describes the artifact of our OSDI '20 paper: **Determinizing Crash Behavior with a Verified Snapshot-Consistent Flash Translation Layer**.

This artiract consists of four major parts:

1. Verifing snapshot consistency (Section 4)
2. Verifing SCFTL (Section 5)
3. Testing SCFTL (Section 7.1)
4. Running experiments on xv6/SCFTL (Section 7.2  Figure 5 and 7.3)

For each part, we give instructions on how to automatically obtain the result. We also provide the expected results.

### OS requirement

* Most recent Linux distributions should work. We have tested on Ubuntu 18.04 and NixOS.

Although we provide a Docker image, the last part (running experiments on xv6/SCFTL) will **NOT** work on Windows or Mac even if you use *Docker for Windows* or *Docker for Mac* because it requires the host OS to expose the KVM interface.

### Hardware requirement

* At least 16 GB of DRAM
* CPU supporting KVM (Intel VT or AMD-V)

#### DRAM

We need at least 16 GB of DRAM because our experiments are done on [FEMU](https://github.com/ucare-uchicago/femu), a QEMU-based emulator supporting the emulation of an Open-Channel SSD (OCSSD).
FEMU emulates an 8-GB OCSSD with 8 GB of DRAM.

#### KVM

You can run the following command to check if your CPU support KVM:

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
$ sudo docker run -it --rm --privileged yunshengchang/scftl:artifact
```

The flag `--privileged` is required because FEMU needs to access the virtualization hardware (at `/dev/kvm`).
From now on, we will assume the following steps are performed on the container.

## Step 1: Verifing snapshot consistency

**Estimated execution time**: less than 3 minutes

### Instruction

```
$ cd /env/scftl/agda
$ ./check.sh
```

### Expected results

```
Checking snapshot consistency
Pass
```

### Description

Please refer to [TODO](ref).

## Step 2: Verifing SCFTL

**Estimated execution time**: 1 hour ~ 3 hours

### Instruction

```
$ cd /env/scftl/verif
$ make
```

### Expected results

Checking methods with specification:

```
Tests for ftl.c
Running test "@check_sufficient_avail_blocks"
Number of side conditions: 0
Side conditions checked
Checking method specification
Method specification verified
cpu time: 23 real time: 643 gc time: 0
...
```

Checking loops with specification:

```
Running test "@invalidate_delta_buf_loop"
Number of side conditions: 3
Side conditions checked
Loop specification verified
cpu time: 11 real time: 396 gc time: 0
Finished test "@invalidate_delta_buf_loop"
...
```

Checking FTL operations (`ftl_write`, `ftl_flush`, `ftl_gc_copy`, `ftl_gc_erase`, and `ftl_recovery`). We show the expected results when verifying `ftl_write`:

```
Running test "@ftl_write"
...
Number of side conditions: 40
Side conditions checked
Checking RI
Sectors in usable blocks do not appear in L2P (81 conjuncts) [Proved]
Sectors in the right half of the active block do not appear in L2P (82 conjuncts) [Proved]
L2P is an one-to-one mapping except for invalid entries (99 conjuncts) [Proved]
...
RI holds
Checking AR
The GC counters are equal (99 conjuncts) [Proved]
The active sectors are equal (99 conjuncts) [Proved]
The active pages are equal (99 conjuncts) [Proved]
...
AR holds
Checking CI
Proving crash state 0
At least one full checkpoint is committed (99 conjuncts) [Proved]
Both full checkpoint commit flags are synchronized (99 conjuncts) [Proved]
A raised full checkpoint commit flag implies that the L2P table is synchronized (99 conjuncts) [Proved]
...
CI holds
Checking CR
Proving crash state 0 under initial state partition 0
Unpack this (70 conjuncts) [Proved]
Stable L2P entries point to the data region (99 conjuncts) [Proved]
Stable L2P entries point to synchronized pages (99 conjuncts) [Proved]
...
CR holds
cpu time: 1379 real time: 507533 gc time: 33
Finished test "@ftl_write"
```

Checking observational equivalence (`ftl_read`)

```
Running test "Observational equivalence"
Number of side conditions: 4
Side conditions checked
Checking observational equivalence
Observational equivalence checked
cpu time: 44 real time: 7041 gc time: 5
Finished test "Observational equivalence"
```

Checking initial consistency (`ftl_format`)

```
Running test "Initial consistency"
Number of side conditions: 1
Side conditions checked
Checking CI
At least one full checkpoint is committed [Proved]
Both full checkpoint commit flags are synchronized [Proved]
A raised full checkpoint commit flag implies that the L2P table is synchronized [Proved]
...
CI holds
Checking CR
Unpack this [Proved]
Stable L2P entries point to the data region [Proved]
Stable L2P entries point to synchronized pages [Proved]
...
CR holds
cpu time: 19 real time: 425 gc time: 0
Finished test "Initial consistency"
```

Finally, 

```
20 success(es) 0 failure(s) 0 error(s) 20 test(s) run
cpu time: 8523 real time: 3786908 gc time: 339
0
  20 ftl.rkt
20 tests passed
```


### File structure

* `verif/inv-rel.rkt` contains the representation invariants (RI), abstraction relation (AR), crash representation invariants (CI), crash abstraction relation (CR).

## Step 3: Testing SCFTL

**Estimated execution time**: ~10 minutes

### Instruction

```
$ cd /env/scftl/test
$ make && ./test.sh 2
```

### Expected results

```
[mkftl] Formating flash starts.
[flashemu] Flash image ./init.img not found. Generate a new one.
[flashemu] flash_fini: Number of written pages = 514.
[mkftl] Formating flash ends.
[crash-test] Hello crash! crash = 10000 wr = 100 cmp = 100
Simulated 19846 writes, 218 flushes, and 1 crashes.
Pass all 186 times of comparison.
[crash-test] Hello crash! crash = 10000 wr = 100 cmp = 200000
Simulated 1511901 writes, 15300 flushes, and 3 crashes.
Pass all 4 times of comparison.
[crash-test] Hello crash! crash = 400000 wr = 2 cmp = 20000
Simulated 29574 writes, 29774 flushes, and 1 crashes.
Pass all 2 times of comparison.
[crash-test] Hello crash! crash = 5 wr = 100 cmp = 1000
Simulated 15271 writes, 159 flushes, and 380 crashes.
Pass all 14 times of comparison.
```

### Note

1. As described in our paper, we ran the test with 4 configurations for 8 hours, but the instructions above only run each configuration for two minutes. You can tell `test.sh` how long (in minutes) you want to run the test. E.g., `./test.sh 480` will run each configuration for 8 hours.
2. We use main memory to emulate flash memory, so running each test may require up to 8 GB of main memory. The test may fail when the system is running out of memory.

## Step 4: Runnig experiment on xv6 + SCFTL

### Instruction

**Estimated execution time**: 5 minutes + ? hours + 51 minutes

### Instruction

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
$ git clone https://github.com/yunshengtw/scftl.git && cd scftl && make
$ cd exp
$ ./randwr.sh && ./app.sh
```

All the benchmarks that we use in Section 7.2 and 7.3 will start.

Finally, you can compare the results produced on your machine with the ones produced on ours:

```
$ python parse.py && python cmp.py
```

### Expected results

```
```
