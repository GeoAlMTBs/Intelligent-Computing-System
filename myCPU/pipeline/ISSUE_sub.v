`include "../mycpu.h"

module issue_sub(
    //input
    input                           valid_i,
    input [`DECODE_BUS_WD -1:0]     decode_bus_i ,
    input                           first        ,
    
    output                          inst_type    , //0: simple; 1: complex
    output                          ready_go   ,
    output [`ISSUE_BUS_WD -1  :0]   issue_bus  ,
    output                          special_inst,//force to signle issue
    output                          iss_ex,
    
    input                           es_reg_write,
    output [ 4                :0]   iss_rs1      ,
    output [ 4                :0]   iss_rs2      ,
    output [ 4                :0]   iss_rd      ,
    //to regfile
    output [ 4                :0]   rf_raddr0    ,
    output [ 4                :0]   rf_raddr1    ,
    input  [31                :0]   rf_rdata0    ,
    input  [31                :0]   rf_rdata1    ,

    //forwarding
    input  [31:                 0]  es_alu_result_0,
    input  [31:                 0]  es_alu_result_1,
    input  [31:                 0]  m1s_alu_result_0,
    input  [31:                 0]  m1s_alu_result_1,
    input  [31:                 0]  m2s_alu_result_0,
    input  [31:                 0]  m2s_alu_result_1,
    input  [4                 :0]   es_rd_0,
    input  [4                 :0]   es_rd_1,
    input  [4                 :0]   m1s_rd_0       ,
    input  [4                 :0]   m1s_rd_1       ,
    input  [4                 :0]   m2s_rd_0       ,
    input  [4                 :0]   m2s_rd_1       ,
    input                           es_reg_write_0,
    input                           es_reg_write_1,
    input                           m1s_reg_write_0,
    input                           m1s_reg_write_1,
    input                           m2s_reg_write_0,
    input                           m2s_reg_write_1,
    input                           es_valid_0    ,
    input                           es_valid_1    ,
    input                           m1s_valid_0    ,
    input                           m1s_valid_1    ,
    input                           m2s_valid_0    ,
    input                           m2s_valid_1    ,

    input                           es_res_from_cp0,
    input                           m1s_res_from_cp0,
    input                           m2s_res_from_cp0,
    input                           es_mem_read,
    input                           m1s_mem_read,
    input                           m2s_mem_read,
    input                           m2s_res_from_mem_ok,

    //from cp0
    input                           has_int     ,
    //
    output                          b_or_j       ,
    input                           preinst_is_bj,
    output                          iss_bd        
);


wire                         iss_valid;
wire [31                :0]  iss_inst  ;
wire [31                :0]  iss_pc    ;
wire [31                :0]  iss_pd_pc ;
wire [4                 :0]  iss_excode;
wire                         br;

assign iss_valid = valid_i;





wire [15:0] alu_op;
wire        load_op;
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_0imm;
wire        src2_is_8;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [15:0] imm;
wire [25:0] jidx;
wire [31:0] rs_value;
wire [31:0] rt_value;
wire        res_is_hi;
wire        res_is_lo;
wire        hi_wen;
wire        lo_wen;
wire        eret_flush;
wire        mtc0_we;
wire [7:0]  cp0_addr;
wire        iss_res_from_cp0;
wire        overflow_en;
wire        inst_undef;


wire        l_is_lw;
wire        l_is_lb;
wire        l_is_lbu;
wire        l_is_lh;
wire        l_is_lhu;
wire        l_is_lwl;
wire        l_is_lwr;
wire        s_is_sw;
wire        s_is_sb;
wire        s_is_sh;
wire        s_is_swl;
wire        s_is_swr;

wire [11:0] bj_type;
wire        rs_eq_rt;
wire        rs_le_zero;
wire        rs_lt_zero;
wire        inst_bne;
wire        inst_blez;
wire        inst_bltz;
wire        inst_bgez;
wire        inst_bgtz;
wire        inst_bltzal;
wire        inst_bgezal;
wire        inst_jal;
wire        inst_jr;
wire        inst_j;
wire        inst_jalr;




assign   {
        special_inst     ,  //167
        inst_type        ,  //166
        bj_type          ,  //165:154
        iss_pd_pc        ,  //153:122
        b_or_j           ,  //121
        //-------exception---------
        overflow_en      ,  //120
        eret_flush       ,  //119
        mtc0_we          ,  //118
        cp0_addr         ,  //117:110
        iss_res_from_cp0  ,  //109
        iss_ex            ,  //108
        iss_excode        ,  //107:103
        //-------exception---------
        l_is_lwl         ,  //102
        l_is_lwr         ,  //101
        l_is_lw          ,  //100
        l_is_lb          ,  //99
        l_is_lbu         ,  //98
        l_is_lh          ,  //97
        l_is_lhu         ,  //96
        s_is_swl         ,  //95
        s_is_swr         ,  //94
        s_is_sw          ,  //93
        s_is_sb          ,  //92
        s_is_sh          ,  //91
        hi_wen           ,  //90
        lo_wen           ,  //89
        res_is_hi        ,  //88
        res_is_lo        ,  //87
        src2_is_0imm     ,  //86
        iss_rs2           ,  //85:81
        iss_rs1           ,  //80:76
        alu_op           ,  //75:60
        load_op          ,  //59
        src1_is_sa       ,  //58
        src1_is_pc       ,  //57
        src2_is_imm      ,  //56
        src2_is_8        ,  //55
        gr_we            ,  //54
        mem_we           ,  //53
        dest             ,  //52:48
        imm              ,  //47:32
        iss_pc               //31 :0
        } = decode_bus_i;

assign {inst_beq,inst_bne,inst_bltz,inst_blez,inst_bgez,inst_bgtz,inst_bltzal,inst_bgezal,inst_jal,inst_jr,inst_j,inst_jalr} = bj_type;





assign iss_rd   = dest;
assign jidx     = {iss_rs1,iss_rs2,imm};
assign rf_raddr0 = iss_rs1;
assign rf_raddr1 = iss_rs2;
assign rs_value = rf_rdata0;
assign rt_value = rf_rdata1;

//============================ forwarding =======================================
wire                         es_rd_after_wr;
wire                         m1s_rd_after_wr;
wire                         m2s_rd_after_wr;


wire [31                 :0] br_target;
wire [31                 :0] bd_pc;
wire [31                 :0] br_src1;
wire [31                 :0] br_src2;
wire [31                 :0] br_real_target;

assign ready_go        = !iss_valid || !(es_rd_after_wr | m1s_rd_after_wr | m2s_rd_after_wr);
assign es_rd_after_wr  = (es_res_from_cp0  | es_mem_read )  && (es_rd_0  == iss_rs1 || es_rd_0  == iss_rs2) && es_rd_0 != 0;
assign m1s_rd_after_wr = (m1s_res_from_cp0 | m1s_mem_read)  && (m1s_rd_0 == iss_rs1 || m1s_rd_0 == iss_rs2) && m1s_rd_0 != 0;
assign m2s_rd_after_wr = (m2s_res_from_cp0 | m2s_mem_read)  && (m2s_rd_0 == iss_rs1 || m2s_rd_0 == iss_rs2) && m2s_rd_0 != 0;


assign br_src1 = !(iss_valid) ? rf_rdata0
               : ((iss_rs1 == es_rd_0)  && (es_rd_0 != 5'd0)  && es_reg_write_0  && es_valid_0)  ? es_alu_result_0
               : ((iss_rs1 == es_rd_1)  && (es_rd_1 != 5'd0)  && es_reg_write_1  && es_valid_1)  ? es_alu_result_1
               : ((iss_rs1 == m1s_rd_0) && (m1s_rd_0 != 5'd0) && m1s_reg_write_0 && m1s_valid_0) ? m1s_alu_result_0
               : ((iss_rs1 == m1s_rd_1) && (m1s_rd_1 != 5'd0) && m1s_reg_write_1 && m1s_valid_1) ? m1s_alu_result_1
               : ((iss_rs1 == m2s_rd_0) && (m2s_rd_0 != 5'd0) && m2s_reg_write_0 && m2s_valid_0) ? m2s_alu_result_0
               : ((iss_rs1 == m2s_rd_1) && (m2s_rd_1 != 5'd0) && m2s_reg_write_1 && m2s_valid_1) ? m2s_alu_result_1
               : rf_rdata0;

assign br_src2 = !(iss_valid) ? rf_rdata1
               : ((iss_rs2 == es_rd_0)  && (es_rd_0 != 5'd0)  && es_reg_write_0  && es_valid_0)  ? es_alu_result_0
               : ((iss_rs2 == es_rd_1)  && (es_rd_1 != 5'd0)  && es_reg_write_1  && es_valid_1)  ? es_alu_result_1
               : ((iss_rs2 == m1s_rd_0) && (m1s_rd_0 != 5'd0) && m1s_reg_write_0 && m1s_valid_0) ? m1s_alu_result_0
               : ((iss_rs2 == m1s_rd_1) && (m1s_rd_1 != 5'd0) && m1s_reg_write_1 && m1s_valid_1) ? m1s_alu_result_1
               : ((iss_rs2 == m2s_rd_0) && (m2s_rd_0 != 5'd0) && m2s_reg_write_0 && m2s_valid_0) ? m2s_alu_result_0
               : ((iss_rs2 == m2s_rd_1) && (m2s_rd_1 != 5'd0) && m2s_reg_write_1 && m2s_valid_1) ? m2s_alu_result_1
               : rf_rdata1;



assign bd_pc = iss_pc + 32'h4;            //delay slot pc
assign iss_bd = preinst_is_bj;

// assign rs_eq_rt = (br_src1 == br_src2);
// assign rs_lt_zero = ($signed(br_src1) <  0);
// assign rs_le_zero = ($signed(br_src1) <= 0);
// assign br_taken = (   inst_beq     &  rs_eq_rt
//                    | inst_bne     & !rs_eq_rt
//                    | inst_blez    &  rs_le_zero
//                    | inst_bltz    &  rs_lt_zero
//                    | inst_bgez    & !rs_lt_zero
//                    | inst_bgtz    & !rs_le_zero
//                    | inst_bltzal  &  rs_lt_zero
//                    | inst_bgezal  & !rs_lt_zero
//                    | inst_jal
//                    | inst_jr
//                    | inst_j
//                    | inst_jalr
// ) && iss_valid;
// assign br_target = (inst_beq | inst_bne | inst_bltz | inst_blez | inst_bgez | inst_bgtz | inst_bltzal | inst_bgezal) ? (bd_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
//                    (inst_jr | inst_jalr)              ? br_src1 :
//                   /*inst_jal??inst_j*/              {bd_pc[31:28], jidx[25:0], 2'b0};
//  BHT
// assign br_real_target = br_taken ? br_target : iss_pc+4'h8;
// assign br_prd_err = iss_valid && b_or_j && (br_real_target != iss_pd_pc);
//========exception=========



assign issue_bus   = {
                        first             , //231
                        iss_pd_pc         ,  //230:199
                        b_or_j           ,  //198
                        bj_type          ,  //197:186
                        //-------exception---------
                        overflow_en      ,  //185
                        iss_bd            ,  //184
                        eret_flush       ,  //183
                        mtc0_we          ,  //182
                        cp0_addr         ,  //181:174
                        iss_res_from_cp0  ,  //173
                        iss_ex            ,  //172
                        iss_excode        ,  //171:167
                        //-------exception---------
                        l_is_lwl         ,  //166
                        l_is_lwr         ,  //165
                        l_is_lw          ,  //164
                        l_is_lb          ,  //163
                        l_is_lbu         ,  //162
                        l_is_lh          ,  //161
                        l_is_lhu         ,  //160
                        s_is_swl         ,  //159
                        s_is_swr         ,  //158
                        s_is_sw          ,  //157
                        s_is_sb          ,  //156
                        s_is_sh          ,  //155:
                        hi_wen           ,  //154
                        lo_wen           ,  //153
                        res_is_hi        ,  //152
                        res_is_lo        ,  //151
                        src2_is_0imm     ,  //150
                        iss_rs2           ,  //149:145
                        iss_rs1           ,  //144:140
                        alu_op           ,  //139:124
                        load_op          ,  //123:123
                        src1_is_sa       ,  //122:122
                        src1_is_pc       ,  //121:121
                        src2_is_imm      ,  //120:120
                        src2_is_8        ,  //119:119
                        gr_we            ,  //118:118
                        mem_we           ,  //117:117
                        dest             ,  //116:112
                        imm              ,  //111:96
                        br_src1          ,  //95 :64
                        br_src2          ,  //63 :32
                        iss_pc               //31 :0
                    };
        

endmodule
