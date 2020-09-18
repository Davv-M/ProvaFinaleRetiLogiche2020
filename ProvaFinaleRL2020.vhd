--Prova finale di Reti Logiche
--Prof. Fabio Salice, A.A. 2019/20
--Davide Mantegazza

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk: in std_logic;
        i_start: in std_logic;
        i_rst: in std_logic;
        i_data: in std_logic_vector(7 downto 0);
        o_address: out std_logic_vector(15 downto 0);
        o_done: out std_logic;
        o_en: out std_logic;
        o_we: out std_logic;
        o_data: out std_logic_vector(7 downto 0)
    );
end entity project_reti_logiche;

architecture behavioral of project_reti_logiche is
    type state_type is (IDLE, INPUT_ADDRESS_FETCHING, INPUT_ADDRESS_WAIT_FOR_RAM, SAVE_INPUT_ADDRESS, WZ_FETCHING, WZ_WAIT_FOR_RAM, SAVE_WZ, WZ_CHECK, CONVERT_OFFSET, PREPARE_MODIFIED_OUTPUT_ADDDRESS, WRITE_UNMODIFIED_OUTPUT_ADDRESS, WRITE_MODIFIED_OUTPUT_ADDRESS, DONE);
    signal current_state: state_type;
    begin
        mainProcess: process (i_clk, i_rst)
        constant MEM_ADDR_OF_INPUT: unsigned := "0000000000001000";
        constant MEM_ADDR_OF_OUTPUT: unsigned := "0000000000001001";
        variable address_to_convert, current_wz, wz_offset: unsigned(7 downto 0);
        variable address_saved, wz_saved: boolean;
        variable wz_address: std_logic_vector(15 downto 0);
        variable wz_num: std_logic_vector(3 downto 0):= "0000";
        variable wz_offset_onehot: std_logic_vector(3 downto 0);
        variable final_address: std_logic_vector(7 downto 0);
        begin
            if (i_rst = '1') then
                o_en <= '0';
                o_we <= '0';
                address_to_convert := "00000000";
                current_wz := "00000000";
                address_saved := false;
                wz_saved := false;
                wz_address := "0000000000000000";
                wz_num := "0000";
                wz_offset := "00000000";
                wz_offset_onehot := "0000";
                final_address := "00000000";
                current_state <= IDLE;
            elsif(rising_edge(i_clk)) then
                case current_state is
                    when IDLE =>
                      if (i_start = '1') then
                          current_state <= INPUT_ADDRESS_FETCHING;
                      end if;
                    
                    when INPUT_ADDRESS_FETCHING =>
                      o_en <= '1';
                      o_we <= '0';
                      if (not address_saved) then
                          o_address <= std_logic_vector(MEM_ADDR_OF_INPUT);
                      end if;
                      current_state <= INPUT_ADDRESS_WAIT_FOR_RAM;
                      
                    when INPUT_ADDRESS_WAIT_FOR_RAM =>
                      if (address_saved) then
                          current_state <= WZ_FETCHING;
                      else
                          current_state <= SAVE_INPUT_ADDRESS;
                      end if;
                      
                    when SAVE_INPUT_ADDRESS =>
                      if (not address_saved) then
                          address_to_convert := unsigned(i_data);
                          address_saved := true;
                          current_state <= INPUT_ADDRESS_WAIT_FOR_RAM;
                      else
                          current_state <= WZ_FETCHING;
                      end if;
                        
                    when WZ_FETCHING =>
                      o_en <= '1';
                      o_we <= '0';
                      if(not wz_saved) then
                        o_address <= std_logic_vector("000000000000" & unsigned(wz_num));
                      end if;
                      current_state <= WZ_WAIT_FOR_RAM;
                      
                    when WZ_WAIT_FOR_RAM =>
                      if(wz_saved) then
                        current_state <= WZ_CHECK;
                      elsif(not wz_saved) then
                        current_state <= SAVE_WZ;
                      end if;
                      
                    when SAVE_WZ =>
                      if(not wz_saved) then
                        current_wz := unsigned(i_data);
                        wz_saved := true;
                        current_state <= WZ_WAIT_FOR_RAM;
                       else
                        current_state <= WZ_CHECK;
                       end if;
                       
                     when WZ_CHECK =>
                       if (wz_num <= "111") then
                        wz_offset := address_to_convert - current_wz;
                        if (wz_offset < "00000100") then
                         current_state <= CONVERT_OFFSET;
                        else
                         wz_num := std_logic_vector(unsigned(wz_num)+1);
                         wz_saved := false;
                         current_state <= WZ_FETCHING;
                        end if ;
                       else
                        current_state <= WRITE_UNMODIFIED_OUTPUT_ADDRESS;
                       end if;
                                         
                    when WRITE_UNMODIFIED_OUTPUT_ADDRESS =>
                      o_en <= '1';
                      o_we <= '1';
                      o_address <= "0000000000001001";
                      o_data <= std_logic_vector(unsigned(address_to_convert));
                      o_done <= '1';
                      current_state <= DONE;
                      
                    when CONVERT_OFFSET =>
                      case wz_offset is
                        when "00000000" =>
                          wz_offset_onehot := "0001";
                        when "00000001" =>
                          wz_offset_onehot := "0010";
                        when "00000010" =>
                          wz_offset_onehot := "0100";
                        when "00000011" =>
                          wz_offset_onehot := "1000";
                        when others =>
                          wz_offset_onehot := "0000";
                      end case;
                      current_state <= PREPARE_MODIFIED_OUTPUT_ADDDRESS;
                      
                    when PREPARE_MODIFIED_OUTPUT_ADDDRESS =>
                      wz_num(3):= '1';
                      final_address := wz_num & wz_offset_onehot;
                      current_state <= WRITE_MODIFIED_OUTPUT_ADDRESS;
                      
                    when WRITE_MODIFIED_OUTPUT_ADDRESS =>
                      o_en <= '1';
                      o_we <= '1';
                      o_address <= "0000000000001001";
                      o_data <= final_address;
                      o_done <= '1';
                      current_state <= DONE;
                      
                    when DONE =>
                      if (i_start = '0') then
                          o_done <= '0';
                          address_to_convert := "00000000";
                          current_wz := "00000000";
                          address_saved := false;
                          wz_saved := false;
                          wz_address := "0000000000000000";
                          wz_num := "0000";
                          wz_offset := "00000000";
                          wz_offset_onehot := "0000";
                          final_address := "00000000";
                          current_state <= IDLE;
                      end if;
                end case;
            end if;    
        end process;
end architecture behavioral;