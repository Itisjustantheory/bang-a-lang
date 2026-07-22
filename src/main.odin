package main


import "core:fmt"
import "core:os"


errout :: proc(message: string , args : ..any ) -> ! {
	raw := fmt.tprintf(message , ..args)
	fmt.fprintfln(os.stderr, "[ERROR]: %s", raw)
	os.exit(-1)
}

debugout :: proc(message: string , args : ..any) {
	raw := fmt.tprintf(message , ..args)
	fmt.fprintfln(os.stderr, "[DEBUG]: %s", raw)
}



main :: proc() {

	if len(os.args) != 2 do errout("./bangc <file-path>")

	debugout("ENTRY")

	raw_source, read_error := os.read_entire_file_from_path(
		os.args[1],
		context.allocator,
	)

	defer delete(raw_source)


	if read_error != os.ERROR_NONE do errout("bangalang source does not exist! (read error)")

	debugout("READ SUCCESS!")

	source := string(raw_source)

	tokens := tokenize(source)

	fmt.print(tokens)
	fmt.print("\n")
	debugout("TOKENIZE SUCCCESS!")

	stream := TokenStream { tokens = tokens[:] , next_index = 0 }
	ast_nodes := parse_program(&stream)
	fmt.println("ast_nodes: ")
	fmt.println(ast_nodes)
	debugout("PARSING SUCCESS!")


	generate_program("./bin/bang.asm" , ast_nodes)
	debugout("GENERATION SUCCESS!")


}
