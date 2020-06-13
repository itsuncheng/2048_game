### I-Tsun Cheng
### 20576079
### ichengaa@connect.ust.hk

.data

input_key:	.word 0 # input key from the player

game_score:	.word 0 # the game score
game_win_text:	.asciiz "You Win! "
game_lose_text:	.asciiz "Game Over! " #You can learn more tricks to win. 
input_target: .asciiz "Enter the target score for winning a game (in the range [64, 2048]): "


# a 16-dim array representing the 4x4 game board grid 
puzzle_map: .word
0 0 0 0 
0 0 0 2
0 0 4 0
0 0 0 0 
# previous puzzle map for checking the grid changes 
puzzle_map_prev: .word
0 0 0 0 
0 0 0 2
0 0 4 0
0 0 0 0 
# a temporary puzzle_map, which could be used in check_lose
puzzle_map_temp: .word
0 0 0 0 
0 0 0 0
0 0 0 0
0 0 0 0 
# an array with 4 elements 
arr4: .word
0 0 0 0
# elements in the zero_indices array are the indices of the zero elements in puzzle_map (i.e. empty spots in the game grid)
# could be used in generate_a_random_tile. 
zero_indices:  .word
0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 

# target number for winning the game
target: .word  2048

.text
main:		
		# read the input target score and store
		jal input_game_target_score	
		# create the game screen and background	
		li $v0, 200 
		syscall
		# pass the input target to the game screen
		lw $a0, target
		li $v0, 204 
		syscall
game_start:
		# initalize the 2048 game grid
		jal generate_a_new_game_map_randomly # overwrite puzzle_map with a new map with 2 random non-zero elements
		li $v0, 201	 # refresh the screen with the new puzzle map
		la $a0, puzzle_map
		syscall
		 
game_loop:
		# 1. read keyboard input
		jal get_keyboard_input
		la $t0, input_key 
		lw $t7, 0($t0) # new input key
		
		# 2. core sliding operations for valid keyboard inputs 
		li $t0, 119 # corresponds to key 'w'
		beq $t7, $t0, process_slide_operation  
		li $t0, 115 # corresponds to key 's'
		beq $t7, $t0, process_slide_operation
		li $t0, 97 # corresponds to key 'a'
		beq $t7, $t0, process_slide_operation
		li $t0, 100 # corresponds to key 'd'
		beq $t7, $t0, process_slide_operation
		
		j game_nap # sleep some ms then jump to game_loop for invalid keyboard inputs
		
	game_update_status:
		# 3. update game status after a slide operation. 
		jal update_game_score # update the game score as the max number of the puzzle
		jal check_win # check whether a game is won and process it. (the game terminates if win)
		bne $v0, $zero, game_win
		
		#   check any tile moved after a slide operation. (a new number will only be generated if tiles are moveable.)
		la $a0, puzzle_map
		la $a1, puzzle_map_prev
		jal check_map_changed
		beq $v0, $zero, game_loop # no tile moved after slide, restart game_loop.
		
		# refresh the game screen, sleep for while to highlight the new generated number
		li $v0, 201 # refresh the screen with the new puzzle map
		la $a0, puzzle_map
		syscall
		li $a0, 150
		jal have_a_nap # sleep $a0 ms
		
		# 4. generate a new non-zero tile in an empty spot
		jal generate_a_random_tile
		
		# 5. check whether the game is lost and take actions. 
		jal check_lose # check after the last new tile is filled
		bne $v0, $zero, game_lose
			
		# 6. refresh the screen with the new puzzle map
		li $v0, 201 
		la $a0, puzzle_map
		syscall

	game_nap:
		li $a0, 30 
		jal have_a_nap 
		j game_loop
		
	game_win: 
		jal actions_for_win
		li $v0, 10 # terminate this program
		syscall
		
	game_lose:
		jal actions_for_lose
		li $v0, 10 # terminate this program
		syscall
				
				
