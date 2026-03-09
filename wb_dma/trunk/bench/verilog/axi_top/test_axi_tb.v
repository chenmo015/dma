`timescale 1ns/1ps

module test_axi_tb;

`ifdef WAVES
initial begin
    $fsdbDumpfile("dma_axi4lite.fsdb");
    $fsdbDumpvars(0, test_axi_tb, "+all");
end
`endif

reg clk;
reg rst;

reg ack_cnt_clr;
reg [31:0] ack_cnt;

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

localparam CH_COUNT = 4;

// ------------------------------------------------------------
// AXI control port s0 <- CPU AXI-Lite master model
// ------------------------------------------------------------
wire [31:0] s0_axi_awaddr;
wire        s0_axi_awvalid;
wire        s0_axi_awready;
wire [31:0] s0_axi_wdata;
wire [3:0]  s0_axi_wstrb;
wire        s0_axi_wvalid;
wire        s0_axi_wready;
wire [1:0]  s0_axi_bresp;
wire        s0_axi_bvalid;
wire        s0_axi_bready;
wire [31:0] s0_axi_araddr;
wire        s0_axi_arvalid;
wire        s0_axi_arready;
wire [31:0] s0_axi_rdata;
wire [1:0]  s0_axi_rresp;
wire        s0_axi_rvalid;
wire        s0_axi_rready;

// keep control port s1 idle
reg  [31:0] s1_axi_awaddr;
reg         s1_axi_awvalid;
wire        s1_axi_awready;
reg  [31:0] s1_axi_wdata;
reg  [3:0]  s1_axi_wstrb;
reg         s1_axi_wvalid;
wire        s1_axi_wready;
wire [1:0]  s1_axi_bresp;
wire        s1_axi_bvalid;
reg         s1_axi_bready;
reg  [31:0] s1_axi_araddr;
reg         s1_axi_arvalid;
wire        s1_axi_arready;
wire [31:0] s1_axi_rdata;
wire [1:0]  s1_axi_rresp;
wire        s1_axi_rvalid;
reg         s1_axi_rready;

// ------------------------------------------------------------
// AXI data master ports from DMA -> connected to two memory models
// ------------------------------------------------------------
wire [31:0] m0_axi_awaddr;
wire        m0_axi_awvalid;
wire        m0_axi_awready;
wire [31:0] m0_axi_wdata;
wire [3:0]  m0_axi_wstrb;
wire        m0_axi_wvalid;
wire        m0_axi_wready;
wire [1:0]  m0_axi_bresp;
wire        m0_axi_bvalid;
wire        m0_axi_bready;
wire [31:0] m0_axi_araddr;
wire        m0_axi_arvalid;
wire        m0_axi_arready;
wire [31:0] m0_axi_rdata;
wire [1:0]  m0_axi_rresp;
wire        m0_axi_rvalid;
wire        m0_axi_rready;

wire [31:0] m1_axi_awaddr;
wire        m1_axi_awvalid;
wire        m1_axi_awready;
wire [31:0] m1_axi_wdata;
wire [3:0]  m1_axi_wstrb;
wire        m1_axi_wvalid;
wire        m1_axi_wready;
wire [1:0]  m1_axi_bresp;
wire        m1_axi_bvalid;
wire        m1_axi_bready;
wire [31:0] m1_axi_araddr;
wire        m1_axi_arvalid;
wire        m1_axi_arready;
wire [31:0] m1_axi_rdata;
wire [1:0]  m1_axi_rresp;
wire        m1_axi_rvalid;
wire        m1_axi_rready;

reg  [CH_COUNT-1:0] dma_req_i;
wire [CH_COUNT-1:0] dma_ack_o;
reg  [CH_COUNT-1:0] dma_nd_i;
reg  [CH_COUNT-1:0] dma_rest_i;
wire inta_o;
wire intb_o;

integer error_cnt;
integer mode;

// register offsets (same as legacy TB)
`define	MEM		32'h0002_0000
`define REG_BASE   32'hb000_0000

`define	COR		8'h0
`define INT_MASKA  8'h04
`define	INT_MASKB	8'h8
`define INT_SRCA   8'h0c
`define	INT_SRCB	8'h10

`define	CH0_CSR		8'h20
`define	CH0_TXSZ	8'h24
`define	CH0_ADR0	8'h28
`define CH0_AM0		8'h2c
`define	CH0_ADR1	8'h30
`define CH0_AM1		8'h34
`define	PTR0		8'h38

`define	CH1_CSR		8'h40
`define	CH1_TXSZ	8'h44
`define	CH1_ADR0	8'h48
`define CH1_AM0		8'h4c
`define	CH1_ADR1	8'h50
`define CH1_AM1		8'h54
`define	PTR1		8'h58

