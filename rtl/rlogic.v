module rlogic #
(
    parameter     AWIDTH = 4
)
(
    input                   rclk,   // reading circuit's clock
    input                   arst_n, // asynchronous reset
    input                   rrq,    // data request signal. Reading circuit must assert this to indicate that it can accept the data on the data bus
    input      [AWIDTH:0]   wgray,  // gray write pointer from writer to reader (for safe synchronization across clock domains)
    output     [AWIDTH:0]   rgray,  // gray read pointer from reader to writer  (for safe synchronization across clock domains)
    output     [AWIDTH-1:0] raddr,  // read address for the FIFO buffer
    output reg              rempty, // FIFO empty indicator for the reading circuit
    output                  ren     // enable signal to update the read bus from FIFO buffer
);


// internal nets
    reg [AWIDTH:0]  wgray_step1;        // sync version
    reg [AWIDTH:0]  wgray_rsync;        // double-sync version
    wire [AWIDTH:0] wgray_rsync_bin;    // binary converted
    reg [AWIDTH:0]  rbincounter;        // binary read pointer (extra MSB tracks wrapping around)
    wire [AWIDTH:0] rbincounter_next;   // next state combinational signal

    assign raddr = rbincounter[AWIDTH-1:0]; // read address for the FIFO buffer (lower bits of binary read pointer)
    assign ren = rrq && !rempty;            // enable when the reader is requesting and FIFO is not empty


// Synchronize wgray in rclk domain
// wgray --> FF --> FF --> wgray_rsync
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n) begin
            wgray_step1 <= 0;
            wgray_rsync  <= 0;
        end else begin
            wgray_step1 <= wgray;
            wgray_rsync <= wgray_step1;
        end
    end


// binary counter
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n)
            rbincounter <= 0;
        else
            rbincounter <= rbincounter_next;
    end

    assign rbincounter_next = (rrq && !rempty) ? (rbincounter + 1'b1) : rbincounter;
    // assign rbincounter_next = rbincounter + (rrq && !rempty);


// binary to gray conversion
    bin2gray #(.SIZE(AWIDTH+1))
        bin2gray (
            .bin       (rbincounter ),
            .gray      (rgray       )
        );

// gray to binary conversion
    gray2bin #(.SIZE(AWIDTH+1))
        gray2bin (
            .gray      (wgray_rsync         ),
            .bin       (wgray_rsync_bin)
        );


// Empty logic
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n)
            rempty <= 0;
        else begin
            // if the read pointer catches upto the write pointer
            // if both the pointers have wrapped around the same number of times
            rempty <= (wgray_rsync_bin == rbincounter_next);
        end
    end




endmodule
