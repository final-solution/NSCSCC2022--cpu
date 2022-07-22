`include "defines.v"
module ex(
	input wire rst,
	
	//运算类型
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	
	//操作数
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	
	//写请求
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	
	//当前指令是否为延迟槽指令
	(* DONT_TOUCH = "1" *) input wire is_in_delayslot_i,
	
	//需要保存在寄存器的链接地址
	input wire[`RegBus] link_addr_i,
	
	//处于本阶段的指令内容
	(* DONT_TOUCH = "1" *) input wire[`RegBus] inst_i,
	
	//回写阶段需要的写信号
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	//用于load相关
	output wire[`AluOpBus] aluop_o,

	//直接访存
	output reg[`RegBus] mem_addr_o,
	output reg[3:0] mem_sel_o,			//每一位对应一个字中的四个字节
	output reg[`RegBus] mem_data_o,		//待存储数据
	output reg mem_ce_o,				//使能信号
	output reg mem_we_o
);

//运算结果选择
reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] arithres;
reg[`DoubleRegBus] mulres;


wire overflow;				//保存溢出情况
wire reg1_lt_reg2;			//第一个操作数是否小于第二个操作数
wire[`RegBus] reg2_i_neg;	//保存第二个数的相反数补码
wire[`RegBus] sum_res;		//加法结果
wire[`RegBus] data1_mul;	//被乘数
wire[`RegBus] data2_mul;	//乘数
wire[`RegBus] mem_addr;

//减法和有符号比较
assign reg2_i_neg = ((aluop_i == `SUB_OP) || 
					(aluop_i == `SLT_OP)) ? (~reg2_i)+1 : reg2_i;

assign sum_res = reg1_i + reg2_i_neg;

assign overflow = (!reg1_i[31] && !reg2_i_neg[31] && sum_res[31]) ||
					(reg1_i[31] && reg2_i_neg[31] && !sum_res[31]);
					
assign reg1_lt_reg2 = (reg1_i[31]&&!reg2_i[31])||
					(!reg1_i[31]&&!reg2_i[31]&&sum_res[31])||
					(reg1_i[31]&&reg2_i[31]&&sum_res[31]);	

//乘法
assign data1_mul = aluop_i == `MUL_OP && reg1_i[31] ? (~reg1_i+1) : reg1_i;
assign data2_mul = aluop_i == `MUL_OP && reg2_i[31] ? (~reg2_i+1) : reg2_i;
 
//存取指令使用
assign aluop_o = aluop_i;
assign mem_addr = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

//算术运算
always@(*) begin
	if(rst == `RstEnable) 
		arithres = `ZeroWord;
	else begin
		case(aluop_i)
			`SLT_OP:
				arithres = reg1_lt_reg2;
			`ADD_OP,`ADDU_OP,`SUB_OP:
				arithres = sum_res;
			default:
				arithres = `ZeroWord;
		endcase
		end
end		

//乘法
always@(*) begin
	if(rst == `RstEnable)
		mulres = {`ZeroWord,`ZeroWord};
	else if(aluop_i == `MUL_OP) begin
		if(reg1_i[31]^reg2_i[31])
			mulres = ~(data1_mul*data2_mul)+1;
		else
			mulres = data1_mul*data2_mul;
		end
	else
		mulres = {`ZeroWord,`ZeroWord};
end		

//逻辑运算
always@(*) begin
	if(rst == `RstEnable)
		logicout = `ZeroWord;
	else begin
		case(aluop_i)
			`OR_OP:
				logicout = reg1_i | reg2_i;
			`AND_OP:
				logicout = reg1_i & reg2_i;
			`XOR_OP:
				logicout = reg1_i ^ reg2_i;	
			default:
				logicout = `ZeroWord;
		endcase
		end
end

//移位
always@(*) begin
	if(rst == `RstEnable)
		shiftres = `ZeroWord;
	else begin
		case(aluop_i) 
			`SLL_OP:
				shiftres = reg2_i << reg1_i[4:0];
			`SRL_OP:
				shiftres = reg2_i >> reg1_i[4:0];
			`SRA_OP:
				shiftres = ({32{reg2_i[31]}} << (6'd32 - {1'b0,reg1_i[4:0]})) | (reg2_i >> reg1_i[4:0]);
			default:
				shiftres = `ZeroWord;
		endcase
		end
end		

//获得待写入的数据
always@(*) begin
	wd_o = wd_i;
	
	if((aluop_i==`ADD_OP || aluop_i==`SUB_OP) && overflow)	//溢出则不写入
		wreg_o = `WriteDisable;
	else 	
		wreg_o = wreg_i;
		
	case(alusel_i)
		`RES_LOGIC:
			wdata_o = logicout;
		`RES_SHIFT:
			wdata_o = shiftres;
		`RES_ARITHMETIC:
			wdata_o = arithres;
		`RES_MUL:
			wdata_o = mulres[31:0];
		`RES_JUMP_BRANCH:
			wdata_o = link_addr_i;
		default:
			wdata_o = `ZeroWord;
	endcase
end

//发起访存
always@(*) begin
	if(rst == `RstEnable) begin
		mem_addr_o = `ZeroWord;
		mem_sel_o = 4'b1111;
		mem_data_o = `ZeroWord;
		mem_ce_o = `ChipDisable;
		mem_we_o = `WriteDisable;
	end else begin
		mem_addr_o = `ZeroWord;
		mem_sel_o = 4'b0000;
		mem_data_o = `ZeroWord;
		mem_ce_o = `ChipDisable;
		mem_we_o = `WriteDisable;
		case(aluop_i)
			`LB_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteDisable;
				mem_ce_o = `ChipEnable;
				case(mem_addr[1:0])
					2'b11:begin
						mem_sel_o = 4'b0111;
						end
					2'b10:begin
						mem_sel_o = 4'b1011;
						end
					2'b01:begin
						mem_sel_o = 4'b1101;
						end
					2'b00:begin
						mem_sel_o = 4'b1110;
						end
					default:begin
						mem_sel_o = 4'b0000;
						end
				endcase
			end
			`LW_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteDisable;
				mem_ce_o = `ChipEnable;
				end
			`SB_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteEnable;
				mem_ce_o = `ChipEnable;	
				mem_data_o = {{4{reg2_i[7:0]}}};
				case(mem_addr[1:0])
					2'b11:mem_sel_o = 4'b0111;
					2'b10:mem_sel_o = 4'b1011;
					2'b01:mem_sel_o = 4'b1101;
					2'b00:mem_sel_o = 4'b1110;
					default:mem_sel_o = 4'b1111;
				endcase
			end
			`SW_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteEnable;
				mem_data_o = reg2_i;
				mem_ce_o = `ChipEnable;	
			end	
		endcase
	end		
end

endmodule	
