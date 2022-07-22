`include "defines.v"
module id_ex(
	input wire clk,
	input wire rst,
	
	//��������׶ε��Ņ�
	input wire[`AluOpBus] id_aluop,
	input wire[`AluSelBus] id_alusel,
	input wire[`RegBus] id_reg1,
	input wire[`RegBus] id_reg2,
	input wire[`RegAddrBus] id_wd,
	input wire id_wreg,
	input wire id_is_in_delayslot,
	input wire next_inst_in_delayslot_i,
	input wire[`RegBus] id_link_addr,
	input wire[`RegBus] id_inst,
	
	//��ͣ�ź�
	input wire stall_pre,	//ǰһ���׶ε���ͣ�ź�
	input wire stall_next,	//��һ���׶ε���ͣ�ź�
	
	//��?��ִ�н׶ε��Ņ�
	output reg[`AluOpBus] ex_aluop,
	output reg[`AluSelBus] ex_alusel,
	output reg[`RegBus] ex_reg1,
	output reg[`RegBus] ex_reg2,
	output reg[`RegAddrBus] ex_wd,
	output reg ex_wreg,
	output reg ex_is_in_delayslot,
	output reg[`RegBus] ex_link_addr,
	output reg[`RegBus] ex_inst,
	
	//ָʾ��һʱ����������׶�Ϊ�ӳٲ�ָ��
	output reg is_in_delayslot_o
);

always@(posedge clk) begin
	if(rst == `RstEnable) begin
		ex_aluop <= `NOP_OP;
		ex_alusel <= `RES_NOP;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
		ex_link_addr <= `ZeroWord;
		ex_is_in_delayslot <= 1'b0;
		is_in_delayslot_o <= 1'b0;
		ex_inst <= `ZeroWord;
		end
	else if(stall_pre == 1'b1 && stall_next == 1'b0) begin	//������ͣ,ִ�м���
		ex_aluop <= `NOP_OP;
		ex_alusel <= `RES_NOP;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
		ex_link_addr <= `ZeroWord;
		ex_is_in_delayslot <= 1'b0;
		is_in_delayslot_o <= 1'b0;
		ex_inst <= `ZeroWord;
		end
	else if(stall_pre == 1'b0) begin
		ex_aluop <= id_aluop;
		ex_alusel <= id_alusel;
		ex_reg1 <= id_reg1;
		ex_reg2 <= id_reg2;
		ex_wd <= id_wd;
		ex_wreg <= id_wreg;
		ex_link_addr <= id_link_addr;
		ex_is_in_delayslot <= id_is_in_delayslot;
		is_in_delayslot_o <= next_inst_in_delayslot_i;
		ex_inst <= id_inst;
		end
	//Ĭ�ϱ����źŲ���	
end

endmodule
		