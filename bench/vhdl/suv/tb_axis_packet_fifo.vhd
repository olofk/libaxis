--
-- Test bench for AXI Stream packet FIFO. Part of libaxis
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

-- TODO: Add coverage points
library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

library osvvm;
use osvvm.RandomPkg.RandomPType;

library libstorage_1;
use libstorage_1.libstorage_pkg.all;

library libaxis_1;

entity tb_axis_packet_fifo is

  generic (
    DEPTH    : positive := 32;
    TRANSACTIONS : positive := 500);

end entity tb_axis_packet_fifo;

architecture tb of tb_axis_packet_fifo is

  constant WIDTH : positive := 16;
  constant MAX_PKT_LEN : positive := 10;
  subtype data_type is std_ulogic_vector(WIDTH-1 downto 0);

  package bfm is new libaxis_1.axis_bfm;

  signal clk : std_ulogic := '1';
  signal rst : std_ulogic := '1';

  signal s_tdata  : data_type;
  signal s_tlast  : std_ulogic := '0';
  signal s_tvalid : std_ulogic := '0';
  signal s_tready : std_ulogic;
  signal pkt_size : integer;
  signal m_tdata  : data_type;
  signal m_tlast  : std_ulogic;
  signal m_tvalid : std_ulogic;
  signal m_tready : std_ulogic := '0';

  type t_packet is record
    buf : t_mem(0 to MAX_PKT_LEN-1)(WIDTH-1 downto 0);
    len : positive;
  end record t_packet;

  type t_packets is array (natural range <>) of t_packet;

  shared variable packets : t_packets(0 to TRANSACTIONS-1);
begin

  clk <= not clk after 5 ns;
  rst <= '0' after 20 ns;

  i_dut : entity libaxis_1.axis_packet_fifo
    generic map (
      DEPTH    => DEPTH,
      MAX_PACKETS => 4)                 --FIXME
    port map (
      clk      => clk,
      rst      => rst,
      s_tdata  => s_tdata,
      s_tlast  => s_tlast,
      s_tvalid => s_tvalid,
      s_tready => s_tready,
      pkt_size => pkt_size,
      m_tdata  => m_tdata,
      m_tlast  => m_tlast,
      m_tvalid => m_tvalid,
      m_tready => m_tready);

  p_send :process 
    variable RV : RandomPType;
    variable n : positive;
  begin
    RV.InitSeed(RV'instance_name);
    for idx in 0 to TRANSACTIONS-1 loop
      n := RV.RandInt(1, MAX_PKT_LEN);
      packets(idx).len := n;
      for widx in 0 to n-1 loop
        packets(idx).buf(widx) := RV.RandSlv(WIDTH);
      end loop;
    end loop;

    wait until falling_edge(rst);


    for idx in 0 to TRANSACTIONS-1 loop
      bfm.send_packet(clk,
                      s_tdata,
                      s_tlast,
                      s_tvalid,
                      s_tready,
                      packets(idx).buf(0 to packets(idx).len-1),
                      0.9);
    end loop;
    wait;
  end process;

  p_receive : process
    variable len : positive;
    variable rec : t_packet;
    variable exp : t_packet;
  begin
    wait until falling_edge(rst);
    for idx in 0 to TRANSACTIONS-1 loop
      bfm.recv_packet(clk,
                      m_tdata,
                      m_tlast,
                      m_tvalid,
                      m_tready,
                      rec.buf,
                      rec.len,
                      0.5);
      exp := packets(idx);
      assert exp.len = rec.len report "Mismatch in packet length" severity failure;
      for w in 0 to rec.len-1 loop
        assert exp.buf(w) = rec.buf(w) report "Data mismatch" severity failure;
      end loop;
    end loop;
    report "All tests passed" severity note;
    stop;
  end process;

  p_monitor : process
    variable is_active : boolean;
    variable size : integer;
  begin
    wait until rising_edge(clk);
    if is_active then
      assert m_tvalid = '1' report "tvalid was deasserted during packet read" severity error;
      assert size = pkt_size report "pkt_size changed during packet readout" severity error;
      if m_tlast and m_tready then
        is_active := false;
      end if;
    else
      if m_tvalid then
        is_active := true;
        size := pkt_size;
      end if;
    end if;
  end process;
end architecture tb;
