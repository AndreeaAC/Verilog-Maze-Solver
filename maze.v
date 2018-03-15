`timescale 1ns / 1ps 

module maze( 
input clk,
input[5:0] starting_col, starting_row, 		// indicii punctului de start
input maze_in, 							// ofera informatii despre punctul de coordonate [row, col]
output reg [5:0] row, col, 							// selecteaza un rand si o coloana din labirint
output reg maze_oe,							// output enable (activeaza citirea din labirint la randul si coloana date) - semnal sincron	
output reg maze_we, 							// write enable (activeaza scrierea in labirint la randul si coloana  date) - semnal sincron
output reg done);		 						// iesirea din labirint a fost gasita; semnalul ramane activ 



`define start_maze 0
`define write 1
`define check_right 2
`define verify 3
`define end_maze 4
`define check_forward 5
`define move_forward 6
`define done_checking 7

`define left 0
`define right 1
`define up 2
`define down 3

 reg [3:0] state,next_state;
 reg [5:0] current_row, current_col;
 reg [1:0] direction;
 reg last_checked;//0=right, 1=forward; trebuie sa stiu ce verificare fac in functie directia in care ma uit

 initial
 begin
	state=`start_maze;
	direction=`up;
 end
 
 
 always @(posedge clk)
	 begin
		state<=next_state;
	 end
	 
 always @(*)
 begin
	maze_oe=0;
	maze_we=0;
	case(state)
		`start_maze://blocul initial al automatului, se initializeaza pozitia curenta cu cea initiala
			begin
				current_row=starting_row;
				current_col=starting_col;
				done=0;
				next_state=`write;//actualizarea labirintului(scriu 2 pe pozitia initiala)
			end
			
		`write://blocul de actualizare al labirintului
			begin
				maze_we=1;
				row=current_row;
				col=current_col;
				next_state=`check_right;//dupa actualizare, verific din nou reperul principal al regulii(pozitia din dreapta)
			end
			
		`check_right://blocul de verificare pentru regula mainii drepte
			begin
				maze_oe=1;
				case(direction)//pozitia din dreapta depinde de directia in care ma uit
					`left:
					begin
						row=current_row-1;
						col=current_col;
					end
					
					`right:
					begin
						row=current_row+1;
						col=current_col;
					end
					
					`up:
					begin
						col=current_col+1;
						row=current_row;
					end
					
					`down:
					begin
						col=current_col-1;
						row=current_row;
					end
							
				endcase
				last_checked=0;//retin ultima directie pe care am citit-o, pentru a o putea verifica ulterior
				next_state=`done_checking;//astept un ciclu de ceas pentru a se termina citirea din labirint
			end
				
			`verify:
			begin
					if((row==0 || row==63 || col==0 || col==63) && maze_in==0 )//verific conditia de iesire din labirint(marginea sa fie culoar, si sa fiu la o pozitie distanta de ea)
						begin
							done=1;
							maze_we=1;
							current_col=col;
							current_row=row;
							next_state=`end_maze;
						end
					if((row==0 || row==63 || col==0 || col==63) && maze_in==1)//marginea pe care o verific, si fata de care ma aflu la o pozitie distanta este zid
						begin
							case(direction)//ma rotesc si ma uit din nou spre dreapta in functie de noul reper
								`left: direction=`down;
								`right: direction=`up;
								`up: direction=`left;
								`down: direction=`right;
							endcase
							next_state=`check_right;
						end
					if(row!=0 && row!=63 && col!=0 && col!=63)//nu sunt la o pozitie distanta de margine
					begin
							if(maze_in==0 && last_checked==0)//culoar la dreapta
							begin
								case(direction)//ma rotesc spre dreapta, in functie de reper si avansez o pozitie, pentru a avea din nou zid in partea dreapta
								`left:
								begin
									direction=`up;
									current_row=current_row-1;
								end
								`right:
								begin
									direction=`down;
									current_row=current_row+1;
								end
								`up:
								begin
									direction=`right;
									current_col=current_col+1;
								end
								`down:
								begin
									direction=`left;
									current_col=current_col-1;
								end	
							endcase
								next_state=`write;//actualizarea labirintului
							end
							if(maze_in==1 && last_checked==0)//perete in dreapta
								next_state=`check_forward;	//verific daca am culoar in fata pentru a putea avansa o pozitie
							if(maze_in==1 && last_checked==1)//perete in fata
							begin
								case(direction)//ma rotesc si ma uit din nou spre dreapta in functie de noul reper
									`left: direction=`down;
									`right: direction=`up;
									`up: direction=`left;
									`down: direction=`right;
								endcase
								next_state=`check_right;
							end
							if(maze_in==0 && last_checked==1)//culoar in fata
								next_state=`move_forward;
				end
			end
			`end_maze://starea finala a automatului
			begin
				next_state=`end_maze;//raman mereu la finalul labirintului
			end			
				
			`check_forward:
			begin
				maze_oe=1;
				case(direction)//citesc pozitia din fata, in functie de directia in care ma uit, pentru a o verifica ulterior
					`left:
					begin
						row=current_row;
						col=current_col-1;
					end
					
					`right:
					begin
						col=current_col+1;
						row=current_row;
					end
					
					`up:
					begin
						row=current_row-1;
						col=current_col;
					end
					
					`down:
					begin
						row=current_row+1;
						col=current_col;
					end
							
				endcase
				last_checked=1;//retin, pentru verificare, ca am citit o casuta din fata
				next_state=`done_checking;//astept un clock pentru a se termina citirea din labirint
			end
			
			`move_forward:
			begin
			case(direction)//ma mut inainte o pozitie, in functie de directia in care ma uit
					`left:
					begin
						current_col=current_col-1;
					end
					
					`right:
					begin
						current_col=current_col+1;
					end
					
					`up:
					begin
						current_row=current_row-1;
					end
					
					`down:
					begin
						current_row=current_row+1;
					end
							
				endcase
			next_state=`write;//actualizare labirint
			end
			
			`done_checking:
			 begin
				 maze_oe=0;
				 next_state=`verify;
			 end
			
		endcase
		
 end

endmodule
