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

// LCD 관련 함수들
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

// 포크레인(굴삭기) 상태 표시 함수
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

// UART 송신 (한 글자)
int simple_uart_send_char(char c) {
    int timeout = 10000;
    while (Xil_In32(UART_BASEADDR + 0x8) & 0x8) {
        if(--timeout <= 0) {
            xil_printf("UART TX timeout!\r\n");
            return -1;
        }
    }
    Xil_Out8(UART_BASEADDR + 0x4, c);
    return 0;
}

// UART 문자열 전송
int simple_uart_send_string(const char* str) {
    while(*str) {
        if(simple_uart_send_char(*str++) != 0) return -1;
    }
    return 0;
}

// 버튼 읽기
uint32_t read_raw_btn() {
    return Xil_In32(BTN_BASE + 0x8);
}

// 버튼 + 모드 데이터 전송
int send_button_mode_data(uint32_t pressed_buttons, int mode) {
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "BTN:%u,MODE:%d\r\n", pressed_buttons, mode);
    return simple_uart_send_string(buf);
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

// 조이스틱 + 모드 데이터 전송
int send_joystick_mode_data(uint32_t *vals, int mode) {
    char buf[128];
    int len = snprintf(buf, sizeof(buf),
        "MODE:%d\r\nX1:%u\r\nY1:%u\r\nX2:%u\r\nY2:%u\r\nEND\r\n",
        mode, vals[0], vals[1], vals[2], vals[3]);
    return simple_uart_send_string(buf);
}

// 중립값 전송
int send_neutral_mode(int mode) {
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "MODE:%d\r\nNEUTRAL\r\n", mode);
    return simple_uart_send_string(buf);
}

int main() {
    init_platform();
    print("=== Excavator Control System - Basys3 ===\n\r");
    
    // I2C LCD 초기화
    XIic_Initialize(&iic_instance, IIC_ADDR);
    lcdInit();
    
    // 초기 연결 테스트
    if(simple_uart_send_string("INIT:Excavator_Ready\r\n") == 0) {
        print("DEBUG: UART OK\r\n");
    } else {
        print("ERROR: UART failed!\r\n");
    }
    
    // ADC 보정 상수
    const uint32_t RAW_MIN[4] = {8, 8, 7, 7};
    const uint32_t RAW_MAX[4] = {3000, 3000, 3000, 3000};
    const uint32_t NEUTRAL[4] = {2048, 2048, 2048, 2048};
    const uint32_t DEADZONE = 200;
    
    u32 adc_raw[4];
    int idle_counter = 0;
    int current_mode = -1;  // 현재 모드 (-1: 대기 상태)
    int display_counter = 0;
    
    // 버튼 디바운싱 변수들
    uint32_t prev_btn_state = 0xF;  // 초기값: 모든 버튼이 눌리지 않은 상태
    uint32_t debounce_count = 0;
    
    // 초기 LCD 표시
    displayExcavatorStatus(current_mode, adc_scaled);
    
    while(1) {
        // 버튼 상태 읽기 및 디바운싱 처리
        uint32_t btn_data = read_raw_btn();
        
        if (btn_data != prev_btn_state) {
            debounce_count++;
            if (debounce_count > 50) {  // 디바운싱 임계값
                uint32_t pressed = prev_btn_state & (~btn_data);  // 새로 눌린 버튼
                
                if (pressed) {
                    // 버튼에 따른 처리
                    if (pressed & 0x1) {
                        // 버튼 0: 버킷 다운 (모드 변경 없음)
                        send_button_mode_data(pressed, current_mode);
                        xil_printf("Bucket Down Action\n");
                    }
                    else if (pressed & 0x2) {
                        // 버튼 1: 워크 모드 변경
                        current_mode = 1;
                        xil_printf("Work Mode Selected\n");
                        send_button_mode_data(pressed, current_mode);
                        displayExcavatorStatus(current_mode, adc_scaled);
                    }
                    else if (pressed & 0x4) {
                        // 버튼 2: 드라이브 모드 변경 - 로컬 LCD만 업데이트, UART로는 현재 모드 전송
                        current_mode = 2;
                        xil_printf("Drive Mode Selected\n");
                        send_button_mode_data(pressed, current_mode);
                        displayExcavatorStatus(current_mode, adc_scaled);  // 로컬 LCD만 업데이트
                    }
                    else if (pressed & 0x8) {
                        // 버튼 3: 버킷 업 (모드 변경 없음)
                        send_button_mode_data(pressed, current_mode);
                        xil_printf("Bucket Up Action\n");
                    }
                }
                
                prev_btn_state = btn_data;
                debounce_count = 0;
            }
        } else {
            debounce_count = 0;
        }
        
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
        
        if(active) {
            idle_counter = 0;
            send_joystick_mode_data(adc_scaled, current_mode);
            xil_printf("[MODE:%d] X1=%u,Y1=%u,X2=%u,Y2=%u\r\n",
                current_mode, adc_scaled[0], adc_scaled[1],
                adc_scaled[2], adc_scaled[3]);
        } else {
            idle_counter++;
            if(idle_counter == 1) send_neutral_mode(current_mode);
        }
        
        // LCD 주기적 업데이트 (500ms마다)
        display_counter++;
        if(display_counter >= 500) {
            displayExcavatorStatus(current_mode, adc_scaled);
            display_counter = 0;
        }
        
        usleep(1000); // 1ms
    }
    
    cleanup_platform();
    return 0;
}