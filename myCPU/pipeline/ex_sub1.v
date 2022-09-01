`include "../mycpu.h"

module ex_sub1(
    input                               clk,
    input                               reset,
    input                               es_valid,

    input  [`SIMPLE_ES_BUS_WD -1:0]     ds_to_es_bus,
    output [`ES_TO_M1S_BUS1_WD -1:0]    es_to_m1s_bus,
    output [`ES_FWD_BUS-1 :0]           es_fwd_bus,

    output [`BR_BUS_WD-1:0]             es_br_bus,
    output [31:0]                       es_pc,
    output                              es_b_or_j              
);

wire [15:0] es_alu_op       ;
wire        es_load_op      ;
wire        es_src1_is_sa   ;  
wire        es_src1_is_pc   ;
wire        es_src2_is_imm  ;
wire        es_src2_is_0imm ; 
wire        es_src2_is_8    ;
wire        es_gr_we        ;
wire [ 4:0] es_dest         ;
wire [15:0] es_imm          ;
wire [31:0] es_rs_value     ;
wire [31:0] es_rt_value     ;
wire [3:0]  es_rf_wen       ;

wire [4:0]  es_rs1;
wire [4:0]  es_rs2;



wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_final_result;

wire        es_reg_write    ;
wire [4:0]  es_rd           ;


// br bus
wire [25:0] jidx;
wire [31:0] es_pd_pc;
wire [31                 :0] br_target;
wire [31                 :0] bd_pc;
wire [31                 :0] br_real_target;
wire        br_taken;
wire [11:0] es_bj_type;
wire        prd_err;
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

assign bd_pc = es_pc + 32'h4;            //delay slot pc
assign jidx = {es_rs1,es_rs2,es_imm};
assign {inst_beq,inst_bne,inst_bltz,inst_blez,inst_bgez,inst_bgtz,inst_bltzal,inst_bgezal,inst_jal,inst_jr,inst_j,inst_jalr} = es_bj_type;

assign rs_eq_rt = (es_rs_value == es_rt_value);
assign rs_lt_zero = ($signed(es_rs_value) <  0);
assign rs_le_zero = ($signed(es_rs_value) <= 0);
assign br_taken = (   inst_beq     &  rs_eq_rt
                   | inst_bne     & !rs_eq_rt
                   | inst_blez    &  rs_le_zero
                   | inst_bltz    &  rs_lt_zero
                   | inst_bgez    & !rs_lt_zero
                   | inst_bgtz    & !rs_le_zero
                   | inst_bltzal  &  rs_lt_zero
                   | inst_bgezal  & !rs_lt_zero
                   | inst_jal
                   | inst_jr
                   | inst_j
                   | inst_jalr
) && es_valid;
assign br_target = (inst_beq | inst_bne | inst_bltz | inst_blez | inst_bgez | inst_bgtz | inst_bltzal | inst_bgezal) ? (bd_pc + {{14{es_imm[15]}}, es_imm[15:0], 2'b0}) :
                   (inst_jr | inst_jalr)              ? es_rs_value :
                  /*inst_jal??inst_j*/              {bd_pc[31:28], jidx[25:0], 2'b0};

assign prd_err = es_b_or_j && (es_pd_pc != br_real_target);
assign br_real_target = br_taken ? br_target : es_pc+4'h8;
assign es_br_bus = {prd_err,br_real_target};

wire   es_first;

assign {
        es_first            ,  //195
        es_pd_pc            ,  //194:163
        es_b_or_j           ,  //162
        es_bj_type          ,  //161:150

        es_src2_is_0imm     ,  //149
        es_rs2              ,  //148:144
        es_rs1              ,  //143:139
        es_alu_op           ,  //138:123
        es_load_op          ,  //122
        es_src1_is_sa       ,  //121
        es_src1_is_pc       ,  //120
        es_src2_is_imm      ,  //119
        es_src2_is_8        ,  //118
        es_gr_we            ,  //117
        es_dest             ,  //116:112
        es_imm              ,  //111:96
        es_rs_value         ,  //95 :64
        es_rt_value         ,  //63 :32
        es_pc                  //31 :0
       } = ds_to_es_bus;


assign      es_rd            = es_dest;
assign      es_reg_write     = es_gr_we;
assign      es_res_from_mem  = es_load_op;


//========================= alu op =======================================

// alu result
wire [31:0] es_alu_result;

assign      es_alu_src1  = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                                         es_src1_is_pc  ? es_pc[31:0] :
                                         es_rs_value;

assign      es_alu_src2  = es_src2_is_imm ? {{16{es_imm[15]}}, es_imm[15:0]} : 
                                         es_src2_is_0imm ? {{16{1'b0}}, es_imm[15:0]} :
                                         es_src2_is_8   ? 32'd8 :
                                         es_rt_value;

alu_1 u_alu_1(
    .alu_op             (es_alu_op          ),
    .alu_src1           (es_alu_src1        ),
    .alu_src2           (es_alu_src2        ),
    .alu_result         (es_alu_result      ),
    //overflow
    .overflow_en        (1'b0     )
    );                                




// final result
assign      op_alu    = | es_alu_op[11:0];

assign      es_final_result = {32{op_alu}} & es_alu_result;


assign      es_rf_wen = {4{es_gr_we}} & 4'b1111 ;




assign es_fwd_bus = {
                    es_valid,
                    es_reg_write,
                    es_rd,
                    es_alu_result
                    };





//=================================es to m1s bus==============================================

assign es_to_m1s_bus = {
                        es_first       ,  //75
                        es_rf_wen      ,  //74:71
                        es_res_from_mem,  //70:70
                        es_gr_we       ,  //69:69
                        es_dest        ,  //68:64
                        es_final_result,  //63:32
                        es_pc             //31:0
                        };

endmodule