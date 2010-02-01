#ifndef __TRACE_H_
#define __TRACE_H_

#define TRACE(LEVEL, FORMAT, ARGS... )				\
do {								\
	char MSG[256];						\
								\
	if(LEVEL <= TRACE_LEVEL) {				\
		snprintf( MSG, sizeof(MSG), FORMAT, ## ARGS);	\
		fputs(MSG, I);					\
	}							\
} while (0)

/* hex to binary */
void hex2str(char *str, uint8_t src)
{
	uint8_t	i = 128, j = 0;
	do {
		if( src & i ) {
			str[j] = '1' ;				
		} else {
			str[j] = '0' ;				
		}
		
		j++;
		i >>= 1 ;
	} while(i);

	str[j] = '\0' ;
}

void dump_asci(volatile uint8_t *data, size_t size)
{
        unsigned long   i;

        for(i=0;i<size;i++) {
                if(!(i&0x1f)) {
                        fprintf(I, "\n%08lx:", i);
                }
                uint8_t c = *data;
                c = (c > 0x1f) && (c < 0x7f) ?c :'.';
                fprintf(I, "  %c",  c);
                data++;
        }
        fprintf(I, "\n");
}

void dump_hex(volatile uint8_t *data, size_t size)
{
        unsigned long   i;

        dump_asci(data, size);

        fprintf(I, "len: %lu@%08lx", (unsigned long)size, (unsigned long)data);
        if(!data)
                return;

        for(i=0;i<size;i++) {
                if(!(i&0x1f)) {
                        fprintf(I, "\n%08lx:", i);
                }

                fprintf(I, " %02x", *data);
                data++; 
        } 
        fprintf(I, "\n");
};

#endif /* __TRACE_H_ */
