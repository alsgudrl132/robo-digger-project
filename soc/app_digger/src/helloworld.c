#include "xuartlite.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR
#define USB_UART_BASEADDR   XPAR_XUARTLITE_1_BASEADDR
#define HANDLE_ADDR         XPAR_MYIP_HANDLE_0_BASEADDR
#define PWM_0_ADDR XPAR_MYIP_PWM_X1_BASEADDR  // X1용 (360도 서보)
#define PWM_1_ADDR XPAR_MYIP_PWM_Y1_BASEADDR  // Y1용
#define PWM_2_ADDR XPAR_MYIP_PWM_X2_BASEADDR  // X2용  
#define PWM_3_ADDR XPAR_MYIP_PWM_Y2_BASEADDR  // Y2용 (0~90도)
#define PWM_4_ADDR XPAR_MYIP_PWM_BLADE_BASEADDR  // 블레이드
#define PWM_5_ADDR XPAR_MYIP_PWM_LEFT_WHEEL_BASEADDR  // 왼쪽바퀴
#define PWM_6_ADDR XPAR_MYIP_PWM_RIGHT_WHEEL_BASEADDR  // 오른쪽바퀴

#define SYS_CLK_FREQ  100000000  
#define REG_DUTY      0x0                   
#define REG_TEMP      0x4
#define REG_DUTYSTEP  0x8
#define BUFFER_SIZE       512
#define LINE_BUFFER_SIZE  128
#define RANGE_MIN         1500  // 더 큰 데드존
#define RANGE_MAX         2600  // 더 큰 데드존
#define MAX_SPEED_CHANGE  10

XUartLite Uart_HC05;

// 서보 각도/속도
static int x1_angle = 90, y1_angle = 90, x2_angle = 90, y2_angle = 45;

// 라인 버퍼
static char line_buffer[LINE_BUFFER_SIZE];
static int line_index = 0;

// 마지막 값들 (fallback용)
static int last_x1 = 2048, last_y1 = 2048, last_x2 = 2048, last_y2 = 2048;

// 바퀴 속도값 
static int current_left_speed = 0;
static int current_right_speed = 0;

// 함수 프로토타입 선언
void uart_send_string(const char *str);
int get_number_improved(const char* str, const char* key);
int get_button_value(const char* str);
int is_neutral_command(const char* str);
void move_servo_smooth_x1(int joystick_val);
void move_servo_smooth_y1(int joystick_val);
void move_servo_smooth_x2(int joystick_val);
void move_servo_smooth_y2(int joystick_val);
void set_motor_speed(uint32_t pwm_addr, int speed_percent);
void move_wheels_smooth(int y1_val, int y2_val);
void force_stop_motors(void);
void process_data(const char* line);
void emergency_stop(void);

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

// =================== DC모터 PWM 속도 설정 함수 ===================
void set_motor_speed(uint32_t pwm_addr, int speed_percent) {
    if (speed_percent < 0) speed_percent = 0;
    if (speed_percent > 100) speed_percent = 100;
    
    // DC모터용 PWM 설정 (주파수: 1kHz)
    uint32_t duty = (4095 * speed_percent) / 100;  // 0~4095 범위
    uint32_t temp = SYS_CLK_FREQ / 1000 / 4095 / 2; // 1kHz 주파수
    
    Xil_Out32(pwm_addr + REG_DUTY, duty);
    Xil_Out32(pwm_addr + REG_TEMP, temp);
    Xil_Out32(pwm_addr + REG_DUTYSTEP, 4095);
}

// =================== 개별 서보 스무스 제어 함수들 ===================
void move_servo_smooth_x1(int joystick_val) {
    static int target_angle = 90;
    
    // X2, Y1과 동일한 일반 서보 계산 (0~180도)
    if (joystick_val < RANGE_MIN) {
        target_angle = 90 + (RANGE_MIN - joystick_val) * 90 / RANGE_MIN;
    } else if (joystick_val > RANGE_MAX) {
        target_angle = 90 - (joystick_val - RANGE_MAX) * 90 / (4095 - RANGE_MAX);
    } else {
        target_angle = 90; // 중립
    }
    
    // 각도 제한 (0~180도)
    if (target_angle < 0) target_angle = 0;
    if (target_angle > 180) target_angle = 180;
    
    // 부드러운 각도 변화
    if (x1_angle < target_angle) {
        x1_angle += 3;
        if (x1_angle > target_angle) x1_angle = target_angle;
    } else if (x1_angle > target_angle) {
        x1_angle -= 3;
        if (x1_angle < target_angle) x1_angle = target_angle;
    }
    
    // PWM 출력
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t duty = duty_min + ((duty_max - duty_min) * x1_angle) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(PWM_0_ADDR + REG_DUTY, duty);
    Xil_Out32(PWM_0_ADDR + REG_TEMP, temp);
    Xil_Out32(PWM_0_ADDR + REG_DUTYSTEP, 4095);
}

