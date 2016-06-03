// TOP-level module
module top_dual_fifo #
(
    parameter     AWIDTH = 3,
    parameter     DWIDTH = 16
)
(
    input                   arst_n, // asynchronous reset

    input                   wclk,   // writing circuit's clock
    input                   wdv,    // data valid signal. Writing circuit must assert this signa to have the data registered
    input   [DWIDTH-1:0]    wdata,  // data to be written by the writing circuit
    output                  wfull,  // FIFO full indicator for the writing circuit

    input                   rclk,   // reading circuit's clock
    input                   rrq,    // data request signal. Reading circuit must assert this to indicate that it can accept the data on the data bus
    output  [DWIDTH-1:0]    rdata,  // data to be read by the reading circuit
    output                  rempty, // FIFO empty indicator for the reading circuit
    output                  rdv     // data valid signal. Reading circuit can safely register the data on the data bus
);


    // internal nets
    wire [AWIDTH:0]     rgray;
    wire [AWIDTH:0]     wgray;
    wire [AWIDTH-1:0]   waddr;
    wire [AWIDTH-1:0]   raddr;
    wire                wen;
    wire                ren;


// Write logic
wlogic  #(.AWIDTH(AWIDTH))
  wlogic
(
    .wclk       (wclk   ),
    .arst_n     (arst_n ),
    .wdv        (wdv    ),
    .rgray      (rgray  ),
    .wgray      (wgray  ),
    .waddr      (waddr  ),
    .wfull      (wfull  ),
    .wen        (wen    )
);

// Read logic
rlogic  #(.AWIDTH(AWIDTH))
  rlogic
(
    .rclk       (rclk   ),
    .arst_n     (arst_n ),
    .rrq        (rrq    ),
    .wgray      (wgray  ),
    .rgray      (rgray  ),
    .raddr      (raddr  ),
    .rempty     (rempty ),
    .ren        (ren    )
);


// Dual-port block RAM for FIFO buffer
dualport_ram  #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
)
  dualport_ram
(
    .arst_n  (arst_n  ),
    .wclk    (wclk    ),
    .wen     (wen     ),
    .waddr   (waddr   ),
    .wdata   (wdata   ),
    .rclk    (rclk    ),
    .raddr   (raddr   ),
    .rdata   (rdata   ),
    .ren     (ren     ),
    .rdv     (rdv     )
);


endmodule
