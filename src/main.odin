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


	raw_source, read_error := os.read_entire_file_from_path(
		"./bangalang_examples/empty.bang",
		context.allocator,
	)


	if read_error != os.ERROR_NONE do errout("bangalang source does not exist! (read error)")


	source := string(raw_source)


	assembly_file, assembly_file_error := os.open(
		"./bin/bang.asm",
		os.O_CREATE | os.O_WRONLY | os.O_TRUNC,
		os.Permissions_All,
	)

	defer os.close(assembly_file)

	if assembly_file_error != os.ERROR_NONE do errout("binary file could not be opened (read error)")

	fmt.fprintln(assembly_file, "define _start")
	fmt.fprintln(assembly_file, "_start:")
	fmt.fprintln(assembly_file, "	mov rdx , 60 ; syscall identity (exit)")
	fmt.fprintln(assembly_file, "	mov rdi , 0  ; exit code ")
	fmt.fprintln(
		assembly_file,
		"	syscall      ; call said syscall with exit code (exits with exit code 0) ",
	)


}
