package main


AstNodeType :: enum {
	SCOPE,
	DECLARATION_STATEMENT,
	ASSIGNMENT_STATEMENT,
	EXIT_STATEMENT,
	TERM,
	IDENTIFIER,
	INTEGER_LITERAL,
}

AstNode :: struct {

	type : AstNodeType,
	value : string,
	children : [dynamic]AstNode,
	position : Position,
}

parse_program :: proc(stream : ^TokenStream) -> (nodes : [dynamic]AstNode) {

	for stream.next_index < len(stream.tokens) {

		append(&nodes , parse_statement(stream))
	}


	return nodes
}

parse_statement :: proc(stream : ^TokenStream) -> (node : AstNode) {

	#partial switch peek_token(stream).type {

		case .OPEN_CURLY_BRACKETS:
			node = parse_scope_statement(stream)

		case .IDENTIFIER:

			#partial switch peek_token(stream , offset = 1).type {

				case .OPEN_PARENTHESES:
					node = parse_exit_statement(stream)
				case .COLON:
					node = parse_declaration_statement(stream)
				case .EQUALS:
					node = parse_assignment_statement(stream)

				case:
					token := peek_token(stream)
					errout("Failed to parse statement\ninvalid token at line-number: %s at column: %s" , token.position.line_number , token.position.line_number)
			}

		case:
			token := peek_token(stream)
			errout("Failed to parse statement\ninvalid token at line-number: %s at column: %s" , token.position.line_number , token.position.column_number)

	}

	return node
}

parse_scope_statement :: proc(stream : ^TokenStream) -> (node : AstNode) {

	node.type = .SCOPE

	node.position.line_number = peek_token(stream).position.line_number
	node.position.column_number = peek_token(stream).position.column_number

	next_token(stream , []TokenType { .OPEN_CURLY_BRACKETS })

	for stream.next_index < len(stream.tokens) {

		if peek_token(stream).type == .CLOSE_CURLY_BRACKETS {
			next_token(stream)
			return node
		}

		append(&node.children , parse_statement(stream))
	}

	errout("unterminated scope!")
}

parse_declaration_statement :: proc(stream : ^TokenStream) -> (node : AstNode) {

	node.type = .DECLARATION_STATEMENT

	node.position.line_number = peek_token(stream).position.line_number
	node.position.column_number = peek_token(stream).position.column_number

	lhs := AstNode { type = .IDENTIFIER , value = next_token(stream , []TokenType { .IDENTIFIER }).lexeme}

	append(&node.children , lhs)

	next_token(stream , []TokenType {.COLON})
	next_token(stream , []TokenType {.EQUALS})


	rhs := parse_term(stream)
	append(&node.children , rhs)

	return node
}

parse_assignment_statement :: proc(stream : ^TokenStream) -> (node : AstNode) {

	node.type = .ASSIGNMENT_STATEMENT

	node.position.line_number = peek_token(stream).position.line_number
	node.position.column_number = peek_token(stream).position.column_number

	lhs := AstNode { type = .IDENTIFIER , value = next_token(stream , []TokenType { .IDENTIFIER }).lexeme}

	append(&node.children , lhs)

	next_token(stream , []TokenType {.EQUALS})


	rhs := parse_term(stream)
	append(&node.children , rhs)

	return node
}

parse_exit_statement :: proc(stream : ^TokenStream) -> (node : AstNode)  {

	node.type = .EXIT_STATEMENT

	node.position.line_number = peek_token(stream).position.line_number
	node.position.column_number = peek_token(stream).position.column_number

	exit := next_token(stream , []TokenType {.IDENTIFIER})

	// technically this is redundant as next_token will call the asserted version
	if exit.lexeme != "exit" {
		errout("Failed to parse statement\ninvalid token at line-number: %s at column: %s" , exit.position.line_number , exit.position.column_number)
	}

	next_token(stream , []TokenType {.OPEN_PARENTHESES})

	parameter := parse_term(stream)
	append(&node.children , parameter)

	next_token(stream , []TokenType {.CLOSE_PARENTHESES})

	return node
}

parse_term :: proc(stream : ^TokenStream) -> (node : AstNode) {


	node.type = .TERM

	node.position.line_number = peek_token(stream).position.line_number
	node.position.column_number = peek_token(stream).position.column_number

	token := next_token(stream , []TokenType { .IDENTIFIER , .INTEGER_LITERAL })

	node.value = token.lexeme

	#partial switch token.type {

		case .IDENTIFIER:
			node.type = .IDENTIFIER
		case .INTEGER_LITERAL:
			node.type = .INTEGER_LITERAL
		case:
			errout("Failed to parse term\ninvalid token at line-number: %s at column: %s" , token.position.line_number , token.position.column_number)
	}

	return node

}
