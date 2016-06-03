`timescale 1ns/100ps

module tester #
(
    parameter     AWIDTH = 4,
    parameter     DWIDTH = 8
)
(
    output                      wclk,
    output                      rclk,
    output reg                  arst_n,

    input                       fifo_full,
    input                       fifo_rdv,
    output reg                  fifo_wdv,
    output reg  [DWIDTH-1:0]    fifo_wdata,

    input                       fifo_empty,
    input  [DWIDTH-1:0]         fifo_rdata,
    output reg                  fifo_rrq
);



task sync_wclk;
    begin
        @(posedge wclk);
    end
endtask

task sync_rclk;
    begin
        @(posedge rclk);
    end
endtask


// data will fill the FIFO buffer many times over
parameter data_length = 2**AWIDTH * 107 + 5;

integer watchdog_timer;
reg [31:0] period_wclk;
reg [31:0] period_rclk;
reg [31:0] phase_offset_wclk;
reg [31:0] phase_offset_rclk;


// Slow production (write), fast consumption (read)
initial begin
    period_wclk = 71 * 2;   // both half-periods are prime numbers
    period_rclk = 29 * 2;
    phase_offset_wclk = 0;
    phase_offset_rclk = 10;
end

osc osc_wclk (
    .enable         (1'b1               ),
    .period         (period_wclk        ),
    .phase_offset   (phase_offset_wclk  ),
    .clk            (wclk               )
);

osc osc_rclk (
    .enable         (1'b1               ),
    .period         (period_rclk        ),
    .phase_offset   (phase_offset_rclk  ),
    .clk            (rclk               )
);

    // open file for reading and writing data
    integer fhw, fhr;
    initial begin
        fhw = $fopen("log_wdata.txt","w");
        fhr = $fopen("log_rdata.txt","w");
    end

    integer i, j, k, l, m;
    wire [31:0] long_period;
    assign long_period = (period_wclk > period_rclk) ? period_wclk : period_rclk;

    reg por_done; // status of power-on reset
    reg sim_done; // status of running simulation
    reg mismatch; // indicates verification failure
    reg [DWIDTH-1:0] testmem_r [0:data_length-1];
    reg [DWIDTH-1:0] testmem_w [0:data_length-1];

    // power-on reset
    initial begin
        $display ("SIM %0t ns: Waiting for power-on reset (POR)", $time);
            watchdog_timer = $time;
            arst_n = 1'bx;
            por_done = 1'bx;
            sim_done = 1'bx;
        repeat(2) #(long_period * 4);
            arst_n = 1'b0;
            por_done = 1'b0;
            sim_done = 1'b0;
        #(long_period * 3)
            arst_n = 1'b1;
        #(long_period * 5)
            por_done = 1;
    end


    initial begin
        fifo_wdv = 0;
        fifo_wdata = 'bx;
        fifo_rrq = 0;
    end

    initial begin
        wait(por_done); // wait for power-on reset to complete
        $display ("SIM %0t ns: Initialize and POR complete", $time);

//===========================================================================
// Main testbench activity starts below
//===========================================================================
repeat (5) #(long_period);

fork

    // writing to FIFO
    begin
        for (i = 0; i < data_length; i = i+1) begin
            @(posedge wclk)
            fifo_wdv = 1;
            // fifo_wdata = i[DWIDTH-1:0]; // fifo_wdata = 8'd65 + i[DWIDTH-1:0];
            fifo_wdata = $random;
            $display("SIM %0t ns: WR_data = %h", $time, fifo_wdata);
            $fdisplay(fhw, "%d", fifo_wdata);
            @(negedge wclk)

            // Do not write on the full buffer
            if(fifo_full)  begin
                fifo_wdv = 0;
                wait(!fifo_full);
                fifo_wdv = 1;
            end

            // stop writing. Let the buffer drain (go empty)
            if(j == data_length/4 || i == (data_length/4)*3) begin
                fifo_wdv  = 0;
                wait(fifo_empty);
                fifo_wdv  = 1;
            end
        end

        @(posedge wclk)
        fifo_wdv = 0;
    end


    // reading from FIFO
    begin
        // wait a while before start reading
        wait(i > (1 + 2**AWIDTH / 2));
        for (j = 0; j < data_length; j = j+1) begin
            @(posedge rclk);
            fifo_rrq = 1;
            wait(fifo_rdv);

            // Do not read from the empty buffer
            if(fifo_empty) begin
                fifo_rrq  = 0;
                wait(!fifo_empty);
                fifo_rrq  = 1;
            end

            // stop reading. Let the buffer fill
            if(i == (data_length/3)*2) begin
                fifo_rrq  = 0;
                wait(fifo_full);
                fifo_rrq  = 1;
            end

            // Swap the read/write speed
            // Fast production (write), slow consumption (read)
            if (j == data_length/2) begin
                period_wclk <= period_rclk;
                period_rclk <= period_wclk;
            end
        end

        #(long_period * 10);
        sim_done = 1;
    end


    // logging read_data to file
    begin
        forever begin
            @(posedge rclk)
            if(fifo_rdv) begin
                $display("SIM %0t ns: RD_data = %h", $time, fifo_rdata);
                $fdisplay(fhr, "%d", fifo_rdata);
            end
        end
    end

    // catch the sim_done signal and compare files
    begin
        wait(sim_done);

        // close the files and open again
        $fclose(fhw);
        $fclose(fhr);

        fhw = $fopen("log_wdata.txt","r");
        fhr = $fopen("log_rdata.txt","r");

        for (i = 0; i < data_length; i = i+1) begin
            k = $fscanf(fhw, "%d", testmem_w[i]);
            k = $fscanf(fhr, "%d", testmem_r[i]);
            $display("SIM: (WR, RD)[%2d] = (%h, %h) %s", i, testmem_w[i], testmem_r[i], (testmem_r[i] != testmem_w[i]) ? "MISMATCH" : "MATCH");
            mismatch = mismatch  || (testmem_r[i] != testmem_w[i]);
        end

        $fclose(fhr);
        $fclose(fhw);

        if(mismatch)
            $display("SIM ERROR: There was a mismatch between sent and received data. FIFO verification failed!");
        else
            $display("SIM SUCCESS: Data received as sent. FIFO verified successfully!");



        $display ("SIM %0t ns: Simulation completed", $time);
        // $stop;
    end


join
//===========================================================================
// Main testbench activity ends above
//===========================================================================




        $display ("SIM: Total Simulation time = %0d", $time);
        // $stop;
    end


    // reset watchdog timer on any activity
    always @(fifo_wdata, fifo_rdata, fifo_rdv, fifo_wdv, fifo_full, fifo_empty) begin
        watchdog_timer = $time;
    end

    // trigger watchdog timer after a long period of inactivity
    initial begin
        forever begin
            #(long_period*300)
            if ($time - watchdog_timer > long_period*300) begin
                $display ("SIM %0t ns: Watchdog timer activated", $time);
                $stop;
            end
        end

    end




endmodule
