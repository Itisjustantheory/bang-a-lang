package main

import "core:strings"


tokenize :: proc(source: string) -> [dynamic]string {


	tokens: [dynamic]string = {}


	for index := 0; index < len(source); index += 1 {

		if strings.is_space(rune(source[index])) do continue

		if source[index] == '(' {
			append(&tokens, "(")
		} else if source[index] == ')' {
			append(&tokens, ")")
		} else if source[index] == 'e' {

			if index + 3 >= len(source) do errout("not enough space for parsing 'exit' ")

			if source[index + 1] != 'x' || source[index + 2] != 'i' || source[index + 3] != 't' do errout("you spelt 'exit' wrong!")

			append(&tokens, "exit")
			index += 3

		} else if (source[index] >= '0' && source[index] <= '9') || source[index] == '-' {

			start := index
			end := index

			if source[end] == '-' {
				end += 1
			}

			for end < len(source) && source[end] >= '0' && source[end] <= '9' {
				end += 1
			}

			if source[start] == '-' && end == start + 1 {
				errout("negative what though?")
			}

			append(&tokens, source[start:end])
			index = end - 1
		} else do errout("Unknown character")

	}

	return tokens
}