process_slide_operation:
	la $a0, puzzle_map
	la $a1, puzzle_map_prev
	jal copy_map0_to_map1 # save the current map for the tile movement checking, i.e., puzzle_map_prev = puzzle_map
	
	lw $t7, input_key # load key value
	
	# slide the puzzle map in a given direction
	la $a0, puzzle_map # set input param for map_slide_* procedure
	li $t0, 119 # 'w'
	beq $t7, $t0, slide_up  
	li $t0, 115 # 's'
	beq $t7, $t0, slide_down
	li $t0, 97 # 'a'
	beq $t7, $t0, slide_left
	li $t0, 100 # 'd'
	beq $t7, $t0, slide_right
	slide_up: 
	  jal map_slide_up
	  j game_update_status
	slide_down: 
	  jal map_slide_down
	  j game_update_status
	slide_left: 
	  jal map_slide_left
	  j game_update_status
	slide_right: 
	  jal map_slide_right
	  j game_update_status

#--------------------------------------------------------------------
# procedure: slide a given puzzle map in the right direction
# input: $a0, address of the puzzle map to be slided
# result: the input puzzle map will be changed. 
#--------------------------------------------------------------------
map_slide_right:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	add $s0, $a0, $zero # load the address of the puzzle map to be slided

	# slide 1st row
	addi  $a0, $s0, 0  
	addi  $a1, $s0, 4  
	addi  $a2, $s0, 8  
	addi  $a3, $s0, 12
	jal slide
	# slide 2nd row
	addi  $a0, $s0, 16  
	addi  $a1, $s0, 20  
	addi  $a2, $s0, 24  
	addi  $a3, $s0, 28
	jal slide
	# slide 3rd row
	addi  $a0, $s0, 32
	addi  $a1, $s0, 36  
	addi  $a2, $s0, 40  
	addi  $a3, $s0, 44
	jal slide
	# slide 4th row
	addi  $a0, $s0, 48
	addi  $a1, $s0, 52  
	addi  $a2, $s0, 56  
	addi  $a3, $s0, 60
	jal slide
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra 
	
#--------------------------------------------------------------------
# procedure: slide a given puzzle map in the left direction
# input: $a0, address of the puzzle map to be slided
# result: the input puzzle map will be changed. 
#--------------------------------------------------------------------
map_slide_left:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	add $s0, $a0, $zero 

	# slide 1st row
	addi  $a0, $s0, 12  
	addi  $a1, $s0, 8  
	addi  $a2, $s0, 4  
	addi  $a3, $s0, 0
	jal slide
	# slide 2nd row
	addi  $a0, $s0, 28  
	addi  $a1, $s0, 24  
	addi  $a2, $s0, 20  
	addi  $a3, $s0, 16
	jal slide
	# slide 3rd row
	addi  $a0, $s0, 44
	addi  $a1, $s0, 40  
	addi  $a2, $s0, 36  
	addi  $a3, $s0, 32
	jal slide
	# slide 4th row
	addi  $a0, $s0, 60
	addi  $a1, $s0, 56 
	addi  $a2, $s0, 52  
	addi  $a3, $s0, 48
	jal slide
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra	
		

#--------------------------------------------------------------------
# procedure: slide a given puzzle map in the down direction
# input: $a0, address of the puzzle map to be slided
# result: the input puzzle map will be changed. 
#--------------------------------------------------------------------
map_slide_down:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	add $s0, $a0, $zero 

	# slide 1st row
	addi  $a0, $s0, 0  
	addi  $a1, $s0, 16  
	addi  $a2, $s0, 32  
	addi  $a3, $s0, 48
	jal slide
	# slide 2nd row
	addi  $a0, $s0, 4  
	addi  $a1, $s0, 20  
	addi  $a2, $s0, 36  
	addi  $a3, $s0, 52
	jal slide
	# slide 3rd row
	addi  $a0, $s0, 8
	addi  $a1, $s0, 24  
	addi  $a2, $s0, 40  
	addi  $a3, $s0, 56
	jal slide
	# slide 4th row
	addi  $a0, $s0, 12
	addi  $a1, $s0, 28  
	addi  $a2, $s0, 44  
	addi  $a3, $s0, 60
	jal slide
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra 

