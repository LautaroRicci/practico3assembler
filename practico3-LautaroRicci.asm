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
failure: .asciiz "La operacion NO se pudo realizar\n\n"
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
    sw $t0, wclist 	# actualizar wclist desde el registro $t0
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
				lw $t0, cclist # cargo la primer categoria
				beqz $t0, error201 #error si no hay categorias
				
				lw $t1, cclist #copia para comparar
				
				j listcategories_loop
	
	listcategories_loop:
				lw $t0, 8($t0) #0x10040000
				la $a0, 0($t0) # cargo 0x10040000 en a0 para imprimir
				li $v0, 4
				syscall
				
				lw $t0, 28($t0) # accedo a 0x10040000 corrido 28 lugares (puntero a la siguiente categoria)
				beq $t0, $t1, loopcategories_finaliza # si la siguiente categoria es igual al puntero de la primera finaliza
				j listcategories_loop
				
	loopcategories_finaliza:
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
		beqz $t0, err501 # ERROR NO HAY CATEGORIA (RA = MENU)
	        
	        addiu $s4, $s4, -4
	        sw $ra, 4($sp) # GUARDO EL RA
	        
	        la $a0, objName
	        jal getblock # necesita un a0 como entrada (string de cadena) y de salida devuelve la direccion creada en v0
	      	
	     move $a2, $v0 # muevo la direccion del nuevo bloque creado a a2
	     
	     lw $a0, wclist 
	
	     la $a0, 4($a0) # accedo a la direccion del puntero de objeto de la categoria actual
	     lw $t0, 0($a0) # cargo el contenido de esa direccion en $t0

	     beqz $t0, create_list	 # creo una nueva lista si no hay objetos
	     lw $t0, 0($t0)
	     lw $t0, 4($t0)
	     addi $a1, $t0, 1	# increments the old ID 
	
create_node:
	jal addnode	# agrego un nodo,  Entradas: $a0: Direccion de la categoria donde se añadira el nodo.
				# $a1: ID.
				# $a2: cclist del nodo
				# Salida: $v0, direccion del nodo recien creado
				# Tambien guarda en la posicion 4, de la categoria actual donde se ingresa el objeto, la direccion del
				# objeto anadido
				# Y actualiza la posicion 0 del objeto creado, con la direccion del propio objeto al igual q la posicion 12
	lw $t0, wclist
	la $t0, 4($t0)
	
	beqz $t0, first_object

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
jr $ra

#
# FUNCION LISTAR OBJETO
#
listobjects:
	lw $t1, wclist
	beqz $t1, err601	# no hay categorias
	
	lw $t1, 4($t1) #0x10040030 puntero al siguiente objeto
	beqz $t1, err602	# no hay objetos
	
	lw $t2, wclist # copia para comparar el primer objeto
	lw $t2, 4($t2) #0x10040030
	
	j list_objectsloop
		
list_objectsloop:
		lw $a0, 4($t1)
		li $v0, 1
		syscall
		imprimir_mensaje(idSymbol)
		lw $t1, 8($t1) # 0x10040020
		la $a0, 0($t1) # cargo la direccion del string en a0 para imprimir
		li $v0, 4
		syscall
		
		lw $t1, 28($t1) # agarra el puntero al siguiente objeto
		beq $t1, $t2,  endloop_obj # si el proximo puntero de objeto es igual a la copia del primero, termina
		j list_objectsloop # sino vuelve a empezar
		
endloop_obj:
	jr $ra

err601:
imprimir_error(201)
jr $ra           

err602:
imprimir_error(602)
jr $ra

#
# FUNCION ELIMINAR OBJETO
#
delobject:
		addiu $sp, $sp, -4
		sw $ra, 4($sp) #guardo el ra del menu

		lw $t0, wclist
		beqz $t0, err701	# no hay categorias
		
		# pido un numero y lo guardo en $v0
		imprimir_mensaje(idObj)
		lee_entero
		
		lw $t1, wclist # accedo al wclist (0x10040010)
		lw $t1, 4($t1) # accedo a el puntero de objeto siguiente o primero (0x10040014)
		
		lw $t3, ($t1) #copia del primer objeto para comprobacion
		
		beqz $t1, err701 # no hay objetos
		
delobject_loop:
		lw $t4, ($t0) # direccion del objeto (SOLO USADO EN CASO DE QUE COINCIDAN LOS IDS DE USUARIO E OBJETO)
		
		lw $t2, 4($t1) # accedo al id del objeto
		
		beq $t2, $v0, delobject_found # ID == ID USUARIO
		lw $t1, 12($t1) # si el id del objeto no es igual al id que ingreso el usuario, $t1 se reemplaza por la direccion al objeto siguiente
		beq $t1, $t3, errFueraRango # si la direccion de objeto siguiente es igual a la copia de la primera direccion, quiere decir que no hay mas objetos por comprobar su ID
		
		j delobject_loop

delobject_found:
	move $a0, $t4 # pongo el contenido de la direccion del objeto en a0
	add $a1, $t0, 4 # al wclist le sumo 4 y lo pongo en a1
	jal delnode
	imprimir_mensaje(success)
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra
		
err701:
imprimir_error(701)
jr $ra

errFueraRango:
imprimir_mensaje(failure)
jr $ra

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
    addi $sp, $sp, -4        # Reservar espacio en la pila
    sw $ra, 4($sp)           # Guardar el valor de retorno en la pila
    
    li $v0, 4                # Preparar syscall para imprimir cadena
    syscall                  # Imprime la cadena apuntada por $a0
    
    jal smalloc              # Llama a smalloc para asignar memoria
    move $a0, $v0            # Guarda la direccion del bloque asignado en $a0
    
    li $a1, 16               # Establece un tamaño 16 bytes
    li $v0, 8                # Otra syscall para ajustar el tamaño del bloque
    syscall                  # Ejecuta la syscall
    
    move $v0, $a0            # Devuelve la dirección asignada en $v0
    lw $ra, 4($sp)           # Restaurar $ra desde la pila
    addi $sp, $sp, 4         # Liberar el espacio reservado en la pila
    jr $ra                   # Retorna al llamador

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
