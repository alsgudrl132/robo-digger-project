//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Mon Sep 22 16:18:25 2025
//Host        : min-MacBookPro15-1 running 64-bit Ubuntu 24.04.3 LTS
//Command     : generate_target soc_digger_wrapper.bd
//Design      : soc_digger_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module soc_digger_wrapper
   (motor_control_0,
    pwm_0,
    pwm_1,
    pwm_2,
    pwm_3,
    pwm_4,
    pwm_5,
    pwm_6,
    reset,
    rx_0,
    sys_clock,
    tx_0,
    usb_uart_rxd,
    usb_uart_txd);
  output [3:0]motor_control_0;
  output pwm_0;
  output pwm_1;
  output pwm_2;
  output pwm_3;
  output pwm_4;
  output pwm_5;
  output pwm_6;
  input reset;
  input rx_0;
  input sys_clock;
  output tx_0;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [3:0]motor_control_0;
  wire pwm_0;
  wire pwm_1;
  wire pwm_2;
  wire pwm_3;
  wire pwm_4;
  wire pwm_5;
  wire pwm_6;
  wire reset;
  wire rx_0;
  wire sys_clock;
  wire tx_0;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  soc_digger soc_digger_i
       (.motor_control_0(motor_control_0),
        .pwm_0(pwm_0),
        .pwm_1(pwm_1),
        .pwm_2(pwm_2),
        .pwm_3(pwm_3),
        .pwm_4(pwm_4),
        .pwm_5(pwm_5),
        .pwm_6(pwm_6),
        .reset(reset),
        .rx_0(rx_0),
        .sys_clock(sys_clock),
        .tx_0(tx_0),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