#--------------------------------------------------------------------
# procedure: slide a given puzzle map in the up direction
# input: $a0, address of the puzzle map to be slided
# result: the input puzzle map will be changed. 
#--------------------------------------------------------------------
map_slide_up:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	add $s0, $a0, $zero 

	# slide 1st row
	addi  $a0, $s0, 48  
	addi  $a1, $s0, 32  
	addi  $a2, $s0, 16  
	addi  $a3, $s0, 0
	jal slide
	# slide 2nd row
	addi  $a0, $s0, 52  
	addi  $a1, $s0, 36  
	addi  $a2, $s0, 20  
	addi  $a3, $s0, 4
	jal slide
	# slide 3rd row
	addi  $a0, $s0, 56
	addi  $a1, $s0, 40  
	addi  $a2, $s0, 24  
	addi  $a3, $s0, 8
	jal slide
	# slide 4th row
	addi  $a0, $s0, 60
	addi  $a1, $s0, 44  
	addi  $a2, $s0, 28  
	addi  $a3, $s0, 12
	jal slide
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra 

#--------------------------------------------------------------------
# procedure: slide($a0, $a1, $a2, $a3)   (Core) 
#    slide 4 numbers in a row or column, say n0,n1,n2,n3. 
#    slide n0,n1,n2,n3 in the direction of n0->n1->n2->n3 as far as possible until they hit the boundary or a non-zero number.
# input: $a0, $a1, $a2, $a3 are the addresses of the 4 numbers of a column or row
# result: the 4 numbers will be shifted and merged in the direction of $a0 -> $a3, according to the 2048 game rules.
#--------------------------------------------------------------------
slide:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	lw $t0, 0($a0)	# load n1,n2,n3,n4 values
	lw $t1, 0($a1)
	lw $t2, 0($a2)
	lw $t3, 0($a3)
	
	add $t7, $zero, $zero	# t7 is used as a flag to indicate whether a merge operation is performed. 
	
	bne $t3, $zero, exit_t3ne0
	add $t3, $t2, $zero
	add $t2, $t1, $zero
	add $t1, $t0, $zero
	add $t0, $zero, $zero
	exit_t3ne0:
	
	#***** Task 3: slide and merge the numbers in a row or column.  
	# hint: the sliding operation can be decomposited into 3 steps
	# step 1, move non-zero tiles to the end and squeeze the intermediate zero tiles. e.g. [0,2,0,2] -> [0,0,2,2]. 
	# step 2, merge two neigboring tiles if they are equal, e.g. [2,2,2,2] -> [0,4,0,4]. 
	#        (Note: DO NOT merge them recursively, i.e., [2,2,2,2] -> [0,0,0,8], which violates the 2048 game rule).
	# step 3, repeat step 1 for alignment, [0,4,0,4] -> [0,0,4,4]
	#------ Your code starts here ------
	move_to_end:
	li $t6, 2 # max number of shifts (already shifted by 1 if $t3=0)
	add $t5, $zero, $zero # shifts made
	
	checkt3ne0:
	beq $t5, $t6, merge_equal
	beq $t3, $zero, t3e0
	j checkt2ne0
	t3e0:
	add $t3, $t2, $zero
	add $t2, $t1, $zero
	add $t1, $t0, $zero
	add $t0, $zero, $zero
	addi $t5, $t5, 1
	j checkt3ne0
	
	checkt2ne0:
	beq $t5, $t6, merge_equal
	beq $t2, $zero, t2e0
	j checkt1ne0
	t2e0:
	add $t2, $t1, $zero
	add $t1, $t0, $zero
	add $t0, $zero, $zero
	addi $t5, $t5, 1
	j checkt2ne0
	
	checkt1ne0:
	beq $t5, $t6, merge_equal
	beq $t1, $zero, t1e0
	j merge_equal
	t1e0:
	add $t1, $t0, $zero
	add $t0, $zero, $zero
	addi $t5, $t5, 1
	j checkt1ne0
	
	
	merge_equal:
	bne $t7, $zero, exit_slide # if merge is already performed, exit slide
	beq $t2, $t3, t2equalt3
	beq $t1, $t2, t1equalt2
	j checkift0equalt1
	
	t2equalt3:
	add $t3, $t3, $t3
	add $t2, $zero, $zero
	j checkift0equalt1
	
	t1equalt2:
	add $t2, $t2, $t2
	add $t1, $zero, $zero
	j complete_merge
	
	checkift0equalt1:
	beq $t0, $t1, t0equalt1
	j complete_merge
	
	t0equalt1:
	add $t1, $t1, $t1
	add $t0, $zero, $zero
	
	complete_merge:
	li $t7, 1 # merge operation is performed
	j move_to_end
	
	exit_slide:
	#------ Your code ends here ------	
   
	sw $t0, 0($a0)	# store new values to the map
	sw $t1, 0($a1)
	sw $t2, 0($a2)
	sw $t3, 0($a3) 
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	
	jr $ra		# return
	
