`include "alucontrol.v"

module alu(input  logic [31:0] SrcA, SrcB,
           input  logic [3:0]  ALUControl,
           output logic [31:0] ALUResult,
           output logic        Zero);

    logic [4:0] shamt;
    assign shamt = SrcB[4:0];

    always_comb
        case(ALUControl)
            `ALU_ADD: ALUResult  = SrcA + SrcB;
            `ALU_SUB: ALUResult  = SrcA - SrcB;
            `ALU_AND: ALUResult  = SrcA & SrcB;
            `ALU_OR: ALUResult   = SrcA | SrcB;
            `ALU_LESS: ALUResult = (SrcA < SrcB) ? 1 : 0;
            `ALU_SLL: ALUResult = SrcA << shamt;
            `ALU_SRL: ALUResult = SrcA >> shamt;
            `ALU_SRA: ALUResult = $signed(SrcA) >>> shamt;
            default: begin
                $display("Unknown alu control command: %d", ALUControl);
                ALUResult = 32'bx; // undefined operation
            end
        endcase

    assign Zero = (ALUResult == 32'b0);

endmodule
