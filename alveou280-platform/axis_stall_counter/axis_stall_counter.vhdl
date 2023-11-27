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
-- Title      : AXI stream profiler
-- Project    :
-------------------------------------------------------------------------------
-- File       : axi_stream_stall_counter.vhdl
-- Author     : Topi Leppanen
-- Company    : Tampere University
-- Created    : 2023-11-22
-- Last update: 2023-11-22
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2023-11-22  1.0      leppanen  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_stall_counter is
  generic (
    axis_dataw_g : integer := 512;
    axis_tdestw_g : integer := 5;
    axi_addrw_g : integer := 5
  );
  port (
    clk       : in std_logic;
    rstx      : in std_logic;
    -- AXIS interface to profile
    S_AXIS_TREADY  : out std_logic;
    S_AXIS_TVALID  : in  std_logic;
    S_AXIS_TDATA   : in  std_logic_vector(axis_dataw_g-1 downto 0);
    S_AXIS_TDEST   : in  std_logic_vector(axis_tdestw_g-1 downto 0);
    -- Outgoing AXIS interface, not modifying the stream
    M_AXIS_TREADY  : in std_logic;
    M_AXIS_TVALID  : out  std_logic;
    M_AXIS_TDATA   : out  std_logic_vector(axis_dataw_g-1 downto 0);
    M_AXIS_TDEST   : out  std_logic_vector(axis_tdestw_g-1 downto 0);
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
end entity axis_stall_counter;

architecture rtl of axis_stall_counter is


  constant AXI_OKAY    : std_logic_vector(1 downto 0) := "00";
  constant AXI_SLVERR  : std_logic_vector(1 downto 0) := "10";

  constant REG_SUCCESFUL_LO : unsigned(2 downto 0)      := "000";
  constant REG_SUCCESFUL_HI : unsigned(2 downto 0)      := "001";
  constant REG_STALLED_TREADY_LO : unsigned(2 downto 0) := "010";
  constant REG_STALLED_TREADY_HI : unsigned(2 downto 0) := "011";
  constant REG_STALLED_TVALID_LO : unsigned(2 downto 0) := "100";
  constant REG_STALLED_TVALID_HI : unsigned(2 downto 0) := "101";

  type state_t is (S_READY, S_WRITE_DATA, S_READ_DATA, S_FINISH_WRITE, S_FINISH_READ);
  signal state   : state_t;

  -- Output registers
  signal s_axi_awready_r : std_logic;
  signal s_axi_wready_r  : std_logic;
  signal s_axi_bresp_r   : std_logic_vector(s_axi_bresp'range);
  signal s_axi_bvalid_r  : std_logic;
  signal s_axi_arready_r : std_logic;
  signal s_axi_rdata_r   : std_logic_vector(s_axi_rdata'range);
  signal s_axi_rresp_r   : std_logic_vector(s_axi_rresp'range);
  signal s_axi_rvalid_r  : std_logic;

  signal axi_addr_r   : unsigned(2 downto 0);

  signal succesful_transfer_count_r : unsigned(64-1 downto 0);
  signal stalled_tready_count_r     : unsigned(64-1 downto 0);
  signal stalled_tvalid_count_r     : unsigned(64-1 downto 0);
  -- Temporary registers to accumulate results which get added to actual
  -- counter only when succesful transfer happens
  signal tmp_stalled_tready_count_r : unsigned(64-1 downto 0);
  signal tmp_stalled_tvalid_count_r : unsigned(64-1 downto 0);
  signal first_transfer_done_r      : std_logic;
  signal reset_counters_r           : std_logic;

  signal tvalid_r : std_logic;
  signal tready_r : std_logic;

begin
    --bypass the stream as it is, we don't want to modify it while profiling
    M_AXIS_TVALID <= S_AXIS_TVALID;
    M_AXIS_TDATA  <= S_AXIS_TDATA;
    M_AXIS_TDEST  <= S_AXIS_TDEST;
    S_AXIS_TREADY <= M_AXIS_TREADY;

    -- The process handling the profiling
    axis_profile : process(clk, rstx)
    begin
        if rstx = '0' then
            succesful_transfer_count_r <= (others => '0');
            stalled_tready_count_r <= (others => '0');
            stalled_tvalid_count_r <= (others => '0');
            tvalid_r <= '0';
            tready_r <= '0';
            first_transfer_done_r <= '0';
            tmp_stalled_tready_count_r <= (others => '0');
            tmp_stalled_tvalid_count_r <= (others => '0');
        elsif rising_edge(clk) then
            --register these to isolate path from axi stream to 64bit profiling counters
            tvalid_r <= S_AXIS_TVALID;
            tready_r <= M_AXIS_TREADY;
            if reset_counters_r = '1' then
                succesful_transfer_count_r <= (others => '0');
                stalled_tready_count_r <= (others => '0');
                stalled_tvalid_count_r <= (others => '0');
                first_transfer_done_r <= '0';
                tmp_stalled_tready_count_r <= (others => '0');
                tmp_stalled_tvalid_count_r <= (others => '0');
            else
                -- increment the profiling counters
                -- we only count stalls in between valid transfers
                if tvalid_r = '1' and tready_r = '1' then
                    succesful_transfer_count_r <= succesful_transfer_count_r + 1;
                    first_transfer_done_r <= '1';
                    -- only accumulate the stall registers once a valid transfer happens.
                    -- this guards against counting the stall cycles after all valid transfers are done
                    stalled_tready_count_r <= stalled_tready_count_r + tmp_stalled_tready_count_r;
                    stalled_tvalid_count_r <= stalled_tvalid_count_r + tmp_stalled_tvalid_count_r;
                    -- reset the temporary counting registers
                    tmp_stalled_tready_count_r <= (others => '0');
                    tmp_stalled_tvalid_count_r <= (others => '0');
                -- first_transfer_done_r guards against not counting stall cycles before
                -- we have started real computation
                elsif tvalid_r = '1' and tready_r = '0' and first_transfer_done_r = '1' then
                    tmp_stalled_tready_count_r <= stalled_tready_count_r + 1;
                elsif tvalid_r = '0' and tready_r = '1' and first_transfer_done_r = '1' then
                    tmp_stalled_tvalid_count_r <= stalled_tvalid_count_r + 1;
                end if;
            end if;
        end if;
end process;

    -- Process for handling axi4 lite reads
    axi4lite_read : process(clk, rstx)
    begin
        if rstx = '0' then
            s_axi_awready_r <= '0';
            s_axi_wready_r  <= '0';
            s_axi_bresp_r   <= (others => '0');
            s_axi_bvalid_r  <= '0';
            s_axi_arready_r <= '0';
            s_axi_rdata_r   <= (others => '0');
            s_axi_rresp_r   <= (others => '0');
            s_axi_rvalid_r  <= '0';

            axi_addr_r          <= (others => '0');
            reset_counters_r    <= '0';
            state               <= S_READY;
        elsif rising_edge(clk) then
            if s_axi_arready_r = '1' and s_axi_arvalid = '1' then
                s_axi_arready_r <= '0';
            end if;
            if s_axi_awready_r = '1' and s_axi_awvalid = '1' then
                s_axi_awready_r <= '0';
            end if;
            s_axi_wready_r  <= '0';
            reset_counters_r <= '0';
            case state is
                when S_READY =>
                    if s_axi_awvalid = '1' then
                        s_axi_awready_r <= '1';
                        state         <= S_WRITE_DATA;
                    elsif s_axi_arvalid = '1' then
                        s_axi_arready_r <= '1';
                        axi_addr_r      <= unsigned(s_axi_araddr(4 downto 2));
                        state           <= S_READ_DATA;
                    end if;

                when S_WRITE_DATA =>
                    s_axi_wready_r <= '1';
                    if s_axi_wvalid = '1' and s_axi_wready_r = '1' then
                        s_axi_wready_r <= '0';
                        s_axi_bresp_r  <= AXI_OKAY;
                        s_axi_bvalid_r <= '1';
                        state        <= S_FINISH_WRITE;
                        reset_counters_r <= '1';
                    end if;

                when S_FINISH_WRITE =>
                    if s_axi_bready = '1' then
                        s_axi_bvalid_r <= '0';
                    end if;
                    if s_axi_bvalid_r = '0' then
                        state <= S_READY;
                    end if;

                when S_READ_DATA =>
                    if s_axi_rready = '1' or s_axi_rvalid_r = '0' then
                        s_axi_rvalid_r <= '1';
                        s_axi_rresp_r  <= AXI_OKAY;
                        case axi_addr_r is
                            when REG_SUCCESFUL_LO =>
                                s_axi_rdata_r <= std_logic_vector(succesful_transfer_count_r(31 downto 0));
                            when REG_SUCCESFUL_HI =>
                                s_axi_rdata_r <= std_logic_vector(succesful_transfer_count_r(63 downto 32));
                            when REG_STALLED_TREADY_LO =>
                                s_axi_rdata_r <= std_logic_vector(stalled_tready_count_r(31 downto 0));
                            when REG_STALLED_TREADY_HI =>
                                s_axi_rdata_r <= std_logic_vector(stalled_tready_count_r(63 downto 32));
                            when REG_STALLED_TVALID_LO =>
                                s_axi_rdata_r <= std_logic_vector(stalled_tvalid_count_r(31 downto 0));
                            when REG_STALLED_TVALID_HI =>
                                s_axi_rdata_r <= std_logic_vector(stalled_tvalid_count_r(63 downto 32));
                            when others =>
                                s_axi_rdata_r <= (others => '0');
                        end case;
                        state <= S_FINISH_READ;
                    end if;
                when S_FINISH_READ =>
                    if s_axi_rready = '1' and s_axi_rvalid_r = '1' then
                        s_axi_rvalid_r <= '0';
                        state          <= S_READY;
                    end if;
            end case;
        end if;
    end process;

    s_axi_awready  <= s_axi_awready_r;
    s_axi_wready   <= s_axi_wready_r;
    s_axi_bresp    <= s_axi_bresp_r;
    s_axi_bvalid   <= s_axi_bvalid_r;
    s_axi_arready  <= s_axi_arready_r;
    s_axi_rdata    <= s_axi_rdata_r;
    s_axi_rresp    <= s_axi_rresp_r;
    s_axi_rvalid   <= s_axi_rvalid_r;

end architecture rtl;

