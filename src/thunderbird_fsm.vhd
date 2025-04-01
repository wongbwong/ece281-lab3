--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 
--|                  ON    | 
--|                  R1    | 
--|                  R2    | 
--|                  R3    | 
--|                  L1    | 
--|                  L2    | 
--|                  L3    | 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------

-----------------------
--| One-Hot State Encoding key
--| --------------------
--| State | Encoding
--| --------------------
--| OFF   | 10000000
--| ON    | 01000000
--| R1    | 00100000
--| R2    | 00010000
--| R3    | 00001000
--| L1    | 00000100
--| L2    | 00000010
--| L3    | 00000001
--| --------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

    type state_type is (ST_OFF, ST_ON, ST_R1, ST_R2, ST_R3, ST_L1, ST_L2, ST_L3);
    signal current_state, next_state : state_type;

    signal l_wire : std_logic_vector(2 downto 0);
    signal r_wire : std_logic_vector(2 downto 0);

begin


    process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            current_state <= ST_OFF;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;



    process (current_state, i_left, i_right)
    begin
        case current_state is
            when ST_OFF =>
                if i_left = '1' and i_right = '0' then
                    next_state <= ST_L1;
                elsif i_right = '1' and i_left = '0' then
                    next_state <= ST_R1;
                elsif i_left = '1' and i_right = '1' then
                    next_state <= ST_ON;
                else
                    next_state <= ST_OFF;
                end if;

            when ST_ON =>
                next_state <= ST_OFF;

            when ST_R1 =>
                next_state <= ST_R2;

            when ST_R2 =>
                next_state <= ST_R3;

            when ST_R3 =>
                next_state <= ST_OFF;

            when ST_L1 =>
                next_state <= ST_L2;

            when ST_L2 =>
                next_state <= ST_L3;

            when ST_L3 =>
                next_state <= ST_OFF;

            when others =>
                next_state <= ST_OFF;
        end case;
    end process;


    process (current_state)
    begin

        l_wire <= "000";
        r_wire <= "000";

        case current_state is
            when ST_OFF =>
                l_wire <= "000";
                r_wire <= "000";

            when ST_ON =>
                l_wire <= "111";
                r_wire <= "111";

            when ST_R1 =>
                r_wire <= "001";

            when ST_R2 =>
                r_wire <= "011";

            when ST_R3 =>
                r_wire <= "111";

            when ST_L1 =>
                l_wire <= "001";

            when ST_L2 =>
                l_wire <= "011";

            when ST_L3 =>
                l_wire <= "111";

            when others =>
                l_wire <= "000";
                r_wire <= "000";
        end case;
    end process;



    o_lights_L <= l_wire;
    o_lights_R <= r_wire;

end thunderbird_fsm_arch;