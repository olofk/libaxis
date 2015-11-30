--
-- AXI Stream packet FIFO. Part of libaxis
--
-- Copyright (C) 2015  Olof Kindgren <olof.kindgren@gmail.com>
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--

-- TODO: Handle packets larger than FIFO size

library ieee;
use ieee.std_logic_1164.all;

library libaxis_1;

entity axis_packet_fifo is
  generic (
    type data_type;
    DEPTH        : positive;
    MAX_PACKETS  : positive);
  port (
    clk      : in  std_ulogic;
    rst      : in  std_ulogic;
    pkt_size : out integer;
    s_tdata  : in  data_type;
    s_tvalid : in  std_ulogic;
    s_tlast  : in  std_ulogic;
    s_tready : out std_ulogic;
    m_tdata  : out data_type;
    m_tvalid : out std_ulogic;
    m_tlast  : out std_ulogic;
    m_tready : in  std_ulogic);

end entity axis_packet_fifo;

architecture rtl of axis_packet_fifo is

  subtype t_cnt is integer range 0 to DEPTH;
  
  signal m_cnt_tdata  : t_cnt;
  signal m_cnt_tvalid : std_ulogic;
  signal m_cnt_tready : std_ulogic;

  signal s_cnt_tdata  : t_cnt;
  signal s_cnt_tvalid : std_ulogic;
  signal s_cnt_tready : std_ulogic;

  signal m_data_tvalid : std_ulogic;
  signal m_data_tready : std_ulogic;

  signal s_data_tvalid : std_ulogic;
  signal s_data_tready : std_ulogic;

  signal cnt_out : t_cnt;
begin

  s_tready <= s_cnt_tready and s_data_tready;

  s_data_tvalid <= s_tvalid and s_cnt_tready;

  s_cnt_tvalid <= s_tvalid and s_data_tready and s_tlast;

  m_tvalid <= m_cnt_tvalid;

  m_data_tready <= m_tready and m_cnt_tvalid;

  m_cnt_tready <= m_tready and m_tlast;

  pkt_size <= m_cnt_tdata;
  m_tlast <= '1' when (cnt_out = m_cnt_tdata-1) else '0';

  p_main: process (clk) is
  begin
    if rising_edge(clk) then
      if s_tvalid and s_tready then
        s_cnt_tdata <= 1 when s_tlast else s_cnt_tdata + 1;
      end if;

      if m_data_tvalid and m_data_tready then
        cnt_out <= 0 when (m_tlast = '1') else cnt_out + 1;
      end if;
      if rst then
        s_cnt_tdata <= 1;
      end if;
    end if;
  end process;

  size_fifo : entity libaxis_1.axis_sync_fifo
    generic map (
      data_type => t_cnt,
      DEPTH     => MAX_PACKETS)
    port map (
      clk      => clk,
      rst      => rst,
      s_tdata  => s_cnt_tdata,
      s_tvalid => s_cnt_tvalid,
      s_tready => s_cnt_tready,
      m_tdata  => m_cnt_tdata,
      m_tvalid => m_cnt_tvalid,
      m_tready => m_cnt_tready);

  data_fifo : entity libaxis_1.axis_sync_fifo
    generic map (
      data_type => data_type,
      DEPTH     => DEPTH)
    port map (
      clk      => clk,
      rst      => rst,
      s_tdata  => s_tdata,
      s_tvalid => s_data_tvalid,
      s_tready => s_data_tready,
      m_tdata  => m_tdata,
      m_tvalid => m_data_tvalid,
      m_tready => m_data_tready);
end architecture rtl;
