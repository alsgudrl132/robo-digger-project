#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// UART 및 PWM 주소 정의
#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR
#define USB_UART_BASEADDR   XPAR_XUARTLITE_1_BASEADDR
#define HANDLE_ADDR         XPAR_MYIP_HANDLE_0_BASEADDR

#define PWM_0_ADDR XPAR_MYIP_PWM_X1_BASEADDR  
#define PWM_1_ADDR XPAR_MYIP_PWM_Y1_BASEADDR  
#define PWM_2_ADDR XPAR_MYIP_PWM_X2_BASEADDR  
#define PWM_3_ADDR XPAR_MYIP_PWM_Y2_BASEADDR  
#define PWM_5_ADDR XPAR_MYIP_PWM_LEFT_WHEEL_BASEADDR  
#define PWM_6_ADDR XPAR_MYIP_PWM_RIGHT_WHEEL_BASEADDR  

#define SYS_CLK_FREQ  100000000  
#define BUFFER_SIZE   256
#define LINE_SIZE     64
#define NEUTRAL_MIN   1500  // 조이스틱 중립 구간
#define NEUTRAL_MAX   2600  // 조이스틱 중립 구간

XUartLite Uart_HC05;

// 현재 상태 저장
int x1_angle = 90, y1_angle = 90, x2_angle = 90, y2_angle = 45;
char line_buf[LINE_SIZE];
int line_idx = 0;
int last_x1 = 2048, last_y1 = 2048, last_x2 = 2048, last_y2 = 2048; // 이전값 보관
int left_speed = 0, right_speed = 0; // 현재 속도

// USB로 디버그 메시지 전송
void send_msg(const char *str) {
    while (*str) {
        while (Xil_In32(USB_UART_BASEADDR + 0x8) & 0x8);
        Xil_Out8(USB_UART_BASEADDR + 0x4, *str++);
    }
}

// 문자열에서 값 추출 (파싱 실패시 0 반환)
int get_value(const char* str, const char* key) {
    char* pos = strstr(str, key);
    if (!pos) return 0; // 파싱 실패
    
    pos += strlen(key);
    while (*pos == ' ') pos++; // 공백 건너뛰기
    
    int result = atoi(pos);
    if (result < 0 || result > 4095) return 0; // 범위 체크
    return result;
}

// 버튼값 추출
int get_btn(const char* str) {
    char* pos = strstr(str, "BTN=");
    if (!pos) return 0;
    return atoi(pos + 4);
}

// DC모터 PWM 설정
void set_motor(uint32_t addr, int speed) {
    if (speed > 100) speed = 100;
    if (speed < 0) speed = 0;
    
    uint32_t duty = (4095 * speed) / 100;  
    uint32_t temp = SYS_CLK_FREQ / 1000 / 4095 / 2; 
    
    Xil_Out32(addr, duty);
    Xil_Out32(addr + 0x4, temp);
    Xil_Out32(addr + 0x8, 4095);
}

// 서보모터 제어
void move_servo(uint32_t addr, int *current_angle, int joy_val) {
    int target = 90; // 중립위치
    
    // 조이스틱 값에 따른 각도 계산
    if (joy_val < NEUTRAL_MIN) {
        target = 90 + (NEUTRAL_MIN - joy_val) * 90 / NEUTRAL_MIN;
    } else if (joy_val > NEUTRAL_MAX) {
        target = 90 - (joy_val - NEUTRAL_MAX) * 90 / (4095 - NEUTRAL_MAX);
    }
    
    if (target < 0) target = 0;
    if (target > 180) target = 180;
    
    // 부드럽게 움직이기 (급작스러운 움직임 방지)
    if (*current_angle < target) {
        *current_angle += 3;
        if (*current_angle > target) *current_angle = target;
    } else if (*current_angle > target) {
        *current_angle -= 3;
        if (*current_angle < target) *current_angle = target;
    }
    
    // 서보모터 PWM 출력 (50Hz)
    uint32_t duty_min = 4095 * 5 / 200;  
    uint32_t duty_max = 4095 * 25 / 200; 
    uint32_t duty = duty_min + ((duty_max - duty_min) * (*current_angle)) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(addr, duty);
    Xil_Out32(addr + 0x4, temp);
    Xil_Out32(addr + 0x8, 4095);
}

