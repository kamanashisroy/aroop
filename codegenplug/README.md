
Edsger W. Dijkstra
====================
I sometimes have called "the separation of concerns", which, even if not perfectly possible, is yet the only available technique for effective ordering of one's thoughts, that I know of.

Edward de bono
==============

"
There are many advantages to modules,

- 4. Ease of diagnosis if things go wrong. Each module can be tested in its own right. Sometimes modules can be designed to be self-testing.

- 5. Ease of repair. A faulty module is simply replaced.
"

Debug options
=============

The modules can now be enabled for debug using --module-debug parameter. For example, following parameter will select CastExpressionModule to print debug output into standard output.

```
aroopc --module-debug .castexpression.
```



