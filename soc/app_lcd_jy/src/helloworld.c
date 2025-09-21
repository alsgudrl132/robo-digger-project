#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xiic_l.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"

#define MYIP_BASEADDR XPAR_MYIP_ADC_NEW_0_BASEADDR
#define UART_BASEADDR XPAR_AXI_UARTLITE_1_BASEADDR // HC-05 연결 UART Lite
#define BTN_BASE XPAR_MYIP_BTN_0_BASEADDR           // 버튼 베이스 주소 추가
#define IIC_ADDR XPAR_AXI_IIC_0_BASEADDR           // I2C LCD 주소

uint32_t adc_scaled[4] = {0,0,0,0};
XIic iic_instance;

// LCD 관련 함수들 (기존과 동일)
void lcdCommand(uint8_t command)
{
    uint8_t high_nibble, low_nibble;
    uint8_t i2c_buffer[4];
    
    high_nibble = command & 0xf0;
    low_nibble = (command << 4) & 0xf0;
    
    i2c_buffer[0] = high_nibble | 0x04 | 0x08; // en=1, rs=0, rw=0, backlight=1
    i2c_buffer[1] = high_nibble | 0x00 | 0x08; // en=0, rs=0, rw=0, backlight=1
    i2c_buffer[2] = low_nibble | 0x04 | 0x08;  // en=1, rs=0, rw=0, backlight=1
    i2c_buffer[3] = low_nibble | 0x00 | 0x08;  // en=0, rs=0, rw=0, backlight=1
    
    XIic_Send(IIC_ADDR, 0x27, i2c_buffer, 4, XIIC_STOP);
}

void lcdData(uint8_t data)
{
    uint8_t high_nibble, low_nibble;
    uint8_t i2c_buffer[4];
    
    high_nibble = data & 0xf0;
    low_nibble = (data << 4) & 0xf0;
    
    i2c_buffer[0] = high_nibble | 0x05 | 0x08;
    i2c_buffer[1] = high_nibble | 0x01 | 0x08;
    i2c_buffer[2] = low_nibble | 0x05 | 0x08;
    i2c_buffer[3] = low_nibble | 0x01 | 0x08;
    
    XIic_Send(IIC_ADDR, 0x27, i2c_buffer, 4, XIIC_STOP);
}

void lcdInit()
{
    msleep(50);
    lcdCommand(0x33);
    msleep(5);
    lcdCommand(0x32);
    msleep(5);
    lcdCommand(0x28);
    msleep(5);
    lcdCommand(0x0C);
    msleep(5);
    lcdCommand(0x06);
    msleep(5);
    lcdCommand(0x01);
    msleep(2);
}

void lcdString(char *str)
{
    while (*str) lcdData(*str++);
}

void moveCursor(uint8_t row, uint8_t col)
{
    lcdCommand(0x80 | row << 6 | col);
}

void lcdClear()
{
    lcdCommand(0x01);
    msleep(2);
}

// 포클레인(굴삭기) 상태 표시 함수
void displayExcavatorStatus(int mode, uint32_t *joystick_vals)
{
    char line1[17];  // LCD 한 줄은 16자 + null
    char line2[17];
    
    // 첫 번째 줄: 현재 모드
    switch(mode) {
        case 0:
            sprintf(line1, "BUCKET DOWN");
            break;
        case 1:
            sprintf(line1, "WORK MODE");
            break;
        case 2:
            sprintf(line1, "DRIVE MODE");
            break;
        case 3:
            sprintf(line1, "BUCKET UP");
            break;
        default:
            sprintf(line1, "EXCAVATOR READY");
            break;
    }
    
    // 두 번째 줄: 빈 줄 또는 상태 메시지
    sprintf(line2, "STATUS: OK");
    
    lcdClear();
    moveCursor(0, 0);
    lcdString(line1);
    moveCursor(1, 0);
    lcdString(line2);
}

// =================== 개선된 UART 송신 함수 ===================

