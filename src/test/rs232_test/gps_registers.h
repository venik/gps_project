#ifndef __GPS_REGISTERS_
#define __GPS_REGISTERS_

/* table for tranfer byte i,q and i,q */
typedef enum {
	i1	= 0x3<<0,
	q1	= 0x3<<2,
	i2	= 0x3<<4,
	q2	= 0x3<<6
} gps_nibble;


int8_t gps_value[] = {0, 1, -2, -1};

/* GPS - registers */ 

typedef enum {
	CHIPEN		= 1<<27,

	IDLE_en		= 1<<26,
	IDLE_dis	= 0<<26,

	ILNA1		= 1<<25,

	ILNA2		= 1<<21,

	ILO		= 1<<19,

	IMIX		= 1<<16,

	MIXPOLE_36	= 1<<15,
	MIXPOLE_13	= 0<<15,

	/* unfinished */

} addr_0000;

typedef enum {
	VCOEN		= 1<<27,

	IVCO_l		= 1<<26,
	IVCO_n		= 0<<26,

	REFOUTEN	= 1<<24,

	REG_23		= 1<<23,

	REFDIV_x2	= 0<<21,
	REFDIV_d4	= 1<<21,
	REFDIV_d2	= 2<<21,
	REFDIV_x1	= 3<<21,

	IXTAL_onc	= 0<<19,
	IXTAL_bnc	= 1<<19,
	IXTAL_omc	= 2<<19,
	IXTAL_ohc	= 3<<19,
	XTALCAP		= 1<<18,

	LDMUX		= 0<<13,
	ICP_1ma		= 1<<9,
	ICP_05ma	= 0<<9,
	PFDEN_en	= 0<<8,
	PFDEN_dis	= 1<<8,
	CPTEST		= 0<<6,
	INT_PLL_int	= 1<<3,
	INT_PLL_frac	= 0<<3,
	PWSAV_on	= 1<<2,
	PWSAV_off	= 0<<2
} addr_0011;

#endif /* __GPS_REGISTERS_ */
