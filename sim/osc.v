`timescale 1ns/100ps

module osc (
    input           enable,
    input [31:0]    period,
    input [31:0]    phase_offset,
    output reg      clk
);

real half_period;

always @(period) begin
    half_period = period / 2;
end


initial begin
    clk = 1'b0;
    repeat(2) #(phase_offset);
    $display ("SIM %0t ns: initial clock phase offset = %d", $time, phase_offset);
    forever begin
        if (enable)
            #(half_period) clk = ~clk;
        else
            #(half_period);
    end
end


endmodule
