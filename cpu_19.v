`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2025 04:56:58 PM
// Design Name: 
// Module Name: cpu_19
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Instruction Formats:
// R-type: [4-bit opcode][4-bit r1][4-bit r2][4-bit r3][3-bit unused]
// I-type: [4-bit opcode][4-bit r1][8-bit immediate][3-bit unused]
// J-type: [4-bit opcode][15-bit address]
// M-type: [4-bit opcode][4-bit r1][8-bit address][3-bit unused]

module cpu_19(reset,clk1,clk2,PC,ID_EX_A,ID_EX_B,ID_EX_IMM,EX_MEM_ALUOUT, EX_MEM_COND,MEM_WB_LMD,MEM_WB_ALUOUT);// to see the ouputs in testbench wave forms we menthioned here 
input reset,clk1,clk2;
reg [18:0] IF_ID_IR,IF_ID_NPC;
output reg [18:0] PC;     //IF-ID STAGE 
reg [18:0] ID_EX_IR,ID_EX_NPC;
output reg [18:0] ID_EX_A,ID_EX_B,ID_EX_IMM;      //ID_EX STAGE
reg [18:0]EX_MEM_IR,EX_MEM_B;
output reg [18:0]EX_MEM_ALUOUT;      //EX_MEM_STAGE
output reg EX_MEM_COND;  //CONDITIOM
reg [18:0] MEM_WB_IR;
output reg [18:0] MEM_WB_LMD,MEM_WB_ALUOUT;   //MEM-WB STAGE 
reg [2:0] ID_EX_TYPE,EX_MEM_TYPE,MEM_WB_TYPE;     //TYPE 


reg [18:0] Reg[0:15];    //reg 16*19  4 bitis for registers
reg [18:0] Mem[0:1023];     //memory 1024*32
reg [18:0] temp;
//we assign parameters to increase readability of code 
parameter  RR_ALU_OP=4'b0000,ADD=3'b000,SUB=3'b001,MUL=3'b010,DIV=3'b011, AND=3'b100,OR=3'b101,XOR=3'b110,
          INC=4'b0001,DEC=4'b0010,NOT=4'b0011,HLT=4'b0100,
           JUMP=4'b0101,BEQ=4'b0110,BNE=4'b0111,CALL=4'b1000,RET=4'b1010,
           LD=4'b1011,ST=4'b1100,FFT=4'b1101,ENC=4'b1110,DECR=4'b1111;
           
           
parameter RR_ALU=3'b000,RM_ALU=3'b001,LOAD=3'b010,STORE=3'b011,
          BRANCH=3'b100,HALT=3'b101,JUMP_TYPES=3'b110,CUSTOM=3'B111;
          
reg HALTED;
reg TAKEN_BRANCH;    //to stop the next instruction from getting executed after branch taken
reg TAKEN_JUMP;
integer i;
always@(posedge clk1 or posedge reset)  //if stage
if(HALTED==0)
begin
 if(reset)
 begin
 PC <= 0;
    IF_ID_IR <= 0;
    IF_ID_NPC <= 0;
    ID_EX_IR <= 0;
    EX_MEM_IR <= 0;
    MEM_WB_IR <= 0;
    HALTED <= 0;
    TAKEN_BRANCH <= 0;
    TAKEN_JUMP <= 0;
    for (i = 0; i < 16; i = i + 1)
        Reg[i] <= 0;
    Reg[15] <= 1023; // Initialize SP
    // Initialize SP to top of memory
  
 end
 else if(((EX_MEM_IR[18:15]==BEQ)&&(EX_MEM_COND==1))||
    ((EX_MEM_IR[18:15]==BNE)&&(EX_MEM_COND==0)))
 begin
   IF_ID_IR=Mem[EX_MEM_ALUOUT];
   TAKEN_BRANCH= 1'b1;
   IF_ID_NPC= EX_MEM_ALUOUT+1;
   PC=EX_MEM_ALUOUT+1;
 end
 else if(EX_MEM_IR[18:15] == JUMP)
    begin
    IF_ID_IR=Mem[ID_EX_IMM];
    IF_ID_NPC=Mem[ID_EX_IMM]+1;
    PC=Mem[ID_EX_IMM]+1;
    TAKEN_JUMP=1'b0;
    end
  else if (EX_MEM_IR[18:15] == CALL) 
     begin
     IF_ID_IR = Mem[EX_MEM_ALUOUT];
     IF_ID_NPC = EX_MEM_ALUOUT + 1;
     PC = EX_MEM_ALUOUT + 1;
     TAKEN_JUMP=1'b0;
     end
 else
 begin
 IF_ID_IR=Mem[PC];
 IF_ID_NPC= PC+1;
 PC = PC+1;
 end
end
 


always @(posedge clk2)  //ID stage
if(HALTED==0) 
 begin
   if(IF_ID_IR[14:11]==4'b0000)
    ID_EX_A <=0;
   else
   ID_EX_A <=  Reg[IF_ID_IR[14:11]];  //"rs"
   if(IF_ID_IR[10:7]==4'b0000)
    ID_EX_B<=0;
   else
    ID_EX_B <= Reg[IF_ID_IR[10:7]];
    ID_EX_NPC<= IF_ID_NPC;
    ID_EX_IR<=IF_ID_IR;
    ID_EX_IMM <= {{8{IF_ID_IR[10]}},{IF_ID_IR[10:0]}};
    case(IF_ID_IR[18:15])
     RR_ALU_OP:
        ID_EX_TYPE<= RR_ALU;
      LD:
        ID_EX_TYPE<= LOAD;
     ST:
        ID_EX_TYPE<= STORE;
     JUMP,CALL,RET:
     begin
       TAKEN_JUMP<=1;
       ID_EX_TYPE<=JUMP_TYPES;
     end
     BNE,BEQ:
        ID_EX_TYPE<=  BRANCH;
     FFT,ENC,DECR:
        ID_EX_TYPE<=CUSTOM;
     HLT:
       ID_EX_TYPE<= HALT;
      default:
        ID_EX_TYPE<=HALT;
      endcase
  end
   

always @(posedge clk1)  //EX-stage
if(HALTED==0 & TAKEN_JUMP==0)
 begin
   EX_MEM_TYPE<=  ID_EX_TYPE;
   EX_MEM_IR <=  ID_EX_IR;
   TAKEN_BRANCH<=  0;
   case(ID_EX_IR[18:15])
     RR_ALU_OP:
     begin
       case(ID_EX_IR[2:0])
       ADD:
         EX_MEM_ALUOUT <=  ID_EX_A+ID_EX_B;
       SUB:
         EX_MEM_ALUOUT <= ID_EX_A-ID_EX_B;
       MUL:
         EX_MEM_ALUOUT <=  ID_EX_A * ID_EX_B;
       DIV:
         EX_MEM_ALUOUT<=ID_EX_A/ID_EX_B;
       AND:
         EX_MEM_ALUOUT<=  ID_EX_A & ID_EX_B;
       OR:
         EX_MEM_ALUOUT <=  ID_EX_A | ID_EX_B;
       XOR:
          EX_MEM_ALUOUT <=  ID_EX_A ^ ID_EX_B;
       default:
         EX_MEM_ALUOUT <=  32'hxxxxxxxx;
       endcase
     end
   INC:
      EX_MEM_ALUOUT <=ID_EX_A +1;
   DEC:
    EX_MEM_ALUOUT <=  ID_EX_A-1;
   NOT:
      EX_MEM_ALUOUT <= ~(ID_EX_B);
   LD,ST:
   begin
    EX_MEM_ALUOUT <=  ID_EX_A+ ID_EX_IMM;
    EX_MEM_B <=  ID_EX_B;
   end
   BEQ,BNE:
   begin
     EX_MEM_ALUOUT <=  ID_EX_NPC+ID_EX_IMM;
     EX_MEM_COND <=  (ID_EX_A ==ID_EX_B);
   end
   CALL:
   begin
    EX_MEM_ALUOUT <= Reg[15] - 1;   // where to store return addr
    EX_MEM_B      <= ID_EX_NPC;     // return address (PC+1)
    TAKEN_BRANCH  <= 1'b1;
   end

   RET:
   begin
    EX_MEM_ALUOUT <= Reg[15] + 1;   // location of return addr
    TAKEN_BRANCH  <= 1'b1;
   end
    FFT:
     begin
                EX_MEM_TYPE <= STORE;  // Treat as store operation
                temp = Mem[ID_EX_B];
                EX_MEM_ALUOUT = {temp[7:0], temp[15:8]} + 16'h1234;
                EX_MEM_B = ID_EX_A; // Destination address
    end
            
    ENC:
     begin
                EX_MEM_TYPE <= STORE;
                EX_MEM_ALUOUT = Mem[ID_EX_B] ^ 16'hA5A5;
                EX_MEM_B = ID_EX_A;
            end
            
    DECR:
     begin
                EX_MEM_TYPE <= STORE;
                EX_MEM_ALUOUT = Mem[ID_EX_B] ^ 16'hA5A5;
                EX_MEM_B = ID_EX_A;
     end
       
//   FFT:
//   ENC:
//   DECR:
       
    
   
  endcase
 end


always @(posedge clk2)  //MEM

 begin
   MEM_WB_TYPE <=EX_MEM_TYPE;
   MEM_WB_IR = EX_MEM_IR;
   case(EX_MEM_TYPE)
     RR_ALU,CUSTOM:
       MEM_WB_ALUOUT<= EX_MEM_ALUOUT;
     LOAD:
     MEM_WB_LMD <=  Mem[EX_MEM_ALUOUT];
     STORE:
     if(TAKEN_BRANCH==0)
        Mem[EX_MEM_ALUOUT] <= EX_MEM_B;
     JUMP_TYPES:
     begin
        if (EX_MEM_IR[18:15] == CALL) begin
            Mem[EX_MEM_ALUOUT] <= EX_MEM_B; // push return address
        end
        else if (EX_MEM_IR[18:15] == RET) begin
            MEM_WB_LMD <= Mem[EX_MEM_ALUOUT]; // pop return address
        end
    end
   
    endcase
   
 end

always @(posedge clk1)
begin
 if(TAKEN_BRANCH==0)
 case(MEM_WB_TYPE)
   RR_ALU,CUSTOM:
     Reg[MEM_WB_IR[6:3]]<=  MEM_WB_ALUOUT;
   RM_ALU:
     Reg[MEM_WB_IR[10:7]]<=  MEM_WB_ALUOUT;
   LOAD:
     Reg[MEM_WB_IR[10:7]]<=  MEM_WB_LMD;
     
     JUMP_TYPES:
      begin
        if (MEM_WB_IR[18:15] == CALL) begin
            Reg[15] <= Reg[15] - 1; // update SP
            PC <= ID_EX_IMM;        // jump to subroutine
        end
        else if (MEM_WB_IR[18:15] == RET) begin
            Reg[15] <= Reg[15] + 1; // restore SP
            PC <= MEM_WB_LMD;       // jump back to return address
        end
    end
    endcase
end 

endmodule

