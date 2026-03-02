/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE DMA DMA Engine Core                               ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/wb_dma/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: wb_dma_de.v,v 1.3 2002-02-01 01:54:45 rudi Exp $
//
//  $Date: 2002-02-01 01:54:45 $
//  $Revision: 1.3 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.2  2001/08/15 05:40:30  rudi
//
//               - Changed IO names to be more clear.
//               - Uniquifyed define names to be core specific.
//               - Added Section 3.10, describing DMA restart.
//
//               Revision 1.1  2001/07/29 08:57:02  rudi
//
//
//               1) Changed Directory Structure
//               2) Added restart signal (REST)
//
//               Revision 1.3  2001/06/13 02:26:48  rudi
//
//
//               Small changes after running lint.
//
//               Revision 1.2  2001/06/05 10:22:36  rudi
//
//
//               - Added Support of up to 31 channels
//               - Added support for 2,4 and 8 priority levels
//               - Now can have up to 31 channels
//               - Added many configuration items
//               - Changed reset to async
//
//               Revision 1.1.1.1  2001/03/19 13:10:44  rudi
//               Initial Release
//
//
//

`include "wb_dma_defines.v"

module wb_dma_de(clk, rst,

	// WISHBONE MASTER INTERFACE 0
	mast0_go, mast0_we, mast0_adr, mast0_din,
	mast0_dout, mast0_err, mast0_drdy, mast0_wait, 

	// WISHBONE MASTER INTERFACE 1
	mast1_go, mast1_we, mast1_adr, mast1_din,
	mast1_dout, mast1_err, mast1_drdy, mast1_wait,

	// DMA Engine Init & Setup
	de_start, nd, csr, pointer, pointer_s, txsz,
	adr0, adr1, am0, am1,

	// DMA Engine Register File Update Outputs
	de_csr_we, de_txsz_we, de_adr0_we, de_adr1_we, ptr_set,
	de_csr, de_txsz, de_adr0, de_adr1, de_fetch_descr,

	// DMA Engine Control Outputs
	next_ch, de_ack,

	// DMA Engine Status
	pause_req, paused,
	dma_abort, dma_busy, dma_err, dma_done, dma_done_all
	);

input		clk, rst;

// --------------------------------------
// WISHBONE MASTER INTERFACE 0

output		mast0_go;	// Perform a Master Cycle								//输出到总线上的信号，在这个模块里可以理解成输出
output		mast0_we;	// Read/Write
output	[31:0]	mast0_adr;	// Address for the transfer
input	[31:0]	mast0_din;	// Internal Input Data
output	[31:0]	mast0_dout;	// Internal Output Data
input		mast0_err;	// Indicates an error has occurred
input		mast0_drdy;	// Indicated that either data is available
				// during a read, or that the master can accept
				// the next data during a write
output		mast0_wait;	// Tells the master to insert wait cycles
				// because data can not be accepted/provided

// --------------------------------------
// WISHBONE MASTER INTERFACE 1

output		mast1_go;	// Perform a Master Cycle
output		mast1_we;	// Read/Write
output	[31:0]	mast1_adr;	// Address for the transfer
input	[31:0]	mast1_din;	// Internal Input Data
output	[31:0]	mast1_dout;	// Internal Output Data
input		mast1_err;	// Indicates an error has occurred
input		mast1_drdy;	// Indicated that either data is available
				// during a read, or that the master can accept
				// the next data during a write
output		mast1_wait;	// Tells the master to insert wait cycles
				// because data can not be accepted/provided

// --------------------------------------
// DMA Engine Signals

// DMA Engine Init & Setup
input		de_start;	// Start DMA Engine Indicator							//输入的配置信息，DMA引擎根据这些信息完成状态转换和数据传输
input		nd;		// Next Descriptor Indicator
input	[31:0]	csr;		// Selected Channel CSR
input	[31:0]	pointer;	// Linked List Descriptor pointer
input	[31:0]	pointer_s;	// Previous Pointer
input	[31:0]	txsz;		// Selected Channel Transfer Size
input	[31:0]	adr0, adr1;	// Selected Channel Addresses
input	[31:0]	am0, am1;	// Selected Channel Address Masks

// DMA Engine Register File Update Outputs
output		de_csr_we;	// Write enable for csr register						//返回给rf模块的信号，用于一些配置相关寄存器的更新，告诉rf模块我完成了数据的传输
output		de_txsz_we;	// Write enable for txsz register
output		de_adr0_we;	// Write enable for adr0 register
output		de_adr1_we;	// Write enable for adr1 register
output		ptr_set;	// Set Pointer as Valid
output	[31:0]	de_csr;		// Write Data for CSR when loading External Desc.
output	[11:0]	de_txsz;	// Write back data for txsz register
output	[31:0]	de_adr0;	// Write back data for adr0 register
output	[31:0]	de_adr1;	// Write back data for adr1 register
output		de_fetch_descr;	// Indicates that we are fetching a descriptor

// DMA Engine Control Outputs													给到sel模块，表示当前通道传输结束，可以开始下一个通道了，由sel模块决定下一个通道是谁
output		next_ch;	// Indicates the DMA Engine is done
output		de_ack;

// DMA Abort from RF (software forced abort)
input		dma_abort;

// DMA Engine Status															返回给rf模块的状态信号
input		pause_req;									
output		paused;
output		dma_busy, dma_err, dma_done, dma_done_all;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

parameter	[10:0]	// synopsys enum state
		IDLE		= 11'b000_0000_0001,
		READ		= 11'b000_0000_0010,
		WRITE		= 11'b000_0000_0100,
		UPDATE		= 11'b000_0000_1000,
		LD_DESC1	= 11'b000_0001_0000,
		LD_DESC2	= 11'b000_0010_0000,
		LD_DESC3	= 11'b000_0100_0000,
		LD_DESC4	= 11'b000_1000_0000,
		LD_DESC5	= 11'b001_0000_0000,
		WB		= 11'b010_0000_0000,
		PAUSE		= 11'b100_0000_0000;

reg	[10:0]	/* synopsys enum state */ state, next_state;
// synopsys state_vector state

reg	[31:0]	mast0_adr, mast1_adr;

reg	[29:0]	adr0_cnt, adr1_cnt;
wire	[29:0]	adr0_cnt_next, adr1_cnt_next;
wire	[29:0]	adr0_cnt_next1, adr1_cnt_next1;
reg		adr0_inc, adr1_inc;

reg	[8:0]	chunk_cnt;
reg		chunk_dec;

reg	[11:0]	tsz_cnt;
reg		tsz_dec;

reg		de_txsz_we;
reg		de_csr_we;
reg		de_adr0_we;
reg		de_adr1_we;
reg		ld_desc_sel;

wire		chunk_cnt_is_0_d;
reg		chunk_cnt_is_0_r;
wire		tsz_cnt_is_0_d;
reg		tsz_cnt_is_0_r;

reg		read, write;
reg		read_r, write_r;
wire		rd_ack, wr_ack;
reg		rd_ack_r;

reg		chunk_0;
wire		done;
reg		dma_done_d;
reg		dma_done_r;
reg		dma_abort_r;
reg		next_ch;
wire		read_hold, write_hold;
reg		write_hold_r;

reg	[1:0]	ptr_adr_low;						//读链表时的地址的最低两位，分别有0123四个数，代表一段链表在内存中占用4个连续的word：csr、txz、adr0、adr1
reg		m0_go;													//m0_go和m0_we用于加载链表时的控制，由状态机控制，因为访问链表时的读写和正常搬运数据时的读写不一样，所以用这两个信号去选择
reg		m0_we;													//正常来讲DMA读完肯定要写回，但是DESC加载链表模式下读完不写回内存而是给rf，所以要把读链表单独区分出来
reg		ptr_set;

// Aliases
wire		a0_inc_en = csr[4];	// Source Address (Adr 0) increment enable
wire		a1_inc_en = csr[3];	// Dest. Address (Adr 1) increment enable
wire		ptr_valid = pointer[0];												//pointer有效标志，为0加载链表到rf里，为1直接开始搬运
wire		use_ed = csr[`WDMA_USE_ED];											//是否使用内存链表

