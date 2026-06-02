module analyzer(

    input wire clk,

    input wire ext_in_0,
    input wire ext_in_1,

    output wire osc_enable,

    output wire bridge_out_14,
    output wire bridge_en_14,

    output wire bridge_out_15,
    output wire bridge_en_15

);

assign osc_enable = 1'b1;

assign bridge_en_14 = 1'b1;
assign bridge_en_15 = 1'b1;

reg chA_ff1 = 1'b1;
reg chA_ff2 = 1'b1;

reg chB_ff1 = 1'b1;
reg chB_ff2 = 1'b1;

always @(posedge clk)
begin

    chA_ff1 <= ext_in_0;
    chA_ff2 <= chA_ff1;

    chB_ff1 <= ext_in_1;
    chB_ff2 <= chB_ff1;

end

assign bridge_out_14 = chA_ff2;
assign bridge_out_15 = chB_ff2;

endmodule
