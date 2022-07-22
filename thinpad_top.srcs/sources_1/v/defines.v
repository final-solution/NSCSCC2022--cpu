//全局
`define ZeroWord 32'h00000000
`define RstEnable 1'b1
`define RstDisable 1'b0
`define WriteEnable 1'b0
`define WriteDisable 1'b1
`define ReadEnable 1'b0
`define ReadDisable 1'b1
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Branch 1'b1
`define NotBranch 1'b0
`define ChipEnable 1'b0
`define ChipDisable 1'b1
`define AluOpBus 7:0
`define AluSelBus 2:0


//译码阶段使用的操作码
//逻辑运算指令
`define AND  6'b100100
`define ANDI 6'b001100
`define OR   6'b100101
`define ORI  6'b001101
`define XOR 6'b100110
`define XORI 6'b001110
`define LUI 6'b001111

//移位指令
`define SLL  6'b000000
`define SLLV  6'b000100
`define SRL  6'b000010
`define SRLV  6'b000110
`define SRA  6'b000011
`define SRAV  6'b000111

//算术运算指令
`define ADD  6'b100000
`define ADDI  6'b001000
`define ADDU  6'b100001
`define ADDIU  6'b001001
`define SUB  6'b100010
`define SLT  6'b101010
`define MUL  6'b000010

//分支跳转指令
`define J  6'b000010
`define JAL  6'b000011
`define JALR  6'b001001
`define JR  6'b001000
`define BEQ  6'b000100
`define BNE  6'b000101
`define BGEZ  5'b00001
`define BGTZ  6'b000111
`define BLEZ  6'b000110
`define BLTZ  5'b00000

//访存指令
`define LB  6'b100000
`define LW  6'b100011
`define SB  6'b101000
`define SW  6'b101011

//空指令
`define NOP 6'b000000

//部分指令的op操作码
`define EXE_SPECIAL_INST 6'b000000
`define EXE_REGIMM_INST 6'b000001
`define EXE_SPECIAL2_INST 6'b011100

//执行阶段使用的操作码
//逻辑运算指令
`define AND_OP   8'b00100100
`define OR_OP    8'b00100101
`define XOR_OP  8'b00100110
`define LUI_OP  8'b01011100   

//移位指令
`define SLL_OP  8'b01111100
`define SRL_OP  8'b00000010
`define SRA_OP  8'b00000011

//算术运算指令
`define SLT_OP  8'b00101010 
`define ADD_OP  8'b00100000
`define ADDU_OP  8'b00100001
`define SUB_OP  8'b00100010
`define MUL_OP  8'b10101001

//访存指令，但是用在访存阶段
`define LB_OP  8'b11100000
`define LW_OP  8'b11100011
`define SB_OP  8'b11101000
`define SW_OP  8'b11101011

//空指令
`define NOP_OP    8'b00000000

//运算结果选择AluSel
`define RES_NOP 3'b000
`define RES_LOGIC 3'b001
`define RES_SHIFT 3'b010
`define RES_ARITHMETIC 3'b011	
`define RES_MUL 3'b100
`define RES_JUMP_BRANCH 3'b101
`define RES_LOAD_STORE 3'b110	


//指令存储器inst_rom
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17

//数据存储器data_ram
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 131071
`define DataMemNumLog2 17
`define ByteWidth 7:0


//通用寄存器regfile
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000
`define DoubleRegBus 63:0
