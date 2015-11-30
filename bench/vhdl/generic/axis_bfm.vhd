--
-- AXI Stream Bus Functional Model. Part of libaxis
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
use ieee.math_real.all;

package axis_bfm is
  generic (
    type data_type);

  type t_tdata_arr is array(natural range <>) of data_type;
  
  procedure send_word (
    --External interface
    signal clk      : in  std_ulogic;
    signal tdata_o  : out data_type;
    signal tvalid_o : out std_ulogic;
    signal tready_i : in  std_ulogic;
    --Configuration parameters
    word_i          : in  data_type;
    rate_i          : in  real);

  procedure send_packet (
    signal clk      : in  std_ulogic;
    signal tdata_o  : out data_type;
    signal tlast_o  : out std_ulogic;
    signal tvalid_o : out std_ulogic;
    signal tready_i : in  std_ulogic;
    buf : in t_tdata_arr;
    rate : in real);

  procedure recv_word (
    --External interface
    signal clk      : in  std_ulogic;
    signal tdata_i  : in  data_type;
    signal tvalid_i : in  std_ulogic;
    signal tready_o : out std_ulogic;
    --Configuration parameters
    word_o          : out data_type;
    rate_i          : in  real);

  procedure recv_packet (
    signal clk      : in  std_ulogic;
    signal tdata_i  : in  data_type;
    signal tlast_i  : in  std_ulogic;
    signal tvalid_i : in  std_ulogic;
    signal tready_o : out std_ulogic;
    buf : out t_tdata_arr;
    n   : out natural;
    rate : in real);
end package axis_bfm;

package body axis_bfm is

  shared variable seed1 : integer := 16#dead#;
  shared variable seed2 : integer := 16#beef#;

  procedure send_word (
    --External interface
    signal clk      : in  std_ulogic;
    signal tdata_o  : out data_type;
    signal tvalid_o : out std_ulogic;
    signal tready_i : in  std_ulogic;
    --Configuration parameters
    word_i          : in  data_type;
    rate_i          : in  real) is
    variable rnd : real;
  begin
    tvalid_o <= '0';

    -- rate_i sets the probability that tvalid_o assertion is delayed
    loop
      uniform(seed1, seed2, rnd);
      exit when rnd < rate_i;
      wait until rising_edge(clk);
    end loop;

    --Set outputs
    tdata_o  <= word_i;
    tvalid_o <= '1';

    --Wait for tready_i
    loop
      wait until rising_edge(clk);
      exit when tready_i = '1';
    end loop;

    --Lower tvalid_o after completion
    tvalid_o <= '0';
  end procedure;

  procedure send_packet (
    signal clk      : in  std_ulogic;
    signal tdata_o  : out data_type;
    signal tlast_o  : out std_ulogic;
    signal tvalid_o : out std_ulogic;
    signal tready_i : in  std_ulogic;
    buf : in t_tdata_arr;
    rate : in real) is
    variable idx : integer;
    variable last : boolean;
  begin
    for idx in buf'range loop
      tlast_o <= '1' when (idx = buf'high) else '0';
      send_word(clk, tdata_o, tvalid_o, tready_i, buf(idx), rate);
    end loop;
  end procedure;

  procedure recv_word (
    --External interface
    signal clk      : in  std_ulogic;
    signal tdata_i  : in  data_type;
    signal tvalid_i : in  std_ulogic;
    signal tready_o : out std_ulogic;
    --Configuration parameters
    word_o          : out data_type;
    rate_i          : in  real
    ) is
    variable rnd : real;
    variable rdy : boolean;
  begin
    tready_o <= '0';

    loop
      uniform(seed1, seed2, rnd);
      rdy := rdy or (rnd < rate_i);
      if rdy then
        tready_o <= '1';
      end if;
      wait until rising_edge(clk);
      exit when rdy and (tvalid_i = '1');
    end loop;
    word_o := tdata_i;
    tready_o <= '0';
  end procedure;

  procedure recv_packet (
    signal clk      : in  std_ulogic;
    signal tdata_i  : in  data_type;
    signal tlast_i  : in  std_ulogic;
    signal tvalid_i : in  std_ulogic;
    signal tready_o : out std_ulogic;
    buf : out t_tdata_arr;
    n   : out natural;
    rate : in real) is
    variable idx  : integer;
    variable word : data_type;
  begin
    for idx in buf'range loop
      recv_word(clk, tdata_i, tvalid_i, tready_o, word, rate);
      buf(idx) := word;
      if tlast_i = '1' then
        n := idx+1;
        exit;
      end if;
    end loop;
  end procedure;

end package body axis_bfm;
