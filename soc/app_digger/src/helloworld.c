#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// UART 주소 정의
#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR
#define USB_UART_BASEADDR   XPAR_XUARTLITE_1_BASEADDR
#define HANDLE_ADDR         XPAR_MYIP_HANDLE_0_BASEADDR

// PWM 주소들
#define PWM_0_ADDR XPAR_MYIP_PWM_X1_BASEADDR  
#define PWM_1_ADDR XPAR_MYIP_PWM_Y1_BASEADDR  
#define PWM_2_ADDR XPAR_MYIP_PWM_X2_BASEADDR  
#define PWM_3_ADDR XPAR_MYIP_PWM_Y2_BASEADDR  
#define PWM_5_ADDR XPAR_MYIP_PWM_LEFT_WHEEL_BASEADDR  
#define PWM_6_ADDR XPAR_MYIP_PWM_RIGHT_WHEEL_BASEADDR  

// 설정값들
#define SYS_CLK_FREQ  100000000  
#define REG_DUTY      0x0                   
#define REG_TEMP      0x4
#define REG_DUTYSTEP  0x8
#define BUFFER_SIZE   512
#define LINE_SIZE     128
#define RANGE_MIN     1500  
#define RANGE_MAX     2600  

XUartLite Uart_HC05;

// 전역변수들
int x1_angle = 90, y1_angle = 90, x2_angle = 90, y2_angle = 45;
char line_buf[LINE_SIZE];
int line_idx = 0;
int last_x1 = 2048, last_y1 = 2048, last_x2 = 2048, last_y2 = 2048;
int left_speed = 0, right_speed = 0;

// UART로 문자열 전송
void send_msg(const char *str) {
    while (*str) {
        while (Xil_In32(USB_UART_BASEADDR + 0x8) & 0x8);
        Xil_Out8(USB_UART_BASEADDR + 0x4, *str++);
    }
}

// 문자열에서 숫자값 추출 (예: "X1=2048"에서 2048 추출)
int get_value(const char* str, const char* key) {
    char* pos = strstr(str, key);
    if (!pos) return -999;
    pos += strlen(key);
    
    while (*pos == ' ') pos++; // 공백건너뜀
    
    char num[8];
    int i = 0;
    while (*pos >= '0' && *pos <= '9' && i < 6) {
        num[i++] = *pos++;
    }
    num[i] = '\0';
    
    if (i == 0) return -999;
    int result = atoi(num);
    return (result < 0 || result > 4095) ? -999 : result;
}

// 버튼값 추출
int get_btn(const char* str) {
    char* pos = strstr(str, "BTN=");
    if (!pos) return -999;
    pos += 4;
    
    while (*pos == ' ') pos++;
    
    char num[4];
    int i = 0;
    while (*pos >= '0' && *pos <= '9' && i < 2) {
        num[i++] = *pos++;
    }
    num[i] = '\0';
    
    return (i == 0) ? -999 : atoi(num);
}

// DC모터 PWM 설정
void set_motor(uint32_t addr, int speed) {
    if (speed < 0) speed = 0;
    if (speed > 100) speed = 100;
    
    uint32_t duty = (4095 * speed) / 100;  
    uint32_t temp = SYS_CLK_FREQ / 1000 / 4095 / 2; 
    
    Xil_Out32(addr + REG_DUTY, duty);
    Xil_Out32(addr + REG_TEMP, temp);
    Xil_Out32(addr + REG_DUTYSTEP, 4095);
}

// 서보모터 제어 (일반 서보 0~180도)
void move_servo(uint32_t addr, int *current_angle, int joy_val) {
    int target = 90; // 기본 중립위치
    
    if (joy_val < RANGE_MIN) {
        target = 90 + (RANGE_MIN - joy_val) * 90 / RANGE_MIN;
    } else if (joy_val > RANGE_MAX) {
        target = 90 - (joy_val - RANGE_MAX) * 90 / (4095 - RANGE_MAX);
    }
    
    if (target < 0) target = 0;
    if (target > 180) target = 180;
    
    // 부드럽게 움직이기
    if (*current_angle < target) {
        *current_angle += 3;
        if (*current_angle > target) *current_angle = target;
    } else if (*current_angle > target) {
        *current_angle -= 3;
        if (*current_angle < target) *current_angle = target;
    }
    
    // PWM 출력 (서보모터용 50Hz)
    uint32_t duty_min = 4095 * 5 / 200;  // 1ms
    uint32_t duty_max = 4095 * 25 / 200; // 2.5ms
    uint32_t duty = duty_min + ((duty_max - duty_min) * (*current_angle)) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(addr + REG_DUTY, duty);
    Xil_Out32(addr + REG_TEMP, temp);
    Xil_Out32(addr + REG_DUTYSTEP, 4095);
}

