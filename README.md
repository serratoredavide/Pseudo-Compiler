# Pseudo-Compiler

### Compiler course's project report
University of Padua | Computer Engineering Department


#### Authors
Serratore Davide - M.1207660 | Vesco Omar - M.1197699

---

## Repository content

	Report.pdf                \\ Project report (Italian Language)

	Makefile                  \\ Makefile to compile code
	scanner.fl                \\ Lexical Analyzer source code
	syntax_analyzer.y         \\ Syntax Analyzer source code
	utils.c                   \\ Function utility: Symbol Table, print code 
	uthash.h                  \\ Hash table for C structure http://troydhanson.github.io/uthash/



## Compile and Execution

Flex and Bison softwares needed to compile. Command:

	make 

To execute code:

	./a.out < input.txt > output.txt

It's also possible to write code on the terminal. In this case `EOF` is needed to print output code. 

To test output code copy inside a standard code c:

	#include "utils.h"
	int main() {
      \\output code 
      }

`make clean` to clean up executable files
