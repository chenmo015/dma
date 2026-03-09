module wb_master_to_axi4lite_master #(
    parameter AW = 32,
    parameter DW = 32
) (
    input                  clk,
    input                  rst,

    // Wishbone slave side (接收来自DMA内部Wishbone主机的请求)
    input      [AW-1:0]    wb_addr_i,
    input      [DW-1:0]    wb_data_i,
    output reg [DW-1:0]    wb_data_o,
    input      [DW/8-1:0]  wb_sel_i,
    input                  wb_we_i,
    input                  wb_cyc_i,
    input                  wb_stb_i,
    output reg             wb_ack_o,
    output reg             wb_err_o,
    output reg             wb_rty_o,

    // AXI4-Lite master (向系统总线发起AXI访问)
    output reg [AW-1:0]    m_axi_awaddr,
    output reg             m_axi_awvalid,
    input                  m_axi_awready,
    output reg [DW-1:0]    m_axi_wdata,
    output reg [DW/8-1:0]  m_axi_wstrb,
    output reg             m_axi_wvalid,
    input                  m_axi_wready,
    input      [1:0]       m_axi_bresp,
    input                  m_axi_bvalid,
    output reg             m_axi_bready,

    output reg [AW-1:0]    m_axi_araddr,
    output reg             m_axi_arvalid,
    input                  m_axi_arready,
    input      [DW-1:0]    m_axi_rdata,
    input      [1:0]       m_axi_rresp,
    input                  m_axi_rvalid,
    output reg             m_axi_rready
);

localparam ST_IDLE  = 3'd0;
localparam ST_WADDR = 3'd1;
localparam ST_WRESP = 3'd2;
localparam ST_RADDR = 3'd3;
localparam ST_RRESP = 3'd4;
localparam ST_CAP   = 3'd5;

reg [2:0] state;      // 写地址/写响应/读地址/读响应阶段控制

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= ST_IDLE;
        wb_data_o     <= {DW{1'b0}};
        wb_ack_o      <= 1'b0;
        wb_err_o      <= 1'b0;
        wb_rty_o      <= 1'b0;

        m_axi_awaddr  <= {AW{1'b0}};
        m_axi_awvalid <= 1'b0;
        m_axi_wdata   <= {DW{1'b0}};
        m_axi_wstrb   <= {DW/8{1'b0}};
        m_axi_wvalid  <= 1'b0;
        m_axi_bready  <= 1'b0;

        m_axi_araddr  <= {AW{1'b0}};
        m_axi_arvalid <= 1'b0;
        m_axi_rready  <= 1'b0;
    end else begin
        wb_ack_o <= 1'b0;
        wb_err_o <= 1'b0;
        wb_rty_o <= 1'b0;

        case (state)
/*            ST_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin
                        m_axi_awaddr  <= wb_addr_i;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wdata   <= wb_data_i;
                        m_axi_wstrb   <= wb_sel_i;
                        m_axi_wvalid  <= 1'b1;
                        state         <= ST_WADDR;
                    end else begin
                        m_axi_araddr  <= wb_addr_i;
                        m_axi_arvalid <= 1'b1;
                        state         <= ST_RADDR;
                    end
                end
            end
*/
	    ST_IDLE: begin
                if (wb_cyc_i && wb_stb_i)
                    state <= ST_CAP;
            end

            ST_CAP: begin
                // Capture WB request one cycle later to avoid edge-alignment
                // sampling races with DMA engine updates.
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin
                        m_axi_awaddr  <= wb_addr_i;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wdata   <= wb_data_i;
                        m_axi_wstrb   <= wb_sel_i;
                        m_axi_wvalid  <= 1'b1;
                        state         <= ST_WADDR;
                    end else begin
                        m_axi_araddr  <= wb_addr_i;
                        m_axi_arvalid <= 1'b1;
                        state         <= ST_RADDR;
                    end
                end else begin
                    state <= ST_IDLE;
                end
            end		

            ST_WADDR: begin
                if (m_axi_awvalid && m_axi_awready)
                    m_axi_awvalid <= 1'b0;
                if (m_axi_wvalid && m_axi_wready)
                    m_axi_wvalid <= 1'b0;

                if ((!m_axi_awvalid || m_axi_awready) && (!m_axi_wvalid || m_axi_wready)) begin
                    m_axi_bready <= 1'b1;
                    state        <= ST_WRESP;
                end
            end

            ST_WRESP: begin
                if (m_axi_bvalid) begin
                    m_axi_bready <= 1'b0;
                    wb_ack_o     <= 1'b1;
                    if (m_axi_bresp != 2'b00)
                        wb_err_o <= 1'b1;
                    state <= ST_IDLE;
                end
            end

            ST_RADDR: begin
                if (m_axi_arvalid && m_axi_arready) begin
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready  <= 1'b1;
                    state         <= ST_RRESP;
                end
            end

            ST_RRESP: begin
                if (m_axi_rvalid) begin
                    wb_data_o    <= m_axi_rdata;
                    wb_ack_o     <= 1'b1;
                    if (m_axi_rresp != 2'b00)
                        wb_err_o <= 1'b1;
                    m_axi_rready <= 1'b0;
                    state        <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule