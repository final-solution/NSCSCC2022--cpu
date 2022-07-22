`include "defines.v"
module myCPU(
	input wire clk,
	input wire rst,
	input wire stallreq_from_thinpad,
	output wire stall_to_thinpad,
	
	//指令输入
	input wire[`RegBus] rom_data_i,
	
	//数据输入
	input wire[`RegBus] ram_data_i,
	
	//取指
	output wire[`RegBus] rom_addr_o,
	output wire[3:0] rom_sel_o,
	output wire rom_ce_o,
	
	//与数据存储器交互
	output wire[`RegBus] ram_addr_o,
	output wire ram_we_o,
	output wire[3:0] ram_sel_o,
	output wire[`RegBus] ram_data_o,
	output wire ram_ce_o
);

assign rom_sel_o = 4'b0;
//PC寄存器使�?????
wire[`InstAddrBus] pc;
wire[`RegBus] br_addr;
wire br_flag;

//译码
wire[`InstAddrBus] id_pc_i;	
wire[`AluOpBus] id_aluop_o;
wire[`AluSelBus] id_alusel_o;
wire[`RegBus] id_reg1_o;
wire[`RegBus] id_reg2_o;
wire id_wreg_o;
wire[`RegAddrBus] id_wd_o;
wire next_inst_in_delayslot;
wire is_in_delayslot;
wire[`RegBus] id_linkaddr_o;
wire id_is_in_delayslot_o;
wire[`RegBus] id_inst_o;

