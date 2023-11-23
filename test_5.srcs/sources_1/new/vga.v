`timescale 1ns / 1ps

module vga (
		input wire clk,
		input wire reset,
		output wire hsync, vsync, 
		output wire display, 
		output wire clk_25_hi,
		output wire [9:0] h_out, v_out
);
	
	reg [1:0] clk100_out; 
	wire [1:0] clk100_in;
	wire clk_25;	
	
	always @(posedge clk, posedge reset)
		if(reset)
		clk100_out <= 0;
		else
		  clk100_out <= clk100_in;
	
	assign clk100_in = clk100_out + 1;
	
	assign clk_25 = (clk100_out == 0);

	reg [9:0] hrzntl_cs, hrzntl_ns, vrtcl_cs, vrtcl_ns;

	always @*	
		begin
		  hrzntl_ns = clk_25 ? 								 
		               hrzntl_cs == 799 ? 0 : hrzntl_cs + 1 
			       : hrzntl_cs;
		end
			
	always @(posedge clk, posedge reset) begin
         if(reset)
                hrzntl_cs <= 0;
         else
                hrzntl_cs <= hrzntl_ns;
    end
                   	
	always @(posedge clk, posedge reset) begin
		if(reset)
               vrtcl_cs <= 0;
		else
               vrtcl_cs <= vrtcl_ns;	
    end

	always @*
        begin
            vrtcl_ns = clk_25 && hrzntl_cs == 799 ? 			
                           (vrtcl_cs == 524 ? 0 : vrtcl_cs + 1) 
                       : vrtcl_cs;
        end	

    assign display = (hrzntl_cs < 640) 
                          && (vrtcl_cs < 480);
						  
	reg vsync_cs, hsync_cs;
	wire vsync_ns, hsync_ns;
	
	always @(posedge clk, posedge reset) begin
		   if(reset)
                hsync_cs   <= 0;
           else
                hsync_cs   <= hsync_ns;
	end	
	
    assign hsync_ns = hrzntl_cs >= 656	
                            && hrzntl_cs <= 751;
							
	always @(posedge clk, posedge reset) begin
          if(reset)
                vsync_cs   <= 0;
          else
                vsync_cs   <= vsync_ns;
    end
    
    assign vsync_ns = vrtcl_cs >= 490 	
                            && vrtcl_cs <= 491;

    assign hsync  = hsync_cs;  
    assign vsync  = vsync_cs;  
    assign h_out  = hrzntl_cs;
    assign v_out  = vrtcl_cs;
    assign clk_25_hi = clk_25;
	
endmodule