void move_servo_smooth_y1(int joystick_val) {
    static int target_angle = 90;
    
    if (joystick_val < RANGE_MIN) {
        target_angle = 90 + (RANGE_MIN - joystick_val) * 90 / RANGE_MIN;
    } else if (joystick_val > RANGE_MAX) {
        target_angle = 90 - (joystick_val - RANGE_MAX) * 90 / (4095 - RANGE_MAX);
    } else {
        target_angle = 90;
    }
    
    if (target_angle < 0) target_angle = 0;
    if (target_angle > 180) target_angle = 180;
    
    if (y1_angle < target_angle) {
        y1_angle += 3;
        if (y1_angle > target_angle) y1_angle = target_angle;
    } else if (y1_angle > target_angle) {
        y1_angle -= 3;
        if (y1_angle < target_angle) y1_angle = target_angle;
    }
    
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t duty = duty_min + ((duty_max - duty_min) * y1_angle) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(PWM_1_ADDR + REG_DUTY, duty);
    Xil_Out32(PWM_1_ADDR + REG_TEMP, temp);
    Xil_Out32(PWM_1_ADDR + REG_DUTYSTEP, 4095);
}

void move_servo_smooth_x2(int joystick_val) {
    static int target_angle = 90;
    
    // X1과 동일한 정방향 계산
    if (joystick_val < RANGE_MIN) {
        target_angle = 90 + (RANGE_MIN - joystick_val) * 90 / RANGE_MIN;
    } else if (joystick_val > RANGE_MAX) {
        target_angle = 90 - (joystick_val - RANGE_MAX) * 90 / (4095 - RANGE_MAX);
    } else {
        target_angle = 90;
    }
    
    if (target_angle < 0) target_angle = 0;
    if (target_angle > 180) target_angle = 180;
    
    if (x2_angle < target_angle) {
        x2_angle += 3;
        if (x2_angle > target_angle) x2_angle = target_angle;
    } else if (x2_angle > target_angle) {
        x2_angle -= 3;
        if (x2_angle < target_angle) x2_angle = target_angle;
    }
    
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t duty = duty_min + ((duty_max - duty_min) * x2_angle) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(PWM_2_ADDR + REG_DUTY, duty);
    Xil_Out32(PWM_2_ADDR + REG_TEMP, temp);
    Xil_Out32(PWM_2_ADDR + REG_DUTYSTEP, 4095);
}

void move_servo_smooth_y2(int joystick_val) {
    static int target_angle = 45; // 중간값을 45도로
    
    if (joystick_val < RANGE_MIN) {
        target_angle = 45 + (RANGE_MIN - joystick_val) * 45 / RANGE_MIN; // 45~90도
    } else if (joystick_val > RANGE_MAX) {
        target_angle = 45 - (joystick_val - RANGE_MAX) * 45 / (4095 - RANGE_MAX); // 45~0도
    } else {
        target_angle = 45; // 중립 45도
    }
    
    if (target_angle < 0) target_angle = 0;
    if (target_angle > 90) target_angle = 90;
    
    if (y2_angle < target_angle) {
        y2_angle += 3;
        if (y2_angle > target_angle) y2_angle = target_angle;
    } else if (y2_angle > target_angle) {
        y2_angle -= 3;
        if (y2_angle < target_angle) y2_angle = target_angle;
    }
    
    uint32_t duty_min = 4095 * 5 / 200;
    uint32_t duty_max = 4095 * 25 / 200;
    uint32_t duty = duty_min + ((duty_max - duty_min) * y2_angle) / 180;
    uint32_t temp = SYS_CLK_FREQ / 50 / 4095 / 2;
    
    Xil_Out32(PWM_3_ADDR + REG_DUTY, duty);
    Xil_Out32(PWM_3_ADDR + REG_TEMP, temp);
    Xil_Out32(PWM_3_ADDR + REG_DUTYSTEP, 4095);
}

// =================== 강제 정지 기능 ===================
void force_stop_motors(void) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    handle[0] = 0;
    set_motor_speed(PWM_5_ADDR, 0);
    set_motor_speed(PWM_6_ADDR, 0);
    current_left_speed = 0;
    current_right_speed = 0;
}

