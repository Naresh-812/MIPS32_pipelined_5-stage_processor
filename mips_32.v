`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2025 12:02:48 AM
// Design Name: 
// Module Name: mips_32
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


module mips_32(clk1,clk2,PC,ID_EX_A,ID_EX_B,ID_EX_IMM,EX_MEM_ALUOUT, EX_MEM_COND,MEM_WB_LMD,MEM_WB_ALUOUT);
input clk1,clk2;
reg [31:0] IF_ID_IR,IF_ID_NPC;
output reg [31:0] PC;     //IF-ID STAGE 
reg [31:0] ID_EX_IR,ID_EX_NPC;
output reg [31:0] ID_EX_A,ID_EX_B,ID_EX_IMM;      //ID_EX STAGE
reg [31:0]EX_MEM_IR,EX_MEM_B;
output reg [31:0]EX_MEM_ALUOUT;      //EX_MEM_STAGE
output reg EX_MEM_COND;  //CONDITIOM
reg [31:0] MEM_WB_IR;
output reg [31:0] MEM_WB_LMD,MEM_WB_ALUOUT;   //MEM-WB STAGE 
reg [2:0] ID_EX_TYPE,EX_MEM_TYPE,MEM_WB_TYPE;     //TYPE 


reg [31:0] Reg[0:31];    //reg 32*32
reg [31:0] Mem[0:1024];     //memory 1024*32

//we assign parameters to increase readability of code 
parameter  ADD=6'b000000,SUB=6'b000001,AND=6'b000010,OR=6'b000011,
           SLT=6'b000100,MUL=6'b000101,HLT=6'b111111,LW=6'b001000,
           SW=6'b001001,ADDI=6'b001010,SUBI=6'b001011,SLTI=6'b001100,
           BEQZ=6'b001101,BNEQZ=6'b001110;
           
           
parameter RR_ALU=3'b000,RM_ALU=3'b001,LOAD=3'b010,STORE=3'b011,
          BRANCH=3'b100,HALT=3'b101;
          
reg HALTED;
reg TAKEN_BRANCH;    //to stop the next instruction from getting executed after branch taken


always@(posedge clk1)  //if stage
if(HALTED==0)
begin
 if(((EX_MEM_IR[31:26]==BEQZ)&&(EX_MEM_COND==0))||
    ((EX_MEM_IR[31:26]==BNEQZ)&&(EX_MEM_COND==0)))
 begin
   IF_ID_IR=Mem[EX_MEM_ALUOUT];
   TAKEN_BRANCH= 1'b1;
   IF_ID_NPC= EX_MEM_ALUOUT+1;
   PC=EX_MEM_ALUOUT+1;
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
   if(IF_ID_IR[25:21]==5'b00000)
    ID_EX_A <=0;
   else
   ID_EX_A <=  Reg[IF_ID_IR[25:21]];  //"rs"
   if(IF_ID_IR[20:16]==5'b00000)
    ID_EX_B<=0;
   else
    ID_EX_B <= Reg[IF_ID_IR[20:16]];
    ID_EX_NPC<= IF_ID_NPC;
    ID_EX_IR<=IF_ID_IR;
    ID_EX_IMM <= {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
    case(IF_ID_IR[31:26])
     ADD,SUB,AND,OR,SLT,MUL:
        ID_EX_TYPE<= RR_ALU;
     ADDI,SUBI,SLTI:
        ID_EX_TYPE<= RM_ALU;
     LW:
        ID_EX_TYPE<= LOAD;
     SW:
        ID_EX_TYPE<= STORE;
     BNEQZ,BEQZ:
        ID_EX_TYPE<=  BRANCH;
     HLT:
       ID_EX_TYPE<= HALT;
      default:
        ID_EX_TYPE<=  HALT;
      endcase
  end
   

always @(posedge clk1)  //EX-stage
 if(HALTED==0)
 begin
   EX_MEM_TYPE<=  ID_EX_TYPE;
   EX_MEM_IR <=  ID_EX_IR;
   TAKEN_BRANCH<=  0;
   case(ID_EX_TYPE)
     RR_ALU:
     begin
       case(ID_EX_IR[31:26])
       ADD:
         EX_MEM_ALUOUT <=  ID_EX_A+ID_EX_B;
       SUB:
         EX_MEM_ALUOUT <= ID_EX_A-ID_EX_B;
       AND:
         EX_MEM_ALUOUT<=  ID_EX_A & ID_EX_B;
       OR:
         EX_MEM_ALUOUT <=  ID_EX_A | ID_EX_B;
       SLT:
         EX_MEM_ALUOUT <=  ID_EX_A < ID_EX_B;
       MUL:
          EX_MEM_ALUOUT <=  ID_EX_A * ID_EX_B;
       default:
         EX_MEM_ALUOUT <=  32'hxxxxxxxx;
       endcase
     end
    RM_ALU:
    begin
      case(ID_EX_IR[31:26])
        ADDI:
          EX_MEM_ALUOUT <= ID_EX_A+ID_EX_IMM;
        SUBI:
          EX_MEM_ALUOUT <=  ID_EX_A-ID_EX_IMM;
        SLTI:
          EX_MEM_ALUOUT <=  ID_EX_A < ID_EX_IMM;
        default:
          EX_MEM_ALUOUT <=  32'hxxxxxxxx;
        endcase
    end
   LOAD,STORE:
   begin
    EX_MEM_ALUOUT <=  ID_EX_A+ ID_EX_IMM;
    EX_MEM_B <=  ID_EX_B;
   end
   BRANCH:
   begin
     EX_MEM_ALUOUT <=  ID_EX_NPC+ID_EX_IMM;
     EX_MEM_COND <=  (ID_EX_A ==0);
   end
  endcase
 end


always @(posedge clk2)  //MEM
if (HALTED==0)
 begin
   MEM_WB_TYPE <=EX_MEM_TYPE;
   MEM_WB_IR = EX_MEM_IR;
   case(EX_MEM_TYPE)
     RR_ALU,RM_ALU:
       MEM_WB_ALUOUT<= EX_MEM_ALUOUT;
     LOAD:
     MEM_WB_LMD <=  Mem[EX_MEM_ALUOUT];
     STORE:
     if(TAKEN_BRANCH==0)
        Mem[EX_MEM_ALUOUT] <= EX_MEM_B;
    endcase
   
 end

always @(posedge clk1)
begin
 if(TAKEN_BRANCH==0)
 case(MEM_WB_TYPE)
   RR_ALU:
     Reg[MEM_WB_IR[15:11]]<=  MEM_WB_ALUOUT;
   RM_ALU:
     Reg[MEM_WB_IR[20:16]]<=  MEM_WB_ALUOUT;
   LOAD:
     Reg[MEM_WB_IR[20:16]]<=  MEM_WB_LMD;
   HALT:
     HALTED<= 1'b1;
    endcase
end

endmodule
