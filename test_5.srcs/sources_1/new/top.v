`timescale 1ns / 1ps

module top(
    input wire clk,             
    input wire reset, 
    input wire ps2c, 
    input wire ps2d, 
    output wire hsync,       
    output wire vsync,       
    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);
    reg [11:0] out; 
          
    wire display;				
    wire clk_25_hi;		

    wire [7:0] keyboard_data; //ascii
    
    reg [11:0] out_cs;     
    wire [9:0] h_out, v_out; //x & y coordinates of current pixel
    reg wea1,web1,wea2,web2; 
    reg [15:0]addra1,addrb2,addrb1,addra2;
    wire [7:0] douta1,doutb1,douta2,doutb2;
    reg [7:0] dina1,dinb1,dina2,dinb2;
    
    reg [19:0]kcs; // keyboard current state state machine
    reg [17:0] scs = 0; // state machine for scanning of each pixel,
    reg [3:0] fcs = 0; // filtering state machine current state
    wire zero_valid; // indicates '0' has been pressed
    wire scan_begin; // variable that starts the scanning state machine
    wire write_fin; // variable which indicates when the filtered data is stored back in BRAM1 from BRAM2
    wire filter_begin;// when the center pixel has been set, satrt filtering the surrounding 8 pixels
    reg [7:0] temp[8:0];// to store the image data of the 9 pixels
    reg [10:0] accumulate;// to store the sum of the 9 pixel's image data
    wire filter_fin;//to indicate that the filtered data has been calculated for the center pixel
    wire scan_fin; // indicates all the pixels have been scanned, filtered and the filteredc data written to BRAM2,
                    // now new data can be stored back in BRAM1
    reg [16:0] wcs = 0; // writing the 65536 pixels fileterd data to BRAM1 again
    reg dcs = 0;// the display state machine
    wire flag_1;
    
    initial
        begin
            wea1<=0;
            web1<=0;
            //dina1 <= 0;
            dinb1 <= 0;
            wea2 <= 0;
            web2 <= 0;
            //dina2 <= 0;
            dinb2 <= 0;
            kcs<=0;
            //out_cs <= 12'h000;
        end
        
    vga vga_uut   
        (   .clk(clk),
            .reset(reset),
            .hsync(hsync), .vsync(vsync), 
            .display(display),
            .clk_25_hi(clk_25_hi),
            .h_out(h_out), .v_out(v_out)
        );
       
    keyboard key_uut(
        .clk(clk),
        .PS2Clk(ps2c),
        .data(ps2d),
        .reg_out(keyboard_data),
        .flag_1(flag_1)
        );
    
    blk_mem_gen_0 memory_unit_1 //BRAM 1
           (                    //Image Displayed from this RAM
            .clka(clk),
            .wea(wea1),
            .addra(addra1),
            .dina(dina1),
            .douta(douta1),
            .clkb(clk),
            .web(web1),
            .addrb(addrb1),
            .dinb(dinb1),
            .doutb(doutb1)
          );
     
    blk_mem_gen_0 memory_unit_2 //BRAM2
         (                      //Fileterd data being stored in this RAM
          .clka(clk),
          .wea(wea2),
          .addra(addra2),
          .dina(dina2),
          .douta(douta2),
          .clkb(clk),
          .web(web2),
          .addrb(addrb2),
          .dinb(dinb2),
          .doutb(doutb2)
        );
                                  
assign zero_valid = (keyboard_data == 8'h45 && flag_1 == 1)? 1:0; //High '0' pressed
assign scan_begin = (kcs == 1) ? 1:0;// indicate begining of scan state machine for each pixel
assign filter_begin = (scs[1:0] == 1) ? 1:0;// indicates to start filtering data for the center pixel of the kernel
assign filter_fin = (fcs == 14)? 1:0;// indicates filtering finished for the center pixel of the 3x3 kernel
assign scan_fin = (scs == 262143)?1:0;// indicates scanning and filetring of data is finished for all pixels
assign write_fin = (wcs == 65537)?1:0;//indicates fileterddata for whole image stroed in RAM1 from RAM1

  //Key board state machine
  always @(posedge clk) begin
    case(kcs)
        0 : begin
            if(zero_valid==1) //Check if zero pressed
                kcs<=kcs+1;
        end
        1: kcs <= kcs+1; // Go to next state
        2:begin
            if (scan_fin == 1) // Remain here until scan of all pixels finished
                    kcs <= kcs + 1;
            end
        10000000: kcs <= 0;// additional delay for keyboard
        default: kcs <= kcs + 1;
    endcase
  end
  
  // Scan state machine 4 sub-states, for each pixel
  always @(posedge clk) begin
    case(scs[1:0])
        0: begin
            if(scan_begin == 1 || scs != 0)
                scs <= scs +1;
        end
        1: begin
            scs <= scs + 1;
        end
        2: begin
            if(filter_fin == 1) begin //be in this state until filtered data for
                                    // the current center pixel is stored in 2nd RAM
                scs <= scs +1; // if filtering finished for current pixel go to next state
            end
        end
        3 : begin
                scs <=scs + 1; // Move onto the next pixel for calculating fileterd image data
        end
    endcase
  end
  
  // Filter State machine 
  always @(posedge clk) begin
    case(fcs)
        0: begin
            if(filter_begin == 1)// remain in this state until filter_begin is HIGH
                fcs <= fcs +1;
        end
        1: begin
            addra1 <= scs[17:2] - 257;// upper left pixel
            fcs <= fcs + 1;
        end
        2: begin
            temp[0] <= douta1;// data of upper left
            addra1 <= addra1 + 1;//top pixel address
            fcs <= fcs + 1;
        end
        3: begin
            temp[1] <= douta1;// top pixel data
            addra1 <= addra1 + 1;// corner right pixel
            fcs <= fcs + 1;
        end
        4: begin
            temp[2] <= douta1;// corner right pixel data
            addra1 <= addra1 + 254;//left pixel address
            fcs <= fcs + 1;
        end
        5: begin
                temp[3] <= douta1;//left pixel data
                addra1 <= addra1 + 1;//center pixel address
                fcs <= fcs + 1;
            end
        6: begin
            temp[4] <= douta1;//center pixel data
            addra1 <= addra1 + 1;// right pixel address
            fcs <= fcs + 1;
        end
        7: begin
            temp[5] <= douta1;// right pixel data
            addra1 <= addra1 + 254;//bottom corner left pixel address
            fcs <= fcs + 1;
        end
        8: begin
            temp[6] <= douta1;//bottom corner left pixel data
            addra1 <= addra1 + 1;// bottom pixel address
            fcs <= fcs + 1;
        end
        9: begin
            temp[7] <= douta1;// bottom pixel data
            addra1 <= addra1 + 1;// right bottom corner pixel
            fcs <= fcs + 1;
        end
        10: begin
            temp[8] <= douta1;// right bottom corner pixel data
            fcs <= fcs + 1;
        end
        11: begin
            accumulate <= ((temp[0]+temp[1]+temp[2]+temp[3]+temp[4]+temp[5]+temp[6]+temp[7]+temp[8])*7)>>6;//average
            addrb2 <= addra1 - 257;// center pixel address
            fcs <= fcs + 1;
        end
        12: begin
            dinb2 <= accumulate;//store data to RAM2 at center pixel address
            web2 <= 1;//enable write
            fcs <= fcs + 1;
        end
        13: begin
            web2 <= 0;// disbale RAM2 write at port B
            fcs <= fcs + 1;
        end
        14: fcs <= fcs+1;
        15: begin
            fcs<=0;//reset state
        end
    endcase
 
    //Dispaly state machine   
    if(scs == 0) begin
    case(dcs) 
            0: begin  
                addra1 <= v_out + 256*h_out; // address calculation of current pixel
                dcs <= dcs +1;
            end
            1: begin
            if (h_out>=0 && h_out <256 && v_out>=0 && v_out<256) begin //If within display area
                out[3:0] <= douta1[7:4];//display data in grayscale
                out[7:4] <= douta1[7:4];
                out[11:8] <= douta1[7:4];
                dcs <= 0;
            end
            else begin //if outside display area of 256x256 display black
                out[3:0] <= 0;
                out[7:4] <= 0;
                out[11:8] <= 0;
                dcs<=0;
            end
            end
            endcase 
  end
  end
  
  //Writing back to RAM 1 state machine
  always @(posedge clk) begin
    case(wcs)
        0: begin
            if(scan_fin == 1) begin //When scan is finished,begin writing filtered data to RAM1
               addrb1 <= wcs;//set address of RAM1
               addra2 <= wcs;//set address to write from on RAM2
               wcs <= wcs + 1; //increment address for next clock
            end
        end
        default: begin
            web1<=1;//write  enable on RAM1
            dinb1 <= douta2;//store data from RAM2 port to RAM1 port same address
            addrb1 <= wcs;//set new address for RAM1
            addra2 <= wcs;//set new address for RAM1
            wcs <= wcs + 1;
        end
        65538: begin
            wcs <= 0;//when all pixels are done reset
            web1 <= 0;
        end
    endcase      
  end
  
  assign R = out[11:8];
  assign G = out[7:4];
  assign B = out[3:0];
  
endmodule