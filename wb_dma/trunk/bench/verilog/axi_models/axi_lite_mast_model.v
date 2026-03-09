`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// AXI-Lite Master Model (CPU/Host behavioral model)
// 提供和原版 wb_mast_model 类似的“主机任务接口”风格：axi_wr1 / axi_rd1
// -----------------------------------------------------------------------------
module axi_lite_mast_model(
    input               clk,
    input               rst,

    output reg [31:0]   awaddr,
    output reg          awvalid,
    input               awready,

    output reg [31:0]   wdata,
    output reg [3:0]    wstrb,
    output reg          wvalid,
    input               wready,

    input      [1:0]    bresp,
    input               bvalid,
    output reg          bready,

    output reg [31:0]   araddr,
    output reg          arvalid,
    input               arready,

    input      [31:0]   rdata,
    input      [1:0]    rresp,
    input               rvalid,
    output reg          rready
);

initial begin
    awaddr  = 32'h0;
    awvalid = 1'b0;
    wdata   = 32'h0;
    wstrb   = 4'h0;
    wvalid  = 1'b0;
    bready  = 1'b0;
    araddr  = 32'h0;
    arvalid = 1'b0;
    rready  = 1'b0;
    #1;
    $display("INFO: AXI-Lite MASTER MODEL INSTANTIATED (%m)");
end

// 单次写任务：发起 AW/W，等待 B
// a: 地址, d: 数据
task axi_wr1;
    input [31:0] a;
    input [31:0] d;
    begin
        @(posedge clk);
        #1;
        awaddr  = a;
        awvalid = 1'b1;
        wdata   = d;
        wstrb   = 4'hf;
        wvalid  = 1'b1;

        while (!(awready && wready)) @(posedge clk);
        #1;
        awvalid = 1'b0;
        wvalid  = 1'b0;

        bready = 1'b1;
        while (!bvalid) @(posedge clk);
        #1;
        bready = 1'b0;

        if (bresp != 2'b00)
            $display("ERROR: axi_wr1 BRESP != OKAY (%0h) @%0t", bresp, $time);
    end
endtask

// 单次读任务：发起 AR，等待 R
// a: 地址, d: 读回数据
task axi_rd1;
    input  [31:0] a;
    output [31:0] d;
    begin
        @(posedge clk);
        #1;
        araddr  = a;
        arvalid = 1'b1;

        while (!arready) @(posedge clk);
        #1;
        arvalid = 1'b0;

        rready = 1'b1;
        while (!rvalid) @(posedge clk);
        #1;
        d = rdata;
        rready = 1'b0;

        if (rresp != 2'b00)
            $display("ERROR: axi_rd1 RRESP != OKAY (%0h) @%0t", rresp, $time);
    end
endtask

endmodule