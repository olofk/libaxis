--
-- AXI Stream synchronous FIFO. Part of libaxis
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
library ieee;
use ieee.std_logic_1164.all;

library libstorage_1;

entity axis_sync_fifo is
  generic (
    DEPTH : positive);
  port (
    clk      : in  std_ulogic;
    rst      : in  std_ulogic;
    s_tdata  : in  std_ulogic_vector;
    s_tvalid : in  std_ulogic;
    s_tready : out std_ulogic;
    m_tdata  : out std_ulogic_vector;
    m_tvalid : out std_ulogic;
    m_tready : in  std_ulogic);
end entity axis_sync_fifo;

architecture str of axis_sync_fifo is

  signal wr_en : std_ulogic;
  signal rd_en : std_ulogic;
  signal full  : std_ulogic;
  signal empty : std_ulogic;
begin

  wr_en    <= not full and s_tvalid;
  s_tready <= not full;

  m_tvalid <= not empty;
  rd_en    <= not empty and m_tready;

  fifo : entity libstorage_1.fifo_fwft_generic
    generic map (
      DEPTH => DEPTH,
      FWFT  => true)
    port map (
      clk       => clk,
      rst       => rst,
      wr_data_i => s_tdata,
      wr_en_i   => wr_en,
      full_o    => full,
      rd_data_o => m_tdata,
      empty_o   => empty,
      rd_en_i   => rd_en);

end architecture str;
