title:  GNU make自动依赖生成
description: 
time: 2015/04/11 15:45
category: translate
++++++++

原文：[Auto-Dependency Generation](http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/)  
作者：Paul D.Smith [\<psmith@gnu.org\>](mailto:psmith@gnu.org)

---------------------------------

*在基于make的编译环境中，正确列出makefile文件中所有的依赖项，是一个特别重要，却又时常令人沮丧的任务。*  
*本文档将给出一种能让make自动生成并维护依赖的有效方法。*  
*这个方法的发明人是Tom Tromey [\<tromey@cygnus.com\>](mailto:tromey@cygnus.com)，我仅在这里提一次。方法的所有权归他；解释不妥之处都由我（Paul D.Smith）负责。*  

---------------------------------

- [传统的`make depend`方法](#p1)
- [使用GNU make的`include`](#p2)
- [简单自动依赖生成](#p3)
- [高级自动依赖生成](#p4)
	- [避免重复执行`make`](#p4.1)
	- [避免`No rule to make target …`错误](#p4.2)
- [放置输出文件](#p5)
- [定义`MAKEDEPEND`](#p6)
	- [`MAKEDEPEND = /usr/lib/cpp`](#p6.1)
	- [`MAKEDEPEND = makedepend`](#p6.2)
	- [`MAKEDEPEND = gcc -M`](#p6.3)
	- [将编译和依赖合在一起](#p6.4)
	- [非C文件的依赖生成](#p6.5)


为了确保在必须的时候一定会编译（且仅在必须的时候才进行编译），所有的`make`程序都必须精确地知晓目标文件的依赖。

手动更新这个列表不仅繁琐，而且很容易出错。任何初具规模的系统，都倾向于提供自动提取信息的工具。可能最常用的工具就是`makedepend`程序，它能读取c源码并生成格式化的目标项依赖列表，可以插入或被包含进makefile文件中。

另一种流行的方案，是使用合适的编译器或预处理器（譬如GCC）来生成依赖信息。

本文的主要目的不是要讨论如何生成依赖信息，虽然我会在最后一节中提及一些方法。
这里主要想介绍如何把这些工具的调用和输出整合进GNU `make`中，使依赖信息保持准确和实时，并尽可能做到无缝和高效。

如上所述，这些方法只适用于GNU `make`。适当的修改后应该也可以用于任何包含了`include`功能的其它版本make程序；这可以当作留给读者的练习。不过在做练习之前，请先阅读[Paul的Makefile第一法则](http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/rules.html#rule1):)。

<div id="p1"></div>
## 传统的`make depend`方法

一个历史悠久的方法是在makefile文件中加入特殊目标项，通常使用`depend`，用来创建依赖信息。主要思路是启动某个依赖跟踪工具来更新目录中的相关文件。

对于功能较弱的make程序，通常还需要借助shell脚本的帮助将生成的依赖追加至makefile自身。当然在GNU `make`中，我们可以用`include`指令完成。

这个方法虽然简单，却常带来严重问题。首先，只有在用户显式指明的时候依赖才会重新生成；如果用户不定期运行`make depend`，很快会因为依赖过期而不能正确生成目标。基于此，我们不能认为这个方法是无缝和精确的。

另一个问题是，这种方法的第二次以及以后每次运行都是相对低效的。因为它修改makefile文件，你就必须添加一个独立的编译步骤，这就意味着在每个子目录都产生了调用开销，还得要加上依赖生成工具本身的开销。同时，即使文件没有改变，它也会检查每一个文件。

那么，我们来瞧瞧如何做得更好。

<div id="p2"></div>
## 使用GNU make的`include`

下文涉及的方法依赖于GNU `make`的`include`预处理语句。正如它的名字，`include`语句使得makefile文件可以包含其他makefile文件，效果就如同文件是在那儿输入的一样。

我们马上就能找到它的用处，即用来避免用前面提到的方法追加依赖信息。并且GNU `make`在处理`include`时有一个有趣的特性：如同生成普通文件，GNU `make`会尝试生成被包含的makefile文件。如果被包含的makefile被重建，`make`将重新运行，读取新版本的makefile文件。

我们可以利用这个自动重建的特性来避免独立的`make depend`步骤，而是在正常的生成应用之前生成依赖。例如，如果你定义依赖输出文件依赖于所有的源文件，那么它将在每一次有代码改变时重建。因此依赖信息将永远保持最新，而不需要用户显式指明来生成依赖文件。当然，不幸的是，任何文件有任何变化都会导致依赖文件的重建。

关于GNU `make`自动重建特性的详情，请参阅GNU `make`用户手册， *`How Makefiles Are Remade`* 一节。

<div id="p3"></div>
## 简单自动依赖生成

GNU `make`用户手册中介绍了一种处理自动生成依赖的方法，参见 *`Generating Dependencies Automatically`* 一节。

在此方法中，对每个源文件创建一个“依赖”文件（在我们的例子中使用后缀`.P`来标识）。依赖文件中包含的是一个源文件的依赖信息声明。

随后makefile程序include所有的依赖文件并从中获取依赖信息。一个隐含的规则用来描述依赖文件是如何生成的。类似于这样的形式：

```
SRCS = foo.c bar.c ...

%.P : %.c
	$(MAKEDEPEND)
	@sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' < $*.d > $@; \
		rm -f $*.d; [ -s $@ ] || rm -f $@

include $(SRCS:.c=.P)
```

这些例子中我将简单使用`$(MAKEDEPEND)`来代表你选择的生成依赖的任意方式。几种可能的实现会在稍后介绍。
在这里，输出先被写入一个临时文件，接着被后续处理改变了正常的格式：

```
foo.o: foo.c foo.h bar.h baz.h
```

将也包含.P文件自身，类似这样：

```
foo.o foo.P: foo.c foo.h bar.h baz.h
```

每当GNU `make`读取makefile后，在执行任何操作之前，它会检查并重建每个包含的makefile文件，在这里就是.P文件。我们有创建他们的规则，也有它们的依赖项（在本例中与.o文件相同）。如果有任何可能导致.o文件需要重建的修改，都会导致.P文件重建。

也就是说，当源文件或其包含的文件变化后，`make`会重建.P文件，重启自身，读取新版makefile，再用常规方法生成目标，这时读到的就是更新过的准确的依赖列表。

这里我们解决了旧方法的两个问题。第一，用户不必使用特殊命令来确保依赖列表的准确性。第二，只有真正变化的依赖才会被更新，而不是更新目录中的所有文件。

但是，这种方法带来了三个新问题。首先仍然是效率问题。虽然我们只重新检查了发生变化的文件，但是任何文件修改都会导致`make`重启，在大型的编译系统中可能会很慢。

第二个问题只是一个小烦恼。当你添加一个新文件，或是第一次编译时，.P文件不存在。当`make`试图包含它却发现它不在，会产生一个警告。这不是致命的，因为make会接着重建.P文件并自行重启；只是有些难看而已。

第三个问题就相对严重了：如果你删除或是重命名了被依赖文件（比如C的.h文件），make将停止并报怨找不到目标：

```
make: *** No rule to make target `bar.h', needed by `foo.P'. Stop.
```

这是因为.P文件依赖于一个无法找到的文件。`make`无法重建.P文件，除非找到它依赖的所有文件，但是在重建.P文件之前，make无法知道正确的依赖。这是铁律。

唯一的解决办法是手动删除与丢失文件相关的.P文件——简单的做法是直接全部都删掉而不必去查找相关文件。你甚至可以创建一个`clean-deps`目标来让它自动化（需要根据`MAKECMDGOALS`环境变量的具体情况来实现以避免重建.P文件）。毫无疑问这是令人烦恼的，但鉴于在典型环境中不会经常有文件改名或删除的操作，这个问题也许不那么严重。

<div id="p4"></div>
## 高级自动依赖生成

这里介绍的方法由Tom Tromey [\<tromey@cygnus.com\>](mailto:tromey@cygnus.com)发明，同时也是[FSF](http://www.gnu.org/)的[automake](http://www.gnu.org/software/automake/automake.html)工具所使用的标准方法。我认为它极为巧妙。

<div id="p4.1"></div>
### 避免重复执行`make`

让我们再来审视上面提及的第一个问题：重新执行`make`。如果你认为重新调用真的很没有必要。因为目标项的依赖被更改这点我们是已经知道的，实际上我们在*此次*生成时不需要最新的依赖列表。我们已经知道目标需要重新生成了，而最新的依赖列表对这点毫无影响。我们真正需要确保的是在下次执行`make`，判断目标是否需要重新生成时，依赖列表是已更新的。

因为我们在本次生成时不需要最新的依赖列表，避免重新执行make就是完全可行的：我们可以在生成目标的*同时*生成依赖列表。换句话说，我们可以修改目标的生成规则，在其命令中加入生成依赖列表。此外，在这种情况下，我们必须小心不要再提供自动生成依赖的规则了：如果那样，`make`会重新生成它们并重启：这不是我们所希望的。

现在我们不再关心依赖文件的存在与否，解决第二个问题（画蛇添足的警告）就很简单了：我们可以使用GNU `make`的`-include`指令来包含它们，这样它们不存在时就不会有任何提示了。

让我们来看看到目前为止的一个例子：

```
SRCS = foo.c bar.c ...

%.o : %.c
	@$(MAKEDEPEND)
	$(COMPILE.c) -o $@ $<

-include $(SRCS:.c=.P)
```

<div id="p4.2"></div>
### 避免`No rule to make target …`错误

这个问题有些棘手。事实上，我们可以通过显式在目标中指明文件来说服`make`不要报错退出。如果存在目标项，却不包含命令（无论是显式或隐式）或任何依赖项，则make简单地认为目标项是最新的。这是合情合理的，并且也正是我们所期待的。

对于上述发生错误的情况，目标项不存在。根据GNU `make`用户手册 *没有命令或依赖项的规则* ：

```
如果规则不包含任何依赖项或命令，而且目标文件不存在，那么make会认为目标项总是已更改的。这意味着其他依赖于此目标项的命令一定会被执行。
```

完美。这条规则保证了`make`在处理不存在的文件时不会抛出异常，而且保证了任何依赖于目标项的文件都会被重新生成，这正是我们想要的。

因此，我们要做的就是在生成完原来的依赖文件后，将所有的依赖项放到目标项中，不给它添加命令或依赖项。类似于这样的[\[1\]](#ref):

```
SRCS = foo.c bar.c ...

%.o : %.c
	@$(MAKEDEPEND); \
		cp $*.d $*.P; \
		sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
			-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
		rm -f $*.d
	$(COMPILE.c) -o $@ $<

-include $(SRCS:.c=.P)
```

简单解释一下，这里首先创建原始的依赖列表，然后对依赖文件中的每一行作如下处理后追加至依赖列表：去掉原来的目标顶和所有的行继续符（\），在末尾追加依赖分隔符（:）。这个方法在下文的几种`MAKEDEPEND`实现时工作正常；如果你用了其他依赖生成工具，或许需要作些修改。

<div id="p5"></div>
## 放置输出文件

也许你不喜欢让.P文件塞满你的源码目录。你可以很容易让makefile将它们放到别的地方。这里有一个针对进阶方法的例子，你可以依理应用到其他方法：

```
DEPDIR = .deps
df = $(DEPDIR)/$( *F)

SRCS = foo.c bar.c ...

%.o : %.c
	@$(MAKEDEPEND); \
		cp $(df).d $(df).P; \
		sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
			-e '/^$$/ d' -e 's/$$/ :/' < $(df).d >> $(df).P; \
		rm -f $(df).d
	$(COMPILE.c) -o $@ $<

-include $(SRCS:%.c=$(DEPDIR)/%.P)
```

注意你需要把所有`MAKEDEPEND`脚本中的所有`$*.d`都替换成`$(df).d`。

<div id="p6"></div>
## 定义`MAKEDEPEND`

我在上文中无所顾忌地使用了`MAKEDEPEND`这个变量，下面将讨论几种可能的实现。

<div id="p6.1"></div>
### MAKEDEPEND = `/usr/lib/cpp`

生成依赖最简单的方法是使用C预处理器本身。这需要对你的预处理器的输出格式有一定了解——幸运的是对我们的目的而言，大部分UNIX预处理器都有类似的输出。为了维护在输出错误或调试信息时所要的行号信息，预处理器必须在每次进入或跳出`#include`文件时提供行号及文件名信息。这些信息可以被用作分析哪些文件被包含了。

大多数UNIX系统会输出这种格式的特殊行：

```
#lineno "filename" extra
```

我们只关心`filename`。如果你的预处理器产生上面的输出，像这样定义`MAKEDEPEND`应该是可行的：

```
MAKEDEPEND = $(CPP) $(CPPFLAGS) $< \
	| sed -n 's/^\# *[0-9][0-9]* *"\([^"]*\)".*/$*.o: \1/p' \
	| sort | uniq > $*.d
```

如果你使用的是进阶方法，你可以在sed脚本中将`$*.o`替换成`$@`。如果你使用了现代版本的`sort`，你也可以把`sort | uniq`用`sort -u`替换。

当然了，如果你走这条路，你也可以把你要添加的后期处理加入脚本中。

<div id="p6.2"></div>
### MAKEDEPEND = `makedepend`

X window系统的源代码树提供了一个`makedepend`程序。它检查C源文件及头文件生成依赖列表。它默认设计是将依赖列表追加至makefile文件的尾部，因此想用我们自己的方式来使用它需要使用一点小伎俩。例如某些版本会在输出文件不存在时报错。

这样做应该是可行的：

```
MAKEDEPEND = touch $*.d && makedepend $(CPPFLAGS) -f $*.d $<
```

<div id="p6.3"></div>
### MAKEDEPEND = `gcc -M`

GCC包含了一个可生成依赖文件的预处理器。这样做应该是可行的：

```
MAKEDEPEND = gcc -M $(CPPFLAGS) -o $*.d $<
```

<div id="p6.4"></div>
### 将编译和依赖合在一起

如果你使用GCC，你可以在编译时同时生成依赖，从而节省大量的时间。如果你有一个GCC的最新版本，你可以使用`-MD`选项使之生成依赖信息。这个选项始终把依赖信息输出到.d文件中。因此，你可以在进阶方法的基础上稍作修改，得到一个快一些的版本：

```
%.o : %.c
	$(COMPILE.c) -MD -o $@ $<
	@cp $*.d $*.P; \
		sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
			-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
		rm -f $*.d
```

在一些旧版的GCC上使用环境变量也能做到。你还可以向GCC传递一个选项序列，类似于`-Wp`,`-MD`,`$*.xx`，来用指定的文件名替换GCC的默认输出。这在你想输出依赖文件到不同的目录时特别有用。查阅你的编译器/预处理器以得到更多信息。

<div id="p6.5"></div>
### 非C文件的依赖生成

一般来说，你需要用某种方式生成依赖文件，以使用这些方法。如果你的工作不是基于C文件的，你需要找到或写自己的方法。只要能生成依赖文件就行。这通常不会太难。

Han-Wen Nienhuys [\<hanwen@cs.uu.nl\>](mailto:hanwen@cs.uu.nl)提出了一个有趣的方案，并有一个“用于验证”的[实现](http://make.mad-scientist.net/gendep-0.1.tar.gz)，尽管它目前只在Linux上工作。他提出使用`LD_PRELOAD`环境变量来插入特殊的共享库替换`open(2)`系统调用。新版本的`open()`会输出命令执行时读过的所有文件。于是不用任何特殊扩展工具就能得到可信赖的依赖信息。在他用于验证的实现在，你可以控制输出文件来排除一些类型文件（也许是共享库）。

-------------------------------

<div id="ref"></div>
\[1\]: 注意我修改了Tom在`automake`中使用的预处理脚本，使之可适应不同风格的`MAKEDEPEND`输出。