`define	CH2_CSR		8'h60
`define	CH2_TXSZ	8'h64
`define	CH2_ADR0	8'h68
`define CH2_AM0		8'h6c
`define	CH2_ADR1	8'h70
`define CH2_AM1		8'h74
`define	PTR2		8'h78

`define	CH3_CSR		8'h80
`define	CH3_TXSZ	8'h84
`define	CH3_ADR0	8'h88
`define CH3_AM0		8'h8c
`define	CH3_ADR1	8'h90
`define CH3_AM1		8'h94
`define	PTR3		8'h98

// CPU主机模型实例：对齐原版 wb_mast 的思路
axi_lite_mast_model m0 (
    .clk(clk), .rst(rst),
    .awaddr(s0_axi_awaddr), .awvalid(s0_axi_awvalid), .awready(s0_axi_awready),
    .wdata(s0_axi_wdata), .wstrb(s0_axi_wstrb), .wvalid(s0_axi_wvalid), .wready(s0_axi_wready),
    .bresp(s0_axi_bresp), .bvalid(s0_axi_bvalid), .bready(s0_axi_bready),
    .araddr(s0_axi_araddr), .arvalid(s0_axi_arvalid), .arready(s0_axi_arready),
    .rdata(s0_axi_rdata), .rresp(s0_axi_rresp), .rvalid(s0_axi_rvalid), .rready(s0_axi_rready)
);

