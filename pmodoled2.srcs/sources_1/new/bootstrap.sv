`default_nettype none
`timescale 1ns / 1ps

module bootstrap #(
    parameter CLK_FREQ = 125e6,
    parameter POLL_PERIOD = 1e-3
)(
    input wire sysclk,
    input wire rst,
    // input wire [3:0] row,
    // (* fsm_encoding = "none" *) output logic [3:0] col,
    output logic [3:0] led,
    output logic led6_b,
    output logic led5_b,
    output logic led5_r,
    (* fsm_encoding = "none" *) output logic [7:0] je,
    // s(* fsm_encoding = "none" *) output logic [7:0] jb,

    input wire [3:0] row,
    // (* fsm_encoding = "none" *) output logic [3:0] col = 'b0111
    (* fsm_encoding = "none" *) output logic [3:0] col
    // output logic [3:0] led = 0
);

    // apparently this module only runs with 100MHz clock
    logic [3:0] key;
    logic [3:0] keys[2:0];

    logic key_trigger;
    logic rst = 'b0;
    PmodOLEDCtrl ctrl(
        .CLK(sysclk),
        .RST(rst),
        .CS(je[0]),
        .SDIN(je[1]),
        .SCLK(je[3]),
        .DC(je[4]),
        .RES(je[5]),
        .VBAT(je[6]),
        .VDD(je[7]),
        .KEY(key),
        .KEYS(keys),
        .KEYTRIGGER(key_trigger)
    );

    logic all_not_pressed;
    always_comb
        led6_b = all_not_pressed;

    logic prev_all_not_pressed = 0;
    always_ff @(posedge sysclk) begin
        prev_all_not_pressed <= all_not_pressed;
    end

    keypad_decode #(CLK_FREQ, POLL_PERIOD) decode(
        .sysclk(sysclk),
        .row(row),
        .col(col),
        .led(key),
        .all_not_pressed(all_not_pressed)
    );

    always_comb
        key_trigger = prev_all_not_pressed == 'b0 && all_not_pressed == 'b1;

    always_ff @(posedge sysclk) begin
        if (key == 'hA) begin
            if(keys[2] == 'h1 && keys[1] == 'h2 && keys[0] == 'h3) begin
                led5_b <= 'b1;
                led5_r <= 'b0;
            end
            else begin
                led5_b <= 'b0;
                led5_r <= 'b1;
            end
        end
        else if (prev_all_not_pressed == 'b0 && all_not_pressed == 'b1) begin
            keys <= {keys[1:0], key};
            led5_b <= 'b0;
            led5_r <= 'b0;
        end
    end

    always_comb
        led = key == 'hA ? keys[2] : key;
endmodule
`default_nettype wire
