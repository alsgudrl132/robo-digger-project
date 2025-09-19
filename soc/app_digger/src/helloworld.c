/******************************************************************************
* 단순화된 HC-05 파싱 코드 - 단일 라인 처리
******************************************************************************/

#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
typedef unsigned char u8;

#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR
#define USB_UART_BASEADDR   XPAR_XUARTLITE_1_BASEADDR
#define HANDLE_ADDR         XPAR_MYIP_HANDLE_0_BASEADDR

#define PWM_0_ADDR XPAR_MYIP_PWM_0_BASEADDR  // X1용
#define PWM_1_ADDR XPAR_MYIP_PWM_1_BASEADDR  // Y1용
#define PWM_2_ADDR XPAR_MYIP_PWM_2_BASEADDR  // X2용  
#define PWM_3_ADDR XPAR_MYIP_PWM_3_BASEADDR  // Y2용

#define SYS_CLK_FREQ  100000000  
#define REG_DUTY      0x0
#define REG_TEMP      0x4
#define REG_DUTYSTEP  0x8

#define BUFFER_SIZE       512
#define LINE_BUFFER_SIZE  256
#define RANGE_MIN         1500
#define RANGE_MAX         3000

XUartLite Uart_HC05;
static int x1_angle = 90;
static int y1_angle = 90;
static int x2_angle = 90;
static int y2_angle = 90;

// 라인 누적용 버퍼
static char line_buffer[LINE_BUFFER_SIZE];
static int line_index = 0;

// 마지막 값들 저장 (값이 없을 때 0으로 초기화되는 것을 방지)
static int last_x1 = 2048, last_y1 = 2048, last_x2 = 2048, last_y2 = 2048;

// =================== 함수 선언 ===================
void servoHandler(int mode, int x1, int y1, int x2, int y2);
uint32_t angle_to_duty(uint32_t angle, uint32_t duty_step);
void pwm_set(uint32_t base, uint32_t duty, uint32_t pwm_freq, uint32_t duty_step);
void process_line(const char* line);
int extract_number_after_key(const char* str, const char* key);
void control_servo(int value, int* angle, uint32_t pwm_addr, const char* name); 
void control_move(int y1_val, int y2_val);

// =================== simple UART 함수 ===================
int simple_uart_send_char(char c) {
    int timeout = 10000;
    while (Xil_In32(USB_UART_BASEADDR + 0x8) & 0x8) {
        if (--timeout <= 0) {
            return -1;
        }
    }
    Xil_Out8(USB_UART_BASEADDR + 0x4, c);
    return 0;
}

void simple_uart_send_string(const char *str) {
    while (*str) {
        simple_uart_send_char(*str++);
    }
}

// =================== 강화된 파싱 함수 ===================
int extract_number_after_key(const char* str, const char* key) {
    char* pos = strstr(str, key);
    if (!pos) return -999;  // 키 없음
    pos += strlen(key);

    // 숫자만 파싱 (음수도 고려)
    char numbuf[16];
    int i = 0;
    while (*pos && ((*pos >= '0' && *pos <= '9') || *pos == '-')) {
        if (i < (int)(sizeof(numbuf) - 1)) {
            numbuf[i++] = *pos;
        }
        pos++;
    }
    numbuf[i] = '\0';

    if (i == 0) return -999;  // 숫자 없음
    return atoi(numbuf);
}


void process_line(const char* line) {
    int mode = extract_number_after_key(line, "MODE=");
    int x1   = extract_number_after_key(line, "X1=");
    int y1   = extract_number_after_key(line, "Y1=");
    int x2   = extract_number_after_key(line, "X2=");
    int y2   = extract_number_after_key(line, "Y2=");

    // 값이 정상인지 확인
    if (mode == -999 || (x1 == -999 && y1 == -999 && x2 == -999 && y2 == -999)) {
        // 완전히 깨진 라인 → 무시
        return;
    }

    // 이전 값 보존
    if (x1 == -999) x1 = last_x1;
    else last_x1 = x1;
    if (y1 == -999) y1 = last_y1;
    else last_y1 = y1;
    if (x2 == -999) x2 = last_x2;
    else last_x2 = x2;
    if (y2 == -999) y2 = last_y2;
    else last_y2 = y2;

    // 서보 제어
    servoHandler(mode, x1, y1, x2, y2);
}


