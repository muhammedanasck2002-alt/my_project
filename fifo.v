module FIFO #(parameter Data_size = 8,
    parameter address_width = 3)(
    output [Data_size-1:0] read_data,       // Output data - data to be read
    output write_full,                   // Write full signal
    output read_empty,                  // Read empty signal
    input [Data_size-1:0] write_data,        // Input data - data to be written
    input wptr_inc, wclk, wrst_n,       // Write increment, write clock, write reset
    input rptr_inc, rclk, rrst_n        // Read increment, read clock, read reset
    );

    wire [address_width-1:0] waddr, raddr;
    wire [address_width:0] wptr, rptr, wq2_rptr, rq2_wptr;

    two_ff_sync #(address_width+1) sync_r2w (       // Read pointer syncronization to write clock domain
        .q2(wq2_rptr), 
        .din(rptr),
        .clk(wclk), 
        .rst_n(wrst_n)
    );

    two_ff_sync #(address_width+1) sync_w2r (       // Write pointer syncronization to read clock domain
        .q2(rq2_wptr), 
        .din(wptr),
        .clk(rclk), 
        .rst_n(rrst_n)
    );

    FIFO_memory #(Data_size, address_width) fifomem(    // Memory module
        .read_data(read_data), 
        .write_data(write_data),
        .waddr(waddr), 
        .raddr(raddr),
        .wclk_en(wptr_inc), 
        .write_full(write_full),
        .wclk(wclk)
    );

    rptr_empty #(address_width) rptr_empty(         // Read pointer and empty signal handling
        .read_empty(read_empty),
        .raddr(raddr),
        .rptr(rptr), 
        .rq2_wptr(rq2_wptr),
        .rptr_inc(rptr_inc), 
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    wptr_full #(address_width) wptr_full(           // Write pointer and full signal handling
        .write_full(write_full), 
        .waddr(waddr),
        .wptr(wptr), 
        .wq2_rptr(wq2_rptr),
        .wptr_inc(wptr_inc), 
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

endmodule


//FIFO write pointer module with full flag.
module wptr_full #(parameter ADDR_SIZE = 4)(
    output reg write_full,                   // Full flag
    output [ADDR_SIZE-1:0] waddr,       // Write address
    output reg [ADDR_SIZE :0] wptr,     // Write pointer
    input [ADDR_SIZE :0] wq2_rptr,      // Read pointer in gray  synchronised to write clock domain
    input wptr_inc, wclk, wrst_n            // Write increment, write-clock, and reset
    );

    reg [ADDR_SIZE:0] w_bin;                     // Binary write pointer
    wire [ADDR_SIZE:0] wgray_next, w_bin_next;   // Next write pointer in gray and binary code
    wire write_full_val;                             // Full flag value
    
    // Synchronous FIFO write pointer (gray code)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)            // Reset the FIFO
            {w_bin, wptr} <= 0;
        else 
            {w_bin, wptr} <= {w_bin_next, wgray_next}; // Shift the write pointer
    end

    assign waddr = w_bin[ADDR_SIZE-1:0];             // Write address calculation from the write pointer
    assign w_bin_next = w_bin + (wptr_inc & ~write_full);       // Increment the write pointer if not full,(wptr_inc=0 initially at rest)
    assign wgray_next = (w_bin_next>>1) ^ w_bin_next;    // Convert binary to gray code

 
 
 
    // Check if the FIFO is full
    assign write_full_val = (wgray_next=={~wq2_rptr[ADDR_SIZE:ADDR_SIZE-1], wq2_rptr[ADDR_SIZE-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)            // Reset the full flag
            write_full <= 1'b0;
        else 
            write_full <= write_full_val; // Update the full flag
    end
endmodule

//FIFO read pointer Handle module with empty flag.
module rptr_empty #(parameter ADDR_SIZE = 4)(
    output reg read_empty,                  // Empty flag
    output [ADDR_SIZE-1:0] raddr,       // Read address
    output reg [ADDR_SIZE :0] rptr,     // Read pointer
    input [ADDR_SIZE :0] rq2_wptr,      // Write pointer (gray) - synchronised to read clock domain
    input rptr_inc, rclk, rrst_n            // Read increment, read-clock, and reset
    );

    reg [ADDR_SIZE:0] rbin;                     // Binary read pointer
    wire [ADDR_SIZE:0] rgray_next, rbin_next;   // Next read pointer in gray and binary code
    wire read_empty_val;                            // Empty flag value

    // Synchronous FIFO read pointer (gray code)
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)                // Reset the FIFO
            {rbin, rptr} <= 0;
        else 
            {rbin, rptr} <= {rbin_next, rgray_next};  // Shift the read pointer
    end

    assign raddr = rbin[ADDR_SIZE-1:0];                 // Read address calculation from the read pointer
    assign rbin_next = rbin + (rptr_inc & ~read_empty);         // Increment the read pointer if not empty
    assign rgray_next = (rbin_next>>1) ^ rbin_next;     // Convert binary to gray code

    // Check if the FIFO is empty
    assign read_empty_val = (rgray_next == rq2_wptr);       // Empty flag calculation

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)                // Reset the empty flag
            read_empty <= 1'b1;
        else 
            read_empty <= read_empty_val;  // Update the empty flag
    end
endmodule


module FIFO_memory #(parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 4)(
    output [DATA_SIZE-1:0] read_data,        // Output data - data to be read
    input [DATA_SIZE-1:0] write_data,         // Input data - data to be written
    input [ADDR_SIZE-1:0] waddr, raddr,     // Write and read address
    input wclk_en, write_full, wclk          // Write clock enable, write full, write clock
    );

    localparam DEPTH = 1<<ADDR_SIZE;     // Depth of the FIFO memory
    reg [DATA_SIZE-1:0] mem [0:DEPTH-1];// Memory array

    assign read_data = mem[raddr];          // Read data

    always @(posedge wclk)
        if (wclk_en && !write_full) mem[waddr] <= write_data; // Write data

endmodule



// This is a 2-stage synchronous FIFO module.
module two_ff_sync #(parameter SIZE = 4)( 
    output reg [SIZE-1:0] q2,   // Output of the second flip-flop
    input [SIZE-1:0] din,       // Input data
    input clk, rst_n            // Clock and reset
    );

    reg [SIZE-1:0] q1; // Output of the first flip-flop

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            {q2, q1} <= 0;          // Reset the FIFO
        else 
            {q2, q1} <= {q1, din};  // Shift the data
    end 

endmodule