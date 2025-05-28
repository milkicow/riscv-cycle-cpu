module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump, JumpReg,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp,
               output logic       LUIOp);

    logic [12:0] controls;

    assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
            ResultSrc, Branch, ALUOp, Jump, JumpReg, LUIOp} = controls;

    always_comb
        case(op)
            // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_JumpReg_LUIOp
            7'b0000011: controls = 13'b1_00_1_0_01_0_00_0_0_0; // lw
            7'b0100011: controls = 13'b0_01_1_1_00_0_00_0_0_0; // sw
            7'b0110011: controls = 13'b1_xx_0_0_00_0_10_0_0_0; // R-type
            7'b0110111: controls = 13'b1_xx_1_0_00_0_00_0_0_1; // lui
            7'b1100011: controls = 13'b0_10_0_0_00_1_01_0_0_0; // beq, bne, blt, bge, bltu, bgeu
            7'b0010011: controls = 13'b1_00_1_0_00_0_10_0_0_0; // I-type ALU
            7'b1101111: controls = 13'b1_11_0_0_10_0_00_1_0_0; // jal
            7'b1100111: controls = 13'b1_11_0_0_10_0_00_1_1_0; // jalr
            default:    controls = 13'bx_xx_x_x_xx_x_xx_x_x_0;
        endcase

endmodule
