interface MyIdentifiable satisfies Identifiable {}
class MyIdentifiableObject() {}

class T() extends Object() {
    shared actual String string = "hello";
    shared actual Boolean equals(Object that) {
        return that.string==string;
    }
    shared actual Integer hash {
        return string.hash;
    }
}

interface Format {}

class TypesPair<out X,out Y>(X x, Y y) 
        given X satisfies Object
        given Y satisfies Object {
    shared actual default String string {
        return "(" x.string ", " y.string ")";
    }
}

class TypesComplex(Float x, Float y) 
        extends TypesPair<Float, Float>(x,y) {
    shared actual String string {
        return "" x.string "+" y.string "i"; 
    }
    shared String pairString {
        return super.string;
    }
}

interface TypesList<out X> {
    shared formal Integer size;
    shared formal Boolean empty;
}

class ConcreteTypesList<out X>(X... xs) 
        satisfies TypesList<X> {
    shared actual Integer size {
        return 0;
    }
    shared actual Boolean empty {
        return true;
    }
}

class TypesCouple<X>(x, y) 
        extends TypesPair<X,X>(x,y) 
        given X satisfies Object {
    shared X x;
    shared X y;
}


class JsIssue9C1() {
    shared default String test() { return "1"; }
}
class JsIssue9C2() extends JsIssue9C1() {
    variable Boolean flag1 := false;
    shared actual default String test() {
        if (flag1) {
            return "ERR1";
        }
        flag1 := true;
        return super.test() + "2";
    }
}
class JsIssue9C3() extends JsIssue9C2() {
    variable Boolean flag2 := false;
    shared actual default String test() {
        if (flag2) {
            return "ERR2";
        }
        flag2 := true;
        return super.test() + "3";
    }
}

void testJsIssue9() {
    value obj = JsIssue9C3();
    check(obj.test()=="123", "Issue #9");
}

//originally in ceylon-js
interface TypeTestI1 {}
interface TypeTestI2 {}
interface TypeTestI3 {}
interface TypeTestI4 {}

class TypeTestC1() satisfies TypeTestI1&TypeTestI2{}
class TypeTestC3() satisfies TypeTestI3{}


