`include "defines.v"
module ex_mem(
	input wire clk,
	input wire rst,
	
	//来自执行阶段的信�??
	input wire[`RegAddrBus] ex_wd,
	input wire ex_wreg,
	input wire[`RegBus] ex_wdata,
	input wire[`AluOpBus] ex_aluop,
	input wire[`RegBus] ex_mem_addr,
	
	//暂停信号
	input wire stall_pre,	//前一个阶段的暂停信号
	input wire stall_next,	//后一个阶段的暂停信号
	
	//传�?�给访存阶段的信�??
	output reg[`RegAddrBus] mem_wd,
	output reg mem_wreg,
	output reg[`RegBus] mem_wdata,
	output reg[`AluOpBus] mem_aluop,
	output reg[`RegBus] mem_addr
);

always@(posedge clk) begin
	if(rst == `RstEnable) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;
		mem_aluop <= `NOP_OP;
		mem_addr <= `ZeroWord;
		end
	else if(stall_pre == 1'b1 && stall_next == 1'b0) begin	//执行暂停，访存继�??
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;
		mem_aluop <= `NOP_OP;
		mem_addr <= `ZeroWord;
		end
	else if(stall_pre == 1'b0) begin
		mem_wd <= ex_wd;
		mem_wreg <= ex_wreg;
		mem_wdata <= ex_wdata;
		mem_aluop <= ex_aluop;
		mem_addr <= ex_mem_addr;
		end
	else begin
		mem_wd <= mem_wd;
		mem_wreg <= mem_wreg;
		mem_wdata <= mem_wdata;
		mem_aluop <= mem_aluop;
		mem_addr <= mem_addr;
		end	
end

endmodule		