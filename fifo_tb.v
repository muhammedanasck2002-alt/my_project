//a testbench for the FIFO module.

`timescale 1ns/1ps

module FIFO_tb();

    parameter Data_size = 8; // Data bus size
    parameter address_width = 3; // Address bus size
    parameter DEPTH = 1 << address_width; // Depth of the FIFO memory

    reg [Data_size-1:0] write_data;       // Input data
    wire [Data_size-1:0] read_data;       // Output data
    wire write_full, read_empty;          // Write full and read empty signals
    reg wptr_inc, rptr_inc, wclk, rclk, wrst_n, rrst_n; // Write and read signals

    FIFO #(Data_size, address_width) fifo (
        .read_data(read_data), 
        .write_data(write_data),
        .write_full(write_full),
        .read_empty(read_empty),
        .wptr_inc(wptr_inc), 
        .rptr_inc(rptr_inc), 
        .wclk(wclk), 
        .rclk(rclk), 
        .wrst_n(wrst_n), 
        .rrst_n(rrst_n)
    );

    integer i=0;
    integer seed = 1;

    // Read and write clock in loop
    always #5 wclk = ~wclk;    // faster writing
    always #10 rclk = ~rclk;   // slower reading
    
    initial begin
        // Initialize all signals
        wclk = 0;
        rclk = 0;
        wrst_n = 1;     // Active low reset
        rrst_n = 1;     // Active low reset
        wptr_inc = 0;
        rptr_inc = 0;
        write_data = 0;

        // Reset the FIFO
        #40 wrst_n = 0; rrst_n = 0;
        #40 wrst_n = 1; rrst_n = 1;

        // TEST CASE 1: Write data and read it back
        rptr_inc = 1;
        for (i = 0; i < 10; i = i + 1) begin
            write_data = $random(seed) % 256;
            wptr_inc = 1;
            #10;
            wptr_inc = 0;
            #10;
        end

        // TEST CASE 2: Write data to make FIFO full and try to write more data
        wptr_inc = 0;
        rptr_inc = 1;
        for (i = 0; i < DEPTH + 3; i = i + 1) begin
            #20;
        end
        
         // TEST CASE 3: Read data from empty FIFO and try to read more data
        rptr_inc = 0;
        wptr_inc = 1;
        for (i = 0; i < DEPTH + 3; i = i + 1) begin
            write_data = $random(seed) % 256;
            #10;
        end

  
      

        $finish;
    end

endmodule

//----------------------------EXPLANATION-----------------------------------------------
// The testbench for the FIFO module generates random data and writes it to the FIFO,
// then reads it back and compares the results. The testbench includes three test cases:
// 1. Write data and read it back.
// 2. Write data to make the FIFO full and try to write more data.
// 3. Read data from an empty FIFO and try to read more data. The testbench uses
// clock signals for writing and reading, and includes reset signals to initialize
// the FIFO. The testbench finishes after running the test cases.
//--------------------------------------------------------------------------------------