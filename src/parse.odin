package main


AstNodeType :: enum {
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
}

parse_program :: proc(tokens : [dynamic]Token) -> (nodes : [dynamic]AstNode) {

	for index := 0; index < len(tokens); {

		ast_node , token_count := parse_statement(tokens , index)

		append(&nodes , ast_node)
		index += token_count
	}


	return nodes
}

parse_statement :: proc(tokens : [dynamic]Token, start_index : int) -> (node : AstNode , token_parsed : int) {

	#partial switch tokens[start_index].type {

		case .IDENTIFIER:
			if start_index + 2 >= len(tokens) do errout("EOF encountered")

			#partial switch tokens[start_index + 1].type {

				case .COLON:
					node , token_parsed = parse_declaration_statement(tokens , start_index)
				case .EQUALS:
					node , token_parsed = parse_assignment_statement(tokens , start_index)
				case .OPEN_PARENTHESES:
					node , token_parsed = parse_exit_statement(tokens , start_index)

				case:
					errout("invalid statement")
			}

		case:
			errout("invalid statement")

	}

	return node , token_parsed
}

parse_declaration_statement :: proc(tokens : [dynamic]Token , start_index : int) -> (node : AstNode , token_parsed : int) {

	if start_index + 3 >= len(tokens) do errout("Invalid declaration")

	node.type = .DECLARATION_STATEMENT

	lhs := AstNode { type = .IDENTIFIER , value = tokens[start_index].lexeme }
	append(&node.children , lhs)
	token_parsed += 1

	if tokens[start_index + 1].type != .COLON || tokens[start_index + 2].type != .EQUALS do errout("Invalid declaration")

	// for the ':' , '='
	token_parsed += 2

	rhs , parsed := parse_term(tokens , start_index + 3)
	token_parsed += parsed

	append(&node.children , rhs)

	return node , token_parsed
}

parse_assignment_statement :: proc(tokens : [dynamic]Token , start_index : int ) -> (node : AstNode , token_parsed : int) {

	if start_index + 2 >= len(tokens) do errout("Invalid assignment!")

	node.type = .ASSIGNMENT_STATEMENT

	lhs := AstNode { type = .IDENTIFIER , value = tokens[start_index].lexeme }
	append(&node.children , lhs)
	token_parsed += 1

	if tokens[start_index + 1].type != .EQUALS do errout("Invalid assignment!")
	// for the '='
	token_parsed += 1

	rhs , parsed := parse_term(tokens , start_index + 2)
	token_parsed += parsed

	append(&node.children , rhs)

	return node , token_parsed
}

parse_exit_statement :: proc(tokens : [dynamic]Token , start_index : int ) -> (node : AstNode , token_parsed : int) {

	if start_index + 3 >= len(tokens) do errout("invalid statement")

	if tokens[start_index + 1].type != .OPEN_PARENTHESES || tokens[start_index + 3].type != .CLOSE_PARENTHESES do errout("invalid statement")

	node.type = .EXIT_STATEMENT

	// for the 'exit' and '('
	token_parsed += 2

	parameter_node , parsed := parse_term(tokens , start_index + 2)
	append(&node.children , parameter_node)

	token_parsed += parsed

	// for the ')'
	token_parsed += 1
	return node , token_parsed
}

parse_term :: proc(tokens : [dynamic]Token , index : int ) -> (node : AstNode , token_parsed : int) {

	node.type = .TERM

	child_node := AstNode { value = tokens[index].lexeme }

	#partial switch tokens[index].type {

		case .IDENTIFIER:
			child_node.type = .IDENTIFIER
		case .INTEGER_LITERAL:
			child_node.type = .INTEGER_LITERAL
		case:
			errout("invalid statement")
	}

	token_parsed += 1
	append(&node.children , child_node)




	return node , token_parsed

}