#--------------------------------------------------------------------
# procedure: generate_a_new_game_map_randomly
# result: overwrite puzzle_map with a 4x4 map with two random non-zero tiles. 
#--------------------------------------------------------------------	
generate_a_new_game_map_randomly:
	addi $sp, $sp, -4  # push 
	sw $ra, 0($sp)
	
	la $a0, puzzle_map
	jal clear_map		   # clear the puzzle map
	jal generate_a_random_tile # generate two non-zero tiles randomly
	jal generate_a_random_tile
	
	lw $ra, 0($sp)	#pop
	addi $sp, $sp, 4
	jr $ra	

#--------------------------------------------------------------------
# procedure: clear_map($a0)
# input: $a0, address of a puzzle map
# result: set all elements in the puzzle map to be 0
#--------------------------------------------------------------------
clear_map: 
	#***** Task 1: zero out all elements in the puzzle map. 
	# The address of the puzzle map is already loaded into $a0 as an input parameter. 
	#------ Your code starts here ------
	add $t0, $zero, $zero # i counter
	li $t1, 16 # len of puzzle_map
	
	loop_clear_map:
	slt $t2, $t0, $t1
	beq $t2, $zero, finish_loop_clear_map
	sw $zero, 0($a0)
	addi $a0, $a0, 4
	addi $t0, $t0, 1
	j loop_clear_map
	
	finish_loop_clear_map:

	#------ Your code ends here ------
	jr $ra

#--------------------------------------------------------------------
# procedure: generate_a_random_tile()
# result: a zero tile in puzzle_map will be replaced by a random number (either 2 or 4).  
#--------------------------------------------------------------------
generate_a_random_tile:
	la $t0, puzzle_map
	la $t1, zero_indices
	
	#***** Task 2: generate a non-zero tile with the value of 2 or 4 (uniformly at random) in an empty spot in the game grid. 
	# hint: 
	# step 1: find the indices of zero tiles and save them in array zero_indices and count the number of zero tiles (named num_zero_tiles)
	# step 2: generate a random integer in range [0, num_zero_tiles) using syscall service 42, let's denote it as zero_ind_ind
	# step 3: generate a random integer among 2 and 4, let's denote it as X. 
	# step 4: set puzzle_map[zero_indices[zero_ind_ind]] = X
	#------ Your code starts here ------
	# step 1
	add $t7, $zero, $zero # i counter
	li $t6, 16 # len of puzzle_map
	add $t5, $zero, $zero # num_zero_tiles
	
	loop:
	beq $t7, $t6, finish_loop
	lw $t2, 0($t0)
	bne $t2, $zero, not_zero
	sw $t7, 0($t1) # store i to zero_indices
	addi $t1, $t1, 4
	addi $t5, $t5, 1
	
	not_zero:
	addi $t0, $t0, 4
	addi $t7, $t7, 1
	j loop
	
	# step 2
	finish_loop:
	add $a0, $zero, $zero
	add $a1, $t5, $zero
	li $v0, 42
	syscall
	add $t3, $a0, $zero # $t3 = zero_ind_ind
	
	# step 3
	addi $a0, $zero, 1
	addi $a1, $zero, 2
	li $v0, 42
	syscall
	beq $a0, $zero, new_tile_is_two
	addi $t4, $zero, 4 # $t4 = X
	j step4
	
	new_tile_is_two:
	addi $t4, $zero, 2 # $t4 = X
	
	# step 4
	step4:
	add $t7, $zero, $zero
	la $t1, zero_indices
	loop_step4:
	beq $t7, $t3, finish_loop_step4
	addi $t1, $t1, 4
	addi $t7, $t7, 1
	j loop_step4
	
	finish_loop_step4:
	lw $t3, 0($t1) # t3 = zero_indices[zero_ind_ind]
	add $t7, $zero, $zero
	la $t0, puzzle_map
	loop2_step4:
	beq $t7, $t3, finish_loop2_step4
	addi $t0, $t0, 4
	addi $t7, $t7, 1
	j loop2_step4
	
	finish_loop2_step4:
	sw $t4, 0($t0) # 0($t0) = puzzle_map[zero_indices[zero_ind_ind]]
	
	
	
	#------ Your code ends here ------
	
	jr $ra		# return
	
