module top_module(
    input clk,
    input rst,
    
    input enterA,
    input enterB,
    input [2:0] letterIn,
    input sw3,			 
    
    output [7:0] led,
    output a_out,b_out,c_out,d_out,e_out,f_out,g_out,p_out,
    output [3:0] an
);


    wire clk_50;
    wire enterA_db;
    wire enterB_db;

    wire [6:0] SSD3,SSD2,SSD1,SSD0;
    wire [7:0] seven;

    wire rst_inv = ~rst;
    wire enterA_inv = ~enterA; 
    wire enterB_inv = ~enterB;
    

    clk_divider clk_div (
        .clk_in(clk),
        .divided_clk(clk_50)
    );

    debouncer dbA (
        .clk(clk_50),
        .rst(rst_inv),
        .noisy_in(enterA_inv),
        .clean_out(enterA_db)
    );

    debouncer dbB (
        .clk(clk_50),
        .rst(rst_inv),
        .noisy_in(enterB_inv),
        .clean_out(enterB_db)
    );
    

    bonusgame game (
        .clk(clk_50),
        .rst(rst),
        .enterA(enterA_db),
        .enterB(enterB_db),
        .letterIn(letterIn),
        .sw3(sw3),
        .LEDX(led),
        .SSD3(SSD3),
        .SSD2(SSD2),
        .SSD1(SSD1),
        .SSD0(SSD0)
    );


    ssd game_ssd (
        .clk(clk),
        .disp0(SSD0),
        .disp1(SSD1),
        .disp2(SSD2),
        .disp3(SSD3),
        .seven(seven),
        .segment(an)
    );

    assign a_out = seven[0];
    assign b_out = seven[1];
    assign c_out = seven[2];
    assign d_out = seven[3];
    assign e_out = seven[4];
    assign f_out = seven[5];
    assign g_out = seven[6];
    assign p_out = seven[7];
	
endmodule

