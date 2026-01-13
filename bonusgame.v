module bonusgame(

    input clk,
    input rst,
    
    input enterA,
    input enterB,
    input [2:0] letterIn,
    input sw3,		
   
    output reg [7:0] LEDX,
    output reg [6:0] SSD3,
    output reg [6:0] SSD2,
    output reg [6:0] SSD1,
    output reg [6:0] SSD0 
    
    );

    parameter S_reset = 4'd0;
    parameter S_start = 4'd1;
    parameter S_wait = 4'd2;
    parameter S_show_score = 4'd3;
    parameter S_show_player = 4'd4;
    parameter S_codemaker_input = 4'd5;
    parameter S_show_lives = 4'd6;
    parameter S_codebreaker_input = 4'd7;
    parameter S_check_guess = 4'd8;
    parameter S_reveal_secret = 4'd9;
    parameter S_game_score = 4'd10;
    parameter S_round_finished = 4'd11;
    parameter S_generate_secret = 4'd12;

    reg [3:0] state, next_state;

    wire exact;
    wire exact_3,exact_2,exact_1,exact_0;
    wire partial_0,partial_1,partial_2,partial_3;

    wire invalid_secret;

    wire rng_bit;
    reg  rng_rst;
    reg [3:0] rng_count;   // counts 0..11 bits
    reg [2:0] bit_cnt;        // 0..2


    rng_module RNG (
    .clk(clk),
    .rst(rng_rst),
    .rng_out(rng_bit)
    );


    reg single_player;   // 0 = normal game, 1 = bonus mode

    reg active_player;        // 0 = A, 1 = B
    reg [1:0] scoreA, scoreB; // max 2
    reg [1:0] lives;          // 3 lives max
    reg [2:0] index;          // for 4-letter code

    reg [2:0] secret0, secret1, secret2, secret3;
    reg [2:0] guess0, guess1, guess2, guess3;

    reg [6:0] timer;   

    always @(posedge clk or negedge rst) // main sequential for logic
    begin
        if(!rst)
        begin
            state <= S_reset;
            scoreA <= 2'd0;
            scoreB <= 2'd0;
            lives <= 2'd3; //
            index <= 3'd0;
            active_player <= 1'b0; // arbitrary
            timer <= 7'd0;
            guess0 <= 3'd0;
            guess1 <= 3'd0;
            guess2 <= 3'd0;
            guess3 <= 3'd0;
            secret0 <= 3'd0;
            secret1 <= 3'd0;
            secret2 <= 3'd0;
            secret3 <= 3'd0;
            single_player <= 1'b0;
            rng_rst <= 1'b1;
            rng_count <= 4'd0;
            bit_cnt <= 2'd0;
        end
        else
        begin

            state <= next_state;
            case(state)

                S_start:
                begin
                    scoreA <= 2'd0;
                    scoreB <= 2'd0;
                    index <= 3'd0;
                    guess0 <= 3'd0;
                    guess1 <= 3'd0;
                    guess2 <= 3'd0;
                    guess3 <= 3'd0;
                    secret0 <= 3'd0;
                    secret1 <= 3'd0;
                    secret2 <= 3'd0;
                    secret3 <= 3'd0;
                    lives <= 2'd3;//
                    rng_rst   <= 1'b0;
                    rng_count <= 4'd0;
                    bit_cnt     <= 2'd0;

                end

                S_wait:
                begin
                    if (enterA) begin
                        active_player <= 1'b0; // Player A
                        if(sw3)
                            single_player <= 1'b1; // bonus mode
                        else
                            single_player <= 1'b0;
                        
                    end
                    else if (enterB) begin
                        active_player <= 1'b1; // Player B
                        single_player <= 1'b0; 
                    end
                end

                S_show_score:
                begin

                    if(timer == 7'd99)
                    begin
                        timer <= 7'd0;
                        if (single_player == 1'b1) begin
                            bit_cnt <= 2'd0;
                            rng_count <= 4'd0;
                            rng_rst  <= 1'b0;
                        end
                    end

                    else
                        timer <= timer + 7'd1;
                end

                S_show_player: 
                begin

                    if(timer == 7'd99) begin
                        timer <= 7'd0;
                        index <= 3'd0;
                        lives <= 3'd3;
                    end
                    else
                        timer <= timer + 7'd1;
                end

                S_generate_secret:
                begin

                    rng_rst <= 1'b0;

                    if(rng_count < 4'd12)begin
                        
                        case(rng_count)
                            4'd0: secret3[2] <= rng_bit;
                            4'd1: secret3[1] <= rng_bit;
                            4'd2: secret3[0] <= rng_bit;
                            4'd3: secret2[2] <= rng_bit;
                            4'd4: secret2[1] <= rng_bit;
                            4'd5: secret2[0] <= rng_bit;
                            4'd6: secret1[2] <= rng_bit;
                            4'd7: secret1[1] <= rng_bit;
                            4'd8: secret1[0] <= rng_bit;
                            4'd9: secret0[2] <= rng_bit;
                            4'd10: secret0[1] <= rng_bit;
                            4'd11: secret0[0] <= rng_bit;
                        endcase

                        rng_count <= rng_count + 4'd1;
                    end
                    else begin
                        if(invalid_secret && rng_count == 12)begin
                            rng_count <= 4'd0;
                            secret0 <= 3'd0;
                            secret1 <= 3'd0;
                            secret2 <= 3'd0;
                            secret3 <= 3'd0;
                        end
                    end
                    
                end


                S_codemaker_input:
                begin
                    if(((active_player == 1'b0 && enterA) || (active_player == 1'b1 && enterB)) && (letterIn != 3'b000)) 
                    begin
                        if(index < 4)begin
                            case(index)
                                3'd0: secret3 <= letterIn; 
                                3'd1: secret2 <= letterIn;
                                3'd2: secret1 <= letterIn;
                                3'd3: secret0 <= letterIn;
                            endcase
                            index <= index + 3'd1;
                        end
                        if(index == 3) begin
                            active_player <= ~active_player; // go to code breaker
                        end
                    end
                end

                S_show_lives:
                begin
                    if(timer == 7'd99) begin
                        timer <= 7'd0;
                        index <= 3'd0;
                        guess0 <= 3'd0;
                        guess1 <= 3'd0;
                        guess2 <= 3'd0;
                        guess3 <= 3'd0;
                    end
                    else
                        timer <= timer + 7'd1;
                    
                    if (single_player) begin
                        bit_cnt     <= 2'd0;
                        letter_cnt  <= 2'd0;
                        temp_letter <= 3'd0;
                    end

                end

                S_codebreaker_input:
                begin
                    if(((active_player == 1'b0 && enterA) || (active_player == 1'b1 && enterB)) && (letterIn != 3'b000))begin
                        if(index < 4)begin
                            case(index)
                                3'd0: guess3 <= letterIn;
                                3'd1: guess2 <= letterIn;
                                3'd2: guess1 <= letterIn;
                                3'd3: guess0 <= letterIn;
                            endcase
                            index <= index + 3'd1;
                        end
                    end
                end

                S_check_guess:
                begin
                    if((active_player == 1'b0 && enterA) || (active_player == 1'b1 && enterB))
                    begin
                        if(exact)begin
                            if(active_player == 1'b0) // A (code breaker)
                                scoreA <= scoreA + 2'd1;
                            else // B (code breaker)
                                scoreB <= scoreB + 2'd1;
                        end
                        else begin
                            lives <= lives - 2'd1;
                            index <= 3'd0;
                            guess0 <= 3'd0;
                            guess1 <= 3'd0;
                            guess2 <= 3'd0;
                            guess3 <= 3'd0;
                        end
                    end
                end

                S_reveal_secret: 
                begin
                    if(timer == 7'd99)begin
                        timer <= 7'd0;
                        if(active_player == 1'b0) // code breaker is A 
                            scoreB <= scoreB + 2'd1; // code maker wins
                        else
                            scoreA <= scoreA + 2'd1; // code maker wins
                    end
                    else
                        timer <= timer + 7'd1;
                end

                S_game_score:
                begin
                    if(timer == 7'd99)begin
                        timer <= 7'd0;
                        index <= 0; 
                    end
                    else
                        timer <= timer + 7'd1;
                end

                S_round_finished:
                begin
                    if(timer == 7'd99)begin
                        timer <= 7'd0;
                        secret0 <= 3'd0;
                        secret1 <= 3'd0;
                        secret2 <= 3'd0;
                        secret3 <= 3'd0;
                    end
                    else
                        timer <= timer + 7'd1;   
                end


                default:
                begin
                    timer <= 7'd0;
                end

            endcase
        end       
    end

    always @(*) begin

        case(state)

            S_reset:
                next_state = S_start;

            S_start:
                next_state = S_wait;

            S_wait: 
            begin
                if (enterA)
                    next_state = S_show_score;
                else if (enterB)
                    next_state = S_show_score;
                else
                    next_state = S_wait;
            end

            S_show_score:
            begin
                if (timer == 7'd99)begin
                    if (single_player == 1'b1) 
                        next_state = S_generate_secret;
                    else
                        next_state = S_show_player;
                end
                else
                    next_state = S_show_score;
            end

            S_generate_secret:
            begin
                if(rng_count == 4'd12)begin
                    if(invalid_secret)
                        next_state = S_generate_secret;
                    else
                        next_state = S_show_player;
                end
                else
                    next_state = S_generate_secret;
            end

            S_show_player:
            begin
                if (timer == 7'd99) begin
                    if(single_player == 1'b1)
                        next_state = S_show_lives;
                    else if(index == 4)
                        next_state = S_show_lives;
                    else
                        next_state = S_codemaker_input;
                end
                else
                    next_state = S_show_player;
            end

            S_codemaker_input:
            begin
                if (index == 4)
                    next_state = S_show_player;
                else 
                    next_state = S_codemaker_input;
            end

            S_show_lives:
            begin
                if (timer == 7'd99)
                begin 
                    if(lives > 0)
                        next_state = S_codebreaker_input;
                    else
                        next_state = S_reveal_secret;
                end
                else
                    next_state = S_show_lives;
            end

            S_codebreaker_input:
            begin
                if(index == 4)
                    next_state = S_check_guess;
                else 
                    next_state = S_codebreaker_input;
            end

            S_check_guess:
            begin
                if((active_player == 1'b0 && enterA) || (active_player == 1'b1 && enterB))
                begin
                    if(exact)begin
                        next_state = S_game_score;
                    end
                    else
                        next_state = S_show_lives;
                end
                else
                    next_state = S_check_guess;
            end

            S_reveal_secret:
            begin
                if (timer == 7'd99)
                    next_state = S_game_score;
                else
                    next_state = S_reveal_secret;
            end
            S_game_score:
            begin
                if(timer == 7'd99)
                    next_state = S_round_finished;               
                else
                    next_state = S_game_score;
            end

            S_round_finished:
            begin
                if (single_player) begin
                    if (enterA)
                        next_state = S_reset;
                    else
                        next_state = S_round_finished;
                end
                else begin
                    if(scoreA == 2 || scoreB == 2) begin
                        if(enterA || enterB)
                            next_state = S_reset;
                        else
                            next_state = S_round_finished;
                    end
                    else begin
                        next_state = S_show_player;
                    end
                end
            end

            default:
                next_state = S_reset;

        endcase
    end

    assign exact = ((guess3 == secret3) && (guess2 == secret2) && (guess1 == secret1) && (guess0 == secret0));
                    
    assign exact_3 = (guess3 == secret3);
    assign exact_2 = (guess2 == secret2);
    assign exact_1 = (guess1 == secret1);
    assign exact_0 = (guess0 == secret0);

    assign partial_3 = (!exact_3) && ((guess3 == secret2) || (guess3 == secret1) || (guess3 == secret0));
    assign partial_2 = (!exact_2) && ((guess2 == secret3) || (guess2 == secret1) || (guess2 == secret0));
    assign partial_1 = (!exact_1) && ((guess1 == secret3) || (guess1 == secret2) || (guess1 == secret0));
    assign partial_0 = (!exact_0) && ((guess0 == secret3) || (guess0 == secret2) || (guess0 == secret1));

    assign invalid_secret = ((secret3 == 3'b000) || (secret2 == 3'b000) || (secret1 == 3'b000) || (secret0 == 3'b000));


    parameter [6:0] seg_blank = 7'b0000000;
    parameter [6:0] seg_dash  = 7'b1000000;

    // digits
    parameter [6:0] seg_0 = 7'b0111111;
    parameter [6:0] seg_1 = 7'b0000110;
    parameter [6:0] seg_2 = 7'b1011011;
    parameter [6:0] seg_3 = 7'b1001111;

    parameter [6:0] seg_A = 7'b1110111;
    parameter [6:0] seg_b = 7'b1111100;
    parameter [6:0] seg_C = 7'b0111001;
    parameter [6:0] seg_E = 7'b1111001; 
    parameter [6:0] seg_F = 7'b1110001;
    parameter [6:0] seg_H = 7'b1110110;
    parameter [6:0] seg_L = 7'b0111000;
    parameter [6:0] seg_P = 7'b1110011;
    parameter [6:0] seg_U = 7'b0111110;

    always @(*) 
    begin
        case (state)
            S_start: begin
                SSD3 = seg_blank;
                SSD2 = seg_A;
                SSD1 = seg_dash;
                SSD0 = seg_b;
                LEDX = 8'b00000000;
            end

            S_wait: begin
                SSD3 = seg_blank;
                SSD2 = seg_A;
                SSD1 = seg_dash;
                SSD0 = seg_b;
                LEDX = 8'b00000000;
            end 

            S_show_score: begin
                SSD3 = seg_blank;
                case(scoreA)
                    2'd0: SSD2 = seg_0;
                    2'd1: SSD2 = seg_1;
                    2'd2: SSD2 = seg_2;
                    default: SSD2 = seg_0;
                endcase

                case(scoreB)
                    2'd0: SSD0 = seg_0;
                    2'd1: SSD0 = seg_1;
                    2'd2: SSD0 = seg_2;
                    default: SSD0 = seg_0;
                endcase

                SSD1 = seg_dash;
                LEDX = 8'b00000000;
            end

            S_generate_secret: begin
                SSD3 = seg_blank;
                case(scoreA)
                    2'd0: SSD2 = seg_0;
                    2'd1: SSD2 = seg_1;
                    2'd2: SSD2 = seg_2;
                    default: SSD2 = seg_0;
                endcase

                case(scoreB)
                    2'd0: SSD0 = seg_0;
                    2'd1: SSD0 = seg_1;
                    2'd2: SSD0 = seg_2;
                    default: SSD0 = seg_0;
                endcase

                SSD1 = seg_dash;
                LEDX = 8'b00000000;
            end

            S_show_player: begin
                SSD3 = seg_blank;
                SSD2 = seg_P;
                SSD1 = seg_dash;
                if(active_player == 1'b0)
                    SSD0 = seg_A; // pl A
                else
                    SSD0 = seg_b; // pl B
                LEDX = 8'b00000000;
            end

            S_codemaker_input: 
            begin
                LEDX = 8'b00000000; 
                SSD3 = seg_blank;
                SSD2 = seg_blank;
                SSD1 = seg_blank;
                SSD0 = seg_blank;
                if(index == 0)begin
                    case(letterIn)
                        3'b000: SSD3 = seg_dash;
                        3'b001: SSD3 = seg_A;
                        3'b010: SSD3 = seg_C;
                        3'b011: SSD3 = seg_E;
                        3'b100: SSD3 = seg_F;
                        3'b101: SSD3 = seg_H;
                        3'b110: SSD3 = seg_L;
                        3'b111: SSD3 = seg_U;
                        default: SSD3 = seg_blank; 
                    endcase
                        
                    SSD2 = seg_blank;
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end
                else if(index == 1)begin
                    SSD3 = seg_dash;
                    case(letterIn)
                        3'b000: SSD2 = seg_dash;
                        3'b001: SSD2 = seg_A;
                        3'b010: SSD2 = seg_C;
                        3'b011: SSD2 = seg_E;
                        3'b100: SSD2 = seg_F;
                        3'b101: SSD2 = seg_H;
                        3'b110: SSD2 = seg_L;
                        3'b111: SSD2 = seg_U;
                        default: SSD2 = seg_blank; 
                    endcase
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end

                else if(index == 2)begin
                    SSD3 = seg_dash;
                    SSD2 = seg_dash;
                    case(letterIn)
                        3'b000: SSD1 = seg_dash;
                        3'b001: SSD1 = seg_A;
                        3'b010: SSD1 = seg_C;
                        3'b011: SSD1 = seg_E;
                        3'b100: SSD1 = seg_F;
                        3'b101: SSD1 = seg_H;
                        3'b110: SSD1 = seg_L;
                        3'b111: SSD1 = seg_U;
                        default: SSD1 = seg_blank; 
                    endcase
                    SSD0 = seg_blank;
                end

                else if(index == 3)begin
                    SSD3 = seg_dash;
                    SSD2 = seg_dash;
                    SSD1 = seg_dash;
                    case(letterIn)
                        3'b000: SSD0 = seg_dash;
                        3'b001: SSD0 = seg_A;
                        3'b010: SSD0 = seg_C;
                        3'b011: SSD0 = seg_E;
                        3'b100: SSD0 = seg_F;
                        3'b101: SSD0 = seg_H;
                        3'b110: SSD0 = seg_L;
                        3'b111: SSD0 = seg_U;
                        default: SSD0 = seg_blank; 
                    endcase
                end

                else begin
                    SSD3 = seg_blank;
                    SSD2 = seg_blank;
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end
            end

            S_show_lives: begin
                LEDX = 8'b00000000;
                SSD3 = seg_blank;
                SSD2 = seg_L;
                SSD1 = seg_dash;
                case (lives)
                    2'd0: SSD0 = seg_0;
                    2'd1: SSD0 = seg_1;
                    2'd2: SSD0 = seg_2;
                    2'd3: SSD0 = seg_3;
                    default: SSD0 = seg_0;
                endcase
            end

            S_codebreaker_input: begin
                LEDX = 8'b00000000;
                SSD3 = seg_blank;
                SSD2 = seg_blank;
                SSD1 = seg_blank;
                SSD0 = seg_blank;
                if(index == 0)begin 
                    case(letterIn)
                        3'b000: SSD3 = seg_dash;
                        3'b001: SSD3 = seg_A;
                        3'b010: SSD3 = seg_C;
                        3'b011: SSD3 = seg_E;
                        3'b100: SSD3 = seg_F;
                        3'b101: SSD3 = seg_H;
                        3'b110: SSD3 = seg_L;
                        3'b111: SSD3 = seg_U;
                        default: SSD3 = seg_blank; 
                    endcase
                    SSD2 = seg_blank;
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end

                else if(index == 1)begin
                    case(guess3)
                        3'b001: SSD3 = seg_A;
                        3'b010: SSD3 = seg_C;
                        3'b011: SSD3 = seg_E;
                        3'b100: SSD3 = seg_F;
                        3'b101: SSD3 = seg_H;
                        3'b110: SSD3 = seg_L;
                        3'b111: SSD3 = seg_U;
                        default: SSD3 = seg_blank; 
                    endcase
                    case(letterIn)
                        3'b000: SSD2 = seg_dash;
                        3'b001: SSD2 = seg_A;
                        3'b010: SSD2 = seg_C;
                        3'b011: SSD2 = seg_E;
                        3'b100: SSD2 = seg_F;
                        3'b101: SSD2 = seg_H;
                        3'b110: SSD2 = seg_L;
                        3'b111: SSD2 = seg_U;
                        default: SSD2 = seg_blank; 
                    endcase
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end

                else if(index == 2)begin
                    case(guess3)
                        3'b001: SSD3 = seg_A;
                        3'b010: SSD3 = seg_C;
                        3'b011: SSD3 = seg_E;
                        3'b100: SSD3 = seg_F;
                        3'b101: SSD3 = seg_H;
                        3'b110: SSD3 = seg_L;
                        3'b111: SSD3 = seg_U;
                        default: SSD3 = seg_blank; 
                    endcase

                    case(guess2)
                        3'b001: SSD2 = seg_A;
                        3'b010: SSD2 = seg_C;
                        3'b011: SSD2 = seg_E;
                        3'b100: SSD2 = seg_F;
                        3'b101: SSD2 = seg_H;
                        3'b110: SSD2 = seg_L;
                        3'b111: SSD2 = seg_U;
                        default: SSD2 = seg_blank; 
                    endcase

                    case(letterIn)
                        3'b000: SSD1 = seg_dash;
                        3'b001: SSD1 = seg_A;
                        3'b010: SSD1 = seg_C;
                        3'b011: SSD1 = seg_E;
                        3'b100: SSD1 = seg_F;
                        3'b101: SSD1 = seg_H;
                        3'b110: SSD1 = seg_L;
                        3'b111: SSD1 = seg_U;
                        default: SSD1 = seg_blank; 
                    endcase
                    SSD0 = seg_blank;
                end

                else if(index == 3)begin
                    case(guess3)
                        3'b001: SSD3 = seg_A;
                        3'b010: SSD3 = seg_C;
                        3'b011: SSD3 = seg_E;
                        3'b100: SSD3 = seg_F;
                        3'b101: SSD3 = seg_H;
                        3'b110: SSD3 = seg_L;
                        3'b111: SSD3 = seg_U;
                        default: SSD3 = seg_blank; 
                    endcase

                    case(guess2)
                        3'b001: SSD2 = seg_A;
                        3'b010: SSD2 = seg_C;
                        3'b011: SSD2 = seg_E;
                        3'b100: SSD2 = seg_F;
                        3'b101: SSD2 = seg_H;
                        3'b110: SSD2 = seg_L;
                        3'b111: SSD2 = seg_U;
                        default: SSD2 = seg_blank; 
                    endcase

                    case(guess1)
                        3'b001: SSD1 = seg_A;
                        3'b010: SSD1 = seg_C;
                        3'b011: SSD1 = seg_E;
                        3'b100: SSD1 = seg_F;
                        3'b101: SSD1 = seg_H;
                        3'b110: SSD1 = seg_L;
                        3'b111: SSD1 = seg_U;
                        default: SSD1 = seg_blank; 
                    endcase

                    case(letterIn)
                        3'b000: SSD0 = seg_dash;
                        3'b001: SSD0 = seg_A;
                        3'b010: SSD0 = seg_C;
                        3'b011: SSD0 = seg_E;
                        3'b100: SSD0 = seg_F;
                        3'b101: SSD0 = seg_H;
                        3'b110: SSD0 = seg_L;
                        3'b111: SSD0 = seg_U;
                        default: SSD0 = seg_blank; 
                    endcase
                end

                else
                begin
                    SSD3 = seg_blank;
                    SSD2 = seg_blank;
                    SSD1 = seg_blank;
                    SSD0 = seg_blank;
                end
            end
            
            S_check_guess: begin

                LEDX = 8'b00000000;

                case(guess3)
                    3'b001: SSD3 = seg_A;
                    3'b010: SSD3 = seg_C;
                    3'b011: SSD3 = seg_E;
                    3'b100: SSD3 = seg_F;
                    3'b101: SSD3 = seg_H;
                    3'b110: SSD3 = seg_L;
                    3'b111: SSD3 = seg_U;
                    default: SSD3 = seg_blank; 
                endcase

                case(guess2)
                    3'b001: SSD2 = seg_A;
                    3'b010: SSD2 = seg_C;
                    3'b011: SSD2 = seg_E;
                    3'b100: SSD2 = seg_F;
                    3'b101: SSD2 = seg_H;
                    3'b110: SSD2 = seg_L;
                    3'b111: SSD2 = seg_U;
                    default: SSD2 = seg_blank; 
                endcase

                case(guess1)
                    3'b001: SSD1 = seg_A;
                    3'b010: SSD1 = seg_C;
                    3'b011: SSD1 = seg_E;
                    3'b100: SSD1 = seg_F;
                    3'b101: SSD1 = seg_H;
                    3'b110: SSD1 = seg_L;
                    3'b111: SSD1 = seg_U;
                    default: SSD1 = seg_blank; 
                endcase

                case(guess0)
                    3'b001: SSD0 = seg_A;
                    3'b010: SSD0 = seg_C;
                    3'b011: SSD0 = seg_E;
                    3'b100: SSD0 = seg_F;
                    3'b101: SSD0 = seg_H;
                    3'b110: SSD0 = seg_L;
                    3'b111: SSD0 = seg_U;
                    default: SSD0 = seg_blank; 
                endcase
                

                if(exact_3)begin
                    LEDX[7] = 1'b1;
                    LEDX[6] = 1'b1;
                end
                else if(partial_3)begin
                    LEDX[7] = 1'b0;
                    LEDX[6] = 1'b1;
                end
                else begin
                    LEDX[7] = 1'b0;
                    LEDX[6] = 1'b0;
                end

                if(exact_2)begin
                    LEDX[5] = 1'b1;
                    LEDX[4] = 1'b1;
                end
                else if(partial_2)begin
                    LEDX[5] = 1'b0;
                    LEDX[4] = 1'b1;
                end
                else begin
                    LEDX[5] = 1'b0;
                    LEDX[4] = 1'b0;
                end

                if(exact_1)begin
                    LEDX[3] = 1'b1;
                    LEDX[2] = 1'b1;
                end
                else if(partial_1)begin
                    LEDX[3] = 1'b0;
                    LEDX[2] = 1'b1;
                end
                else begin
                    LEDX[3] = 1'b0;
                    LEDX[2] = 1'b0;
                end 

                if(exact_0)begin
                    LEDX[1] = 1'b1;
                    LEDX[0] = 1'b1;
                end
                else if(partial_0)begin
                    LEDX[1] = 1'b0;
                    LEDX[0] = 1'b1;
                end
                else begin
                    LEDX[1] = 1'b0;
                    LEDX[0] = 1'b0;
                end           
            end

            S_reveal_secret: begin

                LEDX = 8'b00000000;
                case(secret3)
                    3'b001: SSD3 = seg_A;
                    3'b010: SSD3 = seg_C;
                    3'b011: SSD3 = seg_E;
                    3'b100: SSD3 = seg_F;
                    3'b101: SSD3 = seg_H;
                    3'b110: SSD3 = seg_L;
                    3'b111: SSD3 = seg_U;
                    default: SSD3 = seg_blank;
                endcase

                case(secret2)
                    3'b001: SSD2 = seg_A;
                    3'b010: SSD2 = seg_C;
                    3'b011: SSD2 = seg_E;
                    3'b100: SSD2 = seg_F;
                    3'b101: SSD2 = seg_H;
                    3'b110: SSD2 = seg_L;
                    3'b111: SSD2 = seg_U;
                    default: SSD2 = seg_blank;
                endcase

                case(secret1)
                    3'b001: SSD1 = seg_A;
                    3'b010: SSD1 = seg_C;
                    3'b011: SSD1 = seg_E;
                    3'b100: SSD1 = seg_F;
                    3'b101: SSD1 = seg_H;
                    3'b110: SSD1 = seg_L;
                    3'b111: SSD1 = seg_U;
                    default: SSD1 = seg_blank; 
                endcase

                case(secret0)
                    3'b001: SSD0 = seg_A;
                    3'b010: SSD0 = seg_C;
                    3'b011: SSD0 = seg_E;
                    3'b100: SSD0 = seg_F;
                    3'b101: SSD0 = seg_H;
                    3'b110: SSD0 = seg_L;
                    3'b111: SSD0 = seg_U;
                    default: SSD0 = seg_blank; 
                endcase
            end

            S_game_score: 
            begin
                LEDX = 8'b00000000;
                SSD3 = seg_blank;
                SSD1 = seg_dash;

                case(scoreA)
                    2'd0: SSD2 = seg_0;
                    2'd1: SSD2 = seg_1;
                    2'd2: SSD2 = seg_2;
                    default: SSD2 = seg_0;
                endcase

                case(scoreB)
                    2'd0: SSD0 = seg_0;
                    2'd1: SSD0 = seg_1;
                    2'd2: SSD0 = seg_2;
                    default: SSD0 = seg_0;
                endcase
                
            end

            S_round_finished:begin

                SSD3 = seg_blank;
                SSD1 = seg_dash;

                case(scoreA)
                    2'd0: SSD2 = seg_0;
                    2'd1: SSD2 = seg_1;
                    2'd2: SSD2 = seg_2;
                    default: SSD2 = seg_0;
                endcase

                case(scoreB)
                    2'd0: SSD0 = seg_0;
                    2'd1: SSD0 = seg_1;
                    2'd2: SSD0 = seg_2;
                    default: SSD0 = seg_0;
                endcase
            
                if(scoreA == 2'd2 || scoreB == 2'd2) begin
                    if(timer[4] == 1'b1) //
                    LEDX = 8'b10101010;
                else
                    LEDX = 8'b01010101;
                end
                else if(single_player == 1'b1) begin
                    if(timer[4] == 1'b1) //
                        LEDX = 8'b10101010;
                    else
                        LEDX = 8'b01010101;
                end
                else begin
                    LEDX = 8'b00000000;
                end
            end
            
            default: begin
                LEDX = 8'b00000000;
                SSD3 = seg_blank;
                SSD2 = seg_blank;
                SSD1 = seg_blank;
                SSD0 = seg_blank;
                // default
            end
        endcase
    end
endmodule

