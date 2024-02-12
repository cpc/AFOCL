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
    axi_addrw_g : integer := 7;
    axis_dataw_g : integer := 512
  );
  port (
    clk       : in std_logic;
    rstx      : in std_logic;
    -- Constant interface
    M_AXIS_M00_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M01_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M02_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M03_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M04_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M05_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M06_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M07_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M08_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M09_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M10_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M11_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M12_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M13_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M14_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M15_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M16_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M17_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M18_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M19_tdata  : out std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_M00_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M01_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M02_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M03_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M04_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M05_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M06_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M07_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M08_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M09_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M10_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M11_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M12_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M13_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M14_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M15_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M16_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M17_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M18_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M19_tdest  : out std_logic_vector(4 downto 0);
    M_AXIS_M00_tvalid : out std_logic;
    M_AXIS_M01_tvalid : out std_logic;
    M_AXIS_M02_tvalid : out std_logic;
    M_AXIS_M03_tvalid : out std_logic;
    M_AXIS_M04_tvalid : out std_logic;
    M_AXIS_M05_tvalid : out std_logic;
    M_AXIS_M06_tvalid : out std_logic;
    M_AXIS_M07_tvalid : out std_logic;
    M_AXIS_M08_tvalid : out std_logic;
    M_AXIS_M09_tvalid : out std_logic;
    M_AXIS_M10_tvalid : out std_logic;
    M_AXIS_M11_tvalid : out std_logic;
    M_AXIS_M12_tvalid : out std_logic;
    M_AXIS_M13_tvalid : out std_logic;
    M_AXIS_M14_tvalid : out std_logic;
    M_AXIS_M15_tvalid : out std_logic;
    M_AXIS_M16_tvalid : out std_logic;
    M_AXIS_M17_tvalid : out std_logic;
    M_AXIS_M18_tvalid : out std_logic;
    M_AXIS_M19_tvalid : out std_logic;
    M_AXIS_M00_tready  : in  std_logic;
    M_AXIS_M01_tready  : in  std_logic;
    M_AXIS_M02_tready  : in  std_logic;
    M_AXIS_M03_tready  : in  std_logic;
    M_AXIS_M04_tready  : in  std_logic;
    M_AXIS_M05_tready  : in  std_logic;
    M_AXIS_M06_tready  : in  std_logic;
    M_AXIS_M07_tready  : in  std_logic;
    M_AXIS_M08_tready  : in  std_logic;
    M_AXIS_M09_tready  : in  std_logic;
    M_AXIS_M10_tready  : in  std_logic;
    M_AXIS_M11_tready  : in  std_logic;
    M_AXIS_M12_tready  : in  std_logic;
    M_AXIS_M13_tready  : in  std_logic;
    M_AXIS_M14_tready  : in  std_logic;
    M_AXIS_M15_tready  : in  std_logic;
    M_AXIS_M16_tready  : in  std_logic;
    M_AXIS_M17_tready  : in  std_logic;
    M_AXIS_M18_tready  : in  std_logic;
    M_AXIS_M19_tready  : in  std_logic;
    S_AXIS_S00_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S01_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S02_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S03_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S04_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S05_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S06_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S07_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S08_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S09_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S10_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S11_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S12_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S13_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S14_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S15_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S16_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S17_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S18_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S19_tdata  : in std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_S00_tready : out std_logic;
    S_AXIS_S01_tready : out std_logic;
    S_AXIS_S02_tready : out std_logic;
    S_AXIS_S03_tready : out std_logic;
    S_AXIS_S04_tready : out std_logic;
    S_AXIS_S05_tready : out std_logic;
    S_AXIS_S06_tready : out std_logic;
    S_AXIS_S07_tready : out std_logic;
    S_AXIS_S08_tready : out std_logic;
    S_AXIS_S09_tready : out std_logic;
    S_AXIS_S10_tready : out std_logic;
    S_AXIS_S11_tready : out std_logic;
    S_AXIS_S12_tready : out std_logic;
    S_AXIS_S13_tready : out std_logic;
    S_AXIS_S14_tready : out std_logic;
    S_AXIS_S15_tready : out std_logic;
    S_AXIS_S16_tready : out std_logic;
    S_AXIS_S17_tready : out std_logic;
    S_AXIS_S18_tready : out std_logic;
    S_AXIS_S19_tready : out std_logic;
    S_AXIS_S00_tvalid  : in  std_logic;
    S_AXIS_S01_tvalid  : in  std_logic;
    S_AXIS_S02_tvalid  : in  std_logic;
    S_AXIS_S03_tvalid  : in  std_logic;
    S_AXIS_S04_tvalid  : in  std_logic;
    S_AXIS_S05_tvalid  : in  std_logic;
    S_AXIS_S06_tvalid  : in  std_logic;
    S_AXIS_S07_tvalid  : in  std_logic;
    S_AXIS_S08_tvalid  : in  std_logic;
    S_AXIS_S09_tvalid  : in  std_logic;
    S_AXIS_S10_tvalid  : in  std_logic;
    S_AXIS_S11_tvalid  : in  std_logic;
    S_AXIS_S12_tvalid  : in  std_logic;
    S_AXIS_S13_tvalid  : in  std_logic;
    S_AXIS_S14_tvalid  : in  std_logic;
    S_AXIS_S15_tvalid  : in  std_logic;
    S_AXIS_S16_tvalid  : in  std_logic;
    S_AXIS_S17_tvalid  : in  std_logic;
    S_AXIS_S18_tvalid  : in  std_logic;
    S_AXIS_S19_tvalid  : in  std_logic;
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

  type t_constant_arr is array (0 to constant_count_c-1) of std_logic_vector(M_AXIS_M00_tdest'range);
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
                            tready_tdest_arr(to_integer(axi_addr_r)) <= s_axi_wdata(M_AXIS_M00_tdest'range);
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
    M_AXIS_M00_tdest  <= tready_tdest_arr(0);
    M_AXIS_M01_tdest  <= tready_tdest_arr(1);
    M_AXIS_M02_tdest  <= tready_tdest_arr(2);
    M_AXIS_M03_tdest  <= tready_tdest_arr(3);
    M_AXIS_M04_tdest  <= tready_tdest_arr(4);
    M_AXIS_M05_tdest  <= tready_tdest_arr(5);
    M_AXIS_M06_tdest  <= tready_tdest_arr(6);
    M_AXIS_M07_tdest  <= tready_tdest_arr(7);
    M_AXIS_M08_tdest  <= tready_tdest_arr(8);
    M_AXIS_M09_tdest  <= tready_tdest_arr(9);
    M_AXIS_M10_tdest  <= tready_tdest_arr(10);
    M_AXIS_M11_tdest  <= tready_tdest_arr(11);
    M_AXIS_M12_tdest  <= tready_tdest_arr(12);
    M_AXIS_M13_tdest  <= tready_tdest_arr(13);
    M_AXIS_M14_tdest  <= tready_tdest_arr(14);
    M_AXIS_M15_tdest  <= tready_tdest_arr(15);
    M_AXIS_M16_tdest  <= tready_tdest_arr(16);
    M_AXIS_M17_tdest  <= tready_tdest_arr(17);
    M_AXIS_M18_tdest  <= tready_tdest_arr(18);
    M_AXIS_M19_tdest  <= tready_tdest_arr(19);

    S_AXIS_S00_tready <= M_AXIS_M00_tready and tready_enable_arr(0);
    S_AXIS_S01_tready <= M_AXIS_M01_tready and tready_enable_arr(1);
    S_AXIS_S02_tready <= M_AXIS_M02_tready and tready_enable_arr(2);
    S_AXIS_S03_tready <= M_AXIS_M03_tready and tready_enable_arr(3);
    S_AXIS_S04_tready <= M_AXIS_M04_tready and tready_enable_arr(4);
    S_AXIS_S05_tready <= M_AXIS_M05_tready and tready_enable_arr(5);
    S_AXIS_S06_tready <= M_AXIS_M06_tready and tready_enable_arr(6);
    S_AXIS_S07_tready <= M_AXIS_M07_tready and tready_enable_arr(7);
    S_AXIS_S08_tready <= M_AXIS_M08_tready and tready_enable_arr(8);
    S_AXIS_S09_tready <= M_AXIS_M09_tready and tready_enable_arr(9);
    S_AXIS_S10_tready <= M_AXIS_M10_tready and tready_enable_arr(10);
    S_AXIS_S11_tready <= M_AXIS_M11_tready and tready_enable_arr(11);
    S_AXIS_S12_tready <= M_AXIS_M12_tready and tready_enable_arr(12);
    S_AXIS_S13_tready <= M_AXIS_M13_tready and tready_enable_arr(13);
    S_AXIS_S14_tready <= M_AXIS_M14_tready and tready_enable_arr(14);
    S_AXIS_S15_tready <= M_AXIS_M15_tready and tready_enable_arr(15);
    S_AXIS_S16_tready <= M_AXIS_M16_tready and tready_enable_arr(16);
    S_AXIS_S17_tready <= M_AXIS_M17_tready and tready_enable_arr(17);
    S_AXIS_S18_tready <= M_AXIS_M18_tready and tready_enable_arr(18);
    S_AXIS_S19_tready <= M_AXIS_M19_tready and tready_enable_arr(19);
    M_AXIS_M00_tvalid <= S_AXIS_S00_tvalid and tready_enable_arr(0);
    M_AXIS_M01_tvalid <= S_AXIS_S01_tvalid and tready_enable_arr(1);
    M_AXIS_M02_tvalid <= S_AXIS_S02_tvalid and tready_enable_arr(2);
    M_AXIS_M03_tvalid <= S_AXIS_S03_tvalid and tready_enable_arr(3);
    M_AXIS_M04_tvalid <= S_AXIS_S04_tvalid and tready_enable_arr(4);
    M_AXIS_M05_tvalid <= S_AXIS_S05_tvalid and tready_enable_arr(5);
    M_AXIS_M06_tvalid <= S_AXIS_S06_tvalid and tready_enable_arr(6);
    M_AXIS_M07_tvalid <= S_AXIS_S07_tvalid and tready_enable_arr(7);
    M_AXIS_M08_tvalid <= S_AXIS_S08_tvalid and tready_enable_arr(8);
    M_AXIS_M09_tvalid <= S_AXIS_S09_tvalid and tready_enable_arr(9);
    M_AXIS_M10_tvalid <= S_AXIS_S10_tvalid and tready_enable_arr(10);
    M_AXIS_M11_tvalid <= S_AXIS_S11_tvalid and tready_enable_arr(11);
    M_AXIS_M12_tvalid <= S_AXIS_S12_tvalid and tready_enable_arr(12);
    M_AXIS_M13_tvalid <= S_AXIS_S13_tvalid and tready_enable_arr(13);
    M_AXIS_M14_tvalid <= S_AXIS_S14_tvalid and tready_enable_arr(14);
    M_AXIS_M15_tvalid <= S_AXIS_S15_tvalid and tready_enable_arr(15);
    M_AXIS_M16_tvalid <= S_AXIS_S16_tvalid and tready_enable_arr(16);
    M_AXIS_M17_tvalid <= S_AXIS_S17_tvalid and tready_enable_arr(17);
    M_AXIS_M18_tvalid <= S_AXIS_S18_tvalid and tready_enable_arr(18);
    M_AXIS_M19_tvalid <= S_AXIS_S19_tvalid and tready_enable_arr(19);
    M_AXIS_M00_tdata <= S_AXIS_S00_tdata;
    M_AXIS_M01_tdata <= S_AXIS_S01_tdata;
    M_AXIS_M02_tdata <= S_AXIS_S02_tdata;
    M_AXIS_M03_tdata <= S_AXIS_S03_tdata;
    M_AXIS_M04_tdata <= S_AXIS_S04_tdata;
    M_AXIS_M05_tdata <= S_AXIS_S05_tdata;
    M_AXIS_M06_tdata <= S_AXIS_S06_tdata;
    M_AXIS_M07_tdata <= S_AXIS_S07_tdata;
    M_AXIS_M08_tdata <= S_AXIS_S08_tdata;
    M_AXIS_M09_tdata <= S_AXIS_S09_tdata;
    M_AXIS_M10_tdata <= S_AXIS_S10_tdata;
    M_AXIS_M11_tdata <= S_AXIS_S11_tdata;
    M_AXIS_M12_tdata <= S_AXIS_S12_tdata;
    M_AXIS_M13_tdata <= S_AXIS_S13_tdata;
    M_AXIS_M14_tdata <= S_AXIS_S14_tdata;
    M_AXIS_M15_tdata <= S_AXIS_S15_tdata;
    M_AXIS_M16_tdata <= S_AXIS_S16_tdata;
    M_AXIS_M17_tdata <= S_AXIS_S17_tdata;
    M_AXIS_M18_tdata <= S_AXIS_S18_tdata;
    M_AXIS_M19_tdata <= S_AXIS_S19_tdata;
end architecture rtl;

