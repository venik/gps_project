#ifndef __GPS_REGISTERS_
#define __GPS_REGISTERS_

#define GET_I1(x) ( x & 0x3 )
#define GET_Q1(x) ( (x & (0x3<<2)) >> 2)
#define GET_I2(x) ( (x & (0x3<<4)) >> 4)
#define GET_Q2(x) ( (x & (0x3<<6)) >> 6)

/* table for tranfer byte i,q and i,q */
//int8_t gps_value[] = {0, 1, -2, -1};
int8_t gps_value[] = {0, 1, -1, -2};

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


/* GPS - registers */ 
typedef enum {
	CHIPEN_en	= 1<<27,		/* Chip enable. Set 1 to enable the device and */
	CHIPEN_off	= 0<<27,		/* 0 to disable the entire device except the serial bus */

	IDLE_en		= 1<<26,		/* Idle enable. Set 1 to put the chip in the idle mode and */
	IDLE_dis	= 0<<26,		/* 0 for operating mode */

	ILNA1		= 1<<25,		/* LNA1 current programming */

	ILNA2		= 1<<21,		/* LNA2 current programming */

	ILO		= 1<<19,		/* LO buffer current programming */

	IMIX		= 1<<16,		/* Mixer current programming */

	MIXPOLE_36	= 1<<15,		/* Mixer pole selection. Set 1 to program the passive filter pole  */
	MIXPOLE_13	= 0<<15,		/* at mixer output at 36MHz, or set 0 to program the pole at 13MHz */

	LNAMODE_sg	= 0<<14,		/* LNA mode selection, D14:D13 = 00: LNA selection gated by the antenna bias circuit */
	LNAMODE_2a	= 1<<13,		/* 01: LNA2 is active */
	LNAMODE_1a	= 1<<14,		/* 10: LNA1 is active */
	LNAMODE_off	= 3<<14,		/* 11: both LNA1 and LNA2 are off */

	MIXEN_en 	= 1<<12,		/* Mixer enable. Set 1 to enable the mixer and 0 to shut down the mixer */
	MIXEN_off	= 0<<12,

	ANTEN_en	= 1<<11,		/* Antenna b i as enab l e. S et 1 to enab l e the antenna b i as and 0 */
	ANTEN_off	= 0<<11,		/* to shutdown the antenna bias */

	FCEN		= 0xd<<5, 		/* IF center frequency programming. Default for fCENTER = 4MHz, BW = 2.5MHz */

	FBW_25		= 0<<4,			/* IF filter center bandwidth selection. D4:D3 = 00: 2.5MHz */ 
	FBW_42		= 1<<4,			/* 10: 4.2MHz */
	FBW_8		= 1<<3,			/* 01: 8MHz */
	FBW_18		= 3<<4,			/* 11: 18MHz (only used as a lowpass filter) */

	F3OR5_5		= 0<<2,			/* Filter order selection. Set 0 to select the 5th-order Butterworth filter */
	F3OR5_3		= 1<<2,			/* Set 1 to select the 3rd-order Butterworth filter */

	FCENX_cpfm	= 1<<1,			/* Polyphase filter selection. Set 1 to select complex bandpass filter mode */
	FCENX_lfm	= 0<<1,			/* Set 0 to select lowpass filter mode */

	FGAIN_def	= 1<<0,
	FGAIN_6db	= 0<<0,			/* IF filter gain setting. Set 0 to reduce the filter gain by 6dB */

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

/* default values */

typedef enum {
		reg_addr_000 = (CHIPEN_en | IDLE_dis | ILNA1 | ILNA2 | ILO | IMIX | MIXPOLE_13 | LNAMODE_sg |
				MIXEN_en | ANTEN_en | FCEN | FBW_25 | F3OR5_5 | FCENX_cpfm | FGAIN_def ),
} default_gps_registers;


#endif /* __GPS_REGISTERS_ */