#--------------------------------------------------------------------
# procedure: check_map_changed($a0, $a1)
# input: $a0 - map0, $a1 - map1
# return: $v0=0 if the two maps are identical, otherwise $v0=1
#--------------------------------------------------------------------	
check_map_changed:
	add $t0, $a0, $zero
	add $t1, $a1, $zero
	add $t7, $zero, $zero	#i, counter 
	li $t6, 16
	add $v0, $zero, $zero # return value
	
	# for (i=0;i<16;i++) {if (map_prev[i]!=map[i]) {moved=1; goto }}
	loop_compare:
	bne $t7, $t6, if_compareloop_not_done  # if i<16,in for (i=0;i<16;i++)
	j end_if_compareloop_not_done
	if_compareloop_not_done:
	  lw $t3, 0($t0)
	  lw $t4, 0($t1)
	  #if (map_prev[i]!=map[i])
	  bne $t3, $t4, if_find_moved_tile  # if (map_prev[i]!=map[i])
	  j end_if_find_moved_tile
	  if_find_moved_tile:
	    li $v0, 1
	    j end_if_compareloop_not_done # goto the end
	  end_if_find_moved_tile:
	  
	  addi $t0, $t0, 4 # point to next element to be copied
	  addi $t1, $t1, 4 
	  addi $t7, $t7, 1 # i++
	  j loop_compare
	end_if_compareloop_not_done:
	
	jr $ra		# return
	
#--------------------------------------------------------------------
# procedure: check_process_win()
# return: $v0=1 if win, $v0=0 if not win yet. 
#--------------------------------------------------------------------
check_win:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	li $v0, 0
	
	#***** Task 4: check game win.
	#------ Your code starts here ------
	la  $a0, puzzle_map
	li  $a1, 16
	jal find_max
	add $t0, $v0, $zero
	li $v0, 0
	la $t1, target
	lw $t2, 0($t1)
	
	slt $t3, $t0, $t2
	bne $t3, $zero, not_win
	li $v0, 1
	
	not_win:
	
	#------ Your code ends here ------
	
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra		# return	

#--------------------------------------------------------------------
# procedure: actions_for_win 
#  perform a series of actions after winning the game
#--------------------------------------------------------------------
actions_for_win:
	addi $sp, $sp, -4  # push 
	sw $ra, 0($sp)
	
	la $a0, puzzle_map # refresh screen  
	li $v0, 201
	syscall
	li $a0, 4 # play the sound of passing a game level
	li $a1, 0
	li $v0, 202
	syscall
	li $a0, 120
	jal have_a_nap # sleep $a0 ms
	la $a3, game_win_text # display game winning message 
	li $a0, -2 # special ID for this text object
	addi $a1, $zero, 180 # display the message at coordinate (x=$a1, y=$a2)
	addi $a2, $zero, 300
	li $v0, 207 # create object of the game winning or losing message	
	syscall  
	li $a0, 0 # stop background sound
	li $a1, 2
	li $v0, 202
	syscall
	
	lw $ra, 0($sp)	#pop
	addi $sp, $sp, 4
	jr $ra		# return

