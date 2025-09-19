#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
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
#define LINE_BUFFER_SIZE  128
#define RANGE_MIN         1100
#define RANGE_MAX         3000

XUartLite Uart_HC05;

// 서보 각도
static int x1_angle = 90, y1_angle = 90, x2_angle = 90, y2_angle = 90;

// 라인 버퍼
static char line_buffer[LINE_BUFFER_SIZE];
static int line_index = 0;

// 마지막 값들 (fallback용)
static int last_x1 = 2048, last_y1 = 2048, last_x2 = 2048, last_y2 = 2048;

// =================== 간단한 UART 함수 ===================
void uart_send_string(const char *str) {
    while (*str) {
        while (Xil_In32(USB_UART_BASEADDR + 0x8) & 0x8);
        Xil_Out8(USB_UART_BASEADDR + 0x4, *str++);
    }
}

// =================== 개선된 숫자 추출 함수 ===================
int get_number_improved(const char* str, const char* key) {
    char* pos = strstr(str, key);
    if (!pos) return -999;
    pos += strlen(key);
    
    // 공백 건너뛰기
    while (*pos == ' ' || *pos == '\t') pos++;
    
    char numbuf[8];
    int i = 0;
    
    // 숫자만 추출 (4자리 고정 형식 대응)
    while (*pos >= '0' && *pos <= '9' && i < 6) {
        numbuf[i++] = *pos++;
    }
    numbuf[i] = '\0';
    
    if (i == 0) return -999;
    
    int result = atoi(numbuf);
    // 범위 검증 (0~4095)
    return (result < 0 || result > 4095) ? -999 : result;
}

// =================== 개선된 버튼 추출 함수 ===================
int get_button_value(const char* str) {
    char* pos = strstr(str, "BTN=");
    if (!pos) return -999;
    pos += 4;  // "BTN=" 길이
    
    // 공백 건너뛰기
    while (*pos == ' ' || *pos == '\t') pos++;
    
    char numbuf[4];
    int i = 0;
    
    // 숫자만 추출 (2자리 고정 형식)
    while (*pos >= '0' && *pos <= '9' && i < 2) {
        numbuf[i++] = *pos++;
    }
    numbuf[i] = '\0';
    
    if (i == 0) return -999;
    
    return atoi(numbuf);
}

// =================== NEUTRAL 체크 함수 ===================
int is_neutral_command(const char* str) {
    return (strstr(str, "NEUTRAL=1") != NULL);
}

// =================== 간단한 서보 제어 ===================
void move_servo(int *angle, int value, uint32_t pwm_addr, int direction) {
    int old_angle = *angle;
    
    if (value < RANGE_MIN) *angle += direction * 4;
    else if (value > RANGE_MAX) *angle -= direction * 4;
    
    if (*angle < 0) *angle = 0;
    if (*angle > 180) *angle = 180;
    if (old_angle != *angle) {
        // PWM 설정
        uint32_t duty_min = 4095 * 5 / 200;   // 0.5ms
        uint32_t duty_max = 4095 * 25 / 200;  // 2.5ms
        uint32_t duty = duty_min + ((duty_max - duty_min) * (*angle)) / 180;
        uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
        
        Xil_Out32(pwm_addr + REG_DUTY, duty);
        Xil_Out32(pwm_addr + REG_TEMP, temp);
        Xil_Out32(pwm_addr + REG_DUTYSTEP, 4095);
    }
}

// =================== 간단한 이동 제어 ===================
void move_wheels(int y1_val, int y2_val) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    int cmd = 0;
    
    if (y1_val >= RANGE_MIN && y1_val <= RANGE_MAX && 
        y2_val >= RANGE_MIN && y2_val <= RANGE_MAX) {
        cmd = 0; // 정지
    } else {
        if (y1_val > RANGE_MAX) cmd |= 0x01;      // 왼쪽 전진
        else if (y1_val < RANGE_MIN) cmd |= 0x02; // 왼쪽 후진
        
        if (y2_val > RANGE_MAX) cmd |= 0x04;      // 오른쪽 전진
        else if (y2_val < RANGE_MIN) cmd |= 0x08; // 오른쪽 후진
    }
    
    handle[0] = cmd;
}

