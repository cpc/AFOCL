-- Copyright (c) 2023 Tampere University
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------
-- Title      : AXI slave constant
-- Project    :
-------------------------------------------------------------------------------
-- File       : axi_constant.vhdl
-- Author     : Topi Leppanen
-- Company    : Tampere University
-- Created    : 2023-10-10
-- Last update: 2023-10-10
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2023-10-10  1.0      leppanen  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_constant is
  generic (
    axi_addrw_g : integer := 7
  );
  port (
    clk       : in std_logic;
    rstx      : in std_logic;
    -- Constant interface
    tready_00_tdest_out  : out std_logic_vector(4 downto 0);
    tready_01_tdest_out  : out std_logic_vector(4 downto 0);
    tready_02_tdest_out  : out std_logic_vector(4 downto 0);
    tready_03_tdest_out  : out std_logic_vector(4 downto 0);
    tready_04_tdest_out  : out std_logic_vector(4 downto 0);
    tready_05_tdest_out  : out std_logic_vector(4 downto 0);
    tready_06_tdest_out  : out std_logic_vector(4 downto 0);
    tready_07_tdest_out  : out std_logic_vector(4 downto 0);
    tready_08_tdest_out  : out std_logic_vector(4 downto 0);
    tready_09_tdest_out  : out std_logic_vector(4 downto 0);
    tready_10_tdest_out  : out std_logic_vector(4 downto 0);
    tready_11_tdest_out  : out std_logic_vector(4 downto 0);
    tready_12_tdest_out  : out std_logic_vector(4 downto 0);
    tready_13_tdest_out  : out std_logic_vector(4 downto 0);
    tready_14_tdest_out  : out std_logic_vector(4 downto 0);
    tready_15_tdest_out  : out std_logic_vector(4 downto 0);
    tready_16_tdest_out  : out std_logic_vector(4 downto 0);
    tready_17_tdest_out  : out std_logic_vector(4 downto 0);
    tready_18_tdest_out  : out std_logic_vector(4 downto 0);
    tready_19_tdest_out  : out std_logic_vector(4 downto 0);
    tready_00_tready_out : out std_logic;
    tready_01_tready_out : out std_logic;
    tready_02_tready_out : out std_logic;
    tready_03_tready_out : out std_logic;
    tready_04_tready_out : out std_logic;
    tready_05_tready_out : out std_logic;
    tready_06_tready_out : out std_logic;
    tready_07_tready_out : out std_logic;
    tready_08_tready_out : out std_logic;
    tready_09_tready_out : out std_logic;
    tready_10_tready_out : out std_logic;
    tready_11_tready_out : out std_logic;
    tready_12_tready_out : out std_logic;
    tready_13_tready_out : out std_logic;
    tready_14_tready_out : out std_logic;
    tready_15_tready_out : out std_logic;
    tready_16_tready_out : out std_logic;
    tready_17_tready_out : out std_logic;
    tready_18_tready_out : out std_logic;
    tready_19_tready_out : out std_logic;
    tready_00_tready_in  : in  std_logic;
    tready_01_tready_in  : in  std_logic;
    tready_02_tready_in  : in  std_logic;
    tready_03_tready_in  : in  std_logic;
    tready_04_tready_in  : in  std_logic;
    tready_05_tready_in  : in  std_logic;
    tready_06_tready_in  : in  std_logic;
    tready_07_tready_in  : in  std_logic;
    tready_08_tready_in  : in  std_logic;
    tready_09_tready_in  : in  std_logic;
    tready_10_tready_in  : in  std_logic;
    tready_11_tready_in  : in  std_logic;
    tready_12_tready_in  : in  std_logic;
    tready_13_tready_in  : in  std_logic;
    tready_14_tready_in  : in  std_logic;
    tready_15_tready_in  : in  std_logic;
    tready_16_tready_in  : in  std_logic;
    tready_17_tready_in  : in  std_logic;
    tready_18_tready_in  : in  std_logic;
    tready_19_tready_in  : in  std_logic;
    -- AXI slave port
    s_axi_awaddr   : in  STD_LOGIC_VECTOR (axi_addrw_g-1 downto 0);
    s_axi_awvalid  : in  STD_LOGIC;
    s_axi_awready  : out STD_LOGIC;
    s_axi_wdata    : in  STD_LOGIC_VECTOR (31 downto 0);
    s_axi_wvalid   : in  STD_LOGIC;
    s_axi_wready   : out STD_LOGIC;
    s_axi_bresp    : out STD_LOGIC_VECTOR (2-1 downto 0);
    s_axi_bvalid   : out STD_LOGIC;
    s_axi_bready   : in  STD_LOGIC;
    s_axi_araddr   : in  STD_LOGIC_VECTOR (axi_addrw_g-1 downto 0);
    s_axi_arvalid  : in  STD_LOGIC;
    s_axi_arready  : out STD_LOGIC;
    s_axi_rdata    : out STD_LOGIC_VECTOR (31 downto 0);
    s_axi_rresp    : out STD_LOGIC_VECTOR (2-1 downto 0);
    s_axi_rvalid   : out STD_LOGIC;
    s_axi_rready   : in  STD_LOGIC
  );
