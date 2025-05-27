module riscvpipelined(input  logic        clk, reset,

                      output logic [31:0] PC,
                      input  logic [31:0] InstrF,

                      // Memory
                      output logic        MemWrite,
                      output logic [31:0] ALUResult, WriteData,
                      input  logic [31:0] ReadData);


    logic [6:0] op;
    logic [2:0] funct3;
    logic funct7b5;

    logic RegWriteD;
    logic [1:0] ResultSrcD, ImmSrcD;
    logic [3:0] ALUControlD;

    logic MemWriteD, JumpD, JumpRegD, BranchD, ALUSrcD;

    logic [31:0] InstrD;

    assign op = InstrD[6:0];
    assign funct3 = InstrD[14:12];
    assign funct7b5 = InstrD[30];

    logic InverseBrCondD;

    controller c(.op(op), .funct3(funct3), .funct7b5(funct7b5),

                .RegWriteD(RegWriteD),
                .ResultSrcD(ResultSrcD),
                .MemWriteD(MemWriteD),
                .JumpD(JumpD),
                .JumpRegD(JumpRegD),
                .BranchD(BranchD),
                .ALUControlD(ALUControlD),
                .ALUSrcD(ALUSrcD),
                .ImmSrcD(ImmSrcD),
                .InverseBrCondD(InverseBrCondD));

    datapath dp(.clk(clk), .reset(reset),
                // controller input signals
                .RegWriteD(RegWriteD),
                .ResultSrcD(ResultSrcD),
                .MemWriteD(MemWriteD),
                .JumpD(JumpD),
                .JumpRegD(JumpRegD),
                .BranchD(BranchD),
                .ALUControlD(ALUControlD),
                .ALUSrcD(ALUSrcD),
                .ImmSrcD(ImmSrcD),
                .InverseBrCondD(InverseBrCondD),
                // mem data
                .MemWriteM(MemWrite),
                .ALUResultM(ALUResult),
                .WriteDataM(WriteData),
                .ReadDataM(ReadData),
                //
                .InstrF(InstrF),
                .PCF(PC),
                .InstrD(InstrD));
endmodule
