all:
	bison -d syntax.y
	flex css.l
	gcc main.c tree.c lex.yy.c syntax.tab.c -o css -lfl
clean:
	rm -f lex.yy.c css syntax.tab.c syntax.tab.h