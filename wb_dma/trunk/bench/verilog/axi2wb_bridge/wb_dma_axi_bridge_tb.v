`timescale 1ns/1ps

module wb_dma_axi_bridge_tb;

`ifdef WAVES
initial begin
    $fsdbDumpfile("axi2wb.fsdb");
    $fsdbDumpvars(0, wb_dma_axi_bridge_tb, "+all");
end
`endif

reg clk;
reg rst;

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

integer error_cnt; // 自检错误计数

// ------------------------------------------------------------
// DUT #1 : axi4lite_slave_to_wb_master
// 用于验证“AXI-Lite从机访问 -> Wishbone主机访问”转换是否正确
// ------------------------------------------------------------
reg  [31:0] s_awaddr;
reg         s_awvalid;
wire        s_awready;
reg  [31:0] s_wdata;
reg  [3:0]  s_wstrb;
reg         s_wvalid;
wire        s_wready;
wire [1:0]  s_bresp;
wire        s_bvalid;
reg         s_bready;
reg  [31:0] s_araddr;
reg         s_arvalid;
wire        s_arready;
wire [31:0] s_rdata;
wire [1:0]  s_rresp;
wire        s_rvalid;
reg         s_rready;

wire [31:0] wbm_addr;
wire [31:0] wbm_data_o;
reg  [31:0] wbm_data_i;
wire [3:0]  wbm_sel;
wire        wbm_we;
wire        wbm_cyc;
wire        wbm_stb;
reg         wbm_ack;
reg         wbm_err;
reg         wbm_rty;

axi4lite_slave_to_wb_master u_s2w (
    .clk(clk), .rst(rst),
    .s_axi_awaddr(s_awaddr), .s_axi_awvalid(s_awvalid), .s_axi_awready(s_awready),
    .s_axi_wdata(s_wdata), .s_axi_wstrb(s_wstrb), .s_axi_wvalid(s_wvalid), .s_axi_wready(s_wready),
    .s_axi_bresp(s_bresp), .s_axi_bvalid(s_bvalid), .s_axi_bready(s_bready),
    .s_axi_araddr(s_araddr), .s_axi_arvalid(s_arvalid), .s_axi_arready(s_arready),
    .s_axi_rdata(s_rdata), .s_axi_rresp(s_rresp), .s_axi_rvalid(s_rvalid), .s_axi_rready(s_rready),
    .wb_addr_o(wbm_addr), .wb_data_o(wbm_data_o), .wb_data_i(wbm_data_i), .wb_sel_o(wbm_sel),
    .wb_we_o(wbm_we), .wb_cyc_o(wbm_cyc), .wb_stb_o(wbm_stb), .wb_ack_i(wbm_ack), .wb_err_i(wbm_err), .wb_rty_i(wbm_rty)
);

// ------------------------------------------------------------
// DUT #2 : wb_master_to_axi4lite_master
// 用于验证“Wishbone请求 -> AXI-Lite主机访问”转换是否正确
// ------------------------------------------------------------
reg  [31:0] wbs_addr;
reg  [31:0] wbs_data_i;
wire [31:0] wbs_data_o;
reg  [3:0]  wbs_sel;
reg         wbs_we;
reg         wbs_cyc;
reg         wbs_stb;
wire        wbs_ack;
wire        wbs_err;
wire        wbs_rty;

wire [31:0] m_awaddr;
wire        m_awvalid;
reg         m_awready;
wire [31:0] m_wdata;
wire [3:0]  m_wstrb;
wire        m_wvalid;
reg         m_wready;
reg  [1:0]  m_bresp;
reg         m_bvalid;
wire        m_bready;
wire [31:0] m_araddr;
wire        m_arvalid;
reg         m_arready;
reg  [31:0] m_rdata;
reg  [1:0]  m_rresp;
reg         m_rvalid;
wire        m_rready;

wb_master_to_axi4lite_master u_w2m (
    .clk(clk), .rst(rst),
    .wb_addr_i(wbs_addr), .wb_data_i(wbs_data_i), .wb_data_o(wbs_data_o), .wb_sel_i(wbs_sel),
    .wb_we_i(wbs_we), .wb_cyc_i(wbs_cyc), .wb_stb_i(wbs_stb), .wb_ack_o(wbs_ack), .wb_err_o(wbs_err), .wb_rty_o(wbs_rty),
    .m_axi_awaddr(m_awaddr), .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready),
    .m_axi_wdata(m_wdata), .m_axi_wstrb(m_wstrb), .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
    .m_axi_bresp(m_bresp), .m_axi_bvalid(m_bvalid), .m_axi_bready(m_bready),
    .m_axi_araddr(m_araddr), .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready),
    .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp), .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready)
);


task report;
    input cond;
    input [1023:0] msg;
    begin
        if (!cond) begin
            $display("ERROR: %0s @%0t", msg, $time);
            error_cnt = error_cnt + 1;
        end
    end
endtask

initial begin
    error_cnt = 0;

    // 全局初始化
    rst = 1'b1;

    s_awaddr  = 32'h0; s_awvalid = 1'b0;
    s_wdata   = 32'h0; s_wstrb   = 4'h0; s_wvalid = 1'b0;
    s_bready  = 1'b0;
    s_araddr  = 32'h0; s_arvalid = 1'b0;
    s_rready  = 1'b0;

    wbm_data_i = 32'h0;
    wbm_ack = 1'b0; wbm_err = 1'b0; wbm_rty = 1'b0;

    wbs_addr = 32'h0; wbs_data_i = 32'h0; wbs_sel = 4'h0;
    wbs_we = 1'b0; wbs_cyc = 1'b0; wbs_stb = 1'b0;

    m_awready = 1'b0; m_wready = 1'b0;
    m_bresp = 2'b00; m_bvalid = 1'b0;
    m_arready = 1'b0;
    m_rdata = 32'h0; m_rresp = 2'b00; m_rvalid = 1'b0;

    repeat (5) @(posedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // --------------------------------------------------------
    // Test 1: AXI-Lite write -> Wishbone write
    // --------------------------------------------------------
    s_awaddr  <= 32'h1000_0010;
    s_wdata   <= 32'hA5A5_55AA;
    s_wstrb   <= 4'hF;
    s_awvalid <= 1'b1;
    s_wvalid  <= 1'b1;
    while (!(s_awready && s_wready)) @(posedge clk);
    @(posedge clk);
    s_awvalid <= 1'b0;
    s_wvalid  <= 1'b0;

    repeat (2) @(posedge clk);
    report(wbm_cyc && wbm_stb && wbm_we, "s2w should issue WB write cycle");
    report(wbm_addr == 32'h1000_0010, "s2w WB write address mismatch");
    report(wbm_data_o == 32'hA5A5_55AA, "s2w WB write data mismatch");

    wbm_ack <= 1'b1;
    @(posedge clk);
    wbm_ack <= 1'b0;

    repeat (1) @(posedge clk);
    report(s_bvalid, "s2w should return AXI BVALID");
    report(s_bresp == 2'b00, "s2w write response should be OKAY");

    s_bready <= 1'b1;
    @(posedge clk);
    s_bready <= 1'b0;

    // --------------------------------------------------------
    // Test 2: AXI-Lite read -> Wishbone read
    // --------------------------------------------------------
    s_araddr  <= 32'h1000_0020;
    s_arvalid <= 1'b1;
    while (!s_arready) @(posedge clk);
    @(posedge clk);
    s_arvalid <= 1'b0;

    repeat (2) @(posedge clk);
    report(wbm_cyc && wbm_stb && !wbm_we, "s2w should issue WB read cycle");
    report(wbm_addr == 32'h1000_0020, "s2w WB read address mismatch");

    wbm_data_i <= 32'hDEAD_BEEF;
    wbm_ack    <= 1'b1;
    @(posedge clk);
    wbm_ack    <= 1'b0;

    repeat (1) @(posedge clk);
    report(s_rvalid, "s2w should return AXI RVALID");
    report(s_rdata == 32'hDEAD_BEEF, "s2w AXI read data mismatch");
    report(s_rresp == 2'b00, "s2w read response should be OKAY");

    s_rready <= 1'b1;
    @(posedge clk);
    s_rready <= 1'b0;

    // --------------------------------------------------------
    // Test 3: Wishbone write -> AXI-Lite write
    // --------------------------------------------------------
    wbs_addr   <= 32'h2000_0040;
    wbs_data_i <= 32'h1122_3344;
    wbs_sel    <= 4'hF;
    wbs_we     <= 1'b1;
    wbs_cyc    <= 1'b1;
    wbs_stb    <= 1'b1;

    repeat (2) @(posedge clk);
    report(m_awvalid && m_wvalid, "w2m should drive AXI AWVALID/WVALID");
    report(m_awaddr == 32'h2000_0040, "w2m AWADDR mismatch");
    report(m_wdata == 32'h1122_3344, "w2m WDATA mismatch");

    @(posedge clk);
    m_awready <= 1'b1;
    m_wready  <= 1'b1;
    @(posedge clk);
    m_awready <= 1'b0;
    m_wready  <= 1'b0;

    repeat (1) @(posedge clk);
    m_bresp  <= 2'b00;
    m_bvalid <= 1'b1;
    @(posedge clk);
    m_bvalid <= 1'b0;

    wbs_cyc <= 1'b0;
    wbs_stb <= 1'b0;
    wbs_we <= 1'b0;

    @(posedge clk);
    report(wbs_ack, "w2m WB ack reported for write");
    report(!wbs_err, "w2m WB err should be low for OKAY write resp");

    wbs_cyc <= 1'b0;
    wbs_stb <= 1'b0;
    wbs_we  <= 1'b0;

    // --------------------------------------------------------
    // Test 4: Wishbone read -> AXI-Lite read
    // --------------------------------------------------------
    repeat (2) @(posedge clk);
    wbs_addr <= 32'h2000_0080;
    wbs_we   <= 1'b0;
    wbs_cyc  <= 1'b1;
    wbs_stb  <= 1'b1;

    repeat (2) @(posedge clk);
    report(m_arvalid, "w2m should drive AXI ARVALID");
    report(m_araddr == 32'h2000_0080, "w2m ARADDR mismatch");
    
    @(posedge clk);
    m_arready <= 1'b1;
    @(posedge clk);
    m_arready <= 1'b0;

    repeat (1) @(posedge clk);
    m_rdata  <= 32'hCAFE_BABE;
    m_rresp  <= 2'b00;
    m_rvalid <= 1'b1;
    @(posedge clk);
    m_rvalid <= 1'b0;

    wbs_cyc <= 1'b0;
    wbs_stb <= 1'b0;
    
    @(posedge clk);
    report(wbs_ack, "w2m WB ack reported for read");
    report(wbs_data_o == 32'hCAFE_BABE, "w2m WB read data mismatch");
    report(!wbs_err, "w2m WB err should be low for OKAY read resp");

    wbs_cyc <= 1'b0;
    wbs_stb <= 1'b0;

    repeat (3) @(posedge clk);

    if (error_cnt == 0)
        $display("PASS: wb_dma_axi_bridge_tb");
    else
        $display("FAIL: wb_dma_axi_bridge_tb with %0d errors", error_cnt);

    $finish;
end

endmodule