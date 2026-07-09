---
title: the-cooperative-os
subtitle: How trusting your software could make everything faster, and why we stopped.
date: 2026-07
display-date: July 2026
byline: Ethan Smith
slug: the-cooperative-os
summary: How trusting your software could make everything faster, and why we stopped.
links:
  - text: Codeberg
    url: https://codeberg.org/binaryspy/the-cooperative-os
  - text: GitHub
    url: https://github.com/Binary12Spy/the-cooperative-os
---

We expect a lot from our operating systems, today we may simultaneously have several browser tabs open, some documents open for review, a video editing program up that we're working on, and a music player going on in the background. This paper aims to work through the history of multitasking and personal computers, how we came to stop trusting our software, and exploring how we could trust it again.

# The History of The OS
## Single-Threaded Illusion

[Gary Kildall](https://en.wikipedia.org/wiki/Gary_Kildall), an American computer scientist, created [CP/M](https://en.wikipedia.org/wiki/CP/M) (Control Program for Microcomputers) in 1974. It ran on the Intel 8080-based microcomputers and became the dominant OS for personal computers before Microsoft DOS hit the scene. Its initial implementation was simplistic, one task at a time. It would later add the capability to have multiple user sessions, and be migrated to a 16bit CPU.

[MS-DOS](https://en.wikipedia.org/wiki/MS-DOS) followed the same single-task model, released in 1981. Microsoft licensed [QDOS](https://en.wikipedia.org/wiki/86-DOS) (Quick and Dirty Operating System) from Seattle Computer Products and later licensed it to IBM. MS-DOS quickly became incredibly popular, and its similarities to CP/M made converting existing applications easy. DOS, in many forms, became the industry standard and served as the backbone of the entire PC revolution through the 1980s and early 1990s.

[TSRs](https://en.wikipedia.org/wiki/Terminate-and-stay-resident_program) (Terminate and Stay Resident) programs were the first DOS-era workaround to achieve background tasks. A program would be run, hook into the system interrupt table, load itself into memory, and "wake up" when triggered by a timer or keyboard input. The technology made personal computers feel more interactive than before. [SideKick](https://en.wikipedia.org/wiki/Borland_Sidekick), a program launched by Borland in 1984, capitalized on TSR technology to pop-up a calculator or notepad on-top of whatever program you were running at the time.

System timers of PCs in this age fired interrupts at ~18.2Hz (every 55ms), and developers used this as a steady heartbeat to drive background work. The system was doing more, all at the same time, without a scheduler directing traffic. If you wanted to make two or more things happen at once, you were crafting the interleaving yourself.

## The Cooperative Era

[Apple Lisa](https://en.wikipedia.org/wiki/Apple_Lisa) (1983) and then [MacOS](https://en.wikipedia.org/wiki/MacOS) (1984) introduced a formally defined cooperative multitasking model to personal computing. Instead of relying on hardware interrupts for your program to get CPU time, the OS put all running processes in a task list. Running programs were expected to yield during idle time, utilizing the Event Manager. When a process was at a point where it could hibernate for a moment, it would call `GetNextEvent` to tell the OS that it was "done for now." and the next task in order would be resumed.

[Windows 1.0](https://en.wikipedia.org/wiki/Windows_1.0) (1985) through to Windows 3.x used the same cooperative task management model. `GetMessage` in the windows API was the yield point and the message pump. An application that never called it starved the rest of the system of CPU time. The Cooperative Era was ushered in and provided formal multitasking.

This cooperative world worked remarkably well when software yielded when it could. Context switching between tasks was nearly free, all because the OS only switched when invited to. This also led to a failure mode that was system breaking. A program in an infinite loop, that was stuck on a network call, or just a developer who forgot to yield the program, caused the whole machine to lock up. There was no recourse for a misbehaving program either; reboot and hope you remembered to save.

Windows 3.1 by this time had shipped this mode of computing to millions. The phrase "Not Responding" became ingrained in the cultural vocabulary of computing. The breaking point of this cooperative system was third-party software. Microsoft couldn't verify that every program ran on Windows would cooperate and not freeze the system. The contract of this cooperative system was implicit, unenforceable, and was one bad actor away from bringing the whole thing to a screeching halt and upset users.

[Windows 95](https://en.wikipedia.org/wiki/Windows_95) (1995) introduced a new system architecture, one that did away with the cooperative task management system. Preemptive scheduling was the industry's answer to the trust problem. The OS would no longer rely on a process to yield when it could, it now forcibly parks a task mid-execution to start or resume processing on another. A process no longer needed to cooperate, it could run indefinitely and the rest of the system would carry on regardless.

The cooperative era ended not because the model was wrong, but because it had no mechanism to enforce the cooperative contract.

# The Preemptive Tradeoff

## How Preemption Actually Works

The OS sets a hardware timer, the **scheduler tick**, to fire at regular intervals; typically every 1-15 ms on modern systems. When it fires, the CPU is interrupted, control transfers to the kernel, which decides what to run next from its list of tasks. Notably not necessarily in the same order they were interrupted in. The logic that decides what task runs next is generally quite opaque to an observer of the system.

To swap processes, the OS performs a context switch, saving the entire CPU state of the outgoing process (registers, program counter, stack pointer) to memory, then restoring the saved state of the incoming process. Neither process has any knowledge this happened, the scheduling happens transparently to each application.

This scheduler tick defaults on Linux to 250Hz (every 4ms). Windows sits at ~64Hz (15.6ms) by default.

## What Context Switching Costs

The direct cost of this system is saving and restoring CPU registers. This process is fast, usually measured in nanoseconds. The indirect cost is *cache disruption*. Modern CPUs are fast because of layered caches (L1/L2/L3). When the scheduler swaps a process out, the incoming process's data isn't in cache; it has to be fetched from RAM. The cache cold start can cost hundreds of nanoseconds per switch, orders of magnitude more than the switch itself.

A heavily loaded system performing thousands of context switches per second can spend a meaningful percentage of CPU time just switching, not working.

## The Synchronization Problem

Because preemption can interrupt a process *at any time*, including mid-way through modifying shared data, concurrent programs need to protect shared state with lock primitives like mutexes and semaphores.

Locks introduce contention; if one process holds a lock, others waiting on that lock are stuck waiting. Under heavy workloads and constant contention this serializes what was supposed to be parallel work. Locks also introduce **deadlock** risk where two processes are each waiting on a lock the other holds, freezing both.

The field of concurrent and async programming exists largely to manage the hazards that preemption creates.

## Honest Counterpoint

Preemption solved a real problem, and completely. A misbehaving process can no longer freeze the system. Period.

Modern schedulers (Linux CFS, Windows HPET-based scheduler) are extraordinarily well tuned. The overhead, while real, is small enough that most software never notices it. The complexity that locks and synchronization bring are real, but tooling, languages, and runtimes have decades of investment in managing it.

Preemption was the right answer for a world where the OS couldn't trust its software. The question is whether that world is the only world worth designing for.

# The Yield Contract

The problem with historical implementations cooperative scheduling of the past can be answered with the Yield Contract.

## The Core

The problem with historical implementations of cooperative scheduling wasn't the model, it was the absence of any verifiable commitment. Programs were *expected* to yield but never *proven* to. A Yield Contract makes that commitment explicit, testable, and enforced. Any program who wants to run on this new OS declares its yield profile at install time; how long it expects to hold the CPU before yielding, under what conditions, and how frequently. This declaration is the contract.

A certification suite validates that declaration against the program's actual behavior. A program that claims to yield every 10ms gets tested to prove it. Pass, and this OS extends trust. The contract is signed.

## What the OS Gives In Return

Certified programs get scheduler privileges that uncertified programs don't. A video encoder that declares "I need 8 cycles before I yield for this operation" gets those 8 cycles, because it has proven it will yield afterward. The OS can plan around it; because the scheduler knows when every certified program intends to yield, it can construct an execution schedule with no wasted gaps. No preemptive interruptions mid-cache-hot execution, no forced context switches at arbitrary points, means the CPU stays cache warm for longer.

Context switching only happens at yield points. Yield points are known in advance. The scheduler becomes more like a choreographer than a traffic cop.

## What the Certification Suite Actually Tests

- Yield frequency: Does the program yield within its declared window under normal operation?
- Yield frequency under load: Does it still yield when doing heavy computation?
- Yield frequency under I/O: Does it yield while waiting on disk or network rather than spinning?
- Worst-case execution time: What is the longest the program has ever held the CPU in testing? This becomes the ceiling the OS plans around.
- Pass/fail: The program either upholds the contract or it doesn't.

## The Modern Precedent

These systems already exist in narrow forms. JavaScript's event loop is cooperative scheduling. The browser's JS runtime is single-threaded and cooperative; your code runs until it yields (returns or awaits), the next task runs. The entire async/await model is a form of yield contract.

`asyncio` in Python, `tokio` in Rust, Go's `goroutine` scheduler; all cooperative at the task level, sitting on top of a preemptive OS. The Yield Contract proposes moving the model down to the OS level, where the hardware efficiency gains actually live. `RTOS` (Real Time Operating Systems) like FreeRTOS offer cooperative scheduling modes for embedded systems where timing guarantees matter more than resilience to bad actors. The Yield Contract is this idea, formalized and brought to general-purpose computing.


Preemption says "We don't trust you, so we'll take control whenever we want". The Yield Contract says "Prove you can be trusted, and we'll never need to take control at all". In this new system, the OS doesn't eliminate enforcement, it moves the enforcement to install time rather than runtime. Catch the bad actor before it runs, not while it's running.

# When Contracts Break

The next question we have to ask is "What if someone breaks their contract"? With this there are two failure modes worth discussing, and those depend on the nature of the non-compliance.

- Malicious non-compliance: A program that intentionally never yields, trying to starve the system of CPU time. This is the historical cooperative failure mode.
- Accidental non-compliance: A certified program that hits an unexpected code path, an infinite loop from a bug, a deadlocked dependency, a network call that never returns. The program meant to yield, it simply isn't.

These are two different problems with different solutions, but the OS can't know which one it's looking at. It only knows that the contract is being violated. This is solved with an escalation model.

## The Escalation Model

As part of the cooperative task scheduling, the OS maintains a per-process execution cycle budget; derived from the program's declared yield profile at certification time. A video encoder that declared "8 cycles max" has a budget of 8 cycles. When a program exceeds its budget, the OS sends a **yield signal**, a soft interrupt the program should be able to handle. A well-written certified program catches this, finishes its current atomic operation, and yields gracefully. This is the first line of response.

If the program doesn't respond to the yield signal within a system-wide hard timeout (something like 1000ms; long enough to not false-positive on legitimate heavy work, short enough to keep the system responsive), the OS terminates the process. That is the key operator, termination, not preemption. The OS doesn't steal the CPU back and reschedule; the contract was broken, the warning wasn't heeded, the process is gone.

## Why Termination Instead of Preemption

Preemption keeps the bad process alive and running, just parked temporarily. It will run again and the problem will continue to occur. Termination is a permanent response to a permanent breach. The contract had become void, this frees the OS from ever needing a preemptive scheduler as a fallback. The safety button of the system is ejection, not takeover.

A crashed program is a recoverable system state. A preemptive interrupt of a cooperative program mid-execution could leave shared state corrupted; termination at a known-bad moment is cleaner than preemption at an arbitrary one. Whether the OS attempts a graceful shutdown before the hard kill is an open design question, but the principle holds either way.

## The Yield Signal as a Feature

High-priority certified programs can use the Yield Signal proactively. A video encoder near the end of a frame could listen for yield pressure from the OS and use it as a cue to wrap up; not because it's misbehaving, but because it's participating in the system's health. The Yield Signal becomes a communication channel between OS and program, not just a last warning before termination. 

This is the feature a Yield Signal provides, cooperation in both directions.


This lands nicely in user-space. A certified program that crashes due to contract breach is reported clearly, not a vague "Not Responding" but a breach event. The system stays up and other certified programs are unaffected. Uncertified programs that breach get the same treatment. There is no special leniency and no special punishment. Uncertified programs simply run without the privileges of trust.

Preemptive scheduling hijacks the CPU to keep order, the Yield Contract ends a process that breaches its contract.

# Multicore Without Locks

Cooperative scheduling on a single core is elegant; one program runs at a time, yields explicitly, the next program runs. No two programs ever touch the same memory simultaneously. Most systems today have multiple cores. Two certified cooperative programs running on separate cores can access the same memory at the same time. The scheduler doesn't help us here, we still need a way to synchronize between processes. This is the biggest piece that is in the way of our ideal OS.

The locks we are familiar with today, mutexes and semaphores, exist because preemption can interrupt a program anywhere, including in the middle of a write to shared memory. Programs need a way to lock that memory before writing so no other program reads or also attempts to write when the first process still has control. In a cooperative, single-core world, locks would never be needed. On multiple cores, even cooperative programs need to lock shared memory, this highlights the synchronization problem we took on with this new design.

We can solve this by changing what programs share. If a certified program is prohibited from sharing memory directly, if the concurrency model is ownership transfer rather than shared areas, locks become unnecessary regardless of core count. Instead of two programs reading and writing the same location in memory, one program owns a piece of data, does its work, then passes ownership to another. At no point do two programs have simultaneous access. This is the model that Erlang pioneered in the 1980s for telecom systems; isolated processes, message passing, no shared memory. Erlang systems are famous for their reliability because this model eliminates whole classes of concurrency bugs.

The Rust programming language also enforces a version of this ownership and borrowing model, enforcing it at compile time. The compiler rejects programs that would create simultaneous mutable access. This allows developers using Rust to access fearless concurrency, if the program compiles it runs. The Yield Contract in this case could make this a certification requirement; a program that passes certification has proven it plays by ownership rules.

What this means for the multicore Yield Contract OS is that each core owns its own cooperative scheduler; certified programs are isolated by ownership and don't share memory, they pass it; communication between programs happens through structured message passing, which the OS treats as a yield point — send a message, yield, recipient runs; and the certification suite validates ownership compliance alongside yield compliance. A program that shares memory directly fails certification.

This is where we have some real limitations, and it's best to be honest about them. Legacy software is built almost entirely around shared memory. Threads share a heap, global variables, shared caches. None of these existing programs would pass certification. This isn't a flaw in the OS-level ownership model, it's the honest cost for fearless concurrency system wide. We give up compatibility with existing software in exchange for concurrency that is demonstrably safer, and meaningfully faster and simpler.

This system has some real-world parallels that exist today. Web Workers in browsers use this exact model. Isolated JS contexts that communicate only through message passing, no shared memory by default. It's a system that works, not one that is theoretical. Go's design philosophy mirrors this as well: "Don't communicate by sharing memory; share memory by communicating." The Yield Contract OS makes this a hard, system-wide requirement and not just a cultural preference.

# The Uncertified World

The natural question at this point, given everything so far has described a system optimized for certified programs, is likely "what about all the software that already exists?" This is where this paper demonstrates that this OS is not a walled garden, but a spectrum.

The OS doesn't refuse to run uncertified software. It runs it, just without the privileges that come with certification. An uncertified program gets no extended cycle budgets. No scheduler trust. No ownership-based concurrency guarantees. Uncertified programs get a default, conservative execution budget; short enough to keep the system responsive, long enough to not be useless. A machine running only certified programs is the ideal, it allows the scheduler to become the choreographer, the cache to stay warm, waste no cycles, and have no lock contention.

A machine running a mix of certified and uncertified programs degrades gracefully. The certified programs still benefit from their contracts with each other. The uncertified programs introduce unpredictability, but only in proportion to how badly they behave. A machine running only uncertified programs looks roughly like a cooperative OS from 1992, functional but fragile. The user chose that by running only uncertified software. The system's quality is a direct reflection of the quality of the software running on it.

Uncertified programs are not allowed to claim extended CPU cycles; can't participate in ownership-based message passing; can't signal yield pressure to the OS proactively. Uncertified programs are guests without trust, not citizens with contracts.

This incentivizes developers to certify. Certified software runs better, gets scheduler privileges, and participates fully in the system. Users can see certification status, running an uncertified program must be a visible, explicit choice, not a hidden default. This ecosystem would naturally trend toward certification over time as the performance gap becomes more apparent.

This certification split in software is roughly how code signing works today on macOS and iOS. Unsigned apps can run but with reduced privileges and explicit user warnings. The Yield Contract is that idea applied to scheduling behavior rather than security provenance. The difference is that code signing is about identity and trust in the publisher. The Yield Contract is about behavior and trust in the program itself. You don't trust the developer, you trust the tested binary.

# A Proof of Concept

The preceding sections argued that an OS like this is sound; here we aim to describe the minimum viable product that proves it to be. My goal with this document and PoC is not to produce a product to ship. I do not aim to make a complete, stable OS. This design is by no means pressure tested. I aim to prove the principles around this system are coherent. A working demonstration that the Yield Contract model is not theoretical.

## Milestones

- M0: A bare-bones kernel that schedules yielding programs cooperatively on a single core. No preemptive fallback. No safety net beyond the yield signal and termination models described earlier. Two programs running side by side, both yielding explicitly, the scheduler moving between them only at yield points.
- M1: A suite of tests that takes a program binary and validates its yield behavior. Tests for yield frequency under normal operation, under load, and under I/O wait. Produces a pass/fail result and worst-case execution time ceiling.
- M2: A certified program and an uncertified program running simultaneously on the same kernel. The certified program gets its extended cycle budget and runs smoothly. The uncertified program runs on the default conservative budget. If the uncertified program breaches, either through a simulated loop or a hung call, it receives the yield signal, ignores it, and gets terminated. The certified program is unaffected.
- M3: Two certified programs running on separate cores, communicating exclusively through message passing and no shared memory. The message passing event is treated as a yield point by both schedulers. No locks anywhere in the demonstration.

Milestone 3 is the keystone of this paper. It would prove the ownership-based concurrency model works in practice, that the multicore problem is solvable without reintroducing locks, and that the cooperative scheduler can coordinate across cores through the message passing primitive alone. Everything before milestone 3 is groundwork, that milestone is the argument made visible.

## Success Indicators

A successful PoC produces a runnable, bare-bones native kernel implementing cooperative scheduling. A certification suite that produces verifiable pass/fail results. A demonstration of a certified and uncertified program running side by side, with breach and termination visible; Milestone 3 running cleanly, two cores, two certified programs, message passing as yield, no locks.

This PoC is again not a full OS. No filesystem, no display stack, no driver model. It is not a certification authority. It would simply prove the suite can exist, not that anyone governs it. This is also not a performance benchmark. The gains described in this paper require a full ecosystem of certified software to materialize, this PoC only proves the mechanism. An operating system that trusts the programs it runs, that is more efficient with its time and resources, and that has fearless, lock-free concurrency as a default, is something that I as an engineer would be proud to ship.

# Limitations

We've discussed the history of schedulers, weighed the pros and cons, and designed a system that tried to take back the speed and efficiency of cooperative scheduling, while preventing the system halting problems of the 1990s. This is where the design meets reality.

## 1. The Cold Start Problem
A new OS starts with zero certified software. The performance benefits of the Yield Contract model only materialize when the ecosystem around it is certified. On day one, everything runs as uncertified, and the system looks and feels like a cooperative OS from 1992. The incentive to certify would exist, but incentives take time to act on. The gap between "OS exists" and "enough certified software exists to feel the difference" is real and could be fatal to adoption. This is the same install base problem every new platform faces. It is not unique to this design, but it is not solved by it either.

## 2. The Certification Suite Needs a Maintainer
The certification suite is only as good as the tests in it. Someone has to write those tests, maintain them, update them as hardware changes, and decide what passes and what doesn't. That someone has a level of power over what software can be a first-class citizen on this OS. Governance of the suite is a harder problem than building it. A poorly governed suite becomes a gatekeeping mechanism. A well governed suite requires sustained institutional investment. This paper does not have an answer for who that should be.

## 3. Certified Programs Can Still Misbehave Through Bugs
Certification tests a program's behavior in the test environment. It cannot exhaustively cover every code path the program will encounter in production. A certified program that hits an untested edge case, a memory allocation that takes longer than expected, a dependency that deadlocks, an input that triggers an unexpected loop, will breach its contract not through malice but through incompleteness. The Yield Signal and termination model handles this, but termination of a certified program mid-task is still a bad user experience. The system stays up, but the task is gone. Certification certainly reduces the risk, but it does not eliminate it.

## 4. Legacy Software and the Shared Memory Assumption
The entire existing software ecosystem is built around shared memory. Porting legacy software to the ownership model is not a rewrite, it's a re-architecture. For most existing programs this is not a practical task. There is no clean migration story. Legacy software can run uncertified, permanently, unless someone rebuilds it from the ground up. A compatibility layer that lets legacy software run in a sandboxed uncertified context is possible, but it doesn't solve the problem, it simply contains it.

## 5. Hardware Assumptions
This design assumes the OS controls the scheduling at the hardware level. On virtualized environments, cloud VMs, containers, hypervisors, the host OS is doing its own preemptive scheduling underneath. The Yield Contract's timing guarantees evaporate when a hypervisor can pause the entire VM mid-yield. This is not a fatal flaw but is a real constraint. The Yield Contract OS is most coherent on bare metal.


These are real costs to this system, naming them honestly is part of the argument, not a concession against it.

# Conclusion

We started with cooperative scheduling, it was exceptionally fast but fragile. That fragility was answered with preemption, and with it came complexity that has compounded ever since. Preemption assumed software couldn't be trusted. The Yield Contract answers the same fragility in a different way, that software can prove itself and have verified trust. The complexity of modern concurrent programming is largely a consequence of preemption's assumption. This system isn't nostalgia for 1992, it's asking whether the problem preemption solved required the solution it got.