// Y2 서보 제어 (0~90도만 사용)
void move_y2_servo(int joy_val) {
    int target = 45; // 중립 45도
    
    if (joy_val < NEUTRAL_MIN) {
        target = 45 + (NEUTRAL_MIN - joy_val) * 45 / NEUTRAL_MIN;
    } else if (joy_val > NEUTRAL_MAX) {
        target = 45 - (joy_val - NEUTRAL_MAX) * 45 / (4095 - NEUTRAL_MAX);
    }
    
    if (target < 0) target = 0;
    if (target > 90) target = 90;
    
    // 부드러운 움직임
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
    
    Xil_Out32(PWM_3_ADDR, duty);
    Xil_Out32(PWM_3_ADDR + 0x4, temp);
    Xil_Out32(PWM_3_ADDR + 0x8, 4095);
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

// 바퀴 구동 (점진적 가속/감속)
void drive_wheels(int y1_val, int y2_val) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    int cmd = 0;
    int target_left = 0, target_right = 0;
    
    // 중립구간 체크
    if (y1_val >= NEUTRAL_MIN && y1_val <= NEUTRAL_MAX && 
        y2_val >= NEUTRAL_MIN && y2_val <= NEUTRAL_MAX) {
        target_left = 0;
        target_right = 0;
    } else {
        // 왼쪽 바퀴
        if (y1_val > NEUTRAL_MAX) {
            cmd |= 0x08; // 전진
            target_left = (y1_val - NEUTRAL_MAX) * 100 / (4095 - NEUTRAL_MAX);
        } else if (y1_val < NEUTRAL_MIN) {
            cmd |= 0x04; // 후진
            target_left = (NEUTRAL_MIN - y1_val) * 100 / NEUTRAL_MIN;
        }
        
        // 오른쪽 바퀴
        if (y2_val > NEUTRAL_MAX) {
            cmd |= 0x01; // 전진
            target_right = (y2_val - NEUTRAL_MAX) * 100 / (4095 - NEUTRAL_MAX);
        } else if (y2_val < NEUTRAL_MIN) {
            cmd |= 0x02; // 후진
            target_right = (NEUTRAL_MIN - y2_val) * 100 / NEUTRAL_MIN;
        }
        
        if (target_left > 100) target_left = 100;
        if (target_right > 100) target_right = 100;
    }
    
    // 점진적 가속/감속 (급작스러운 속도변화 방지)
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
    
    // 모터 제어 출력
    handle[0] = cmd;
    set_motor(PWM_5_ADDR, left_speed);
    set_motor(PWM_6_ADDR, right_speed);
}

// 받은 데이터 처리
void process_data(const char* line) {
    if (strlen(line) < 10) return; // 너무 짧으면 무시
    
    // 버튼 처리
    if (strstr(line, "BTN=")) {
        int btn = get_btn(line);
        if (btn > 0) {
            switch(btn) {
                case 1: send_msg("BUCKET DOWN\r\n"); break;
                case 2: send_msg("WORK MODE\r\n"); break;
                case 4: send_msg("DRIVE MODE\r\n"); break;
                case 8: send_msg("BUCKET UP\r\n"); break;
                case 16: 
                    stop_motors();
                    send_msg("EMERGENCY STOP!\r\n");
                    break;
            }
        }
        return;
    }
    
    // 중립 명령 처리
    if (strstr(line, "NEUTRAL=1")) {
        stop_motors();
        return;
    }
    
    // 조이스틱 데이터 파싱
    int mode = get_value(line, "MODE=");
    if (mode == 0) return;
    
    int x1 = get_value(line, "X1=");
    int y1 = get_value(line, "Y1=");
    int x2 = get_value(line, "X2=");
    int y2 = get_value(line, "Y2=");
    
    // 이전값 사용 (파싱 실패시 안정성 확보)
    if (x1 > 0) last_x1 = x1; else x1 = last_x1;
    if (y1 > 0) last_y1 = y1; else y1 = last_y1;
    if (x2 > 0) last_x2 = x2; else x2 = last_x2;
    if (y2 > 0) last_y2 = y2; else y2 = last_y2;
    
    // 모드별 제어
    if (mode == 1) {  // 작업 모드
        // 중립 체크 (불필요한 동작 방지)
        if (x1 >= NEUTRAL_MIN && x1 <= NEUTRAL_MAX &&
            y1 >= NEUTRAL_MIN && y1 <= NEUTRAL_MAX &&
            x2 >= NEUTRAL_MIN && x2 <= NEUTRAL_MAX &&
            y2 >= NEUTRAL_MIN && y2 <= NEUTRAL_MAX) {
            return; // 중립이면 아무것도 안함
        }
        
        move_servo(PWM_0_ADDR, &x1_angle, x1);  
        move_servo(PWM_1_ADDR, &y1_angle, y1);
        move_servo(PWM_2_ADDR, &x2_angle, x2);
        move_y2_servo(y2);  
    }
    else if (mode == 2) {  // 운전 모드
        drive_wheels(y1, y2);
    }
}

int main(void) {
    // UART 초기화
    if (XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    
    send_msg("System Start!\r\n");
    
    // 모터 안전 초기화
    set_motor(PWM_5_ADDR, 0);  
    set_motor(PWM_6_ADDR, 0); 
    
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    handle[0] = 0;
    
    send_msg("System Ready!\r\n");
    
    // 메인 루프
    u8 buffer[BUFFER_SIZE];
    line_idx = 0;
    
    while (1) {
        int count = XUartLite_Recv(&Uart_HC05, buffer, BUFFER_SIZE);
        
        if (count > 0) {
            for (int i = 0; i < count; i++) {
                char ch = buffer[i];
                
                if (ch == '\n') {  // 한 줄 완료
                    if (line_idx > 0) {
                        line_buf[line_idx] = '\0';
                        process_data(line_buf); // 데이터 처리
                    }
                    line_idx = 0; // 버퍼 리셋
                }
                else if (ch >= 32 && ch <= 126) {  // 일반 문자만
                    if (line_idx < LINE_SIZE - 1) {
                        line_buf[line_idx++] = ch;
                    } else {
                        // 버퍼 오버플로우 방지
                        line_idx = 0;
                    }
                }
            }
        }
    }
    return 0;
}