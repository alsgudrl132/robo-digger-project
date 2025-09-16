//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Tue Sep 16 17:35:57 2025
//Host        : min-MacBookPro15-1 running 64-bit Ubuntu 24.04.3 LTS
//Command     : generate_target soc_pwm_wrapper.bd
//Design      : soc_pwm_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module soc_pwm_wrapper
   (pwm_0,
    pwm_1,
    pwm_2,
    pwm_3,
    pwm_4,
    pwm_5,
    pwm_6,
    pwm_7,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  output pwm_0;
  output pwm_1;
  output pwm_2;
  output pwm_3;
  output pwm_4;
  output pwm_5;
  output pwm_6;
  output pwm_7;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire pwm_0;
  wire pwm_1;
  wire pwm_2;
  wire pwm_3;
  wire pwm_4;
  wire pwm_5;
  wire pwm_6;
  wire pwm_7;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  soc_pwm soc_pwm_i
       (.pwm_0(pwm_0),
        .pwm_1(pwm_1),
        .pwm_2(pwm_2),
        .pwm_3(pwm_3),
        .pwm_4(pwm_4),
        .pwm_5(pwm_5),
        .pwm_6(pwm_6),
        .pwm_7(pwm_7),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
