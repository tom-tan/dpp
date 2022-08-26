extern(C)
{
    
    #define _ISSUE_H_INCLUDED_ 
    #ifdef DEF_VAL
    #    undef DEF_VAL
    #endif
    static if(!is(typeof(DEF_VAL))) {
        private enum enumMixinStr_DEF_VAL = `enum DEF_VAL = 0;`;
        static if(is(typeof({ mixin(enumMixinStr_DEF_VAL); }))) {
            mixin(enumMixinStr_DEF_VAL);
        }
    }
    #define DEF_VAL 0
}
