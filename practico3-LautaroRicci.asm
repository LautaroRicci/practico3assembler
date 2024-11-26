		.macro lee_entero
		li $v0, 5
		syscall
		.end_macro

		.macro imprimir_mensaje(%label)
		la $a0, %label
		li $v0, 4
		syscall
		.end_macro

		.macro finalizo
		li $v0,10
		syscall
		.end_macro	

		.macro imprimir_error(%errno)
		 imprimir_mensaje(error)
		li $a0, %errno
		li $v0, 1
		syscall
		 imprimir_mensaje(return)
		.end_macro
		
.data
slist: .word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu: .ascii "Colecciones de objetos categorizados\n"
.ascii "====================================\n"
.ascii "1-Nueva categoria\n"
.ascii "2-Siguiente categoria\n"
.ascii "3-Categoria anterior\n"
.ascii "4-Listar categorias\n"
.ascii "5-Borrar categoria actual\n"
.ascii "6-Anexar objeto a la categoria actual\n"
.ascii "7-Listar objetos de la categoria\n"
.ascii "8-Borrar objeto de la categoria\n"
.ascii "0-Salir\n"
.asciiz "Ingrese la opcion deseada: "
error: .asciiz "Error: "
return: .asciiz "\n"
catName: .asciiz "\nIngrese el nombre de una categoria: "
selCat: .asciiz "\nSe ha seleccionado la categoria: "
idObj: .asciiz "\nIngrese el ID del objeto a eliminar: "
objName: .asciiz "\nIngrese el nombre de un objeto: "
success: .asciiz "La operación se realizo con exito\n\n"
failure: .asciiz "La operacion NO se pudo realizar."
selected: .asciiz ">>"
idSymbol: .asciiz "-> "
thanks: .asciiz "Gracias!\n"

.text
main:
	# Inicialización del vector scheduler
	la $t0, schedv
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcategory
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcategory
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)

### Comienzo el Programa
main_loop:
	# muestro el menu
	jal menu_display
	beqz $v0, main_end
	addi $v0, $v0, -1	# decremento el ingreso del usuario por 1, ya que las opciones van del 0 al 7
	sll $v0, $v0, 2         # multiplico por 4 para obtener la opcion del menu
	la $t0, schedv # cargo la direccion del schev
	add $t0, $t0, $v0 # sumo el schedv y el ingreso del usuario (multiplicado por 4) para obtener la direccion de la funcion que corresponde
	lw $t1, ($t0) # cargo la direccion de la funcion en $t1
	la $ra, main_loop2 # cargo $ra para que el programa termine cuando no haya mas iteraciones 
	jr $t1 # salto a la funcion usando su direccion

main_loop2:
    j main_loop		

main_end:
	imprimir_mensaje(thanks)
	finalizo

menu_display:
	imprimir_mensaje(menu)
	lee_entero
	# verifica si es una opcion invalida y salta a L1
	bgt $v0, 8, menu_display_L1 # si v0 es mayor que 8 salta
	bltz $v0, menu_display_L1  # si v0 es menor que 0 salta
	# vuelve a la ejecucion del main loop, luego del jal menu_display
	jr $ra
	
menu_display_L1:
	imprimir_error(101)
	j menu_display
	
	##
	## FUNCION NUEVA CATEGORIA
	##
newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		# carga la direccion para el ingreso de una categoria por teclado
	jal getblock
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0			# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	imprimir_mensaje(success)
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

# $a0: Direccion de la lista
# $a1: NULL si es categoria, direccion del nodo si es objeto
# $v0: Direccion del nodo añadido

#
# FUNCION SIGUIENTE CATEGORIA 
#
nextcategory:
    lw $t0, wclist 
    beqz $t0, err201 	# no categories print error 201
    
    lw $t1, wclist 	 # wclist copy for compare
    lw $t0, 12($t0) # cargo la direccion del nodo siguiente
   
    beq $t0, $t1, err202 	# one category print error 202
    sw $t0, wclist 	# save wclist from register
    lw $t0, 8($t0) 
    imprimir_mensaje(selCat)
    la $a0, 0($t0) 	#print selected category
    li $v0, 4 	
    syscall 
    jr $ra
		
err201:
	imprimir_error(201)
	jr $ra

err202:
	imprimir_error(202)
	jr $ra

#
# FUNCION ANTERIOR CATEGORIA 
#
prevcategory:
	lw $t0, wclist

	beqz $t0, error201 # no hay categorias
	
	lw $t1, wclist #copia del wclist para comparar si es la unica categoria
	lw $t0, 0($t0) #cargo la direccion del puntero a la categoria anterior
	
	beq 	$t0, $t1, error202 # error unica categoria
	sw $t0, wclist # la direccion que hay en t0 la guardo en el nuevo workinglist 
	lw $t0, 8($t0) # cargo la direccion del string en esa categoria
	
	imprimir_mensaje(selCat)
	la $a0, 0($t0) # cargo la direccion del string en a0 para imprimir
	li $v0, 4
	syscall
	jr $ra

error201:
imprimir_error(201)
jr $ra

error202:
imprimir_error(202)
jr $ra


