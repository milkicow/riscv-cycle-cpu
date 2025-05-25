module hazard(input  logic [4:0] Rs1E, Rs2E, RdM, RdW,
              input  logic       RegWriteM, RegWriteW,
              output logic [1:0] ForwardAE, ForwardBE);

    bypass bypass1(.RsE(Rs1E), .RdM(RdM), .RdW(RdW),
                   .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                   .Forward(ForwardAE));

    bypass bypass2(.RsE(Rs2E), .RdM(RdM), .RdW(RdW),
                   .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                   .Forward(ForwardBE));

endmodule
