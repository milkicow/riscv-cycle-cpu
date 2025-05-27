module hazard(// ByPasses args
              input  logic [4:0] Rs1E, Rs2E, RdM, RdW,
              input  logic       RegWriteM, RegWriteW,
              output logic [1:0] ForwardAE, ForwardBE,
              // Stall args
              input  logic [4:0] Rs1D, Rs2D, RdE,
              input  logic       ResultSrcE0,
              output logic       StallF, StallD, FlushE,
              // Clear args
              input  logic       PCSrcE,
              output logic       FlushD);

    bypass bypass1(.RsE(Rs1E), .RdM(RdM), .RdW(RdW),
                   .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                   .Forward(ForwardAE));

    bypass bypass2(.RsE(Rs2E), .RdM(RdM), .RdW(RdW),
                   .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                   .Forward(ForwardBE));

    logic lwStall;
    assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));

    assign StallF = lwStall;
    assign StallD = lwStall;

    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;

endmodule