//执行
wire[`AluOpBus] ex_aluop_i;
wire[`AluSelBus] ex_alusel_i;
wire[`RegBus] ex_reg1_i;
wire[`RegBus] ex_reg2_i;
wire ex_wreg_i;
wire[`RegAddrBus] ex_wd_i;
wire[`RegBus] ex_linkaddr_i;
wire ex_is_in_delayslot_i;
wire[`RegBus] ex_inst_i;
wire ex_wreg_o;
wire[`RegAddrBus] ex_wd_o;
wire[`RegBus] ex_wdata_o;
wire[`AluOpBus] ex_aluop_o;
wire[`RegBus] ex_mem_addr_o;

//访存
wire mem_wreg_i;
wire[`RegAddrBus] mem_wd_i;
wire[`RegBus] mem_wdata_i;
wire[`AluOpBus] mem_aluop_i;
wire[`RegBus] mem_mem_addr_i;
wire mem_wreg_o;
wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;

//回写
wire wb_wreg_i;
wire[`RegAddrBus] wb_wd_i;
wire[`RegBus] wb_wdata_i;

//寄存器堆
wire reg1_read;
wire reg2_read;
wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;
wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;

//控制模块的暂停信�?????
wire stallreq_from_id;
wire[5:0] stall;

assign stall_to_thinpad = stall[1];

//控制模块
ctrl ctrl0(
	.rst(rst),
	.req_from_id(stallreq_from_id),
	.req_from_thinpad(stallreq_from_thinpad),
	
	.stall(stall)
);	

//PC寄存�?????
pc_reg pc_reg0(
	.clk(clk),
	.rst(rst),
	.br_flag_i(br_flag),
	.br_addr_i(br_addr),
	.stall(stall[0]),
	
	.pc(pc),
	.ce(rom_ce_o)
);	

assign rom_addr_o = pc;

//流水线寄存器
if_id if_id0(
	.clk(clk),
	.rst(rst),
	.if_pc(pc),
	.stall_pre(stall[1]),
	.stall_next(stall[2]),
	
	.id_pc(id_pc_i)
);

//译码
id id0(
	.rst(rst),
	.pc_i(id_pc_i),
	.inst_i(rom_data_i),
	.reg1_data_i(reg1_data),
	.reg2_data_i(reg2_data),
	.ex_wreg_i(ex_wreg_o),
	.ex_wd_i(ex_wd_o),
	.ex_wdata_i(ex_wdata_o),
	.mem_wreg_i(mem_wreg_o),
	.mem_wd_i(mem_wd_o),
	.mem_wdata_i(mem_wdata_o),
	.is_in_delayslot_i(is_in_delayslot),
	.ex_aluop_i(ex_aluop_o),
	
	.reg1_read_o(reg1_read),
	.reg2_read_o(reg2_read),
	.reg1_addr_o(reg1_addr),
	.reg2_addr_o(reg2_addr),
	.aluop_o(id_aluop_o),
	.alusel_o(id_alusel_o),
	.reg1_o(id_reg1_o),
	.reg2_o(id_reg2_o),
	.wd_o(id_wd_o),
	.wreg_o(id_wreg_o),
	.br_flag_o(br_flag),
	.br_addr_o(br_addr),
	.next_inst_in_delayslot_o(next_inst_in_delayslot),
	.link_addr_o(id_linkaddr_o),
	.is_in_delayslot_o(id_is_in_delayslot_o),
	.inst_o(id_inst_o),
	.stallreq(stallreq_from_id)
);	

//寄存器堆
regfile regfile1(
	.clk(clk),
	.rst(rst),
	.we(wb_wreg_i),
	.waddr(wb_wd_i),
	.wdata(wb_wdata_i),
	.re1(reg1_read),
	.re2(reg2_read),
	.raddr1(reg1_addr),
	.raddr2(reg2_addr),
	.rdata1(reg1_data),
	.rdata2(reg2_data)
);

//流水线寄存器
id_ex id_ex0(
	.clk(clk),
	.rst(rst),
	.id_aluop(id_aluop_o),
	.id_alusel(id_alusel_o),
	.id_reg1(id_reg1_o),
	.id_reg2(id_reg2_o),
	.id_wd(id_wd_o),
	.id_wreg(id_wreg_o),
	.next_inst_in_delayslot_i(next_inst_in_delayslot),
	.id_link_addr(id_linkaddr_o),
	.id_is_in_delayslot(id_is_in_delayslot_o),
	.id_inst(id_inst_o),
	.stall_pre(stall[2]),
	.stall_next(stall[3]),
	
	.ex_aluop(ex_aluop_i),
	.ex_alusel(ex_alusel_i),
	.ex_reg1(ex_reg1_i),
	.ex_reg2(ex_reg2_i),
	.ex_wd(ex_wd_i),
	.ex_wreg(ex_wreg_i),
	.ex_link_addr(ex_linkaddr_i),
	.ex_is_in_delayslot(ex_is_in_delayslot_i),
	.is_in_delayslot_o(is_in_delayslot),
	.ex_inst(ex_inst_i)
);	

//执行
ex ex0(
	.rst(rst),
	.aluop_i(ex_aluop_i),
	.alusel_i(ex_alusel_i),
	.reg1_i(ex_reg1_i),
	.reg2_i(ex_reg2_i),
	.wd_i(ex_wd_i),
	.wreg_i(ex_wreg_i),
	.link_addr_i(ex_linkaddr_i),
	.is_in_delayslot_i(ex_is_in_delayslot_i),
	.inst_i(ex_inst_i),

	
	.wd_o(ex_wd_o),
	.wreg_o(ex_wreg_o),
	.wdata_o(ex_wdata_o),
	.aluop_o(ex_aluop_o),
	.mem_addr_o(ex_mem_addr_o),
	.mem_we_o(ram_we_o),
	.mem_sel_o(ram_sel_o),
	.mem_data_o(ram_data_o),
	.mem_ce_o(ram_ce_o)
);

assign ram_addr_o = ex_mem_addr_o;

//流水线寄存器
ex_mem ex_mem0(
	.clk(clk),
	.rst(rst),
	.ex_wd(ex_wd_o),
	.ex_wreg(ex_wreg_o),
	.ex_wdata(ex_wdata_o),
	.ex_aluop(ex_aluop_o),
	.ex_mem_addr(ex_mem_addr_o),
	.stall_pre(stall[3]),
	.stall_next(stall[4]),
	
	.mem_wd(mem_wd_i),
	.mem_wreg(mem_wreg_i),
	.mem_wdata(mem_wdata_i),
	.mem_aluop(mem_aluop_i),
	.mem_addr(mem_mem_addr_i)
);

//访存
mem mem0(
	.rst(rst),
	.wd_i(mem_wd_i),
	.wreg_i(mem_wreg_i),
	.wdata_i(mem_wdata_i),
	.mem_data_i(ram_data_i),
	.aluop_i(mem_aluop_i),
	.mem_addr_i(mem_mem_addr_i),
	
	
	.wd_o(mem_wd_o),
	.wreg_o(mem_wreg_o),
	.wdata_o(mem_wdata_o)
);

//流水线寄存器
mem_wb mem_wb0(
	.clk(clk),
	.rst(rst),
	.mem_wd(mem_wd_o),
	.mem_wreg(mem_wreg_o),
	.mem_wdata(mem_wdata_o),
	.stall_pre(stall[4]),
	.stall_next(stall[5]),
	
	.wb_wd(wb_wd_i),
	.wb_wreg(wb_wreg_i),
	.wb_wdata(wb_wdata_i)
);

endmodule