// 더 안전한 UART 문자열 전송 (흐름 제어 추가)
int safe_uart_send_string(const char* str) {
    if (str == NULL) return -1;
    
    int len = strlen(str);
    if (len == 0) return 0;
    
    // 전송 전 충분한 대기
    for(int timeout = 0; timeout < 1000; timeout++) {
        if(!(Xil_In32(UART_BASEADDR + 0x8) & 0x08)) break;
        usleep(10);
    }
    
    // 천천히 한 문자씩 전송 (흐름 제어)
    for(int i = 0; i < len; i++) {
        int retry = 0;
        while((Xil_In32(UART_BASEADDR + 0x8) & 0x08) && retry < 5000) {
            retry++;
            usleep(1); // 1μs 대기
        }
        
        if(retry >= 5000) {
            xil_printf("UART timeout at char %d\r\n", i);
            return -1;
        }
        
        Xil_Out8(UART_BASEADDR + 0x4, str[i]);
        
        // 문자 간 작은 지연 (수신측 처리 시간 확보)
        usleep(50); // 50μs 대기 (전송 속도 조절)
    }
    
    // 전송 완료 후 추가 대기
    usleep(1000); // 1ms 대기
    
    return 0;
}

// 버튼 읽기
uint32_t read_raw_btn() {
    return Xil_In32(BTN_BASE + 0x8);
}

// **수정된 버튼 + 모드 데이터 전송 (고정 길이 형식)**
int send_button_mode_data(uint32_t pressed_buttons, int mode) {
    char buf[32];
    memset(buf, 0, sizeof(buf));
    
    // 고정 길이로 전송 (BTN은 2자리, MODE는 1자리)
    int len = snprintf(buf, sizeof(buf)-1, "BTN=%02u MODE=%d\n", 
                      pressed_buttons, mode);
    
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_button_mode_data\r\n");
        return -1;
    }
    
    return safe_uart_send_string(buf);
}

// ADC 보정
uint32_t remap_adc(uint32_t raw, uint32_t raw_min, uint32_t raw_max) {
    if(raw_max <= raw_min) return 0;
    if(raw <= raw_min) return 0;
    if(raw >= raw_max) return 4095;
    
    uint64_t numer = (uint64_t)(raw - raw_min) * 4095;
    uint32_t denom = raw_max - raw_min;
    uint32_t result = (uint32_t)(numer / denom);
    if(result > 4095) result = 4095;
    return result;
}

// **핵심 수정: 조이스틱 + 모드 데이터 전송 (고정 4자리 형식)**
int send_joystick_mode_data(uint32_t *vals, int mode) {
    char buf[64];
    
    // 버퍼 초기화
    memset(buf, 0, sizeof(buf));
    
    // **고정 4자리 형식으로 전송 (0001, 0123, 4095 등)**
    // 각 값을 4자리로 고정하여 파싱 문제 해결
    int len = snprintf(buf, sizeof(buf)-1,
        "MODE=%d X1=%04u Y1=%04u X2=%04u Y2=%04u\n",
        mode, vals[3], vals[2], vals[1], vals[0]);
    
    // 길이 체크
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_joystick_mode_data\r\n");
        return -1;
    }
    
    // 데이터 검증 (범위 체크)
    for(int i = 0; i < 4; i++) {
        if(vals[i] > 4095) {
            xil_printf("Invalid ADC value[%d]: %u\r\n", i, vals[i]);
            return -1;
        }
    }
    
    // 안전한 전송
    return safe_uart_send_string(buf);
}

// **수정된 NEUTRAL 전송 (고정 형식)**
int send_neutral_mode(int mode) {
    char buf[32];
    memset(buf, 0, sizeof(buf));
    
    // 고정 형식으로 NEUTRAL 전송
    int len = snprintf(buf, sizeof(buf)-1, "MODE=%d NEUTRAL=1\n", mode);
    
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_neutral_mode\r\n");
        return -1;
    }
    
    return safe_uart_send_string(buf);
}

