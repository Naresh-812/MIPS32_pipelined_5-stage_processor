# 🧠 MIPS32 5-Stage Pipelined Processor

This project implements a 5-stage pipelined MIPS32 processor in Verilog HDL, supporting Register-type (R-type), Immediate-type (I-type), and Jump-type (J-type) instructions. The processor adheres to the classic 5-stage MIPS pipeline architecture:

1. **IF** – Instruction Fetch
2. **ID** – Instruction Decode & Register Fetch
3. **EX** – Execute / Address Calculation
4. **MEM** – Memory Access
5. **WB** – Write Back

---

## 🔧 Features

* ✅ 32-bit instruction support (MIPS32 ISA)
* ✅ R-type, I-type, and J-type instruction execution
* ✅ Hazard detection and basic forwarding logic
* ✅ Pipeline register implementation between all stages
* ✅ Support for arithmetic, logic, memory, and branch instructions
* ✅ Parameterized instruction and data memory
* ✅ Synthesizable and testbench-verified

---


### R-Type:

* `add`, `sub`, `and`, `or`, `slt`

### I-Type:

* `addi`, `andi`, `ori`, `lw`, `sw`, `beq`, `bne`

### J-Type:

* `j`, `jal`

---
## 📌 Future Improvements

* Full forwarding unit to eliminate all stalls
* Branch prediction
* Exception/Interrupt handling
* Support for more instructions (e.g., shift, multiplication, division)

---



## 🙌 Acknowledgements

Special thanks to my mentors, academic resources, and MIPS documentation.

---

Let me know if you'd like this in PDF or DOCX format for additional documentation or college reports.