void types() {
    Void bool = true;
    Void entry = 1->2;
    Void nothing = null;
    Void one = 1;
    Void t = T();
    Void c = `c`;
    Void str = "string";
    Void seq = {"hello"};
    Void empty = {};
    
    check(bool is Object, "boolean type is object");
    check(bool is IdentifiableObject, "boolean type is identifiable");
    //check(bool is Equality, "boolean type is equality");
    check(!bool is Nothing, "not null boolean type is not nothing");
    check(bool is Boolean, "boolean type 1");
    //check(bool is Void, "boolean type 2");
    //check(bool is Nothing|Boolean, "boolean type 3");
    
    check(nothing is Nothing, "null type 1");
    //check(!nothing is Equality, "null type 2");
    check(!nothing is Object, "null type 3");
    check(!nothing is IdentifiableObject, "null type 4");
    //check(nothing is Void, "null type 5");
        
    check(entry is Object, "entry type 1");
    check(!entry is IdentifiableObject, "not entry type");
    //check(entry is Equality, "entry type 2");
    check(!entry is Nothing, "not null entry type");
    check(entry is Entry<Object,Object>, "entry type 3");
    //check(entry is Entry<Integer,Integer>, "entry type 3");
    //check(entry is Void, "entry type 4");
        
    check(one is Object, "not natural type 1");
    check(!one is IdentifiableObject, "not natural type 2");
    //check(one is Equality, "natural type 1");
    check(!one is Nothing, "not null natural type");
    check(one is Integer, "natural type 2");
    //check(nothing is Void, "natural type 3");
        
    check(c is Object, "not char type 1");
    check(!c is IdentifiableObject, "not char type 1");
    //check(c is Equality, "char type 1");
    check(!c is Nothing, "not null char type");
    check(c is Character, "char type 2");
    //check(c is Void, "char type 3");
        
    check(str is Object, "not string type 1");
    check(!str is IdentifiableObject, "not string type 1");
    //check(str is Equality, "string type 1");
    check(!str is Nothing, "not null string type");
    check(str is String, "string type 2");
    //check(str is Void, "string type 3");
            
    //check(!t is Equality, "not eq custom type");
    check(!t is IdentifiableObject, "not id custom type");
    check(!t is Nothing, "custom type 1");
    check(t is Object, "custom type 2");
    check(t is T, "custom type 3");
    //check(is Void t, "custom type 4");
                
    //if (bool is Equality) {} else { fail("boolean type 4"); }
    if (bool is IdentifiableObject) {} else { fail("boolean type 5"); }
    if (bool is Object) {} else { fail("boolean type 6"); }
    if (bool is Nothing) { fail("null type 6"); }
    if (bool is Boolean?) {} else { fail("optional boolean type 7"); }

    //if (one is Equality) {} else { fail("natural type 4"); }
    if (one is IdentifiableObject) { fail("natural type 5"); }
    if (one is Object) {} else { fail("natural type 6"); }
    if (one is Nothing) { fail("null type 7"); }
    if (one is Integer) {} else { fail("natural type 7"); }
    if (one is Integer?) {} else { fail("optional natural type 8"); }

    //if (c is Equality) {} else { fail("character type 1"); }
    if (c is IdentifiableObject) { fail("character type 2"); }
    if (c is Object) {} else { fail("character type 3"); }
    if (c is Nothing) { fail("null type 8"); }
    if (c is Character) {} else { fail("character type 4"); }
    if (c is Character?) {} else { fail("optional character type 5"); }

    //if (str is Equality) {} else { fail("string type 4"); }
    if (str is IdentifiableObject) { fail("string type 5"); }
    if (str is Object) {} else { fail("string type 6"); }
    if (str is Nothing) { fail("null type 9"); }
    if (str is String?) {} else { fail("optional string type 7"); }

    //if (t is Equality) { fail("custom type 5"); }
    if (t is IdentifiableObject) { fail("custom type 6"); }
    if (t is Object) {} else { fail("custom type 7"); }
    if (t is Nothing) { fail("null type 10"); }
    if (t is T?) {} else { fail("optional custom type 8"); }

    //if (entry is Equality) {} else { fail("entry type 5"); }
    if (entry is IdentifiableObject) { fail("entry type 6"); }
    if (entry is Object) {} else { fail("entry type 7"); }
    if (entry is Nothing) { fail("null type 11"); }
    if (entry is Entry<Object,Object>) {} else { fail("entry type 8"); }
    //if (is Entry<Integer,Integer> entry) {} else { fail("entry type 8"); }
    //if (is Entry<Integer,String> entry) { fail("entry type 9 (required reified gens)"); }
    
    //if (is Equality nothing) { fail("null type 12"); }
    if (nothing is IdentifiableObject) { fail("null type 13"); }
    if (nothing is Object) { fail("null type 14"); }
    if (nothing is Nothing) {} else { fail("null type 15"); }
    if (!nothing is Nothing) { fail("null type 15"); }
    if (nothing is Character?) {} else { fail("null is optional type"); }
    
    if (bool is Boolean|Character|T) {} else { fail("union type 1"); }
    if (t is Boolean|Character|T) {} else { fail("union type 2"); }
    if (str is Boolean|Character|T) { fail("union type 3"); } else {}
    if (nothing is Boolean|Character|T) { fail("union type 4"); } else {}
    if (one is Object&Castable<Bottom>) {} else { fail("intersection type 1"); }
    if (bool is Object&Castable<Bottom>) { fail("intersection type 2"); } else {}
    if (str is Category&Iterable<Void>) {} else { fail("intersection type 3"); }
    if (t is Category&Iterable<Void>) { fail("intersection type 4"); } else {}
    //if (is String[] empty) {} else { fail("sequence type 1"); }
    //if (is String[] seq) {} else { fail("sequence type 2"); }
    //if (is String[]? seq) {} else { fail("sequence type 3"); }
    //if (is Integer[] seq) { fail("sequence type 4 (required reified gens)"); } else {}
    
    check(className(1)=="ceylon.language::Integer", "natural classname");
    check(className(1.0)=="ceylon.language::Float", "float classname");
    check(className("hello").endsWith(".language::SequenceString"), "string classname [1] " + className("hello"));
    check(className("").endsWith(".language::EmptyString"), "string classname [2] " + className(""));
    check(className(` `)=="ceylon.language::Character", "character classname");
    check(className(1->"hello")=="ceylon.language::Entry", "entry classname");
    check(className(true)=="ceylon.language::true", "true classname");
    check(className(false)=="ceylon.language::false", "false classname");

    //from ceylon-js
    value pair = TypesPair("hello", "world");
    check(pair.string=="(hello, world)", "pair.string");
    Object pairObj = pair;
    check(pairObj is TypesPair<Object, Object>, "pair type");
    //check(is TypesPair<String, String> pairObj, "pair type");
    value almostZero = TypesComplex(0.1, 0.1);
    check(almostZero.string=="0.1+0.1i", "complex.string: expected '0.1+0.1i' got " almostZero.string "");
    check(almostZero.pairString=="(0.1, 0.1)", "complex.pairString: expected (0.1, 0.1) got " almostZero.pairString "");
    check(ConcreteTypesList().empty, "concreteList.empty");
    testJsIssue9();

    TypeTestC1|TypeTestC3 c1 = TypeTestC1();
    if (is TypeTestI1&TypeTestI2|TypeTestI3&TypeTestI4 c1) {} else { fail("is A&B|C&D"); }
    
    object myId extends Object() satisfies MyIdentifiable {}
    object myIdo extends MyIdentifiableObject() {}
    Object yourId = myId;
    Object yourIdo = myIdo;
    Object ido = MyIdentifiableObject();
    check(yourId is Identifiable, "is identifiable");
    check(!yourId is IdentifiableObject, "is not identifiable object");
    check(yourIdo is Identifiable, "is identifiable 1");
    check(yourIdo is IdentifiableObject, "is identifiable object 1");
    check(ido is Identifiable, "is identifiable 2");
    check(ido is IdentifiableObject, "is identifiable object 2");
}
