module it.c.compile.preprocessor;


import it;


@("simple macro")
@safe unittest {
    shouldCompile(
        C(
            `
                #define FOO 5
            `
        ),
        D(
            q{
                int[FOO] foos;
                static assert(foos.length == 5, "Wrong length for foos");
            }
        )
    );
}

@("define macro, undefine, then define again")
@safe unittest {
    shouldCompile(
        C(
            `
                #define FOO foo
                #undef FOO
                #define FOO bar
                int FOO(int i);
            `
        ),
        D(
            q{
                int i = bar(2);
            }
        )
    );
}


@("include guards")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("hdr.h",
                  `#ifndef HAHA
                   #    define HAHA
                   int inc(int);
                   #endif`);
        writeFile("foo.dpp",
                  `#include "hdr.h"
                   import bar;
                   int func(int i) { return inc(i) * 2; }`);
        writeFile("bar.dpp",
                  `#include "hdr.h";
                   int func(int i) { return inc(i) * 3; }`);

        runPreprocessOnly("foo.dpp");
        runPreprocessOnly("bar.dpp");
        shouldCompile("foo.d");
    }
}


@("octal.whitespace")
@safe unittest {
    shouldCompile(
        C(
            `
                #define FOO	   00
            `
        ),
        D(
            q{
            }
        )
    );

}


@("elaborate")
@safe unittest {
    shouldCompile(
        C(
            `
                struct Foo {};
                #define STRUCT_HEAD \
                    int count; \
                    struct Foo *foo;
            `
        ),
        D(
            q{
                static struct Derived {
                    STRUCT_HEAD
                }

                auto d = Derived();
                d.count = 42;
                d.foo = null;
            }
        )
    );
}


version(Posix)  // FIXME
@("multiline")
@safe unittest {
    shouldCompile(
        C(
            `
                // WARNING: don't attempt to tidy up the formatting here or the
                // test is actually changed
#define void_to_int_ptr(x) ( \
    (int *) x \
)
            `
        ),
        D(
            q{
                import std.stdio: writeln;
                int a = 7;
                void *p = &a;
                auto intPtr = void_to_int_ptr(p);
            }
        )
    );
}

@("func")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("hdr.h",
                  `#define FOO(x) ((x) * 2)
                   #define BAR(x, y) ((x) + (y))
                   #define BAZ(prefix, ...) text(prefix, __VA_ARGS__)
                   #define STR(x) #x
                   #define ARGH(x) STR(I like spaces x)
                   #define NOARGS() ((short) 42)`);

        writeFile("foo.dpp",
                  [`#include "hdr.h"`,
                   `import std.conv : text;`]);
        writeFile("bar.d",
                  q{
                      import foo;
                      static assert(FOO(2) == 4);
                      static assert(FOO(3) == 6);
                      static assert(BAR(2, 3) == 5);
                      static assert(BAR(3, 4) == 7);
                      static assert(BAZ("prefix_", 42, "foo") == "prefix_42foo");
                      static assert(BAZ("prefix_", 42, "foo", "bar") == "prefix_42foobar");
                      static assert(NOARGS() == 42);
                  });

        runPreprocessOnly("--function-macros", "foo.dpp");
        shouldCompile("bar.d");
    }
}
