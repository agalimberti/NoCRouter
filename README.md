# NoCRouter - RTL Router Design in SystemVerilog

## Summary
We developed a Network-on-Chip interconnection module with a 2D mesh topology, enabling the connection of computing nodes either in a direct or indirect network.

The routers allocate data at flit granularity, implementing a wormhole switching architecture further optimized by the presence of multiple virtual channels per input, avoiding the Head of Line blocking issue and thus allowing an higher average throughput to the network.

Packet routing is driven by the Dimension Order Routing algorithm, independently computed by each router belonging to the mesh.

Flow control is implemented in the switching activity management, which is controlled by a per-router switch allocation unit, and uses the On/Off algorithm, easy to implement but efficient enough for a medium level of traffic in the network.

## Design and implementation

The Network-on-Chip router has been developed following a bottom-up approach, for easier testing purposes, as simple, lower-level modules were implemented and tested before moving on to higher-level modules.

A strong emphasis has been put on simplifying the connections between the submodules of the router, thus the *interface* construct provided by SystemVerilog has been widely adopted.  
This helps in decoupling the functional part of the modules from their I/O specification, making the connections and interactions between them easier to understand even from the source code.

For each virtual channel at each port, a single-bit error output is implemented to signal to the external environment the detection of errors (e.g., inconsistencies in the signals between allocators and input ports, or ill-formed packets).  
This allows verifying that the interconnection network works correctly, with respect to the most critical corner cases, also when deployed in a real-life scenario.

## Verification

The verification phase has not been approached from a complete functional testing point of view, as developing a complete testbench for the whole developed system would have required a disproportionate effort with respect to the desired quality level.  
Instead, testing properly chosen corner cases has been deemed enough for the verification purposes of this project, thus all the router submodule and the router and mesh modules are each tested in their own testbench module.

In particular, each testbench contains the module to be tested (DUT) and the necessary logic to both steer the input signals of the DUT and check its output signals, and verifies the correctness of the DUT output signals by checking them against the expected output values inside a scoreboard structure.

Testing of single modules and of multiple modules interacting with each other has been performed with a bottom-up approach, alongside the development phase, both by manually analyzing the VCD waveforms produced by simulations in the Vivado environment and by means of testbenches self-evaluating the results of the same simulations.  
All tests have been executed in the *Vivado HL WebPack 2016.4* IDE on Linux machines.

*For further information, refer to the [project documentation](https://github.com/agalimberti/NoCRouter/raw/master/doc/Project%20Documentation.pdf)*.

*The project was carried out by Andrea Galimberti ([@agalimberti](https://github.com/agalimberti)), Filippo Testa ([@f-testa](https://github.com/f-testa)) and Alberto Zeni ([@albertozeni](https://github.com/albertozeni)) in the Embedded Systems course at Politecnico di Milano, A.Y. 2016/2017.*
