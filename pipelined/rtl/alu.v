module alu(input  logic [31:0] SrcA, SrcB,
           input  logic [2:0]  ALUControl,
           output logic [31:0] ALUResult,
           output logic        Zero);

    always_comb
        case(ALUControl)
            3'b000: ALUResult = SrcA + SrcB;
            3'b001: ALUResult = SrcA - SrcB;
            3'b010: ALUResult = SrcA & SrcB;
            3'b011: ALUResult = SrcA | SrcB;
            3'b101: ALUResult = (SrcA < SrcB) ? 1 : 0;
            default: ALUResult = 32'bx; // undefined operation
        endcase

    assign Zero = (ALUResult == 32'b0);

endmodule
