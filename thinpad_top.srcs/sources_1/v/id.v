`include "defines.v"
module id(
	input wire rst,
	
	//指令相关信息
	input wire[`InstAddrBus] pc_i,
	input wire[`InstBus] inst_i,
	
	//从寄存器堆中读出的寄存器内容
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,
	
	//来自执行阶段的前递信�??
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,
	
	//来自访存阶段的前递信�??
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,
	
	//指示当前指令是否为延迟槽指令
	input wire is_in_delayslot_i,
	
	//处于执行阶段的指令操作类型，配合停顿使用
	input wire[`AluOpBus] ex_aluop_i,
	
	//解析指令获得的运算类�??
	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	
	//访问寄存器堆�??要的使能信号、地�??
	output reg reg1_read_o,
	output reg reg2_read_o,
	output reg[`RegAddrBus] reg1_addr_o,
	output reg[`RegAddrBus] reg2_addr_o,
	
	//传�?�给执行阶段的两个操作数
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	
	//回写阶段�??要的写地�??和写数据
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	
	//分支跳转相关信号
	output reg br_flag_o,
	output reg[`RegBus] br_addr_o,
	output reg next_inst_in_delayslot_o,
	output reg[`RegBus] link_addr_o,	//�??要保存在寄存器中的地�??
	output reg is_in_delayslot_o,
	
	//暂停请求信号
	output wire stallreq,
	
	//向后传�?�指令内容，供存取指令使�??
	output wire[`RegBus] inst_o
);

//解析指令片段
wire[5:0] op = 	inst_i[31:26];
wire[5:0] op3 = inst_i[5:0];
wire[4:0] op4 = inst_i[20:16];

//分支跳转指令使用
wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_inst;		//存放扩展的立即数

//存放指令中的立即数片�??(非分支跳转指�??)
reg[`RegBus] imm;

//指示指令是否有效
reg instvalid;

//用于load相关问题
reg reg1_load;
reg reg2_load;
wire load_related;


