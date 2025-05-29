module datapath(input  logic        clk, reset,
                // Control Unit signals
                input  logic        RegWriteD,
                input  logic [1:0]  ResultSrcD,
                input  logic        MemWriteD,
                input  logic        JumpD,
                input  logic        JumpRegD,
                input  logic        BranchD,
                input  logic [3:0]  ALUControlD,
                input  logic        ALUSrcD,
                input  logic [1:0]  ImmSrcD,
                input  logic        InverseBrCondD,
                input  logic        LUIOpD,
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

    logic StallF, StallD, FlushE, FlushD;
    //

    // Fetch
    logic [31:0] PCNextF;
    logic [31:0] PCTargetE, PCTargetEImm, PCTargetEReg;

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
    logic [3:0] ALUControlE;

    // Execute
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] ALUResultE;
    logic [31:0] WriteDataE;

    logic [1:0] ForwardAE, ForwardBE;

    logic [4:0] RdM;

    logic RegWriteM;
    logic [1:0] ResultSrcM;
    logic JumpRegE;


    // Memory
    logic [31:0] PCPlus4M;

    logic [31:0] ALUResultW /* verilator public */;
    logic [31:0] ReadDataW;
    logic [31:0] PCPlus4W;

    logic [4:0] RdW /* verilator public */;

    logic       RegWriteW /* verilator public */;
    logic [1:0] ResultSrcW;

    // For cosimulation
    logic [31:0] InstrE, InstrM, InstrW /* verilator public */;
    logic [31:0] PCM, PCW /* verilator public */;
    logic MemWriteW /* verilator public */;
    logic [31:0] WriteDataW /* verilator public */;

    logic PCSrcE;
    logic ZeroE;

    logic InverseBrCondE;

    assign PCSrcE = BranchE & (ZeroE ^ InverseBrCondE) | JumpE;

    // assign in verilator on elf loading stage
    logic [31:0] startPC /* verilator public */;

    // ------------------ Fetch ---------------------

    mux2    #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);

    flopenr #(32) pcreg(clk, reset, !StallF, startPC, PCNextF, PCF);
    adder         pcadd4(PCF, 32'd4, PCPlus4F);

    flopenr #(96) FetchDecode(clk, FlushD, !StallD, 0,
                              {InstrF, PCF, PCPlus4F},
                              {InstrFController, PCD, PCPlus4D});

    // ------------------ Decode --------------------

    logic [31:0] InstrFController;
    logic multiInstrStall;
    igor_controller igor_controller(clk, InstrFController, InstrD, multiInstrStall);

    assign RdD = InstrD[11:7];

    assign Rs1D = LUIOpD ? 0 : InstrD[19:15];
    assign Rs2D = InstrD[24:20];


    regfile     regfile_inst(clk, RegWriteW,
                             Rs1D, Rs2D, RdW,
                             ResultW,
                             RD1D, RD2D);

    extend  ext(InstrD, ImmExtD);

    flopenr #(220) DecodeExecute(clk, FlushE, 1, 0,
            {RD1D, RD2D, PCD, RdD, ImmExtD, PCPlus4D,
            RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, Rs1D, Rs2D,
            InverseBrCondD, JumpRegD,
            InstrD},
            {RD1E, RD2E, PCE, RdE, ImmExtE, PCPlus4E,
            RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE, Rs1E, Rs2E,
            InverseBrCondE, JumpRegE,
            InstrE});

    // ------------------ Execute --------------------

    logic [31:0] predSrcBE;

    mux3 #(32)  srcaemux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAE);
    mux3 #(32)  predsrcbemux(RD2E, ResultW, ALUResultM, ForwardBE, predSrcBE);
    // assign SrcAE = RD1E;



    alu         alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);
    mux2 #(32)  srcbmux(predSrcBE, ImmExtE, ALUSrcE, SrcBE);
    adder       pcaddbranchimm(PCE, ImmExtE, PCTargetEImm);
    adder       pcaddbranchreg(RD1E, ImmExtE, PCTargetEReg);

    mux2 #(32)  jumpresult(PCTargetEImm, PCTargetEReg, JumpRegE, PCTargetE);

    assign WriteDataE = predSrcBE;

    flopenr #(169) ExecuteMemory(clk, reset, 1, 0,
                                 {ALUResultE, WriteDataE, RdE, PCPlus4E,
                                  RegWriteE, ResultSrcE, MemWriteE,
                                  InstrE, PCE},
                                 {ALUResultM, WriteDataM, RdM, PCPlus4M,
                                  RegWriteM, ResultSrcM, MemWriteM,
                                  InstrM, PCM});

    // ------------------ Memory ----------------------

    flopenr #(201) MemoryWriteback(clk, reset, 1, 0,
                                  {ALUResultM, ReadDataM, RdM, PCPlus4M, RegWriteM, ResultSrcM,
                                   InstrM, PCM, MemWriteM, WriteDataM},
                                  {ALUResultW, ReadDataW, RdW, PCPlus4W, RegWriteW, ResultSrcW,
                                  InstrW, PCW, MemWriteW, WriteDataW});


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
                  .StallF(StallF), .StallD(StallD), .FlushE(FlushE),
                  // Clear args
                  .PCSrcE(PCSrcE),
                  .FlushD(FlushD),
                  // MuitiInstrStall
                  .multiInstrStall(multiInstrStall));

endmodule
