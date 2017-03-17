.text
.globl main

main:

	la $a0, bst_1
	li $a1, 0
	li $a2, 8	# delete 13
	la $a3, flag_bst_1
	addi $sp, $sp, -4
	li $t0, 10
	lw $t0, 0($sp)
	jal delete_node
	addi $sp, $sp, 4

	# print return value
	move $a0, $v0
	li $v0, 1
	syscall

	# print 2 newline
	li $v0, 4
	la $a0, endl
	syscall
	syscall



	la $a0, bst_1
	li $a1, 0
	li $a2, 6	# delete 10
	la $a3, flag_bst_1
	addi $sp, $sp, -4
	li $t0, 10
	lw $t0, 0($sp)
	jal delete_node
	addi $sp, $sp, 4
	# print return value
	move $a0, $v0
	li $v0, 1
	syscall
	# print 2 newline
	li $v0, 4
	la $a0, endl
	syscall
	syscall

done:
	li $v0, 10
	syscall

.data
endl: .asciiz "\n"
.align 2

nodes2: .word 0x01060008 0x02030003 0xFFFF0001 0x04050006 0xFFFF0004 0xFFFF0007 0xFF07000A 0x08FF000E 0xFFFF000D #root 0, sample tree

# Additional testing cases
nodes1: .word 0xFFFF0001 # root node with 0 children - root 0
nodes3: .word 0x01FF0001 0xFFFF0002 # root node with 1 left child - root 0
nodes4: .word 0xFF010001 0xFFFF0003 # root node with 1 right child - root 0
nodes5: .word 0xFF030001 0xFFFF000F 0xFF010007 0xFF020003 # completely unbalanced tree - linked list to right (with nodes mixed up) - root 0
nodes6: .word 0x02FF0001 0x03FF0004 0x01FF0002 0xFFFF0008 # completely unbalanced tree - linked list to left (with nodes mixed up) - root 0
nodes7: .word 0x01060008 0x0203FFFD 0xFFFF0001 0x0405FFFA 0xFFFF0004 0xFFFFFFF9 0xFF07000A 0x08FFFFF2 0xFFFF000D # sample tree w/ negative nodes - root 0
nodes8: .word 0xFFFF0004 0x02030003 0xFFFF0001 0x00050006 0x01060008 0xFFFF0007 0xFF07000A 0x08FF000E 0xFFFF000D # sample tree - root 4


.align 2
alloc_size: .word 255 #maxSize of alloc_mem
to_byte_bound1: .space 1 # flag arrays pushed off word boundary
#GUARANTEED BYTE BOUNDARY, NOT WORD BOUNDARY, FOR FLAG ARRAYS
alloc_mem_flag_array: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		    	    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		    	    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		    	    0, 0	# 8 words = 32 bytes = 256 bits (1 bit not needed at end)

flag_array_0: .byte 0xFF, 0xFF, 0xFF, 0x3F
flag_array_size16: .byte 0x82, 0x44


.align 2
bst_1: .word 0x01060008 0x02030003 0x09FFFFFB 0x04050006 0xFFFF0004 0xFFFF0007 0xFF07000A 0x08FF000E 0xFFFF000D 0xFFFF8000 # root 0
	# all valid indices (filled)
	# maxSize = 10
	# preorder: 8 3 -5 -32768 6 4 7 10 14 13

# Additional testing cases
bst_2: .word 0xFED89999 0xF9041111 0xFFFF0002 0xFFFF0003 # root 2
	# only valid index = 2 (single root node)
	# maxSize = 4
	# preorder: 2
bst_3: .word 0xFED89999 0xF9041111 0xFF030002 0x05FF0005 0xFFFF0003 0xFF040002 # root 2
	# valid indices = 2,3,4.5 (single root node and right subtree)
	# maxSize = 6
	# preorder: 2 5 2 3
bst_4: .word 0xFED89999 0xF9041111 0x06030002 0x05FF0005 0xFFFF0003 0xFF040002 0x09070001 0xFFFF0001 0xFED77777 0xFFFFFFFF # root 2
	# valid indices = 2,3,4,5,6,7,9
	# maxSize = 10
	# preorder: 2 1 -1 1 5 2 3

to_byte_bound2: .space 1
flag_bst_1: .byte 0xFF, 0x0F # first 10 bits valid, rest ignored

# Additional testing cases
flag_bst_2: .byte 0xF4 # first 4 bits valid, rest ignored
flag_bst_3: .byte 0x3C # first 6 bits valid, rest ignored
flag_bst_4: .byte 0xFC, 0x02 # first 10 bits valid, rest ignored



.include "BST.asm"
