--
-- AXI Stream framer. Part of libaxis
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

library libaxis_1;

entity axis_framer is
  
  generic (
    type data_type;
    type header_type;
    function index(d : header_type; idx : integer) return data_type;
    function len(d : header_type) return integer);
  port (
    clk      : in  std_ulogic;
    rst      : in  std_ulogic;
    header   : in  header_type;
    s_tdata  : in  data_type;
    s_tvalid : in  std_ulogic;
    s_tlast  : in  std_ulogic;
    s_tready : out std_ulogic;
    m_tdata  : out data_type;
    m_tvalid : out std_ulogic;
    m_tlast  : out std_ulogic;
    m_tready : in  std_ulogic);

end entity axis_framer;

architecture rtl of axis_framer is
  type t_state is (S_IDLE, S_HEADER, S_DATA);
  signal state : t_state;

  signal idx : integer range 0 to len(header);

  signal data_last   : std_ulogic;
  signal header_last : std_ulogic;
begin
  m_tdata <= s_tdata when (state = S_DATA) else index(header, idx);
  m_tvalid <= s_tvalid;
  m_tlast  <= s_tlast when (state = S_DATA) else '0';

  s_tready <= m_tready when (state = S_DATA) else '0';

  header_last <= m_tvalid and m_tready when (idx = len(header)-1) else '0';
  data_last   <= m_tvalid and m_tready and m_tlast;
  p_main : process(clk)
  begin
    if rising_edge(clk) then
      case state is
        when S_IDLE =>
          if s_tvalid then
            state <= S_HEADER;
          end if;
        when S_HEADER =>
          if header_last then
            state <= S_DATA;
          end if;
        when S_DATA =>
          if data_last then
            state <= S_IDLE;
          end if;
        when others => state <= S_IDLE;
      end case;

      if m_tvalid and m_tready then
        idx <= 0 when (header_last or data_last) else idx + 1;
      end if;

      if rst then
        state <= S_IDLE;
      end if;
    end if;
  end process;

end architecture;
