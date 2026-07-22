package main

import "core:os"
import "core:fmt"
import "core:strings"


Stack :: struct {
	top : int,
	variables : map[string]int,
}


emit_assembly :: proc(file_name: ^os.File, format: string, args: ..any, level: int = 0) {
    raw := fmt.tprintf(format, ..args)
    fmt.fprintfln(file_name, "%s%s", strings.repeat(" ", level * 8), raw)
}

generate_program :: proc(file_name : string , nodes : [dynamic]AstNode) {

	assembly_file, assembly_file_error := os.open(
		file_name,
		os.O_CREATE | os.O_WRONLY | os.O_TRUNC,
		os.Permissions_All,
	)

	defer os.close(assembly_file)
	if assembly_file_error != os.ERROR_NONE do errout("binary file could not be opened (read error)")

	emit_assembly(assembly_file , "global _start" , level = 0)
	emit_assembly(assembly_file , "_start:" , level = 0)

	stack := Stack{}



	for node in nodes {
		generate_statement(assembly_file , node , &stack)
	}

	emit_assembly(assembly_file , "mov rax , 60" , level = 1)
	emit_assembly(assembly_file , "mov rdi , 0" , level = 1)
	emit_assembly(assembly_file , "syscall" , level = 1)

}

generate_statement :: proc(file : ^os.File , node : AstNode , stack : ^Stack) {

	#partial switch node.type {

		case .SCOPE:
			generate_scope(file , node , stack)
		case .DECLARATION_STATEMENT:
			generate_declaration_statement(file , node , stack)
		case .ASSIGNMENT_STATEMENT:
			generate_assignment_statement(file , node , stack)
		case .EXIT_STATEMENT:
			generate_exit_statement(file  , node , stack)
		case:
			errout("Failed to generate statement as assembly instruction!\nInvalid node found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)
	}
}

generate_scope :: proc(file : ^os.File , node : AstNode , stack : ^Stack) {

	emit_assembly(file , "; start scope" , level =  1)

	scope_start := stack.top
	scoped_stack := Stack{
		top = stack.top,
		variables = make(map[string]int)
	}

	defer delete(scoped_stack.variables)

	for key , value in stack.variables {
		scoped_stack.variables[key] = value
	}



	for child in node.children {
		generate_statement(file , child , &scoped_stack)
	}


	if scoped_stack.top - stack.top != 0 do emit_assembly(file , "add rsp , %i" , scoped_stack.top - stack.top , level = 1)
	emit_assembly(file , "; end scope" , level = 1)
}

generate_declaration_statement :: proc(file : ^os.File , node : AstNode , stack : ^Stack) {

	lhs := node.children[0]
	rhs := node.children[1]

	emit_assembly(file , "; declare %s" , lhs.value , level =  1)

	if rhs.type == .IDENTIFIER {

		if rhs.value not_in stack.variables do errout("Failed to generate declaration statement as assembly instruction!\nundeclared identifier '%s' found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)


		variable_pointer := stack.variables[rhs.value]
		variable_offset := stack.top - variable_pointer

		emit_assembly(file , "mov rax , [rsp + %i]" , variable_offset , level = 1)
	}
	else if rhs.type == .INTEGER_LITERAL {

		emit_assembly(file , "mov rax , %s" , rhs.value , level = 1)
	}
	else do errout("Failed to generate declaration statement as assembly instruction!\nundeclared identifier '%s' found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)

	if lhs.value in stack.variables do errout("Duplicate variable '%s' declared at line-number: %i at column: %i " , lhs.value , node.position.line_number , node.position.column_number)

	emit_assembly(file , "mov [rsp] , rax" , level = 1)
	emit_assembly(file , "sub rsp , 8" , level = 1)
	stack.variables[lhs.value] = stack.top
	stack.top += 8

}

generate_assignment_statement :: proc(file : ^os.File , node : AstNode , stack : ^Stack) {

	lhs := node.children[0]
	rhs := node.children[1]

	emit_assembly(file , "; assign to %s" , lhs.value , level =  1)

	if rhs.type == .IDENTIFIER {

		if rhs.value not_in stack.variables do errout("Failed to generate declaration statement as assembly instruction!\nundeclared identifier '%s' found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)


		variable_pointer := stack.variables[rhs.value]
		variable_offset := stack.top - variable_pointer

		emit_assembly(file , "mov rax , [rsp + %i]" , variable_offset , level = 1)
	}
	else if rhs.type == .INTEGER_LITERAL {

		emit_assembly(file , "mov rax , %s" , rhs.value , level = 1)
	}
	else do errout("Failed to generate statement as assembly instruction!\nInvalid node found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)

	if lhs.value not_in stack.variables do errout("Failed to generate declaration statement as assembly instruction!\nundeclared identifier '%s' found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)

	emit_assembly(file , "; move value to stack offset for %s" , lhs.value , level = 1)
	variable_pointer := stack.variables[lhs.value]
	variable_offset := stack.top - variable_pointer

	emit_assembly(file , "mov [rsp + %i] , rax" , variable_offset , level = 1)

}

generate_exit_statement :: proc(file : ^os.File , node : AstNode , stack : ^Stack) {

	emit_assembly(file , "; exit" , level = 1)

	parameter := node.children[0]

	emit_assembly(file , "mov rax , 60" , level = 1)

	if parameter.type == .IDENTIFIER {

		if parameter.value not_in stack.variables do errout("Failed to generate declaration statement as assembly instruction!\nundeclared identifier '%s' found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)

		variable_pointer := stack.variables[parameter.value]
		variable_offset := stack.top - variable_pointer

		emit_assembly(file , "mov rdi , [rsp + %i]" , variable_offset , level = 1)
	}
	else if parameter.type == .INTEGER_LITERAL {
		emit_assembly(file , "mov rdi , %s" , parameter.value , level = 1)
	}
	else do errout("Failed to generate statement as assembly instruction!\nInvalid node found at line-number: %i at column: %i" , node.position.line_number , node.position.column_number)


	emit_assembly(file , "syscall" , level = 1)
}
