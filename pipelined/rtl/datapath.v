module datapath(input  logic        clk, reset,
                // Control Unit signals
                input  logic        RegWriteD,
                input  logic [1:0]  ResultSrcD,
                input  logic        MemWriteD,
                input  logic        JumpD,
                input  logic        BranchD,
                input  logic [2:0]  ALUControlD,
                input  logic        ALUSrcD,
                input  logic [1:0]  ImmSrcD,
                // Memory
                output logic        MemWriteM,
                output logic [31:0] ALUResultM, WriteDataM,
                input  logic [31:0] ReadDataM,
                //
                input  logic [31:0] InstrF,
                output logic [31:0] PCF,
                output logic [31:0] InstrD);


    // hazard wire
    logic resetFD;
    logic resetDE;
    logic resetEM;
    logic resetMW;
    //

    // Fetch
    logic [31:0] PCNextF;
    logic [31:0] PCTargetE;

    logic [31:0] PCPlus4F;
    logic [31:0] PCD, PCPlus4D;
    logic [31:0] PCE, PCPlus4E;

    // Decode
    logic [31:0] ImmExtD;
    logic [31:0] RD1D, RD2D;
    logic [4:0] RdD;

    logic [31:0] ResultW;


    logic [31:0] ImmExtE;
    logic [31:0] RD1E, RD2E;
    logic [4:0] RdE;


    logic RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
    logic [1:0] ResultSrcE;
    logic [2:0] ALUControlE;

    // Execute
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] ALUResultE;
    logic [31:0] WriteDataE;

    logic [4:0] RdM;

    logic RegWriteM;
    logic [1:0] ResultSrcM;

    // Memory
    logic [31:0] PCPlus4M;

    logic [31:0] ALUResultW;
    logic [31:0] ReadDataW;
    logic [31:0] PCPlus4W;

    logic [4:0] RdW;

    logic       RegWriteW;
    logic [1:0] ResultSrcW;


    logic PCSrcE;
    logic ZeroE;

    assign PCSrcE = BranchE & ZeroE | JumpE;

    // assign in verilator on elf loading stage
    logic [31:0] startPC /* verilator public */;

    // ------------------ Fetch ---------------------

    mux2  #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);
    flopr #(32) pcreg(clk, reset, startPC, PCNextF, PCF);
    adder       pcadd4(PCF, 32'd4, PCPlus4F);

    flopr #(96) FetchDecode(clk, resetFD, 0,
                             {InstrF, PCF, PCPlus4F},
                             {InstrD, PCD, PCPlus4D});

    // ------------------ Decode --------------------

    assign RdD = InstrD[11:7];

    regfile     regfile_inst(clk, RegWriteW,
                             InstrD[19:15], InstrD[24:20], RdW,
                             ResultW,
                             RD1D, RD2D);

    extend      ext(InstrD[31:7], ImmSrcD, ImmExtD);

    flopr #(175) DecodeExecute(clk, resetDE, 0,
                               {RD1D, RD2D, PCD, RdD, ImmExtD, PCPlus4D,
                               RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD},
                               {RD1E, RD2E, PCE, RdE, ImmExtE, PCPlus4E,
                               RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE});

    // ------------------ Execute --------------------

    assign SrcAE = RD1E;

    alu         alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);
    mux2 #(32)  srcbmux(RD2E, ImmExtE, ALUSrcE, SrcBE);
    adder       pcaddbranch(PCE, ImmExtE, PCTargetE);

    assign WriteDataE = RD2E;

    flopr #(105) ExecuteMemory(clk, resetEM, 0,
                              {ALUResultE, WriteDataE, RdE, PCPlus4E,
                              RegWriteE, ResultSrcE, MemWriteE},
                              {ALUResultM, WriteDataM, RdM, PCPlus4M,
                              RegWriteM, ResultSrcM, MemWriteM});


    // ------------------ Memory ----------------------

    flopr #(104) MemoryWriteback(clk, resetMW, 0,
                                {ALUResultM, ReadDataM, RdM, PCPlus4M,
                                RegWriteM, ResultSrcM},
                                {ALUResultW, ReadDataW, RdW, PCPlus4W,
                                RegWriteW, ResultSrcW});


    // ------------------ Write-Back ------------------

    mux3 #(32)  resultmux(ALUResultW, ReadDataW, PCPlus4W, ResultSrcW, ResultW);

endmodule
