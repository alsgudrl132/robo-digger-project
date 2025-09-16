`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 02:29:33 PM
// Design Name: 
// Module Name: countre
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


module fnd_cntr(
    input clk,
    input reset_p,
    input [15:0] fnd_value,
    input hex_bcd,
    output [7:0] seg_7,
    output [3:0] com
);

    wire [15:0] bcd_value;

    // 12비트 이하만 BCD 변환 (예: 초 0~59)
    bin_to_dec bcd(
        .bin(fnd_value[11:0]),
        .bcd(bcd_value)
    );

    reg [16:0] clk_div;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    anode_selector ring_counter_com(
        .scan_count(clk_div[16:15]),
        .an_out(com)
    );

    reg [3:0] digit_value;

    // 선택 신호에 따라 BCD 또는 원래 값 사용
    wire [15:0] out_value;
    assign out_value = hex_bcd ? fnd_value : bcd_value;

    // 비동기 리셋 포함, com 신호에 따라 출력할 4비트 digit 선택
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            digit_value <= 4'd0;
        end else begin
            case (com)
                4'b1110: digit_value <= out_value[3:0];
                4'b1101: digit_value <= out_value[7:4];
                4'b1011: digit_value <= out_value[11:8];
                4'b0111: digit_value <= out_value[15:12];
                default: digit_value <= 4'd0;
            endcase
        end
    end

    seg_decoder edc(
        .digit_in(digit_value),
        .seg_out(seg_7)
    );

endmodule


module debounce (
    input clk,
    input btn_in,
    output reg btn_out
);

    reg [15:0] count;
    reg btn_sync_0, btn_sync_1;
    wire stable = (count == 16'hFFFF);

    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk) begin
        if(btn_sync_1 == btn_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if(stable)
                btn_out <= btn_sync_1;
        end
    end

endmodule

module btn_cntr(
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_nedge
);

wire debounce_btn;

// 디바운스 처리
debounce btn_0 (
    .clk(clk),
    .btn_in(btn),
    .btn_out(debounce_btn)
);

// 엣지 검출기
edge_detector_p mode_ed (
    .clk(clk),
    .reset_p(reset_p),
    .cp(debounce_btn),
    .p_edge(btn_pedge),
    .n_edge(btn_nedge)
);

endmodule



module dht11_cntr(
    input clk, reset_p,
    inout dht11_data,
    output reg [7:0] humidity, temperature,
    output [15:0] led);

    localparam S_IDLE       = 6'b00_0001;
    localparam S_LOW_18MS   = 6'b00_0010;
    localparam S_HIGH_20US  = 6'b00_0100;
    localparam S_LOW_80US   = 6'b00_1000;
    localparam S_HIGH_80US  = 6'b01_0000;
    localparam S_READ_DATA  = 6'b10_0000;
    
    localparam S_WAIT_PEDGE = 2'b01;
    localparam S_WAIT_NEDGE = 2'b10;
    
    wire clk_usec_nedge;
    clock_div_100 us_clk(.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            count_usec <= 0;
        else if(clk_usec_nedge && count_usec_e)
            count_usec <= count_usec + 1;
        else if(!count_usec_e)
            count_usec <= 0;
    end
    
    wire dht_nedge, dht_pedge;
    edge_detector_p dht_ed(
        .clk(clk), .reset_p(reset_p), .cp(dht11_data),
        .p_edge(dht_pedge), .n_edge(dht_nedge));
        
    reg dht11_buffer;
    reg dht11_data_out_e;
    assign dht11_data = dht11_data_out_e ? dht11_buffer : 1'bz;
    
    reg [5:0] state, next_state;
    assign led[5:0] = state;
    reg [1:0] read_state;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            state <= S_IDLE;
        else
            state <= next_state;
    end
    
    reg [39:0] temp_data;
    reg [5:0] data_count;
    assign led[11:6] = data_count;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state       <= S_IDLE;
            temp_data        <= 0;
            data_count       <= 0;
            dht11_data_out_e <= 0;
            read_state       <= S_WAIT_PEDGE;
            humidity         <= 0;
            temperature      <= 0;
        end
        else begin
            case(state)
                S_IDLE: begin
                    if(count_usec < 22'd3_000_000) begin
                        count_usec_e      <= 1;
                        dht11_data_out_e  <= 0;
                    end
                    else begin
                        count_usec_e      <= 0;
                        next_state        <= S_LOW_18MS;
                    end
                end

                S_LOW_18MS: begin
                    if(count_usec < 22'd18_000) begin
                        count_usec_e      <= 1;
                        dht11_data_out_e  <= 1;
                        dht11_buffer      <= 0;
                    end
                    else begin
                        count_usec_e      <= 0;
                        next_state        <= S_HIGH_20US;
                        dht11_data_out_e  <= 0;
                    end
                end

                S_HIGH_20US: begin
                    count_usec_e <= 1;
                    if(count_usec > 22'd100_000) begin
                        next_state  <= S_IDLE;
                        data_count  <= 0;
                    end
                    else if(dht_nedge) begin
                        next_state  <= S_LOW_80US;
                        count_usec_e <= 0;
                    end
                end

                S_LOW_80US: begin
                    count_usec_e <= 1;
                    if(count_usec > 22'd100_000) begin
                        next_state  <= S_IDLE;
                        data_count  <= 0;
                    end
                    else if(dht_pedge) begin
                        next_state  <= S_HIGH_80US;
                        count_usec_e <= 0;
                    end
                end

                S_HIGH_80US: begin
                    if(dht_nedge)
                        next_state <= S_READ_DATA;
                end

                S_READ_DATA: begin
                    case(read_state)
                        S_WAIT_PEDGE: begin
                            if(dht_pedge) 
                                read_state <= S_WAIT_NEDGE;
                            count_usec_e <= 0;
                        end
                        S_WAIT_NEDGE: begin
                            if(dht_nedge) begin
                                read_state <= S_WAIT_PEDGE;
                                data_count <= data_count + 1;
                                if(count_usec < 50)
                                    temp_data <= {temp_data[38:0], 1'b0};
                                else
                                    temp_data <= {temp_data[38:0], 1'b1};
                            end
                            else begin
                                count_usec_e <= 1;
                                if(count_usec > 22'd100_000) begin
                                    next_state <= S_IDLE;
                                    data_count <= 0;
                                    read_state <= S_WAIT_PEDGE;
                                end
                            end
                        end
                    endcase

                    if(data_count >= 40) begin
                        next_state  <= S_IDLE;
                        data_count  <= 0;
                        humidity    <= temp_data[39:32];
                        temperature <= temp_data[23:16];
                    end
                end

                default: next_state <= S_IDLE;
            endcase
        end
    end
endmodule
// 초음파 센서(HC-SR04)용 컨트롤러
// - 1us(마이크로초) 틱으로 상태머신(FSM) 동작
// - TRIG 10us 펄스 → ECHO 하이 구간 길이 측정 → cm로 환산(distance = time_us / 58)
// - 타임아웃 처리(에코 미수신/범위 초과 시 0xFFFF 표기)

module hcsr_cntr(
    input        clk,        // 시스템 기준 클럭
    input        reset_p,    // 비동기 리셋(양의 로직, 1:리셋)
    input        echo,       // HC-SR04의 ECHO 입력(하이: 왕복 시간 카운트)
    output reg   trig,       // HC-SR04의 TRIG 출력(10us 하이 펄스)
    output reg [15:0] distance, // 계산된 거리(cm). 실패/초과 시 16'hFFFF
    output [15:0] led        // 디버그용 LED(하단 assign 참고)
);

    // -----------------------------
    // FSM 상태 정의
    // -----------------------------
    localparam S_IDLE         = 3'd0; // 대기 → 트리거 준비
    localparam S_TRIG_HIGH    = 3'd1; // TRIG를 10us 동안 High
    localparam S_WAIT_ECHO_H  = 3'd2; // ECHO가 High가 되길 대기(타임아웃 30ms)
    localparam S_COUNT_ECHO   = 3'd3; // ECHO High 기간(왕복 시간) 카운트
    localparam S_DONE         = 3'd4; // 결과 정리 → 다음 측정까지 휴지시간

    // -----------------------------
    // 1us 단위 틱 생성기(음수 에지 명칭이지만 사실상 1us 주기의 펄스 입력으로 사용)
    // clk_usec_nedge가 '1'이 되는 순간을 posedge로 샘플링 → 1us마다 한 번 실행되는 효과
    // -----------------------------
    wire clk_usec_nedge;
    clock_div_100 us_clk (
        .clk(clk),
        .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge) // 1us 간격으로 펄스(또는 토글) 발생한다고 가정
    );

    // -----------------------------
    // 상태/카운터 레지스터
    // -----------------------------
    reg [2:0]  state;        // FSM 현재 상태
    reg [19:0] count_usec;   // 1us 단위 카운터(최대 수만 us까지 카운트)
    reg        count_start;  // (현재 로직에서는 기능적으로 사용되지 않음: 디버그/훗날 확장용)

    // -----------------------------
    // LED 출력 매핑
    //  - led[2:0]  : 현재 상태 표시
    //  - led[15:3] : 하위 13비트에 count_usec(디버깅/상태 관찰용)
    // -----------------------------
    assign led[2:0]   = state;
    assign led[15:3]  = count_usec[12:0];

    // -----------------------------
    // FSM + 카운터 + 거리계산
    // 모든 로직은 1us 틱(clk_usec_nedge)의 양엣지에서 동작
    // -----------------------------
    always @(posedge clk_usec_nedge or posedge reset_p) begin
        if (reset_p) begin
            // 리셋: 모든 레지스터 초기화
            state       <= S_IDLE;
            count_usec  <= 0;
            count_start <= 0;
            distance    <= 0;
            trig        <= 0;
        end else begin
            // 기본값: TRIG는 매 사이클 Low로 내려둠
            // (필요한 상태에서만 1로 올려 10us 펄스를 만듦)
            trig <= 0;

            case (state)
                // -----------------------------------------
                // 1) 대기: 바로 TRIG를 만들기 위한 준비
                // -----------------------------------------
                S_IDLE: begin
                    state       <= S_TRIG_HIGH; // 다음 상태: TRIG High 구간
                    count_usec  <= 0;           // 펄스 폭 측정 위해 카운터 0으로
                end

                // -----------------------------------------
                // 2) TRIG High: 10us 동안 TRIG=1 유지
                // -----------------------------------------
                S_TRIG_HIGH: begin
                    trig        <= 1;               // TRIG 신호 High 유지
                    count_usec  <= count_usec + 1;  // 1us 틱마다 +1
                    if (count_usec >= 10)           // 10us 경과 시
                        state <= S_WAIT_ECHO_H;     // ECHO 상승을 기다리는 상태로
                end

                // -----------------------------------------
                // 3) ECHO High 대기: ECHO가 1이 될 때까지 대기
                //    (센서가 초음파를 발사하고 반사파를 수신하면 ECHO가 1로 올라감)
                //    타임아웃: 30ms(=30000us) 넘으면 실패 처리
                // -----------------------------------------
                S_WAIT_ECHO_H: begin
                    count_usec <= count_usec + 1;   // 대기 시간 카운트
                    if (echo) begin                 // ECHO가 High로 변하면
                        state       <= S_COUNT_ECHO;
                        count_usec  <= 0;           // ECHO High 구간 길이 측정 시작
                        count_start <= 1;           // (현재 로직에선 미사용)
                    end
                    else if (count_usec >= 30000) begin // 30ms 넘도록 ECHO 미수신
                        state       <= S_DONE;      // 실패로 간주하고 종료 상태로
                        distance    <= 16'hFFFF;   // "측정 불가" 표시
                        count_usec  <= 0;
                    end
                end

                // -----------------------------------------
                // 4) ECHO High 카운트: ECHO가 1인 동안 1us씩 카운트
                //    - ECHO가 0으로 떨어지는 순간까지의 카운트를 보유
                //    - 4m(왕복 약 23.2ms) 초과 시 범위 초과 처리
                // -----------------------------------------
                S_COUNT_ECHO: begin
                    count_usec <= count_usec + 1;   // ECHO 하이 구간 시간 누적
                    if (!echo) begin                // ECHO가 Low로 떨어졌다면
                        state    <= S_DONE;         // 측정 종료
                        // 거리(cm) = (시간_us) / 58
                        // 58 상수의 근거는 아래 "왜 /58?" 설명 참고
                        distance <= count_usec / 58;
                    end
                    else if (count_usec >= 23200) begin // 약 4m 왕복 한계(23.2ms)
                        state     <= S_DONE;
                        distance  <= 16'hFFFF;      // "측정 범위 초과" 표기
                    end
                end

                // -----------------------------------------
                // 5) 완료 및 재트리거 대기: 결과를 잠시 유지
                //    - 60ms 정도 쉬었다가 다시 S_IDLE로 돌아감(연속 측정)
                // -----------------------------------------
                S_DONE: begin
                    count_usec <= count_usec + 1;
                    if (count_usec >= 60000) begin  // 약 60ms 휴지
                        state      <= S_IDLE;       // 다음 측정 시작
                        count_usec <= 0;
                    end
                end

                // (방어적 default를 두고 싶다면 여기에 추가 가능)
            endcase
        end
    end
endmodule

module keypad_cntr(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] column,
    output reg [3:0] key_value,
    output reg key_valid);

    localparam [4:0]SCAN_0       = 5'b00001;
    localparam [4:0]SCAN_1       = 5'b00010;
    localparam [4:0]SCAN_2       = 5'b00100;
    localparam [4:0]SCAN_3       = 5'b01000;
    localparam [4:0]KEY_PROCESS  = 5'b10000;
    
    reg [19:0] clk_10ms; // 대략 10ms
    always @(posedge clk) clk_10ms = clk_10ms + 1;
    
    wire clk_10ms_nedge, clk_10ms_pedge;
    edge_detector_p ms_10_ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(clk_10ms[19]),
        .p_edge(clk_10ms_pedge),  // 상승 엣지
        .n_edge(clk_10ms_nedge)   // 하강 엣지
    );
    
    reg [4:0] state, next_state;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) state = SCAN_0;
        else if (clk_10ms_pedge) state = next_state;
    end
    




// 상태별 LED 표시

// 내부에서 wire로 상태 확인

    always @*begin  // always @(*) begin 과 동일 
        case(state)
            SCAN_0      : begin
                if(row == 0) next_state = SCAN_1;
                else next_state = KEY_PROCESS;
            end
            SCAN_1      : begin
                if(row == 0) next_state = SCAN_2;
                else next_state = KEY_PROCESS;
            end
            SCAN_2      : begin
                if(row == 0) next_state = SCAN_3;
                else next_state = KEY_PROCESS;
            end
            SCAN_3      : begin
                if(row == 0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
            KEY_PROCESS : begin    
                if(row == 0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
            default : next_state = SCAN_1;
        endcase
    end
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            column = 4'b0001;
            key_value = 0;
            key_valid = 0;
        end
        else if(clk_10ms_nedge)begin
            case(state)
                SCAN_0      : begin
                    column = 4'b0001;
                    key_valid = 0;
                end
                SCAN_1      : begin
                    column = 4'b0010;
                    key_valid = 0;
                end
                SCAN_2      : begin
                    column = 4'b0100;
                    key_valid = 0;
                end
                SCAN_3      : begin
                    column = 4'b1000;
                    key_valid = 0;
                end
                KEY_PROCESS : begin   
                    key_valid = 1;
                    case({column, row})
                        8'b0001_0001 : key_value = 4'h7;  //7  0
                        8'b0001_0010 : key_value = 4'h8;  //8  1
                        8'b0001_0100 : key_value = 4'h9;  //9 
                        8'b0001_1000 : key_value = 4'ha;  //A
                        8'b0010_0001 : key_value = 4'h4;  //4
                        8'b0010_0010 : key_value = 4'h5;  //5
                        8'b0010_0100 : key_value = 4'h6;  //6
                        8'b0010_1000 : key_value = 4'hb;  //B
                        8'b0100_0001 : key_value = 4'h1;  //1
                        8'b0100_0010 : key_value = 4'h2;  //2
                        8'b0100_0100 : key_value = 4'h3;  //3
                        8'b0100_1000 : key_value = 4'he;  //E
                        8'b1000_0001 : key_value = 4'hc;  //C
                        8'b1000_0010 : key_value = 4'h0;  //0
                        8'b1000_0100 : key_value = 4'hf;  //F
                        8'b1000_1000 : key_value = 4'hd;  // D
                    endcase
                end                   
            endcase
        end
    end
    
endmodule


// 주소랑 데이터 주고 컴 스타트 1을 주면 i2c통신을 한다!!
module I2C_master(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] data,
    input rd_wr, comm_start,
    output reg scl, sda,
    output [15:0] led);

    localparam IDLE         = 7'b000_0001;
    localparam COMM_START   = 7'b000_0010;
    localparam SEND_ADDR    = 7'b000_0100;
    localparam RD_ACK       = 7'b000_1000;
    localparam SEND_DATA    = 7'b001_0000;
    localparam SCL_STOP     = 7'b010_0000;
    localparam COMM_STOP    = 7'b100_0000;
    
    wire clk_usec_nedge;
    clock_div_100 us_clk(.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge));
    
    wire comm_start_pedge;
    edge_detector_p comm_start_ed(
        .clk(clk), .reset_p(reset_p), .cp(comm_start),
        .p_edge(comm_start_pedge));
        
    wire scl_nedge, scl_pedge;
    edge_detector_p scl_ed(
        .clk(clk), .reset_p(reset_p), .cp(scl),
        .p_edge(scl_pedge), .n_edge(scl_nedge));
        
    reg [2:0] count_usec5;
    reg scl_e;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            count_usec5 = 0;
            scl = 0;
        end
        else if(scl_e)begin
            if(clk_usec_nedge)begin
                if(count_usec5 >= 4)begin
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end
        end
        else if(!scl_e)begin
            count_usec5 = 0;
            scl = 1;
        end
    end
    
    reg [6:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    wire [7:0] addr_rd_wr;
    assign addr_rd_wr = {addr, rd_wr};
    reg [2:0] cnt_bit;
    reg stop_flag;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            scl_e = 0;
            sda = 1;
            cnt_bit = 7;
            stop_flag = 0;
        end
        else begin
            case(state)
                IDLE        : begin
                    scl_e = 0;
                    sda = 1;
                    if(comm_start_pedge)next_state = COMM_START;
                end
                COMM_START  : begin
                    sda = 0;
                    scl_e = 1;
                    next_state = SEND_ADDR;
                end
                SEND_ADDR   : begin
                    if(scl_nedge)sda = addr_rd_wr[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                RD_ACK      : begin
                    if(scl_nedge)sda = 'bz;
                    else if(scl_pedge)begin
                        if(stop_flag)begin
                            stop_flag = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            stop_flag = 1;
                            next_state = SEND_DATA;
                        end
                    end
                end 
                SEND_DATA   : begin
                    if(scl_nedge)sda = data[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                SCL_STOP    : begin
                    if(scl_nedge)sda = 0;
                    if(scl_pedge)next_state = COMM_STOP;
                end
                COMM_STOP   : begin
                    if(count_usec5 >= 3)begin
                        scl_e = 0;
                        sda = 1;
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end
endmodule



module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr, 
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy,
    output [15:0] led);

    localparam IDLE                     = 6'b00_0001;
    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
    localparam SEND_DISABLE             = 6'b10_0000;
    
    wire clk_usec_nedge;
    clock_div_100 us_clk(.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge));
    
    reg [7:0] data;
    reg comm_start;
    
    wire send_pedge;
    edge_detector_p send_ed(
        .clk(clk), .reset_p(reset_p), .cp(send),
        .p_edge(send_pedge));
        
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end    
    
    I2C_master master(clk, reset_p, addr, data, 1'b0, comm_start, scl, sda);
    
    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)begin
            state = IDLE;
        end
        else begin
            state = next_state;
        end
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            comm_start = 0;
            count_usec_e = 0;
            data = 0;
            busy = 0;
        end
        else begin
            case(state)
                IDLE                    :begin
                    if(send_pedge)begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                        busy = 1;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE  :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[3:0], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_DISABLE            :begin 
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = IDLE;
                        count_usec_e = 0;
                        comm_start = 0;
                        busy = 0;
                    end
                end
            endcase
        end
    end
endmodule



module pwm_Nfreq_Nstep(
    input clk, reset_p,
    input [31:0] duty,
    output reg pwm
);

parameter sys_clk_freq = 100_000_000;
parameter pwm_freq = 10_000;
parameter duty_step_N = 300;
parameter temp = sys_clk_freq / pwm_freq / duty_step_N / 2;

integer cnt;
reg pwm_freqN;

always @(posedge clk, posedge reset_p) begin
    if (reset_p) begin
        cnt = 0;
        pwm_freqN = 0;
    end
    else begin
        if (cnt >= temp - 1) begin
            cnt = 0;
            pwm_freqN = ~pwm_freqN;
        end
        else cnt = cnt + 1;
    end
end

wire pwm_freqN_negedge;

edge_detector_p pwm_freqN_edge(
    .clk(clk),
    .reset_p(reset_p),
    .cp(pwm_freqN),
    .n_edge(pwm_freqN_negedge)
);

integer cnt_duty;
always @(posedge clk, posedge reset_p) begin
    if (reset_p) begin
        cnt_duty = 0;
        pwm = 0;
    end
    else if (pwm_freqN_negedge) begin
        if(cnt_duty >= duty_step_N) 
            cnt_duty = 0;
        else 
            cnt_duty = cnt_duty + 1;

        if (cnt_duty < duty)
            pwm = 1;
        else
            pwm = 0;
    end
end

endmodule








// 50hz가 나올려면 100,000,000  / 200,000 나와야 50 hz