// =================== DC모터 부드러운 속도 제어 ===================
void move_wheels_smooth(int y1_val, int y2_val) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    int cmd = 0;
    int target_left_speed = 0;
    int target_right_speed = 0;
    
    // 목표 속도 계산
    if (y1_val >= RANGE_MIN && y1_val <= RANGE_MAX && 
        y2_val >= RANGE_MIN && y2_val <= RANGE_MAX) {
        cmd = 0;
        target_left_speed = 0;
        target_right_speed = 0;
    } else {
        // 왼쪽 모터
        if (y1_val > RANGE_MAX) {
            cmd |= 0x08;
            target_left_speed = (y1_val - RANGE_MAX) * 100 / (4095 - RANGE_MAX);
        } else if (y1_val < RANGE_MIN) {
            cmd |= 0x04;
            target_left_speed = (RANGE_MIN - y1_val) * 100 / RANGE_MIN;
        }
        
        // 오른쪽 모터
        if (y2_val > RANGE_MAX) {
            cmd |= 0x01;
            target_right_speed = (y2_val - RANGE_MAX) * 100 / (4095 - RANGE_MAX);
        } else if (y2_val < RANGE_MIN) {
            cmd |= 0x02;
            target_right_speed = (RANGE_MIN - y2_val) * 100 / RANGE_MIN;
        }
        
        if (target_left_speed > 100) target_left_speed = 100;
        if (target_right_speed > 100) target_right_speed = 100;
    }
    
    // 부드러운 가속/감속
    if (target_left_speed == 0 && target_right_speed == 0) {
        current_left_speed = 0;
        current_right_speed = 0;
    } else {
        if (current_left_speed < target_left_speed) {
            current_left_speed += MAX_SPEED_CHANGE;
            if (current_left_speed > target_left_speed) 
                current_left_speed = target_left_speed;
        } else if (current_left_speed > target_left_speed) {
            current_left_speed -= MAX_SPEED_CHANGE;
            if (current_left_speed < target_left_speed) 
                current_left_speed = target_left_speed;
        }
        
        if (current_right_speed < target_right_speed) {
            current_right_speed += MAX_SPEED_CHANGE;
            if (current_right_speed > target_right_speed) 
                current_right_speed = target_right_speed;
        } else if (current_right_speed > target_right_speed) {
            current_right_speed -= MAX_SPEED_CHANGE;
            if (current_right_speed < target_right_speed) 
                current_right_speed = target_right_speed;
        }
    }
    
    // 제어 신호 출력
    handle[0] = cmd;
    set_motor_speed(PWM_5_ADDR, current_left_speed);
    set_motor_speed(PWM_6_ADDR, current_right_speed);
}

// =================== 비상정지 함수 ===================
void emergency_stop(void) {
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    
    // 모든 모터 정지
    handle[0] = 0;
    set_motor_speed(PWM_5_ADDR, 0);
    set_motor_speed(PWM_6_ADDR, 0);
    
    // 속도 리셋
    current_left_speed = 0;
    current_right_speed = 0;
    
    uart_send_string("EMERGENCY STOP!\r\n");
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
            // 버튼별 동작 처리
            switch(btn_val) {
                case 1: uart_send_string("BUCKET DOWN\r\n"); break;
                case 2: uart_send_string("WORK MODE\r\n"); break;
                case 4: uart_send_string("DRIVE MODE\r\n"); break;
                case 8: uart_send_string("BUCKET UP\r\n"); break;
                case 16: // 비상정지 버튼
                    emergency_stop();
                    break;
            }
        }
        return;
    }
    
    // NEUTRAL 명령 처리
    if (is_neutral_command(line)) {
        int mode = get_number_improved(line, "MODE=");
        if (mode != -999) {
            emergency_stop(); // 중립 명령시 모터 정지
        }
        return;
    }
    
    // 조이스틱 데이터 처리
    if (!strstr(line, "MODE=")) return;
    
    // 파싱
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
    
    // 제어 실행
    if (mode == 1) {  // Work Mode
        // 중립 체크
        if (x1 >= RANGE_MIN && x1 <= RANGE_MAX &&
            y1 >= RANGE_MIN && y1 <= RANGE_MAX &&
            x2 >= RANGE_MIN && x2 <= RANGE_MAX &&
            y2 >= RANGE_MIN && y2 <= RANGE_MAX) {
            return;
        }
        
        uart_send_string("WORK MODE\r\n");
        move_servo_smooth_x1(x1);  // 360도 서보
        move_servo_smooth_y1(y1);
        move_servo_smooth_x2(x2);
        move_servo_smooth_y2(y2);  // 0~90도 서보
    }
    else if (mode == 2) {  // Drive Mode
        // 중립 체크 및 강제 정지
        if (y1 >= RANGE_MIN && y1 <= RANGE_MAX && 
            y2 >= RANGE_MIN && y2 <= RANGE_MAX) {
            force_stop_motors();
            return;
        }
        move_wheels_smooth(y1, y2);
    }
}

// =================== 메인 ===================
int main(void) {
    // UART 초기화
    if (XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    uart_send_string("=== Enhanced Servo & DC Motor Control Start ===\r\n");
    
    // DC모터만 초기화 (안전상 필요)
    set_motor_speed(PWM_5_ADDR, 0);  // 왼쪽 바퀴 정지
    set_motor_speed(PWM_6_ADDR, 0);  // 오른쪽 바퀴 정지
    uart_send_string("DC Motors initialized (stopped)\r\n");
    
    // 핸들 초기화
    volatile unsigned int *handle = (volatile unsigned int*)HANDLE_ADDR;
    handle[0] = 0;
    uart_send_string("Handle initialized\r\n");
    
    uart_send_string("System ready!\r\n");
    
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