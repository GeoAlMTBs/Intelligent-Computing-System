`include "../mycpu.h"

module id_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    input                           issue_allowin,
    //fifo
    input                           fifo_to_ds_valid_0,
    input                           fifo_to_ds_valid_1,
    input  [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_0  ,
    input  [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_1  ,
    output [ 1                :0]   issue_mode,
    //to issue
    output                          ds_to_issue_valid_0,
    output                          ds_to_issue_valid_1,
    output [`DECODE_BUS_WD -1:0]    ds_to_issue_bus_0 ,
    output [`DECODE_BUS_WD -1:0]    ds_to_issue_bus_1 ,

    //from cp0
    input                           has_int     
);



//==============================================================================

id_sub id_sub_0(
    //input
    .fifo_to_ds_valid               (fifo_to_ds_valid_0 ),
    .fifo_to_ds_bus                 (fifo_to_ds_bus_0   ),
    //output
    .decode_bus                     (ds_to_issue_bus_0       ),

    //from cp0
    .has_int                        (has_int            )
);

id_sub id_sub_1(
    //input
    .fifo_to_ds_valid               (fifo_to_ds_valid_1 ),
    .fifo_to_ds_bus                 (fifo_to_ds_bus_1   ),
    //output
    .decode_bus                     (ds_to_issue_bus_1       ),

    //from cp0
    .has_int                        (1'b0               )
);


assign ds_to_issue_valid_0 = fifo_to_ds_valid_0;
assign ds_to_issue_valid_1 = fifo_to_ds_valid_1;
assign issue_mode   = (fifo_to_ds_valid_0 & fifo_to_ds_valid_1 & issue_allowin) ? `DUAL
                    : (fifo_to_ds_valid_0 & issue_allowin) ? `SIGNLE
                    : 0;



// assign simple_es_bus = {
//                         ds_pd_pc         ,  //250:219
//                         b_or_j           ,  //218
//                         br_real_target   ,  //217:186
//                         src2_is_0imm     ,  //150:150
//                         ds_rs2           ,  //149:145
//                         ds_rs1           ,  //144:140
//                         alu_op           ,  //139:124
//                         load_op          ,  //123:123
//                         src1_is_sa       ,  //122:122
//                         src1_is_pc       ,  //121:121
//                         src2_is_imm      ,  //120:120
//                         src2_is_8        ,  //119:119
//                         gr_we            ,  //118:118
//                         dest             ,  //116:112
//                         imm              ,  //111:96
//                         br_src1          ,  //95 :64
//                         br_src2          ,  //63 :32
//                         ds_pc               //31 :0
// };


// assign complex_es_bus = {
//                         //-------exception---------
//                         overflow_en      ,  //185
//                         ds_bd            ,  //184
//                         eret_flush       ,  //183
//                         mtc0_we          ,  //182
//                         cp0_addr         ,  //181:174
//                         ds_res_from_cp0  ,  //173
//                         ds_ex            ,  //172
//                         ds_excode        ,  //171:167
//                         //-------exception---------
//                         l_is_lwl         ,  //166
//                         l_is_lwr         ,  //165
//                         l_is_lw          ,  //164
//                         l_is_lb          ,  //163
//                         l_is_lbu         ,  //162
//                         l_is_lh          ,  //161
//                         l_is_lhu         ,  //160
//                         s_is_swl         ,  //159
//                         s_is_swr         ,  //158
//                         s_is_sw          ,  //157
//                         s_is_sb          ,  //156
//                         s_is_sh          ,  //155:
//                         hi_wen           ,  //154:154
//                         lo_wen           ,  //153:153
//                         res_is_hi        ,  //152:152
//                         res_is_lo        ,  //151:151
//                         src2_is_0imm     ,  //150:150
//                         ds_rs2           ,  //149:145
//                         ds_rs1           ,  //144:140
//                         alu_op           ,  //139:124
//                         load_op          ,  //123:123
//                         src1_is_sa       ,  //122:122
//                         src1_is_pc       ,  //121:121
//                         src2_is_imm      ,  //120:120
//                         src2_is_8        ,  //119:119
//                         gr_we            ,  //118:118
//                         mem_we           ,  //117:117
//                         dest             ,  //116:112
//                         imm              ,  //111:96
//                         br_src1          ,  //95 :64
//                         br_src2          ,  //63 :32
//                         ds_pc               //31 :0
// };

// //perf_count
// reg [31:0] dual_issue_cnt;
// reg [31:0] signle_issue_cnt;
// reg [31:0] wait_cnt;
// reg [31:0] real_wait_cnt;
// reg [31:0] es_not_allowin_cnt;
// reg [31:0] ready_but_not_go_cnt;

// reg [31:0] sub0_ready_not_go_cnt;
// reg [31:0] sub1_ready_sub0_not_cnt;

// always@(posedge clk)begin
//         if(reset)begin
//                 dual_issue_cnt <= 0;
//                 signle_issue_cnt <= 0;
//         end
//         else if(issue_mode == `DUAL)begin
//                 dual_issue_cnt <= dual_issue_cnt + 1'b1;
//         end
//         else if(issue_mode == `SIGNLE)begin
//                 signle_issue_cnt <= signle_issue_cnt + 1'b1;
//         end
// end

// always@(posedge clk)begin
//         if(reset)begin
//                 wait_cnt <= 0;
//                 es_not_allowin_cnt <= 0;
//         end
//         else if((fifo_to_ds_valid_0 || fifo_to_ds_valid_1) && issue_mode == `NULL)begin
//                 wait_cnt <= wait_cnt + 1'b1;
//                 if(!es_allowin)
//                         es_not_allowin_cnt <= es_not_allowin_cnt + 1'b1;
//         end
// end

// always@(posedge clk)begin
//         if(reset)begin
//                 real_wait_cnt <= 0;
//         end
//         else if(fifo_to_ds_valid_0 && issue_mode == `NULL)begin
//                 real_wait_cnt <= real_wait_cnt + 1'b1;
//         end
// end


// always@(posedge clk)begin
//         if(reset)begin
//                 ready_but_not_go_cnt <= 0;
//         end
//         else if((sub_0_ready_go && fifo_to_ds_valid_0 && sub_1_ready_go && fifo_to_ds_valid_1) && issue_mode == `NULL)begin
//                 ready_but_not_go_cnt <= ready_but_not_go_cnt + 1'b1;
//         end
// end

// always@(posedge clk)begin
//         if(reset)begin
//                 sub1_ready_sub0_not_cnt <= 0;
//         end
//         else if((!sub_0_ready_go && sub_1_ready_go && fifo_to_ds_valid_0 && fifo_to_ds_valid_1) && issue_mode == `NULL)begin
//                 sub1_ready_sub0_not_cnt <= sub1_ready_sub0_not_cnt + 1'b1;
//         end
// end

// always@(posedge clk)begin
//         if(reset)begin
//                 sub0_ready_not_go_cnt <= 0;
//         end
//         else if(sub_0_ready_go && fifo_to_ds_valid_0 && issue_mode == `NULL)begin
//                 sub0_ready_not_go_cnt <= sub0_ready_not_go_cnt + 1'b1;
//         end
// end
        

endmodule