#--------------------------------------------------------------------
# procedure: check_lose()
# return: $v0=1 if lose, $v0=0 otherwise. 
#--------------------------------------------------------------------
check_lose:
	addi $sp, $sp, -8  # push 
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	li $v0, 0
	
	#***** Task 5: check game lose. 
	#------ Your code starts here ------
	la $t0, puzzle_map
	add $t7, $zero, $zero # i counter
	li $t6, 16 # len of puzzle_map
	
	# check whether puzzle map is full
	loop_check_lose:
	beq $t7, $t6, finish_loop_check_lose
	lw $t1, 0($t0)
	beq $t1, $zero, not_lost_yet # if a tile is empty, not lost yet
	addi $t0, $t0, 4
	addi $t7, $t7, 1
	j loop_check_lose
	
	# check whether there are neighbors that are combinable
	finish_loop_check_lose:
	la $t0, puzzle_map
	
	# checking corners
	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, 16($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	
	lw $t1, 12($t0)
	lw $t2, 8($t0)
	lw $t3, 28($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	
	lw $t1, 48($t0)
	lw $t2, 32($t0)
	lw $t3, 52($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	
	lw $t1, 60($t0)
	lw $t2, 56($t0)
	lw $t3, 44($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	
	# checking sides
	lw $t1, 4($t0)
	lw $t2, 8($t0)
	beq $t1, $t2, not_lost_yet
	
	lw $t1, 52($t0)
	lw $t2, 56($t0)
	beq $t1, $t2, not_lost_yet
	
	lw $t1, 16($t0)
	lw $t2, 32($t0)
	beq $t1, $t2, not_lost_yet
	
	lw $t1, 28($t0)
	lw $t2, 44($t0)
	beq $t1, $t2, not_lost_yet
	
	#checking middle
	addi $t0, $t0, 20
	lw $t1, 0($t0) # middle element
	lw $t2, -16($t0)
	lw $t3, -4($t0)
	lw $t4, 4($t0)
	lw $t5, 16($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	beq $t1, $t4, not_lost_yet
	beq $t1, $t5, not_lost_yet
	
	addi $t0, $t0, 4
	lw $t1, 0($t0) # middle element
	lw $t2, -16($t0)
	lw $t3, -4($t0)
	lw $t4, 4($t0)
	lw $t5, 16($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	beq $t1, $t4, not_lost_yet
	beq $t1, $t5, not_lost_yet
	
	addi $t0, $t0, 12
	lw $t1, 0($t0) # middle element
	lw $t2, -16($t0)
	lw $t3, -4($t0)
	lw $t4, 4($t0)
	lw $t5, 16($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	beq $t1, $t4, not_lost_yet
	beq $t1, $t5, not_lost_yet
	
	addi $t0, $t0, 4
	lw $t1, 0($t0) # middle element
	lw $t2, -16($t0)
	lw $t3, -4($t0)
	lw $t4, 4($t0)
	lw $t5, 16($t0)
	beq $t1, $t2, not_lost_yet
	beq $t1, $t3, not_lost_yet
	beq $t1, $t4, not_lost_yet
	beq $t1, $t5, not_lost_yet
	
	lose:
	li $v0, 1 # if no neigboring tiles have the same value, loses
	
	not_lost_yet:

	#------ Your code starts here ------
	lw $ra, 4($sp)	#pop
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	
	jr $ra

#--------------------------------------------------------------------
# procedure: actions_for_lose
#  perform a series of actions after winning the game
#--------------------------------------------------------------------
actions_for_lose:
	addi $sp, $sp, -4  # push 
	sw $ra, 0($sp)
	
	la $a0, puzzle_map # refresh screen 
	li $v0, 201
	syscall
	li $a0, 3     # play the sound of losing the game
	li $a1, 0
	li $v0, 202
	syscall
	la $a3, game_lose_text # display game winning message c
	li $a0, -1 # special ID for this text object
	addi $a1, $zero, 180 # display the message at coordinate (x=$a1, y=$a2)
	addi $a2, $zero, 300
	li $v0, 207 # create object of the game winning or losing message	
	syscall 
	
	lw $ra, 0($sp)	#pop
	addi $sp, $sp, 4
	jr $ra		# return
	
#--------------------------------------------------------------------
# procedure: copy_map0_to_map1($a0, $a1)
# input: $a0 - addr of map0, $a1 - addr of map1
#--------------------------------------------------------------------
copy_map0_to_map1: 
	add $t0, $a0, $zero
	add $t1, $a1, $zero
	
	add $t7, $zero, $zero	#i, counter 
	li $t6, 16
	# for (i=0;i<16;i++) {map_prev[i]=map[i]}
	loop_copy:
	bne $t7,$t6, if_copy_not_done
	j end_if_copy_not_done
	if_copy_not_done:
	  lw $t3, 0($t0)
	  sw $t3, 0($t1)
	  addi $t0, $t0, 4 # point to next element to be copied
	  addi $t1, $t1, 4
	  addi $t7, $t7, 1 # i++
	  j loop_copy
	end_if_copy_not_done:
	
	jr $ra		# return
	
#--------------------------------------------------------------------
# procedure: update_game_score()
# Find the max number in puzzle_map and take it to update the obtained game score. 
#--------------------------------------------------------------------
update_game_score:
	addi $sp, $sp, -4  # push 
	sw $ra, 0($sp)
	
	la  $a0, puzzle_map
	li  $a1, 16
	jal find_max
	add $a0, $v0, $zero  # $a0=max_val
	li $v0, 203
	syscall
	
	lw $ra, 0($sp)	#pop
	addi $sp, $sp, 4
	jr $ra 

#--------------------------------------------------------------------
# procedure: find_max($a0, $a1), find the max element in an array. 
# input: $a0: array address. $a1: the length of the array. 
# return: $v0, the max element
#--------------------------------------------------------------------
find_max:
	add $t0, $a0, $zero
	add $t1, $a1, $zero # len
	add $t7, $zero, $zero	#i, counter
	add $v0, $zero, $zero # temp max 
	
	loop_findmax:
	bne $t7,$t1, if_findmax_not_done
	j end_if_findmax_not_done
	if_findmax_not_done:
	  lw $t3, 0($t0)
	  slt $t5, $v0, $t3
	  beq $t5, $zero, exit_update_max  # if max >= arr[i], exit
	    add $v0, $t3, $zero   # max = arr[i]
	  exit_update_max:
	  addi $t0, $t0, 4 # point to next element to be copied
	  addi $t7, $t7, 1 # i++
	  j loop_findmax
	end_if_findmax_not_done:
	
	jr $ra 

#--------------------------------------------------------------------
# procedure: have_a_nap($a0)
# The grogram sleeps for $a0 milliseconds
#--------------------------------------------------------------------
have_a_nap:
	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall
	jr $ra
	
#--------------------------------------------------------------------
# procedure: get_keyboard_input
# If an input is available, save its ASCII value in the array input_key,
# otherwise save the value 0 in input_key.
#--------------------------------------------------------------------
get_keyboard_input:
	add $t2, $zero, $zero
	lui $t0, 0xFFFF
	lw $t1, 0($t0)
	andi $t1, $t1, 1
	beq $t1, $zero, gki_exit
	lw $t2, 4($t0)

	gki_exit:
	la $t0, input_key 
	sw $t2, 0($t0) # save input key
	jr $ra

#--------------------------------------------------------------------
# procedure: input_game_target_score
# get the following information interactively from the user:
# 1) the target number for a win
# the results will be placed in $v0 and stored in target 
#--------------------------------------------------------------------
input_game_target_score:
	la $a0, input_target
	li $v0, 4
	syscall # print string
	li $v0, 5
	syscall # read integer
	la $t0, target
	sw $v0, 0($t0) # store
	
	jr $ra

