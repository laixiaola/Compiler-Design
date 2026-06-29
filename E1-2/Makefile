all:
	bison -d syntax.y
	flex css.l
	gcc main.c syntax.tab.c -o css -lfl
clean:
	rm -f lex.yy.c css