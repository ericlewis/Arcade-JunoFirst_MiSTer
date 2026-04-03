//============================================================================
//  Juno First Arcade for Analogue Pocket
//  Copyright (C) 2026 Eric Lewis — GPL-3.0-or-later
//============================================================================
`default_nettype wire

module core_top (
input   wire            clk_74a, clk_74b,
inout   wire    [7:0]   cart_tran_bank2,  output wire cart_tran_bank2_dir,
inout   wire    [7:0]   cart_tran_bank3,  output wire cart_tran_bank3_dir,
inout   wire    [7:0]   cart_tran_bank1,  output wire cart_tran_bank1_dir,
inout   wire    [7:4]   cart_tran_bank0,  output wire cart_tran_bank0_dir,
inout   wire            cart_tran_pin30,  output wire cart_tran_pin30_dir,
output  wire            cart_pin30_pwroff_reset,
inout   wire            cart_tran_pin31,  output wire cart_tran_pin31_dir,
input   wire            port_ir_rx,       output wire port_ir_tx, port_ir_rx_disable,
inout   wire            port_tran_si,     output wire port_tran_si_dir,
inout   wire            port_tran_so,     output wire port_tran_so_dir,
inout   wire            port_tran_sck,    output wire port_tran_sck_dir,
inout   wire            port_tran_sd,     output wire port_tran_sd_dir,
output  wire [21:16] cram0_a, output wire cram0_clk, cram0_adv_n, cram0_cre, cram0_ce0_n, cram0_ce1_n, cram0_oe_n, cram0_we_n, cram0_ub_n, cram0_lb_n,
inout   wire [15:0]  cram0_dq, input wire cram0_wait,
output  wire [21:16] cram1_a, output wire cram1_clk, cram1_adv_n, cram1_cre, cram1_ce0_n, cram1_ce1_n, cram1_oe_n, cram1_we_n, cram1_ub_n, cram1_lb_n,
inout   wire [15:0]  cram1_dq, input wire cram1_wait,
output  wire [12:0] dram_a, output wire [1:0] dram_ba, dram_dqm,
inout   wire [15:0] dram_dq,
output  wire dram_clk, dram_cke, dram_ras_n, dram_cas_n, dram_we_n,
output  wire [16:0] sram_a, output wire sram_oe_n, sram_we_n, sram_ub_n, sram_lb_n,
inout   wire [15:0] sram_dq,
input   wire vblank,
output  wire dbg_tx, input wire dbg_rx, output wire user1, input wire user2,
inout   wire aux_sda, output wire aux_scl, output wire vpll_feed,
output  wire [23:0] video_rgb,
output  wire video_rgb_clock, video_rgb_clock_90, video_de, video_skip, video_vs, video_hs,
output  wire audio_mclk, audio_dac, audio_lrck, input wire audio_adc,
output  wire bridge_endian_little,
input   wire [31:0] bridge_addr, bridge_wr_data,
input   wire bridge_rd, bridge_wr,
output  reg  [31:0] bridge_rd_data,
input   wire [31:0] cont1_key, cont2_key, cont3_key, cont4_key,
input   wire [31:0] cont1_joy, cont2_joy, cont3_joy, cont4_joy,
input   wire [15:0] cont1_trig, cont2_trig, cont3_trig, cont4_trig
);

// Tie-offs
assign port_ir_tx=0; assign port_ir_rx_disable=1; assign bridge_endian_little=0;
assign cart_tran_bank3=8'hzz; assign cart_tran_bank3_dir=0;
assign cart_tran_bank2=8'hzz; assign cart_tran_bank2_dir=0;
assign cart_tran_bank1=8'hzz; assign cart_tran_bank1_dir=0;
assign cart_tran_bank0=4'hf;  assign cart_tran_bank0_dir=1;
assign cart_tran_pin30=0;     assign cart_tran_pin30_dir=1'bz;
assign cart_pin30_pwroff_reset=0;
assign cart_tran_pin31=1'bz;  assign cart_tran_pin31_dir=0;
assign port_tran_so=1'bz; assign port_tran_so_dir=0;
assign port_tran_si=1'bz; assign port_tran_si_dir=0;
assign port_tran_sck=1'bz; assign port_tran_sck_dir=0;
assign port_tran_sd=1'bz; assign port_tran_sd_dir=0;
assign cram0_a=0; assign cram0_dq={16{1'bZ}}; assign cram0_clk=0;
assign cram0_adv_n=1; assign cram0_cre=0; assign cram0_ce0_n=1; assign cram0_ce1_n=1;
assign cram0_oe_n=1; assign cram0_we_n=1; assign cram0_ub_n=1; assign cram0_lb_n=1;
assign cram1_a=0; assign cram1_dq={16{1'bZ}}; assign cram1_clk=0;
assign cram1_adv_n=1; assign cram1_cre=0; assign cram1_ce0_n=1; assign cram1_ce1_n=1;
assign cram1_oe_n=1; assign cram1_we_n=1; assign cram1_ub_n=1; assign cram1_lb_n=1;
assign dram_a=0; assign dram_ba=0; assign dram_dq={16{1'bZ}};
assign dram_dqm=0; assign dram_clk=0; assign dram_cke=0;
assign dram_ras_n=1; assign dram_cas_n=1; assign dram_we_n=1;
assign sram_a=0; assign sram_dq={16{1'bZ}};
assign sram_oe_n=1; assign sram_we_n=1; assign sram_ub_n=1; assign sram_lb_n=1;
assign dbg_tx=1'bZ; assign user1=1'bZ; assign aux_scl=1'bZ; assign vpll_feed=1'bZ;

// Bridge
wire [31:0] cmd_bridge_rd_data;
always @(*) begin
    casex(bridge_addr)
    32'hF8xxxxxx: bridge_rd_data <= cmd_bridge_rd_data;
    default:      bridge_rd_data <= 0;
    endcase
end

wire reset_n, pll_core_locked, pll_core_locked_s;
synch_3 s01(pll_core_locked, pll_core_locked_s, clk_74a);

wire dataslot_requestread, dataslot_requestwrite, dataslot_update, dataslot_allcomplete;
wire [15:0] dataslot_requestread_id, dataslot_requestwrite_id, dataslot_update_id;
wire [31:0] dataslot_requestwrite_size, dataslot_update_size;
wire [31:0] rtc_epoch_seconds, rtc_date_bcd, rtc_time_bcd;
wire rtc_valid, osnotify_inmenu;
wire savestate_start, savestate_load;
reg target_dataslot_read=0, target_dataslot_write=0, target_dataslot_getfile=0, target_dataslot_openfile=0;
wire target_dataslot_ack, target_dataslot_done;
wire [2:0] target_dataslot_err;
reg [15:0] target_dataslot_id;
reg [31:0] target_dataslot_slotoffset, target_dataslot_bridgeaddr, target_dataslot_length;
wire [31:0] target_buffer_param_struct, target_buffer_resp_struct;
wire [9:0] datatable_addr; wire datatable_wren; wire [31:0] datatable_data, datatable_q;

core_bridge_cmd icb(
    .clk(clk_74a), .reset_n(reset_n),
    .bridge_endian_little(bridge_endian_little),
    .bridge_addr(bridge_addr), .bridge_rd(bridge_rd), .bridge_rd_data(cmd_bridge_rd_data),
    .bridge_wr(bridge_wr), .bridge_wr_data(bridge_wr_data),
    .status_boot_done(pll_core_locked_s), .status_setup_done(pll_core_locked_s), .status_running(reset_n),
    .dataslot_requestread(dataslot_requestread), .dataslot_requestread_id(dataslot_requestread_id),
    .dataslot_requestread_ack(1'b1), .dataslot_requestread_ok(1'b1),
    .dataslot_requestwrite(dataslot_requestwrite), .dataslot_requestwrite_id(dataslot_requestwrite_id),
    .dataslot_requestwrite_size(dataslot_requestwrite_size),
    .dataslot_requestwrite_ack(1'b1), .dataslot_requestwrite_ok(1'b1),
    .dataslot_update(dataslot_update), .dataslot_update_id(dataslot_update_id), .dataslot_update_size(dataslot_update_size),
    .dataslot_allcomplete(dataslot_allcomplete),
    .rtc_epoch_seconds(rtc_epoch_seconds), .rtc_date_bcd(rtc_date_bcd), .rtc_time_bcd(rtc_time_bcd), .rtc_valid(rtc_valid),
    .savestate_supported(1'b0), .savestate_addr(0), .savestate_size(0), .savestate_maxloadsize(0),
    .savestate_start(savestate_start), .savestate_start_ack(0), .savestate_start_busy(0), .savestate_start_ok(0), .savestate_start_err(0),
    .savestate_load(savestate_load), .savestate_load_ack(0), .savestate_load_busy(0), .savestate_load_ok(0), .savestate_load_err(0),
    .osnotify_inmenu(osnotify_inmenu),
    .target_dataslot_read(target_dataslot_read), .target_dataslot_write(target_dataslot_write),
    .target_dataslot_getfile(target_dataslot_getfile), .target_dataslot_openfile(target_dataslot_openfile),
    .target_dataslot_ack(target_dataslot_ack), .target_dataslot_done(target_dataslot_done), .target_dataslot_err(target_dataslot_err),
    .target_dataslot_id(target_dataslot_id), .target_dataslot_slotoffset(target_dataslot_slotoffset),
    .target_dataslot_bridgeaddr(target_dataslot_bridgeaddr), .target_dataslot_length(target_dataslot_length),
    .target_buffer_param_struct(target_buffer_param_struct), .target_buffer_resp_struct(target_buffer_resp_struct),
    .datatable_addr(datatable_addr), .datatable_wren(datatable_wren), .datatable_data(datatable_data), .datatable_q(datatable_q)
);

always @(posedge clk_74a) begin
    target_dataslot_read <= 0; target_dataslot_write <= 0;
    target_dataslot_getfile <= 0; target_dataslot_openfile <= 0;
end

// Clocks
wire CLK_49M, clk_vid, clk_vid_90;
pll pll_inst(
    .refclk(clk_74a), .rst(1'b0),
    .outclk_0(CLK_49M), .outclk_1(clk_vid), .outclk_2(clk_vid_90),
    .locked(pll_core_locked),
    .reconfig_to_pll(64'd0), .reconfig_from_pll()
);

// Reset — held until ROM loading completes
reg [19:0] reset_cnt = 20'd300000;
wire reset = |reset_cnt | ioctl_download;
always @(posedge CLK_49M)
    if (ioctl_download)
        reset_cnt <= 20'd300000;
    else if (reset_cnt)
        reset_cnt <= reset_cnt - 1'd1;

// ROM loading via data_loader — all ROMs concatenated at 0x0xxxxxxx
wire        rom_dl_wr;
wire [27:0] rom_dl_addr;
wire  [7:0] rom_dl_data;

data_loader #(.ADDRESS_MASK_UPPER_4(4'h2), .ADDRESS_SIZE(28)) rom_loader (
    .clk_74a(clk_74a), .clk_memory(CLK_49M),
    .bridge_wr(bridge_wr), .bridge_endian_little(bridge_endian_little),
    .bridge_addr(bridge_addr), .bridge_wr_data(bridge_wr_data),
    .write_en(rom_dl_wr), .write_addr(rom_dl_addr), .write_data(rom_dl_data)
);

reg ioctl_download = 0;
reg dl_downloading = 0;
reg dl_s0, dl_s1;
always @(posedge clk_74a) begin
    if (dataslot_requestwrite) dl_downloading <= 1;
    if (dataslot_allcomplete)  dl_downloading <= 0;
end
always @(posedge CLK_49M) begin
    dl_s0 <= dl_downloading; dl_s1 <= dl_s0;
    ioctl_download <= dl_s1;
end

wire        ioctl_wr    = rom_dl_wr;
wire  [7:0] ioctl_data  = rom_dl_data;
// Index and relative address based on absolute offset in concatenated ROM:
// 0x00000-0x17FFF = index 0 (96KB main CPU), addr relative
// 0x18000-0x18FFF = index 1 (4KB Z80 sound), addr = offset - 0x18000
// 0x19000-0x19FFF = index 2 (4KB i8039 MCU), addr = offset - 0x19000
wire  [7:0] ioctl_index = (rom_dl_addr < 28'h18000) ? 8'd0 :
                           (rom_dl_addr < 28'h19000) ? 8'd1 : 8'd2;
wire [24:0] ioctl_addr  = (rom_dl_addr < 28'h18000) ? rom_dl_addr[24:0] :
                           (rom_dl_addr < 28'h19000) ? rom_dl_addr[24:0] - 25'h18000 :
                                                        rom_dl_addr[24:0] - 25'h19000;

// Juno First core
wire signed [15:0] snd;
wire [4:0] r_out, g_out, b_out;
wire       hs_core, vs_core, hblank_core, vblank_core, ce_pix_core;

JunoFirst JF_inst (
    .reset          (~reset),
    .clk_49m        (CLK_49M),
    .coin           ({1'b1, ~cont1_key[14]}),   // Select = coin
    .start_buttons  ({~cont1_key[7], ~cont1_key[15]}), // Start=1P, Y=2P
    .p1_joystick    ({~cont1_key[3], ~cont1_key[2], ~cont1_key[1], ~cont1_key[0]}),
    .p2_joystick    ({~cont2_key[3], ~cont2_key[2], ~cont2_key[1], ~cont2_key[0]}),
    .p1_fire        (~cont1_key[4]),  // A
    .p2_fire        (~cont2_key[4]),
    .p1_warp        (~cont1_key[5]),  // B
    .p2_warp        (~cont2_key[5]),
    .btn_service    (1'b1),         // active low
    .dip_sw         (16'h73FF),     // DSW2=0x73 (3 lives, demo sounds on), DSW1=0xFF (1c/1cr)
    .h_center       (4'd0),
    .v_center       (4'd0),
    .video_hsync    (hs_core),
    .video_vsync    (vs_core),
    .video_vblank   (vblank_core),
    .video_hblank   (hblank_core),
    .ce_pix         (ce_pix_core),
    .video_r        (r_out),
    .video_g        (g_out),
    .video_b        (b_out),
    .sound          (snd),
    .ioctl_addr     (ioctl_addr),
    .ioctl_wr       (ioctl_wr & ioctl_download),
    .ioctl_data     (ioctl_data),
    .ioctl_index    (ioctl_index),
    .pause          (1'b0),
    .underclock     (1'b0),
    .hs_address     (),
    .hs_data_out    (),
    .hs_data_in     (8'd0),
    .hs_write       (1'b0)
);

// Color adjustment (from MiSTer Arcade-JunoFirst.sv)
wire [7:0] r = (r_out[0]?8'h19:0) + (r_out[1]?8'h24:0) + (r_out[2]?8'h35:0) + (r_out[3]?8'h40:0) + (r_out[4]?8'h4D:0);
wire [7:0] g = (g_out[0]?8'h19:0) + (g_out[1]?8'h24:0) + (g_out[2]?8'h35:0) + (g_out[3]?8'h40:0) + (g_out[4]?8'h4D:0);
wire [7:0] b = (b_out[0]?8'h19:0) + (b_out[1]?8'h24:0) + (b_out[2]?8'h35:0) + (b_out[3]?8'h40:0) + (b_out[4]?8'h4D:0);

// Video output at pixel clock
assign video_rgb_clock    = clk_vid;
assign video_rgb_clock_90 = clk_vid_90;
assign video_skip = 1'b0;

reg [7:0] vid_r, vid_g, vid_b;
reg       vid_hs, vid_vs, vid_de;
always @(posedge clk_vid) begin
    vid_r  <= r;
    vid_g  <= g;
    vid_b  <= b;
    vid_hs <= ~hs_core;
    vid_vs <= ~vs_core;
    vid_de <= ~hblank_core & ~vblank_core;
end

assign video_rgb = vid_de ? {vid_r, vid_g, vid_b} : 24'd0;
assign video_de  = vid_de;
assign video_vs  = vid_vs;
assign video_hs  = vid_hs;

// Audio via agg23 sound_i2s (proper CDC + I2S generation)
sound_i2s #(.CHANNEL_WIDTH(16), .SIGNED_INPUT(1)) sound_i2s_inst (
    .clk_74a   (clk_74a),
    .clk_audio (CLK_49M),
    .audio_l   (snd),
    .audio_r   (snd),
    .audio_mclk(audio_mclk),
    .audio_lrck(audio_lrck),
    .audio_dac (audio_dac)
);

endmodule
