
.text


.macro reset_reg
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
.end_macro

preorder:
    #Define your code here
    
    #a0 = Node currNodeAddr
    #a1 = Node[] nodes
    #a2 = int fd
    
    reset_reg
    
    move $t0, $a0 #move a0 into t0 for bitwise processing
    lw $t1, ($t0) #load the word from the array address
    andi $t1, $t1, 0x0000FFFF #int nodeValue = currNodeAddr.getValue
    #addi $t1, $t1, '0' #make it to a char
    #la $t2, word #load the address of where i am going to store the value (need address for syscall 15!!!)
    #sw $t1, ($t2) #store the value there
    
    addi $sp, $sp, -16 #save the registers on the stack to call itof
    sw $a0, ($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $ra, 12($sp)
    
    move $a0, $a2 #file descriptor in a0
    move $a1, $t1 #i will just pass in the value and use the buffer in itof
    #la $a1, word #MUST be an address, address of the value
    jal itof #call itof and store the char into the file
    
    lw $a0, ($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16 #load the registers back after calling itof
    
    addi $sp, $sp, -12 #Must preserve a0, a1, and a2 because syscall 15 uses them
    sw $a0, ($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    
    li $v0, 15 #Preparing to write a newline char to the file
    move $a0, $a2 #Move the file desc. to a0, Must preserve a0
    la $a1, nl #Load the buffer a1 with a new line char
    li $a2, 1 #Length of the buffer
    syscall
    
    lw $a0, ($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    addi $sp, $sp, 12 #Restore the a0, a1, and a2 args back from the stack
    
    move $t0, $a0 #Move the node into t1 to do bitwise processing - get the left node index
    lw $t1 ($t0) #get the word again for processing
    andi $t1, $t1, 0xFF000000 #this gets byte 3 and t1 now has the index of the left node in the array
    srl $t1, $t1, 24 #move the bits over because 0xFF000000 is not in the range of 0-255
    
    beq $t1, 255, invalidLeftNode #if the left node EQUALS 255 it is not valid
    
    move $t2, $a1 #Store the base address of the array in t2, need to get offset
    li $t3, 4
    mul $t3, $t3, $t1 #Multiply the index by the element size (4) to get the offset
    add $t2, $t2, $t3 #t2 plus the offset t3, t2 now has the leftNodeAddr
    
    #must call preorder here recursively with the leftNodeAddr as the currNodeAddr
    addi $sp, $sp, -16
    sw $a0, ($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $ra, 12($sp)
    
    move $a0, $t2 #t2 has the offset of the nodes array with the leftNodeAddr
    move $a1, $a1 #a1 has the nodes array
    move $a2, $a2 #has the file descriptor
    jal preorder #recursively call preorder
    
    lw $a0, ($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    
    invalidLeftNode:
    
    move $t0, $a0 #Move the currNode into t0 to check the right node
    lw $t1, ($t0) #get the word
    andi $t1, $t1, 0x00FF0000 #get the right node by anding it with 8 bits
    srl $t1, $t1, 16
    
    beq $t1, 255, invalidRightNode
    
    move $t2, $a1 #store the base address of the array to get the offset
    li $t3, 4 #element size
    mul $t3, $t3, $t1 #element size * index
    add $t2, $t2, $t3 #addr + elem_size * index = addr + offset = rightNodeAddr
    
    #must call preorder here recursively with the rightNodeAddr as the currNodeAddr
    addi $sp, $sp, -16
    sw $a0, ($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $ra, 12($sp)
    
    move $a0, $t2 #t2 has the offset of the nodes array with the leftNodeAddr
    move $a1, $a1 #a1 has the nodes array
    move $a2, $a2 #has the file descriptor
    jal preorder #recursively call preorder
    
    lw $a0, ($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    
    invalidRightNode:
    
    jr $ra
    
    
    
itof:

	#this function is a helper function for preorder to write the value into the text file
	#a1 is the value to be written
	#a0 is the file descriptor
	
	#Problem: If the number is greater than 1 char, we will need to process the value
	
	li $t0, 10 #Will be used for dividing
	move $fp, $sp #I will be using sp to store the remainders onto the stack
	#fp will help keep track of where I put my remainders initially
	
	#lo = quo
	#hi = rem
	
	andi $t2, $a1, 32768 #check if the 16th bit (sign bit) is 1 or 0
	li $t4, 32768
		
	beq $t2, $t4, isNeg
	j itof_dividingNum
	
	isNeg:
	
		xori $a1, $a1, 65535 #flip all the bits
		addi $a1, $a1, 1
		move $t3, $a1 #holds the value to restore after isNeg syscall
		#a0 has the fd
		la $a1, neg
		li $a2, 1
		li $v0, 15
		syscall
		move $a1, $t3
		j itof_dividingNum
	
	
	itof_dividingNum:
	
		beqz $a1, endDividing #a1 holds our value, once it is zero we end the loop
		div $a1, $t0 #divide it by 10
		mflo $a1 #replace the number with quotient to divide again
		mfhi $t1 #store the rem on the stack
		addi $sp, $sp, -4
		sw $t1, ($sp)
		j itof_dividingNum
		
		
	endDividing:
	
		beq $fp, $sp, end_itof #once we reach fp again we stop
		lw $t0, ($sp) #get the value (rem)
		la $t1, word #get the addr of the buffer
		addi $t0, $t0, '0' #add '0' to make it a char
		sw $t0, ($t1) #store it into the buffer bc we need an addr
		la $a1, word #get the addr
		#a0 has the file descriptor
		li $a2, 1
		li $v0, 15
		syscall
		addi $sp, $sp, 4
		j endDividing
		
	end_itof:
	
		jr $ra
	



linear_search:

	reset_reg

	#a0 has the byte[] flags array
	#a1 has the max size
	move $t0, $a1 #gunna need to calculate the number of bytes from the bit max size
	li $t1, 8 #used for dividing
	li $t2, 0 #used as a counter
	
	calculate_bytes:
	
		beqz $t0, end_calculate_bytes
		div $t0, $t1 #divide it by 8 (1 byte)
		mflo $t0 #put it back to divide
		addi $t2, $t2, 1 #increment the byte counter
		j calculate_bytes
		
	end_calculate_bytes:
	
		mfhi $t3 #holds the remainder, if the remainder is 0, do not add to t2, if its more, add 1 to t2
		bgtz $t3, another_byte
		j before_findzerobit #do not add 1 byte
		#if it doesnt just to another byte, then t2 is fine the way it is
		
	another_byte:
	
		addi $t2, $t2, 1 #increment the # of bytes
		#now we need to loop through the array and then loop through each byte to find the first zero
		
	before_findzerobit:
	
		move $t0, $a0 #t0 has the bytes array
		li $t1, 8 #t1 has the number 8, can be used to loop thru the bits
		#t2 has the number of bytes in the array
		#t3 will hold the byte of each iteration
		li $t4, 0 #t4 will hold the overall counter of bits traversed so far aka num to return
		li $t5, 0 #will be used as a bit counter for each inner loop
		#t6 will hold the lsb
		move $t7, $a1 #holds the max value
		
	findzerobit:
		
		bltz $t2, noEmptyNodeFound #make a for loop
		lb $t3, ($t0) #load the byte from the byte array, need to loop thru the bits and find the first zero
		
		bitloop:
		
			li $t1, 8
			beq $t5, $t1, endBitLoop
			beqz $t7, endBitLoop
		
			move $t6, $t3 #hold the byte to calc lsb
			andi $t6, $t6, 1 #will get the lsb
			beqz $t6, foundEmptyNode
			
			srl $t3, $t3, 1
			addi $t4, $t4, 1
			addi $t5, $t5, 1
			addi $t7, $t7, -1
			
			j bitloop
			
		endBitLoop:
		
		addi $t2, $t2, -1
		addi $t0, $t0, 1
		li $t5, 0
		li $t1, 8
		
		j findzerobit
		
		noEmptyNodeFound:
		
			li $v0, -1
			jr $ra
		
		foundEmptyNode:
		
			move $v0, $t4
			jr $ra
			


set_flag:

	reset_reg

	#a0 has the byte[] flags array
	#a1 has the index to change the bit at
	#a2 has the has the value (0 or 1) to set at the index in the LSB
	#a3 has the has the maxSize
	
	bltz $a1, error_set_flag #throw error if the index is < 0
	bge $a1, $a3, error_set_flag #throw error if the index is >= maxSize
	
	li $t0, 8
	div $a1, $t0 #divide the index by 8 - quotient is the byte and the remainder is the bit pos
	
	mflo $t1 #hold the quotient
	mfhi $t2 #holds the remainder
	
	add $a0, $a0, $t1 #add the offset to get the byte
	
	lb $t3, ($a0) #get the byte from the byte flags array
	
	ror $t3, $t3, $t2 #rotate the bits by the remainder
	
	andi $a2, $a2, 1 #and it with 1 to get the LSB (0 or 1)
	
	beqz $a2, setValToZero #if the value is being turned to zero we want to do diff ops than turning to one
	j setValToOne
	
	setValToZero:
	
		andi $t3, $t3, 4294967294 #Must and it with 1111...0 (31 ones) because ror rotates by 32 bits
		rol $t3, $t3, $t2 #rotate it back to the original pos
		j end_setflag
	
	setValToOne:
	
		andi $t3, $t3, 4294967294 #And it by 1111...0 (31 ones)
		addi $t3, $t3, 1 #Add one to change the bit to a one
		rol $t3, $t3, $t2 #Rotate back
		j end_setflag
	
	error_set_flag:
	
		li $v0, 0
		jr $ra
		
	end_setflag:
	
		sb $t3, ($a0) #Store the byte back into the flags array
		li $v0, 1
		jr $ra
	

find_position:

	reset_reg

	#a0 has the node[] nodes array
	#a1 has the currIndex - the index of the current node
	#a2 has the new Value to be inserted
	#returns v0 - the index of the would be parent node
	#returns v1 - 0 if left child and 1 if right child
	
	#newValue = toSignedHalfWord(newValue) means we must discard the upper 16 bits and sign extend by the 16th bit
	move $t7, $a2 #This is for the recursive statement
	move $t0, $a2 #move the value into t0
	andi $t0, $a2, 32768 #this will get the 16th bit
	beqz $t0, nonNegValue
	j NegValue
	
	nonNegValue:
	
		andi $t0, $a2, 65535 #gets the lower 16 bits of the value
		lui $a2, 0x0000 #load the upper 16 bits with zero because the value is positive
		add $a2, $a2, $t0 #add the lower 16 bits from t0 into a2
		j cont_find_position
	
	NegValue:
	
		andi $t0, $a2, 65535
		lui $a2, 0xFFFF #we want the upper 16 to be 1's (neg)
		add $a2, $a2, $t0
		#a2 now has the sign extended value
		
	cont_find_position:
	
		move $t0, $a0 #move the nodes array to t0
		li $t1, 4 #size of a node
		mul $t1, $t1, $a1 #4 * index => get the address
		add $t0, $t0, $t1 #base addr + offset
		lw $t1, ($t0) #load word the byte that has the value #keep this t1 - will need it later possibly
		andi $t2, $t1, 0x0000FFFF #get the lower 16 bits of the node (value)
		
		#we must check if the value is negative or positive and sign extend it
		andi $t3, $t2, 32768 #and it with the 16th bit, t3 will either by equal to 32768 (negative) or 0 (positive)
		beqz $t3, currIndexPositive
		j currIndexNegative
		
		currIndexPositive:
		
			li $t3, 0 #t3 will now hold the actual value of the curr Index
			add $t3, $t3, $t2 #add the lower 16 bits
			j checkIfNewValLess
			
		currIndexNegative:
		
			lui $t3, 0xFFFF #load the upper 16 bits of t3 with 1's
			add $t3, $t3, $t2 #add the lower 16 bits
			j checkIfNewValLess
		
	checkIfNewValLess:
	
		#t3 hold the sign extended value of the currIndex
		#a2 has the newValue (sign extended)
		#t1 has the node word
		#must check if the new val is less than the currIndex val
		
		blt $a2, $t3, isLessThan
		j isGreaterThan
		
		isLessThan:
		
			#we must get the left index from t1
			andi $t2, $t1, 0xFF000000 #and it to get the upper 8 bits (holds the left value)
			srl $t2, $t2, 24 #move it over 24 bits
			
			beq $t2, 255, isLessThan_return
			j isLessThan_recursive
			
			isLessThan_return:
			
				move $v0, $a1 #return the currIndex
				li $v1, 0 #indicates left child
				jr $ra
			
			isLessThan_recursive:
			
				addi $sp, $sp, -16
				sw $a0, ($sp)
				sw $a1, 4($sp)
				sw $a2, 8($sp)
				sw $ra, 12($sp)
			
				move $a0, $a0 #has the nodes address already
				move $a1, $t2 #has the index of the left node
				move $a2, $t7 #has the newValue
				
				jal find_position
				
				lw $a0, ($sp)
				lw $a1, 4($sp)
				lw $a2, 8($sp)
				lw $ra, 12($sp)
				addi $sp, $sp, 16
				
				jr $ra
		
		isGreaterThan:
		
			#we must get the right index from t1
			andi $t2, $t1, 0x00FF0000 #and it to get the bits (holds the right value)
			srl $t2, $t2, 16 #move it over 16 bits
			
			beq $t2, 255, isGreaterThan_return
			j isGreaterThan_recursive
			
			isGreaterThan_return:
			
				move $v0, $a1 #return the currIndex
				li $v1, 1 #indicates left child
				jr $ra
			
			isGreaterThan_recursive:
			
				addi $sp, $sp, -16
				sw $a0, ($sp)
				sw $a1, 4($sp)
				sw $a2, 8($sp)
				sw $ra, 12($sp)
			
				move $a0, $a0 #has the nodes address already
				move $a1, $t2 #has the index of the right node
				move $a2, $t7 #has the newValue
				
				jal find_position
				
				lw $a0, ($sp)
				lw $a1, 4($sp)
				lw $a2, 8($sp)
				lw $ra, 12($sp)
				addi $sp, $sp, 16
				
				jr $ra
	
		

add_node:

	#a0 is is the nodes[] Nodes array
	#a1 is the int rootIndex
	#a2 is the int newValue
	#a3 is the int newIndex
	#a4 is the byte[] flags array
	#a5 is the int maxSize
	
	lw $t0, ($sp) #holds the int maxSize
	lw $t1, 4($sp) #holds the byte[] flags array
	#do not restore the stack, leave it the way it is
	
	move $t2, $a1 #move the rootIndex to t2, need to discard the upper 24
	andi $t2, $t2, 0x000000FF
	
	move $t3, $a3 #move the newIndex to t3, need to discard the upper 24 bits
	andi $t3, $t3, 0x000000FF
	
	bge $t2, $t0, error_add_node
	bge $t3, $t0, error_add_node
	
	andi $t4, $a2, 0x0000FFFF #get the lower 16 bits of the node value

	#we must check if the value is neg or pos and sign extend it
	andi $t5, $t4, 32768 #get the 16th bit
	beqz $t5, newValPositive
	j newValNegative
	
	newValPositive:
	
		li $t5, 0 #t5 will now hold the actual value of the new value
		add $t5, $t5, $t4 #add the lower 16 bits
		move $t4, $t5 #keep t registers in order
		j check_root
	
	newValNegative:
	
		lui $t5, 0xFFFF #load the upper 16 bits with 1's
		add $t5, $t5, $t4 #add the lower 16 bits
		move $t4, $t5 #keep t registers in order
		j check_root
		
	check_root:
	
		#we must check if the root index is set in the flags array or not to know if its valid/exists
		#t0-t4 are occupied, must use t5
		move $t5, $t1 #Move the byte array to t5 for processing
		move $t6, $t2 #Move the rootindex to t6 to get the hi and lo
		li $t7, 8 #used to divide
		div $t6, $t7 #rootIndex / 8, lo has the index in the byte array and hi has the bit
		mflo $t6 #has the index
		mfhi $t7 #has the bit pos
		add $t5, $t5, $t6 #move to the byte by adding to the base addr
		lb $t6, ($t5) #get the byte
		ror $t6, $t6, $t7 #rotate it so that the bit we want is at pos 0
		andi $t6, $t6, 1 #get the lsb - contains the root index bit - must check if its 0 or 1
		move $t5, $t6 #move it into t5 to keep the registers in order
		
		beqz $t5, nonValidRoot
		j validRoot
		
		
		
		validRoot:
		#if its valid:
		addi $sp, $sp, -40
		sw $a0, ($sp)
		sw $a1, 4($sp)
		sw $a2, 8($sp)
		sw $a3, 12($sp)
		sw $ra, 16($sp)
		sw $t0, 20($sp)
		sw $t1, 24($sp)
		sw $t2, 28($sp)
		sw $t3, 32($sp)
		sw $t4, 36($sp)
		
		jal find_position
		
		move $t5, $v0 #hold the parent index
		move $t6, $v1 #holds whether it is left or right child (0 = left, 1 = right)
		
		lw $a0, ($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		lw $a3, 12($sp)
		lw $ra, 16($sp)
		lw $t0, 20($sp)
		lw $t1, 24($sp)
		lw $t2, 28($sp)
		lw $t3, 32($sp)
		lw $t4, 36($sp)
		addi $sp, $sp, 40
		
		#we must check if the node is a left or right child
		beqz $t6, leftChild
		j rightChild
		
		leftChild:
		
			move $t6, $a0 #move the nodes array to t6 to get the offset
			li $t7, 4
			mul $t7, $t7, $t5 #get the address where the parent index is
			add $t6, $t6, $t7 #add offset to the address
			lw $t7, ($t6) #get the word/node
			#t3 has the newIndex in the form 0x000000FF, we want this to be moved to 0xFF000000
			sll $t3, $t3, 24 #move it over 24 bits
			andi $t7, $t7, 0x00FFFFFF
			or $t7, $t7, $t3 #change the left index of the node, we must store it back
			sw $t7 ($t6)
			srl $t3, $t3, 24
			j insertedNode
		
		rightChild:
		
			move $t6, $a0 #move the nodes array to t6 to get the offset
			li $t7, 4
			mul $t7, $t7, $t5 #get the address where the parent index is
			add $t6, $t6, $t7 #add offset to the address
			lw $t7, ($t6) #get the word/node
			#t3 has the newIndex in the form 0x000000FF, we want this to be moved to 0x00FF0000
			sll $t3, $t3, 16 #move it over 16 bits
			andi $t7, $t7, 0xFF00FFFF
			or $t7, $t7, $t3 #change the left index of the node, we must store it back
			sw $t7 ($t6)
			srl $t3, $t3, 16 #move it back because we need this to get the next address offset
			j insertedNode
			
		
		nonValidRoot:
		
			move $a3, $a1 #move the root index arg to the new Index
			move $t3, $t2 #also move the truncated root index to new index
			j insertedNode
		
			
		insertedNode:
		
			li $t7, 4
			mul $t7, $t7, $t3 #get the address of where the child node is
			move $t6, $a0 #move the nodes array to here
			add $t6, $t6, $t7 #add the offset to the address
			lw $t7, ($t6) #get the word from the address
			lui $t7, 0xFFFF #load the upper 16 bits with 1's (255 for left and right node indices)
			andi $t4, $t4, 0x0000FFFF #need to get the lower 16 bits of the new value to put into the node
			add $t7, $t7, $t4 #add the value to the node
			sw $t7, ($t6) #store it back into the nodes array
	 	
	 	call_set_flag:
	 	
	 		addi $sp, $sp, -4
	 		sw $ra, ($sp)
	 		
	 		move $a0, $t1 #move the flag to the arg 1
	 		move $a1, $t3 #holds the index /byte in the byte array
	 		li $a2, 1 #change the bit to 1
	 		move $a3, $t0 #has the maxSize
	 		
	 		jal set_flag
	 		
	 		lw $ra, ($sp)
	 		addi $sp, $sp, 4
	 		
	 		#v0 has the return already
	 		jr $ra
	 	
	 	error_add_node:
	 	
	 		li $v0, 0
	 		jr $ra
	 		
	




get_parent:

	reset_reg
	
	#a0 has the nodes array
	#a1 has the int currIndex
	#a2 has the int childValue (the value of the child node)
	#a3 has the int childIndex (the index of the child node)
	#childIndex must have the same value as childValue incase there r nodes with duplicate values
	
	#childIndex = toUnsignedByte(childIndex)
	move $t0, $a3 #need to get the byte
	andi $t0, $t0, 0x000000FF #this gets the byte value
	
	#childValue = signedHalfWorld(childValue)
	#sign extension
	move $t1, $a2 #get the 16th bit from t1
	andi $t1, $t1, 32768 #either 1 (neg) or 0 (pos)
	
	beqz $t1, childValPos
	j childValNeg
	
	childValPos:
	
		move $t1, $a2
		andi $t1, $t1, 0x0000FFFF #make the upper 16 bits 0's, leave the lower 16
		j getparent_mainif
	
	childValNeg:
	
		move $t1, $a2 #move the value into t1
		andi $t1, $t1, 0x0000FFFF #get the lower 16 bits
		lui $t2, 0xFFFF #load the upper 16 bits of t2 with 1's
		add $t2, $t2, $t1 #add the lower 16 bits
		move $t1, $t2 #put t2 into t1 to keep registers ordered
		#t1 holds the sign extended childValue
		j getparent_mainif
		
	getparent_mainif:
	
		#t1 holds the childValue
		li $t2, 4
		move $t3, $a1 #move the curr index to t3, need to mul by 4
		mul $t3, $t3, $t2 #currIndex * 4
		move $t2, $a0 #get the nodes array into t2 (dont need t2 to hold 4 anymore)
		add $t2, $t2, $t3 #gets the offset of the nodes array to where currIndex is
		#t2 contains currNodeAddr, keep this for later
		lw $t3, ($t2) #get the node from the array, we must get the value of it
		andi $t3, $t3, 32768 #get the 16th bit to check if neg or pos
		
		beqz $t3, currIndexPos
		j currIndexNeg
		
		currIndexPos:
		
			lw $t3, ($t2) #get the node again
			andi $t3, $t3, 0x0000FFFF #get the value, is pos so no sign extension
			j getparent_mainif_check
			
		currIndexNeg:
		
			lw $t3, ($t2) #get the node again
			lui $t4, 0xFFFF #load the upper 16 bits with 1's
			andi $t3, $t3, 0x0000FFFF #get the lower 16 bits of the node
			add $t4, $t4, $t3 #add the lower 16 bits
			move $t3, $t4 #move the value to t3, t0 has the childIndex, t1 has the childVal and t2 has currNodeAddr
			j getparent_mainif_check
	
		getparent_mainif_check:
		
			blt $t1, $t3, getparent_lessthan #if the childVal < currNode value
			j getparent_greaterthan
			
			getparent_lessthan:
			
				lw $t3, ($t2) #get the node again, need the left index of the node
				andi $t3, $t3, 0xFF000000 #gets the left index
				srl $t3, $t3, 24 #shift it 24 bits to the right to get it in the first 2 positions
				beq $t3, 255, getparent_lessthan_equal255
				beq $t3, $t0, getparent_lessthan_equalChildIndex
				j getparent_lessthan_recursive
				
				getparent_lessthan_equal255:
				
					li $v0, -1
					li $v1, -1 #dont care
					jr $ra
				
				getparent_lessthan_equalChildIndex:
				
					move $v0, $a1 #currIndex
					li $v1, 0
					jr $ra
				
				getparent_lessthan_recursive:
				
					#a0 is the same
					#a2 is the same
					#a3 is the same
					#a1 has the currIndex and should be replaced with the leftIndex
					addi $sp, $sp, -4
					sw $ra, ($sp)
					
					move $a1, $t3
					jal get_parent
					
					lw $ra, ($sp)
					addi $sp, $sp, 4
					
					
					jr $ra
			
			getparent_greaterthan:
			
				lw $t3, ($t2) #get the node again, need the right index of the node
				andi $t3, $t3, 0x00FF0000 #gets the right index
				srl $t3, $t3, 16 #shift it 16 bits to the right to get it in the first 2 positions
				beq $t3, 255, getparent_greaterthan_equal255
				beq $t3, $t0, getparent_greaterthan_equalChildIndex
				j getparent_greaterthan_recursive
				
				getparent_greaterthan_equal255:
				
					li $v0, -1
					li $v1, -1 #dont care
					jr $ra
				
				getparent_greaterthan_equalChildIndex:
				
					move $v0, $a1 #currIndex
					li $v1, 1
					jr $ra
				
				getparent_greaterthan_recursive:
				
					#a0 is the same
					#a2 is the same
					#a3 is the same
					#a1 has the currIndex and should be replaced with the leftIndex
					addi $sp, $sp, -4
					sw $ra, ($sp)
					
					move $a1, $t3
					jal get_parent
					
					lw $ra, ($sp)
					addi $sp, $sp, 4
					
					
					jr $ra


find_min:

	#a0 has the nodes array
	#a1 has the currIndex
	reset_reg
	
	li $t0, 4 #will be used to multiply the currIndex to get the base offset
	mul $t1, $a1, $t0 #t1 holds the offset
	move $t0, $a0 #holds the nodes array
	add $t0, $t0, $t1 #has the offset with the currIndex
	
	lw $t1, ($t0) #get the node at that position
	
	andi $t1, $t1, 0xFF000000 #get the left index from the node
	srl $t1, $t1, 24 #shift it to the right
	
	beq $t1, 255, find_min_return
	j find_min_recursive
	
	find_min_return:
	
		move $v0, $a1 #move the currIndex into v0
		lw $t1, ($t0) #get the node again, need to check if its a leaf
		andi $t1, $t1, 0xFFFF0000 #get the left AND right child index, must check if it equals 0xffff0000
		sll $t1, $t1, 16
		li $7, 65535
		beq $t1, $t7, find_min_return_isLeaf
		j find_min_return_isntLeaf
		
		find_min_return_isLeaf:
		
			li $v1, 1
			jr $ra
		
		find_min_return_isntLeaf:
		
			li $v1, 0
			jr $ra
	
	find_min_recursive:
	
		move $a1, $t1 #move the leftIndex into the currIndex
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		jal find_min
		
		lw $ra, ($sp)
		addi $sp, $sp, 4
		
		jr $ra



delete_node:

	reset_reg
	#a0 has the nodes array
	#a1 has the int rootIndex
	#a2 has the int deleteIndex
	#a3 has the byte[] flags array
	#t0 has the maxSize
	lw $t0, ($sp) #get the 5th arg off of the stack
	
	move $t1, $a1 #move the root index
	#rootindex = toUnsignedByte(rootindex)
	andi $t1, $t1, 0x000000FF #gets the lower byte of the root index
	
	move $t2, $a2 #move the deleteIndex
	#deleteIndex = toUnsignedByte(deleteIndex)
	andi $t2, $t2, 0x000000FF #get the lower byte of the delete index
	
	bge $t1, $t0, delete_node_error
	bge $t2, $t0, delete_node_error
	#if either root index or delete index are >= the max Size throw an error (return 0)
	
	#we must determine if the node at rootIndex and deleteIndex actually exist (check the flags array)
	#t0, t1, t2 are all occuppied
	
	checkIfRootExists:
	
		move $t3, $a3 #move the flags array here to get the offset
		li $t4, 8 #used to divide the indices
		move $t5, $t1 #move the rootindex so it can be divided
		div $t5, $t4 #index /8
		mflo $t4 #t4 holds the index to go to
		mfhi $t5 #t5 holds the bit we want to check
		
		add $t3, $t3, $t4 #add to the base addr to go to the byte
		lb $t4, ($t3) #dont need t4, so load byte into it from the flags array
		ror $t4, $t4, $t5 #rotate it to the right so that the LSB is the bit we want to check (the root index)
		andi $t4, $t4, 1 #get the LSB
		#if its not valid, we want to jump to error, else check the deleteIndex
		beqz $t4, delete_node_error
		j checkIfDeleteIndexExists
		
	checkIfDeleteIndexExists:
	
		move $t3, $a3 #move the flags array to get the offset
		li $t4, 8 #used ot divide
		move $t5, $t1 #move the deleteIndex so it can be divided
		div $t5, $t4 #deleteIndex /8
		mflo $t4 #holds the byte index ot go to 
		mfhi $t5 #holds the bit we want to check
		
		add $t3, $t3, $t4 #add the base addr
		lb $t4, ($t3) #dont need t4, load byte of flag
		ror $t4, $t4, $t5 #rotate it to the lsb
		andi $t4, $t4, 1 #get the lsb
		beqz $t4, delete_node_error
		j checkIfLeafOrOneChild
		
	checkIfLeafOrOneChild:
	
		#t0-t2 are occupied
		li $t3, 4 #used to mul the idnex to get the offset
		mul $t3, $t3, $t2 #t2 has the delete index, store offset into t3
		move $t4, $a0 #move the nodes array into t4
		add $t4, $t4, $t3 #add the offset to the base nodes array addr
		lw $t5, ($t4) #get the node, need to check if its a leaf, has 1 child, or 'else'
		
		andi $t6, $t5, 0xFFFF0000 #get the left and right index
		srl $t6, $t6, 16 #move it over 16 bits to check
		li $t9, 65535
		beq $t6, $t9, deletenode_noChildren
		
		andi $t6, $t5, 0xFF000000 #get just the left child and check if it has 1 child
		srl $t6, $t6, 24 #move it over to the lsb
		beq $t6, 255, deletenode_oneChild
		
		andi $t6, $t5, 0x00FF0000 #get the right child and check if it has 1 child
		srl $t6, $t6, 16 #move it over ot the lsb
		beq $t6, 255, deletenode_oneChild
		
		j deletenode_twoChildren
		
		deletenode_noChildren:
		
			addi $sp, $sp, -32
			sw $a0, ($sp)
			sw $a1, 4($sp)
			sw $a2, 8($sp)
			sw $a3, 12($sp)
			sw $t0, 16($sp)
			sw $t1, 20($sp)
			sw $t2, 24($sp)
			sw $ra, 28($sp)
			
			move $a0, $a3 #move the flags array to a0 for set_flag func
			move $a1, $t2 #move the delete index to a1
			li $a2, 0 #we want to change the bit to 0
			move $a3, $t0 #move maxSize to a3
			
			jal set_flag
			
			lw $a0, ($sp)
			lw $a1, 4($sp)
			lw $a2, 8($sp)
			lw $a3, 12($sp)
			lw $t0, 16($sp)
			lw $t1, 20($sp)
			lw $t2, 24($sp)
			lw $ra, 28($sp)
			addi $sp, $sp, 32
			
			beq $t1, $t2, deletenode_noChildren_rootEqualDeleteIndex #rootIndex == deleteIndex?
			j deletenode_noChildren_checkDeleteIndex
			
			deletenode_noChildren_rootEqualDeleteIndex:
			
				li $v0, 1
				jr $ra
			
			deletenode_noChildren_checkDeleteIndex:
			
			#for the get_parent method call we need nodes[deleteIndex].value
			#this includes check if pos or neg and sign extending it
			
			move $t3, $a0 #move the nodes array into t3 for the base addr
			li $t4, 4 #used to muliply to index to get the offset
			mul $t4, $t4, $t2 #deleteIndex * 4
			add $t3, $t3, $t4 #add the offset to the base addr
			lw $t4, ($t3) #get the word/node from the array
			
			andi $t4, $t4, 32768 #ge tthe 16th bit
			beqz $t4, deletenode_noChildren_deleteIndexPos
			j deletenode_noChildren_deleteIndexNeg
			
			deletenode_noChildren_deleteIndexPos:
				
				lw $t4, ($t3) #get the node again - we want the value
				andi $t4, $t4, 0x0000FFFF #this gets the positive value 
				j deletenode_noChildren_callGetParent
							
			deletenode_noChildren_deleteIndexNeg:
			
				lw $t4, ($t3) #get the node again - we want the value
				andi $t4, $t4, 0x0000FFFF #get the value
				lui $t5, 0xFFFF #load the upper 16 bits with 1's
				add $t5, $t5, $t4 #add the lower 16 bits
				move $t4, $t5 #move the t5 to t4 to keep in order
				j deletenode_noChildren_callGetParent
				
			deletenode_noChildren_callGetParent:
			
			addi $sp, $sp, -36
			sw $a0, ($sp)
			sw $a1, 4($sp)
			sw $a2, 8($sp)
			sw $a3, 12($sp)
			sw $t0, 16($sp)
			sw $t1, 20($sp)
			sw $t2, 24($sp)
			sw $ra, 28($sp)
			sw $t3, 32($sp)
			
			#a0 already has the nodes array
			move $a1, $t1 #move the rootIndex to a1
			move $a2, $t4 #move the calculated value t4 to a2
			move $a3, $t2 #move the deleteindex to a3
			
			jal get_parent
			
			move $t4, $v0 #move the parentIndex to t4
			move $t5, $v1 #move the left/right indicator to t5
			
			lw $a0, ($sp)
			lw $a1, 4($sp)
			lw $a2, 8($sp)
			lw $a3, 12($sp)
			lw $t0, 16($sp)
			lw $t1, 20($sp)
			lw $t2, 24($sp)
			lw $ra, 28($sp)
			lw $t3, 32($sp)
			addi $sp, $sp, 36
			
			beqz $t5, deletenode_noChildren_deleteLeft
			j deletenode_noChildren_deleteRight
			
			deletenode_noChildren_deleteLeft:
			
				li $t6, 4 #used to mul to get the offset
				mul $t6, $t6, $t4 #parentIndex * 4
				move $t7, $a0 #move the nodes array to t7
				add $t7, $t7, $t6 #add the offset to t7
				lw $t6, ($t7) #get the node
				andi $t6, $t6, 0x00FFFFFF #turn the left index to zero first
				ori $t6, $t6, 0xFF000000 #turn the left index to 255
				sw $t6, ($t7)
				
				li $v0, 1
				jr $ra
			
			deletenode_noChildren_deleteRight:
			
				li $t6, 4 #used to mul to get the offset
				mul $t6, $t6, $t4 #parentIndex * 4
				move $t7, $a0 #move the nodes array to t7
				add $t7, $t7, $t6 #add the offset to t7
				lw $t6, ($t7) #get the node
				andi $t6, $t6, 0xFF00FFFF #turn the left index to zero first
				ori $t6, $t6, 0x00FF0000 #turn the left index to 255
				sw $t6, ($t7)
				
				li $v0, 1
				jr $ra
		
		deletenode_oneChild:
		
			#t0-t2 have important info
			#t4 already has the nodes array at the index of deleteIndex
			
			lw $t3, ($t4) #get the node, must check if it has a left or right child
			andi $t3, $t3, 0xFF000000 #this gets the left child
			srl $t3, $t3, 24 #shift it over 24 bits to make it 255
			
			beq $t3, 255, deletenode_oneChild_isRight
			j deletenode_oneChild_isLeft
			
			deletenode_oneChild_isLeft:
			
				lw $t3, ($t4) #get the node
				andi $t3, $t3, 0xFF000000 #get the left index
				srl $t3, $t3, 24 #move it over 24 bits
				j deletenode_oneChild_checkIfRootEqualDelete
			
			deletenode_oneChild_isRight:
			
				lw $t3, ($t4) #get the node
				andi $t3, $t3, 0x00FF0000 #get the right index
				srl $t3, $t3, 16 #move it over 16 bits to make it LSB
				j deletenode_oneChild_checkIfRootEqualDelete
				#t3 has the childindex
				
			deletenode_oneChild_checkIfRootEqualDelete:
			
				beq $t1, $t2, deletenode_oneChild_RootEqualsDelete #does the rootindex = deleteindex?
				j deletenode_oneChild_callGetParent
				
				deletenode_oneChild_RootEqualsDelete:
				
					#t3 has the child index 
					li $t4, 4
					mul $t4, $t4, $t3 #get the offset by 4 * childindex
					move $t5, $a0 #move the nodes array to t5
					add $t5, $t5, $t4 #add the offset to t5
					move $t4, $t5 #keep registers consistent
					
					lw $t5, ($t4) #get the node from childIndex, need to store in deleteIndex
					
					li $t4, 4
					mul $t4, $t4, $t2 #deleteIndex * 4
					move $t6, $a0 #move the nodes array to t6
					add $t6, $t6, $t4 #add the offset to the base addr
					sw $t5, ($t6) #put the node that we got from childindex into deleteindex
					
					addi $sp, $sp, -4
					sw $ra, ($sp)
					
					move $a0, $a3 #move the flags array into the first arg
					move $a1, $t3 #move the child index into arg 2
					li $a2, 0 #change bit to 0
					move $a3, $t0 #move the maxSize into arg 4
					
					jal set_flag
					
					lw $ra, ($sp)
					addi $sp, $sp, 4
					
					li $v0, 1
					jr $ra
				
				deletenode_oneChild_callGetParent:
				
					#t1 - rootIndex, t2 - deleteIndex, t3 - childIndex, t4 - addr of delete index
					#need to get the value of the the addr at delete index
					lw $t5, ($t4) #get the node
					andi $t5, $t5, 0x0000FFFF #get just the value of the node
					
					addi $sp, $sp, -40
					sw $a0, ($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
					sw $a3, 12($sp)
					sw $t0, 16($sp)
					sw $t1, 20($sp)
					sw $t2, 24($sp)
					sw $t3, 28($sp)
					sw $t4, 32($sp)
					sw $ra, 36($sp)
					
					#a0 already has the nodes array
					move $a1, $t1 #move theroot index
					move $a2, $t5 #move the node value
					move $a3, $t2 #move the delete index
					
					jal get_parent
					
					move $t5, $v0 #has the parentIndex
					move $t6, $v1 #has an indicator of left or right child
					
					lw $a0, ($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					lw $a3, 12($sp)
					lw $t0, 16($sp)
					lw $t1, 20($sp)
					lw $t2, 24($sp)
					lw $t3, 28($sp)
					lw $t4, 32($sp)
					lw $ra, 36($sp)
					addi $sp, $sp, 40
					
					beqz $t6, deletenode_oneChild_getParentLeft
					j deletenode_oneChild_getParentRight
					
					deletenode_oneChild_getParentLeft:
					
						li $t6, 4
						mul $t6, $t6, $t5 #parentIndex * 4
						move $t5, $a0 #move the nodes array to t5
						add $t5, $t5, $t6 #add the offset
						lw $t6, ($t5) #get the node
						andi $t6, $t6, 0x00FFFFFF #set the left index to 0
						#t3 currently holds the childIndex at the lsb, need to move it to the msb
						sll $t3, $t3, 24 #move it 24 bits up
						add $t6, $t6, $t3 #or it to make the upper 8 bits the new childIndex
						sw $t6, ($t5)
						j deletenode_oneChild_callSetFlag
					
					deletenode_oneChild_getParentRight:
					
						li $t6, 4
						mul $t6, $t6, $t5 #parentIndex * 4
						move $t5, $a0 #move the nodes array to t5
						add $t5, $t5, $t6 #add the offset
						lw $t6, ($t5) #get the node
						andi $t6, $t6, 0xFF00FFFF #set the left index to 0
						#t3 currently holds the childIndex at the lsb, need to move it to the msb
						sll $t3, $t3, 16 #move it 24 bits up
						add $t6, $t6, $t3 #or it to make the upper 8 bits the new childIndex
						sw $t6, ($t5)
						j deletenode_oneChild_callSetFlag
					
					deletenode_oneChild_callSetFlag:
					
						addi $sp, $sp, -4
						sw $ra, ($sp)
						
						move $a0, $a3 #move the flag array to arg 1
						move $a1, $t2 #move the delete index to arg 2
						li $a2, 0
						move $a3, $t0 #move the maxsize to arg 4
						
						jal set_flag
						
						lw $ra, ($sp)
						addi $sp, $sp, 4
						
						li $v0, 1
						jr $ra
		
		deletenode_twoChildren:
		
			#t0-t2 have values in them
			addi $sp, $sp, -32
			sw $a0, ($sp)
			sw $a1, 4($sp)
			sw $a2, 8($sp)
			sw $a3, 12($sp)
			sw $t0, 16($sp)
			sw $t1, 20($sp)
			sw $t2, 24($sp)
			sw $ra, 28($sp)
			
			#a0 already has nodes
			#a1 has to be nodes[deleteIndex].right
			
			move $t3, $a0 #move the nodes array to t3
			li $t4, 4 #used to mul the deleteIndex
			mul $t4, $t4, $t2 #deleteIndex * 4
			add $t3, $t3, $t4 #base addr + offset
			lw $t4, ($t3) #get the node - we need the right index
			andi $t3, $t4, 0x00FF0000 #gets the right index byte
			srl $t3, $t3, 16 #move it over 16 bits
			
			move $a1, $t3 #move the index to a1 to call find_min
			
			jal find_min
			
			lw $a0, ($sp)
			lw $a1, 4($sp)
			lw $a2, 8($sp)
			lw $a3, 12($sp)
			lw $t0, 16($sp)
			lw $t1, 20($sp)
			lw $t2, 24($sp)
			lw $ra, 28($sp)
			addi $sp, $sp, 32
			
			move $t3, $v0 #holds the minIndex
			move $t4, $v0 #holds an indicator if it is left or right
			
			#we must now call getparent
			addi $sp, $sp, -40
			sw $a0, ($sp)
			sw $a1, 4($sp)
			sw $a2, 8($sp)
			sw $a3, 12($sp)
			sw $t0, 16($sp)
			sw $t1, 20($sp)
			sw $t2, 24($sp)
			sw $ra, 28($sp)
			sw $t3, 32($sp)
			sw $t4, 36($sp)
			
			#a0 already has nodes
			move $a1, $t2 #move the deleteIndex to arg 2
			
			#we have to get nodes[minIndex].value
			li $t5, 4
			mul $t5, $t5, $t3 #4 * minIndex
			move $t6, $a0 #holds the nodes array
			add $t5, $t5, $t6 #holds the addr where the index is minIndex
			lw $t6, ($t5) #get the node
			andi $t6, $t6, 0x0000FFFF #getht evalue of the node
			move $t5, $t6 #put it in t5 to keep register consistency
			
			move $a2, $t5 #move into arg 3
			move $a3, $t3 #move minIndex into arg 4
			
			jal get_parent
			
			move $t5, $v0 #has the parentIndex
			move $t6, $v1 #has whether it is left or right child
			
			lw $a0, ($sp)
			lw $a1, 4($sp)
			lw $a2, 8($sp)
			lw $a3, 12($sp)
			lw $t0, 16($sp)
			lw $t1, 20($sp)
			lw $t2, 24($sp)
			lw $ra, 28($sp)
			lw $t3, 32($sp)
			lw $t4, 36($sp)
			addi $sp, $sp, 40
			
			#must check if the minimum node is a leaf or not
			#t3 holds the minIndex
			li $t7, 4
			mul $t7, $t7, $t3 #minIndex * 4
			move $t8, $a0 #move the nodes array to t8
			add $t8, $t8, $t7 #add the offset to it
			lw $t7, ($t8) #get the node
			andi $t7, $t7, 0xFFFF0000 #get the left and right index together
			srl $t7, $t7, 16 #move it over 16 bits
			li $t8, 65535
			beq $t7, $t8, deletenode_twoChildren_minIsLeaf
			j deletenode_twoChildren_minIsntLeaf
			
			deletenode_twoChildren_minIsLeaf:
			
				beqz $t6, deletenode_twoChildren_minIsLeaf_left
				j deletenode_twoChildren_minIsLeaf_right
				
				deletenode_twoChildren_minIsLeaf_left:
				
					#t5 has the parent index
					#nodes[parentIndex].left = 255
					li $t7, 4
					mul $t7, $t7, $t5 #parentIndex * 4
					move $t8, $a0 #move the nodes array
					add $t8, $t8, $t7 #add the offset
					lw $t7, ($t8) #get the node
					andi $t7, $t7, 0x00FFFFFF #make the left index zero
					ori $t7, $t7, 0xFF000000 #make the left idnex val 255
					sw $t7, ($t8) #store it back
					j deletenode_twoChildren_callSetFlag
				
				deletenode_twoChildren_minIsLeaf_right:
				
					#t5 has the parent index
					#nodes[parentIndex].right = 255
					li $t7, 4
					mul $t7, $t7, $t5 #parentIndex * 4
					move $t8, $a0 #move the nodes array
					add $t8, $t8, $t7 #add the offset
					lw $t7, ($t8) #get the node
					andi $t7, $t7, 0xFF00FFFF #make the left index zero
					ori $t7, $t7, 0x00FF0000 #make the left idnex val 255
					sw $t7, ($t8) #store it back
					j deletenode_twoChildren_callSetFlag
			
			deletenode_twoChildren_minIsntLeaf:
			
				beqz $t6, deletenode_twoChildren_minIsntLeaf_left
				j deletenode_twoChildren_minIsntLeaf_right
			
				deletenode_twoChildren_minIsntLeaf_left:
				
					#t5 has the parent index
					#nodes[parentIndex].left = 255
					li $t7, 4
					mul $t7, $t7, $t5 #parentIndex * 4
					move $t8, $a0 #move the nodes array
					add $t8, $t8, $t7 #add the offset
					lw $t7, ($t8) #get the node
					andi $t7, $t7, 0x00FFFFFF #make the left index zero
					
					#we emptied the parentIndex's left index
					#now we must get nodes[minIndex].right
					#we dont need t6 for anything
					#we must preserver t7 and t8 (to store it back)
					
					li $t6, 4
					mul $t6, $t6, $t3 #4 * minIndex
					move $t9, $a0 #holds the nodes array
					add $t6, $t6, $t9 #add the offset to the nodes array
					lw $t9, ($t6)
					andi $t9, $t9, 0x00FF0000 #get the right index of the minIndex
					sll $t9, $t9, 8 #shift it 8 bits to add it to t7 as the left index
					add $t7, $t7, $t9 #t7 now has the new node
					
					sw $t7, ($t8) #store the node back into the array
					
					j deletenode_twoChildren_callSetFlag
				
				deletenode_twoChildren_minIsntLeaf_right:
				
					#t5 has the parent index
					#nodes[parentIndex].right = 255
					li $t7, 4
					mul $t7, $t7, $t5 #parentIndex * 4
					move $t8, $a0 #move the nodes array
					add $t8, $t8, $t7 #add the offset
					lw $t7, ($t8) #get the node
					andi $t7, $t7, 0xFF00FFFF #make the left index zero
					
					#we emptied the parentIndex's left index
					#now we must get nodes[minIndex].right
					#we dont need t6 for anything
					#we must preserver t7 and t8 (to store it back)
					
					li $t6, 4
					mul $t6, $t6, $t3 #4 * minIndex
					move $t9, $a0 #holds the nodes array
					add $t6, $t6, $t9 #add the offset to the nodes array
					lw $t9, ($t6)
					andi $t9, $t9, 0x00FF0000 #get the right index of the minIndex
					add $t7, $t7, $t9 #t7 now has the new node
					
					sw $t7, ($t8) #store the node back into the array
					
					j deletenode_twoChildren_callSetFlag
			
			deletenode_twoChildren_callSetFlag:
			
				#we do not need parentIndex anymore
				#available registers: 4 5 6 7 8 9
				
				move $t4, $a0 #move the nodes array to t4
				li $t5, 4
				mul $t5, $t5, $t2 #deleteIndex * 4
				add $t4, $t4, $t5 #add the base + offset
				#t4 has the addr of deleteIndex node
				
				move $t5, $a0 #move the nodes array to t5
				li $t6, 4
				mul $t6, $t6, $t3 #minIndex * 4
				add $t5, $t5, $t6 #base + offset
				#t5 has the minIndex node
				
				lw $t6, ($t4) #deleteIndex node
				lw $t7, ($t5) #minIndex node
				
				andi $t6, $t6, 0xFFFF0000 #remove the value of t6
				andi $t7, $t7, 0x0000FFFF #get the value of t7
				add $t6, $t6, $t7 #add the val of t7 to t6
				
				sw $t6, ($t4) #store the deleteIndex node back into the addr
				
				addi $sp, $sp, -4
				sw $ra, ($sp)
				
				move $a0, $a3 #move the flags array
				move $a1, $t3 #mvoe the minIndex to a1
				li $a2, 0
				move $a3, $t0 #move the max Size
				
				jal set_flag
				
				lw $ra, ($sp)
				addi $sp, $sp, 4
				
				li $v0, 1
				jr $ra
			
		
		delete_node_error:
		
			li $v0, 0
			jr $ra
	
	



.data
.align 2  # Align next items to word boundary

nl: .ascii "\n" #new line char
neg: .ascii "-" #negative symbol
word: .word 1


