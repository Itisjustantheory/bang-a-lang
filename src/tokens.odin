package main

import "core:strings"


TokenType :: enum {
	OPEN_PARENTHESES,
	CLOSE_PARENTHESES,
	EQUALS,
	IDENTIFIER,
	INTEGER_LITERAL,
}

Token :: struct {
	lexeme: string,
	type:   TokenType,
}




tokenize :: proc(source: string) -> (tokens: [dynamic]Token) {

	for index := 0; index < len(source); index += 1 {

		if strings.is_space(rune(source[index])) do continue

		if source[index] == '(' {
			append(&tokens, Token{lexeme = "(", type = .OPEN_PARENTHESES})

		}
	 	else if source[index] == ')' {
			append(&tokens, Token{lexeme = ")", type = .CLOSE_PARENTHESES})

		}
		else if source[index] == '=' {
			append(&tokens, Token{lexeme = "=", type = .EQUALS})

		}
		else if (source[index] >= 'A' && source[index] <= 'Z') ||
		   (source[index] >= 'a' && source[index] <= 'z') ||
		   source[index] == '_' {

			start := index
			end := index + 1

			for (source[end] >= 'A' && source[end] <= 'Z') ||
			    (source[end] >= 'a' && source[end] <= 'z') ||
			    source[end] == '_' ||
			    (source[end] >= '0' && source[index] <= '9') {
				end += 1
			}

			append(&tokens, Token{lexeme = source[start:end], type = .IDENTIFIER})
			index = end - 1

		}
		else if (source[index] >= '0' && source[index] <= '9') || source[index] == '-' {

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

			append(&tokens, Token{lexeme = source[start:end], type = .INTEGER_LITERAL})
			index = end - 1
		} else do errout("Unknown character")

	}

	return
}
