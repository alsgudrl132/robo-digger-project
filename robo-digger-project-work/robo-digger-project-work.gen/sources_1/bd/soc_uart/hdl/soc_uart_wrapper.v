//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Tue Sep 16 19:27:34 2025
//Host        : min-MacBookPro15-1 running 64-bit Ubuntu 24.04.3 LTS
//Command     : generate_target soc_uart_wrapper.bd
//Design      : soc_uart_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module soc_uart_wrapper
   (reset,
    rx_0,
    sys_clock,
    tx_0,
    usb_uart_rxd,
    usb_uart_txd);
  input reset;
  input rx_0;
  input sys_clock;
  output tx_0;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire reset;
  wire rx_0;
  wire sys_clock;
  wire tx_0;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  soc_uart soc_uart_i
       (.reset(reset),
        .rx_0(rx_0),
        .sys_clock(sys_clock),
        .tx_0(tx_0),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
