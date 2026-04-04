//
// bridge_interact.sv — Simple register file for interact menu
// Each 32-bit register at word offset maps directly to 8 bits of status[].
// Register 0 → status[7:0], Register 1 → status[15:8], etc.
//
`default_nettype none

module bridge_interact #(
    parameter NUM_REGS = 8
) (
    input         clk_74a,
    input         clk_sys,
    input  [31:0] bridge_addr,
    input         bridge_wr,
    input  [31:0] bridge_wr_data,
    input         bridge_rd,
    output [31:0] bridge_rd_data,
    output reg [127:0] status
);

reg [31:0] regs [0:NUM_REGS-1];

integer k;
initial for (k = 0; k < NUM_REGS; k = k + 1) regs[k] = 32'd0;

// Write: registered
always @(posedge clk_74a) begin
    if (bridge_wr && bridge_addr[7:2] < NUM_REGS[5:0])
        regs[bridge_addr[7:2]] <= bridge_wr_data;
end

// Read: COMBINATIONAL — Pocket expects data immediately on bridge_rd
assign bridge_rd_data = (bridge_addr[7:2] < NUM_REGS[5:0])
                        ? regs[bridge_addr[7:2]]
                        : 32'd0;

// Sync to clk_sys and pack into status[]
reg [31:0] regs_meta [0:NUM_REGS-1];
reg [31:0] regs_sys  [0:NUM_REGS-1];

integer j;
always @(posedge clk_sys) begin
    for (j = 0; j < NUM_REGS; j = j + 1) begin
        regs_meta[j] <= regs[j];
        regs_sys[j]  <= regs_meta[j];
    end
    status <= 128'd0;
    for (j = 0; j < NUM_REGS && j < 16; j = j + 1)
        status[j*8 +: 8] <= regs_sys[j][7:0];
end

endmodule

// Restore default nettype for other modules compiled after this one
`default_nettype wire