reg		mast0_drdy_r;
reg		paused;

reg		de_fetch_descr;		// Indicates that we are fetching a descriptor
////////////////////////////////////////////////////////////////////
//
// Misc Logic
//

always @(posedge clk)
	dma_done_r <= #1 dma_done;



//这一大段看着吓人，其实逻辑很简单，就是源地址adr0和目的地址adr1的计数器逻辑
//源地址计数器adr0_cnt，初始值为输入的adr0，，根据am0寄存器配置判断每一位要不要加，每次读操作rd_ack时加1，加法是30位的，低2位固定为00
// Address Counter 0 (Source Address)
always @(posedge clk)
	if(de_start | ptr_set)		adr0_cnt <= #1 adr0[31:2];
	else
	if(adr0_inc & a0_inc_en)	adr0_cnt <= #1 adr0_cnt_next;

// 30 Bit Incrementor (registered)
wb_dma_inc30r u0(	.clk(	clk		),
			.in(	adr0_cnt	),
			.out(	adr0_cnt_next1 	)	);

assign adr0_cnt_next[1:0] = adr0_cnt_next1[1:0];
assign adr0_cnt_next[2] = am0[4] ? adr0_cnt_next1[2] : adr0_cnt[2];				//根据am0寄存器的配置，决定该位是否要加1
assign adr0_cnt_next[3] = am0[5] ? adr0_cnt_next1[3] : adr0_cnt[3];				//有些时候不需要地址线性增加，比如循环缓冲区0x8000_0000~0x8000_FFFF
assign adr0_cnt_next[4] = am0[6] ? adr0_cnt_next1[4] : adr0_cnt[4];
assign adr0_cnt_next[5] = am0[7] ? adr0_cnt_next1[5] : adr0_cnt[5];
assign adr0_cnt_next[6] = am0[8] ? adr0_cnt_next1[6] : adr0_cnt[6];
assign adr0_cnt_next[7] = am0[9] ? adr0_cnt_next1[7] : adr0_cnt[7];
assign adr0_cnt_next[8] = am0[10] ? adr0_cnt_next1[8] : adr0_cnt[8];
assign adr0_cnt_next[9] = am0[11] ? adr0_cnt_next1[9] : adr0_cnt[9];
assign adr0_cnt_next[10] = am0[12] ? adr0_cnt_next1[10] : adr0_cnt[10];
assign adr0_cnt_next[11] = am0[13] ? adr0_cnt_next1[11] : adr0_cnt[11];
assign adr0_cnt_next[12] = am0[14] ? adr0_cnt_next1[12] : adr0_cnt[12];
assign adr0_cnt_next[13] = am0[15] ? adr0_cnt_next1[13] : adr0_cnt[13];
assign adr0_cnt_next[14] = am0[16] ? adr0_cnt_next1[14] : adr0_cnt[14];
assign adr0_cnt_next[15] = am0[17] ? adr0_cnt_next1[15] : adr0_cnt[15];
assign adr0_cnt_next[16] = am0[18] ? adr0_cnt_next1[16] : adr0_cnt[16];
assign adr0_cnt_next[17] = am0[19] ? adr0_cnt_next1[17] : adr0_cnt[17];
assign adr0_cnt_next[18] = am0[20] ? adr0_cnt_next1[18] : adr0_cnt[18];
assign adr0_cnt_next[19] = am0[21] ? adr0_cnt_next1[19] : adr0_cnt[19];
assign adr0_cnt_next[20] = am0[22] ? adr0_cnt_next1[20] : adr0_cnt[20];
assign adr0_cnt_next[21] = am0[23] ? adr0_cnt_next1[21] : adr0_cnt[21];
assign adr0_cnt_next[22] = am0[24] ? adr0_cnt_next1[22] : adr0_cnt[22];
assign adr0_cnt_next[23] = am0[25] ? adr0_cnt_next1[23] : adr0_cnt[23];
assign adr0_cnt_next[24] = am0[26] ? adr0_cnt_next1[24] : adr0_cnt[24];
assign adr0_cnt_next[25] = am0[27] ? adr0_cnt_next1[25] : adr0_cnt[25];
assign adr0_cnt_next[26] = am0[28] ? adr0_cnt_next1[26] : adr0_cnt[26];
assign adr0_cnt_next[27] = am0[29] ? adr0_cnt_next1[27] : adr0_cnt[27];
assign adr0_cnt_next[28] = am0[30] ? adr0_cnt_next1[28] : adr0_cnt[28];
assign adr0_cnt_next[29] = am0[31] ? adr0_cnt_next1[29] : adr0_cnt[29];

