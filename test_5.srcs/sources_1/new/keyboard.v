`timescale 1ns / 1ps

module keyboard(
    input wire clk,
    input wire PS2Clk,
    input wire data,
    output reg [7:0]reg_out, 
    output wire flag_1
);
    
    reg [7:0] data_next; 
    reg [7:0] data_prev;
    reg [3:0] b;
    reg flag;
    
    assign flag_1 = (b == 11)?1:0;
    
    initial
        begin
            b<=4'h1;
            flag<=1'b0;
            data_next<=8'hf0;
            data_prev<=8'hf0;
            reg_out<=8'hff;
        end
        
    always @(negedge PS2Clk)
        begin
            case(b)
                1:;
                2:data_next[0]<=data;
                3:data_next[1]<=data;
                4:data_next[2]<=data;
                5:data_next[3]<=data;
                6:data_next[4]<=data;
                7:data_next[5]<=data;
                8:data_next[6]<=data;
                9:data_next[7]<=data;
                10:flag<=1'b1;
                11: begin 
                    flag<=1'b0;
                    end
            endcase
        end

     always @(negedge PS2Clk)
        begin   
            if(b<=10)
                b<=b+1;
            else if(b==11)
                b<=1;
        end
    
    always@(negedge PS2Clk) 
    begin
        if(b == 10 && data_next==8'hf0)
            reg_out<=data_prev;
    end
    
    always@(negedge PS2Clk) 
    begin
        if(b == 10 && data_next!=8'hf0)
            data_prev<=data_next;
    end 
    
endmodule