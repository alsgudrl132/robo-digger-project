/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include "xil_io.h"
#include "xparameters.h"
#include <unistd.h>

#define SYS_CLK_FREQ 100000000
#define PWM_BASEADDR XPAR_MYIP_PWM_0_BASEADDR // 서보 연결 PWM
#define REG_DUTY      0x0
#define REG_TEMP      0x4
#define REG_DUTYSTEP  0x8

// 서보 각도 → duty 계산 (0~180°)
uint32_t angle_to_duty(uint32_t angle, uint32_t duty_step) {
    // 20ms 주기 기준, pulse width: 0.5ms ~ 2.5ms
    // duty = duty_step * (pulse / period)
    uint32_t duty_min = duty_step * 5 / 200;   // 0.5ms → 25 (duty_step=1000 기준)
    uint32_t duty_max = duty_step * 25 / 200;  // 2.5ms → 125

    return duty_min + ((duty_max - duty_min) * angle) / 180;
}

// PWM 설정 함수
void pwm_set(uint32_t base, uint32_t duty, uint32_t pwm_freq, uint32_t duty_step) {
    uint32_t temp = SYS_CLK_FREQ / pwm_freq / duty_step / 2;
    Xil_Out32(base + REG_DUTY, duty);
    Xil_Out32(base + REG_TEMP, temp);
    Xil_Out32(base + REG_DUTYSTEP, duty_step);
}

int main() {
    uint32_t duty_step = 4095; // PWM 모듈 최대값
    uint32_t angle = 0;
    uint8_t inc_flag = 1;

    while(1) {
        // 각도를 duty로 변환 후 PWM 출력
        uint32_t duty = angle_to_duty(angle, duty_step);
        pwm_set(PWM_BASEADDR, duty, 50, duty_step); // 50Hz 서보용

        // 각도 증가/감소
        if (inc_flag) {
            if (angle >= 180) inc_flag = 0;
            else angle += 5;
        } else {
            if (angle <= 0) inc_flag = 1;
            else angle -= 5;
        }

        usleep(20000); // 20ms
    }
}