`timescale 1ns / 1ps

module cpu_19_tb;

reg reset, clk1, clk2;
wire [18:0] PC, ID_EX_A, ID_EX_B, ID_EX_IMM;
wire [18:0] EX_MEM_ALUOUT, MEM_WB_LMD, MEM_WB_ALUOUT;
wire EX_MEM_COND;

cpu_19 uut (
    .reset(reset), .clk1(clk1), .clk2(clk2),
    .PC(PC),
    .ID_EX_A(ID_EX_A), .ID_EX_B(ID_EX_B), .ID_EX_IMM(ID_EX_IMM),
    .EX_MEM_ALUOUT(EX_MEM_ALUOUT), .EX_MEM_COND(EX_MEM_COND),
    .MEM_WB_LMD(MEM_WB_LMD), .MEM_WB_ALUOUT(MEM_WB_ALUOUT)
);

// Clock generation
always #5 clk1 = ~clk1;  // 100 MHz
always #5 clk2 = ~clk2;

initial begin
    clk1 = 0; clk2 = 0;
    reset = 1;
    #10 reset = 0;

    // Initialize memory with test program
    // R1 = 5, R2 = 3, R3 = R1 + R2, R4 = R3 - R1, HALT
    uut.Mem[0] = {4'b1011, 4'b0001, 11'd5};  // LD R1, #5 (immediate load via mem)
    uut.Mem[1] = {4'b1011, 4'b0010, 8'd3, 3'b000};  // LD R2, #3
    //uut.Mem[2] = {4'b0000, 4'b0011, 4'b0001, 4'b0010, 3'b000}; // ADD R3, R1, R2
    //uut.Mem[3] = {4'b0000, 4'b0100, 4'b0011, 4'b0001, 3'b001}; // SUB R4, R3, R1
    uut.Mem[4] = {4'b0100, 15'd0}; // HLT

    // Also preload data memory for immediate LD
    uut.Mem[5] = 19'd5;
    uut.Mem[6] = 19'd3;

    // Run simulation for some time
    #200;

    // Display register results
    $display("R1 = %d", uut.Reg[1]);
    $display("R2 = %d", uut.Reg[2]);
    //$display("R3 = %d (should be 8)", uut.Reg[3]);
    //$display("R4 = %d (should be 3)", uut.Reg[4]);

    $stop;
end

endmodule
