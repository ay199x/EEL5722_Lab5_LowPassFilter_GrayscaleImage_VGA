`timescale 1ns / 1ps

module img_test (
    input wire clk, reset,
    output wire hsync, vsync,
    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);

wire video_on, p_tick;
wire [9:0] x, y;
reg [3:0] r, g, b;
reg [7:0] grayscale;
wire [7:0] a_out;
reg [15:0] a_r; // 16-bit address

// Instantiate VGA controller (vga_sync)
vga vga_sync (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
    .video_on(video_on), .p_tick(p_tick), .x(x), .y(y));

// Instantiate dual-port RAM (blk_mem_gen_0) with only one port used for reading
blk_mem_gen_0 ram (
    .clka(clk), .wea(0), .addra(a_r), .dina(), .douta(a_out),
    .clkb(), .web(), .addrb(), .dinb(), .doutb()
);

// Image display region
localparam X_START = 0; // Adjust according to your image placement
localparam Y_START = 0; // Adjust according to your image placement
localparam X_END = X_START + 255;
localparam Y_END = Y_START + 255;

always @(posedge clk) begin
    if (p_tick) begin
        // Calculate the RAM address based on x and y coordinates
        a_r <= (x + (y - Y_START) * 256); // Example calculation for top-left corner placement

        // Check if the pixel is within the image region
        if (x >= X_START && x <= X_END && y >= Y_START && y <= Y_END) begin
            // Read grayscale data from the dual-port RAM
            grayscale <= a_out;
            // Convert grayscale to 4-bit R, G, and B channels with equal values
            r <= grayscale[7:4];
            g <= grayscale[7:4];
            b <= grayscale[7:4];
        end else begin
            // For coordinates outside the image region, set RGB to 0
            r <= 4'b0000;
            g <= 4'b0000;
            b <= 4'b0000;
        end
    end
end

assign R = r;
assign G = g;
assign B = b;

endmodule
