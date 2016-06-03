module gray2bin #
(
    parameter SIZE = 4
)
(
    input      [SIZE-1:0] gray,
    output reg [SIZE-1:0] bin
);

    integer k;

    always @* begin // combinational logic
        for (k = 0; k < SIZE; k = k+1) begin
            bin[k] = ^(gray >> k);
        end
    end


endmodule
