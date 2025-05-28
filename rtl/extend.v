`include "instr_opcodes.v"

module extend(input  logic [31:0] instr,
              output logic [31:0] immext);

    always @ (*) begin
        case(instr[6:0])
            // I−type
            `OPCODE_I_TYPE, `OPCODE_JALR, `OPCODE_LOAD:
                immext = {{20{instr[31]}}, instr[31:20]};
            // S−type (stores)
            `OPCODE_S_TYPE: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            // B−type (branches)
            `OPCODE_B_TYPE: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            // J−type (jal)
            `OPCODE_JAL: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            `OPCODE_LUI: immext = {instr[31:12], 12'b0};
            default: immext = 32'bx; // undefined
        endcase
    end
endmodule
