module axi4lite_slave_to_wb_master #(
    parameter AW = 32,
    parameter DW = 32
) (
    input                  clk,
    input                  rst,

    // AXI4-Lite slave (本模块作为AXI从机，接收CPU侧寄存器访问)
    input      [AW-1:0]    s_axi_awaddr,
    input                  s_axi_awvalid,
    output reg             s_axi_awready,
    input      [DW-1:0]    s_axi_wdata,
    input      [DW/8-1:0]  s_axi_wstrb,
    input                  s_axi_wvalid,
    output reg             s_axi_wready,
    output reg [1:0]       s_axi_bresp,
    output reg             s_axi_bvalid,
    input                  s_axi_bready,

    input      [AW-1:0]    s_axi_araddr,
    input                  s_axi_arvalid,
    output reg             s_axi_arready,
    output reg [DW-1:0]    s_axi_rdata,
    output reg [1:0]       s_axi_rresp,
    output reg             s_axi_rvalid,
    input                  s_axi_rready,

    // Wishbone master (将AXI事务翻译为Wishbone访问)
    output reg [DW-1:0]    wb_addr_o,
    output reg [DW-1:0]    wb_data_o,
    input      [DW-1:0]    wb_data_i,
    output reg [DW/8-1:0]  wb_sel_o,
    output reg             wb_we_o,
    output reg             wb_cyc_o,
    output reg             wb_stb_o,
    input                  wb_ack_i,
    input                  wb_err_i,
    input                  wb_rty_i
);

localparam ST_IDLE = 2'd0;
localparam ST_WB   = 2'd1;
localparam ST_RESP = 2'd2;

reg [1:0] state;      // 桥接状态机
reg       is_write;   // 记录当前事务是写(1)还是读(0)

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= ST_IDLE;
        is_write      <= 1'b0;

        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bresp   <= 2'b00;
        s_axi_bvalid  <= 1'b0;
        s_axi_arready <= 1'b0;
        s_axi_rdata   <= {DW{1'b0}};
        s_axi_rresp   <= 2'b00;
        s_axi_rvalid  <= 1'b0;

        wb_addr_o     <= {DW{1'b0}};
        wb_data_o     <= {DW{1'b0}};
        wb_sel_o      <= {DW/8{1'b0}};
        wb_we_o       <= 1'b0;
        wb_cyc_o      <= 1'b0;
        wb_stb_o      <= 1'b0;
    end else begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_arready <= 1'b0;

        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;

        case (state)
            ST_IDLE: begin
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;
                wb_we_o  <= 1'b0;

                if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;

                    wb_addr_o <= s_axi_awaddr;
                    wb_data_o <= s_axi_wdata;
                    wb_sel_o  <= s_axi_wstrb;
                    wb_we_o   <= 1'b1;
                    wb_cyc_o  <= 1'b1;
                    wb_stb_o  <= 1'b1;

                    is_write  <= 1'b1;
                    state     <= ST_WB;
                end else if (s_axi_arvalid && !s_axi_rvalid) begin
                    s_axi_arready <= 1'b1;

                    wb_addr_o <= s_axi_araddr;
                    wb_sel_o  <= {DW/8{1'b1}};
                    wb_we_o   <= 1'b0;
                    wb_cyc_o  <= 1'b1;
                    wb_stb_o  <= 1'b1;

                    is_write  <= 1'b0;
                    state     <= ST_WB;
                end
            end

            ST_WB: begin
                if (wb_ack_i || wb_err_i || wb_rty_i) begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;

                    if (is_write) begin
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= (wb_ack_i) ? 2'b00 : 2'b10;
                    end else begin
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= wb_data_i;
                        s_axi_rresp  <= (wb_ack_i) ? 2'b00 : 2'b10;
                    end

                    state <= ST_RESP;
                end
            end

            ST_RESP: begin
                if (is_write) begin
                    if (!s_axi_bvalid)
                        state <= ST_IDLE;
                end else begin
                    if (!s_axi_rvalid)
                        state <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule