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
		"./bangalang_examples/exit.bang",
		context.allocator,
	)


	if read_error != os.ERROR_NONE do errout("bangalang source does not exist! (read error)")

	debugout("READ SUCCESS!")

	source := string(raw_source)

	tokens := tokenize(source)

	debugout("TOKENIZE SUCCCESS!")


	assembly_file, assembly_file_error := os.open(
		"./bin/bang.asm",
		os.O_CREATE | os.O_WRONLY | os.O_TRUNC,
		os.Permissions_All,
	)

	defer os.close(assembly_file)

	if assembly_file_error != os.ERROR_NONE do errout("binary file could not be opened (read error)")

	fmt.fprintln(assembly_file, "global _start")
	fmt.fprintln(assembly_file, "_start:")

	if tokens[0] == "exit" && tokens[1] == "(" && tokens[3] == ")" {
		fmt.fprintln(assembly_file, "	mov rax , 60 ; syscall identity (exit)")
		fmt.fprintfln(assembly_file, "	mov rdi , %s  ; exit code ", tokens[2])
		fmt.fprintfln(
			assembly_file,
			"	syscall      ; call said syscall with exit code (exits with exit code %s) ",
			tokens[2],
		)
	} else do errout("Unrecognized token pattern!")


}
