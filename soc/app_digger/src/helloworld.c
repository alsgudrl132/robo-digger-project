/******************************************************************************
* 라인 단위로 메시지를 처리하는 HC-05 파싱 코드
******************************************************************************/

#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>

typedef unsigned char u8;

#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR
#define USB_UART_BASEADDR   XPAR_XUARTLITE_1_BASEADDR
#define HANDLE_ADDR         XPAR_MYIP_HANDLE_0_BASEADDR

#define PWM_0_ADDR XPAR_MYIP_PWM_0_BASEADDR
#define PWM_1_ADDR XPAR_MYIP_PWM_1_BASEADDR  // Y1용 PWM
#define PWM_2_ADDR XPAR_MYIP_PWM_2_BASEADDR  // X2용 PWM  
#define PWM_3_ADDR XPAR_MYIP_PWM_3_BASEADDR  // Y2용 PWM
#define SYS_CLK_FREQ  100000000  
#define REG_DUTY      0x0
#define REG_TEMP      0x4
#define REG_DUTYSTEP  0x8

#define BUFFER_SIZE   512
#define LINE_BUFFER_SIZE 256
#define RANGE_MIN     1500
#define RANGE_MAX     3000

XUartLite Uart_HC05;
static int x1_angle = 90;
static int y1_angle = 90;  // Y1 각도
static int x2_angle = 90;  // X2 각도
static int y2_angle = 90;  // Y2 각도

// 라인 누적용 버퍼
static char line_buffer[LINE_BUFFER_SIZE];
static int line_index = 0;

// =================== 함수 선언 ===================
void servoHandler(int mode, int x1, int y1, int x2, int y2);
uint32_t angle_to_duty(uint32_t angle, uint32_t duty_step);
void pwm_set(uint32_t base, uint32_t duty, uint32_t pwm_freq, uint32_t duty_step);
void process_complete_message(const char* message);
int extract_number_after_key(const char* str, const char* key);
void control_servo(int value, int* angle, uint32_t pwm_addr, const char* name); 
void control_move(int y1_val, int y2_val);

// =================== simple UART 함수 ===================
int simple_uart_send_char(char c) {
    int timeout = 10000;
    while (Xil_In32(USB_UART_BASEADDR + 0x8) & 0x8) {
        if(--timeout <= 0) {
            return -1;
        }
    }
    Xil_Out8(USB_UART_BASEADDR + 0x4, c);
    return 0;
}

void simple_uart_send_string(const char *str) {
    while(*str) {
        simple_uart_send_char(*str++);
    }
}

// =================== 파싱 함수 ===================
int extract_number_after_key(const char* str, const char* key) {
    char* pos = strstr(str, key);
    if (pos == NULL) return 0;
    
    pos = strchr(pos, '=');
    if (pos == NULL) return 0;
    
    pos++; // '=' 다음으로 이동
    
    // 음수 처리
    int sign = 1;
    if (*pos == '-') {
        sign = -1;
        pos++;
    }
    
    int value = 0;
    while (*pos >= '0' && *pos <= '9') {
        value = value * 10 + (*pos - '0');
        pos++;
    }
    
    return value * sign;
}

void process_complete_message(const char* message) {
    // MODE가 있는 메시지만 처리
    if (strstr(message, "MODE=") == NULL) {
        return;
    }
    
    // 각 값 추출
    int mode = extract_number_after_key(message, "MODE");
    int x1 = extract_number_after_key(message, "X1");
    int y1 = extract_number_after_key(message, "Y1");
    int x2 = extract_number_after_key(message, "X2");
    int y2 = extract_number_after_key(message, "Y2");
    
    // 디버그 출력
    char debug_buf[128];
    snprintf(debug_buf, sizeof(debug_buf), "MODE=%d, X1=%d, Y1=%d, X2=%d, Y2=%d\r\n", 
             mode, x1, y1, x2, y2);
    simple_uart_send_string(debug_buf);
    
    // 서보 제어
    servoHandler(mode, x1, y1, x2, y2);
}

// =================== 서보 제어 함수 ===================
void control_servo(int value, int* angle, uint32_t pwm_addr, const char* name) {
    uint32_t duty_step = 4095;
    uint32_t duty;
    
    if(value < RANGE_MIN && value > 0) {
        *angle -= 3;  // 더 빠른 움직임 (원래 1에서 3으로 증가)
        if(*angle < 0) *angle = 0;
        duty = angle_to_duty(*angle, duty_step);
        pwm_set(pwm_addr, duty, 50, duty_step);
        
        char angle_buf[32];
        snprintf(angle_buf, sizeof(angle_buf), "%s Angle decreased to: %d\r\n", name, *angle);
        simple_uart_send_string(angle_buf);
    }
    else if(value > RANGE_MAX) {
        *angle += 3;  // 더 빠른 움직임 (원래 1에서 3으로 증가)
        if(*angle > 180) *angle = 180;
        duty = angle_to_duty(*angle, duty_step);
        pwm_set(pwm_addr, duty, 50, duty_step);
        
        // char angle_buf[32];
        // snprintf(angle_buf, sizeof(angle_buf), "%s Angle increased to: %d\r\n", name, *angle);
        // simple_uart_send_string(angle_buf);
    }
}