// Y2 서보 제어 (0~90도만 사용)
void move_y2_servo(int joy_val) {
    int target = 45; // 중립 45도
    
    if (joy_val < RANGE_MIN) {
        target = 45 + (RANGE_MIN - joy_val) * 45 / RANGE_MIN; // 45~90도
    } else if (joy_val > RANGE_MAX) {
        target = 45 - (joy_val - RANGE_MAX) * 45 / (4095 - RANGE_MAX); // 45~0도
    }
    
    if (target < 0) target = 0;
    if (target > 90) target = 90;
    
    if (y2_angle < target) {
        y2_angle += 3;
        if (y2_angle > target) y2_angle = target;
    } else if (y2_angle > target) {
        y2_angle -= 3;
        if (y2_angle < target) y2_angle = target;
    }
    
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t duty = duty_min + ((duty_max - duty_min) * y2_angle) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(PWM_3_ADDR + REG_DUTY, duty);
    Xil_Out32(PWM_3_ADDR + REG_TEMP, temp);
    Xil_Out32(PWM_3_ADDR + REG_DUTYSTEP, 4095);
}

// 모터 정지
void stop_motors() {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    handle[0] = 0;
    set_motor(PWM_5_ADDR, 0);
    set_motor(PWM_6_ADDR, 0);
    left_speed = 0;
    right_speed = 0;
}

// 바퀴 구동
void drive_wheels(int y1_val, int y2_val) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    int cmd = 0;
    int target_left = 0, target_right = 0;
    
    // 중립구간이면 정지
    if (y1_val >= RANGE_MIN && y1_val <= RANGE_MAX && 
        y2_val >= RANGE_MIN && y2_val <= RANGE_MAX) {
        cmd = 0;
        target_left = 0;
        target_right = 0;
    } else {
        // 왼쪽바퀴
        if (y1_val > RANGE_MAX) {
            cmd |= 0x08; // 전진
            target_left = (y1_val - RANGE_MAX) * 100 / (4095 - RANGE_MAX);
        } else if (y1_val < RANGE_MIN) {
            cmd |= 0x04; // 후진
            target_left = (RANGE_MIN - y1_val) * 100 / RANGE_MIN;
        }
        
        // 오른쪽바퀴
        if (y2_val > RANGE_MAX) {
            cmd |= 0x01; // 전진
            target_right = (y2_val - RANGE_MAX) * 100 / (4095 - RANGE_MAX);
        } else if (y2_val < RANGE_MIN) {
            cmd |= 0x02; // 후진
            target_right = (RANGE_MIN - y2_val) * 100 / RANGE_MIN;
        }
        
        if (target_left > 100) target_left = 100;
        if (target_right > 100) target_right = 100;
    }
    
    // 급격한 속도변화 방지
    if (target_left == 0 && target_right == 0) {
        left_speed = 0;
        right_speed = 0;
    } else {
        // 점진적 가속/감속
        if (left_speed < target_left) {
            left_speed += 10;
            if (left_speed > target_left) left_speed = target_left;
        } else if (left_speed > target_left) {
            left_speed -= 10;
            if (left_speed < target_left) left_speed = target_left;
        }
        
        if (right_speed < target_right) {
            right_speed += 10;
            if (right_speed > target_right) right_speed = target_right;
        } else if (right_speed > target_right) {
            right_speed -= 10;
            if (right_speed < target_right) right_speed = target_right;
        }
    }
    
    // 출력
    handle[0] = cmd;
    set_motor(PWM_5_ADDR, left_speed);
    set_motor(PWM_6_ADDR, right_speed);
}

