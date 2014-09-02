#Codename One Poker Demo in Mirah

This project is a proof of concept of using the Mirah programming language to write Codename One applications.  I simply ported the Codename One Poker Demo (written by Shai Almog) to Mirah.  

###Why Mirah?

Mirah is unique among JVM programming languages in that it satisfies the following two properties:

1. **It has no runtime dependencies.**  Mirah source code compiles to JVM bytecode (i.e. .class files).  The resulting classes can be used inside Java projects just as if they were written using Java.  There are no runtime library dependencies.  For all intents and purposes, users of such classes need not know that they were written in Mirah.
2. **It is just as fast as Java**.  Because Mirah is statically compiled, the bytecode produced is just as fast as equivalent code produced with Java.

These two properties make Mirah an ideal candidate for Codename One.  The fact that it doesn't have any dependencies means, that it will not cause the size of the resulting application to increase at all.  In the mobile space, this is critical.  It also means that you don't have to worry about porting any runtime libraries to support Codename One's class library.

##Build Instructions

###Prerequisites

To build this app, you need to be running NetBeans 7.4 or higher (may work in earlier versions, but isn't tested), with the following plugins installed:

1. The Codename One plugin.
2. The Mirah Netbeans plugin.

###Steps

1. Download this repository:

~~~
git clone https://github.com/shannah/cn1poker-mirah.git
~~~

2. Open the NetBeans project in NetBeans
3. Run the project.  (This will run in the simulator.  You can also build for any of the platforms).

##Comparing the Source Code

The original Java source code for the Poker demo can be found [here](https://code.google.com/p/codenameone/source/browse/trunk/Demos/CN1Poker/src/com/codename1/demo/poker/Poker.java).  

The Mirah version of this class (which comprises the whole demo) can be seen [here](src/com/codename1/demo/poker/mirah/Poker.java).

If you're not familiar with Mirah, here is a *very* brief description:

1. Ruby-like Syntax
2. Statically compiled
3. Uses aggressive type inference to figure out variable types so you don't have to be as verbose as in Java to provide the same information to the compiler.

With that in mind, let's look at a few choice pieces of code and see how the Java version differs from the Mirah version.

###Static Initialization

**Java:**

~~~
private static final char SUITE_SPADE = 's';
private static final char SUITE_HEART = 'h';
private static final char SUITE_DIAMOND = 'd';
private static final char SUITE_CLUB = 'c';
~~~

**Mirah:**

~~~
@@SUITE_SPADE = 's'.charAt(0)
@@SUITE_HEART = 'h'.charAt(0)
@@SUITE_DIAMOND = 'd'.charAt(0)
@@SUITE_CLUB = 'c'.charAt(0)
~~~

A couple of comments here:

1. Mirah uses the prefix '@@' for static variables.
2. All member and static variables are private.
3. Strings can use single or double quotes, so in order to get chars, I use the charAt(0) method of the string.  There may already be a more direct way to get a char literal, but I'm not aware of it.
4. Mirah uses type inference to know that each of these variables is a `char`.

###Implicit Return Values

In Mirah, the last line executed in a method is used as the return value automatically.  You can still explicitly use the "return" keyword, but it is not necessary.

Let's take the calculateDPI method, for example.

**Java:**

~~~
private int calculateDPI() {
    int pixels = Display.getInstance().getDisplayHeight() * 
           Display.getInstance().getDisplayWidth();
    if(pixels > 1000000) {
        return Display.DENSITY_HD;
    }
    if(pixels > 340000) {
        return Display.DENSITY_VERY_HIGH;
    }
    if(pixels > 150000) {
        return Display.DENSITY_HIGH;
    }
    return Display.DENSITY_MEDIUM;
    }
~~~

**Mirah:**

~~~
def calculateDPI
    pixels = Display.getInstance.getDisplayHeight * 
        Display.getInstance.getDisplayWidth
    if pixels > 1000000
        Display.DENSITY_HD
    elsif pixels > 340000
        Display.DENSITY_VERY_HIGH
    elsif pixels > 150000
        Display.DENSITY_HIGH
    else
        Display.DENSITY_MEDIUM
    end
end
~~~

Here, I omitted the "return" keyword since the last line executed will be returned anyways.  In addition, mirah infers the return type of this method because all return values are `int`s.  We could have explicitly indicated that this method returns `int` by changing:

~~~
def calculateDPI
~~~

to

~~~
def calculateDPI:int
~~~

In fact, if you want the method to have a `void` return type, you would need to explictly declare this:

~~~
def someMethod:void
~~~

###Optional Parenthesis and Semi-colons

Throughout the code you'll notice that I don't use semi-colons at the end of lines.  This is optional - you can include them if you prefer.  In addition, method calls and definitions don't require you to use parenthesis (unless they are required to disambiguate method chains).

e.g.

~~~
def calculateDPI()
~~~

and

~~~
def calculateDPI
~~~

are both fine.

###Closures

Mirah provides two formats for closures:

1. `begin` ... `end`  - Generally used for multi-line closures.
2. `{ ... }`  - Generally used for single-line closures.

Let's look at an example in the code.

**Java:**

~~~
Display.getInstance().callSerially(new Runnable() {
   public void run() {
       //...
       new UITimer(new Runnable() {
           public void run() {
               showGameUI();
           }
       }).schedule(2500, false, splash);
   }
});

~~~


**Mirah:**

~~~
Display.getInstance.callSerially do
    # ...
   timer = UITimer.new {me.showGameUI}.schedule(2500, false, splash)
    
end
~~~

Here we see both styles of closure.  The outer closure used for callSerially uses the `do`...`end` style.  The closure used for the UITimer uses the `{...}` style.

Closures and blocks are one of the biggest wins you gain by writing code in Mirah over Java.  It includes a lot less boiler plate and it uses inference to compile to the correct class in the byte code.  

###Closure Parameters

For an example of closures that take parameters, let's look at the action listener that is added to the card back.

**Java:**

~~~
// when the user taps the card back (the deck) we finish the game
cardBack.addActionListener(new ActionListener() {
    public void actionPerformed(ActionEvent evt) {
        //...
    }
});
~~~

***Mirah:**

~~~
@cardBack.addActionListener do |evt|
    #...
end
~~~

In this case, the closure takes the `evt` parameter, which is an ActionEvent.  I could have explicitly declared it as an ActionEvent by adding a type hint.  E.g.

~~~
@cardBack.addActionListener do |evt:ActionEvent|
    #...
end
~~~

But this is not necessary because Mirah can figure this out with type inference.

Multiple parameter are supported as well:

~~~
do |arg1, arg2|
   #...
end
~~~

And also closures that need to override multiple methods.  E.g.

~~~
obj.addMouseListener do
    def mousePressed(evt)
    
    end
    
    def mouseReleased(evt)
    
    end
end
~~~


###Inner Classes

Currently Mirah doesn't support inner classes (except as lambas/closures which ompile to anonymous inner classes).  The Java version of the poker demo used an inner class named `Card` to encapsulate a playing card.  For the Mirah version I moved this class outside of the `Poker` class, but left it inside the `Poker.mirah` file, since Mirah does support having multiple classes per file.  (It also supports multiple packages per file, but let's not get crazy!).

###Generics

Currently Mirah supports generics as a "consumer" but not as a "producer".  I.e., it can use generic classes that have been defined in Java just fine.  However it has no syntax yet.  For specifying generic classes, variable types, or return types inside Mirah code.  This issue is on the roadmap and I expect it to be implemented in a not-so-distant release.  In the mean time, I generally work around this problem by implementing a class in Java that extends the generic type that I want to use, then I just use that class.

For example, the Java version of the Poker demo, the shuffled deck is represented by an ArrayList<Card>, as instantiated here:

~~~
final List<Card> shuffledDeck = new ArrayList<Card>(Arrays.asList(deck));
~~~

I can't create a generic type like this in Mirah, so I created a class in Java as follows:

~~~
public class CardList extends ArrayList<Card>{
    public CardList(Collection<Card> cards){
      super(cards);
    }
}
~~~

Then I use this class in Mirah:

~~~
shuffledDeck = CardList.new(Arrays.asList(deck))
~~~

##More Reading

1. [Mirah Website](http://mirah.org)
2. [Mirah GitHub Page](http)
3. [Java Version of Poker Demo](https://code.google.com/p/codenameone/source/browse/trunk/Demos/CN1Poker/)
4. [Codename One Website](http://www.codenameone.com)
5. [Mirah NetBeans Plugin](https://github.com/shannah/mirah-nbm)