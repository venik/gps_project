#ifndef __CFG_PARSER_
#define __CFG_PARSER_

#include "trace.h"

/* cfg parser, try to do it simple */

typedef	struct cfg_string_s {
	char		name[255];
	uint64_t	val;
} cfg_string_t;

typedef struct cfg_parser_s {
	int		fd;
	cfg_string_t	*cfg_vals;
} cfg_parser_t;

cfg_parser_t *cfg_prepare(char *cfg_name, cfg_string_t *cfg_vals)
{
	cfg_parser_t *cfg_parser = (cfg_parser_t *)malloc(sizeof(cfg_parser_t)) ;
	if( cfg_parser == NULL ) {
		TRACE(0, "[err] [%s] cannot allocate memory. errno %s\n", __func__, strerror(errno));
		return NULL;
	}

	cfg_parser->fd = open(cfg_name, O_RDONLY, 0666);
	if( cfg_parser->fd < 0 ) {
		TRACE(0, "[err] [%s] during open the cfg file. errno %s\n", __func__, strerror(errno));
		return NULL;
	}
	
	cfg_parser->cfg_vals = cfg_vals;

	return cfg_parser;
}

void cfg_destroy(cfg_parser_t *cfg_parser)
{
	close(cfg_parser->fd);
	free(cfg_parser);	
}

int cfg_get_vals(cfg_parser_t *cfg_parser)
{
	size_t	line_len = 65536, str_len; 
	int 	on = 1;
	char	tmp_str[line_len];
	int	size_of_cfg, i, res;
	cfg_string_t	*cfg_vals = cfg_parser->cfg_vals;

	char		*p_str, *p_start;

	while(on) {
		size_of_cfg = read(cfg_parser->fd, tmp_str, line_len);	
		if( size_of_cfg < 0 ) {
			TRACE(0, "[err] [%s] during read the cfg file. errno %s\n", __func__, strerror(errno));
			return -1;
		} else if (size_of_cfg == 0 ) {
			/* end of the cfg-file */
			break;
		} else if (size_of_cfg != line_len ) {
			/* we already read cfg-file */			
			on = 0;
		}

		while( p_start != (tmp_str + line_len) ) {

			if( *p_start == '\0' ) {
				/* end of the buffer */
				break;
			}

			p_str = p_start;

			/* walk trough the current line */
			do {
				//printf("[%c][%d]\n", *p_str, *p_str) ;
				p_str++;
			} while( (*p_str != '\n') && (*p_str != '\0') );

			if( *p_start != '#' ) {
				/* it's not the comment */
				i = 0;

				/* try to find the token in the token table */
				str_len = strlen(cfg_vals[i].name);
				do {
					res = strncmp(cfg_vals[i].name, p_start, str_len);

					/* have we found it? */
					if( res == 0 )
						break;

				} while( str_len != 0 );

				if( str_len == 0 ) {
					/* unknown token */
					p_start = p_str + 1;
				}

				/* move pointer after the token */
				p_start += str_len;

				i = sscanf(p_start, "=%llx\n", &cfg_vals[i].val);
				if(i < 1) {
					TRACE(0, "[err] cannot parse the string [%s]\n", p_start);
				} else {
					TRACE(0, "[%s] detected token[%s] val[0x%llx]\n",
						__func__, cfg_vals[i].name, cfg_vals[i].val) ;
				}

			} // if( *p_start != '#' )

		} // while( p_start != (tmp_str + line_len) )
	}

	return 0;
}

#endif /* __CFG_PARSER_ */