// 데이터 처리
void process_line(const char* line) {
    if (strlen(line) < 10) return;
    
    // 버튼 명령 처리
    if (strstr(line, "BTN=")) {
        int btn = get_btn(line);
        if (btn != -999) {
            switch(btn) {
                case 1: send_msg("BUCKET DOWN\r\n"); break;
                case 2: send_msg("WORK MODE\r\n"); break;
                case 4: send_msg("DRIVE MODE\r\n"); break;
                case 8: send_msg("BUCKET UP\r\n"); break;
                case 16: // 비상정지
                    stop_motors();
                    send_msg("EMERGENCY STOP!\r\n");
                    break;
            }
        }
        return;
    }
    
    // 중립명령 처리
    if (strstr(line, "NEUTRAL=1")) {
        stop_motors();
        return;
    }
    
    // 조이스틱 데이터 파싱
    int mode = get_value(line, "MODE=");
    if (mode == -999) return;
    
    int x1 = get_value(line, "X1=");
    int y1 = get_value(line, "Y1=");
    int x2 = get_value(line, "X2=");
    int y2 = get_value(line, "Y2=");
    
    // 이전값 사용 (파싱 실패시)
    if (x1 != -999) last_x1 = x1; else x1 = last_x1;
    if (y1 != -999) last_y1 = y1; else y1 = last_y1;
    if (x2 != -999) last_x2 = x2; else x2 = last_x2;
    if (y2 != -999) last_y2 = y2; else y2 = last_y2;
    
    // 모드별 제어
    if (mode == 1) {  // 작업모드
        // 중립체크
        if (x1 >= RANGE_MIN && x1 <= RANGE_MAX &&
            y1 >= RANGE_MIN && y1 <= RANGE_MAX &&
            x2 >= RANGE_MIN && x2 <= RANGE_MAX &&
            y2 >= RANGE_MIN && y2 <= RANGE_MAX) {
            return; // 중립이면 아무것도 안함
        }
        
        // 서보 제어
        move_servo(PWM_0_ADDR, &x1_angle, x1);  
        move_servo(PWM_1_ADDR, &y1_angle, y1);
        move_servo(PWM_2_ADDR, &x2_angle, x2);
        move_y2_servo(y2);  
    }
    else if (mode == 2) {  // 운전모드
        // 중립이면 정지
        if (y1 >= RANGE_MIN && y1 <= RANGE_MAX && 
            y2 >= RANGE_MIN && y2 <= RANGE_MAX) {
            stop_motors();
            return;
        }
        drive_wheels(y1, y2);
    }
}

int main(void) {
    // UART 초기화
    if (XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    
    send_msg("=== Servo Motor Control Start ===\r\n");
    
    // DC모터 초기화 (안전을 위해 정지상태로)
    set_motor(PWM_5_ADDR, 0);  
    set_motor(PWM_6_ADDR, 0); 
    
    // 핸들 초기화
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    handle[0] = 0;
    
    send_msg("System Ready!\r\n");
    
    // 메인루프
    u8 buffer[BUFFER_SIZE];
    memset(line_buf, 0, LINE_SIZE);
    line_idx = 0;
    
    while (1) {
        int count = XUartLite_Recv(&Uart_HC05, buffer, sizeof(buffer));
        
        if (count > 0) {
            for (int i = 0; i < count; i++) {
                char ch = buffer[i];
                
                if (ch == '\n') {  // 한줄 완성
                    if (line_idx > 0) {
                        line_buf[line_idx] = '\0';
                        process_line(line_buf); // 처리
                    }
                    
                    // 버퍼 리셋
                    line_idx = 0;
                    memset(line_buf, 0, LINE_SIZE);
                }
                else if (ch >= 32 && ch <= 126) {  // 일반문자만
                    if (line_idx < LINE_SIZE - 1) {
                        line_buf[line_idx++] = ch;
                    } else {
                        // 오버플로우시 리셋
                        line_idx = 0;
                        memset(line_buf, 0, LINE_SIZE);
                    }
                }
            }
        }
    }
    return 0;
}