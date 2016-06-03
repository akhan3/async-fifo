`timescale 1ns/100ps

module sim;

parameter DWIDTH = 16;
parameter AWIDTH = 5;

// connecting nets
wire                  arst_n;
wire                  wclk;
wire                  rclk;
wire                  fifo_wdv;
wire                  fifo_rdv;
wire  [DWIDTH-1:0]    fifo_wdata;
wire                  fifo_full;
wire                  fifo_ren;
wire  [DWIDTH-1:0]    fifo_rdata;
wire                  fifo_empty;

top_dual_fifo  #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
)
  dut
(
        .arst_n (arst_n        ),
        .wclk   (wclk          ),
        .rclk   (rclk          ),
        .wdv    (fifo_wdv      ),
        .rdv    (fifo_rdv      ),
        .wdata  (fifo_wdata    ),
        .wfull  (fifo_full     ),
        .rrq    (fifo_rrq      ),
        .rdata  (fifo_rdata    ),
        .rempty (fifo_empty    )
);

tester #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
)
    tester
(
        .wclk       (wclk         ),
        .rclk       (rclk         ),
        .arst_n     (arst_n       ),
        .fifo_full  (fifo_full    ),
        .fifo_wdv   (fifo_wdv     ),
        .fifo_rdv   (fifo_rdv     ),
        .fifo_wdata (fifo_wdata   ),
        .fifo_empty (fifo_empty   ),
        .fifo_rdata (fifo_rdata   ),
        .fifo_rrq   (fifo_rrq     )
);



endmodule

