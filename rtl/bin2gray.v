module bin2gray #
(
    parameter SIZE = 4
)
(
    input  [SIZE-1:0] bin,
    output [SIZE-1:0] gray
);

    assign gray = bin ^ (bin >> 1);

endmodule
