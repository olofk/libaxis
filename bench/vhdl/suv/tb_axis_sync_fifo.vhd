--
-- Test bench for AXI Stream synchronous FIFO. Part of libaxis
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
library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

library osvvm;
use osvvm.RandomPkg.RandomPType;

library libstorage_1;
use libstorage_1.libstorage_pkg.all;

library libaxis_1;
use libaxis_1.axis_bfm.all;

entity tb_axis_sync_fifo is

  generic (
    DEPTH    : positive := 32;
    TRANSACTIONS : positive := 100000);

end entity tb_axis_sync_fifo;

architecture tb of tb_axis_sync_fifo is

  constant WIDTH : positive := 16;
  subtype data_type is std_ulogic_vector(WIDTH-1 downto 0);

  signal clk : std_ulogic := '1';
  signal rst : std_ulogic := '1';

  signal s_tdata  : data_type;
  signal s_tvalid : std_ulogic := '0';
  signal s_tready : std_ulogic;
  signal m_tdata  : data_type;
  signal m_tvalid : std_ulogic;
  signal m_tready : std_ulogic := '0';

  shared variable words : t_mem(0 to TRANSACTIONS-1)(WIDTH-1 downto 0);
begin

  clk <= not clk after 5 ns;
  rst <= '0' after 20 ns;

  i_dut : entity libaxis_1.axis_sync_fifo
    generic map (
      DEPTH    => DEPTH)
    port map (
      clk      => clk,
      rst      => rst,
      s_tdata  => s_tdata,
      s_tvalid => s_tvalid,
      s_tready => s_tready,
      m_tdata  => m_tdata,
      m_tvalid => m_tvalid,
      m_tready => m_tready);

  p_send :process 
    variable RV : RandomPType ; 
  begin
    RV.InitSeed(RV'instance_name);
    wait until falling_edge(rst);

    for idx in 0 to TRANSACTIONS-1 loop
      words(idx) := RV.RandSlv(WIDTH);
      send_word(clk,
                s_tdata,
                s_tvalid,
                s_tready,
                words(idx),
                0.5);
    end loop;
    wait;
  end process;

  p_receive : process
    variable len : positive;
    variable rec : data_type;
    variable exp : data_type;
  begin
    for idx in 0 to TRANSACTIONS-1 loop
      recv_word(clk,
                m_tdata,
                m_tvalid,
                m_tready,
                rec,
                0.5);
      exp := words(idx);
      assert exp = rec report "Mismatch in data" severity failure;
    end loop;
    stop;
  end process;

end architecture tb;
