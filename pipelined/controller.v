module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,

                  output logic       RegWriteD,
                  output logic [1:0] ResultSrcD,
                  output logic       MemWriteD,
                  output logic       JumpD,
                  output logic       BranchD,
                  output logic [2:0] ALUControlD,
                  output logic       ALUSrcD,
                  output logic [1:0] ImmSrcD);

    logic [1:0] ALUOp;

    maindec md(op, ResultSrcD, MemWriteD, BranchD,
               ALUSrcD, RegWriteD, JumpD, ImmSrcD, ALUOp);

    aludec ad(op[5], funct3, funct7b5, ALUOp, ALUControlD);

endmodule