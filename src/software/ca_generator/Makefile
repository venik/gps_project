ca_generate: ca_generate.o getca.o
	gcc -o ca_generate ca_generate.o getca.o
ca_generate.o: ca_generate.c
	gcc -c ca_generate.c
getca.o: getca.c
	gcc -c getca.c
clean:
	rm -f *.o ca_generate
