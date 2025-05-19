module datapath(input  logic        clk, reset,
                input  logic [1:0]  ResultSrc,
                input  logic        PCSrc, ALUSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [2:0]  ALUControl,
                output logic        Zero,
                output logic [31:0] PCF,
                input  logic [31:0] InstrF,
                output logic [31:0] ALUResultM, WriteDataM,
                input  logic [31:0] ReadDataM);


    // hazard wire
    logic resetDF;
    logic resetFE;
    logic resetEM;
    logic resetMW;
    //

    // Fetch
    logic [31:0] PCNextF;
    logic [31:0] PCTargetE;

    logic [31:0] PCPlus4F;
    logic [31:0] PCD, PCPlus4D;
    logic [31:0] PCE, PCPlus4E;

    logic [31:0] InstrD;

    // Decode
    logic [31:0] ImmExtD;
    logic [31:0] RD1D, RD2D;
    logic [4:0] RdD;

    logic [31:0] ResultW;


    logic [31:0] ImmExtE;
    logic [31:0] RD1E, RD2E;
    logic [4:0] RdE;

    // Execute
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] ALUResultE;
    logic [31:0] WriteDataE;

    logic [4:0] RdM;

    // Memory
    logic [31:0] PCPlus4M;

    logic [31:0] ALUResultW;
    logic [31:0] ReadDataW;
    logic [31:0] PCPlus4W;

    logic [4:0] RdW;



    // ------------------ Fetch ---------------------

    mux2  #(32) pcmux(PCPlus4F, PCTargetE, PCSrc, PCNextF);
    flopr #(32) pcreg(clk, reset, PCNextF, PCF);
    adder       pcadd4(PCF, 32'd4, PCPlus4F);

    flopr #(96) FetchDecode(clk, resetDF,
                             {InstrF, PCF, PCPlus4F},
                             {InstrD, PCD, PCPlus4D});

    // ------------------ Decode --------------------

    assign RdD = InstrD[11:7];

    regfile     rf(clk, RegWrite,
                   InstrD[19:15], InstrD[24:20], RdW,
                   ResultW,
                   RD1D, RD2D);

    extend      ext(InstrD[31:7], ImmSrc, ImmExtD);

    flopr #(165) DecodeExecute(clk, resetDE,
                               {RD1D, RD2D, PCD, RdD, ImmExtD, PCPlus4D},
                               {RD1E, RD2E, PCE, RdE, ImmExtE, PCPlus4E});

    // ------------------ Execute --------------------

    assign SrcAE = RD1E;

    alu         alu(SrcAE, SrcBE, ALUControl, ALUResultE, Zero);
    mux2 #(32)  srcbmux(RD2E, ImmExtE, ALUSrc, SrcBE);
    adder       pcaddbranch(PCE, ImmExtE, PCTargetE);

    assign WriteDataE = RD2E;

    flopr #(101) ExecuteMemory(clk, resetEM,
                              {ALUResultE, WriteDataE, RdE, PCPlus4E},
                              {ALUResultM, WriteDataM, RdM, PCPlus4M});


    // ------------------ Memory ----------------------

    flopr #(101) MemoryWriteback(clk, resetMW,
                                {ALUResultM, ReadDataM, RdM, PCPlus4M},
                                {ALUResultW, ReadDataW, RdW, PCPlus4W});


    // ------------------ Write-Back ------------------

    mux3 #(32)  resultmux(ALUResultW, ReadDataW, PCPlus4W, ResultSrc, ResultW);

endmodule