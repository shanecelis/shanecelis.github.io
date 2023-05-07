---
layout: post
title: "A Patch for Literate Programming with GNU Guile"
description: ""
category: 
tags: []
---
{% include JB/setup %}
I wrote previously about <a href="/2013/05/20/why-im-trying-literate-programming">why I'm trying literate programming</a>. This
post is a more about how I'm doing it. One of the requirements for
doing literate programming is support for the #line compiler
directive. Typically one sees these in generated source files.

{% highlight c %}
int main(int argc, char *argv[]) {
    #line 360 "hello-world.nw"
    printf("Hello, World!\n");
}
{% endhighlight %}

This tells the compiler to report errors relative to that line in
`hello-world.nw` instead of `hello-world.c`. This is indispensable
when doing literate programming. If one must find the error in the
generated source file then find the error again in the literate
source, literate programming becomes too frustrating and cumbersome to
use, at least for me.

I'm using GNU Guile Scheme for my Google Summer of Code project
Emacsy. Guile doesn't have built-in support for #line directives. But
more importantly it does have support for reader macros.  Reader
macros allow you to define your own syntax. Macro is an overloaded
term, so let me try to disambiguate it.

* C Macros allow one to use C Preprocessor `cpp` as a limited
  metaprogramming facility, but they are tricky to get right because
  of the language impedance mismatch of C and cpp.

* Lisp macros are an entirely different beast. They allow one to write
  code that writes code. Whenever you find yourself writing
  boilerplate code a second or third time, a macro is waiting to be
  born. Macros allow the user to extend the compiler in a principled
  way. Lisp macros work on S-expressions. They provide instructions
  how to transform a given S-expression to some other S-expression.

* Reader macros, or [reader
  extensions](http://www.gnu.org/software/guile/manual/guile.html#Reader-Extensions),
  are pieces of code that transform some arbitrary stream of
  characters into S-expressions. They allow one to express themselves
  in something other than S-expressions. For instance, maybe you want
  a hashmap literal in Guile.  You can write a reader macro that makes
  hashes look like your favorite language.

{% highlight scheme %}
(define hash #{a => 1, b => 2})
{% endhighlight %}

  The above might be translated into something that looks like this:

{% highlight scheme %}
(define hash (let ((h (make-hash-table)))
               (hashq-set! h 'a 1)
               (hashq-set! h 'b 2)
              h))
{% endhighlight %}

  Armed with reader macros, we can extend the syntax of our language.
  One constraint with reader macros is that it must start with a #
  character, which is good because it lets the reader know that a
  reader macro is in play.  Conveniently the # character as the start
  of reader macros is the same as that typically used for compiler
  derectives.

## Implementing #line as a Reader Macro

Given that we can extend the syntax of our language by using a reader
macro, it seems like we should be able to write a #line pragma quite
easily.  Here was my first attempt.  

{% highlight scheme %}
(read-hash-extend 
 #\l 
 (lambda (char port)
   (let* ((ine (read port))
          (lineno (read port))
          (filename (read port)))
     (if (not (eq? ine 'ine))
         (error 
          (format 
           #f
           "Expected '#line <line-number> <filename>'; got '#~a~a ~a \"~a\"'." 
            char ine lineno filename)))
     (set-port-filename! port filename)
     (set-port-line! port lineno)
     (set-port-column! port 0)
     "")))
{% endhighlight %}

So the following code 

{% highlight scheme %}
(define (f x)
#line 314 "increment-literately.nw"
  (+ x 1))
{% endhighlight %}

will turn into

{% highlight scheme %}
(define (f x)
""
  (+ x 1))
{% endhighlight %}
     
In this case, that zero-length string won't cause much of problem, and
it will work for top-level definitions because the strings will just
be ignored, but consider this following bit of code.

{% highlight scheme %}
(+ 1
#line 628 "incrementally-literate.nw"
  2
  3)
{% endhighlight %}

This bit of code will become `(+ 1 "" 2 3)`, which will throw an
exception and does not preserve the original meaning of the code.
Basically, we want a reader macro that emits nothing.  We want a
reader macro whose output is treated like a comment.  

I had hoped that the other commenting facilities in Guile like
[S-expression comments](http://srfi.schemers.org/srfi-62/srfi-62.html)
`(+ 0 #;(+ 1 2) 3) => 3`; or [block
comments](http://www.gnu.org/software/guile/manual/guile.html#Block-Comments),
e.g. `#| this is a comment |#` were implemented as reader extensions.
However, it turns out these are not and could not be implemented as
reader extensions in Scheme.  Luckily, Guile is Free Software so we
can go spelunking and fix it.  

I found them both implemented in `libguile/read.c`.  The reason we
can't implement these as reader extensions is because whatever the
reader extension procedure returns is treated as being from `(read
...)`.  So we need some way to tell it that nothing was read.  There
are many ways to try to represent this.  

* One could have a sentinel value that is treated as though it were
nothing, e.g. any reader extension that emits the symbol
`'no-reader-output` is one such solution.  But what if the reader
macro has output that coincides with the symbol?  

* One could attach some property to the reader extension procedure to
  signify that this reader extension emits nothing.  This is how my
  patch is implemented.  The downside of this is that a procedure may
  not choose to emit or not during its evaluation. As I wrote this
  article I realized I had missed a really good option.

* The question is, what is the best is a way to represent no value or
  nothing in Scheme?  At first I thought, "This was impossible. All
  Scheme procedures return some value.  Some return multiple values."
  Then it hit me, the `values` procedure can be used to return one,
  more, or no values.  Sigh.  Well, I guess I ought to change my
  patch.





