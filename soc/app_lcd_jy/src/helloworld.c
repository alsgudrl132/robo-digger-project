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
#define UART_BASEADDR XPAR_AXI_UARTLITE_1_BASEADDR 
#define BTN_BASE XPAR_MYIP_BTN_0_BASEADDR           
#define IIC_ADDR XPAR_AXI_IIC_0_BASEADDR           

uint32_t adc_scaled[4] = {0,0,0,0};
XIic iic_instance;

// LCD 제어
void lcdCommand(uint8_t command)
{
    uint8_t high_nibble = command & 0xf0;
    uint8_t low_nibble = (command << 4) & 0xf0;
    uint8_t i2c_buffer[4];
    
    i2c_buffer[0] = high_nibble | 0x0C;
    i2c_buffer[1] = high_nibble | 0x08;
    i2c_buffer[2] = low_nibble | 0x0C;
    i2c_buffer[3] = low_nibble | 0x08;
    
    XIic_Send(IIC_ADDR, 0x27, i2c_buffer, 4, XIIC_STOP);
}

void lcdData(uint8_t data)
{
    uint8_t high_nibble = data & 0xf0;
    uint8_t low_nibble = (data << 4) & 0xf0;
    uint8_t i2c_buffer[4];
    
    i2c_buffer[0] = high_nibble | 0x0D;
    i2c_buffer[1] = high_nibble | 0x09;
    i2c_buffer[2] = low_nibble | 0x0D;
    i2c_buffer[3] = low_nibble | 0x09;
    
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

void displayExcavatorStatus(int mode, uint32_t *joystick_vals)
{
    char line1[17];
    char line2[17];
    
    switch(mode) {
        case 0: sprintf(line1, "BUCKET DOWN"); break;
        case 1: sprintf(line1, "WORK MODE"); break;
        case 2: sprintf(line1, "DRIVE MODE"); break;
        case 3: sprintf(line1, "BUCKET UP"); break;
        default: sprintf(line1, "EXCAVATOR READY"); break;
    }
    
    sprintf(line2, "STATUS: OK");
    
    lcdClear();
    moveCursor(0, 0);
    lcdString(line1);
    moveCursor(1, 0);
    lcdString(line2);
}

// UART 통신
int safe_uart_send_string(const char* str) {
    if (str == NULL) return -1;
    
    int len = strlen(str);
    if (len == 0) return 0;
    
    for(int timeout = 0; timeout < 1000; timeout++) {
        if(!(Xil_In32(UART_BASEADDR + 0x8) & 0x08)) break;
        usleep(10);
    }
    
    for(int i = 0; i < len; i++) {
        int retry = 0;
        while((Xil_In32(UART_BASEADDR + 0x8) & 0x08) && retry < 5000) {
            retry++;
            usleep(1);
        }
        
        if(retry >= 5000) {
            xil_printf("UART timeout at char %d\r\n", i);
            return -1;
        }
        
        Xil_Out8(UART_BASEADDR + 0x4, str[i]);
        usleep(50);
    }
    
    usleep(1000);
    return 0;
}

uint32_t read_raw_btn() {
    return Xil_In32(BTN_BASE + 0x8);
}

int send_button_mode_data(uint32_t pressed_buttons, int mode) {
    char buf[32];
    
    int len = snprintf(buf, sizeof(buf)-1, "BTN=%02u MODE=%d\n", 
                      pressed_buttons, mode);
    
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_button_mode_data\r\n");
        return -1;
    }
    
    return safe_uart_send_string(buf);
}

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

int send_joystick_mode_data(uint32_t *vals, int mode) {
    char buf[64];
    
    for(int i = 0; i < 4; i++) {
        if(vals[i] > 4095) {
            xil_printf("Invalid ADC value[%d]: %u\r\n", i, vals[i]);
            return -1;
        }
    }
    
    int len = snprintf(buf, sizeof(buf)-1,
        "MODE=%d X1=%04u Y1=%04u X2=%04u Y2=%04u\n",
        mode, vals[3], vals[2], vals[1], vals[0]);
    
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_joystick_mode_data\r\n");
        return -1;
    }
    
    return safe_uart_send_string(buf);
}

int send_neutral_mode(int mode) {
    char buf[32];
    
    int len = snprintf(buf, sizeof(buf)-1, "MODE=%d NEUTRAL=1\n", mode);
    
    if (len >= sizeof(buf)) {
        xil_printf("Buffer overflow in send_neutral_mode\r\n");
        return -1;
    }
    
    return safe_uart_send_string(buf);
}

int main() {
    init_platform();
    print("=== Excavator Control System - Basys3 ===\n\r");
    
    XIic_Initialize(&iic_instance, IIC_ADDR);
    lcdInit();
    
    usleep(100000);
    if(safe_uart_send_string("INIT Excavator_Ready\n") == 0) {
        print("System ready\r\n");
    } else {
        print("UART init failed\r\n");
    }
    
    const uint32_t RAW_MIN[4] = {120, 120, 120, 120};
    const uint32_t RAW_MAX[4] = {3000, 3000, 3000, 3000};
    const uint32_t NEUTRAL[4] = {2048, 2048, 2048, 2048};
    const uint32_t DEADZONE = 300;
    
    u32 adc_raw[4];
    int idle_counter = 0;
    int current_mode = 1;
    int display_counter = 0;
    int send_counter = 0;
    
    uint32_t prev_btn_state = 0xF;
    
    displayExcavatorStatus(current_mode, adc_scaled);
    
    while(1) {
        uint32_t btn_data = read_raw_btn();

        if ((btn_data & 0x1) == 0 && send_counter % 10 == 0) {
            send_button_mode_data(0x1, current_mode);
            xil_printf("Bucket Down\n");
        }
        if ((btn_data & 0x8) == 0 && send_counter % 10 == 0) {
            send_button_mode_data(0x8, current_mode);
            xil_printf("Bucket Up\n");
        }

        uint32_t pressed_1_2 = (prev_btn_state & (~btn_data)) & 0x6;
        if (pressed_1_2) {
            if (pressed_1_2 & 0x2) {
                current_mode = 1;
                xil_printf("Work Mode\n");
                send_button_mode_data(0x2, current_mode);
                displayExcavatorStatus(current_mode, adc_scaled);
            }
            if (pressed_1_2 & 0x4) {
                current_mode = 2;
                xil_printf("Drive Mode\n");
                send_button_mode_data(0x4, current_mode);
                displayExcavatorStatus(current_mode, adc_scaled);
            }
        }

        prev_btn_state = (prev_btn_state & 0x9) | (btn_data & 0x6);
        
        for(int i=0;i<4;i++) {
            adc_raw[i] = Xil_In32(MYIP_BASEADDR + i*4) & 0xFFF;
            adc_scaled[i] = remap_adc(adc_raw[i], RAW_MIN[i], RAW_MAX[i]);
        }
        
        int active = 0;
        for(int i=0;i<4;i++) {
            if(abs((int)adc_scaled[i] - (int)NEUTRAL[i]) > DEADZONE) {
                active = 1;
                break;
            }
        }
        
        if(send_counter % 10 == 0) {
            if(active) {
                idle_counter = 0;
                
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
                    xil_printf("Neutral\n");
                }
            }
        }
        
        display_counter++;
        if(display_counter >= 500) {
            displayExcavatorStatus(current_mode, adc_scaled);
            display_counter = 0;
        }
        
        send_counter++;
        usleep(1000);
    }
    
    cleanup_platform();
    return 0;
}