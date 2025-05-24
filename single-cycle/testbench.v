module testbench();
    logic clk;
    logic reset;
    logic [31:0] WriteData, DataAdr;
    logic MemWrite;


    // instantiate device to be tested
    top dut(clk, reset, WriteData, DataAdr, MemWrite);
    // initialize test
    initial begin
            reset <= 1; # 22; reset <= 0;
    end

    // generate clock to sequence tests
    always begin
            clk <= 1; # 5; clk <= 0; # 5;
    end
    // check results
    always @(negedge clk) begin
        if(MemWrite) begin
            if(DataAdr === 100 & WriteData === 25) begin
                $display("Simulation succeeded");
                $stop;
            end else if (DataAdr !== 96) begin
                $display("Simulation failed (Unexpected write: DataAddr=%0d, WriteData=%0d)", DataAdr, WriteData);
                $stop;
            end
        end
    end

    initial begin
        $dumpvars;
        $display("Test started...");
        #10000 $finish;
    end


endmodule