// =================== 메인 함수 ===================
int main() {
    init_platform();
    print("=== Excavator Control System - Basys3 (Fixed Format) ===\n\r");
    
    // I2C LCD 초기화
    XIic_Initialize(&iic_instance, IIC_ADDR);
    lcdInit();
    
    // 초기 연결 테스트 (천천히)
    usleep(100000); // 100ms 대기
    if(safe_uart_send_string("INIT Excavator_Ready\n") == 0) {
        print("DEBUG: UART OK\r\n");
    } else {
        print("ERROR: UART failed!\r\n");
    }
    
    // ADC 보정 상수
    const uint32_t RAW_MIN[4] = {120, 120, 120, 120};
    const uint32_t RAW_MAX[4] = {3000, 3000, 3000, 3000};
    const uint32_t NEUTRAL[4] = {2048, 2048, 2048, 2048};
    const uint32_t DEADZONE = 300;
    
    u32 adc_raw[4];
    int idle_counter = 0;
    int current_mode = 1;
    int display_counter = 0;
    int send_counter = 0; // 전송 간격 조절
    
    // 버튼 디바운싱 변수들
    uint32_t prev_btn_state = 0xF;
    uint32_t debounce_count = 0;
    
    // 초기 LCD 표시
    displayExcavatorStatus(current_mode, adc_scaled);
    
    while(1) {
        // 버튼 상태 읽기 및 디바운싱 처리
        uint32_t btn_data = read_raw_btn();

        // 0x1,0x8 버튼 반복 처리 (전송 간격 조절)
        if ((btn_data & 0x1) == 0 && send_counter % 10 == 0) {
            send_button_mode_data(0x1, current_mode);
            xil_printf("Bucket Down Action\n");
        }
        if ((btn_data & 0x8) == 0 && send_counter % 10 == 0) {
            send_button_mode_data(0x8, current_mode);
            xil_printf("Bucket Up Action\n");
        }

        // 0x2,0x4 버튼 단발 처리
        uint32_t pressed_1_2 = (prev_btn_state & (~btn_data)) & 0x6;
        if (pressed_1_2) {
            if (pressed_1_2 & 0x2) {
                current_mode = 1;
                xil_printf("Work Mode Selected\n");
                send_button_mode_data(0x2, current_mode);
                displayExcavatorStatus(current_mode, adc_scaled);
            }
            if (pressed_1_2 & 0x4) {
                current_mode = 2;
                xil_printf("Drive Mode Selected\n");
                send_button_mode_data(0x4, current_mode);
                displayExcavatorStatus(current_mode, adc_scaled);
            }
        }

        prev_btn_state = (prev_btn_state & 0x9) | (btn_data & 0x6);
        
        // ADC 읽기
        for(int i=0;i<4;i++) {
            adc_raw[i] = Xil_In32(MYIP_BASEADDR + i*4) & 0xFFF;
            adc_scaled[i] = remap_adc(adc_raw[i], RAW_MIN[i], RAW_MAX[i]);
        }
        
        // 데드존 체크
        int active = 0;
        for(int i=0;i<4;i++) {
            if(abs((int)adc_scaled[i] - (int)NEUTRAL[i]) > DEADZONE) {
                active = 1;
                break;
            }
        }
        
        // 전송 주기 조절 (10ms마다 전송)
        if(send_counter % 10 == 0) {
            if(active) {
                idle_counter = 0;
                
                // 조이스틱 데이터 전송
                int result = send_joystick_mode_data(adc_scaled, current_mode);
                if (result != 0) {
                    xil_printf("UART send failed!\n");
                }
                
                xil_printf("MODE=%d,X1=%04u,Y1=%04u,X2=%04u,Y2=%04u\n",
                    current_mode, adc_scaled[3], adc_scaled[2],
                    adc_scaled[1], adc_scaled[0]);
            } else {
                idle_counter++;
                if(idle_counter == 1) {
                    send_neutral_mode(current_mode);
                    xil_printf("Sent NEUTRAL\n");
                }
            }
        }
        
        // LCD 주기적 업데이트 (500ms마다)
        display_counter++;
        if(display_counter >= 500) {
            displayExcavatorStatus(current_mode, adc_scaled);
            display_counter = 0;
        }
        
        send_counter++;
        usleep(1000); // 1ms - 전송 간격 조절
    }
    
    cleanup_platform();
    return 0;
}