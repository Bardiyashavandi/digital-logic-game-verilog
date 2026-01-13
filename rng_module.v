module rng_module (
    input        clk,
    input        rst,        
    output       rng_out
);
    reg  [31:0] state;
    assign rng_out = state[31];
    wire feedback;
    assign feedback = state[31] ^ state[21] ^ state[1] ^ state[0];

    always @(posedge clk) begin
        if (rst) 
        begin
            state <= 32'h1;
        end 
        else
        begin
            state <= {state[30:0], feedback};
        end
    end

endmodule