// =================== 개선된 라인 처리 함수 ===================
void process_data(const char* line) {
    // 기본 검증
    if (strlen(line) < 10) return;
    
    // 버튼 명령 처리
    if (strstr(line, "BTN=")) {
        int btn_val = get_button_value(line);
        int mode = get_number_improved(line, "MODE=");
        
        if (btn_val != -999 && mode != -999) {
            char buf[64];
            snprintf(buf, sizeof(buf), "Button: %d, Mode: %d\r\n", btn_val, mode);
            uart_send_string(buf);
            
            // 버튼별 동작 처리
            switch(btn_val) {
                case 1: uart_send_string("BUCKET DOWN\r\n"); break;
                case 2: uart_send_string("WORK MODE\r\n"); break;
                case 4: uart_send_string("DRIVE MODE\r\n"); break;
                case 8: uart_send_string("BUCKET UP\r\n"); break;
            }
        }
        return;
    }
    
    // NEUTRAL 명령 처리
    if (is_neutral_command(line)) {
        int mode = get_number_improved(line, "MODE=");
        if (mode != -999) {
            uart_send_string("NEUTRAL command received\r\n");
        }
        return;
    }
    
    // 조이스틱 데이터 처리
    if (!strstr(line, "MODE=")) return;
    
    // 파싱 (개선된 함수 사용)
    int mode = get_number_improved(line, "MODE=");
    int x1 = get_number_improved(line, "X1=");
    int y1 = get_number_improved(line, "Y1=");
    int x2 = get_number_improved(line, "X2=");
    int y2 = get_number_improved(line, "Y2=");
    
    if (mode == -999) return;
    
    // fallback 적용
    if (x1 != -999) last_x1 = x1; else x1 = last_x1;
    if (y1 != -999) last_y1 = y1; else y1 = last_y1;
    if (x2 != -999) last_x2 = x2; else x2 = last_x2;
    if (y2 != -999) last_y2 = y2; else y2 = last_y2;
    
    // 디버그 출력 (고정 4자리 형식)
    char buf[128];
    snprintf(buf, sizeof(buf), "MODE=%d X1=%04d Y1=%04d X2=%04d Y2=%04d\r\n", 
             mode, x1, y1, x2, y2);
    uart_send_string(buf);
    
    // 제어 실행
    if (mode == 1) {  // Work Mode
        // 중립 체크
        if (x1 >= RANGE_MIN && x1 <= RANGE_MAX &&
            y1 >= RANGE_MIN && y1 <= RANGE_MAX &&
            x2 >= RANGE_MIN && x2 <= RANGE_MAX &&
            y2 >= RANGE_MIN && y2 <= RANGE_MAX) {
            uart_send_string("All neutral\r\n");
            return;
        }
        
        uart_send_string("WORK MODE\r\n");
        move_servo(&x1_angle, x1, PWM_0_ADDR, 1);   // X1: 정방향
        move_servo(&y1_angle, y1, PWM_1_ADDR, 1);   // Y1: 정방향  
        move_servo(&x2_angle, x2, PWM_2_ADDR, -1);  // X2: 역방향
        move_servo(&y2_angle, y2, PWM_3_ADDR, 1);   // Y2: 정방향
    }
    else if (mode == 2) {  // Drive Mode
        uart_send_string("DRIVE MODE\r\n");
        move_wheels(y1, y2);
    }
}

// =================== 메인 ===================
int main(void) {
    // UART 초기화
    if (XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    uart_send_string("=== Simple Servo Control Start ===\r\n");
    // 초기 서보 위치 (90도)
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t initial_duty = duty_min + ((duty_max - duty_min) * 90) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    // 모든 서보 초기화
    uint32_t addrs[] = {PWM_0_ADDR, PWM_1_ADDR, PWM_2_ADDR, PWM_3_ADDR};
    for (int i = 0; i < 4; i++) {
        Xil_Out32(addrs[i] + REG_DUTY, initial_duty);
        Xil_Out32(addrs[i] + REG_TEMP, temp);
        Xil_Out32(addrs[i] + REG_DUTYSTEP, 4095);
    }
    
    uart_send_string("Servos initialized\r\n");
    // 메인 루프
    u8 buffer[BUFFER_SIZE];
    memset(line_buffer, 0, LINE_BUFFER_SIZE);
    line_index = 0;
    while (1) {
        int count = XUartLite_Recv(&Uart_HC05, buffer, sizeof(buffer));
        
        if (count > 0) {
            for (int i = 0; i < count; i++) {
                char ch = buffer[i];
                
                if (ch == '\n') {  // 라인 완료
                    if (line_index > 0) {
                        line_buffer[line_index] = '\0';
                        
                        // 원본 출력
                        uart_send_string("[RX] ");
                        uart_send_string(line_buffer);
                        uart_send_string("\r\n");
                        
                        // 처리
                        process_data(line_buffer);
                    }
                    
                    // 버퍼 리셋
                    line_index = 0;
                    memset(line_buffer, 0, LINE_BUFFER_SIZE);
                }
                else if (ch >= 32 && ch <= 126) {  // 인쇄 가능한 문자만
                    if (line_index < LINE_BUFFER_SIZE - 1) {
                        line_buffer[line_index++] = ch;
                    } else {
                        // 오버플로우시 리셋
                        line_index = 0;
                        memset(line_buffer, 0, LINE_BUFFER_SIZE);
                    }
                }
            }
        }
    }
    return 0;
}