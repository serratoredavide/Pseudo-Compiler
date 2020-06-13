all:
	bison -d syntax_analyzer.y
	flex scanner.fl
	gcc syntax_analyzer.tab.c lex.yy.c utils.c

RM = rm -rf
clean:
	$(RM) syntax_analyzer.tab.*
	$(RM) lex.yy.c 
	$(RM) a.out 
	
again:                                                               
	make clean
	make    