// =================== 서보 제어 함수 ===================
void control_servo(int value, int* angle, uint32_t pwm_addr, const char* name) {
    uint32_t duty_step = 4095;
    uint32_t duty;
    int old_angle = *angle;
    
    char debug_msg[80];
    snprintf(debug_msg, sizeof(debug_msg), "%s: value=%d, current_angle=%d\r\n", 
             name, value, *angle);
    simple_uart_send_string(debug_msg);
    
    // 더 좁은 데드존 적용 (중립값 2048 기준 ±300)
    int neutral_min = 1748;  // 2048 - 300
    int neutral_max = 2348;  // 2048 + 300
    
    // 데드존 확인
    if (value >= neutral_min && value <= neutral_max) {
        char neutral_msg[48];
        snprintf(neutral_msg, sizeof(neutral_msg), "%s in neutral zone (value=%d)\r\n", name, value);
        simple_uart_send_string(neutral_msg);
        return;
    }
    
    // 더 넓은 움직임 범위
    if (value < neutral_min && value > 0) {
        *angle -= 6;
        if (*angle < 0) *angle = 0;  // 0도 제한
        
        char move_msg[48];
        snprintf(move_msg, sizeof(move_msg), "%s moving DOWN: %d->%d (val=%d)\r\n", 
                 name, old_angle, *angle, value);
        simple_uart_send_string(move_msg);
    }
    else if (value > neutral_max || value == 4095) {  // 최대값일 때도 처리
        *angle += 6;  
        if (*angle > 180) *angle = 180;  // 180도 제한
        
        char move_msg[48];
        snprintf(move_msg, sizeof(move_msg), "%s moving UP: %d->%d (val=%d)\r\n", 
                 name, old_angle, *angle, value);
        simple_uart_send_string(move_msg);
    }
    
    // 각도가 변경된 경우만 PWM 업데이트
    if (*angle != old_angle) {
        duty = angle_to_duty(*angle, duty_step);
        pwm_set(pwm_addr, duty, 50, duty_step);
    }
    
    char final_msg[64];
    snprintf(final_msg, sizeof(final_msg), "%s FINAL: angle=%d, duty_changed=%s\r\n", 
             name, *angle, (*angle != old_angle) ? "YES" : "NO");
    simple_uart_send_string(final_msg);
}

void control_move(int y1_val, int y2_val) {
    volatile unsigned int *handle_instance = (volatile unsigned int*)HANDLE_ADDR;
    int cmd = 0;

    // 중립일 때 정지 (더 넓은 데드존 적용)
    if (y1_val >= RANGE_MIN && y1_val <= RANGE_MAX && 
        y2_val >= RANGE_MIN && y2_val <= RANGE_MAX) {
        cmd = 0;
        simple_uart_send_string("Movement: STOP\r\n");
    } else {
        // 왼쪽 조이스틱으로 왼쪽바퀴 제어
        if (y1_val > RANGE_MAX) {
            cmd |= 0x01;  // 왼쪽바퀴 전진
            simple_uart_send_string("Left wheel: FORWARD\r\n");
        }
        else if (y1_val < RANGE_MIN && y1_val >= 0) {
            cmd |= 0x02;  // 왼쪽바퀴 후진
            simple_uart_send_string("Left wheel: BACKWARD\r\n");
        }
        
        // 오른쪽 조이스틱으로 오른쪽바퀴 제어
        if (y2_val > RANGE_MAX) {
            cmd |= 0x04;  // 오른쪽바퀴 전진
            simple_uart_send_string("Right wheel: FORWARD\r\n");
        }
        else if (y2_val < RANGE_MIN && y2_val >= 0) {
            cmd |= 0x08;  // 오른쪽바퀴 후진
            simple_uart_send_string("Right wheel: BACKWARD\r\n");
        }
    }
    
    handle_instance[0] = cmd;
    
    char move_buf[64];
    snprintf(move_buf, sizeof(move_buf), "Move cmd: 0x%02X (Y1=%d, Y2=%d)\r\n", 
             cmd, y1_val, y2_val);
    simple_uart_send_string(move_buf);
}

void servoHandler(int mode, int x1, int y1, int x2, int y2) {
    if (mode == 1) {  // Work Mode
        simple_uart_send_string("=== WORK MODE - Servo Control ===\r\n");
        control_servo(x1, &x1_angle, PWM_0_ADDR, "X1");
        control_servo(y1, &y1_angle, PWM_1_ADDR, "Y1");
        control_servo(x2, &x2_angle, PWM_2_ADDR, "X2");
        control_servo(y2, &y2_angle, PWM_3_ADDR, "Y2");
    }
    else if (mode == 2) {  // Drive Mode
        simple_uart_send_string("=== DRIVE MODE - Wheel Control ===\r\n");
        control_move(y1, y2);
    }
    else {
        simple_uart_send_string("Mode: No control active\r\n");
    }
}

uint32_t angle_to_duty(uint32_t angle, uint32_t duty_step) {
    // 20ms 주기 기준, pulse width: 0.5ms ~ 2.5ms
    // duty = duty_step * (pulse / period)
    uint32_t duty_min = duty_step * 5 / 200;   // 0.5ms → 25 (duty_step=1000 기준)
    uint32_t duty_max = duty_step * 25 / 200;  // 2.5ms → 125

    return duty_min + ((duty_max - duty_min) * angle) / 180;
}

