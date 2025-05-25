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

    logic StallF, StallD, FlushE;
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

    logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E;
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

    logic [1:0] ForwardAE, ForwardBE;

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

    mux2    #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);
    flopenr #(32) pcreg(clk, reset, !StallF, startPC, PCNextF, PCF);
    adder         pcadd4(PCF, 32'd4, PCPlus4F);

    flopenr #(96) FetchDecode(clk, reset, !StallD, 0,
                              {InstrF, PCF, PCPlus4F},
                              {InstrD, PCD, PCPlus4D});

    // ------------------ Decode --------------------

    assign RdD = InstrD[11:7];

    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];

    regfile     regfile_inst(clk, RegWriteW,
                             InstrD[19:15], InstrD[24:20], RdW,
                             ResultW,
                             RD1D, RD2D);

    extend      ext(InstrD[31:7], ImmSrcD, ImmExtD);

    flopenr #(185) DecodeExecute(clk, FlushE, 1, 0,
            {RD1D, RD2D, PCD, RdD, ImmExtD, PCPlus4D,
            RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, Rs1D, Rs2D},
            {RD1E, RD2E, PCE, RdE, ImmExtE, PCPlus4E,
            RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE, Rs1E, Rs2E});

    // ------------------ Execute --------------------

    logic [31:0] predSrcBE;

    mux3 #(32)  srcaemux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAE);
    mux3 #(32)  predsrcbemux(RD2E, ResultW, ALUResultM, ForwardBE, predSrcBE);
    // assign SrcAE = RD1E;

    alu         alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);
    mux2 #(32)  srcbmux(predSrcBE, ImmExtE, ALUSrcE, SrcBE);
    adder       pcaddbranch(PCE, ImmExtE, PCTargetE);

    assign WriteDataE = predSrcBE;

    flopenr #(105) ExecuteMemory(clk, reset, 1, 0,
                                 {ALUResultE, WriteDataE, RdE, PCPlus4E,
                                  RegWriteE, ResultSrcE, MemWriteE},
                                 {ALUResultM, WriteDataM, RdM, PCPlus4M,
                                  RegWriteM, ResultSrcM, MemWriteM});

    // ------------------ Memory ----------------------

    flopenr #(104) MemoryWriteback(clk, reset, 1, 0,
                                  {ALUResultM, ReadDataM, RdM, PCPlus4M, RegWriteM, ResultSrcM},
                                  {ALUResultW, ReadDataW, RdW, PCPlus4W, RegWriteW, ResultSrcW});


    // ------------------ Write-Back ------------------

    mux3 #(32)  resultmux(ALUResultW, ReadDataW, PCPlus4W, ResultSrcW, ResultW);

    // ------------------ Hazard ----------------------

    hazard hazard(// ByPasses args
                  .Rs1E(Rs1E), .Rs2E(Rs2E),
                  .RdM(RdM), .RdW(RdW),
                  .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                  .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
                  // Stall args
                  .Rs1D(Rs1D), .Rs2D(Rs2D), .RdE(RdE),
                  .ResultSrcE0(ResultSrcE[0]),
                  .StallF(StallF), .StallD(StallD), .FlushE(FlushE)
                  );


endmodule
