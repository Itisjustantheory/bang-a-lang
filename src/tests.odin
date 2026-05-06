package main


import "core:os"
import "core:testing"


get_file :: proc(fpath: string) -> ([]byte, os.Error) {
	raw_source, read_error := os.read_entire_file_from_path(fpath, context.allocator)

	return raw_source, read_error
}


get_empty_file :: proc() -> ([]byte, os.Error) {
	return get_file("../bangalang_examples/empty.bang")
}

@(test)
test_empty_file :: proc(t: ^testing.T) {

	source, error := get_empty_file()

	testing.expect(t, error == os.ERROR_NONE, "file should exist!")


	testing.expect(t, len(source) == 0, "file should be empty")

}


get_exit_file :: proc() -> ([]byte, os.Error) {
	return get_file("../bangalang_examples/exit.bang")
}

@(test)
test_exit_parsed_in_exit_file :: proc(t: ^testing.T) {

	source, error := get_exit_file()

	testing.expect(t, error != os.ERROR_NONE, "file should exist!")

	testing.expect(t, len(source) != 0, "file should have source code!")

	testing.expect(
		t,
		len(source) == 4,
		"file should contain code with only the length required for a exit command with its exit code after parsing!",
	)

	tokens := tokenize(string(source))

	testing.expect(t, tokens[0] == "exit", "expected an exit function!")

	testing.expect(t, tokens[1] == "(", "expected a opening parentheses")

	for index := 0; index < len(tokens[2]); index += 1 {
		testing.expect(
			t,
			tokens[2][index] >= '0' && tokens[2][index] <= '9',
			"given exit code should be numerical",
		)
	}

	testing.expect(t, tokens[3] == ")", "expected a closing parentheses")
}