//源地址计数器adr1_cnt，初始值为输入的adr1，，根据am1寄存器配置判断每一位要不要加，每次写操作wr_ack时加1，加法是30位的，低2位固定为00
// Address Counter 1 (Destination Address)
always @(posedge clk)
	if(de_start | ptr_set)		adr1_cnt <= #1 adr1[31:2];
	else
	if(adr1_inc & a1_inc_en)	adr1_cnt <= #1 adr1_cnt_next;

// 30 Bit Incrementor (registered)
wb_dma_inc30r u1(	.clk(	clk		),
			.in(	adr1_cnt	),
			.out(	adr1_cnt_next1 	)	);

assign adr1_cnt_next[1:0] = adr1_cnt_next1[1:0];
assign adr1_cnt_next[2] = am1[4] ? adr1_cnt_next1[2] : adr1_cnt[2];
assign adr1_cnt_next[3] = am1[5] ? adr1_cnt_next1[3] : adr1_cnt[3];
assign adr1_cnt_next[4] = am1[6] ? adr1_cnt_next1[4] : adr1_cnt[4];
assign adr1_cnt_next[5] = am1[7] ? adr1_cnt_next1[5] : adr1_cnt[5];
assign adr1_cnt_next[6] = am1[8] ? adr1_cnt_next1[6] : adr1_cnt[6];
assign adr1_cnt_next[7] = am1[9] ? adr1_cnt_next1[7] : adr1_cnt[7];
assign adr1_cnt_next[8] = am1[10] ? adr1_cnt_next1[8] : adr1_cnt[8];
assign adr1_cnt_next[9] = am1[11] ? adr1_cnt_next1[9] : adr1_cnt[9];
assign adr1_cnt_next[10] = am1[12] ? adr1_cnt_next1[10] : adr1_cnt[10];
assign adr1_cnt_next[11] = am1[13] ? adr1_cnt_next1[11] : adr1_cnt[11];
assign adr1_cnt_next[12] = am1[14] ? adr1_cnt_next1[12] : adr1_cnt[12];
assign adr1_cnt_next[13] = am1[15] ? adr1_cnt_next1[13] : adr1_cnt[13];
assign adr1_cnt_next[14] = am1[16] ? adr1_cnt_next1[14] : adr1_cnt[14];
assign adr1_cnt_next[15] = am1[17] ? adr1_cnt_next1[15] : adr1_cnt[15];
assign adr1_cnt_next[16] = am1[18] ? adr1_cnt_next1[16] : adr1_cnt[16];
assign adr1_cnt_next[17] = am1[19] ? adr1_cnt_next1[17] : adr1_cnt[17];
assign adr1_cnt_next[18] = am1[20] ? adr1_cnt_next1[18] : adr1_cnt[18];
assign adr1_cnt_next[19] = am1[21] ? adr1_cnt_next1[19] : adr1_cnt[19];
assign adr1_cnt_next[20] = am1[22] ? adr1_cnt_next1[20] : adr1_cnt[20];
assign adr1_cnt_next[21] = am1[23] ? adr1_cnt_next1[21] : adr1_cnt[21];
assign adr1_cnt_next[22] = am1[24] ? adr1_cnt_next1[22] : adr1_cnt[22];
assign adr1_cnt_next[23] = am1[25] ? adr1_cnt_next1[23] : adr1_cnt[23];
assign adr1_cnt_next[24] = am1[26] ? adr1_cnt_next1[24] : adr1_cnt[24];
assign adr1_cnt_next[25] = am1[27] ? adr1_cnt_next1[25] : adr1_cnt[25];
assign adr1_cnt_next[26] = am1[28] ? adr1_cnt_next1[26] : adr1_cnt[26];
assign adr1_cnt_next[27] = am1[29] ? adr1_cnt_next1[27] : adr1_cnt[27];
assign adr1_cnt_next[28] = am1[30] ? adr1_cnt_next1[28] : adr1_cnt[28];
assign adr1_cnt_next[29] = am1[31] ? adr1_cnt_next1[29] : adr1_cnt[29];


