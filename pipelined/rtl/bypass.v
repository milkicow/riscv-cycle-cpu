module bypass(input  logic [4:0] RsE, RdM, RdW,
              input  logic       RegWriteM, RegWriteW,
              output logic [1:0] Forward);

    assign Forward = ((RsE != 0) && (RsE == RdM) && RegWriteM) ? 2'b10 :
                     ((RsE != 0) && (RsE == RdW) && RegWriteW) ? 2'b01 : 2'b00;

endmodule