// ------------------------------------------------------------
// DUT
// ------------------------------------------------------------
wb_dma_top_axi #(
    .rf_addr(4'hb),
    .pri_sel(2'd1),
    .ch_count(CH_COUNT),
    .ch0_conf(4'hf),
    .ch1_conf(4'hf),
    .ch2_conf(4'hf),
    .ch3_conf(4'hf)
) u_dma (
    .clk_i(clk),
    .rst_i(rst),

    .s0_axi_awaddr(s0_axi_awaddr), .s0_axi_awvalid(s0_axi_awvalid), .s0_axi_awready(s0_axi_awready),
    .s0_axi_wdata(s0_axi_wdata), .s0_axi_wstrb(s0_axi_wstrb), .s0_axi_wvalid(s0_axi_wvalid), .s0_axi_wready(s0_axi_wready),
    .s0_axi_bresp(s0_axi_bresp), .s0_axi_bvalid(s0_axi_bvalid), .s0_axi_bready(s0_axi_bready),
    .s0_axi_araddr(s0_axi_araddr), .s0_axi_arvalid(s0_axi_arvalid), .s0_axi_arready(s0_axi_arready),
    .s0_axi_rdata(s0_axi_rdata), .s0_axi_rresp(s0_axi_rresp), .s0_axi_rvalid(s0_axi_rvalid), .s0_axi_rready(s0_axi_rready),

    .m0_axi_awaddr(m0_axi_awaddr), .m0_axi_awvalid(m0_axi_awvalid), .m0_axi_awready(m0_axi_awready),
    .m0_axi_wdata(m0_axi_wdata), .m0_axi_wstrb(m0_axi_wstrb), .m0_axi_wvalid(m0_axi_wvalid), .m0_axi_wready(m0_axi_wready),
    .m0_axi_bresp(m0_axi_bresp), .m0_axi_bvalid(m0_axi_bvalid), .m0_axi_bready(m0_axi_bready),
    .m0_axi_araddr(m0_axi_araddr), .m0_axi_arvalid(m0_axi_arvalid), .m0_axi_arready(m0_axi_arready),
    .m0_axi_rdata(m0_axi_rdata), .m0_axi_rresp(m0_axi_rresp), .m0_axi_rvalid(m0_axi_rvalid), .m0_axi_rready(m0_axi_rready),

    .s1_axi_awaddr(s1_axi_awaddr), .s1_axi_awvalid(s1_axi_awvalid), .s1_axi_awready(s1_axi_awready),
    .s1_axi_wdata(s1_axi_wdata), .s1_axi_wstrb(s1_axi_wstrb), .s1_axi_wvalid(s1_axi_wvalid), .s1_axi_wready(s1_axi_wready),
    .s1_axi_bresp(s1_axi_bresp), .s1_axi_bvalid(s1_axi_bvalid), .s1_axi_bready(s1_axi_bready),
    .s1_axi_araddr(s1_axi_araddr), .s1_axi_arvalid(s1_axi_arvalid), .s1_axi_arready(s1_axi_arready),
    .s1_axi_rdata(s1_axi_rdata), .s1_axi_rresp(s1_axi_rresp), .s1_axi_rvalid(s1_axi_rvalid), .s1_axi_rready(s1_axi_rready),

    .m1_axi_awaddr(m1_axi_awaddr), .m1_axi_awvalid(m1_axi_awvalid), .m1_axi_awready(m1_axi_awready),
    .m1_axi_wdata(m1_axi_wdata), .m1_axi_wstrb(m1_axi_wstrb), .m1_axi_wvalid(m1_axi_wvalid), .m1_axi_wready(m1_axi_wready),
    .m1_axi_bresp(m1_axi_bresp), .m1_axi_bvalid(m1_axi_bvalid), .m1_axi_bready(m1_axi_bready),
    .m1_axi_araddr(m1_axi_araddr), .m1_axi_arvalid(m1_axi_arvalid), .m1_axi_arready(m1_axi_arready),
    .m1_axi_rdata(m1_axi_rdata), .m1_axi_rresp(m1_axi_rresp), .m1_axi_rvalid(m1_axi_rvalid), .m1_axi_rready(m1_axi_rready),

    .dma_req_i(dma_req_i), .dma_ack_o(dma_ack_o), .dma_nd_i(dma_nd_i), .dma_rest_i(dma_rest_i), .inta_o(inta_o), .intb_o(intb_o)
);

// ------------------------------------------------------------
// AXI-Lite memory models for data ports (对应原版两个 wb_slv)
// ------------------------------------------------------------
axi_lite_mem_model #(.AW(32), .DW(32), .DEPTH_WORDS(8192)) s0 (
    .clk(clk), .rst(rst),
    .s_axi_awaddr(m0_axi_awaddr), .s_axi_awvalid(m0_axi_awvalid), .s_axi_awready(m0_axi_awready),
    .s_axi_wdata(m0_axi_wdata), .s_axi_wstrb(m0_axi_wstrb), .s_axi_wvalid(m0_axi_wvalid), .s_axi_wready(m0_axi_wready),
    .s_axi_bresp(m0_axi_bresp), .s_axi_bvalid(m0_axi_bvalid), .s_axi_bready(m0_axi_bready),
    .s_axi_araddr(m0_axi_araddr), .s_axi_arvalid(m0_axi_arvalid), .s_axi_arready(m0_axi_arready),
    .s_axi_rdata(m0_axi_rdata), .s_axi_rresp(m0_axi_rresp), .s_axi_rvalid(m0_axi_rvalid), .s_axi_rready(m0_axi_rready)
);

axi_lite_mem_model #(.AW(32), .DW(32), .DEPTH_WORDS(8192)) s1 (
    .clk(clk), .rst(rst),
    .s_axi_awaddr(m1_axi_awaddr), .s_axi_awvalid(m1_axi_awvalid), .s_axi_awready(m1_axi_awready),
    .s_axi_wdata(m1_axi_wdata), .s_axi_wstrb(m1_axi_wstrb), .s_axi_wvalid(m1_axi_wvalid), .s_axi_wready(m1_axi_wready),
    .s_axi_bresp(m1_axi_bresp), .s_axi_bvalid(m1_axi_bvalid), .s_axi_bready(m1_axi_bready),
    .s_axi_araddr(m1_axi_araddr), .s_axi_arvalid(m1_axi_arvalid), .s_axi_arready(m1_axi_arready),
    .s_axi_rdata(m1_axi_rdata), .s_axi_rresp(m1_axi_rresp), .s_axi_rvalid(m1_axi_rvalid), .s_axi_rready(m1_axi_rready)
);

// 功能：按 mode(0..3) 跑单个模式（0->0/0->1/1->0/1->1），并做数据比对
// mode[1] 选择源端口，mode[0] 选择目标端口
reg [31:0]tb_int_src;
integer tb_k1, tb_k;
integer tb_lm0, tb_lm1, tb_lm2, tb_lm3;
integer tb_del;
reg [15:0]tb_chunk_sz;
integer tb_i;

initial begin
    error_cnt = 0;

    rst = 1'b1;
    dma_req_i = {CH_COUNT{1'b0}};
    dma_nd_i = {CH_COUNT{1'b0}};
    dma_rest_i = {CH_COUNT{1'b0}};
	
	ack_cnt = 0;
	ack_cnt_clr = 0;
	error_cnt = 0;

    // s1控制口保持空闲
    s1_axi_awaddr = 0; s1_axi_awvalid = 0; s1_axi_wdata = 0; s1_axi_wstrb = 0; s1_axi_wvalid = 0;
    s1_axi_bready = 0; s1_axi_araddr = 0; s1_axi_arvalid = 0; s1_axi_rready = 0;

    repeat(10) @(posedge clk);
    rst = 1'b0;
    repeat(10) @(posedge clk);

    $display("\n============================================");
    $display(" AXI top-level DMA mode regression started ");
    $display("============================================");

    // 依次执行四种模式
    sw_dma1(3);
    sw_dma2(3);
    hw_dma1(3);
    hw_dma2(3);
    hw_dma3(2);
    sw_ext_desc1(3);
    arb_test1;
    hw_dma4(3);

    if (error_cnt == 0)
        $display("\nPASS: wb_dma_top_axi_tb");
    else
        $display("\nFAIL: wb_dma_top_axi_tb errors=%0d", error_cnt);

    $finish;
end


always @(posedge clk)
	if(ack_cnt_clr)			ack_cnt <= #1 0;
	else
	if((m0_axi_bvalid & m0_axi_bready) | (m0_axi_rvalid & m0_axi_rready) | (m1_axi_bvalid & m1_axi_bready) | (m1_axi_rvalid & m1_axi_rready))	ack_cnt <= #1 ack_cnt + 1;

`include "axi_top/dma_axi_tests.v"
endmodule
