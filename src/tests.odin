package main


import "core:os"
import "core:testing"

get_empty_file :: proc() -> ([]byte, os.Error) {
	raw_source, read_error := os.read_entire_file_from_path(
		"./bangalang_examples/empty.bang",
		context.allocator,
	)

	return raw_source, read_error
}

@(test)
test_empty_file :: proc(t: ^testing.T) {

	source, error := get_empty_file()

	testing.expect(t, error == os.ERROR_NONE, "file should exist!")


	testing.expect(t, len(source) == 0, "file should be empty")

}

get_exit_file :: proc() {

}