assign pc_plus_4 = pc_i + 4;
assign pc_plus_8 = pc_i + 8;
assign imm_inst = {{14{inst_i[15]}},inst_i[15:0],2'b00};
assign inst_o = inst_i;

assign load_related = ((ex_aluop_i == `LB_OP) || (ex_aluop_i == `LW_OP)) ? 1'b1 : 1'b0;

//指令译码							
always@(*) begin
	if(rst == `RstEnable) begin
		aluop_o = `NOP_OP;
		alusel_o = `RES_NOP;
		wd_o = `NOPRegAddr;
		wreg_o = `WriteDisable;
		instvalid = `InstValid;
		reg1_read_o = `ReadDisable;
		reg2_read_o = `ReadDisable;
		reg1_addr_o = `NOPRegAddr;
		reg2_addr_o = `NOPRegAddr;
		imm = 32'h0;
		link_addr_o = `ZeroWord;
		br_addr_o = `ZeroWord;
		br_flag_o = `NotBranch;
		next_inst_in_delayslot_o = 1'b0;
		end
	else begin
		aluop_o = `NOP_OP;
		alusel_o = `RES_NOP;
		wd_o = inst_i[15:11];
		wreg_o = `WriteDisable;
		instvalid = `InstInvalid;
		reg1_read_o = `ReadDisable;
		reg2_read_o = `ReadDisable;
		reg1_addr_o = inst_i[25:21];
		reg2_addr_o = inst_i[20:16];
		imm = `ZeroWord;
		link_addr_o = `ZeroWord;
		br_addr_o = `ZeroWord;
		br_flag_o = `NotBranch;
		next_inst_in_delayslot_o = 1'b0;
		case(op)
			`EXE_SPECIAL_INST:begin
				case(op3)
					`OR:begin
						wreg_o = `WriteEnable;
						aluop_o = `OR_OP;
						alusel_o = `RES_LOGIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`AND:begin
						wreg_o = `WriteEnable;
						aluop_o = `AND_OP;
						alusel_o = `RES_LOGIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`XOR:begin
						wreg_o = `WriteEnable;
						aluop_o = `XOR_OP;
						alusel_o = `RES_LOGIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`SLLV:begin
						wreg_o = `WriteEnable;
						aluop_o = `SLL_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`SRLV:begin
						wreg_o = `WriteEnable;
						aluop_o = `SRL_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`SRAV:begin
						wreg_o = `WriteEnable;
						aluop_o = `SRA_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`SLL:begin
						wreg_o = `WriteEnable;
						aluop_o = `SLL_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadDisable;
						reg2_read_o = `ReadEnable;
						imm[4:0] = inst_i[10:6];
						instvalid = `InstValid;
						end
					`SRL:begin
						wreg_o = `WriteEnable;
						aluop_o = `SRL_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadDisable;
						reg2_read_o = `ReadEnable;
						imm[4:0] = inst_i[10:6];
						instvalid = `InstValid;
						end
					`SRA:begin
						wreg_o = `WriteEnable;
						aluop_o = `SRA_OP;
						alusel_o = `RES_SHIFT;
						reg1_read_o = `ReadDisable;
						reg2_read_o = `ReadEnable;
						imm[4:0] = inst_i[10:6];
						instvalid = `InstValid;
						end	
					`SLT:begin
						wreg_o = `WriteEnable;
						aluop_o = `SLT_OP;
						alusel_o = `RES_ARITHMETIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`ADD:begin
						wreg_o = `WriteEnable;
						aluop_o = `ADD_OP;
						alusel_o = `RES_ARITHMETIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`ADDU:begin
						wreg_o = `WriteEnable;
						aluop_o = `ADDU_OP;
						alusel_o = `RES_ARITHMETIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`SUB:begin
						wreg_o = `WriteEnable;
						aluop_o = `SUB_OP;
						alusel_o = `RES_ARITHMETIC;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`JR:begin
						wreg_o = `WriteDisable;
						aluop_o = `NOP_OP;
						alusel_o = `RES_JUMP_BRANCH;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadDisable;
						link_addr_o = `ZeroWord;
						br_addr_o = reg1_o;
						br_flag_o = `Branch;
						next_inst_in_delayslot_o = `ReadEnable;
						instvalid = `InstValid;
						end
					`JALR:begin
						wreg_o = `WriteEnable;
						aluop_o = `NOP_OP;
						alusel_o = `RES_JUMP_BRANCH;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadDisable;
						link_addr_o = pc_plus_8;
						br_addr_o = reg1_o;
						br_flag_o = `Branch;
						next_inst_in_delayslot_o = `ReadEnable;
						instvalid = `InstValid;
						end
					default:begin
						end
				endcase
			end				
			`EXE_SPECIAL2_INST:begin
				case(op3)
					`MUL:begin
						wreg_o = `WriteEnable;
						aluop_o = `MUL_OP;
						alusel_o = `RES_MUL;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadEnable;
						instvalid = `InstValid;
						end
					default:begin
						end
				endcase
				end	
			`EXE_REGIMM_INST:begin
				case(op4)
					`BGEZ:begin
						wreg_o = `WriteDisable;
						aluop_o = `NOP_OP;
						alusel_o = `RES_JUMP_BRANCH;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadDisable;
						instvalid = `InstValid;
						if(reg1_o[31] == 1'b0) begin
							br_addr_o = pc_plus_4 + imm_inst;
							br_flag_o = `Branch;
							next_inst_in_delayslot_o = 1'b1;
							end
						end
					`BLTZ:begin
						wreg_o = `WriteDisable;
						aluop_o = `NOP_OP;
						alusel_o = `RES_JUMP_BRANCH;
						reg1_read_o = `ReadEnable;
						reg2_read_o = `ReadDisable;
						instvalid = `InstValid;
						if(reg1_o[31] == 1'b1) begin
							br_addr_o = pc_plus_4 + imm_inst;
							br_flag_o = `Branch;
							next_inst_in_delayslot_o = 1'b1;
							end
						end
					default:begin
						end
				endcase	
				end
			`ORI:begin
				wreg_o = `WriteEnable;
				aluop_o = `OR_OP;
				alusel_o = `RES_LOGIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {16'h0,inst_i[15:0]};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`ANDI:begin
				wreg_o = `WriteEnable;
				aluop_o = `AND_OP;
				alusel_o = `RES_LOGIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {16'h0,inst_i[15:0]};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`XORI:begin
				wreg_o = `WriteEnable;
				aluop_o = `XOR_OP;
				alusel_o = `RES_LOGIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {16'h0,inst_i[15:0]};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`LUI:begin
				wreg_o = `WriteEnable;
				aluop_o = `OR_OP;
				alusel_o = `RES_LOGIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {inst_i[15:0],16'h0};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`ADDI:begin
				wreg_o = `WriteEnable;
				aluop_o = `ADD_OP;
				alusel_o = `RES_ARITHMETIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {{16{inst_i[15]}},inst_i[15:0]};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`ADDIU:begin
				wreg_o = `WriteEnable;
				aluop_o = `ADDU_OP;
				alusel_o = `RES_ARITHMETIC;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				imm = {{16{inst_i[15]}},inst_i[15:0]};
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`J:begin
				wreg_o = `WriteDisable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadDisable;
				reg2_read_o = `ReadDisable;
				link_addr_o = `ZeroWord;
				br_flag_o = `Branch;
				br_addr_o = {pc_plus_4[31:28],inst_i[25:0],2'b00};
				next_inst_in_delayslot_o = 1'b1;
				instvalid = `InstValid;
				end
			`JAL:begin
				wreg_o = `WriteEnable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadDisable;
				reg2_read_o = `ReadDisable;
				wd_o = 5'b11111;
				link_addr_o = pc_plus_8;
				br_flag_o = `Branch;
				br_addr_o = {pc_plus_4[31:28],inst_i[25:0],2'b00};
				next_inst_in_delayslot_o = 1'b1;
				instvalid = `InstValid;
				end
			`BEQ:begin
				wreg_o = `WriteDisable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadEnable;
				instvalid = `InstValid;
				if(reg1_o == reg2_o) begin
					br_addr_o = pc_plus_4 + imm_inst;
					br_flag_o = `Branch;
					next_inst_in_delayslot_o = 1'b1;
					end
				end	
			`BGTZ:begin
				wreg_o = `WriteDisable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				instvalid = `InstValid;
				if(reg1_o[31]==1'b0 && reg1_o!=`ZeroWord) begin
					br_addr_o = pc_plus_4 + imm_inst;
					br_flag_o = `Branch;
					next_inst_in_delayslot_o = 1'b1;
					end
				end
			`BLEZ:begin
				wreg_o = `WriteDisable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				instvalid = `InstValid;
				if(reg1_o[31]==1'b1 || reg1_o==`ZeroWord) begin
					br_addr_o = pc_plus_4 + imm_inst;
					br_flag_o = `Branch;
					next_inst_in_delayslot_o = 1'b1;
					end
				end
			`BNE:begin
				wreg_o = `WriteDisable;
				aluop_o = `NOP_OP;
				alusel_o = `RES_JUMP_BRANCH;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadEnable;
				instvalid = `InstValid;
				if(reg1_o != reg2_o) begin
					br_addr_o = pc_plus_4 + imm_inst;
					br_flag_o = `Branch;
					next_inst_in_delayslot_o = 1'b1;
					end
				end	
			`LB:begin
				wreg_o = `WriteEnable;
				aluop_o = `LB_OP;
				alusel_o = `RES_LOAD_STORE;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`LW:begin
				wreg_o = `WriteEnable;
				aluop_o = `LW_OP;
				alusel_o = `RES_LOAD_STORE;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadDisable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
				end
			`SB:begin
				wreg_o = `WriteDisable;
				aluop_o = `SB_OP;
				alusel_o = `RES_LOAD_STORE;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadEnable;
				instvalid = `InstValid;
				end
			`SW:begin
				wreg_o = `WriteDisable;
				aluop_o = `SW_OP;
				alusel_o = `RES_LOAD_STORE;
				reg1_read_o = `ReadEnable;
				reg2_read_o = `ReadEnable;
				instvalid = `InstValid;
				end
			default:begin
				end
		endcase
		end
end

//获得第一个操作数
always@(*) begin
	if(rst == `RstEnable)
		reg1_o = `ZeroWord;
	else if((load_related == 1'b1) && (ex_wd_i == reg1_addr_o) && (reg1_read_o == `ReadEnable))		//发生load相关
		reg1_o = `ZeroWord;
	else if((reg1_read_o == `ReadEnable) && (ex_wreg_i == `WriteEnable) && (ex_wd_i == reg1_addr_o)) 	//发生译码-执行数据相关
		reg1_o = ex_wdata_i;
	else if((reg1_read_o == `ReadEnable) && (mem_wreg_i == `WriteEnable) && (mem_wd_i == reg1_addr_o)) //发生译码-访存数据相关
		reg1_o = mem_wdata_i;
	else if(reg1_read_o == `ReadEnable)
		reg1_o = reg1_data_i;
	else if(reg1_read_o == `ReadDisable)	
		reg1_o = imm;
	else
		reg1_o = `ZeroWord;
end

//获得第二个操作数
always@(*) begin
	if(rst == `RstEnable)
		reg2_o = `ZeroWord;
	else if((load_related == 1'b1) && (ex_wd_i == reg2_addr_o) && (reg2_read_o == `ReadEnable))			//发生load相关	
		reg2_o = `ZeroWord;
	else if((reg2_read_o == `ReadEnable) && (ex_wreg_i == `WriteEnable) && (ex_wd_i == reg2_addr_o))	//发生译码-执行数据相关
		reg2_o = ex_wdata_i;
	else if((reg2_read_o == `ReadEnable) && (mem_wreg_i == `WriteEnable) && (mem_wd_i == reg2_addr_o)) //发生译码-访存数据相关
		reg2_o = mem_wdata_i;	
	else if(reg2_read_o == `ReadEnable)
		reg2_o = reg2_data_i;
	else if(reg2_read_o == `ReadDisable)
		reg2_o = imm;
	else
		reg2_o = `ZeroWord;
end	
//�?查第�?个读寄存器有无load相关
always@(*) begin
    if(rst == `RstEnable) begin
		reg1_load = 1'b0;
	end else if((load_related == 1'b1) && (ex_wd_i == reg1_addr_o) && (reg1_read_o == `ReadEnable))	begin
		reg1_load = 1'b1;
	end else begin
		reg1_load = 1'b0;
	end		
end


//�?查第二个读寄存器有无load相关
always@(*) begin
    if(rst == `RstEnable) begin
		reg2_load = 1'b0;
	end else if((load_related == 1'b1) && (ex_wd_i == reg2_addr_o) && (reg2_read_o == `ReadEnable))	begin
		reg2_load = 1'b1;
	end else begin
		reg2_load = 1'b0;
	end		
end

//处理延迟槽指�??
always@(*) begin
	if(rst == `RstEnable)
		is_in_delayslot_o = 1'b0;
	else
		is_in_delayslot_o = is_in_delayslot_i;
end
		
assign stallreq = reg1_load | reg2_load;	//发出停顿请求
		
endmodule