void pwm_set(uint32_t base, uint32_t duty, uint32_t pwm_freq, uint32_t duty_step) {
    uint32_t temp = SYS_CLK_FREQ / pwm_freq / duty_step / 2;
    Xil_Out32(base + REG_DUTY, duty);
    Xil_Out32(base + REG_TEMP, temp);
    Xil_Out32(base + REG_DUTYSTEP, duty_step);
}
// =================== 메인 ===================
int main(void) {
    int Status;
    u8 RecvBuffer[BUFFER_SIZE];
    int ReceivedCount;

    // UART 초기화
    Status = XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        simple_uart_send_string("UART Init Failed!\r\n");
        return XST_FAILURE;
    }

    simple_uart_send_string("=== Single Line Parser Start ===\r\n");
    simple_uart_send_string("Waiting for commands...\r\n");

    // 버퍼 초기화
    memset(line_buffer, 0, LINE_BUFFER_SIZE);
    line_index = 0;

    // 초기 서보 위치 설정 (90도) - 더 자세한 디버깅
    simple_uart_send_string("Initializing servos...\r\n");
    
    uint32_t initial_duty = angle_to_duty(90, 4095);
    
    simple_uart_send_string("Setting X1 servo...\r\n");
    pwm_set(PWM_0_ADDR, initial_duty, 50, 4095);
    
    simple_uart_send_string("Setting Y1 servo...\r\n");  
    pwm_set(PWM_1_ADDR, initial_duty, 50, 4095);
    
    simple_uart_send_string("Setting X2 servo...\r\n");
    pwm_set(PWM_2_ADDR, initial_duty, 50, 4095);
    
    simple_uart_send_string("Setting Y2 servo...\r\n");
    pwm_set(PWM_3_ADDR, initial_duty, 50, 4095);
    
    simple_uart_send_string("All servos initialized to 90 degrees\r\n");
    
    // PWM 주소 확인
    char addr_info[200];
    snprintf(addr_info, sizeof(addr_info), 
             "PWM Addresses: X1=0x%X, Y1=0x%X, X2=0x%X, Y2=0x%X\r\n",
             PWM_0_ADDR, PWM_1_ADDR, PWM_2_ADDR, PWM_3_ADDR);
    simple_uart_send_string(addr_info);
    
    // 서보 테스트 (각 서보를 45도씩 움직여서 동작 확인)
    simple_uart_send_string("Testing servo movement...\r\n");
    
    // X1 테스트
    x1_angle = 45;
    uint32_t test_duty = angle_to_duty(45, 4095);
    pwm_set(PWM_0_ADDR, test_duty, 50, 4095);
    simple_uart_send_string("X1 moved to 45 degrees\r\n");
    usleep(500000); // 0.5초 대기
    
    x1_angle = 135;
    test_duty = angle_to_duty(135, 4095);
    pwm_set(PWM_0_ADDR, test_duty, 50, 4095);
    simple_uart_send_string("X1 moved to 135 degrees\r\n");
    usleep(500000);
    
    x1_angle = 90;
    test_duty = angle_to_duty(90, 4095);
    pwm_set(PWM_0_ADDR, test_duty, 50, 4095);
    simple_uart_send_string("X1 back to 90 degrees\r\n");
    
    simple_uart_send_string("Servo test completed. Ready for control.\r\n");

    while (1) {
        ReceivedCount = XUartLite_Recv(&Uart_HC05, RecvBuffer, sizeof(RecvBuffer) - 1);

        if (ReceivedCount > 0) {
            for (int i = 0; i < ReceivedCount; i++) {
                char ch = RecvBuffer[i];

                if (ch == '\n') {  // 한 줄 끝
                    if (line_index > 0) {
                        line_buffer[line_index] = '\0';

                        // 수신된 원본 라인 출력
                        simple_uart_send_string("[RX] ");
                        simple_uart_send_string(line_buffer);
                        simple_uart_send_string("\r\n");

                        // 라인 길이와 내용 검증
                        if (strlen(line_buffer) > 10 && strstr(line_buffer, "MODE=") != NULL) {
                            process_line(line_buffer);
                        } else {
                            simple_uart_send_string("[SKIP] Invalid or incomplete line\r\n");
                        }
                    }
                    // 버퍼 리셋
                    line_index = 0;
                    memset(line_buffer, 0, LINE_BUFFER_SIZE);
                }
                else if (ch != '\r' && ch >= 32 && ch <= 126) {
                    if (line_index < LINE_BUFFER_SIZE - 1) {
                        line_buffer[line_index++] = ch;
                    } else {
                        line_index = 0;
                        memset(line_buffer, 0, LINE_BUFFER_SIZE);
                        simple_uart_send_string("[WARN] Line buffer overflow\r\n");
                    }
                }
            }
        }
    }

    return 0;
}