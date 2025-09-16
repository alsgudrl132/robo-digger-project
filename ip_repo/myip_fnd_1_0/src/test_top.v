`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 11:24:31 AM
// Design Name: 
// Module Name: test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ring_counter_led_top (
    input clk,
    input reset_p,
    output reg [15:0] led
);

    reg [20:0] clk_div;
    wire clk_div_18;

    // 분주기: clk_div 카운터 증가
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // 상승 에지 검출기 인스턴스
    edge_detector_p clk_div_edge (
        .clk(clk),
        .reset_p(reset_p),
        .cp(clk_div[18]),
        .p_edge(clk_div_18)
    );

    // 링 카운터
    always @(posedge clk_div_18 or posedge reset_p) begin
        if (reset_p)
            led <= 16'b0000_0000_0000_0001;
        else
            led <= {led[14:0], led[15]};
    end

endmodule

// module watch_top(
//     input clk, reset_p,
//     input [2:0] btn,
//     input sw_12h,               // 12/24시간 선택 스위치
//     output [7:0] seg_7,
//     output [3:0] com,
//     output [15:0] led
// );

//     // 버튼 엣지 출력
//     wire btn_mode, inc_min, inc_hour;

//     // 시계 상태 모드
//     reg set_watch;

//     // 시계 변수
//     reg [32:0] cnt_sysclk;  // 1분 카운터용
//     reg [7:0] min, hour;

//     // 1초 카운터 및 led 토글용
//     reg [26:0] sec_cnt;
//     reg led_15_toggle;

//     // AM/PM LED 제어용
//     reg led_10_toggle;

//     // PM 플래그
//     reg pm_flag;

//     // 스위치 이전 값 저장
//     reg sw_12h_d;
//     wire sw_toggle;

//     // 버튼 엣지 생성기
//     btn_cntr mode_btn(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
//     btn_cntr inc_min_btn(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(inc_min));
//     btn_cntr inc_hour_btn(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(inc_hour));

//     // 엣지 검출
//     wire mode_btn_pedge, min_btn_pedge, hour_btn_pedge;
//     edge_detector_p mode_ed (.clk(clk), .reset_p(reset_p), .cp(btn_mode), .p_edge(mode_btn_pedge));
//     edge_detector_p min_ed  (.clk(clk), .reset_p(reset_p), .cp(inc_min),  .p_edge(min_btn_pedge));
//     edge_detector_p hour_ed (.clk(clk), .reset_p(reset_p), .cp(inc_hour), .p_edge(hour_btn_pedge));

//     // LED 상태 표시
//     assign led[0] = set_watch;
//     assign led[15] = led_15_toggle;
//     assign led[10] = led_10_toggle;

//     // 스위치 토글 감지
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p)
//             sw_12h_d <= sw_12h;
//         else
//             sw_12h_d <= sw_12h;
//     end
//     assign sw_toggle = (sw_12h_d != sw_12h);

//     // 모드 토글
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p)
//             set_watch <= 0;
//         else if (mode_btn_pedge)
//             set_watch <= ~set_watch;
//     end

//     // 1초 카운터 및 led[15] 토글 (100MHz 기준)
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             sec_cnt <= 0;
//             led_15_toggle <= 0;
//         end else if (set_watch) begin
//             if (sec_cnt >= 27'd49_999_999) begin
//                 sec_cnt <= 0;
//                 led_15_toggle <= ~led_15_toggle;
//             end else
//                 sec_cnt <= sec_cnt + 1;
//         end else begin
//             sec_cnt <= 0;
//             led_15_toggle <= 0;
//         end
//     end

//     // 시계 동작 및 12/24 변환 처리
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             cnt_sysclk <= 0;
//             min <= 0;
//             hour <= 0;
//             pm_flag <= 0;
//         end else begin
//             // 1분 카운트 및 시간 증가
//             if (set_watch) begin
//                 if (cnt_sysclk >= 33'd5_999_999_999) begin
//                     cnt_sysclk <= 0;

//                     if (min >= 59) begin
//                         min <= 0;

//                         // 시간 증가 및 PM 플래그 처리
//                         if (sw_12h) begin
//                             // 12시간제: 1~12시 순환, pm_flag 토글
//                             if (hour == 12) begin
//                                 hour <= 1;
//                                 pm_flag <= ~pm_flag;
//                             end else begin
//                                 hour <= hour + 1;
//                             end
//                         end else begin
//                             // 24시간제: 0~23시 순환, pm_flag 0 고정
//                             if (hour >= 23)
//                                 hour <= 0;
//                             else
//                                 hour <= hour + 1;
//                             pm_flag <= 0; // 24시간제일 때 항상 0
//                         end
//                     end else begin
//                         min <= min + 1;
//                     end
//                 end else begin
//                     cnt_sysclk <= cnt_sysclk + 1;
//                 end
//             end

//             // 수동 시간 조정
//             if (min_btn_pedge && !set_watch) begin
//                 min <= (min >= 59) ? 0 : min + 1;
//             end
//             if (hour_btn_pedge && !set_watch) begin
//                 if (sw_12h) begin
//                     // 12시간제: 1~12시 순환
//                     if (hour == 12)
//                         hour <= 1;
//                     else
//                         hour <= hour + 1;
//                 end else begin
//                     // 24시간제: 0~23시 순환
//                     hour <= (hour >= 23) ? 0 : hour + 1;
//                     pm_flag <= 0; // 24시간제라면 pm_flag 무조건 0
//                 end
//             end

//             // 12/24시간제 전환 시 보정
//             if (sw_toggle && !(hour == 0 && min == 0)) begin
//                 if (sw_12h) begin
//                     // 24 → 12 변환
//                     if (hour == 0) begin
//                         hour <= 12;
//                         pm_flag <= 0; // 오전
//                     end else if (hour < 12) begin
//                         // 오전 1~11시
//                         pm_flag <= 0;
//                     end else if (hour == 12) begin
//                         pm_flag <= 1; // 오후 12시
//                     end else begin
//                         hour <= hour - 12;
//                         pm_flag <= 1; // 오후 1~11시
//                     end
//                 end else begin
//                     // 12 → 24 변환
//                     if (pm_flag && hour != 12)
//                         hour <= hour + 12;
//                     else if (!pm_flag && hour == 12)
//                         hour <= 0;
//                     pm_flag <= 0; // 24시간제로 변환 시 무조건 0
//                 end
//             end
//         end
//     end

//     // AM/PM LED 제어
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p)
//             led_10_toggle <= 0;
//         else
//             led_10_toggle <= sw_12h ? pm_flag : 0;
//     end

//     // BCD 변환
//     wire [15:0] hour_bcd, min_bcd;
//     bin_to_dec bcd_hour(.bin(hour), .bcd(hour_bcd));
//     bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));

//     // FND 표시 (HH:MM)
//     fnd_cntr fnd(
//         .clk(clk),
//         .reset_p(reset_p),
//         .fnd_value({hour_bcd[7:0], min_bcd[7:0]}),
//         .hex_bcd(1),
//         .seg_7(seg_7),
//         .com(com)
//     );

// endmodule




module watch (
    input clk,
    input reset_p,
    input btn_mode,
    input inc_sec,
    input inc_min,
    output reg [7:0] sec,
    output reg [7:0] min,
    output reg set_watch
);

    // 시스템 클럭 카운터
    reg [26:0] cnt_sysclk;

    // 모드 전환
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            set_watch <= 0;
        else if (btn_mode)
            set_watch <= ~set_watch;
    end

    // 시계 동작
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            cnt_sysclk <= 0;
            sec <= 0;
            min <= 0;
        end else begin
            if (set_watch) begin
                if (cnt_sysclk >= 27'd100_000_000-1) begin
                    cnt_sysclk <= 0;
                    if (sec >= 59) begin
                        sec <= 0;
                        if (min >= 59)
                            min <= 0;
                        else
                            min <= min + 1;
                    end else
                        sec <= sec + 1;
                end else
                    cnt_sysclk <= cnt_sysclk + 1;
            end

            if (inc_sec && !set_watch)
                sec <= (sec >= 59) ? 0 : sec + 1;
            if (inc_min && !set_watch)
                min <= (min >= 59) ? 0 : min + 1;
        end
    end
endmodule










module watch_top (
    input clk,
    input reset_p,
    input [2:0] btn,         // [0]: mode, [1]: inc_sec, [2]: inc_min
    output [7:0] seg_7,
    output [3:0] com,
    output [15:0] led
);

    // 버튼 엣지 검출
    wire btn_mode, inc_sec, inc_min;

    btn_cntr mode_btn(
        .clk(clk), 
        .reset_p(reset_p),
        .btn(btn[0]),
        .btn_pedge(btn_mode)
    );

    btn_cntr inc_sec_btn(
        .clk(clk), 
        .reset_p(reset_p),
        .btn(btn[1]),
        .btn_pedge(inc_sec)
    );

    btn_cntr inc_min_btn(
        .clk(clk), 
        .reset_p(reset_p),
        .btn(btn[2]),
        .btn_pedge(inc_min)
    );

    // 시계 모듈 인스턴스
    wire [7:0] sec, min;
    wire set_watch;

    watch u_watch (
        .clk(clk),
        .reset_p(reset_p),
        .btn_mode(btn_mode),
        .inc_sec(inc_sec),
        .inc_min(inc_min),
        .sec(sec),
        .min(min),
        .set_watch(set_watch)
    );

    // LED 표시
    assign led[0] = set_watch;

    // BCD 변환
    wire [15:0] sec_bcd, min_bcd;
    bin_to_dec bcd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));

    // FND 표시 (MM:SS)
    fnd_cntr fnd(
        .clk(clk),
        .reset_p(reset_p),
        .fnd_value({min_bcd[7:0], sec_bcd[7:0]}),
        .hex_bcd(1),
        .seg_7(seg_7),
        .com(com)
    );

endmodule








module seg_decoder (
    input  [3:0] digit_in,
    output reg [7:0] seg_out
);
    always @(*) begin
        case (digit_in)
                             // pgfe_dcba
            4'd0: seg_out = 8'b1100_0000;   // 0 (dp 꺼짐)
            4'd1: seg_out = 8'b1111_1001;   // 1
            4'd2: seg_out = 8'b1010_0100;   // 2
            4'd3: seg_out = 8'b1011_0000;   // 3
            4'd4: seg_out = 8'b1001_1001;   // 4
            4'd5: seg_out = 8'b1001_0010;   // 5
            4'd6: seg_out = 8'b1000_0010;   // 6
            4'd7: seg_out = 8'b1111_1000;   // 7
            4'd8: seg_out = 8'b1000_0000;   // 8
            4'd9: seg_out = 8'b1001_0000;   // 9
            4'hA: seg_out = 8'b1000_1000;   // A
            4'hB: seg_out = 8'b1000_0011;   // b
            4'hC: seg_out = 8'b1100_0110;   // C
            4'hD: seg_out = 8'b1010_0001;   // d
            4'hE: seg_out = 8'b1000_0110;   // E
            4'hF: seg_out = 8'b1000_1110;   // F
            default: seg_out = 8'b1111_1111;
        endcase
    end
endmodule

module anode_selector (
    input  [1:0] scan_count,
    output reg [3:0] an_out
);
    always @(*) begin
        case (scan_count)
            2'd0: an_out = 4'b1110; // an[0]
            2'd1: an_out = 4'b1101; // an[1]
            2'd2: an_out = 4'b1011; // an[2]
            2'd3: an_out = 4'b0111; // an[3]
            default: an_out = 4'b1111;
        endcase
    end
endmodule




 






 // 타이머

// module cook_timer(
//     input clk, reset_p,
//     input [3:0] btn,
//     output [7:0] seg_7,
//     output [3:0] com,
//     output reg alarm,
//     output [14:0] led
// );

//     wire btn_mode, inc_sec, inc_min, alarm_off;

//     btn_cntr mode_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
//     btn_cntr inc_sec_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(inc_sec));
//     btn_cntr inc_min_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(inc_min));
//     btn_cntr alarm_off_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(alarm_off));

//     reg start_set;
//     reg [7:0] sec, min;
//     reg [7:0] init_sec, init_min;
//     reg [26:0] cnt_sysclk;

//     // LED 표시
//     assign led[0] = start_set;

//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             start_set <= 0;
//             alarm <= 0;
//             sec <= 0;
//             min <= 0;
//             init_sec <= 0;
//             init_min <= 0;
//             cnt_sysclk <= 0;
//         end else begin
//             // === 1) 알람 상태 처리 ===
//             if (alarm) begin
//                 if (btn_mode || inc_sec || inc_min || alarm_off) begin
//                     // 알람 해제 + 초기값 복원
//                     alarm <= 0;
//                     sec <= init_sec;
//                     min <= init_min;
//                 end
//                 // 알람 중에는 다른 동작 금지
//             end 

//             // === 2) 알람이 아닐 때만 동작 ===
//             else begin
//                 // 스타트 버튼 (시간이 0이 아닐 때만)
//                 if (btn_mode && (sec != 0 || min != 0)) begin
//                     if (!start_set) begin
//                         init_sec <= sec;
//                         init_min <= min;
//                     end
//                     start_set <= ~start_set;
//                 end

//                 // 타이머 동작 중
//                 if (start_set) begin
//                     if (cnt_sysclk >= 99_999_999) begin
//                         cnt_sysclk <= 0;
//                         if (sec == 0) begin
//                             if (min > 0) begin
//                                 min <= min - 1;
//                                 sec <= 59;
//                             end else begin
//                                 start_set <= 0;
//                                 alarm <= 1;
//                             end
//                         end else begin
//                             sec <= sec - 1;
//                         end
//                     end else begin
//                         cnt_sysclk <= cnt_sysclk + 1;
//                     end
//                 end 
//                 // 타이머 정지 상태일 때 시간 조정 가능
//                 else begin
//                     if (inc_sec) begin
//                         if (sec >= 59) sec <= 0;
//                         else sec <= sec + 1;
//                     end
//                     if (inc_min) begin
//                         if (min >= 99) min <= 0;
//                         else min <= min + 1;
//                     end
//                 end
//             end
//         end
//     end

//     // BCD 변환 및 7세그 표시
//     wire [7:0] sec_bcd, min_bcd;
//     bin_to_dec bcd_sec(.bin(sec), .bcd(sec_bcd));
//     bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));

//     fnd_cntr fnd(
//         .clk(clk), .reset_p(reset_p),
//         .fnd_value({min_bcd, sec_bcd}),
//         .hex_bcd(1),
//         .seg_7(seg_7),
//         .com(com)
//     );

// endmodule


module cook (
    input clk,
    input reset_p,
    input start_btn,
    input inc_sec,
    input inc_min,
    input alarm_off_btn,
    output reg [7:0] sec,
    output reg [7:0] min,
    output reg start_set,
    output reg alarm
);

    reg [7:0] init_sec, init_min;
    reg [26:0] cnt_sysclk;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            start_set <= 0;
            alarm <= 0;
            sec <= 0;
            min <= 0;
            init_sec <= 0;
            init_min <= 0;
            cnt_sysclk <= 0;
        end else begin
            // 알람 상태 처리
            if (alarm) begin
                if (start_btn || inc_sec || inc_min || alarm_off_btn) begin
                    alarm <= 0;
                    sec <= init_sec;
                    min <= init_min;
                end
            end else begin
                // 스타트 버튼
                if (start_btn && (sec != 0 || min != 0)) begin
                    if (!start_set) begin
                        init_sec <= sec;
                        init_min <= min;
                    end
                    start_set <= ~start_set;
                end

                // 타이머 동작
                if (start_set) begin
                    if (cnt_sysclk >= 27'd99_999_999) begin
                        cnt_sysclk <= 0;
                        if (sec == 0) begin
                            if (min > 0) begin
                                min <= min - 1;
                                sec <= 8'd59;
                            end else begin
                                start_set <= 0;
                                alarm <= 1;
                            end
                        end else begin
                            sec <= sec - 1;
                        end
                    end else begin
                        cnt_sysclk <= cnt_sysclk + 1;
                    end
                end 
                // 타이머 정지 상태에서 시간 조정
                else begin
                    if (inc_sec) sec <= (sec >= 8'd59) ? 0 : sec + 1;
                    if (inc_min) min <= (min >= 8'd99) ? 0 : min + 1;
                end
            end
        end
    end
endmodule















module cook_timer (
    input clk,
    input reset_p,
    input [3:0] btn,      // [0]: start/모드, [1]: inc_sec, [2]: inc_min, [3]: alarm_off
    output [7:0] seg_7,
    output [3:0] com,
    output [14:0] led,
     output alarm  // <- 추가
);

    // 버튼 엣지 처리
    wire start_btn, inc_sec, inc_min, alarm_off_btn;

    btn_cntr start_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(start_btn)
    );
    btn_cntr sec_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(inc_sec)
    );
    btn_cntr min_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(inc_min)
    );
    btn_cntr alarm_off_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(alarm_off_btn)
    );

    // cook 모듈 인스턴스
    wire [7:0] sec, min;
    wire start_set;
    wire alarm;

    cook u_cook (
        .clk(clk),
        .reset_p(reset_p),
        .start_btn(start_btn),
        .inc_sec(inc_sec),
        .inc_min(inc_min),
        .alarm_off_btn(alarm_off_btn),
        .sec(sec),
        .min(min),
        .start_set(start_set),
        .alarm(alarm)
    );

    // LED 표시
    assign led[0] = start_set;
    assign led[1] = alarm;

    // BCD 변환
    wire [7:0] sec_bcd, min_bcd;
    bin_to_dec bcd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));

    // FND 표시
    fnd_cntr fnd(
        .clk(clk),
        .reset_p(reset_p),
        .fnd_value({min_bcd, sec_bcd}),
        .hex_bcd(1),
        .seg_7(seg_7),
        .com(com)
    );
endmodule





// module stop_watch(
//     input clk, reset_p,
//     input [3:0] btn,
//     output [7:0] seg_7,
//     output [3:0] com,
//     output [14:0] led
// );
//     wire btn_start, btn_lap, btn_clear;
//     reg [7:0] sec, csec;
//     wire [7:0] sec_bcd, csec_bcd;

//     // 버튼 처리 모듈
//     btn_cntr mode_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start)
//     );
//     btn_cntr lap_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap)
//     );
//     btn_cntr clear_btn(
//        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear)
//     );

//     // 시작/정지 토글
//     reg start_stop;
//     assign led[0] = start_stop;
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p)
//             start_stop <= 0;
//         else if (btn_start)
//             start_stop <= ~start_stop;
//         else if (btn_clear)
//             start_stop <= 0;
//     end

//     // 랩 기능
//     reg lap;
//     assign led[1] = lap;
//     reg [7:0] lap_sec, lap_csec;

//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             lap      <= 0;
//             lap_sec  <= 0;
//             lap_csec <= 0;
//         end
//         else if (btn_lap) begin
//             lap      <= ~lap;
//             lap_sec  <= sec;
//             lap_csec <= csec;
//         end
//         else if (btn_clear) begin
//             lap      <= 0;
//             lap_sec  <= 0;
//             lap_csec <= 0;
//         end
//     end

//     // 카운터
//     reg [26:0] cnt_sysclk;
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             sec        <= 0;
//             csec       <= 0;
//             cnt_sysclk <= 0;
//         end
//         else if (start_stop) begin
//             if (cnt_sysclk >= 999_999) begin
//                 cnt_sysclk <= 0;
//                 if (csec >= 99) begin
//                     csec <= 0;
//                     if (sec >= 99)
//                         sec <= 0;
//                     else
//                         sec <= sec + 1;
//                 end
//                 else begin
//                     csec <= csec + 1;
//                 end
//             end
//             else begin
//                 cnt_sysclk <= cnt_sysclk + 1;
//             end
//         end
//         else if (btn_clear) begin
//             sec        <= 0;
//             csec       <= 0;
//             cnt_sysclk <= 0;
//         end
//     end

//     // 랩 모드 시 랩 시간 표시
//     wire [7:0] fnd_sec, fnd_csec;
//     assign fnd_sec  = lap ? lap_sec  : sec;
//     assign fnd_csec = lap ? lap_csec : csec;

//     // 2진수 → BCD 변환
//     bin_to_dec bcd_sec(.bin(fnd_sec), .bcd(sec_bcd));
//     bin_to_dec bcd_csec(.bin(fnd_csec), .bcd(csec_bcd));

//     // FND 표시
//     fnd_cntr fnd(
//         .clk(clk), .reset_p(reset_p),
//         .fnd_value({sec_bcd, csec_bcd}),
//         .hex_bcd(1),
//         .seg_7(seg_7),
//         .com(com)
//     );

// endmodule



module stop (
    input clk,
    input reset_p,
    input start_btn,
    input lap_btn,
    input clear_btn,
    output reg [7:0] sec,
    output reg [7:0] csec,
    output reg [7:0] lap_sec,
    output reg [7:0] lap_csec,
    output reg start_stop,
    output reg lap
);

    reg [26:0] cnt_sysclk;

    // 시작/정지 토글
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            start_stop <= 0;
        else if (start_btn)
            start_stop <= ~start_stop;
        else if (clear_btn)
            start_stop <= 0;
    end

    // 랩 기능
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            lap      <= 0;
            lap_sec  <= 0;
            lap_csec <= 0;
        end
        else if (lap_btn) begin
            lap      <= ~lap;
            lap_sec  <= sec;
            lap_csec <= csec;
        end
        else if (clear_btn) begin
            lap      <= 0;
            lap_sec  <= 0;
            lap_csec <= 0;
        end
    end

    // 카운터
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            sec        <= 0;
            csec       <= 0;
            cnt_sysclk <= 0;
        end
        else if (start_stop) begin
            if (cnt_sysclk >= 999_999) begin
                cnt_sysclk <= 0;
                if (csec >= 99) begin
                    csec <= 0;
                    if (sec >= 99)
                        sec <= 0;
                    else
                        sec <= sec + 1;
                end
                else begin
                    csec <= csec + 1;
                end
            end
            else begin
                cnt_sysclk <= cnt_sysclk + 1;
            end
        end
        else if (clear_btn) begin
            sec        <= 0;
            csec       <= 0;
            cnt_sysclk <= 0;
        end
    end
endmodule


module stop_watch(
    input clk, reset_p,
    input [3:0] btn,          // [0]: start, [1]: lap, [2]: clear
    output [7:0] seg_7,
    output [3:0] com,
    output [14:0] led
);

    wire start_btn, lap_btn, clear_btn;
    wire [7:0] sec, csec, lap_sec, lap_csec;
    wire start_stop, lap_flag;

    // 버튼 엣지 처리
    btn_cntr start_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(start_btn)
    );
    btn_cntr lap_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(lap_btn)
    );
    btn_cntr clear_counter(
        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(clear_btn)
    );

    // stop 모듈 인스턴스
    stop u_stop(
        .clk(clk),
        .reset_p(reset_p),
        .start_btn(start_btn),
        .lap_btn(lap_btn),
        .clear_btn(clear_btn),
        .sec(sec),
        .csec(csec),
        .lap_sec(lap_sec),
        .lap_csec(lap_csec),
        .start_stop(start_stop),
        .lap(lap_flag)
    );

    // LED 표시
    assign led[0] = start_stop;
    assign led[1] = lap_flag;

    // 랩 모드 시 랩 시간 표시
    wire [7:0] fnd_sec  = lap_flag ? lap_sec  : sec;
    wire [7:0] fnd_csec = lap_flag ? lap_csec : csec;

    // 2진수 → BCD 변환
    wire [7:0] sec_bcd, csec_bcd;
    bin_to_dec bcd_sec(.bin(fnd_sec), .bcd(sec_bcd));
    bin_to_dec bcd_csec(.bin(fnd_csec), .bcd(csec_bcd));

    // FND 표시
    fnd_cntr fnd(
        .clk(clk), .reset_p(reset_p),
        .fnd_value({sec_bcd, csec_bcd}),
        .hex_bcd(1),
        .seg_7(seg_7),
        .com(com)
    );

endmodule



// module multi_clock_system(
//     input clk,
//     input reset_p,
//     input [1:0] sw,       // 모드 선택 스위치: 00=일반시계, 01=쿡타이머, 10=스톱워치
//     input [3:0] btn,      // 공통 버튼 입력
//     output [7:0] seg_7,
//     output [15:0] led,
//     output alarm,
//     output [3:0] com
// );

//     // 모드 신호
//     wire [1:0] mode = sw;

//     // === DEMUX: btn 분배 ===
//     // 4비트 btn 신호를 각 모드별로 분배해 줌
//     reg [3:0] btn_watch, btn_timer, btn_stopwatch;

//     always @(*) begin
//         btn_watch = 4'b0;
//         btn_timer = 4'b0;
//         btn_stopwatch = 4'b0;

//         case (mode)
//             2'b00: btn_watch = btn;        // 시계 모드만 버튼 신호 전달
//             2'b01: btn_timer = btn;        // 쿡타이머 모드만 버튼 전달
//             2'b10: btn_stopwatch = btn;    // 스톱워치 모드만 버튼 전달
//             default: begin
//                 btn_watch = 4'b0;
//                 btn_timer = 4'b0;
//                 btn_stopwatch = 4'b0;
//             end
//         endcase
//     end

//     // 1. 일반 시계 모듈 출력
//     wire [7:0] watch_seg_7;
//     wire [3:0] watch_com;
//     wire [15:0] watch_led;    // watch_top led 출력

//     watch_top u_watch(
//         .clk(clk),
//         .reset_p(reset_p),
//         .btn(btn_watch[2:0]),      // 시계는 3개 버튼만 사용
//         .seg_7(watch_seg_7),
//         .com(watch_com),
//         .led(watch_led)
//     );

//     // 2. 쿡 타이머 모듈 출력
//     wire [7:0] timer_seg_7;
//     wire [3:0] timer_com;
//     wire timer_alarm;
//     wire [14:0] timer_led;

//     cook_timer u_cook_timer(
//         .clk(clk),
//         .reset_p(reset_p),
//         .btn(btn_timer),
//         .seg_7(timer_seg_7),
//         .com(timer_com),
//         .alarm(timer_alarm),
//         .led(timer_led)
//     );

//     // 3. 스톱워치 모듈 출력
//     wire [7:0] stopwatch_seg_7;
//     wire [3:0] stopwatch_com;
//     wire [14:0] stopwatch_led;

//     stop_watch u_stopwatch(
//         .clk(clk),
//         .reset_p(reset_p),
//         .btn(btn_stopwatch),
//         .seg_7(stopwatch_seg_7),
//         .com(stopwatch_com),
//         .led(stopwatch_led)
//     );

//     // === MUX: 출력 선택 ===
//     reg [7:0] seg_7_mux;
//     reg [3:0] com_mux;
//     reg [15:0] led_mux;
//     reg alarm_mux;

//     always @(*) begin
//         case (mode)
//             2'b00: begin
//                 seg_7_mux = watch_seg_7;
//                 com_mux   = watch_com;
//                 led_mux   = watch_led;
//                 alarm_mux = 1'b0;      // 시계는 알람 없음
//             end
//             2'b01: begin
//                 seg_7_mux = timer_seg_7;
//                 com_mux   = timer_com;
//                 led_mux   = {1'b0, timer_led}; // 15비트 → 16비트 확장
//                 alarm_mux = timer_alarm;
//             end
//             2'b10: begin
//                 seg_7_mux = stopwatch_seg_7;
//                 com_mux   = stopwatch_com;
//                 led_mux   = {1'b0, stopwatch_led};
//                 alarm_mux = 1'b0;      // 스톱워치 알람 없음
//             end
//             default: begin
//                 seg_7_mux = 8'hFF;
//                 com_mux   = 4'b1111;
//                 led_mux   = 16'b0;
//                 alarm_mux = 1'b0;
//             end
//         endcase
//     end

//     assign seg_7 = seg_7_mux;
//     assign com   = com_mux;
//     assign led   = led_mux;
//     assign alarm = alarm_mux;

// endmodule



module multi_clock(
    input clk,
    input reset_p,
    input [1:0] mode,        // 모드 선택: 00=시계, 01=쿡타이머, 10=스톱워치
    input [3:0] btn,         // 공통 버튼 입력
    output [7:0] seg_7,
    output [3:0] com,
    output [15:0] led,
    output alarm
);

    // === DEMUX: 버튼 분배 ===
    reg [3:0] btn_watch, btn_timer, btn_stopwatch;

    always @(*) begin
        btn_watch = 4'b0;
        btn_timer = 4'b0;
        btn_stopwatch = 4'b0;

        case (mode)
            2'b00: btn_watch = btn;
            2'b01: btn_timer = btn;
            2'b10: btn_stopwatch = btn;
            default: begin
                btn_watch = 4'b0;
                btn_timer = 4'b0;
                btn_stopwatch = 4'b0;
            end
        endcase
    end

    // 1. 일반 시계
    wire [7:0] watch_seg_7;
    wire [3:0] watch_com;
    wire [15:0] watch_led;

    watch_top u_watch(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn_watch[2:0]),
        .seg_7(watch_seg_7),
        .com(watch_com),
        .led(watch_led)
    );

    // 2. 쿡타이머
    wire [7:0] timer_seg_7;
    wire [3:0] timer_com;
    wire timer_alarm;
    wire [14:0] timer_led;

    cook_timer u_cook_timer(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn_timer),
        .seg_7(timer_seg_7),
        .com(timer_com),
        .alarm(timer_alarm),
        .led(timer_led)
    );

    // 3. 스톱워치
    wire [7:0] stopwatch_seg_7;
    wire [3:0] stopwatch_com;
    wire [14:0] stopwatch_led;

    stop_watch u_stopwatch(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn_stopwatch),
        .seg_7(stopwatch_seg_7),
        .com(stopwatch_com),
        .led(stopwatch_led)
    );

    // === MUX: 출력 선택 ===
    reg [7:0] seg_7_mux;
    reg [3:0] com_mux;
    reg [15:0] led_mux;
    reg alarm_mux;

    always @(*) begin
        case (mode)
            2'b00: begin
                seg_7_mux = watch_seg_7;
                com_mux   = watch_com;
                led_mux   = watch_led;
                alarm_mux = 1'b0;
            end
            2'b01: begin
                seg_7_mux = timer_seg_7;
                com_mux   = timer_com;
                led_mux   = {1'b0, timer_led};
                alarm_mux = timer_alarm;
            end
            2'b10: begin
                seg_7_mux = stopwatch_seg_7;
                com_mux   = stopwatch_com;
                led_mux   = {1'b0, stopwatch_led};
                alarm_mux = 1'b0;
            end
            default: begin
                seg_7_mux = 8'hFF;
                com_mux   = 4'b1111;
                led_mux   = 16'b0;
                alarm_mux = 1'b0;
            end
        endcase
    end

    assign seg_7 = seg_7_mux;
    assign com   = com_mux;
    assign led   = led_mux;
    assign alarm = alarm_mux;

endmodule



module multi_clock_system(
    input clk,
    input reset_p,
    input [1:0] sw,       // 모드 선택 스위치
    input [3:0] btn,      // 공통 버튼 입력
    output [7:0] seg_7,
    output [15:0] led,
    output alarm,
    output [3:0] com
);

    multi_clock u_multi_clock(
        .clk(clk),
        .reset_p(reset_p),
        .mode(sw),
        .btn(btn),
        .seg_7(seg_7),
        .led(led),
        .alarm(alarm),
        .com(com)
    );

endmodule


module dht11_top(
    input clk, reset_p,
    inout dht11_data,
    output [7:0] seg_7, 
    output [3:0] com,
    output [15:0] led);
    
    wire [7:0] humidity, temperature;
    dht11_cntr dht11(
        clk, reset_p,
        dht11_data,
        humidity, temperature, led);
    
    wire [7:0] humi_bcd, tmpr_bcd;
    bin_to_dec bcd_humi(.bin(humidity), .bcd(humi_bcd));
    bin_to_dec bcd_tmpr(.bin(temperature), .bcd(tmpr_bcd));   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value({humi_bcd, tmpr_bcd}),
        .hex_bcd(1),
        .seg_7(seg_7), .com(com));

    endmodule
    



module hcsr_top(
    input clk, reset_p,
    input echo,           // 초음파 echo 입력
    output trig,          // 초음파 trig 출력
    output [7:0] seg_7, 
    output [3:0] com,
    output [15:0] led
);


    wire [15:0] distance;
    hcsr_cntr hcsr(
        .clk(clk), 
        .reset_p(reset_p),
        .echo(echo),
        .trig(trig),
        .distance(distance),
        .led(led)           // LED로 상태/카운터 확인
    );


    wire [15:0] dist_bcd;
    bin_to_dec bcd_dist(
        .bin(distance[15:0]),   // 8비트 거리값만 변환 (0~255 cm)
        .bcd(dist_bcd)
    );

    fnd_cntr fnd(
        .clk(clk), 
        .reset_p(reset_p),
        .fnd_value(dist_bcd),  // 거리값 표시
        .hex_bcd(1),
        .seg_7(seg_7), 
        .com(com)
    );

endmodule


module keypad_top(
    input clk,
    input reset_p,
    input [3:0] row,        // 키패드 행 입력
    output [3:0] column,    // 키패드 열 출력
    output [7:0] seg_7,     // 7세그먼트 출력
    output [3:0] com,       // 7세그먼트 공통단자
    output [15:0] led       // LED 출력 (상태 표시용)
);

    wire [3:0] key_value;
    wire key_valid;
    
    // 키패드 컨트롤러 인스턴스
    keypad_cntr keypad(
        .clk(clk),
        .reset_p(reset_p),
        .row(row),
        .column(column),
        .key_value(key_value),
        .key_valid(key_valid)
    );
    
    // 키 값을 16비트 BCD로 확장 (4자리 표시)
    wire [15:0] key_bcd;
    assign key_bcd = {12'h000, key_value}; // 상위 12비트는 0, 하위 4비트에 키 값
    
    // FND 컨트롤러 인스턴스
    fnd_cntr fnd(
        .clk(clk),
        .reset_p(reset_p),
        .fnd_value(key_bcd),    // 키 값 표시
        .hex_bcd(1),            // BCD 모드
        .seg_7(seg_7),
        .com(com)
    );

    
    
    // LED로 키 상태 표시
    assign led[15:4] = 12'h000;        // 상위 12개 LED는 끄기
    assign led[3:0] = key_valid ? key_value : 4'h0;  // 키가 눌리면 하위 4개 LED에 키 값 표시

endmodule
module i2c_txtlcd_top(
    input clk, reset_p,
    input [3:0] btn,
    output scl, sda,
    output [15:0] led,       // 쉼표 추가
    input [3:0] row,         // 키패드 행 입력
    output [3:0] column);

    wire [3:0] btn_pedge;
    btn_cntr btn0(clk, reset_p, btn[0], btn_pedge[0]);
    btn_cntr btn1(clk, reset_p, btn[1], btn_pedge[1]);
    btn_cntr btn2(clk, reset_p, btn[2], btn_pedge[2]);
    btn_cntr btn3(clk, reset_p, btn[3], btn_pedge[3]);
    
    integer cnt_sysclk;
    reg count_clk_e;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) cnt_sysclk = 0;
        else if(count_clk_e) cnt_sysclk = cnt_sysclk + 1;
        else cnt_sysclk = 0;
    end
    
    reg [7:0] send_buffer;
    reg send, rs;
    wire busy;
    i2c_lcd_send_byte send_byte(clk, reset_p, 7'h27, send_buffer, send, rs, scl, sda, busy, led);
    
    wire [3:0] key_value;
    wire key_valid;
    keypad_cntr keypad(
        clk, 
        reset_p,
        row,
        column,
        key_value,
        key_valid
    );

    wire key_valid_pedge;
    edge_detector_p key_ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(key_valid),
        .p_edge(key_valid_pedge) // 오타 수정
    );


    
    assign led[3:0] = row[3:0];
    assign led[4] = key_valid;

    localparam IDLE                 = 6'b00_0001;
    localparam INIT                 = 6'b00_0010;
    localparam SEND_CHARACTER       = 6'b00_0100;
    localparam SHIFT_RIGHT_DISPLAY  = 6'b00_1000;
    localparam SHIFT_LEFT_DISPLAY   = 6'b01_0000;
    localparam SEND_KEY             = 6'b10_0000;

    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) state = IDLE;
        else state = next_state;
    end
    
    reg init_flag;
    reg [10:0] cnt_data;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            next_state = IDLE;
            init_flag = 0;
            count_clk_e = 0;
            send = 0;
            send_buffer = 0;
            rs = 0;
            cnt_data = 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(init_flag) begin
                        if(btn_pedge[0]) next_state = SEND_CHARACTER;
                        if(btn_pedge[1]) next_state = SHIFT_RIGHT_DISPLAY;
                        if(btn_pedge[2]) next_state = SHIFT_LEFT_DISPLAY;
                        if(key_valid_pedge) next_state = SEND_KEY; // 오타 수정
                    end
                    else begin
                        if(cnt_sysclk <= 32'd80_000_00) begin
                            count_clk_e = 1;
                        end
                        else begin
                            next_state = INIT;
                            count_clk_e = 0;
                        end
                    end
                end
                INIT: begin
                    if(busy) begin
                        send = 0;
                        if(cnt_data >= 6) begin
                            cnt_data = 0;
                            next_state = IDLE;
                            init_flag = 1;
                        end
                    end
                    else if(!send) begin
                        case(cnt_data)
                            0: send_buffer = 8'h33;
                            1: send_buffer = 8'h32;
                            2: send_buffer = 8'h28;
                            3: send_buffer = 8'h0c;
                            4: send_buffer = 8'h01;
                            5: send_buffer = 8'h06;
                        endcase
                        send = 1;
                        cnt_data = cnt_data + 1;
                    end
                end
                SEND_CHARACTER: begin
                    if(busy) begin
                        next_state = IDLE;
                        send = 0;
                        if(cnt_data >= 25) cnt_data = 0;
                        cnt_data = cnt_data + 1;
                    end
                    else begin
                        rs = 1;
                        send_buffer = "a" + cnt_data;
                        send = 1;
                    end
                end
                SHIFT_RIGHT_DISPLAY: begin
                    if(busy) begin
                        next_state = IDLE;
                        send = 0;
                    end
                    else begin
                        rs = 0;
                        send_buffer = 8'h1c;
                        send = 1;
                    end
                end
                SHIFT_LEFT_DISPLAY: begin
                    if(busy) begin
                        next_state = IDLE;
                        send = 0;
                    end
                    else begin
                        rs = 0;
                        send_buffer = 8'h18;
                        send = 1;
                    end
                end
                SEND_KEY: begin
                    if(busy) begin
                        next_state = IDLE;
                        send = 0;
                    end
                    else begin
                        rs = 1;
                        if(key_value < 10) send_buffer = "0" + key_value;
                        else if (key_value == 10) send_buffer = "+";
                         else if (key_value == 11) send_buffer = "-";
                          else if (key_value == 12) send_buffer = "C";
                           else if (key_value == 13) send_buffer = "/";
                            else if (key_value == 14) send_buffer = "*";
                            else if (key_value == 15) send_buffer = "=";

                        send = 1;
                    end
                end
            endcase

        end
    end
endmodule

module led_pwm_top(
    input clk,
    input reset_p,
    output led_r,
    output led_g,
    output led_b
);

    // 카운터 생성
    reg [29:0] cnt;
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    // PWM 인스턴스화 (위치 연결 방식 유지)
pwm_Nfreq_Nstep #(.duty_step_N(100)  ) u_pwm_led_r (
    .clk(clk),
    .reset_p(reset_p),
    .duty(cnt[27:21]), // 7비트 duty
    .pwm(led_r)
);

    pwm_Nfreq_Nstep#(.duty_step_N(200)  ) u_pwm_led_g (
        clk,
        reset_p,
        cnt[28:21],
        led_g
    );

    pwm_Nfreq_Nstep #(.duty_step_N(300)  )u_pwm_led_b (
        clk,
        reset_p,
        cnt[29:22],
        led_b
    );

endmodule
module sg90_top(
    input clk, 
    input reset_p,
    output sg90
);
reg inc_flag;
reg [31:0] step;   // step은 reg
reg [31:0] cnt;    // cnt는 reg

wire cnt_pedge;
edge_detector_p key_ed(
    .clk(clk), 
    .reset_p(reset_p), 
    .cp(cnt[22]),
    .p_edge(cnt_pedge)
);

// 카운터
always @(posedge clk or posedge reset_p) begin
    if (reset_p)
        cnt = 0;
    else
        cnt = cnt + 1;
end

// step 증가/감소
always @(posedge clk or posedge reset_p) begin
    if (reset_p) begin
        step = 8;      // 시작 최소값
        inc_flag = 1;
    end
    else if (cnt_pedge) begin
        if (inc_flag) begin
            if (step >= 189) 
                inc_flag = 0;
            else 
                step = step + 1;  // 정수 증가
        end
        else begin
            if (step <= 18) 
                inc_flag = 1;
            else 
                step = step - 1;  // 정수 감소
        end
    end
end


// PWM 연결
pwm_Nfreq_Nstep #(.pwm_freq(50), .duty_step_N(1440)) pwm_sg90 (
    .clk(clk),
    .reset_p(reset_p),
    .duty(step[11:0]),  // 7비트만 사용
    .pwm(sg90)
);

endmodule


module adc_top_6(
    input clk,
    input reset_p,
    input vauxp6,
    input vauxn6,
    output [7:0] seg_7,
    output [3:0] com,
    output [15:0] led
);

wire [4:0] channel_out;
wire eoc_out;
wire [15:0] do_out;

// XADC 인스턴스
xadc_wiz_0 adc(
    .daddr_in({2'b00, channel_out}), // Address bus
    .dclk_in(clk),                    // Clock
    .den_in(eoc_out),                 // Enable
    .reset_in(reset_p),               // Reset
    .vauxp6(vauxp6),
    .vauxn6(vauxn6),
    .channel_out(channel_out),
    .do_out(do_out),
    .eoc_out(eoc_out)
);

reg [11:0] adc_value;

// EOC 포지티브 에지 검출
wire eoc_pedge;
edge_detector_p eoc_ed(
    .clk(clk),
    .reset_p(reset_p),
    .cp(eoc_out),
    .p_edge(eoc_pedge)
);

// ADC 값 저장
always @(posedge clk or posedge reset_p) begin
    if (reset_p)
        adc_value <= 0;
    else if (eoc_pedge)
        adc_value <= do_out[15:8]; // 상위 12비트 저장
end

// FND 표시
fnd_cntr fnd(
    .clk(clk),
    .reset_p(reset_p),
    .fnd_value(adc_value),  // 거리값 표시
    .hex_bcd(4'b0),     // 상수 연결
    .seg_7(seg_7),
    .com(com)
);

endmodule

module adc_sequence2_top(
    input clk, reset_p,
    input vauxp6, 
    input vauxn6, 
    input vauxp14,
    input vauxn14,
    output [7:0] seg_7,
    output [3:0] com,
    output led_g, led_b,
    output [15:0] led,
    output motor_in1, motor_in2
);
    wire [4:0] channel_out;
    wire [15:0] do_out;
    wire eoc_out;
    xadc_wiz_1 joystick
          (
          .daddr_in({2'b00, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .vauxp14(vauxp14),             // Auxiliary channel 14
          .vauxn14(vauxn14),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)             // End of Conversion Signal
          );
          

assign motor_in1 = 1'b1;   // 방향 결정
assign motor_in2 = 1'b0;   // 반대 방향



    // 변환된 ADC 값 저장 레지스터 (12비트만 사용)
    reg [11:0] adc_value_x, adc_value_y;
    
    // eoc_out의 양엣지 검출기
    wire eoc_pedge;
    edge_detector_p echo_ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(eoc_out),        // 입력: eoc_out 신호
        .p_edge(eoc_pedge)); // 출력: eoc_out의 양엣지 발생 시 1 클럭 동안 High
    
    // ADC 값 저장 로직
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            adc_value_x = 0;               // 리셋 시 값 초기화
            adc_value_y = 0;               // 리셋 시 값 초기화
        end
        else if(eoc_pedge) begin
            case(channel_out[3:0])
                6:adc_value_x = do_out[15:4];    // 변환 완료 시 상위 12비트만 adc_value에 저장
                14:adc_value_y = do_out[15:4];
            endcase
        end
    end
    
    wire [7:0] x_bcd, y_bcd;
    
    bin_to_dec bcd_x(.bin(adc_value_x[11:6]), .bcd(x_bcd));
    bin_to_dec bcd_y(.bin(adc_value_y[11:6]), .bcd(y_bcd));
    
    // FND(7세그먼트) 표시 모듈
    fnd_cntr fnd_x(
        .clk(clk), 
        .reset_p(reset_p),
        .fnd_value({x_bcd,y_bcd}), // 입력값: ADC 변환 결과
        .hex_bcd(1),           // 0=HEX 그대로 표시, 1=BCD 변환해서 표시
        .seg_7(seg_7), 
        .com(com));
        
   
          pwm_Nfreq_Nstep#(.duty_step_N(128), .pwm_freq(100)  ) u_pwm_led_g (
        clk,
        reset_p,
       adc_value_x[11:4],
        led_g
    );

    pwm_Nfreq_Nstep #(.duty_step_N(128), .pwm_freq(100)  )u_pwm_led_b (
        clk,
        reset_p,
        adc_value_y[11:4],
        led_b
    );

endmodule