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

#include "xuartlite.h"
#include "xparameters.h"
#include "xil_printf.h"

#define HC05_UART_DEVICE_ID   XPAR_XUARTLITE_0_BASEADDR   // HC-05 연결
#define USB_UART_DEVICE_ID    XPAR_XUARTLITE_1_BASEADDR   // USB-UART 연결

XUartLite Uart_HC05;
XUartLite Uart_USB;

int main(void)
{
    int Status;
    u8 RecvBuffer[16];
    int ReceivedCount;

    xil_printf("HC-05 to USB UART Bridge Start\r\n");

    // 1) HC-05 UART 초기화
    Status = XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("HC-05 UART Init Failed\r\n");
        return XST_FAILURE;
    }

    // 2) USB UART 초기화
    Status = XUartLite_Initialize(&Uart_USB, USB_UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("USB UART Init Failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("UART Init Success\r\n");

    while (1) {
        // 3) HC-05에서 데이터 수신
        ReceivedCount = XUartLite_Recv(&Uart_HC05, RecvBuffer, sizeof(RecvBuffer));

        if (ReceivedCount > 0) {
            // 4) 수신 데이터를 USB UART로 출력
            XUartLite_Send(&Uart_USB, RecvBuffer, ReceivedCount);
        }
    }

    return 0;
}
