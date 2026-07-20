library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port ( 
    i_clk   : in std_logic; 
    i_rst   : in std_logic; 
    i_start : in std_logic; 
    i_add   : in std_logic_vector(15 downto 0); 
    o_done  : out std_logic; 
    o_mem_addr : out std_logic_vector(15 downto 0); 
    i_mem_data : in std_logic_vector(7 downto 0); 
    o_mem_data : out std_logic_vector(7 downto 0); 
    o_mem_we   : out std_logic; 
    o_mem_en   : out std_logic 
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type states is(S0,S1,S2,S3,S4,S4_1,S5,S6,S6_1,S7,S8,S9,S10,S11,DONE);
    signal curr_state : states;
    -- header counter
    signal header_count : unsigned (4 downto 0);
    signal header_en : std_logic;
    signal header_end : std_logic;
    signal hc_plus : std_logic;
    -- K1 8 bit più significativi, K2 8 bit meno significativi.
    signal K1 : std_logic_vector(7 downto 0);
    signal K_start : unsigned (15 downto 0); 
    signal K : unsigned (15 downto 0);
    signal K_minus : std_logic;
    signal k_end : std_logic;
    signal S : std_logic_vector(7 downto 0);
    -- read address register
    signal ra_en : std_logic;  
    signal read_addr : std_logic_vector(15 downto 0);
    signal ra_plus : std_logic; 
    signal ra_lim : std_logic_vector(15 downto 0);
    signal ra_end : std_logic;
    -- write address register
    signal wa_en : std_logic;
    signal write_addr : std_logic_vector(15 downto 0);
    signal wa_plus : std_logic;
    -- segnale per mux o_mem_addr: 0 -> read; 1->write
    signal addr_mux_sel : std_logic;
    signal addr_mux_en : std_logic;
    -- array di coefficienti
    type coeff_array is array(0 to 6) of signed(7 downto 0);
    signal buffer_R : coeff_array;
    signal buffer_rst: std_logic ;
    signal buffer_en : std_logic;
    signal coeff_3 : coeff_array;
    signal coeff_5 : coeff_array;
    signal active_coeff : coeff_array;
    signal coeff_sel: std_logic;
    -- tmp per i calcoli
    signal sum : signed( 31 downto 0);
    signal sum_en : std_logic;
    signal res_norm : signed (31 downto 0);
    signal final_res : signed (7 downto 0); 
    -- contatore
    signal buffer_count : signed(15 downto 0);
    signal count_reset : std_logic;
    signal count_plus : std_logic;
    signal load_end : std_logic;
    signal norm_en : std_logic;
begin
    stateProcess : process(i_clk, i_rst) is
    --Sequenziale
    begin
        if i_rst = '1' then
            curr_state <= S0;
        elsif rising_edge(i_clk) then
            case curr_state is
                when S0 =>
                    curr_state  <= S1;
                when S1 =>
                    if i_start = '1' then
                        curr_state <= S2;
                    end if;
                when S2 =>
                    curr_state <= S3;
                when S3 =>
                    curr_state <= S4;
                when S4 =>
                    if header_end = '1' then
                        curr_state <= S4_1;
                    else 
                        curr_state <= S3;
                    end if;
                when S4_1 =>
                    curr_state <= S5;
                when S5 =>
                    if k_end = '1' then
                        curr_state <= DONE;
                    else
                        curr_state <= S6;
                    end if;
                when S6 =>
                    curr_state  <= S6_1;    
                when S6_1 =>
                    curr_state <= S7;              
                when S7 =>
                    if load_end = '1' then
                        curr_state <= S8;
                    else
                        curr_state <= S6;
                    end if;
                when S8 =>
                    curr_state <= S9;
                when S9 =>
                    curr_state <= S10;
                when S10 =>
                    curr_state <= S11;
                when S11 =>
                    curr_state <= S5;
                when DONE =>
                    if i_start = '1' then
                        curr_state <= DONE;
                     else
                        curr_state <= S1;
                        end if;
            end case;
        end if;
    end process;
    
    controllProcess : process(curr_state) is
    begin
        --valori di default
        ra_en  <= '0';
        ra_plus <= '0';
        wa_en <= '0';
        header_en <= '0';
        hc_plus <= '0';
        addr_mux_sel <= '0';
        addr_mux_en <= '0'; 
        o_done <= '0';
        o_mem_en <= '0';
        buffer_en  <= '0';
        buffer_rst <= '0';
        coeff_sel <= '0';  
        count_plus <= '0'; 
        sum_en <= '0';
        count_reset <= '0'; 
        norm_en  <= '0';   
        wa_plus <= '0';
        o_mem_we <= '0';
        K_minus <= '0';
        case curr_state is  
            when S0 =>
            when S1 =>
            when S2 =>
                ra_en <= '1';
                header_en <= '1';
                buffer_rst <= '1';
            when S3 =>
                addr_mux_en <='1';
                addr_mux_sel <= '0';
                o_mem_en <= '1';
            when S4 =>
                ra_plus <= '1';
                hc_plus <= '1';
            when S4_1 =>
                count_reset <= '1';
                coeff_sel <= '1';
                wa_en <= '1';
            when S5 =>              
            when S6 =>
                o_mem_en  <= '1';
                addr_mux_sel <= '0';
                addr_mux_en <= '1';
            when S6_1 =>   
                buffer_en <= '1';
            when S7 =>
                ra_plus <= '1';
                count_plus <= '1';      
            when S8 =>
                sum_en <= '1';
            when S9 =>
                norm_en  <= '1';
            when S10 =>
                addr_mux_en <= '1';
                addr_mux_sel <= '1';
                o_mem_we <= '1';
                o_mem_en <= '1';
            when S11 =>
                wa_plus <= '1';
                K_minus <= '1';
            when DONE =>
                o_done <= '1';
        end case;
    end process;
   --  read address register
   raProcess_Seq : process(i_rst, i_clk) is
   --sequenziale
   begin
        if i_rst = '1'then
            read_addr <= (others => '0');
        elsif rising_edge(i_clk ) then
            if ra_en = '1' then
                read_addr <= i_add;
            elsif ra_plus = '1' then
                read_addr <= std_logic_vector(unsigned(read_addr) + 1);
            end if;
        end if;
   end process;
   
   raProcess_Com : process(read_addr ) is
   begin
        ra_end <= '0';
        if read_addr > ra_lim then
            ra_end <= '1';
        end if;
   end process;
    
    -- write address register
    waProcess : process(i_rst, i_clk) is
    -- sequenziale
    begin
        if i_rst = '1' then
            write_addr <= (others=> '0');
        elsif rising_edge(i_clk) then
            if wa_en = '1' then
                write_addr <= std_logic_vector(unsigned(read_addr)+unsigned(K));
            elsif wa_plus = '1'then
                write_addr <= std_logic_vector(unsigned(write_addr)+ 1);
            end if;
        end if;
    end process;
    
    -- header counter
    hc_process_Seq : process(i_rst, i_clk) is
    --sequenziale
    begin
        if i_rst = '1' then
            header_count <= (others => '0');
        elsif rising_edge (i_clk ) then
            if header_en = '1' then
                header_count <= (others => '0');
            elsif hc_plus = '1' and header_count < 16 then
                header_count  <= (unsigned(header_count )+ 1);
            end if;
        end if;
    end process;
    
    hc_process_Com : process(header_count) is
    -- combinatorio
    begin
        header_end <= '0';
        if header_count = 16 then
            header_end <= '1';
        end if;
    end process;
    
    -- mux o_mem_addr
    memMux_process :process (addr_mux_en,addr_mux_sel,write_addr,read_addr) is
    begin
        o_mem_addr <= (others => '0');
        if addr_mux_en = '1'then
            if addr_mux_sel = '0' then
                o_mem_addr <= read_addr;
            elsif addr_mux_sel = '1' then
                o_mem_addr <= write_addr;
            end if;
        end if;
    end process;

    -- load header process
    loadHeaderProcess : process( i_rst, i_clk) is
    begin
        if i_rst = '1' then
            K_start <= (others => '0');
            K1 <= (others => '0');
            ra_lim <= (others => '0');
            S <= (others => '0');
            coeff_3 <= (others => (others => '0'));
            coeff_5 <= (others => (others => '0'));
        elsif rising_edge(i_clk) then
            if curr_state = S4 then 
                case to_integer(header_count) is
                    when 0 =>
                        K1 <= i_mem_data;
                    when 1 =>
                        K <= unsigned(K1) & unsigned(i_mem_data);
                        K_start <= unsigned(K1) & unsigned(i_mem_data);
                    when 2 =>
                        S <= i_mem_data;
                        ra_lim <= std_logic_vector(unsigned(i_add)+17+unsigned(K_start)-1);
                    when 3 to 9 =>
                        coeff_3(to_integer(header_count) - 3) <= signed(i_mem_data);
                    when 10 to 16 =>
                        coeff_5(to_integer(header_count) - 10) <= signed(i_mem_data);
                    when others =>
                        null;
                end case;
            elsif K_minus = '1' then
                K<= (unsigned (K)-1);
            end if;
        end if;
    end process;
    
    activeCoeffProcess : process (i_rst , i_clk ) is
    begin
        if i_rst = '1' then
            active_coeff <= (others=> (others => '0'));
        elsif rising_edge (i_clk ) then
            if coeff_sel = '1' then
                if S(0) = '1' then
                    active_coeff <= coeff_5;
                else
                    active_coeff <= coeff_3;
                end if;
            end if;
        end if;
    end process;
        
    count_process_seq : process(i_rst, i_clk ) is
    begin
        if i_rst = '1' then
            buffer_count <= to_signed(-1,buffer_count'length );
        elsif rising_edge(i_clk) then
            if count_reset = '1' then
                if S(0) = '0' then
                    buffer_count <= to_signed (-2,buffer_count'length ); 
                else
                    buffer_count <= to_signed (-3,buffer_count'length );
                end if;
            elsif count_plus = '1' and to_integer(buffer_count) <0 then
                buffer_count <= (signed(buffer_count) +1 );
            end if;
        end if;
    end process;
    
    count_process_com : process(buffer_count,write_addr) is
    begin
        load_end <= '0';
        if to_integer(buffer_count) >= 0 then
            load_end <= '1';
        end if;
    end process;
      
    buffer_process : process(i_rst, i_clk) is
    begin
        if i_rst = '1'then
            buffer_R <= (others => (others => '0'));
        elsif rising_edge(i_clk) then
            if buffer_rst = '1' then
                buffer_R <= (others => (others => '0'));
            elsif buffer_en = '1' then
                if ra_end = '1' then
                    buffer_R(0) <= buffer_R(1);
                    buffer_R(1) <= buffer_R(2);
                    buffer_R(2) <= buffer_R(3);
                    buffer_R(3) <= buffer_R(4);
                    buffer_R(4) <= buffer_R(5);
                    buffer_R(5) <= buffer_R(6);
                    buffer_R(6) <= to_signed(0,buffer_R(6)'length ) ;
                else
                    buffer_R(0) <= buffer_R(1);
                    buffer_R(1) <= buffer_R(2);
                    buffer_R(2) <= buffer_R(3);
                    buffer_R(3) <= buffer_R(4);
                    buffer_R(4) <= buffer_R(5);
                    buffer_R(5) <= buffer_R(6);
                    buffer_R(6) <= signed (i_mem_data ) ;
                end if;
            end if;          
        end if;
    end process;
   
    sum_process : process(i_rst,i_clk) is
    begin
        if i_rst = '1'then
            sum <= (others => '0');
        elsif rising_edge (i_clk ) then
            if sum_en = '1' then
                if S(0) = '0' then
                    sum <=  resize(buffer_R(2) * active_coeff(1), sum'length) +
                            resize(buffer_R(3) * active_coeff(2), sum'length) +
                            resize(buffer_R(4) * active_coeff(3), sum'length) +
                            resize(buffer_R(5) * active_coeff(4), sum'length) +
                            resize(buffer_R(6) * active_coeff(5), sum'length);
                else
                    sum <=  resize(buffer_R(0) * active_coeff(0), sum'length) +
                            resize(buffer_R(1) * active_coeff(1), sum'length) +
                            resize(buffer_R(2) * active_coeff(2), sum'length) +
                            resize(buffer_R(3) * active_coeff(3), sum'length) +
                            resize(buffer_R(4) * active_coeff(4), sum'length) +
                            resize(buffer_R(5) * active_coeff(5), sum'length) +
                            resize(buffer_R(6) * active_coeff(6), sum'length);
                end if;
            end if;
        end if;
    end process;
    
    res_norm_process_seq : process(i_rst, i_clk) is
    begin
        if i_rst = '1'then
            res_norm <= (others => '0');
        elsif rising_edge (i_clk) then
            if norm_en = '1' then
                if S(0) = '0' then
                    if to_integer (sum) < 0 then
                        res_norm <= (shift_right(sum,4) + to_signed(1, 8)) +
                                    (shift_right(sum,6) + to_signed(1, 8)) +
                                    (shift_right(sum,8) + to_signed(1, 8)) +
                                    (shift_right(sum,10) + to_signed(1, 8));
                    else 
                        res_norm <= (shift_right(sum,4)) +
                                    (shift_right(sum,6)) +
                                    (shift_right(sum,8)) +
                                    (shift_right(sum,10));
                    end if;
                else
                    if to_integer (sum) < 0 then
                        res_norm <= (shift_right(sum,6) + to_signed(1, 8)) +
                                    (shift_right(sum,10) + to_signed(1, 8));
                    else 
                        res_norm <= (shift_right(sum,6)) +
                                    (shift_right(sum,10));
                     end if;
                end if;
            end if;
        end if;
    end process;
    
    res_normProcess_com : process (res_norm) is
    begin
        final_res <= resize(res_norm,8);
        if res_norm < to_signed(-128,8) then
            final_res <= to_signed(-128, 8);
        elsif res_norm > to_signed(127, 8) then
            final_res <= to_signed(127, 8);
        end if;
    end process;
    o_mem_data <= std_logic_vector(final_res);
    
    k_process_com : process(K, S)
    begin
        k_end <= '0';
        if to_integer(K) = 0 then
            k_end <= '1';
        end if;
    end process;
end Behavioral;