#
# FUNCION LISTAR CATEGORIAS
#
	listcategories:
	addi $sp, $sp, -4
	sw $ra, 8($sp) # guardo la direccion de retorno en $sp
	
	lw $t0, cclist # cargo el comienzo de la lista
	lw $t1, wclist # cargo la categoria actual
	beqz $t0, error201 # error si no hay categorias
	
	lw $t1, 8($t0) # cargo la direccion del string
	jal listcategories_loop
	
	listcategories_loop:
	la $a0, ($t1) # almaceno la direccion del string en a0 para imprimir
	li $v0, 4 # codigo para imprimir
	syscall # imprimo lo que hay en $t1 = direccion del string 0x1004000X

	addi $t1, $t1, 32 # sumo 32 para avanzar 0x20 en hexadecimal a la proxima direccion
	move $t2, $t1 # copio la direccion sumada en 32 a $t2
	lw $t1, 0($t1) #cargo la direccion del primero, es decir el string
	beq $t1, $0, loopcategories_finaliza # si la direccion esta vacia, voy a loop_finaliza el cual almacena en $ra, el ra de la pila para volver a imprimir el menu
	
	
	la $a0, ($t2) # cargo en $a0, la direccion del string a imprimir
	li $v0, 4 # codigo para imprimir
	syscall
	
	
	addi $t2, $t2, 32 # vuelvo a sumar 32
	lw $t3, 0($t2) # coloco en $t3, el string a imprimir
	move $t1, $t2 # muevo la direccion de $t2 a $t1
	bne $t3, $zero, listcategories_loop 

	loopcategories_finaliza:
	lw $ra, 8($sp) # vuelvo al $ra para terminar la ejecucion
	jr $ra
	
	sumar_32:
	addi $t1, $t1, 32
	jr $ra
	
#
# FUNCION ELIMINAR CATEGORIA
#
delcategory:
addiu $sp, $sp, -4
	sw $ra, 4($sp)		#stack pointer
	
	lw $t0, wclist
	beqz $t0, err401	# no categories print error 401
	
	lw $t0, 4($t0)		# pointer to object list
	beqz $t0, del_empty_cat	# empty cat delete
	
	lw $t1, wclist
	la $a1, 4($t1)
	jal del_objects_loop	# delete all objects and then category
	
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
	
	
del_objects_loop: 
	lw $t3, 12($t0)		# next node pointer
	add $a0, $0, $t0	# $a0 argument for delnode
	jal delnode
	move $t0, $t3		# move $t3 to $t0
	beq $a0, $t0, end_del_objects
	j del_objects_loop

end_del_objects:
    	j del_empty_cat          

del_empty_cat:
	lw $a0, wclist	# deleted category pointer
   	la $a1, cclist 	# pointer to list 
   	lw $t0, 12($a0)	
   	sw $t0, wclist     
	jal delnode
	
	imprimir_mensaje(success)
	lw $t1, cclist
	beqz $t1, wclist_reset	#if cclist = 0 / reset trash of wclist 
	
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
	
wclist_reset:
	sw $0, wclist
	lw $ra, 4($sp)
	addiu $sp, $sp, 4	
	jr $ra
err401:
	imprimir_error(401)
	jr $ra

#
# FUNCION AGREGAR OBJETO
#
newobject:
	lw $t0, wclist
	beqz $t0, err501    # no categories print error 401
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	
	la $a0, objName
	jal getblock		# get memory block
	
	move $a2, $v0
	lw $a0, wclist
	la $a0, 4($a0)
	lw $t0, 0($a0)
	beqz $t0, create_list		# if no objects create new list
	lw $t0, 0($t0)
	lw $t0, 4($t0)
	addi $a1, $t0, 1		# increments the old ID 
	
create_node:
	jal addnode	# add node subrutine
	lw $t0, wclist
	la $t0, 4($t0)
	beqz $t0, first_object		# first object link to the first pointer
	
newobject_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

create_list:
	li $a1, 1		# initialize ID
	j create_node
	
first_object:
	sw $v0, 0($t0)		#store $v0 in $t0's start 
	j newobject_end
	

err501:
imprimir_error(501)
j newobject_end
		
#
# FUNCION LISTAR OBJETO
#
listobjects:

#
# FUNCION ELIMINAR OBJETO
#
delobject:

##
## FUNCIONES ADICIONALES
##
addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) # Establecer contenido del nodo
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) # Dirección del primer nodo
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0) # Dirección del último nodo
	# Actualizar punteros prev y next del nuevo nodo
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	# Actualizar prev y primer nodo al nuevo nodo
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

# $a0: Dirección del nodo a eliminar
# $a1: Dirección de la lista donde se elimina el nodo
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # Obtener dirección del bloque
	jal sfree # Liberar bloque
	lw $a0, 4($sp) # Restaurar argumento a0
	lw $t0, 12($a0) # Obtener dirección del siguiente nodo de a0
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # Obtener dirección del nodo previo
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # Obtener dirección del primer nodo nuevamente
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) # La lista apunta al siguiente nodo
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # Solo queda un nodo
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra
	# a0: msg to ask
	# v0: block address allocated with string
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	
	li $v0, 4 # codigo para imprimir cadena, se asume que ya en a0 debe estar la cadena a imprimir
	syscall
	
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

##
## FUNCIONES PARA MEMORIA
##
smalloc:
	lw $t0, slist #carga la cabeza de la lista
	beqz $t0, sbrk #lista vacia, guarda espacio para 4 words (16 bytes)
	move $v0, $t0 
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra
sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra
