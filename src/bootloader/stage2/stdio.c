#include "stdio.h"
#include "x86.h"

void putc(char c) {
	x86_Video_WriteCharTeletype(c, 0);
}

void puts(const char* str){
	while(*str) {
		putc(*str);
		str++;
	}
}

#define PRINTF_STATE_NORMAL       0
#define PRINTF_STATE_LENGTH       1
#define PRINTF_STATE_LENGTH_SHORT 2
#define PRINTF_STATE_LENGTH_LONG  3
#define PRINTF_STATE_SPEC         4

#define PRINTF_LENGTH_DEFAULT     0
#define PRINTF_LENGTH_SHORT_SHORT 1
#define PRINTF_LENGTH_SHORT       2
#define PRINTF_LENGTH_LONG        3
#define PRINTF_LENGTH_LONG_LONG   4

int * printf_number(int* argp, int length, bool sign, int radix);

void _cdecl printf(const char* fmt, ...){
	int* argp = (int*)&fmt; //pointer of size int because of 8-bit padronization (see notes)
	int state = PRINTF_STATE_NORMAL;
	int length = PRINTF_LENGTH_DEFAULT;
	int radix = 10;
	bool sign = false;
	argp += sizeof(fmt) / sizeof(int);		 // we need to divide because fmt is a vector

// State Machine Implementation
	while (*fmt) {
		switch (state) {
			case PRINTF_STATE_NORMAL:
				switch (*fmt) {
					case '%': state = PRINTF_STATE_LENGTH; // if current character is a %, go to length
										break;
					default: putc(*fmt); // otherwise we print
									 break;
				}
					break;

			case PRINTF_STATE_LENGTH:
				switch (*fmt) {
					case 'h': length = PRINTF_LENGTH_SHORT;
									  state = PRINTF_LENGTH_SHORT;
										break;
					case 'l': length = PRINTF_LENGTH_LONG;
										state = PRINTF_LENGTH_LONG;
										break;
					default: goto PRINTF_STATE_SPEC_;
				}
				break;

			case PRINTF_LENGTH_SHORT:
				if (*fmt == 'h'){
					length = PRINTF_LENGTH_SHORT_SHORT;
					state = PRINTF_STATE_SPEC;
				}
				else goto PRINTF_STATE_SPEC_;
				break;

			case PRINTF_LENGTH_LONG:
				if (*fmt == 'l'){
					length = PRINTF_LENGTH_LONG_LONG;
					state = PRINTF_STATE_SPEC;
				}
				else goto PRINTF_STATE_SPEC_; 
				break;

			case PRINTF_STATE_SPEC:
			PRINTF_STATE_SPEC_:
				switch (*fmt){
					// argp is pointing to a character
					case 'c': putc((char)*argp); // print character
										argp++; // moves argp to next argument 
										break;

					// argp is pointing to the beginning of string
					case 's': puts(*(char**)argp); // passes pointer to beginning of string
										argp++;
										break;
				
					case '%': putc('%'); // prints %
										break;

					case 'd':

					case 'i': radix = 10; sign = true;
										argp = printf_number(argp, length, sign, radix);
										break;

					case 'u': radix = 10; sign = false;
										argp = printf_number(argp, length, sign, radix);
										break;

					case 'X':
					case 'x':
					case 'p': radix = 16; sign = false;
										argp = printf_number(argp, length, sign, radix);
										break;

					case 'o': radix = 8; sign = false;
										argp = printf_number(argp, length, sign, radix);
										break;

					// ignore invalid spec
					default: break;
				}
				
				// reset state
				state = PRINTF_STATE_NORMAL;
				length = PRINTF_LENGTH_DEFAULT;
				radix = 10;
				sign = false;
				break;
		}

		fmt ++;
	}

}

const char g_HexChars[] = "0123456789abcdef";

// convert whatever data type we get to unsigned long long and then to a string
int * printf_number(int* argp, int length, bool sign, int radix){
	// stores formatted result
	char buffer[32];
	unsigned long long number;
	int number_sign = 1;
	int pos = 0;

	// process length
	switch (length){
		case PRINTF_LENGTH_SHORT_SHORT:	
		case PRINTF_LENGTH_SHORT:	
		case PRINTF_LENGTH_DEFAULT:
			if (sign){
				int n = *argp;
				if (n < 0) {
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long)n;
			}
			else {
				number = *(unsigned int*)argp;
			}	
			argp++;
			break;

			case PRINTF_LENGTH_LONG:
			if (sign){
				long int n = *(long int*)argp;
				if (n < 0) {
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long)n;
			}
			else {
				number = *(unsigned long int*)argp;
			}	
			argp += 2;
			break;

			case PRINTF_LENGTH_LONG_LONG:
			if (sign){
				long long int n = *(long long int*)argp;
				if (n < 0) {
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long)n;
			}
			else {
				number = *(unsigned long long int*)argp;
			}	
			argp += 4;
			break;
	}

	// convert number to string (ASCII) -> divide by the base, remainder as index in g_HexChars 
	do {
		uint32_t rem;
		x86_div64_32(number, radix, &number, &rem);
		buffer[pos++] = g_HexChars[rem];
	} while (number > 0);

	// add sign
	if (sign && number_sign < 0)
		buffer[pos++] = '-';

	// print number in reverse order
	while (--pos >= 0)
		putc(buffer[pos]);
	
	return argp;

}
