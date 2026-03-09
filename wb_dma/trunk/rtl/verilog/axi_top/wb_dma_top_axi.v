module wb_dma_top_axi #(
    parameter        rf_addr = 0,
    parameter [1:0]  pri_sel = 2'h0,
    parameter        ch_count = 1,
    parameter [3:0]  ch0_conf = 4'h1,
    parameter [3:0]  ch1_conf = 4'h0,
    parameter [3:0]  ch2_conf = 4'h0,
    parameter [3:0]  ch3_conf = 4'h0,
    parameter [3:0]  ch4_conf = 4'h0,
    parameter [3:0]  ch5_conf = 4'h0,
    parameter [3:0]  ch6_conf = 4'h0,
    parameter [3:0]  ch7_conf = 4'h0,
    parameter [3:0]  ch8_conf = 4'h0,
    parameter [3:0]  ch9_conf = 4'h0,
    parameter [3:0]  ch10_conf = 4'h0,
    parameter [3:0]  ch11_conf = 4'h0,
    parameter [3:0]  ch12_conf = 4'h0,
    parameter [3:0]  ch13_conf = 4'h0,
    parameter [3:0]  ch14_conf = 4'h0,
    parameter [3:0]  ch15_conf = 4'h0,
    parameter [3:0]  ch16_conf = 4'h0,
    parameter [3:0]  ch17_conf = 4'h0,
    parameter [3:0]  ch18_conf = 4'h0,
    parameter [3:0]  ch19_conf = 4'h0,
    parameter [3:0]  ch20_conf = 4'h0,
    parameter [3:0]  ch21_conf = 4'h0,
    parameter [3:0]  ch22_conf = 4'h0,
    parameter [3:0]  ch23_conf = 4'h0,
    parameter [3:0]  ch24_conf = 4'h0,
    parameter [3:0]  ch25_conf = 4'h0,
    parameter [3:0]  ch26_conf = 4'h0,
    parameter [3:0]  ch27_conf = 4'h0,
    parameter [3:0]  ch28_conf = 4'h0,
    parameter [3:0]  ch29_conf = 4'h0,
    parameter [3:0]  ch30_conf = 4'h0
) (
    input               clk_i,
    input               rst_i,

    // AXI4-Lite Slave 0 (控制寄存器窗口0，给CPU/主控访问DMA配置)
    input      [31:0]   s0_axi_awaddr,   // 写地址
    input               s0_axi_awvalid,  // 写地址有效
    output              s0_axi_awready,  // 从机可接收写地址
    input      [31:0]   s0_axi_wdata,    // 写数据
    input      [3:0]    s0_axi_wstrb,    // 写字节使能
    input               s0_axi_wvalid,   // 写数据有效
    output              s0_axi_wready,   // 从机可接收写数据
    output     [1:0]    s0_axi_bresp,    // 写响应
    output              s0_axi_bvalid,   // 写响应有效
    input               s0_axi_bready,   // 主机可接收写响应
    input      [31:0]   s0_axi_araddr,   // 读地址
    input               s0_axi_arvalid,  // 读地址有效
    output              s0_axi_arready,  // 从机可接收读地址
    output     [31:0]   s0_axi_rdata,    // 读数据
    output     [1:0]    s0_axi_rresp,    // 读响应
    output              s0_axi_rvalid,   // 读数据有效
    input               s0_axi_rready,   // 主机可接收读数据

    // AXI4-Lite Master 0 (数据面主机0，原DMA端口0对外发起访存)
    output     [31:0]   m0_axi_awaddr,   // 作为总线0主机写地址通道
    output              m0_axi_awvalid,  // 主机写地址有效
    input               m0_axi_awready,  // 对端可接收写地址
    output     [31:0]   m0_axi_wdata,    // 主机写数据
    output     [3:0]    m0_axi_wstrb,    // 主机写字节使能
    output              m0_axi_wvalid,   // 主机写数据有效
    input               m0_axi_wready,   // 对端可接收写数据
    input      [1:0]    m0_axi_bresp,    // 对端写响应
    input               m0_axi_bvalid,   // 对端写响应有效
    output              m0_axi_bready,   // 主机可接收写响应
    output     [31:0]   m0_axi_araddr,   // 主机读地址
    output              m0_axi_arvalid,  // 主机读地址有效
    input               m0_axi_arready,  // 对端可接收读地址
    input      [31:0]   m0_axi_rdata,    // 对端读数据
    input      [1:0]    m0_axi_rresp,    // 对端读响应
    input               m0_axi_rvalid,   // 对端读数据有效
    output              m0_axi_rready,   // 主机可接收读数据

    // AXI4-Lite Slave 1 (控制寄存器窗口1)
    input      [31:0]   s1_axi_awaddr,   // 写地址
    input               s1_axi_awvalid,  // 写地址有效
    output              s1_axi_awready,  // 从机可接收写地址
    input      [31:0]   s1_axi_wdata,    // 写数据
    input      [3:0]    s1_axi_wstrb,    // 写字节使能
    input               s1_axi_wvalid,   // 写数据有效
    output              s1_axi_wready,   // 从机可接收写数据
    output     [1:0]    s1_axi_bresp,    // 写响应
    output              s1_axi_bvalid,   // 写响应有效
    input               s1_axi_bready,   // 主机可接收写响应
    input      [31:0]   s1_axi_araddr,   // 读地址
    input               s1_axi_arvalid,  // 读地址有效
    output              s1_axi_arready,  // 从机可接收读地址
    output     [31:0]   s1_axi_rdata,    // 读数据
    output     [1:0]    s1_axi_rresp,    // 读响应
    output              s1_axi_rvalid,   // 读数据有效
    input               s1_axi_rready,   // 主机可接收读数据

    // AXI4-Lite Master 1 (数据面主机1，原DMA端口1对外发起访存)
    output     [31:0]   m1_axi_awaddr,   // 作为总线1主机写地址通道
    output              m1_axi_awvalid,  // 主机写地址有效
    input               m1_axi_awready,  // 对端可接收写地址
    output     [31:0]   m1_axi_wdata,    // 主机写数据
    output     [3:0]    m1_axi_wstrb,    // 主机写字节使能
    output              m1_axi_wvalid,   // 主机写数据有效
    input               m1_axi_wready,   // 对端可接收写数据
    input      [1:0]    m1_axi_bresp,    // 对端写响应
    input               m1_axi_bvalid,   // 对端写响应有效
    output              m1_axi_bready,   // 主机可接收写响应
    output     [31:0]   m1_axi_araddr,   // 主机读地址
    output              m1_axi_arvalid,  // 主机读地址有效
    input               m1_axi_arready,  // 对端可接收读地址
    input      [31:0]   m1_axi_rdata,    // 对端读数据
    input      [1:0]    m1_axi_rresp,    // 对端读响应
    input               m1_axi_rvalid,   // 对端读数据有效
    output              m1_axi_rready,   // 主机可接收读数据

    input      [ch_count-1:0] dma_req_i,   // 外设DMA请求
    output     [ch_count-1:0] dma_ack_o,   // DMA请求应答
    input      [ch_count-1:0] dma_nd_i,    // Next Descriptor 请求
    input      [ch_count-1:0] dma_rest_i,  // 传输重启请求
    output                    inta_o,       // 中断A
    output                    intb_o        // 中断B
);

