#include <string.h>
#include "register.h"

static inline float getfloatval(Cell w)
{
    FloatConv converter;
    converter.i = w & FLOAT_MASK;
    return converter.f;
}

#ifdef BITS64

static inline Float make_float_from_ints(UInteger high)
{
  FloatToIntsConv converter;
  converter.int_vals.high = high;
  return converter.float_val;
}

#else 

//the function below assumes that the Float type will be exactally twice the size of the 
//   UInteger type. See basictypes.h for the declaration of converter types.
static inline Float make_float_from_ints(UInteger high, UInteger low)
{
  FloatToIntsConv converter;
  converter.int_vals.high = high;
  converter.int_vals.low = low;
  return converter.float_val;
  }

#endif /* BITS64 */

//Below is the implementation of the inline functions for creating and manipulating boxed floats,
// declared in cell_xsb.h. They only exist if the FAST_FLOATS tag is undefined. Otherwise, they
// are defined as Cell-based macros. See cell_xsb.h for details.
#ifndef FAST_FLOATS

static inline void bld_boxedfloat(CTXTdeclc CPtr addr, Float value)
{
    UInteger tempUIFloat;
    //    Float tempFloat = value;
    memcpy(&tempUIFloat,&value,sizeof(tempUIFloat));
    cell(addr) = makecs(hreg);
    bld_functor(hreg,box_psc);
    bld_int(hreg+1,((ID_BOXED_FLOAT << BOX_ID_OFFSET ) | FLOAT_HIGH_16_BITS(tempUIFloat) ));
    //    printf("high %x %x %x",FLOAT_HIGH_16_BITS(tempUIFloat),
    //	   FLOAT_MIDDLE_24_BITS(tempUIFloat),FLOAT_LOW_24_BITS(tempUIFloat));
    bld_int(hreg+2,FLOAT_MIDDLE_24_BITS(tempUIFloat));
    bld_int(hreg+3,FLOAT_LOW_24_BITS(tempUIFloat));
    hreg += 4;
}

#else
static inline void bld_boxedfloat(CTXTdeclc CPtr addr, Float value) {
  bld_float(addr,value);
}
#endif

static inline Cell makefloat(float f)
{
    FloatConv converter;
    converter.f = f;
    return (Cell)(( converter.i & FLOAT_MASK ) | XSB_FLOAT);
}

