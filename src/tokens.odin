package main

import "core:strings"
import "core:fmt"
import "core:os"

TokenType :: enum {
	OPEN_PARENTHESES,
	CLOSE_PARENTHESES,
	OPEN_CURLY_BRACKETS,
	CLOSE_CURLY_BRACKETS,
	EQUALS,
	COLON,
	IDENTIFIER,
	INTEGER_LITERAL,
}

@(private)
Position :: struct {
	line_number : int,
	column_number : int,
}


Token :: struct {
	lexeme: string,
	type:   TokenType,
	position : Position,
}

TokenStream :: struct {
	tokens : []Token,
	next_index : int,
}

@(require_results)
peek_token :: proc{peek_token_directly , peek_token_shifted}


@(private="file")
peek_token_directly :: proc(stream : ^TokenStream) -> Token {

	if stream.next_index >= len(stream.tokens) {
		last := stream.tokens[len(stream.tokens) - 1]
		errout("unexpected EOF found after token at line-number: %i at column: %i" , last.position.line_number , last.position.column_number)
	}

	return stream.tokens[stream.next_index]
}

@(private="file")
peek_token_shifted :: proc(stream : ^TokenStream , offset : int = 0) -> Token {
	if stream.next_index >= len(stream.tokens) {
		last := stream.tokens[len(stream.tokens) - 1]
		errout("unexpected EOF found after token at line-number: %i at column: %i" , last.position.line_number , last.position.column_number)
	}

	if stream.next_index + offset >= len(stream.tokens) {
		errout("attempted access to tokens beyond EOF!")
	}

	return stream.tokens[stream.next_index + offset]
}

next_token :: proc{ next_token_any , next_token_assert}


@(private="file")
next_token_any :: proc(stream : ^TokenStream) -> Token {

	next_token := peek_token(stream)

	stream.next_index += 1
	return next_token
}



@(private="file")
next_token_assert :: proc(stream : ^TokenStream , asserted : []TokenType) -> Token {

	next_token := next_token_any(stream)

	found := false

	for type in asserted {

		if next_token.type == type {
			found = true
			break
		}

	}


	if !found {

		errout(
			`Invalid token at line-number: %i at column: %i
			 Expected (one from these): %s
			 Found: %s
			`,
			next_token.position.line_number,
			next_token.position.column_number,
			asserted,
			next_token.type
		)
	}

	return next_token

}

tokenize :: proc(source: string) -> (tokens: [dynamic]Token) {


	line_number := 1
	column_number := 1


	for index := 0; index < len(source);  {

		if source[index] == '\n' {
			index += 1

			line_number += 1
			column_number = 1
		}
		else if strings.is_space(rune(source[index])) {
			index += 1
			column_number += 1
		}
		else if source[index] == '{' {
			index += 1
			append(&tokens , Token{lexeme = "{" , type = .OPEN_CURLY_BRACKETS , position = Position{ line_number , column_number }})
			column_number += 1
		}
		else if source[index] == '}' {
			index += 1
			append(&tokens , Token{lexeme = "}" , type = .CLOSE_CURLY_BRACKETS , position = Position{ line_number , column_number }})
			column_number += 1
		}
		else if source[index] == '(' {
			index += 1
			append(&tokens, Token{lexeme = "(", type = .OPEN_PARENTHESES , position = Position{ line_number , column_number }})
			column_number += 1

		}
	 	else if source[index] == ')' {
			index += 1
			append(&tokens, Token{lexeme = ")" , type = .CLOSE_PARENTHESES , position = Position{ line_number , column_number }})
			column_number += 1

		}
		else if source[index] == '=' {
			index += 1
			append(&tokens, Token{lexeme = "=" , type = .EQUALS , position = Position{ line_number , column_number }})
			column_number += 1
		}
		else if source[index] == ':' {
			index += 1
			append(&tokens, Token{lexeme = ":" , type = .COLON , position = Position{ line_number , column_number }})
			column_number += 1
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

			append(&tokens, Token{lexeme = source[start:end] , type = .IDENTIFIER , position = Position{ line_number , column_number }} )
			index = end
			column_number += end - start

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
				fmt.printfln("naked '-' character found at line-number: %i at column: %i" , line_number , column_number)
				os.exit(-1)
			}

			append(&tokens, Token{lexeme = source[start:end], type = .INTEGER_LITERAL , position = Position{ line_number , column_number }})
			index = end
			column_number += end - start
		}
		else {
			fmt.printfln("unknown character: %c found at line-number: %i at column: %i" , source[index] , line_number , column_number)
			os.exit(-1)
		}

	}

	return tokens
}
