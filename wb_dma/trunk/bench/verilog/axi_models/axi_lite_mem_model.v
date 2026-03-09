// ------------------------------------------------------------
// AXI-Lite memory model (single outstanding read/write)
// ------------------------------------------------------------
module axi_lite_mem_model #(
    parameter AW = 32,
    parameter DW = 32,
    parameter DEPTH_WORDS = 1024
) (
    input                  clk,
    input                  rst,

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
    input                  s_axi_rready
);

reg [DW-1:0] mem [0:DEPTH_WORDS-1];
integer i;

// 与原版 wb_slv_model 对齐：外部可在 test task 中直接设置 s0.delay/s1.delay
// delay=0: 无等待；delay=N: 收到请求后等待 N 个时钟再给 ready/resp
reg [5:0] delay;

reg        wr_pending;
reg [5:0]  wr_wait;
reg [AW-1:0] wr_addr;
reg [DW-1:0] wr_data;
reg [DW/8-1:0] wr_strb;

reg        rd_pending;
reg [5:0]  rd_wait;
reg [AW-1:0] rd_addr;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bresp   <= 2'b00;
        s_axi_bvalid  <= 1'b0;
        s_axi_arready <= 1'b0;
        s_axi_rdata   <= {DW{1'b0}};
        s_axi_rresp   <= 2'b00;
        s_axi_rvalid  <= 1'b0;
        delay         <= 6'd0;
        wr_pending    <= 1'b0;
        wr_wait       <= 6'd0;
        wr_addr       <= {AW{1'b0}};
        wr_data       <= {DW{1'b0}};
        wr_strb       <= {DW/8{1'b0}};
        rd_pending    <= 1'b0;
        rd_wait       <= 6'd0;
        rd_addr       <= {AW{1'b0}};
        for (i=0; i<DEPTH_WORDS; i=i+1)
            mem[i] <= {DW{1'b0}};
    end else begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_arready <= 1'b0;

        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;

        // 写请求捕获：仅支持 single outstanding
        if (!wr_pending && !s_axi_bvalid && s_axi_awvalid && s_axi_wvalid) begin
            wr_pending <= 1'b1;
            wr_wait    <= delay;
            wr_addr    <= s_axi_awaddr;
            wr_data    <= s_axi_wdata;
            wr_strb    <= s_axi_wstrb;
        end

        if (wr_pending) begin
            if (wr_wait != 0)
                wr_wait <= wr_wait - 1'b1;
            else if (s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;

                if (wr_strb[0]) mem[wr_addr[31:2]][7:0]   <= wr_data[7:0];
                if (wr_strb[1]) mem[wr_addr[31:2]][15:8]  <= wr_data[15:8];
                if (wr_strb[2]) mem[wr_addr[31:2]][23:16] <= wr_data[23:16];
                if (wr_strb[3]) mem[wr_addr[31:2]][31:24] <= wr_data[31:24];

                s_axi_bresp  <= 2'b00;
                s_axi_bvalid <= 1'b1;
                wr_pending   <= 1'b0;
            end
        end

        // 读请求捕获：仅支持 single outstanding
        if (!rd_pending && !s_axi_rvalid && s_axi_arvalid) begin
            rd_pending <= 1'b1;
            rd_wait    <= delay;
            rd_addr    <= s_axi_araddr;
        end

        if (rd_pending) begin
            if (rd_wait != 0)
                rd_wait <= rd_wait - 1'b1;
            else if (s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rdata   <= mem[rd_addr[13:2]];
                s_axi_rresp   <= 2'b00;
                s_axi_rvalid  <= 1'b1;
                rd_pending    <= 1'b0;
            end
        end
    end
end


task fill_mem;											
	input mode;										

	integer		n, mode;

	begin

	for(n=0;n<DEPTH_WORDS;n=n+1)
	   begin
		case(mode)
		   0:	mem[n] = { n };
		   1:	mem[n] = $random;
		endcase
	   end

	end
endtask

endmodule