// 下列wb*信号是 wrapper 内部连接，桥接模块会把AXI事务转换成这些Wishbone信号
wire [31:0] wb0s_data_i, wb0s_data_o, wb0_addr_i;
wire [3:0]  wb0_sel_i;
wire        wb0_we_i, wb0_cyc_i, wb0_stb_i, wb0_ack_o, wb0_err_o, wb0_rty_o;
wire [31:0] wb0m_data_i, wb0m_data_o, wb0_addr_o;
wire [3:0]  wb0_sel_o;
wire        wb0_we_o, wb0_cyc_o, wb0_stb_o, wb0_ack_i, wb0_err_i, wb0_rty_i;

wire [31:0] wb1s_data_i, wb1s_data_o, wb1_addr_i;
wire [3:0]  wb1_sel_i;
wire        wb1_we_i, wb1_cyc_i, wb1_stb_i, wb1_ack_o, wb1_err_o, wb1_rty_o;
wire [31:0] wb1m_data_i, wb1m_data_o, wb1_addr_o;
wire [3:0]  wb1_sel_o;
wire        wb1_we_o, wb1_cyc_o, wb1_stb_o, wb1_ack_i, wb1_err_i, wb1_rty_i;

axi4lite_slave_to_wb_master u_s0_bridge (
    .clk(clk_i), .rst(rst_i),
    .s_axi_awaddr(s0_axi_awaddr), .s_axi_awvalid(s0_axi_awvalid), .s_axi_awready(s0_axi_awready),
    .s_axi_wdata(s0_axi_wdata), .s_axi_wstrb(s0_axi_wstrb), .s_axi_wvalid(s0_axi_wvalid), .s_axi_wready(s0_axi_wready),
    .s_axi_bresp(s0_axi_bresp), .s_axi_bvalid(s0_axi_bvalid), .s_axi_bready(s0_axi_bready),
    .s_axi_araddr(s0_axi_araddr), .s_axi_arvalid(s0_axi_arvalid), .s_axi_arready(s0_axi_arready),
    .s_axi_rdata(s0_axi_rdata), .s_axi_rresp(s0_axi_rresp), .s_axi_rvalid(s0_axi_rvalid), .s_axi_rready(s0_axi_rready),
    .wb_addr_o(wb0_addr_i), .wb_data_o(wb0m_data_i), .wb_data_i(wb0m_data_o), .wb_sel_o(wb0_sel_i),
    .wb_we_o(wb0_we_i), .wb_cyc_o(wb0_cyc_i), .wb_stb_o(wb0_stb_i), .wb_ack_i(wb0_ack_o), .wb_err_i(wb0_err_o), .wb_rty_i(wb0_rty_o)
);

axi4lite_slave_to_wb_master u_s1_bridge (
    .clk(clk_i), .rst(rst_i),
    .s_axi_awaddr(s1_axi_awaddr), .s_axi_awvalid(s1_axi_awvalid), .s_axi_awready(s1_axi_awready),
    .s_axi_wdata(s1_axi_wdata), .s_axi_wstrb(s1_axi_wstrb), .s_axi_wvalid(s1_axi_wvalid), .s_axi_wready(s1_axi_wready),
    .s_axi_bresp(s1_axi_bresp), .s_axi_bvalid(s1_axi_bvalid), .s_axi_bready(s1_axi_bready),
    .s_axi_araddr(s1_axi_araddr), .s_axi_arvalid(s1_axi_arvalid), .s_axi_arready(s1_axi_arready),
    .s_axi_rdata(s1_axi_rdata), .s_axi_rresp(s1_axi_rresp), .s_axi_rvalid(s1_axi_rvalid), .s_axi_rready(s1_axi_rready),
    .wb_addr_o(wb1_addr_i), .wb_data_o(wb1m_data_i), .wb_data_i(wb1m_data_o), .wb_sel_o(wb1_sel_i),
    .wb_we_o(wb1_we_i), .wb_cyc_o(wb1_cyc_i), .wb_stb_o(wb1_stb_i), .wb_ack_i(wb1_ack_o), .wb_err_i(wb1_err_o), .wb_rty_i(wb1_rty_o)
);

wb_master_to_axi4lite_master u_m0_bridge (
    .clk(clk_i), .rst(rst_i),
    .wb_addr_i(wb0_addr_o), .wb_data_i(wb0s_data_o), .wb_data_o(wb0s_data_i), .wb_sel_i(wb0_sel_o),
    .wb_we_i(wb0_we_o), .wb_cyc_i(wb0_cyc_o), .wb_stb_i(wb0_stb_o), .wb_ack_o(wb0_ack_i), .wb_err_o(wb0_err_i), .wb_rty_o(wb0_rty_i),
    .m_axi_awaddr(m0_axi_awaddr), .m_axi_awvalid(m0_axi_awvalid), .m_axi_awready(m0_axi_awready),
    .m_axi_wdata(m0_axi_wdata), .m_axi_wstrb(m0_axi_wstrb), .m_axi_wvalid(m0_axi_wvalid), .m_axi_wready(m0_axi_wready),
    .m_axi_bresp(m0_axi_bresp), .m_axi_bvalid(m0_axi_bvalid), .m_axi_bready(m0_axi_bready),
    .m_axi_araddr(m0_axi_araddr), .m_axi_arvalid(m0_axi_arvalid), .m_axi_arready(m0_axi_arready),
    .m_axi_rdata(m0_axi_rdata), .m_axi_rresp(m0_axi_rresp), .m_axi_rvalid(m0_axi_rvalid), .m_axi_rready(m0_axi_rready)
);

wb_master_to_axi4lite_master u_m1_bridge (
    .clk(clk_i), .rst(rst_i),
    .wb_addr_i(wb1_addr_o), .wb_data_i(wb1s_data_o), .wb_data_o(wb1s_data_i), .wb_sel_i(wb1_sel_o),
    .wb_we_i(wb1_we_o), .wb_cyc_i(wb1_cyc_o), .wb_stb_i(wb1_stb_o), .wb_ack_o(wb1_ack_i), .wb_err_o(wb1_err_i), .wb_rty_o(wb1_rty_i),
    .m_axi_awaddr(m1_axi_awaddr), .m_axi_awvalid(m1_axi_awvalid), .m_axi_awready(m1_axi_awready),
    .m_axi_wdata(m1_axi_wdata), .m_axi_wstrb(m1_axi_wstrb), .m_axi_wvalid(m1_axi_wvalid), .m_axi_wready(m1_axi_wready),
    .m_axi_bresp(m1_axi_bresp), .m_axi_bvalid(m1_axi_bvalid), .m_axi_bready(m1_axi_bready),
    .m_axi_araddr(m1_axi_araddr), .m_axi_arvalid(m1_axi_arvalid), .m_axi_arready(m1_axi_arready),
    .m_axi_rdata(m1_axi_rdata), .m_axi_rresp(m1_axi_rresp), .m_axi_rvalid(m1_axi_rvalid), .m_axi_rready(m1_axi_rready)
);

wb_dma_top #(
    .rf_addr(rf_addr), .pri_sel(pri_sel), .ch_count(ch_count),
    .ch0_conf(ch0_conf), .ch1_conf(ch1_conf), .ch2_conf(ch2_conf), .ch3_conf(ch3_conf),
    .ch4_conf(ch4_conf), .ch5_conf(ch5_conf), .ch6_conf(ch6_conf), .ch7_conf(ch7_conf),
    .ch8_conf(ch8_conf), .ch9_conf(ch9_conf), .ch10_conf(ch10_conf), .ch11_conf(ch11_conf),
    .ch12_conf(ch12_conf), .ch13_conf(ch13_conf), .ch14_conf(ch14_conf), .ch15_conf(ch15_conf),
    .ch16_conf(ch16_conf), .ch17_conf(ch17_conf), .ch18_conf(ch18_conf), .ch19_conf(ch19_conf),
    .ch20_conf(ch20_conf), .ch21_conf(ch21_conf), .ch22_conf(ch22_conf), .ch23_conf(ch23_conf),
    .ch24_conf(ch24_conf), .ch25_conf(ch25_conf), .ch26_conf(ch26_conf), .ch27_conf(ch27_conf),
    .ch28_conf(ch28_conf), .ch29_conf(ch29_conf), .ch30_conf(ch30_conf)
) u_dma (
    .clk_i(clk_i), .rst_i(rst_i),
    .wb0s_data_i(wb0s_data_i), .wb0s_data_o(wb0s_data_o), .wb0_addr_i(wb0_addr_i), .wb0_sel_i(wb0_sel_i), .wb0_we_i(wb0_we_i), .wb0_cyc_i(wb0_cyc_i),
    .wb0_stb_i(wb0_stb_i), .wb0_ack_o(wb0_ack_o), .wb0_err_o(wb0_err_o), .wb0_rty_o(wb0_rty_o),
    .wb0m_data_i(wb0m_data_i), .wb0m_data_o(wb0m_data_o), .wb0_addr_o(wb0_addr_o), .wb0_sel_o(wb0_sel_o), .wb0_we_o(wb0_we_o), .wb0_cyc_o(wb0_cyc_o),
    .wb0_stb_o(wb0_stb_o), .wb0_ack_i(wb0_ack_i), .wb0_err_i(wb0_err_i), .wb0_rty_i(wb0_rty_i),
    .wb1s_data_i(wb1s_data_i), .wb1s_data_o(wb1s_data_o), .wb1_addr_i(wb1_addr_i), .wb1_sel_i(wb1_sel_i), .wb1_we_i(wb1_we_i), .wb1_cyc_i(wb1_cyc_i),
    .wb1_stb_i(wb1_stb_i), .wb1_ack_o(wb1_ack_o), .wb1_err_o(wb1_err_o), .wb1_rty_o(wb1_rty_o),
    .wb1m_data_i(wb1m_data_i), .wb1m_data_o(wb1m_data_o), .wb1_addr_o(wb1_addr_o), .wb1_sel_o(wb1_sel_o), .wb1_we_o(wb1_we_o), .wb1_cyc_o(wb1_cyc_o),
    .wb1_stb_o(wb1_stb_o), .wb1_ack_i(wb1_ack_i), .wb1_err_i(wb1_err_i), .wb1_rty_i(wb1_rty_i),
    .dma_req_i(dma_req_i), .dma_ack_o(dma_ack_o), .dma_nd_i(dma_nd_i), .dma_rest_i(dma_rest_i), .inta_o(inta_o), .intb_o(intb_o)
);

endmodule