end entity axi_constant;

architecture rtl of axi_constant is

  constant constant_count_c : integer := 20;

  constant AXI_OKAY    : std_logic_vector(1 downto 0) := "00";
  constant AXI_SLVERR  : std_logic_vector(1 downto 0) := "10";
  type state_t is (S_READY, S_WRITE_DATA, S_FINISH_WRITE);
  signal state   : state_t;

  -- Output registers
  signal s_axi_awready_r : std_logic;
  signal s_axi_wready_r  : std_logic;
  signal s_axi_bresp_r   : std_logic_vector(s_axi_bresp'range);
  signal s_axi_bvalid_r  : std_logic;

  signal axi_addr_r   : unsigned(s_axi_awaddr'high - 2 downto 0);

  type t_constant_arr is array (0 to constant_count_c-1) of std_logic_vector(tready_00_tdest_out'range);
  type t_constant_bool_arr is array (0 to constant_count_c-1) of std_logic;
  signal tready_tdest_arr  : t_constant_arr;
  signal tready_enable_arr : t_constant_bool_arr;

begin

    sync : process(clk, rstx)
    begin
        if rstx = '0' then
            s_axi_awready_r <= '0';
            s_axi_wready_r  <= '0';
            s_axi_bresp_r   <= (others => '0');
            s_axi_bvalid_r  <= '0';
            for k in 0 to constant_count_c-1 loop
                tready_tdest_arr(k) <= (others => '1');
                tready_enable_arr(k) <= '0';
            end loop;
            axi_addr_r <= (others => '0');
            state      <= S_READY;
        elsif rising_edge(clk) then
            if s_axi_awready_r = '1' and s_axi_awvalid = '1' then
                s_axi_awready_r <= '0';
            end if;
            s_axi_wready_r  <= '0';

            case state is
                when S_READY =>
                    if s_axi_awvalid = '1' then
                        s_axi_awready_r <= '1';
                        axi_addr_r      <= unsigned(s_axi_awaddr(s_axi_awaddr'high downto 2));
                        state           <= S_WRITE_DATA;
                    end if;

                when S_WRITE_DATA =>
                    s_axi_wready_r <= '1';
                    if s_axi_wvalid = '1' and s_axi_wready_r = '1' then
                        s_axi_wready_r <= '0';
                        s_axi_bresp_r  <= AXI_OKAY;
                        s_axi_bvalid_r <= '1';
                        state        <= S_FINISH_WRITE;
                        if to_integer(axi_addr_r) < constant_count_c then
                            tready_tdest_arr(to_integer(axi_addr_r)) <= s_axi_wdata(tready_00_tdest_out'range);
                            tready_enable_arr(to_integer(axi_addr_r))  <= '1';
                        end if;
                    end if;

                when S_FINISH_WRITE =>
                    if s_axi_bready = '1' then
                        s_axi_bvalid_r <= '0';
                    end if;
                    if s_axi_bvalid_r = '0' then
                        state <= S_READY;
                    end if;
            end case;
        end if;
    end process;

    s_axi_awready  <= s_axi_awready_r;
    s_axi_wready   <= s_axi_wready_r;
    s_axi_bresp    <= s_axi_bresp_r;
    s_axi_bvalid   <= s_axi_bvalid_r;
    s_axi_arready  <= '1';
    s_axi_rdata    <= (others => '0');
    s_axi_rresp    <= AXI_OKAY;
    s_axi_rvalid   <= '1';
    tready_00_tdest_out  <= tready_tdest_arr(0);
    tready_01_tdest_out  <= tready_tdest_arr(1);
    tready_02_tdest_out  <= tready_tdest_arr(2);
    tready_03_tdest_out  <= tready_tdest_arr(3);
    tready_04_tdest_out  <= tready_tdest_arr(4);
    tready_05_tdest_out  <= tready_tdest_arr(5);
    tready_06_tdest_out  <= tready_tdest_arr(6);
    tready_07_tdest_out  <= tready_tdest_arr(7);
    tready_08_tdest_out  <= tready_tdest_arr(8);
    tready_09_tdest_out  <= tready_tdest_arr(9);
    tready_10_tdest_out  <= tready_tdest_arr(10);
    tready_11_tdest_out  <= tready_tdest_arr(11);
    tready_12_tdest_out  <= tready_tdest_arr(12);
    tready_13_tdest_out  <= tready_tdest_arr(13);
    tready_14_tdest_out  <= tready_tdest_arr(14);
    tready_15_tdest_out  <= tready_tdest_arr(15);
    tready_16_tdest_out  <= tready_tdest_arr(16);
    tready_17_tdest_out  <= tready_tdest_arr(17);
    tready_18_tdest_out  <= tready_tdest_arr(18);
    tready_19_tdest_out  <= tready_tdest_arr(19);

    tready_00_tready_out <= tready_00_tready_in and tready_enable_arr(0);
    tready_01_tready_out <= tready_01_tready_in and tready_enable_arr(1);
    tready_02_tready_out <= tready_02_tready_in and tready_enable_arr(2);
    tready_03_tready_out <= tready_03_tready_in and tready_enable_arr(3);
    tready_04_tready_out <= tready_04_tready_in and tready_enable_arr(4);
    tready_05_tready_out <= tready_05_tready_in and tready_enable_arr(5);
    tready_06_tready_out <= tready_06_tready_in and tready_enable_arr(6);
    tready_07_tready_out <= tready_07_tready_in and tready_enable_arr(7);
    tready_08_tready_out <= tready_08_tready_in and tready_enable_arr(8);
    tready_09_tready_out <= tready_09_tready_in and tready_enable_arr(9);
    tready_10_tready_out <= tready_10_tready_in and tready_enable_arr(10);
    tready_11_tready_out <= tready_11_tready_in and tready_enable_arr(11);
    tready_12_tready_out <= tready_12_tready_in and tready_enable_arr(12);
    tready_13_tready_out <= tready_13_tready_in and tready_enable_arr(13);
    tready_14_tready_out <= tready_14_tready_in and tready_enable_arr(14);
    tready_15_tready_out <= tready_15_tready_in and tready_enable_arr(15);
    tready_16_tready_out <= tready_16_tready_in and tready_enable_arr(16);
    tready_17_tready_out <= tready_17_tready_in and tready_enable_arr(17);
    tready_18_tready_out <= tready_18_tready_in and tready_enable_arr(18);
    tready_19_tready_out <= tready_19_tready_in and tready_enable_arr(19);
end architecture rtl;