// =================== 무브 제어 함수 ===================
void control_move(int y1_val, int y2_val)
{
    volatile unsigned int *handle_instance = (volatile unsigned int*)HANDLE_ADDR;

    // [1] 중간값이면 항상 Stop
    if ((y1_val >= RANGE_MIN && y1_val <= RANGE_MAX) &&
        (y2_val >= RANGE_MIN && y2_val <= RANGE_MAX)) {
        handle_instance[0] = 0; // Stop (정지)
    }
    // [2] 전진
    else if((y1_val > RANGE_MAX) && (y2_val > RANGE_MAX)) {
        handle_instance[0] = 1;  // Forward
    }
    // [3] 후진
    else if((y1_val < RANGE_MIN && y1_val > 0) && (y2_val < RANGE_MIN && y2_val > 0)) {
        handle_instance[0] = 2;  // Backward
    }
    // [4] 좌회전
    else if((y1_val < RANGE_MIN && y1_val > 0) && (y2_val > RANGE_MAX)) {
        handle_instance[0] = 4;  // Left
    }
    // [5] 우회전
    else if((y1_val > RANGE_MAX) && (y2_val < RANGE_MIN && y2_val > 0)) {
        handle_instance[0] = 8;  // Right
    }
    else {
        handle_instance[0] = 0;  // Stop
    }
}


void servoHandler(int mode, int x1, int y1, int x2, int y2)
{
    
    if(mode == 1)
    {
        // 모든 서보를 동일한 로직으로 제어
        control_servo(x1, &x1_angle, PWM_0_ADDR, "X1");
        control_servo(y1, &y1_angle, PWM_1_ADDR, "Y1");
        control_servo(x2, &x2_angle, PWM_2_ADDR, "X2");
        control_servo(y2, &y2_angle, PWM_3_ADDR, "Y2");
    }
    else if(mode == 2)
    {
        control_move(y1, y2);
    }
    else {
        simple_uart_send_string("Mode -1: No servo control\r\n");
    }
}

uint32_t angle_to_duty(uint32_t angle, uint32_t duty_step) {
    uint32_t duty_min = duty_step * 5 / 200;
    uint32_t duty_max = duty_step * 25 / 200;
    return duty_min + ((duty_max - duty_min) * angle) / 180;
}

void pwm_set(uint32_t base, uint32_t duty, uint32_t pwm_freq, uint32_t duty_step) {
    uint32_t temp = SYS_CLK_FREQ / pwm_freq / duty_step / 2;
    Xil_Out32(base + REG_DUTY, duty);
    Xil_Out32(base + REG_TEMP, temp);
    Xil_Out32(base + REG_DUTYSTEP, duty_step);
}

// =================== 메인 ===================
int main(void)
{
    int Status;
    u8 RecvBuffer[BUFFER_SIZE];
    int ReceivedCount;

    // UART 초기화
    Status = XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID);
    if(Status != XST_SUCCESS) return XST_FAILURE;

    // 시작 메시지
    simple_uart_send_string("=== Line-based Parsing Start ===\r\n");

    // 버퍼 초기화
    memset(line_buffer, 0, LINE_BUFFER_SIZE);
    line_index = 0;

    while (1) {
        // HC-05에서 데이터 수신
        ReceivedCount = XUartLite_Recv(&Uart_HC05, RecvBuffer, sizeof(RecvBuffer)-1);

        if (ReceivedCount > 0) {
            // 받은 데이터를 한 바이트씩 처리
            for (int i = 0; i < ReceivedCount; i++) {
                char ch = RecvBuffer[i];
                
                // 제어 문자나 구분자 확인 (줄바꿈, 캐리지리턴, 콤마 등)
                if (ch == '\r' || ch == '\n' || ch == 0 || line_index >= LINE_BUFFER_SIZE - 1) {
                    if (line_index > 0) {
                        line_buffer[line_index] = '\0';
                        
                        // 완성된 라인 출력
                        simple_uart_send_string("Line: ");
                        simple_uart_send_string(line_buffer);
                        simple_uart_send_string("\r\n");
                        
                        // 메시지 처리
                        process_complete_message(line_buffer);
                        
                        // 버퍼 리셋
                        line_index = 0;
                        memset(line_buffer, 0, LINE_BUFFER_SIZE);
                    }
                }
                else if (ch >= 32 && ch <= 126) {  // 출력 가능한 ASCII만 저장
                    line_buffer[line_index++] = ch;
                }
                
                // MODE로 시작하는 새로운 메시지 감지
                // if (line_index >= 5 && strncmp(line_buffer + line_index - 5, "MODE=", 5) == 0 && line_index > 5) {
                //     // 이전 메시지 처리
                //     line_buffer[line_index - 5] = '\0';
                //     if (strlen(line_buffer) > 0) {
                //         simple_uart_send_string("Auto-split: ");
                //         simple_uart_send_string(line_buffer);
                //         simple_uart_send_string("\r\n");
                //         process_complete_message(line_buffer);
                //     }
                    
                //     // 새 메시지 시작
                //     strcpy(line_buffer, "MODE=");
                //     line_index = 5;
                // }
            }
            
            // 주기적으로 긴 메시지 처리 (타임아웃 방식)
            static int timeout_counter = 0;
            timeout_counter++;
            if (timeout_counter > 1000 && line_index > 0) {  // 적당한 타임아웃
                line_buffer[line_index] = '\0';
                simple_uart_send_string("Timeout: ");
                simple_uart_send_string(line_buffer);
                simple_uart_send_string("\r\n");
                process_complete_message(line_buffer);
                
                line_index = 0;
                memset(line_buffer, 0, LINE_BUFFER_SIZE);
                timeout_counter = 0;
            }
        }
    }

    return 0;
}