----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:26:46 03/30/2017 
-- Design Name: 
-- Module Name:    multiplier - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multiplier_organised is
    Port ( x : in  STD_LOGIC_VECTOR (31 downto 0);
           y : in  STD_LOGIC_VECTOR (31 downto 0);
           z : out  STD_LOGIC_VECTOR (31 downto 0));
end multiplier_organised;

architecture Behavioral of multiplier_organised is

begin
	process(x,y)
		variable x_mantissa : STD_LOGIC_VECTOR (23 downto 0);
		variable x_exponent : STD_LOGIC_VECTOR (8 downto 0);
		variable x_sign : STD_LOGIC;
		variable y_mantissa : STD_LOGIC_VECTOR (23 downto 0);
		variable y_exponent : STD_LOGIC_VECTOR (8 downto 0);
		variable y_sign : STD_LOGIC;
		variable z_mantissa : STD_LOGIC_VECTOR (22 downto 0);
		variable z_exponent : STD_LOGIC_VECTOR (7 downto 0);
		variable z_sign : STD_LOGIC;
		variable sum_exponent : STD_LOGIC_VECTOR (8 downto 0);
		variable carry : STD_LOGIC:='0';
		variable carry1 : STD_LOGIC:='0';
		variable temp1: STD_LOGIC_VECTOR (8 downto 0) ;
		variable temp : STD_LOGIC_VECTOR (8 downto 0) ;
		variable temp_multiply : STD_LOGIC_VECTOR (47 downto 0) ;
		variable multiply_store : STD_LOGIC_VECTOR (47 downto 0) ;
		variable multiply_store_temp : STD_LOGIC_VECTOR (47 downto 0) ;
		variable multiply_rounder : STD_LOGIC_VECTOR (22 downto 0);
	begin
		x_mantissa(22 downto 0) := x(22 downto 0);
		x_mantissa(23):='0'; --Extra bit will be used later for multiplication
		x_exponent(7 downto 0) := x(30 downto 23);
		x_exponent(8) := '0'; --Extra bit will be used later for addition
		x_sign := x(31);
		
		y_mantissa(22 downto 0) := y(22 downto 0);
		y_mantissa(23):='0'; --Extra bit will be used later for multiplication
		y_exponent(7 downto 0) := y(30 downto 23);
		y_exponent(8) := '0'; --Extra bit will be used later for addition
		y_sign := y(31);
		
		if (x_exponent=255 or y_exponent=255) then --case when infinity*x or x*infinity
			z_exponent := "11111111";
			z_mantissa := (others => '0');
			z_sign := x_sign xor y_sign;
			
		elsif (x_exponent=0 or y_exponent=0) then --case when 0*x or x*0
			z_exponent := (others => '0');
			z_mantissa := (others => '0');
			z_sign := '0';
		else
			temp := "001111111" ; --value of temp assigned to 127
			temp1 := "000000001"; --value of temp assigned to 1
			temp_multiply := (others =>'0'); --making temp_multiply initially zero
			multiply_store := (others => '0'); --making multiply_store initially zero
			multiply_store_temp := (others => '0') ; ---making multiply_store_temp initially zero
			
			multiply_rounder := (others => '0');
			multiply_rounder(0) := '1'; --Making multiply_rounder eqaul to 1
			
			--Adding 1 as MSB to each mantissa for multiplication
			x_mantissa(23) := '1';
			y_mantissa(23) := '1';
			
			--Multiplying mantissas by adding and shifting
			for J in 0 to 23 loop
				temp_multiply := (others => '0'); --Making temp_multiply zero after each iteration
				if(y_mantissa(J)='1') then
					--In x_mantissa*y_mantissa assigning temp_multiply equal to x_mantissa
					--and shifting relevantly
					temp_multiply(23+J downto J) := x_mantissa;
				end if;
				
				--Multiplied value is stored in multiply_store
				multiply_store_temp := multiply_store;--multiply_store_temp values is equaled to multiply_store for full adder operation
				
				--48 bit Full adder
				for I in 0 to 47 loop
					multiply_store(I) := multiply_store_temp(I) xor temp_multiply(I) xor carry;
					carry  := ( multiply_store_temp(I) and temp_multiply(I) ) or ( multiply_store_temp(I) and carry ) or ( temp_multiply(I) and carry );
				end loop;
			end loop;
			
			carry := '0' ; --Reassigning to zero
			carry1 := '0'; --Reassigning to zero
			
			--Simply Adding x_exponent and y_exponent
			for I in 0 to 8 loop
				sum_exponent(I) := x_exponent(I) xor y_exponent(I) xor carry ;
				carry := ( x_exponent(I) and y_exponent(I) ) or ( x_exponent(I) and carry ) or ( y_exponent(I) and carry ) ;
			end loop;
			
			carry := '0' ; --Reassigning to zero
			carry1 := '0'; --Reassigning to zero
			
			if(multiply_store(47)='1') then
				--Increasing the exponent
				for I in 0 to 8 loop
					carry := sum_exponent(I) ;
					sum_exponent(I) :=  carry xor temp1(I) xor carry1 ;
					carry1 := (temp1(I) and carry ) or ( temp1(I) and carry1 ) or ( carry and carry1 ) ;
				end loop;
				
				--Assigning value to z's mantissa
				z_mantissa := multiply_store(46 downto 24);
				
				carry := '0' ; --Reassigning to zero
				carry1 := '0'; --Reassigning to zero
				multiply_rounder(0) := multiply_store(23);--can be zero or one on need
				
				--Rounding of mantissa
				for I in 0 to 22 loop
					carry := z_mantissa(I) ;
					z_mantissa(I) :=  carry xor multiply_rounder(I) xor carry1 ;
					carry1 := (multiply_rounder(I) and carry ) or ( multiply_rounder(I) and carry1 ) or ( carry and carry1 ) ;
				end loop;
			else
				--Assigning value to z's mantissa
				z_mantissa := multiply_store(45 downto 23);
				
				carry := '0' ; --Reassigning to zero
				carry1 := '0'; --Reassigning to zero
				multiply_rounder(0) := multiply_store(22);--can be zero or one on need
				
				--Rounding of mantissa
				for I in 0 to 22 loop
					carry := z_mantissa(I) ;
					z_mantissa(I) :=  carry xor multiply_rounder(I) xor carry1 ;
					carry1 := (multiply_rounder(I) and carry ) or ( multiply_rounder(I) and carry1 ) or ( carry and carry1 ) ;
				end loop;
			end if;
			
			--z_exponent:=z_exponent - 127;
			for I in 0 to 8 loop
				carry := sum_exponent(I) ;
				sum_exponent(I) :=  carry xor temp(I) xor carry1 ;
				carry1 := ( carry1 and Not carry ) or ( temp(I) and Not carry ) or (temp(I) and carry1) ;
			end loop;
			
			if (sum_exponent(8)='1') then 
				if (sum_exponent(7)='0') then -- overflow
					z_exponent := "11111111";
					z_mantissa := (others => '0');
					z_sign := x_sign xor y_sign;
				else 									-- underflow negative representaion
					z_exponent := (others => '0');
					z_mantissa := (others => '0');
					z_sign := '0';
				end if;
			else								  		 -- Ok
				z_exponent := sum_exponent(7 downto 0);
				z_sign := x_sign xor y_sign;
			end if;
			
			z_sign := x_sign xor y_sign;--Xoring sign's
		end if;
		
		--Assigning Z every part
		z(31)<=z_sign;
		z(30 downto 23) <= z_exponent;
		z(22 downto 0)<=z_mantissa;
	end process;
end Behavioral;