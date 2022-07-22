`include "defines.v"
module pc_reg(
	input wire rst,
	input wire clk,
	
	//暂停信号
	input wire stall,
	
	//分支跳转相关信号
	input wire br_flag_i,
	input wire[`RegBus] br_addr_i,
	
	//取指相关信号
	output reg[`InstAddrBus] pc,
	output reg ce
);

//芯片使能控制
always@(posedge clk) begin
	if(rst == `RstEnable)
		ce <= `ChipDisable;
	else
		ce <= `ChipEnable;
end

//指令地址控制
always@(posedge clk) begin
	if(ce == `ChipDisable)
		pc <= 32'h80000000;
	else if(stall == 1'b1)
		pc <= pc;
	else if(br_flag_i == `Branch)
		pc <= br_addr_i;
	else
		pc <= pc + 32'h4;
end

endmodule