//txsz寄存器表示传输的数据量大小，分为两部分：TOT_SZ和CHK_SZ，TOT_SZ表示总的数据量大小，CHK_SZ表示每次传输的数据块大小
//每次外设触发一次搬运，就搬运CHK_SZ大小的数据，这个大小通常由外设的缓冲能力决定，搬运完成1次后，需要外设再次触发req_i才能进行下一个块的搬运
// Chunk Counter															表示每次外部触发（HW）时，DMA搬运的数据块大小
always @(posedge clk)
	if(de_start)				chunk_cnt <= #1 txsz[24:16];
	else
	if(chunk_dec & !chunk_cnt_is_0_r)	chunk_cnt <= #1 chunk_cnt - 9'h1;		//每次读操作read时chunk_cnt减1

assign chunk_cnt_is_0_d = (chunk_cnt == 9'h0);

always @(posedge clk)
	chunk_cnt_is_0_r <= #1 chunk_cnt_is_0_d;

// Total Size Counter														表示一次完整的DMA传输的总字数，传输完成后整个传输结束，向CPU触发中断
always @(posedge clk)
	if(de_start | ptr_set)		tsz_cnt <= #1 txsz[11:0];
	else
	if(tsz_dec & !tsz_cnt_is_0_r)	tsz_cnt <= #1 tsz_cnt - 12'h1;			//每次读操作read时tsz_cnt减1

assign tsz_cnt_is_0_d = (tsz_cnt == 12'h0) & !txsz[15];

always @(posedge clk)
	tsz_cnt_is_0_r <= #1 tsz_cnt_is_0_d;

// Counter Control Logic
always @(posedge clk)
	chunk_dec <= #1 read & !read_r;			//边沿检测

always @(posedge clk)
	tsz_dec <= #1 read & !read_r;

//always @(posedge clk)
always @(rd_ack or read_r)
	adr0_inc = rd_ack & read_r;				//每次读操作rd_ack时源地址adr0_cnt加1

//always @(posedge clk)
always @(wr_ack or write_r)
	adr1_inc = wr_ack & write_r;			//每次写操作wr_ack时目的地址adr1_cnt加1

// Done logic
always @(posedge clk)
	chunk_0 <= #1 (txsz[24:16] == 9'h0);

assign done = chunk_0 ? tsz_cnt_is_0_d : (tsz_cnt_is_0_d | chunk_cnt_is_0_d);		//chunk_0=1说明根本没分块，就看tsz是否归零。chunk_0=0说明真成功分块，就搬完一块done一次
assign dma_done = dma_done_d & done;												//同时满足：一次传输完成+UPDATE提交，才会产生dma_done
assign dma_done_all = dma_done_d & (tsz_cnt_is_0_r | (nd & chunk_cnt_is_0_d));			//非链表nd=0：整个事务的所有数据全部传输完成	链表nd=1：每个块完成都触发，用于推进链表

always @(posedge clk)
	next_ch <= #1 dma_done;

// Register Update Outputs															//每次1个chunk传输完成都会触发更新，方便下次接着传，这些是写回给rf模块的寄存器值，ld_desc_sel来自于状态机
assign de_txsz = ld_desc_sel ? mast0_din[11:0] : tsz_cnt;							//如果是内存配置的话，第一次会进入DESC1-5状态，ld_desc_sel=1，把链表寄存器里的数据写回rf模块，然后rf再给de引擎
assign de_adr0 = ld_desc_sel ? mast0_din : {adr0_cnt, 2'b00};						//					之后进入UPDATE更新状态的时候会把剩余数据量等数据写回rf模块，除非再次加载链表进入DESC1-5状态
assign de_adr1 = ld_desc_sel ? mast0_din : {adr1_cnt, 2'b00};						//如果是CPU配置的话，就不会进入DESC1-5，只会在UPDATE状态把剩余数据量等数据写回rf模块，告诉rf模块当前传输到了哪里
assign de_csr = mast0_din;																//在加载内存链表的时候，输入为mast0_din，说明只能从总线0加载

// Abort logic
always @(posedge clk)
	dma_abort_r <= #1 dma_abort | mast0_err | mast1_err;

assign	dma_err = dma_abort_r;

assign dma_busy = (state != IDLE);

////////////////////////////////////////////////////////////////////
//
// WISHBONE Interface Logic
//

always @(posedge clk)
	read_r <= #1 read;

always @(posedge clk)
	write_r <= #1 write;

always @(posedge clk)
	rd_ack_r <= #1 read_r;

// Data Path
assign mast0_dout = m0_we ? {20'h0, tsz_cnt} : csr[2] ? mast1_din : mast0_din;			//m0_we=1时要往链表里写回数据，写回的时剩余的数据长度
assign mast1_dout = csr[2] ? mast1_din : mast0_din;

// Address Path
always @(posedge clk)
	mast0_adr <= #1 m0_go ?															//mast0_adr在这里有两种情况，一种是正常的DMA传输，一种是加载链表
		(m0_we ? pointer_s : {pointer[31:4], ptr_adr_low, 2'b00}) :					//加载链表时，读操作读pointer指向的地址，写操作写pointer_s指向的地址
		read ? {adr0_cnt, 2'b00} : {adr1_cnt, 2'b00};								//正常DMA传输时，读的话read=1，就选源地址adr0_cnt，否则选目的地址adr1_cnt

always @(posedge clk)
	mast1_adr <= #1 read ? {adr0_cnt, 2'b00} : {adr1_cnt, 2'b00};					//读的话read=1，就选源地址adr0_cnt，否则选目的地址adr1_cnt

// CTRL
assign write_hold = (read | write) & write_hold_r;

always @(posedge clk)
	write_hold_r <= #1 read | write;

assign read_hold = done ? read : (read | write);

assign mast0_go = (!csr[2] & read_hold) | (!csr[1] & write_hold) | m0_go;			//mast*_go是给if的启动信号，最终会转化为cyc和stb，	mo_go等于强制进行mast0的访问，用于加载链表
assign mast1_go = ( csr[2] & read_hold) | ( csr[1] & write_hold);

assign mast0_we = m0_go ? m0_we : (!csr[1] & write);							//m0_go=1说明加载链表，就用m0_we，	否则说明正常的DMA
assign mast1_we = csr[1] & write;

assign rd_ack = (csr[2] ? mast1_drdy : mast0_drdy);
assign wr_ack = (csr[1] ? mast1_drdy : mast0_drdy);

assign mast0_wait = !((!csr[2] & read) | (!csr[1] & write)) & !m0_go;				
assign mast1_wait = !(( csr[2] & read) | ( csr[1] & write));

always @(posedge clk)
	mast0_drdy_r <= #1 mast0_drdy;

assign	de_ack = dma_done;

////////////////////////////////////////////////////////////////////
//
// State Machine
//

always @(posedge clk or negedge rst)
	if(!rst)	state <= #1 IDLE;
	else		state <= #1 next_state;

always @(state or pause_req or dma_abort_r or de_start or rd_ack or wr_ack or
	done or ptr_valid or use_ed or mast0_drdy or mast0_drdy_r or csr or nd)
   begin
	next_state = state;	// Default keep state
	read = 1'b0;
	write = 1'b0;
	dma_done_d = 1'b0;
	de_csr_we = 1'b0;
	de_txsz_we = 1'b0;
	de_adr0_we = 1'b0;
	de_adr1_we = 1'b0;
	de_fetch_descr = 1'b0;

	m0_go = 1'b0;
	m0_we = 1'b0;
	ptr_adr_low = 2'h0;
	ptr_set = 1'b0;
	ld_desc_sel = 1'b0;
	paused = 1'b0;

	case(state)		// synopsys parallel_case full_case

	   IDLE:
	     begin
		if(pause_req)			next_state = PAUSE;
		else
		if(de_start & !csr[`WDMA_ERR])
		   begin
			if(use_ed & !ptr_valid)	next_state = LD_DESC1;
			else			next_state = READ;
		   end
	     end

	   PAUSE:
	     begin
		paused = 1'b1;
		if(!pause_req)		next_state = IDLE;
	     end

	   READ:	// Read From Source
	     begin
		if(dma_abort_r)	next_state = UPDATE;
		else
		if(!rd_ack)	read = 1'b1;
		else
		   begin
			write = 1'b1;
			next_state = WRITE;
		   end
	     end

	   WRITE:	// Write To Destination
	     begin
		if(dma_abort_r)	next_state = UPDATE;
		else
		if(!wr_ack)	write = 1'b1;
		else
		   begin
			if(done)	next_state = UPDATE;
			else
			   begin
				read = 1'b1;
				next_state = READ;
			   end
		   end
	     end

	   UPDATE:	// Update Registers
	     begin
		dma_done_d = 1'b1;								//一次传输完成，dma_done_d置为1，保持一个时钟周期
		de_txsz_we = 1'b1;
		de_adr0_we = 1'b1;
		de_adr1_we = 1'b1;
		if(use_ed & csr[`WDMA_WRB] & nd)
		   begin
			m0_we = 1'b1;
			m0_go = 1'b1;
			next_state = WB;
		   end
		else			next_state = IDLE;
	     end

	   WB:												//WB状态：write back，写回，这里的写回指的是往内存链表里写回剩余数据长度
	     begin											//写回的地址为pointer_s，也就是当前链表地址，因为ptr_set之后pointer已经实现了更新，变成了下一段链表的地址
		m0_we = 1'b1;
		if(mast0_drdy)
		   begin
			next_state = IDLE;
		   end
		else	m0_go = 1'b1;
	     end

	   LD_DESC1:	// Load Descriptor from memory to registers
	     begin
		ptr_adr_low = 2'h0;
		ld_desc_sel = 1'b1;
		m0_go = 1'b1;
		de_csr_we = 1'b1;								//这个状态下同时写回de_csr[31:0]和de_txsz[11:0]
		de_txsz_we = 1'b1;
		de_fetch_descr = 1'b1;
		if(mast0_drdy)
		   begin
			ptr_adr_low = 2'h1;
			next_state = LD_DESC2;
		   end
	     end

	   LD_DESC2:
	     begin
		de_fetch_descr = 1'b1;
		if(mast0_drdy_r)	de_csr_we = 1'b1;
		if(mast0_drdy_r)	de_txsz_we = 1'b1;
		ptr_adr_low = 2'h1;
		ld_desc_sel = 1'b1;
		m0_go = 1'b1;
		if(mast0_drdy)
		   begin
			ptr_adr_low = 2'h2;
			next_state = LD_DESC3;
		   end
	     end

	   LD_DESC3:
	     begin
		de_fetch_descr = 1'b1;
		if(mast0_drdy_r)	de_adr0_we = 1'b1;
		ptr_adr_low = 2'h2;
		ld_desc_sel = 1'b1;
		m0_go = 1'b1;
		if(mast0_drdy)
		   begin
			ptr_adr_low = 2'h3;
			next_state = LD_DESC4;
		   end
	     end

	   LD_DESC4:
	     begin
		de_fetch_descr = 1'b1;
		if(mast0_drdy_r)	de_adr1_we = 1'b1;
		ptr_adr_low = 2'h3;
		ld_desc_sel = 1'b1;
		if(mast0_drdy)
		   begin
			next_state = LD_DESC5;
		   end
		else	m0_go = 1'b1;
	     end

	   LD_DESC5:										//注意这里的逻辑，最后一个word3看似没有用到，实际上在rf模块里ptr_set=1的时候，pointer=de_csr=mast0_din，所以word3刚好是下一段链表的地址
	     begin
		de_fetch_descr = 1'b1;
		ptr_set = 1'b1;											//告诉rf模块，已经完成了一个链表的加载，主要用于更新pointer指针，下次再从内存加载数据就加载新的一块链表
		next_state = READ;
	     end

	endcase

   end

endmodule
