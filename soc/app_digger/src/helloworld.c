/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: HC-05 to USB UART Bridge with [MODE:x] Parsing
 *
 * HC-05 (블루투스 모듈)에서 수신한 문자열을 USB UART로 전달하고
 * "[MODE:x] X1=####,Y1=####,X2=####,Y2=####" 형식 데이터를 파싱.
 */

#include "xuartlite.h"
#include "xparameters.h"
#include "xil_printf.h"
#include <string.h>
#include "sleep.h"
#include <stdio.h>

// =================== 설정 ===================
#define HC05_UART_DEVICE_ID XPAR_XUARTLITE_0_BASEADDR // HC-05 연결
#define USB_UART_DEVICE_ID XPAR_XUARTLITE_1_BASEADDR  // USB-UART 연결

#define RECV_BUFFER_SIZE   16
#define ACCUM_BUFFER_SIZE  256

// =================== 전역 ===================
XUartLite Uart_HC05;
XUartLite Uart_USB;

// 데이터 누적 버퍼
static u8 AccumBuffer[ACCUM_BUFFER_SIZE];
static int AccumCount = 0;

typedef struct {
    int mode;
    int x1;
    int y1;
    int x2;
    int y2;
} ParsedData;

void ProcessCompleteMessage(void);
int FindMessageEnd(u8* buffer, int length);

int main(void)
{
    int Status;
    u8 RecvBuffer[RECV_BUFFER_SIZE];
    int ReceivedCount;

    xil_printf("HC-05 to USB UART Bridge Start\r\n");

    // HC-05 UART 초기화
    Status = XUartLite_Initialize(&Uart_HC05, HC05_UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("HC-05 UART Init Failed\r\n");
        return XST_FAILURE;
    }

    // USB UART 초기화
    Status = XUartLite_Initialize(&Uart_USB, USB_UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("USB UART Init Failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("UART Init Success\r\n");

    memset(AccumBuffer, 0, ACCUM_BUFFER_SIZE);
    AccumCount = 0;

    while (1) {
        // HC-05에서 데이터 수신
        ReceivedCount = XUartLite_Recv(&Uart_HC05, RecvBuffer, RECV_BUFFER_SIZE);

        if (ReceivedCount > 0) {
            if (AccumCount + ReceivedCount >= ACCUM_BUFFER_SIZE) {
                xil_printf("Buffer overflow, resetting\r\n");
                AccumCount = 0;
                continue;
            }

            memcpy(&AccumBuffer[AccumCount], RecvBuffer, ReceivedCount);
            AccumCount += ReceivedCount;

            int messageEndPos = FindMessageEnd(AccumBuffer, AccumCount);
            if (messageEndPos >= 0) {
                AccumBuffer[messageEndPos] = '\0'; // 문자열 종료
                ProcessCompleteMessage();

                int remainingBytes = AccumCount - messageEndPos - 1;
                if (remainingBytes > 0) {
                    memmove(AccumBuffer, &AccumBuffer[messageEndPos + 1], remainingBytes);
                    AccumCount = remainingBytes;
                } else {
                    AccumCount = 0;
                }
            }
        }
        usleep(100);
    }

    return 0;
}

int FindMessageEnd(u8* buffer, int length)
{
    for (int i = 0; i < length; i++) {
        if (buffer[i] == '\n' || buffer[i] == '\r') {
            return i;
        }
    }
    return -1;
}

void ProcessCompleteMessage(void)
{
    ParsedData data;
    data.mode = data.x1 = data.y1 = data.x2 = data.y2 = 0;

    // "[MODE:2] X1=2159,Y1=1810,X2=2202,Y2=2187" 형식 파싱
    if (sscanf((char*)AccumBuffer,
               "[MODE:%d] X1=%d,Y1=%d,X2=%d,Y2=%d",
               &data.mode, &data.x1, &data.y1, &data.x2, &data.y2) == 5) {

        xil_printf("Parsed Data:\r\n");
        xil_printf(" Mode = %d\r\n", data.mode);
        xil_printf(" X1   = %d\r\n", data.x1);
        xil_printf(" Y1   = %d\r\n", data.y1);
        xil_printf(" X2   = %d\r\n", data.x2);
        xil_printf(" Y2   = %d\r\n", data.y2);

        // USB UART로 파싱 결과 전송
        char outbuf[128];
        int len = sprintf(outbuf,
                          "Mode=%d, X1=%d, Y1=%d, X2=%d, Y2=%d\r\n",
                          data.mode, data.x1, data.y1, data.x2, data.y2);
        XUartLite_Send(&Uart_USB, (u8*)outbuf, len);
    }
    else {
        xil_printf("Parse failed: %s\r\n", (char*)AccumBuffer);
    }
}
