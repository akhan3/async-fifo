module wlogic #
(
    parameter     AWIDTH = 4
)
(
    input                   wclk,   // writing circuit's clock
    input                   arst_n, // asynchronous reset
    input                   wdv,    // data valid signal. Writing circuit must assert this signa to have the data registered
    input      [AWIDTH:0]   rgray,  // gray read pointer from reader to writer (for safe synchronization across clock domains)
    output     [AWIDTH:0]   wgray,  // gray write pointer from  writer to reader (for safe synchronization across clock domains)
    output     [AWIDTH-1:0] waddr,  // write address for the FIFO buffer
    output reg              wfull,  // FIFO full indicator for the writing circuit
    output                  wen     // enable signal to register the write data to FIFO buffer
);


// internal nets
    reg [AWIDTH:0]  rgray_step1;        // sync version
    reg [AWIDTH:0]  rgray_wsync;        // double-sync version
    wire [AWIDTH:0] rgray_wsync_bin;    // binary converted
    reg [AWIDTH:0]  wbincounter;        // binary write pointer (extra MSB tracks wrapping around)
    wire [AWIDTH:0] wbincounter_next;   // next state combinational signal

    assign waddr = wbincounter[AWIDTH-1:0]; // write address for the FIFO buffer (lower bits of binary write pointer)
    assign wen = wdv && !wfull;             // enable when the writer has valid data and FIFO is not full


// Synchronize rgray in wclk domain
// rgray --> FF --> FF --> rgray_wsync
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n) begin
            rgray_step1 <= 0;
            rgray_wsync  <= 0;
        end else begin
            rgray_step1 <= rgray;
            rgray_wsync <= rgray_step1;
        end
    end


// binary counter
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n)
            wbincounter <= 0;
        else
            wbincounter <= wbincounter_next;
    end

    assign wbincounter_next = (wdv && !wfull) ? (wbincounter + 1'b1) : wbincounter;
    // assign wbincounter_next = wbincounter + (wdv && !wfull);


// binary to gray conversion
    bin2gray #(.SIZE(AWIDTH+1))
        bin2gray (
            .bin       (wbincounter ),
            .gray      (wgray       )
        );

// gray to binary conversion
    gray2bin #(.SIZE(AWIDTH+1))
        gray2bin (
            .gray      (rgray_wsync         ),
            .bin       (rgray_wsync_bin)
        );


// Full logic
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n)
            wfull <= 0;
        else begin
            // if the write pointer catches upto the read pointer
            // if the write pointer has wrapped around and reaches the read pointer
            // The extra MSB will be different in such case
            wfull <= (rgray_wsync_bin == {~wbincounter_next[AWIDTH], wbincounter_next[AWIDTH-1:0]});
        end
    end




endmodule
