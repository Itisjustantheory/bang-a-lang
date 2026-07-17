package main


import "core:fmt"
import "core:os"


errout :: #force_inline proc(message: string) {
	fmt.fprintfln(os.stderr, "[ERROR]: %s", message)
	os.exit(-1)
}

debugout :: #force_inline proc(message: string) {
	fmt.fprintfln(os.stdout, "[DEBUG]: %s", message)
}


main :: proc() {

	debugout("ENTRY")
	raw_source, read_error := os.read_entire_file_from_path(
		"./bangalang_examples/variable_assign.bang",
		context.allocator,
	)


	if read_error != os.ERROR_NONE do errout("bangalang source does not exist! (read error)")

	debugout("READ SUCCESS!")

	source := string(raw_source)

	tokens := tokenize(source)

	fmt.fprint(os.stdout, tokens)
	fmt.fprint(os.stdout, "\n")

	debugout("TOKENIZE SUCCCESS!")


	assembly_file, assembly_file_error := os.open(
		"./bin/bang.asm",
		os.O_CREATE | os.O_WRONLY | os.O_TRUNC,
		os.Permissions_All,
	)


	debugout("ASSEMBLY FILE ACCESSED (OR CREATED)!")

	defer os.close(assembly_file)

	if assembly_file_error != os.ERROR_NONE do errout("binary file could not be opened (read error)")

	fmt.fprintln(assembly_file, "global _start")
	fmt.fprintln(assembly_file, "_start:")

	stack_pointer := 0

	stack_variables := make(map[string]int)
	defer delete(stack_variables)

	for index := 0; index < len(tokens); {

		#partial switch tokens[index].type {

			case .IDENTIFIER:
				if (index + 1) >= len(tokens) do errout("EOF encountered")

				#partial switch tokens[index + 1].type {
					case .EQUALS:

						if (index + 2) >= len(tokens) do errout("Invalid assignment statement")

						fmt.fprintfln(assembly_file, "    ; assign %s" , tokens[index].lexeme )

						if tokens[index + 2].type == .IDENTIFIER {

							if tokens[index + 2].lexeme not_in stack_variables {
								fmt.printfln("reference to undeclared variable: %s" , tokens[index + 2].lexeme)
								os.exit(-1)
							}

							variable_pointer := stack_variables[tokens[index + 2].lexeme]
							offset := stack_pointer - variable_pointer
							fmt.fprintfln(assembly_file, "    mov rax , [rsp + %i]" , offset)
							fmt.fprintln(assembly_file, "    mov [rsp] , rax")
							stack_variables[tokens[index].lexeme] = stack_pointer

							fmt.fprintln(assembly_file, "    sub rsp , 8 ; allocates 64 bits onto the stack")
							stack_pointer += 8
						}
						else if tokens[index + 2].type == .INTEGER_LITERAL {


							if tokens[index].lexeme in stack_variables
							{
								variable_pointer := stack_variables[tokens[index].lexeme]
								offset := stack_pointer - variable_pointer

								fmt.fprintfln(assembly_file, "    mov rax , %s ; assign value" , tokens[index + 2].lexeme)
								fmt.fprintfln(assembly_file, "    mov [rsp + %i] , rax" , offset)
							}
							else {
								fmt.fprintfln(assembly_file, "    mov rax , %s ; assign value" , tokens[index + 2].lexeme)
								fmt.fprintfln(assembly_file, "    mov [rsp] , rax")
								stack_variables[tokens[index].lexeme] = stack_pointer

								fmt.fprintln(assembly_file, "    sub rsp , 8 ; allocates 64 bits onto the stack")
								stack_pointer += 8
							}

						}
						else do errout("invalid statement")

						index += 3


					case .OPEN_PARENTHESES:

						if (index + 3) >= len(tokens) do errout("EOF encountered")

						fmt.fprintln(assembly_file, "    ; exit")



						fmt.fprintln(assembly_file, "    mov rax , 60 ; syscall to exit")

						if tokens[index + 2].type == .IDENTIFIER && tokens[index + 3].type == .CLOSE_PARENTHESES {
							variable_pointer := stack_variables[tokens[index + 2].lexeme]
							offset := stack_pointer - variable_pointer
							fmt.fprintfln(assembly_file, "    mov rdi , [rsp + %i] ; exit code" , offset)
						}
						else if tokens[index + 2].type == .INTEGER_LITERAL && tokens[index + 3].type == .CLOSE_PARENTHESES {
							fmt.fprintfln(assembly_file, "    mov rdi, %s ; exit_code" , tokens[index + 2].lexeme);
						}
						else do errout("invalid statement")

						fmt.fprintln(assembly_file, "    syscall")
						index += 4

					case:
						errout("invalid statement")
				}
			case:
				errout("invalid statement")

		}

	}

	fmt.fprintln(assembly_file , "    mov rax, 60 ; syscall to exit")
	fmt.fprintln(assembly_file,  "    mov rdi, 0  ; exit_code")
	fmt.fprintln(assembly_file,  "    syscall")



}
