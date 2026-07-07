# the-cooperative-os

We ask a lot of our operating systems: browser tabs, documents, a video editor, and a music player, all running at once. Modern systems deliver this with preemptive scheduling, an architecture built on the assumption that software cannot be trusted.

This is an argument that the assumption is a path taken, not the only path. Cooperative scheduling was faster and simpler, and it was abandoned for one reason: it had no way to enforce its contract. This paper proposes restoring that trust with a verifiable one, the Yield Contract, and argues the efficiency we gave up was not the price of stability but the price of distrust.

It is not a product, not an OS you should install, and not an attempt to replace what runs your machine today. It is a thought experiment carried far enough to run: a demonstration that the trust problem which ended the cooperative era can be solved without preemption.

# Start Here

1. [The paper: The Cooperative OS](https://the-cooperative-os.project802.io/). The full argument: the history of multitasking, why we stopped trusting our software, and how a Yield Contract could let us trust it again. Read it as a typeset page that renders with no scripts and no runtime, or read the [source Markdown](./the-cooperative-os.md).
2. The proof of concept (planned). The smallest thing that demonstrates the Yield Contract is real: a cooperative kernel, a certification suite, and lock-free multicore message passing. See the paper's [Proof of Concept](./the-cooperative-os.md#a-proof-of-concept) section for the milestone ladder.

# Status

- Paper: complete.
- Proof of concept: not yet started. Milestone ladder defined in the paper.

# The Ideas, in Brief

Cooperative scheduling was fast and simple, but fragile: one program that never yielded could freeze the whole machine. Preemption fixed that fragility completely, and its assumption, that software can't be trusted, is the root of most of the complexity in modern concurrent programming.

The redesign answers the same fragility a different way:

- The Yield Contract. A program declares its yield profile at install time; a certification suite proves the declaration against real behavior. Trust is verified, not assumed.
- Enforcement at install time, not runtime. Catch the bad actor before it runs, not while it's running. The scheduler becomes a choreographer, not a traffic cop.
- Termination, not preemption. A program that breaches its contract and ignores the yield signal is ended, not parked to misbehave again. A crashed program is a recoverable state.
- Ownership, not shared memory. Concurrency is message passing and ownership transfer, so multicore needs no locks. Send a message, yield, the recipient runs.
- A spectrum, not a walled garden. Uncertified software still runs, just without the privileges of trust. The system's quality reflects the software running on it.

# The Keystone

The whole design rests on one move: **trust is verifiable**. A program proves it will yield, and the OS never needs to seize the CPU back. The proof of concept's Milestone 3 makes this visible, two certified programs on separate cores communicating through message passing alone, no locks anywhere.

That, running cleanly, is the entire argument made visible.

# Honesty on the hard parts

This is not a pitch, and the paper does not pretend the design is free. It treats its real limitations directly: the cold-start problem of an ecosystem with zero certified software, the governance burden of whoever maintains the certification suite, certified programs that still breach through bugs, the shared-memory assumption baked into all legacy software, and the hardware assumptions that evaporate under a hypervisor. See the paper's [Limitations](./the-cooperative-os.md#limitations) section. Naming these is part of the argument, not a concession against it.

# About

A personal exploration by Ethan Smith, 2026. One engineer's answer to a question worth asking: preemption solved a real problem, but did that problem require the solution it got?
